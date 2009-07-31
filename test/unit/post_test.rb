require File.dirname(__FILE__) + '/../test_helper'

class PostTest < Test::Unit::TestCase
  should "normalize URLs" do
    assert_nil Post.spawn(:location => "").id
    assert_equal "http://www.nytimes.com", Post.spawn(:location => "www.nytimes.com").location
  end

  should "validate title length" do
    post = Post.spawn(:name => "Lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum")

    assert_nil post.id
    assert_equal [[:name, :too_long]], post.errors
  end
end
