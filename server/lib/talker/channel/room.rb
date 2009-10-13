module Talker
  class SubscriptionError < RuntimeError; end

  module Channel
    class Room < MessageChannel
      def initialize(name)
        super(name)
        @presence = Queues.presence
      end
      
      def subscribe(user, &callback)
        queue = user_queue(user.id)
        
        if queue.subscribed?
          raise SubscriptionError, "#{user.name} is already connected this room. " +
                                   "A user can have only one active connection to a room."
        end
        
        # Force re-creation of the queuer in case it was delete by presence server.
        queue.reset
        
        queue.bind(@exchange).subscribe(&callback)
      end
      
      def presence(type, user)
        publish_as_json @presence, :type => type, :room => name, :user => user.info
      end
    end
  end
end