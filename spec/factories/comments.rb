FactoryGirl.define do
  factory :comment do
    body 'New Comment'
  end

  factory :invalid_comment, class: "Comment" do
    body nil
  end
end