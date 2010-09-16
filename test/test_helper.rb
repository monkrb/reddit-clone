ENV['RACK_ENV'] = 'test'

require File.expand_path(File.join(File.dirname(__FILE__), "..", "init"))

require "rack/test"
require "protest"
require "override"

begin
  puts "Connected to Redis #{Ohm.redis.info["redis_version"]} on #{monk_settings(:redis)[:host]}:#{monk_settings(:redis)[:port]}, database #{monk_settings(:redis)[:db]}."
rescue Errno::ECONNREFUSED
  puts <<-EOS

    Cannot connect to Redis.

    Make sure Redis is running on #{monk_settings(:redis)[:host]}:#{monk_settings(:redis)[:port]}.
    This testing suite connects to the database #{monk_settings(:redis)[:db]}.

    To start the server:
      env RACK_ENV=test monk redis start

    To stop the server:
      env RACK_ENV=test monk redis stop

  EOS
  exit 1
end

include Override

override(Date, :today => Date.parse("2009-07-16"))
override(Time, :now => DateTime.parse("2009-07-16 16:21").to_time)

class Protest::TestCase
  include Rack::Test::Methods

  def setup
    Ohm.flush
  end

  def app
    Main.new
  end
end

Protest.report_with(:documentation)
