ENV['RACK_ENV'] = 'test'

require File.expand_path(File.join(File.dirname(__FILE__), "..", "init"))

require "rack/test"
require "contest"
require "override"
require "quietbacktrace"

class Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Main.new
  end
end

include Override

override(Date, :today => Date.parse("2009-07-16"))
override(Time, :now => Time.parse("2009-07-16 16:21:00"))
