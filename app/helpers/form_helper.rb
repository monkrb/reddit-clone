class Monk::Glue
  class HamlPresenter < Ohm::Validations::Presenter
    def on(error, message = (block_given? ? @context.capture_haml { yield } : raise(ArgumentError)))
      handle(error) do
        @output << message
      end
    end

    def present(context)
      @context = context
      super()
    end
  end

  helpers do
    def errors_on(object, &block)
      return if object.errors.empty?

      lines = HamlPresenter.new(object.errors).present(self, &block)

      haml_tag(:div, :class => "errors") do
        haml_tag(:ul) do
          lines.each do |error|
            haml_tag(:li, error)
          end
        end
      end
    end
  end
end
