require 'twitter'

module Codesake
  module Bot

    # This is the main bot class, it is responsible of:
    #   * reading configuration
    #   * using Twitter APIs
    #   * do something
    class Engine

      def initialize(options={})
        @start_time = Time.now
        @online = false
        @config = read_conf(options[:filename])
        authenticate
      end

      def authenticate
        begin
          Twitter.configure do |config|
            config.consumer_key = @config['twitter']['consumer_key']
            config.consumer_secret = @config['twitter']['consumer_secret']
            config.oauth_token = @config['twitter']['oauth_token']
            config.oauth_token_secret = @config['twitter']['oauth_token_secret']
          end
          @online = true
        rescue Exception => e
          puts e.message
        end
      end

      def online?
        @online
      end

      def name
        return @config['bot']['name']
      end

      def uptime
        Time.now - @start_time
      end

      def read_conf(filename=nil)
        return {} if filename.nil? or ! File.exist?(filename) 
        return YAML.load_file(filename)
      end

    end
  end
end
