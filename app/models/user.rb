class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:facebook, :twitter]

  has_many :questions
  has_many :answers
  has_many :votes, dependent: :destroy
  has_many :comments
  has_many :authorizations, dependent: :destroy
  has_many :subscriptions
  has_many :questions, through: :subscriptions

  def author_of?(resource)
    resource.user_id == id
  end

  def self.find_for_oauth(auth)
    authorization = Authorization.where(provider: auth['provider'], uid: auth['uid'].to_s).first
    return authorization.user if authorization

    email = auth['info']['email']
    user = User.where(email: email).first

    if user
      user.create_authorization(auth)
    else
      password = Devise.friendly_token[0, 20]
      user = User.new(email: email, password: password, password_confirmation: password)
      user.skip_confirmation! unless auth['unconfirm']
      return nil unless user.save
      user.create_authorization(auth)
    end
    user
  end

  def self.send_daily_digest
    find_each.each do |user|
      DailyMailer.digest(user).deliver_later
    end
  end

  def self.send_new_answer(answer)
    Subscription.where(question_id: answer.question_id).each do |subscription|
      SubscriptionMailer.new_answer(subscription.user, answer).deliver_later
    end
  end

  def create_authorization(auth)
    self.authorizations.create(provider: auth['provider'], uid: auth['uid'].to_s )
  end
end