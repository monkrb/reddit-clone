class Monk < Thor
  namespace :monk

  include Thor::Actions

  desc "test", "Run all the tests"
  def test
    verify_config(:test)

    $:.unshift File.join(File.dirname(__FILE__), "test")

    Dir['test/**/*_test.rb'].each do |file|
      load file unless file =~ /^-/
    end
  end

  desc "start ENV", "Start Monk in the supplied environment"
  def start(env = ENV["RACK_ENV"] || "development")
    verify_config(env)
    invoke :redis

    exec "env RACK_ENV=#{env} ruby init.rb"
  end

  desc "copy_example EXAMPLE, TARGET", "Copies an example file to its destination"
  def copy_example(example, target = target_file_for(example))
    File.exists?(target) ? return : say_status(:missing, target)
    File.exists?(example) ? confirm_copy_file(example, target) : say_status(:missing, example)
  end

  REDIS_ENV = ENV["RACK_ENV"] || "development"
  REDIS_CNF = File.expand_path(File.join("config", "redis", "#{REDIS_ENV}.conf"), File.dirname(__FILE__))
  REDIS_PID = File.expand_path(File.join("db", "redis", REDIS_ENV, "redis.pid"), File.dirname(__FILE__))

  desc "redis start|stop", "Start the Redis server"
  def redis(action = "start")
    case action
    when "start" then redis_start
    when "stop"  then redis_stop
    else say_status(:error, "Usage: monk redis start|stop")
    end
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

  def verify_config(env)
    verify "config/settings.example.yml"
    verify "config/redis/#{env}.example.conf"
  end

  def verify(example)
    copy_example(example) unless File.exists?(target_file_for(example))
  end

  def redis_start
    unless File.exists?(REDIS_PID)
      system "redis-server #{REDIS_CNF}"
      if $?.success?
        say_status :success, "Redis started"
      else
        say_status :error, "Redis failed to start"
        say_status :solution, "Make sure Redis is installed correctly and redis-server is available. The configuration files are located in config/redis."
        exit(1)
      end
    end
  end

  def redis_stop
    if File.exists?(REDIS_PID)
      say_status :success, "Redis stopped"
      system "kill #{File.read(REDIS_PID)}"
      system "rm #{REDIS_PID}"
    end
  end
end
