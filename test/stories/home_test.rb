require "stories_helper"

class HomeTest < Test::Unit::TestCase
  story "As a developer I want to see the homepage so I know Monk is correctly installed" do
    scenario "A visitor goes to the homepage" do
      visit "/"

      assert_contain "Monk"
    end
  end
end
