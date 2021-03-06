class User < ActiveRecord::Base
  has_many :posts, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :hashtags, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :connections, foreign_key: "follower_id", dependent: :destroy
  # overrides the default with a more natural name with source:
  has_many :followed_users, through: :connections, source: :followed
  # simulates a table of reverse connections by setting followed_id as foreign key
  has_many :reverse_connections, foreign_key: "followed_id", class_name: "Connection", dependent: :destroy
  has_many :followers, through: :reverse_connections
  has_many :comments, :foreign_key => :commenter_id
  has_many :activities, dependent: :destroy
  has_many :members, dependent: :destroy
  
  validates :name, presence: true, length: { minimum: 3 }
  validates :password, presence: true, length: { minimum: 4 }
  validates :email, presence: true, length: { minimum: 6 }
  validates_confirmation_of :password
  validates_uniqueness_of :email, :name
  
  before_create :encrypt_password, :generate_token
  
  mount_uploader :profile_picture, ImageUploader
  
  def notify_mentioned(item)
    text = item.text
    for word in text.split(' ')
      if word.include? "@" and User.find_by_name(word.slice(word.index("@")+1..word.size))
        User.find_by_name(word.slice(word.index("@")+1..word.size)).notify! :mention, self, item.id
      end
    end
  end

  def self.feed(user)
    if user and Post.from_users_followed_by(user).present?
      posts = Post.from_users_followed_by(user)
    else
      posts = []
      for post in Post.all
        # only publicly shared posts with up votes for new users
        if post.publicly_shared and post.votes.up_votes.size > 1
          posts << post
        end
      end
    end
    return posts.sort_by(&:score).reverse
  end
  
  def following?(other_user)
    connections.find_by(followed_id: other_user.id)
  end

  def follow!(other_user)
    connections.create!(followed_id: other_user.id)
  end

  def unfollow!(other_user)
    connections.find_by(followed_id: other_user.id).destroy
  end
  
  def notify!(action, sender, item=1)
    user_name = sender.name
    if self != sender then
      case action
        when :follow
          message = "#{user_name} started following you."
        when :message
          message = "#{user_name} sent you a message."
        when :share_post
          message = "#{user_name} shared your post."
        when :comment
          message = "#{user_name} commented on your post."
        when :reply
          message = "#{user_name} replied to your comment."
        when :comment_proposal
          message = "#{user_name} commented on your proposal."
        when :comment_module
          message = "#{user_name} commented on your module."
        when :comment_share
          message = "#{user_name} commented on your share."
        when :up_vote
          message = "#{user_name} up voted your post."
        when :up_vote_share
          message = "#{user_name} up voted your share."
        when :mention
          message = "#{user_name} mentioned you in a post."
      end
      notifications.create!(message: message, other_user: sender.id,
        action: action.to_s, item: item)
    end
  end
  
  def self.authenticate(email, password)
    user = find_by_email(email.downcase)
    if user && user.password == BCrypt::Engine.hash_secret(password, user.salt)
      user
    else
      nil
    end
  end
  
  def generate_token
    begin
      self.auth_token = SecureRandom.urlsafe_base64
    end while User.exists? auth_token: self.auth_token
  end
  
  def update_token
    self.generate_token
    self.save
  end
  
  private
  
  def encrypt_password
    if password.present?
      self.salt = BCrypt::Engine.generate_salt
      self.password = BCrypt::Engine.hash_secret(password, salt)
    end
  end
end
