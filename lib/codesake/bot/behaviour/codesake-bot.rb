module Codesake
  module Bot
    class Behaviour
      def initialize(options={})

      end

      def find_scanwithdawn
        puts Twitter.search("#scanwithdawn").results
      end
    end
  end
end


