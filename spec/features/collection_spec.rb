require 'spec_helper'
include Worthwhile::SearchPathsHelper

describe 'collection' do
  def create_collection(title, description)
    click_link 'Add a Collection'
    fill_in('Title', with: title)
    fill_in('collection_description', with: description)
    click_button("Create Collection")
    expect(page).to have_content 'Items in this Collection'
    expect(page).to have_content title
    expect(page).to have_content description
  end

  let(:title1) {"Test Collection 1"}
  let(:description1) {"Description for collection 1 we are testing."}
  let(:title2) {"Test Collection 2"}
  let(:description2) {"Description for collection 2 we are testing."}

  let(:user) { FactoryGirl.create(:user, email: 'user1@example.com') }
  let(:user_key) { user.user_key }

  before(:all) do
    @old_resque_inline_value = Resque.inline
    Resque.inline = true

    @gws = []
    (0..12).each do |x|
      @gws[x] =  GenericWork.new.tap do |f|
        f.title = "title #{x}"
        f.apply_depositor_metadata('user1@example.com')
        f.save!
      end
    end
    @gw1 = @gws[0]
    @gw2 = @gws[1]
  end

  after(:all) do
    Resque.inline = @old_resque_inline_value
    Batch.destroy_all
    GenericWork.destroy_all
    Collection.destroy_all
  end


  describe 'create collection' do
    before do
      sign_in user
      visit search_path_for_my_collections
    end
    it "should create a collection" do
      title = "Genealogies of the American West"
      description = "All about Genealogies of the American West"
      click_link 'Add a Collection'
      fill_in('Title', with: title)
      fill_in('collection_description', with: description)
      click_button("Create Collection")
      expect(page).to have_content 'Items in this Collection'
      expect(page).to have_content title
      expect(page).to have_content description
    end
    it "should create collection from the dashboard and include works" do
      pending "batch collection operations (add/remove)"
      create_collection(title2, description2)

      visit search_path_for_my_works
      first('input#check_all').click
      click_button "Add to Collection" # opens the modal
      # since there is only one collection, it's not necessary to choose a radio button
      click_button "Update Collection"
      expect(page).to have_content "Items in this Collection"
      expect(page).to have_selector "ol.catalog li:nth-child(9)" # at least 9 works in this collection
    end
  end

  describe 'delete collection' do
    before (:each) do
      @collection = Collection.new title:'collection title'
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user_key)
      @collection.save
      sign_in user
      visit main_app.catalog_index_path(:'f[generic_type_sim][]' => 'Collection', works: 'mine')
    end

    it "should delete a collection" do
      page.should have_content(@collection.title)
      within('#document_'+@collection.noid) do
        #first('button.dropdown-toggle').click
        first(".itemtrash").click
      end
      page.should_not have_content(@collection.title)
      page.should have_content("Collection was successfully deleted.")
    end
  end

  describe 'show collection' do
    before do
      @collection = Collection.new title: 'collection title'
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user_key)
      @collection.members = [@gw1,@gw2]
      @collection.save
      sign_in user
      visit search_path_for_my_collections
    end

    it "should show a collection with a listing of Descriptive Metadata and catalog-style search results" do
      page.should have_content(@collection.title)
      within('#document_'+@collection.noid) do
        click_link("collection title")
      end
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      # Should have search results / contents listing
      page.should have_content(@gw1.title)
      page.should have_content(@gw2.title)
      page.should_not have_css(".pager")

      #click_link "Gallery"
      #expect(page).to have_content(@gw1.title)
      #expect(page).to have_content(@gw2.title)
    end

    it "should hide collection descriptive metadata when searching a collection" do
      page.should have_content(@collection.title)
      within("#document_#{@collection.noid}") do
        click_link("collection title")
      end
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      page.should have_content(@gw1.title)
      page.should have_content(@gw2.title)
      fill_in('collection_search', with: @gw1.title)
      click_button('collection_submit')
      # Should not have Collection Descriptive metadata table
      page.should_not have_content("Descriptions")
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      # Should have search results / contents listing
      page.should have_content(@gw1.title)
      page.should_not have_content(@gw2.title)
      # Should not have Dashboard content in contents listing
      page.should_not have_content("Visibility")
    end
  end

  describe 'edit collection' do
    before (:each) do
      @collection = Collection.new(title: 'Awesome Title')
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user_key)
      @collection.members = [@gw1, @gw2]
      @collection.save
      sign_in user
      visit search_path_for_my_collections
    end

    it "should edit and update collection metadata" do
      page.should have_content(@collection.title)
      within("#document_#{@collection.noid}") do
        click_link('Edit Collection')
      end
      page.should have_field('collection_title', with: @collection.title)
      page.should have_field('collection_description', with: @collection.description)
      new_title = "Altered Title"
      new_description = "Completely new Description text."
      creators = ["Dorje Trollo", "Vajrayogini"]
      fill_in('Title', with: new_title)
      fill_in('collection_description', with: new_description)
      fill_in('Creator', with: creators.first)
      #within('.form-actions') do
        click_button('Update Collection')
      #end
      save_and_open_page
      page.should_not have_content(@collection.title)
      page.should_not have_content(@collection.description)
      page.should have_content(new_title)
      page.should have_content(new_description)
      page.should have_content(creators.first)
    end

    it "should remove a work from a collection" do
      pending "BUG removing works from a collection"
      page.should have_content(@collection.title)
      within("#document_#{@collection.noid}") do
        click_link('Edit Collection')
      end
      page.should have_field('collection_title', with: @collection.title)
      page.should have_field('collection_description', with: @collection.description)
      page.should have_content(@gw1.title)
      page.should have_content(@gw2.title)
      within("#document_#{@gw1.noid}") do
        click_button('Remove From Collection')
      end
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      page.should_not have_content(@gw1.title)
      page.should have_content(@gw2.title)
    end

    it "should remove all works from a collection", js: true do
      pending "batch collection operations (add/remove)"
      page.should have_content(@collection.title)
      within('#document_'+@collection.noid) do
        click_link('Edit Collection')
      end
      page.should have_field('collection_title', with: @collection.title)
      page.should have_field('collection_description', with: @collection.description)
      page.should have_content(@gw1.title)
      page.should have_content(@gw2.title)
      first('input#check_all').click
      click_button('Remove From Collection')
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      page.should_not have_content(@gw1.title)
      page.should_not have_content(@gw2.title)
    end
  end

  describe 'show pages of a collection' do
    before (:each) do
      @collection = Collection.new title:'collection title'
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user_key)
      @collection.members = @gws
      @collection.save!
      sign_in user
      visit search_path_for_my_collections
    end

    it "should show a collection with a listing of Descriptive Metadata and catalog-style search results" do
      page.should have_content(@collection.title)
      within('#document_'+@collection.noid) do
        click_link("collection title")
      end
      page.should have_css(".pager")
    end
  end
end
