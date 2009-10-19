module Talker
  module Queues
    CHANNEL_PREFIX = "talker.channel".freeze
    USER_CHANNEL_PREFIX = "talker.connection".freeze
    
    def self.topic
      MQ.topic("talker.chat")
    end
    
    def self.presence
      MQ.queue("talker.presence", :durable => true)
    end

    def self.logger
      MQ.queue("talker.log", :durable => true)
    end
    
    def self.create
      presence.bind(topic, :key => "talker.room.*")
      logger.bind(topic, :key => "talker.room.*")
    end
  end
end