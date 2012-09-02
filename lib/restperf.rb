require 'json'
require 'faraday'

module Rest
  module Perf

    API_PREFIX = "/api/sixin/3.0"

    ACTIONS = [
      :login
    ]

    class Bag
      @@bag = {}

      def self.insert(id, action, conn, result)
        @@bag[id] ||= {}
        @@bag[id][conn] = result
        puts "By Connection #{conn},  Actor #{id} finished #{action.to_s} at #{result} seconds"
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
      attr_reader :conn

      def initialize(id, conn)
        @id = id
        @conn = conn
      end

      def login
        t1 = Time.new
        response = @conn.get API_PREFIX + '/user/login'
        save(t1)
      end

      def perform(delay)
        begin
          ACTIONS.each do |action|
            send(action)
            sleep delay if not delay.nil? and delay > 0
          end
        rescue Exception => e
          print e.backtrace.join("\n")
        end
      end

      private
      def save(t1)
        t2 = Time.new
        result = t2 - t1
        Bag.insert(@id, caller.first[(caller.first.index("`")+1)...-1], @conn.url_prefix, result)
      end

    end
  end
end

