require 'json'
require 'faraday'
require 'faraday_middleware'
require 'digest/md5'

module Rest
  module Perf

    API_PREFIX = ""
    LIMIT_LENGTH = 50.freeze
    DEFAULT_APIKEY = "aaa1".freeze
    DEFAULT_SECKEY = "bbb1".freeze
    CALL_ID = "1.0".freeze
    PASSWORD = "123456".freeze
    USER1 = "user".freeze

    #token
    ACCESS_TOKEN = ""

    ACTIONS = [
      :loginrenren,
      :login,
      :loginfb,
      :profile_by_id
      :photo,
      :captcha,
      :register
      :unbindfacebook,
      :bindfacebook,
    ]

    class Bag
      @@bag = {}

      def self.insert(id, action, conn, result)
        @@bag[id] ||= {}
#        @@bag[id][conn] = result
        @@bag[id][action] = result
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
      attr_accessor :session_key
      attr_accessor :secret_key

      def initialize(id, conn)
        @id = id
        @conn = conn
      end

      def login
        t1 = Time.new
        pass = Digest::MD5.hexdigest(PASSWORD)
        response = @conn.post API_PREFIX + '/user/login' do |req|
          req.params[:api_key] = DEFAULT_APIKEY
          req.params[:call_id] = CALL_ID
          req.params[:password] = pass
          req.params[:user] = USER1
        end
        puts response.status.to_s
        puts response.body.to_s
        contents = JSON.parse response.body
        @session_key = contents["session_key"]
        @secret_key = contents["secret_key"]
        @user_id= contents["profile_info"]["user_id"]
        save(t1)

      end

      def loginfb
        t1 = Time.new
        response = @conn.post API_PREFIX + '/user/login/facebook' do |req|
          req.params[:api_key] = DEFAULT_APIKEY
          req.params[:call_id] = CALL_ID
          req.params[:access_token] = ACCESS_TOKEN
          req.params[:expires] = '6000'
          req.params[:sig] = genSig(req.params, DEFAULT_SECKEY)
        end

        puts response.status.to_s
        puts response.body.to_s
        contents = JSON.parse response.body
        @session_key = contents["session_key"]
        @secret_key = contents["secret_key"]
        @user_id= contents["profile_info"]["user_id"]
        save(t1)

      end

      def loginrenren
        t1 = Time.new
        pass = Digest::MD5.hexdigest(PASSWORD)

        response = @conn.post API_PREFIX + '/user/login/renren' do |req|
          req.params[:api_key] = DEFAULT_APIKEY
          req.params[:call_id] = CALL_ID
          req.params[:password] = pass
          req.params[:user] = '13810436416'
          req.params[:sig] = genSig(req.params, DEFAULT_SECKEY)
        end

        puts response.status.to_s
        contents = JSON.parse response.body
        @session_key = contents["session_key"]
        @secret_key = contents["secret_key"]
        save(t1)
      end

      def captcha
        t1 = Time.new
        response = @conn.post API_PREFIX + '/user/register/captcha' do |req|
          req.params[:api_key] = DEFAULT_APIKEY
          req.params[:call_id] = CALL_ID
          req.params[:user] = USER1
#          req.params[:action] = 'GET'
          req.params[:captcha] = '79775'
          req.params[:sig] = genSig(req.params, DEFAULT_SECKEY)
        end
        puts response.status.to_s
        puts response.body.to_s
        save(t1)

      end


      def register
        t1 = Time.new
        pass = Digest::MD5.hexdigest(PASSWORD)
        response = @conn.post API_PREFIX + '/user/register' do |req|
          req.params[:api_key] = DEFAULT_APIKEY
          req.params[:call_id] = CALL_ID
          req.params[:password] = pass
          req.params[:user] = USER1
          req.params[:captcha] = '79775'
          req.params[:sig] = genSig(req.params, DEFAULT_SECKEY)
        end
        puts response.status.to_s
        puts response.body.to_s
        save(t1)
      end

      def bindfacebook
        t1 = Time.new
        response = @conn.post API_PREFIX + '/user/binding/facebook' do |req|
          req.params[:api_key] = DEFAULT_APIKEY
          req.params[:call_id] = CALL_ID
          req.params[:access_token] = ACCESS_TOKEN
          req.params[:expires] = '6000'
          req.params[:session_key] = @session_key
          req.params[:sig] = genSig(req.params, @secret_key)
        end
        puts response.status.to_s
        puts response.body.to_s
        save(t1)
      end

      def unbindfacebook
        t1 = Time.new
        response = @conn.post API_PREFIX + '/user/binding/facebook/' + @user_id do |req|
          req.params[:api_key] = DEFAULT_APIKEY
          req.params[:call_id] = CALL_ID
          req.params[:action] = 'DELETE'
          req.params[:session_key] = @session_key
          req.params[:sig] = genSig(req.params, @secret_key)
        end
        puts response.status.to_s
        puts response.body.to_s
        save(t1)
      end

      def photo
        t1 = Time.new
        file = Faraday::UploadIO.new('chart.png', 'image/png')
        puts "-----------" + file.to_s
        temp = {}
        temp[:api_key] = DEFAULT_APIKEY
        temp[:call_id] = CALL_ID
        temp[:session_key] = @session_key
        img = Faraday::UploadIO.new('chart.png', 'image/png')
        response = @conn.post API_PREFIX + '/file/photo' do |req|
          req.params.merge!(temp)
          req.params[:sig] = genSig(temp, @secret_key)
          req.body = {:data => img}
        end
        puts response.status.to_s
        puts response.body.to_s
        save(t1)
      end

      def profile_by_id
        t1 = Time.new
        puts "sss: " + @user_id.to_s
        response = @conn.post API_PREFIX + '/user/profile/' + @user_id.to_s do |req|
          req.params[:api_key] = DEFAULT_APIKEY
          req.params[:call_id] = CALL_ID
          req.params[:action] = 'GET'
          req.params[:session_key] = @session_key
          req.params[:sig] = genSig(req.params, @secret_key)
        end
        puts response.status.to_s
        puts response.body.to_s
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
#        puts "#{caller.to_s}"
        Bag.insert(@id, caller.first[(caller.first.index("`")+1)...-1], @conn.url_prefix, result)
      end

      def genSig(params, seckey)
        paramsArray = params.sort
        sigSource = ""
        paramsArray.each do |k,v|
          if v.length > LIMIT_LENGTH then
            sigSource = sigSource + k.to_s + "="+ v[0..49]
          else
            sigSource = sigSource + k.to_s + "="+ v
          end
        end

        puts "===== " + sigSource
        return Digest::MD5.hexdigest(sigSource + seckey)
      end

    end
  end
end

