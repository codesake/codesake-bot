require 'data_mapper'
require 'dm-sqlite-adapter'
require 'securerandom'

module Botolo
  module Bot
    # DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/scan_with_dawn.rb")


    class Request
      include DataMapper::Resource

      property :id,           Serial
      property :requested_by, String, :required => true
      property :url,          String, :required => true
      property :text,         String
      property :processed,    Boolean, :default=>false
      property :created_at,   DateTime, :default=>DateTime.now
      property :updated_at,   DateTime, :default=>DateTime.now
    end

    class Behaviour

      def initialize(options={})
        if ! options.empty? and ! options['bot']['db'].nil? and options['bot']['db']['enabled']
          DataMapper.setup(:default, "sqlite3://#{File.join(Dir.pwd, options['bot']['db']['db_name'])}")
          DataMapper.finalize
          DataMapper.auto_migrate!
        end
      end

      def dump_requests
        Request.all.each do |r|
          $logger.log("#{r.requested_by} requests a scan to #{r.url} on #{r.created_at.strftime("%d/%m/%Y - %H:%M")}. Processed: #{r.processed}")
        end
      end
      def find_helobot
        $twitter_client.search("@codesake #helobot", :result_type => "recent").map do |status|
          $logger.log("saying hello to #{status.user.name} (@#{status.user.screen_name}) original tweet: #{status.text}")
          begin
            $twitter_client.update("Hey @#{status.user.screen_name}, what's going on? Tweet your url with #scanwithdawn to have it reviewed")
          rescue => e
            $logger.err("error tweeting: #{e.message}")
          end

        end

      end

      # https://github.com/codesake/codesake_dawn => https://t.co/vqZF4NpA7X
      def find_scanwithdawn
        $twitter_client.search("#scanwithdawn -rt").each do |tweet|
          regexp = /https?:\/\/[\S]+/
          if ! regexp.match(tweet.text).nil?
            r = Botolo::Bot::Request.first(:url=>regexp.match(tweet.text))
            if r.nil?
              r = Botolo::Bot::Request.new
              r.url = regexp.match(tweet.text)[0]
              r.requested_by = tweet.from_user
              r.text = tweet.text
              saved = r.save
              $logger.log "A new #scanwith dawn request created from #{r.requested_by}: #{r.url}" if saved
              $logger.err "Can't save new #scanwith dawn request created from #{r.requested_by}: #{r.url}" if ! saved
            else
              $logger.log "Won't insert a duplicated request for url: #{r.url}"
            end
          else
            $logger.log "Discarding tweet without URLs from #{tweet.from_user}: #{tweet.text}"
          end
        end
      end

      def mark
        $logger.log("codesake_bot is running with pid #{Process.pid}")
      end

      def promote_dawn

        fortunes = [
          "Hey, check http://codesake.com. It will soon open to beta testers #dawnscanner #appsec services for #sinatra #codesake_bot", 
          "Hey, check http://codesake.com. It will soon open to beta testers #dawnscanner #appsec services for #rails #codesake_bot", 
          "Hey, check http://codesake.com. It will soon open to beta testers #dawnscanner #appsec services for #padrino #codesake_bot", 
          "Did you know that #dawnscanner can make code reviews for web applications written in #rails, #sinatra and #padrino too? #codesake_bot",
          "Did you know that #dawnscanner has more than 56 #cve #security checks? Run dawn -k and discover all of them #codesake_bot",
          "Do you care about your web application security? Follow both @codesake and @codiceinsicuro #codesake_bot", 
          "If you care about your web application security you should really install #dawnscanner. Run gem install codesake-dawn now #codesake_bot",
        ]

        message = fortunes[SecureRandom.random_number(fortunes.size)]
        begin
          $twitter_client.update(message)
          $logger.log(message)
        rescue => e
          $logger.err("error tweeting #{message}: #{e.message}")
        end
      end

    end
  end
end


