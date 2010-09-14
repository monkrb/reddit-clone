module Protest
  # This report is based on Citrusbyte's Stories[http://github.com/citrusbyte/stories],
  # by Damian Janowski and Michel Martens.
  class Reports::Stories < Report
    include Utils::Summaries
    include Utils::ColorfulOutput

    attr_reader :stream #:nodoc:

    # Set the stream where the report will be written to. STDOUT by default.
    def initialize(stream=STDOUT)
      @stream = stream
    end

    on :pass do |report, pass|
      report.print ".", :passed
    end

    on :pending do |report, pending|
      report.print "P", :pending
    end

    on :failure do |report, failure|
      report.print "F", :failed
    end

    on :error do |report, error|
      report.print "E", :errored
    end

    on :end do |report|
      report.puts

      Stories.all.values.to_a.each_with_index do |story,i|
        report.puts "- #{story.name}"

        story.scenarios.each do |scenario|
          report.puts "    #{scenario.name}"

          unless scenario.steps.empty? && scenario.assertions.empty?
            scenario.steps.each do |step|
              report.puts "      #{step}"
            end

            scenario.assertions.each do |assertion|
              report.puts "      #{assertion}"
            end

            report.puts
          end
        end

        report.puts unless i + 1 == Stories.all.values.size
      end

      report.puts "%d stories, %d scenarios" % [Stories.all.values.size, Stories.all.values.inject(0) {|total,s| total + s.scenarios.size }]
    end
  end

  add_report :stories, Reports::Stories
end
