require 'digest/sha1'

class User < Ohm::Model
  class WrongUsername < ArgumentError; end
  class WrongPassword < ArgumentError; end

  extend Spawn

  attribute :username
  attribute :password
  attribute :salt
  set :votes, Post

  index :username

  def validate
    assert_present :username
    assert_present :password
    assert_unique :username
  end

  def self.authenticate(username, password)
    raise WrongUsername unless user = find(:username, username).first
    raise WrongPassword unless user.password == encrypt(password, user.salt)
    user
  end

  def to_s
    username.to_s
  end

  def to_param
    username
  end

  def create
    self.salt ||= encrypt(Time.now.to_s, username)
    self.password = encrypt(password, salt)
    super
  end

  def posts_authored
    Post.find(:author, id)
  end

  def votes_received
    posts_authored.inject(0) { |t, p| t + p.votes.to_i }
  end

  def vote_for(post)
    if voted_for?(post)
      post.decr(:votes)
      votes.delete(post.id)
    else
      post.incr(:votes)
      votes.add(post)
    end
  end

  def voted_for?(post)
    votes.include?(post.id)
  end

private

  def self.encrypt(string, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{string}--")
  end

  def encrypt(*attrs)
    self.class.encrypt(*attrs)
  end
end

User.spawner do |user|
  user.username = Faker::Internet.user_name.tr(".", "")
  user.password = "monkey"
end
