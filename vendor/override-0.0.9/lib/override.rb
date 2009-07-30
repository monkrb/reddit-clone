require "rubygems"
require "metaid"

module Override
  def override object, methods
    methods.each do |method, result|
      result.respond_to?(:to_proc) ?
        object.meta_def(method, &result.to_proc) :
        object.meta_def(method) { |*_| result }
    end
    object
  end

  def expect object, method, options
    expectation = lambda do |*params|
      unless params == options[:with]
        raise ExpectationError.new(options[:with], params)
      end
      options[:return]
    end
    override(object, method => expectation)
  end

  class ExpectationError < ArgumentError
    def initialize(expected, actual)
      super("Expected #{expected.inspect}, got #{actual.inspect}")
    end
  end
end
