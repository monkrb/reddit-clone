require "test_helper"

Protest.describe "A post" do
  it "should normalize URLs" do
    assert !Post.spawn(:location => "").id
    assert_equal "http://www.nytimes.com", Post.spawn(:location => "www.nytimes.com").location
  end

  it "should validate title length" do
    post = Post.spawn(:name => "Lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum")

    assert !post.id
    assert_equal [[:name, :too_long]], post.errors
  end
end
