require 'data_mapper'
require 'dm-sqlite-adapter'
require 'securerandom'
require 'rss'

module Botolo
  module Bot
    # DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/scan_with_dawn.rb")


    class Follower
      include DataMapper::Resource

      property :id,             Serial
      property :follower_name,  String, :required => true, :unique=>true
      property :follower_id,    String, :required => true, :unique=>true
      property :created_at,     DateTime, :default=>DateTime.now
      property :updated_at,     DateTime, :default=>DateTime.now
    end

    class Behaviour

      def initialize(options={})
        if ! options.empty? and ! options['bot']['db'].nil? and options['bot']['db']['enabled']
          DataMapper.setup(:default, "sqlite3://#{File.join(Dir.pwd, options['bot']['db']['db_name'])}")
          DataMapper.finalize
          DataMapper.auto_upgrade!
        end
        @start_time = Time.now
        refresh_rss
      end

      def get_info
        f = $twitter_client.followers
        f.each do |user|
          u = Botolo::Bot::Follower.first(:follower_id=>user.id)
          if (u.nil?)
            $logger.debug "Adding #{user.id} - #{user.name}"
            u = Botolo::Bot::Follower.new
            u.follower_name = user.name
            u.follower_id = user.id
            u.save
          end
        end
      end

      def show_blog_links
        begin
          $twitter_client.update("Segui @codiceinsicuro il primo #blog #italiano di #sicurezza #informatica croccante fuori e morbido dentro")
          sleep(15)
          $twitter_client.update("Segui @codiceinsicuro su fabebook: https://www.facebook.com/codiceinsicuro")
          sleep(15)
        rescue => e
          $logger.err("error tweeting #{m}: #{e.message}")
        end
      end

      # Everyday bot will fetch RSS (if online) and build the post catalogue
      def refresh_rss
        rss = nil

        open('https://codiceinsicuro.it/feed.xml') do |http|
          response = http.read
          File.open('./feed.xml', 'w') do |f|
            f.puts(response)
          end
          rss = RSS::Parser.parse(response, false)
        end

        # Parsing a previously saved rss if available
        # $logger.debug "I'm offline, reading feed.xml from disk. Please check network connection"
        # body = ""
        # File.open('./feed.xml', 'r') do |f|
        # body = f.read
        # end
        # rss = RSS::Parser.parse(body, false)

        @feed = []

        rss.items.each_with_index do |item, i|
          @feed << {:title=>item.title.content, :link=>item.link.href}
        end
        $logger.log "#{@feed.size} elements loaded from feed"

      end

      def show_random_posts(limit = 3)
        return nil if @feed.nil? || @feed.size == 0
        (0..limit-1).each do |l|
          post = @feed[SecureRandom.random_number(@feed.size)]
          m = "\"#{post[:title]}\" (#{post[:link]}) #blog #sicurezza #informatica."
          $logger.debug "#{m} - #{m.length}"
          begin
            $twitter_client.update(m)
            $logger.debug "tweet sent!"
          rescue => e
            $logger.err("error tweeting #{m}: #{e.message}")
          end
          sleep(10)

        end
      end

      def find_the_sp0nge_appsec(limit = 5)
        list = $twitter_client.search("from:thesp0nge #appsec")
        unless list.nil? || list.to_a.nil?

          (0..limit-1).each do |l|
            t = list.to_a[SecureRandom.random_number(list.count)]
            $logger.debug "retwitting #{t.user.screen_name}: #{t.text}"
            begin
              # $twitter_client.update("#{t.text} //cc #{t.user.screen_name}")
              $twitter_client.retweet(t)
            rescue => e
              $logger.err("error tweeting #{t.text}: #{e.message}")
            end
            sleep(15)
          end
        end

      end
      def find_appsec(limit = 5)
        list = $twitter_client.search("#appsec")
        unless list.nil? || list.to_a.nil?
          (0..limit-1).each do |l|
            t = list.to_a[SecureRandom.random_number(list.count)]
            $logger.debug "retwitting #{t["from_user"]}: #{t["text"]}"
            begin
              # $twitter_client.update("#{t.text} //cc #{t.user.screen_name}")
              $twitter_client.retweet(t)
            rescue => e
              $logger.err("error tweeting #{t["text"]}: #{e.message}")
            end
            sleep(15)
          end
        end
      end

      def mark
        now = Time.now
        $logger.log("codiceinsicuro_bot is running with pid #{Process.pid}. Uptime is #{time_diff(@start_time, now)}")
      end

      def promote_latest
        return nil if @feed.nil? || @feed.size == 0
        post = @feed[0]
        m = "\"#{post[:title]}\" (#{post[:link]}) #blog #sicurezza #informatica."
        $logger.debug "#{m} - #{m.length}"
        begin
          $twitter_client.update(m)
          $logger.debug "latest tweet sent!"
        rescue => e
          $logger.err("error tweeting #{m}: #{e.message}")
        end
      end


      def time_diff(start_time, end_time)
        seconds_diff = (start_time - end_time).to_i.abs

        hours = seconds_diff / 3600
        seconds_diff -= hours * 3600

        minutes = seconds_diff / 60
        seconds_diff -= minutes * 60

        seconds = seconds_diff

        "h #{hours.to_s.rjust(2, '0')}:m #{minutes.to_s.rjust(2, '0')}:s #{seconds.to_s.rjust(2, '0')}"
      end
    end
  end
end


