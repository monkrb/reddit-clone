# encoding: utf-8

module Protest
  def self.story(description, &block)
    context(description) do
      Protest::Stories.all[self] = Protest::Stories::Story.new(description)
      class_eval(&block) if block_given?
    end
  end

  def self.scenario(name, &block)
    scenario = Protest::Stories::Scenario.new(name)

    Protest::Stories.all[self].scenarios << scenario

    test(name) do
      @scenario = scenario
      instance_eval(&block)
    end
  end

  module Stories
    def self.all
      @all ||= {}
    end

    module TestCase
      def self.included(base)
        class << base
          def story(description, &block)
            context(description) do
              Protest::Stories.all[self] = Protest::Stories::Story.new(description)
              class_eval(&block) if block_given?
            end
          end

          def scenario(name, &block)
            scenario = Protest::Stories::Scenario.new(name)

            Protest::Stories.all[self].scenarios << scenario

            test(name) do
              @scenario = scenario
              instance_eval(&block)
            end
          end
        end
      end
    end

    class Story
      attr_accessor :name, :scenarios

      def initialize(name)
        @name = name
        @scenarios = []
      end
    end

    class Scenario
      attr_accessor :name, :steps, :assertions

      def initialize(name)
        @name = name
        @steps = []
        @assertions = []
      end
    end

    module Methods
      def report(text, &block)
        @scenario.steps << text
        silent(&block) if block_given?
      end

      def silent(&block)
        scenario, @scenario = @scenario, Stories::Scenario.new("#{@scenario.name} (Silent)")

        begin
          block.call
        ensure
          @scenario = scenario
        end
      end
    end

    module Webrat
      def report_for(action, &block)
        define_method(action) do |*args|
          @scenario.steps << block.call(*args)
          super(*args)
        end
      end
      module_function :report_for

      report_for :click_link do |name|
        "Click #{quote(name)}"
      end

      report_for :click_button do |name|
        "Click #{quote(name)}"
      end

      report_for :fill_in do |name, opts|
        "Fill in #{quote(name)} with #{quote(opts[:with])}"
      end

      report_for :visit do |page|
        "Go to #{quote(page)}"
      end

      report_for :check do |name|
        "Check #{quote(name)}"
      end

      report_for :assert_contain do |text|
        "I should see #{quote(text)}"
      end

      def quote(text)
        "“#{text}”"
      end
      module_function :quote
    end
  end

  Protest::TestCase.send(:include, Protest::Stories::TestCase)
  Protest::TestCase.send(:include, Protest::Stories::Methods)
  Protest::TestCase.send(:include, Protest::Stories::Webrat)
end
