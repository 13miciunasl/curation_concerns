require 'spec_helper'

describe CurationConcern::GenericWorksController do
  let(:public_work_factory_name) { :public_generic_work }
  let(:private_work_factory_name) { :work }

  let(:user) { FactoryGirl.create(:user) }
  before { sign_in user }

  describe "#show" do
    context "my own private work" do
      let(:a_work) { FactoryGirl.create(private_work_factory_name, user: user) }
      it "should show me the page" do
        get :show, id: a_work
        expect(response).to be_success
      end
    end
    context "someone elses private work" do
      let(:a_work) { FactoryGirl.create(private_work_factory_name) }
      it "should show 401 Unauthorized" do
        get :show, id: a_work
        expect(response.status).to eq 401
        response.should render_template(:unauthorized)
      end
    end
    context "someone elses public work" do
      let(:a_work) { FactoryGirl.create(public_work_factory_name) }
      it "should show me the page" do
        get :show, id: a_work
        expect(response).to be_success
      end
    end
  end

  describe "#new" do
    context "my work" do
      it "should show me the page" do
        get :new
        expect(response).to be_success
      end
    end
  end

  describe "#create" do
    it "should create a work" do
      expect {
        post :create, accept_contributor_agreement: "accept", generic_work: {  }
      }.to change { GenericWork.count }.by(1)
      response.should redirect_to [:curation_concern, assigns[:curation_concern]]
    end
  end

  describe "#edit" do
    context "my own private work" do
      let(:a_work) { FactoryGirl.create(private_work_factory_name, user: user) }
      it "should show me the page" do
        get :edit, id: a_work
        expect(response).to be_success
      end
    end
    context "someone elses private work" do
      let(:a_work) { FactoryGirl.create(private_work_factory_name) }
      it "should show 401 Unauthorized" do
        get :edit, id: a_work
        expect(response.status).to eq 401
        response.should render_template(:unauthorized)
      end
    end
    context "someone elses public work" do
      let(:a_work) { FactoryGirl.create(public_work_factory_name) }
      it "should show me the page" do
        get :edit, id: a_work
        expect(response.status).to eq 401
        response.should render_template(:unauthorized)
      end
    end
  end

  describe "#update" do
    let(:a_work) { FactoryGirl.create(private_work_factory_name, user: user) }
    it "should update the work " do
      patch :update, id: a_work, generic_work: {  }
      response.should redirect_to [:curation_concern, assigns[:curation_concern]]
    end
    describe "changing rights" do
      it "should prompt to change the files access" do
        controller.stub(actor: double(update: true, visibility_changed?: true))
        patch :update, id: a_work
        response.should redirect_to confirm_curation_concern_permission_path(controller.curation_concern)
      end
    end
    describe "failure" do
      it "renders the form" do
        controller.stub(actor: double(update: false, visibility_changed?: false))
        patch :update, id: a_work
        expect(response).to render_template('edit')
      end
    end
  end

  describe "#destroy" do
    let(:work_to_be_deleted) { FactoryGirl.create(private_work_factory_name, user: user) }
    it "should delete the work" do
      delete :destroy, id: work_to_be_deleted
      expect { GenericWork.find(work_to_be_deleted.pid) }.to raise_error
    end
  end

end
