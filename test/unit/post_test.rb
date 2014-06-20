require "test_helper"

Protest.describe "A post" do
  it "should normalize URLs" do
    assert !Post.new(:location => "").valid?
    assert_equal "http://www.nytimes.com", Post.new(:location => "www.nytimes.com").location
  end

  it "should validate title length" do
    post = Post.new(:name => "Lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum")

    assert !post.valid?
    assert post.errors.include?([:name, :too_long])
  end
end
