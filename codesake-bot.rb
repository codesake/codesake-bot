module Botolo
  module Bot
    class Behaviour
      def initialize(options={})
      end

      def find_scanwithdawn
        Twitter.search("#scanwithdawn").results.each do |tweet|
          puts "#{tweet.from_user}: #{tweet.text}"
        end
      end
      def say_hello
        $logger.log "hello"
      end

      def say_foo
        $logger.log "foo"
      end
    end
  end
end


