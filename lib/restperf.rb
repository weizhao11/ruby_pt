
module perf
  module rest
    
    ACTIONS = []

    class Bag
      @@bag = {}

      def self.insert(id, action, result)
        @@bag[id] ||= {}
        @@bag[id][action] = result
        puts "Actor #{id} finished #{action.to_s} at #{result} seconds"
      end

      def self.info
        @@bag
      end

      def self.reset
        @@bag = {}
      end
    end

    class Actor
      attr_reader :id

      def initialize(id)
        @id = id
        @failed = false
      end 
    end
  end
end

