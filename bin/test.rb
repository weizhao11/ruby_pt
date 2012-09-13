#!/usr/bin/env ruby

require 'json'
require 'faraday_middleware'
#require 'mashify'
require File.dirname(__FILE__) + "/../lib/restperf"

def getConn(url)
  conn = Faraday.new(:url => url) do |faraday|
      faraday.request :multipart
      faraday.request  :url_encoded # form-encode POST
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      faraday.response :json, :content_type => /\bjson$/
      faraday.use :instrumentation
#      faraday.use Faraday::Response::Mashify
  end
#  puts "#{Faraday.lib_path} in current"
  conn
end

if ARGV.length < 1
  puts "Usage: ruby test.rb numberOfUser"
  exit
end


number_of_users = ARGV[0].to_i

puts "Starting #{number_of_users} users..."

threads = []

#loginUrl = ['http://123.125.47.196', 'http://ec2-23-20-72-177.compute-1.amazonaws.com']
#loginUrl = ['http://ec2-107-22-143-143.compute-1.amazonaws.com:8080']
#loginUrl = ['http://ec2-23-22-235-9.compute-1.amazonaws.com:8080']
loginUrl = ['http://23.21.65.62']
#loginUrl = ['http://10.3.24.189:8080']
#loginUrl = ['http://ec2-23-20-72-177.compute-1.amazonaws.com']

loginUrl.each do |x|
  1.upto(number_of_users) do |i|
    threads << Thread.new(i) do |li|
      Rest::Perf::Actor.new(li, getConn(x)).perform 3
    end
  end
end

puts "Waiting for users to finishe...\n"

threads.each {|t| t.join}

#puts Rest::Perf::Bag.info
output = JSON.pretty_generate(Rest::Perf::Bag.info) + "\n"
File.new("outputmas.#{number_of_users}.txt", "w").write(output)


