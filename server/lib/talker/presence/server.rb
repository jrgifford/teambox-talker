require "mq"
require "yajl"

module Talker
  module Presence
    class Server
      DEFAULT_TIMEOUT = 30.0 # sec
      
      attr_accessor :logger
      
      def initialize(persister, options={})
        @persister = persister
        @rooms = Hash.new { |rooms, name| rooms[name] = Room.new(name, @persister) }
        @queue = Queues.presence
        @sweeper = Sweeper.new(self, options[:timeout] || DEFAULT_TIMEOUT)
        @sweeper.start
        
        @parser = Yajl::Parser.new
        @parser.on_parse_complete = method(:presence_received)
      end
      
      def rooms
        @rooms.values
      end
      
      def start
        Talker.logger.info "Watching presence on queue #{@queue.name}"
        load
        
        @queue.subscribe do |message|
          @parser << message
        end
      end
      
      def stop(&callback)
        @queue.unsubscribe
        @sweeper.stop
        callback.call if callback
      end
    
      def load
        @persister.load do |room_id, user_info, state|
          room = @rooms[room_id]
          user = User.new(user_info)
          session = @rooms[room_id].new_session(user, state)
          
          Talker.logger.debug{"loaded connection: room##{room.name} => #{user.name} (#{session.state})"}
        end
      end

      def presence_received(message)
        Talker.logger.debug{"<<< " + message.inspect}
        
        type = message["type"]
        room = @rooms[message["room"].to_i]
        user = User.new(message["user"])
        time = message["time"]
        
        case type
        when "join"
          room.join user, time
        when "leave"
          room.leave user, time
        when "ping"
          room.ping user, time
        else
          Talker::Notifier.error "Wrong type of presence in message #{message.inspect}"
        end
      end
      
      def to_s
        "presence-server"
      end
    end
  end
end