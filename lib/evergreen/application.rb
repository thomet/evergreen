require 'sprockets-sass'
require 'sinatra/sprockets-helpers'

module Evergreen
  class Application < Sinatra::Base
    class << self
      def add_asset_paths(paths)
        paths.each do |path|
          sprockets.append_path path
          #precompile_assets!
        end
      end

      def precompile_assets!
        puts "PRECOMPILE!!"
        manifest = Sprockets::Manifest.new(sprockets.index, '/tmp/my_assets')
        manifest.compile(%w(application.css application.js))
      end

      def clean_precompiled_assets!
        FileUtils.rm_rf('/tmp/my_assets')
      end
    end

    register Sinatra::Sprockets::Helpers

    set :static, false
    set :root, File.expand_path('.', File.dirname(__FILE__))
    set :sprockets, Sprockets::Environment.new
    set :paths, []
    set :asset_path, '/tmp/my_assets'
    set :public_folder, '/tmp/my_assets/assets'

    helpers do
      def url(path)
        Evergreen.mounted_at.to_s + path.to_s
      end

      def render_spec(spec)
        spec.read if spec
      rescue StandardError => error
        erb :_spec_error, :locals => { :error => error }
      end
    end

    configure do
      Sprockets::Helpers.configure do |config|
        config.manifest = Sprockets::Manifest.new(sprockets.index, '/tmp/my_assets')
        config.debug = false
      end
    end

    get '/' do
      @suite = Evergreen::Suite.new
      erb :list
    end

    get '/run/all' do
      @suite = Evergreen::Suite.new
      erb :run
    end

    get '/run/*' do |name|
      @suite = Evergreen::Suite.new
      @spec  = @suite.get_spec(name)
      erb :run
    end

    get "/jasmine/*" do |path|
      send_file File.expand_path(File.join('../jasmine/lib/jasmine-core', path), File.dirname(__FILE__))
    end

    get "/resources/*" do |path|
      send_file File.expand_path(File.join('resources', path), File.dirname(__FILE__))
    end

    get "/assets/*" do |path|
      env_sprockets = request.env.dup
      env_sprockets['PATH_INFO'] = path
      settings.sprockets.call env_sprockets
    end

    get '/*' do |path|
      send_file File.join(Evergreen.root, Evergreen.public_dir, path)
    end

  end
end
