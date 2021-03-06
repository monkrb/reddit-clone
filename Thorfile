class Monk < Thor
  namespace :monk

  include Thor::Actions

  desc "test", "Run all the tests"
  def test
    verify "config/settings.example.yml"
    verify "config/redis/test.example.conf"

    $:.unshift File.join(File.dirname(__FILE__), "test")

    Dir['test/**/*_test.rb'].each do |file|
      load file unless file =~ /^-/
    end
  end

  desc "start ENV", "Start Monk in the supplied environment"
  def start(env = ENV["RACK_ENV"] || "development")
    verify "config/settings.example.yml"
    verify "config/redis/#{env}.example.conf"
    exec "env RACK_ENV=#{env} ruby init.rb"
  end

  desc "copy_example EXAMPLE, TARGET", "Copies an example file to its destination"
  def copy_example(example, target = target_file_for(example))
    File.exists?(target) ? return : say_status(:missing, target)
    File.exists?(example) ? confirm_copy_file(example, target) : say_status(:missing, example)
  end

  desc "verify EXAMPLE_FILE", "Verifies that the corresponding file exists for the supplied example file"
  def verify(example)
    copy_example(example) unless File.exists?(target_file_for(example))
  end

  desc "seed", "Seeds the database with random data"
  def seed
    init

    Ohm.flush

    100.times do
      Post.spawn(:datetime => (Time.now - rand(24) * 60 * 60).strftime("%Y-%m-%d %H:%M:%S"))
    end
  end

  desc "sass", "Compile all Sass files into CSS"
  def sass
    init

    require "sass/plugin"

    Sass::Plugin.options.merge! \
      :template_location => root_path("app", "views", "css"),
      :css_location      => File.join(Main.public, "css"),
      :cache             => false

    Sass::Plugin.update_stylesheets
  end

private

  def init
    require "init"
  end

  def self.source_root
    File.dirname(__FILE__)
  end

  def confirm_copy_file(source, target)
    if yes?("Do you want to copy the file #{source} to #{target}? [yn]")
      copy_file(source, target)
    end
  end

  def target_file_for(example_file)
    example_file.sub(".example", "")
  end
end
