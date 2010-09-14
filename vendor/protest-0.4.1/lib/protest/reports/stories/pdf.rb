require "rubygems"

gem "prawn", "~> 0.4"
require "prawn"

module Protest
  # This report is based on Citrusbyte's Stories[http://github.com/citrusbyte/stories],
  # by Damian Janowski and Michel Martens.
  module Reports
      class Stories::PDF < Report
        include Utils::Summaries
        include Utils::ColorfulOutput

        attr_reader :stream #:nodoc:

        # Set the stream where the report will be written to. STDOUT by default.
        def initialize(stream=STDOUT)
          @stream = stream
        end

        def render_header(pdf)
        end

        def render_many(pdf, elements)
          elements.each do |el|
            pdf.text el.to_s
          end
        end

        on :end do |report|
          Prawn::Document.generate("stories.pdf", :page_size => "A4") do |pdf|
            report.render_header(pdf)

            pdf.text "User Acceptance Tests", :size => 20, :style => :bold
            
            pdf.move_down(15)

            Protest::Stories.all.values.each do |story|
              pdf.text story.name, :style => :bold

              story.scenarios.each_with_index do |scenario,i|
                scenario_leading = 15

                pdf.span(pdf.bounds.width - scenario_leading, :position => scenario_leading) do
                  pdf.text "— #{scenario.name}"

                  pdf.fill_color "666666"

                  unless scenario.steps.empty? && scenario.assertions.empty?
                    pdf.span(pdf.bounds.width - 30, :position => 30) do
                      pdf.font_size(9) do
                        report.render_many(pdf, scenario.steps)
                        report.render_many(pdf, scenario.assertions)
                      end
                    end
                  end

                  pdf.move_down(5) unless i + 1 == story.scenarios.size
                  
                  pdf.fill_color "000000"
                end
              end

              pdf.move_down(10)
            end
          end
        end
      end
  end

  add_report :stories_pdf, Reports::Stories::PDF
end
