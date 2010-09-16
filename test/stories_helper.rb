require "test_helper"

require "rack/test"
require "capybara/dsl"
require "protest/stories"

Capybara.default_driver = :rack_test
Capybara.app = Main.new

class Protest::TestCase
  include Capybara

  def assert_contain(text)
    assert page.has_content?(text)
  end

  def assert_not_contain(text)
    assert !page.has_content?(text)
  end

  def status
    Capybara.current_session.driver.rack_server.response.status
  end

  def teardown
    Capybara.reset_sessions!
  end

  def url(path)
    Capybara.current_session.driver.rack_server.url path
  end

  class << self
    alias original_scenario scenario

    def scenario(name, options = {}, &block)
      original_scenario(name) do
        old_driver, Capybara.current_driver = Capybara.current_driver, options[:driver] || Capybara.current_driver

        instance_eval(&block)

        Capybara.current_driver = old_driver
      end
    end
  end
end
