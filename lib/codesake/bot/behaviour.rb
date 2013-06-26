module Codesake
  module Bot
    class Behaviour

      def initialize(options={})
        @name = options[:name]
      end

      def say_hello
        puts "Hello world from #{@name}"
      end

    end
  end
end
