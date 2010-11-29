class Room < ActiveRecord::Base
  UUID_GENERATOR = UUID.new
  
  has_many :events, :dependent => :destroy
  has_many :connections, :as => :channel, :dependent => :destroy
  has_many :users, :through => :connections
  has_many :guests, :class_name => "User", :dependent => :destroy
  has_many :attachments, :class_name => "::Attachment", # FIX class w/ Paperclip::Attachment
                         :dependent => :destroy
  has_many :feeds, :dependent => :destroy
  has_many :permissions, :dependent => :destroy
  belongs_to :account
  
  validates_presence_of   :name
  validates_uniqueness_of :name, :scope => :account_id
  
  validates_presence_of   :account_id
  validate_on_create      :respect_limit
  
  named_scope :with_permission, proc { |user|
    if user.admin
      {}
    else
      { :conditions => ["private = 0 OR id IN (?)", user.permissions.map(&:room_id)] }
    end
  }
  named_scope :private, :conditions => { :private => true }
  named_scope :public, :conditions => { :private => false }
  
  attr_accessible :name, :description, :access, :invitee_ids
  
  attr_writer :invitee_ids
  after_save :update_permissions
  
  
  def create_public_token!
    self.public_token = ActiveSupport::SecureRandom.hex(3)
    self.opened_at = Time.now
    save(false)
    public_token
  end
  
  def clear_public_token!
    self.public_token = nil
    save(false)
  end
  
  def guest_allowed?
    !!public_token
  end
  
  def access=(v)
    self.private = (v == "private")
  end
  
  def access
    self.private ? "private" : "public"
  end
  
  def public
    !self.private
  end
  
  def to_json(options = {})
    super(options.merge(:only => [:name, :id]))
  end
  
  def send_message(messages, options={})
    can_paste = options.delete(:paste) != false

    events = [messages].flatten.map do |message|
      event = { :id => UUID_GENERATOR.generate(:compact), :type => "message", :content => message, :user => User.talker, :time => Time.now.to_i }.merge(options)
      
      # Paste the message if required
      if can_paste
        event[:content] = Paste.filter(message) do |paste|
          event[:paste] = paste
        end
      end
      
      event
    end
    
    publish *events
    messages.is_a?(Array) ? events : events.first
  end
  
  def publish(*events)
    Connection.publish events.map(&:to_json).join("\n"), "room", id
  end
  
  def to_s
    "#{name.inspect}@#{account.subdomain}"
  end
  
  private
    def update_permissions
      return unless @invitee_ids
      
      if self.public
        @invitee_ids = [] # force update even if none is selected
      end
      
      permissions.update_access @invitee_ids
    end
    
    def respect_limit
      if self.private && !account.features.private_rooms
        errors.add :base, "Your current plan do not allow private rooms. Upgrade your plan to crete a private room."
      end
    end
end
