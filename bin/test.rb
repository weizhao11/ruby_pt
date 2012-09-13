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

loginUrl = ['a.b.c.d']

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


