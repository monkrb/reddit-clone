module Protest
  # The +:summary+ report will output a brief summary with the total number
  # of tests, assertions, passed tests, pending tests, failed tests and
  # errors.
  class Reports::Summary < Report
    include Utils::Summaries
    include Utils::ColorfulOutput

    attr_reader :stream #:nodoc:

    # Set the stream where the report will be written to. STDOUT by default.
    def initialize(stream=STDOUT)
      @stream = stream
    end

    on :end do |report|
      report.summarize_test_totals
    end
  end

  add_report :summary, Reports::Summary
end
