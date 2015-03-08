require 'json'
require 'socket'
require 'websocket/driver'
require 'thread'

# Adapted from https://github.com/mackwic/slack-rtmapi

module Houston
  module Slack
    class Driver
      attr_accessor :stop
      
      def initialize
        @queue = Queue.new
        @has_been_init = false
        @stop = false
        @callbacks = {}
      end
      
      VALID = [:open, :message, :error].freeze
      def on(type, &block)
        unless VALID.include? type
          raise ArgumentError.new "Client#on accept one of #{VALID.inspect}"
        end
        
        callbacks[type] = block
      end
      
      def send(data)
        data[:id] ||= SecureRandom.random_number 9999999
        queue.push MultiJson.dump(data)
        data
      end
      
      # This init has been delayed because the SSL handshake is a blocking and
      # expensive call
      def connect_to(url)
        raise "Already been init" if @has_been_init
        url = URI(url)
        raise ArgumentError.new ":url must be a valid websocket secure url!" unless url.scheme == "wss"
        
        @socket = OpenSSL::SSL::SSLSocket.new(TCPSocket.new url.host, 443)
        socket.connect # costly and blocking !
        
        internalWrapper = (Struct.new :url, :socket do
          def write(*args)
            self.socket.write(*args)
          end
        end).new url.to_s, socket
        
        # this, also, is costly and blocking
        @driver = WebSocket::Driver.client internalWrapper
        driver.on :open do
          @connected = true
          unless callbacks[:open].nil?
            callbacks[:open].call
          end
        end
        
        driver.on :error do |event|
          @connected = false
          unless callbacks[:error].nil?
            callbacks[:error].call
          end
        end
        
        driver.on :message do |event|
          data = JSON.parse event.data
          unless callbacks[:message].nil?
            callbacks[:message].call data
          end
        end
        
        driver.start
        @has_been_init = true
      end
      
      def connected?
        @connected || false
      end
      
      # All the polling work is done here
      def inner_loop
        return if @stop
        
        begin
          # slack-rtmapi had `socket.readpartial 4096`
          # but this is a blocking call and prevents us from
          # sending message until we've received one.
          while data = socket.read_nonblock(4096)
            driver.parse data unless data.nil? or data.empty?
          end
        rescue IO::WaitReadable
          # we're done here
        end
        
        begin
          while messsage = queue.pop(true)
            driver.text messsage
          end
        rescue ThreadError
          # we're done here
        end
      end
      
      def main_loop
        loop do
          inner_loop
          sleep 0.5
        end
      end
      
    private
      attr_reader :url, :queue, :socket, :driver, :callbacks
      
    end
  end
end
