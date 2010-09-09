require "test_helper"

require "rack/test"
require "capybara/dsl"
require "stories"
require "stories/runner"

Capybara.default_driver = :selenium
Capybara.app = Main

class Test::Unit::TestCase
  include Capybara
end
