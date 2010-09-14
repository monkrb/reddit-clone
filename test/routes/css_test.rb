require "test_helper"

Protest.describe "main.css" do
  it "should render the default stylsheet" do
    get "/css/main.css"
    assert_equal "text/css;charset=UTF-8", last_response.content_type
  end
end
