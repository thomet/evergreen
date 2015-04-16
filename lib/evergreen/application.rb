require 'sprockets-sass'
require 'sinatra/sprockets-helpers'

module Evergreen
  class Application < Sinatra::Base
    class << self
      def add_asset_paths(paths)
        paths.each do |path|
          sprockets.append_path path
        end
      end
    end

    register Sinatra::Sprockets::Helpers

    set :static, false
    set :root, File.expand_path('.', File.dirname(__FILE__))
    set :sprockets, Sprockets::Environment.new
    set :paths, []

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
