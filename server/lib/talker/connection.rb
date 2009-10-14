require "eventmachine"
require "yajl"

module Talker
  class ProtocolError < RuntimeError; end
  
  class Connection < EM::Connection
    # TODO freeze constant strings

    attr_accessor :server, :room, :user
    
    # Called after connection is fully initialized and establied from EM.
    def post_init
      @parser = Yajl::Parser.new
      @parser.on_parse_complete = method(:message_parsed)
      @encoder = Yajl::Encoder.new
      
      @room = nil
      @user = nil
    end
    
    # Called when a JSON object in a message is fully parsed
    def message_parsed(message)
      Talker.logger.debug{to_s + "<<< " + message.inspect}
      
      case message["type"]
      when "connect"
        authenticate message["room"], message["user"], message["token"]
      when "message"
        broadcast_message message, message.delete("to")
      when "close"
        close
      when "ping"
        # ignore
      else
        error "Unknown message type: " + message["type"]
      end
    rescue ProtocolError => e
      error e.message
    rescue Exception => e
      Talker.logger.error("[Error] " + e.to_s + ": " + e.backtrace.join("\n"))
      error "Error processing command"
    end
    
    
    ## Message types
    
    def authenticate(room_name, user, token)
      if room_name.nil? || user.nil? || token.nil?
        raise ProtocolError, "Authentication failed"
      end
      
      if !user.is_a?(Hash) || !(user.key?("id") && user.key?("name"))
        raise ProtocolError, "You must specify your user id and name"
      end
      
      @server.authenticate(room_name, user["id"], token) do |success|
        
        if success
          begin
            @room = @server.rooms[room_name]
            @user = User.new(user)
            @user.token = token
            
            # Listen to message in the room
            @subscription = @room.subscribe(@user) { |message| send_data message }
            
            # Broadcast presence
            @room.presence "join", @user
            send_data %({"type":"connected"}\n)
          rescue SubscriptionError => e
            @subscription = @user = nil # do not pretend like user is connected
            error e.message
          end
        
        else
          error "Authentication failed"
        end
        
      end
    end
    
    def broadcast_message(obj, to)
      room_required!
      
      obj["user"] = @user.required_info
      obj["time"] = Time.now.to_i
      
      content = obj["content"]
      
      if Paster.pastable?(content) || obj.delete("paste")
        Paster.new(@user.token).paste(content) do |content, paste_url|
          obj["content"] = content
          obj["paste_url"] = paste_url
          send_message obj, to
        end
      else
        send_message obj, to
      end
    end
    
    def close
      room_required!
      
      if @subscription
        @subscription.unsubscribe
        @subscription = nil
      end
      
      if @user
        @room.presence("leave", @user)
        @user = nil
      end

      close_connection_after_writing
    end
    
    
    ## Helper methods
    
    def error(message)
      Talker.logger.debug {"#{to_s}>>>error: #{message}"}
      send_data(%Q|{"type":"error","message":"#{message}"}\n|)
      close
    end
    
    def to_s
      return "#{@user.name}##{@user.id}@#{@room.name}" if @user
      return "?@#{@room.name}" if @room
      "(?)@(?)"
    end
    
    
    ## EventMachine callbacks
    
    def receive_data(data)
      # continue passing chunks
      @parser << data
    rescue Yajl::ParseError => e
      error "Invalid JSON"
    end
    
    def unbind
      if @room
        @subscription.unsubscribe if @subscription
        @room.presence("idle", @user) if @user
      end
      @server.connection_closed(self)
    end
  
    private
      def room_required!
        raise ProtocolError, "Not connected to a room" unless @room
      end
      
      def send_message(message, to=nil)
        if to
          message["private"] = true
          @room.send_private_message to, message
        else
          @room.send_message message
        end
      end
  end
end