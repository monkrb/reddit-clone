class Post < Ohm::Model
  extend Spawn
  include Comparable

  attribute :name
  attribute :location
  attribute :datetime
  attribute :author

  counter :votes

  index :date
  index :author

  def validate
    assert_present(:name) and assert_length(:name, 0..50)
    assert_present :location
    assert_numeric :author
  end

  def create
    self.datetime ||= Time.now.strftime("%Y-%m-%d %H:%M:%S")
    super
  end

  def to_s
    name.to_s
  end

  def to_param
    name
  end

  def <=> other
    other.votes == votes ?
      name <=> other.name :
      other.votes <=> votes
  end

  def self.by_date(date)
    find(:date => format_date(date))
  end

  def date
    format_date(Time.parse(datetime).send(:to_date))
  end

  def location=(value)
    value = "http://#{value}" unless value.empty? || value =~ %r{^http://}
    write_local(:location, value)
  end

protected

  def assert_length(att, length)
    assert length === send(att).size, [att, :too_long]
  end
end

Post.spawner do |post|
  post.name = Faker::Company.catch_phrase
  post.location = "http://#{Faker::Internet.domain_name}"
  post.author ||= User.spawn.id
end
