require "mq"
require "yajl"

module Talker
  module Presence
    class Server
      attr_accessor :logger
    
      def initialize(persister)
        @persister = persister
      
        @rooms = Hash.new { |rooms, name| rooms[name] = Room.new(name) }
        @queue = Queues.presence
      
        @parser = Yajl::Parser.new
        @parser.on_parse_complete = method(:presence_received)
      end
    
      def start
        Talker.logger.info "Watching presence on queue #{@queue.name}"
        load
      
        @queue.subscribe do |message|
          @parser << message
        end
      end
      
      def stop
        @queue.unsubscribe
      end
    
      def load
        @persister.load do |room_id, user|
          Talker.logger.debug{"loaded connection: room##{room_id} => #{user['name']}"}
          @rooms[room_id] << User.new(user)
        end
      end

      def presence_received(message)
        Talker.logger.debug{message.inspect}
        
        type = message["type"]
        room = @rooms[message["room"]]
        user = User.new(message["user"])
        
        case type
        when "join"
          unless room.present?(user)
            room.join user
            @persister.store(room.name, user.id)
          end
        when "leave"
          if room.present?(user)
            room.leave user
            @persister.delete(room.name, user.id)
          end
        else
          Talker.logger.error "Wrong type of presence in message " + message.inspect
        end
        
        Talker.logger.debug{"room ##{room.name} users: " + room.users.map { |u| u.name }.join(", ")}
      end
      
      def to_s
        "presence-server"
      end
    end
  end
end