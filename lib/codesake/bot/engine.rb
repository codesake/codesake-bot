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
        @config = read_conf(options[:config])
        authenticate
        @tasks = @config['task']
        behaviour = options[:behaviour]
        behaviour = File.join(".", "lib", "codesake", "bot", "behaviour", @config['bot']['behaviour']) unless @config['bot']['behaviour'].nil? 

        $logger.helo "#{name} v#{version} is starting up"
        
        begin
          load behaviour
          $logger.log "using #{behaviour} as bot behaviour"
          @behaviour = Codesake::Bot::Behaviour.new({:name=>name})
        rescue LoadError => e
          $logger.err(e.message)
          require 'codesake/bot/behaviour'
          $logger.log "reverting to default dummy behaviour"
          @behaviour = Codesake::Bot::Behaviour.new({:name=>name})
        end


      end

      def calc_sleep_time(task)
        
        s = /every (\d) (s|m|h|d|w|y)/.match task

        return 300 if s.nil? # safe fallback is 5 minutes sleeping

        return s[1].to_i                         if s[2] == 's'
        return s[1].to_i * 60                    if s[2] == 'm'
        return s[1].to_i * 60 * 60               if s[2] == 'h'
        return s[1].to_i * 60 * 60 * 24          if s[2] == 'd'
        return s[1].to_i * 60 * 60 * 24 * 7      if s[2] == 'w'
        return s[1].to_i * 60 * 60 * 24 * 7 * 52 if s[2] == 'y'

      end

      def run
        $logger.log "entering main loop"
        while true
          @tasks.each do |task|
            begin 
            @behaviour.send(task["action"].to_sym) if @behaviour.respond_to? task["action"].to_sym
            rescue => e
              $logger.err "#{task["action"]} failed (#{e.message})"
            end
            sleep calc_sleep_time(task["schedule"])
          end
        end

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
          $logger.err e.message
        end
      end

      def online?
        @online
      end

      def name
        return @config['bot']['name']
      end
      def version
        return @config['bot']['version']
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
