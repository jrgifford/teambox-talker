$(function() {
  Chat.scrollToBottom();
  Chat.log = $("#log");
  Chat.newMessageElement = $("#message");
  Chat.newMessageUrl = $("#msgForm").attr("action");
  Chat.newMessage();
  
  $("#msgbox").
    keydown(function(e) {
      if (e.which == 13) {
        Chat.send(this.value);
        Chat.newMessage();
        return false;
      }
    }).
    keyup(function(e) {
      if (e.which == 32) { // space
        Chat.send(this.value);
      } else {
        Chat.sendLater(this.value);
      }
    }).
    focus();
});

var Chat = {
  messages: {},
  currentMessage: null,
  
  sendLater: function(data, cond) {
    if (this.sendTimeout) clearTimeout(this.sendTimeout);
    this.sendTimeout = setTimeout(function() {
      Chat.send(data);
    }, 400);
  },
  
  send: function(data) {
    if (this.sendTimeout) clearTimeout(this.sendTimeout);
    this.enqueue(data);
  },
  
  newMessage: function() {
    if (this.currentMessage) this.currentMessage.createElement();
    this.currentMessage = new Message(currentUser.login);
    this.messages[this.currentMessage.uuid] = this.currentMessage;
    
    // Move the new message form to the bottom
    this.newMessageElement.
      appendTo(Chat.log).
      find("form").reset().
      find("textarea").focus();
    
    this.scrollToBottom();
  },
  
  receive: function(uuid, from, content) {
    console.info("Received: message #" + uuid);
    var message = this.messages[uuid];
    if (!message) {
      message = this.messages[uuid] = new Message(from, uuid);
      messages.createElement();
    }

    message.update(content);

    this.scrollToBottom();
  },
  
  enqueue: function(data) {
    this.currentMessage.content = data;
    this.dequeue();
  },
  
  dequeue: function() {
    var message = this.currentMessage;
    $.post(this.newMessageUrl, { uuid: message.uuid, message: message.content });
  },

  scrollToBottom: function() {
    window.scrollTo(0, document.body.clientHeight);
  }
};

function Message(from, uuid) {
  this.from = from;
  this.uuid = uuid || Math.uuid();
  this.elementId = "#message-" + this.uuid;
}

Message.prototype.update = function(content) {
  this.content = content;
  this.element.find(".content").html(content);
}

Message.prototype.createElement = function() {
  // Create of find the message HTML element
  this.element = Chat.log.find(this.elementId);
  if (this.element.length == 0) {
    this.element = $("<tr/>").
      addClass("event").
      addClass("message").
      attr("id", this.elementId).
      append($("<td/>").addClass("author").html(this.from)).
      append($("<td/>").addClass("content").html(this.content)).
      appendTo(Chat.log);
  }
  return this.element;
}