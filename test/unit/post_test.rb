require File.dirname(__FILE__) + '/../test_helper'

class PostTest < Test::Unit::TestCase
  should "normalize URLs" do
    assert_nil Post.spawn(:location => "").id
    assert_equal "http://www.nytimes.com", Post.spawn(:location => "www.nytimes.com").location
  end
end
