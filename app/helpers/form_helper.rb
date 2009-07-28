class Monk::Glue
  helpers do
    def errors_on(object, &block)
      return if object.errors.empty?

      lines = object.errors.present(&block)

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
