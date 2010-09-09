class Main
  set :stylesheets,
    Collage::Packager::Sass.new(root_path("public"),
      [
        root_path("app/views/css/reset.sass"),
        root_path("app/views/css/main.sass"),
      ]
    )

  get "/css.css" do
    content_type "text/css", :charset => "UTF-8"
    self.class.stylesheets.package
  end
end
