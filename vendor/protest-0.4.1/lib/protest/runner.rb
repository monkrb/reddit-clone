module Protest
  class Runner
    # Set up the test runner. Takes in a report that will be passed to test
    # cases for reporting.
    def initialize(report)
      @report = report
    end

    # Run a set of test cases, provided as arguments. This will fire relevant
    # events on the runner's report, at the +start+ and +end+ of the test run,
    # and before and after each test case (+enter+ and +exit+.)
    def run(*test_cases)
      fire_event :start
      test_cases.each do |test_case|
        fire_event :enter, test_case
        test_case.run(self)
        fire_event :exit, test_case
      end
      fire_event :end
    end

    # Run a test and report if it passes, fails, or is pending. Takes the name
    # of the test as an argument.
    def report(test)
      fire_event(:test, Test.new(test)) if test.real?
      test.run(@report)
      fire_event(:pass, PassedTest.new(test)) if test.real?
    rescue Pending => e
      fire_event :pending, PendingTest.new(test, e)
    rescue AssertionFailed => e
      fire_event :failure, FailedTest.new(test, e)
    rescue Exception => e
      fire_event :error, ErroredTest.new(test, e)
      raise if test.raise_exceptions?
    end

    protected

    def fire_event(event, *args)
      event_handler_method = :"on_#{event}"
      @report.send(event_handler_method, *args) if @report.respond_to?(event_handler_method)
    end
  end
end
