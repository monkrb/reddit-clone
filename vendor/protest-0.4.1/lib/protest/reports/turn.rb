module Protest
  # This report displays each test on a separate line with failures being
  # displayed immediately instead of at the end of the tests.
  #
  # You might find this useful when running a large test suite, as it can
  # be very frustrating to see a failure (....F...) and then have to wait
  # until all the tests finish before you can see what the exact failure
  # was.
  #
  # This report is based on the output displayed by TURN[http://github.com/TwP/turn],
  # Test::Unit Reporter (New) by Tim Pease.
  class Reports::Turn < Report
    include Utils::Summaries
    include Utils::ColorfulOutput

    attr_reader :stream #:nodoc:

    PASS    = "PASS"
    FAIL    = "FAIL"
    ERROR   = "ERROR"
    PENDING = "PENDING"

    # Set the stream where the report will be written to. STDOUT by default.
    def initialize(stream=STDOUT)
      @stream = stream
    end

    on :enter do |report, context|
      report.puts context.description unless context.tests.empty?
    end

    on :test do |report, test|
      report.print "    %-67s" % test.test_name
    end

    on :pass do |report, passed_test|
      report.puts  PASS, :passed
    end

    on :failure do |report, failed_test|
      report.puts FAIL, :failed

      report.puts "\t#{failed_test.error_message}", :failed
      failed_test.backtrace.each { |backtrace| report.puts "\t#{backtrace}", :failed }
    end

    on :error do |report, errored_test|
      report.puts ERROR, :errored

      report.puts "\t#{errored_test.error_message}", :errored
      errored_test.backtrace.each { |backtrace| report.puts "\t#{backtrace}", :failed }
    end

    on :pending do |report, pending_test|
      report.puts PENDING, :pending
    end

    on :end do |report|
      pass    = report.passes.count
      pending = report.pendings.count
      failure = report.failures.count
      error   = report.errors.count
      total   = report.tests.count

      bar = '=' * 78
      colorize_as = pass == total ? :passed : (pass + pending == total ? :pending : :failed)

      report.puts bar, colorize_as
      report.puts "  pass: %d,  pending: %d,  fail: %d,  error: %d" % [pass, pending, failure, error]
      report.puts "  total: %d tests with %d assertions in #{report.time_elapsed} seconds" % [total, report.assertions]
      report.puts bar, colorize_as
    end
  end

  add_report :turn, Reports::Turn
end
