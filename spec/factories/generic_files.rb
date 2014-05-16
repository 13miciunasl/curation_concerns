FactoryGirl.define do
  factory :generic_file, class: Worthwhile::GenericFile do
    factory :file_with_work do
      ignore do
        user { FactoryGirl.create(:user) }
        content nil
      end
      batch { FactoryGirl.create(:generic_work, user: user) }

      after(:build) do |file, evaluator|
        file.apply_depositor_metadata(evaluator.user.user_key)
        if evaluator.content
          file.add_file(evaluator.content.read, 'content', evaluator.content.original_filename)
        end
      end
    end
  end
end
