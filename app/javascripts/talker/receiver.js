// 1) Handles incoming events, messages, notices and errors in the browser log.
// 2) Updates list of users in the chat room..
Receiver = {
  // handles all incoming messages in a triage fashion eventually becoming an insertion in the log
  push: function(data, replay, linkToLogs) {
    if (data.type == null) return;
    
    if (typeof Receiver[data.type] == 'function'){
      var lastTime = $('#log p:last[time]').attr('time');
      if ($.inArray(data.type, ['message', 'join', 'leave']) > -1 && lastTime - data.time < -(5 * 60)){
        Receiver.timestamp(data.time, lastTime, linkToLogs);
      }
      Receiver[data.type](data, replay, linkToLogs);
      if (!replay) {
        ChatRoom.scroller.scrollToBottom();
        resizeLogElements();
        ChatRoom.notifier.push(data);
      }
    }else{
      console.info(JSON.encode(data, replay, index));
      console.error("*** Unable to handle data type: (" + data.type + ") with data.  Format may not be appropriate.");
    }
  },
  
  connected: function(data, replay) {
    $('#msgbox').focus();
  },
  
  users: function(data){
    $(data.users).each(function(){
      UserList.add(this);
    });
  },
  
  join: function(data, replay) {
    UserList.add(data.user, replay);
    
    var element = $('<tr/>').attr('author', data.user.name).addClass('received').addClass('notice').addClass('user_' + data.user.id).addClass('event')
      .append($('<td/>').addClass('author'))
      .append($('<td/>').addClass('message')
        .append($('<p/>').attr('time', data.time).html(data.user.name + ' has entered the room')));
    
    element.appendTo('#log');
  },
  
  leave: function(data, replay) {
    UserList.remove(data.user, replay);
    
    var element = $('<tr/>').attr('author', data.user.name).addClass('received').addClass('notice').addClass('user_' + data.user.id).addClass('event')
      .append($('<td/>').addClass('author'))
      .append($('<td/>').addClass('message')
        .append($('<p/>').attr('time', data.time).html(data.user.name + ' has left the room')));
    
    element.appendTo('#log');
  },
  
  close: function(data, replay){

  },
  
  back: function(data, replay) {
    $("#user_" + data.user.id).css('opacity', 1.0).removeClass('idle');
  },
  
  idle: function(data, replay) {
    $("#user_" + data.user.id).css('opacity', 0.5).addClass('idle');
  },
  
  message: function(data, replay, linkToLogs) {
    // format content appropriately
    if (data.paste && data.paste != 'null'){
      data.content = FormatHelper.formatPaste(data);
    } else {
      data.content = FormatHelper.text2html(data.content);
    }
    
    var last_row    = $('#log tr:last');
    var last_author = last_row.attr('author');
    
    
    if (linkToLogs){
      var url = '/rooms/' + data.room + '/logs/' + FormatHelper.getUrlDate(data.time) + '#' + data.time;
      var link_to_log = $('<a/>').attr('href', url).addClass('logs').html('view in logs');
    } else {
      var link_to_log = '';
    }
    
    if (last_author == data.user.name && last_row.hasClass('message') && !last_row.hasClass('private') && !data.private){ // only append to existing blockquote group
      last_row.find('blockquote')
        .append($('<p/>').attr('time', data.time).html(data.content).append(link_to_log));
    } else {
      var element = $('<tr/>')
        .attr('author', data.user.name)
        .addClass('received')
        .addClass('message')
        .addClass('user_' + data.user.id)
        .addClass('event')
        .addClass(data.user.id == currentUser.id ? 'me' : '')
        .addClass(linkToLogs ? 'logs' : '')
        .addClass(data.private ? 'private' : '')
          .append($('<td/>').addClass('author')
            .append('\n' + data.user.name + '\n')
            .append($('<img/>').attr('src', '/images/avatar_default.png').attr('alt', data.user.name).addClass('avatar'))
            .append($('<b/>').addClass('blockquote_tail').html('<!-- display fix --->')))
          .append($('<td/>').addClass('message')
            .append($('<blockquote/>')
              .append($('<p/>').attr('time', data.time)
                .html(data.content).append(link_to_log))));
      
      element.appendTo('#log');
    }
  },
  
  timestamp: function(time, lastTime, linkToLogs) {
    var element = $('<tr/>').addClass('timestamp').addClass(linkToLogs ? 'logs' : '');
    
    var date = FormatHelper.timestamp2date(time);
    var lastDate = FormatHelper.timestamp2date(lastTime);
    
    // Only show date if diff from last one
    if (lastDate == null || (date.getFullYear() != lastDate.getFullYear() ||
                             date.getMonth() != lastDate.getMonth() ||
                             date.getDate() != lastDate.getDate())
        ) {
      element
        .append($('<td/>').addClass('date')
          .append($('<div/>')
            .append($('<span/>').addClass('marker').html(
              '<b><!----></b><i><span class="date">' 
                + FormatHelper.getDate(time)
              + '</span><span class="month">'
                + FormatHelper.getMonth(time)
              + '</span></i>')
            )
          )
        );
    } else {
      element.append($('<td/>'));
    }
    
    element
      .append($('<td/>').addClass('time')
        .append($('<div/>')
          .append($('<span/>').addClass('marker').attr('time', time)
            .html('<b><!----></b><i>' + FormatHelper.toHumanTime(time) + '</i>')
          )
        )
      );
    
    element.appendTo('#log');
  }
}

UserList = {
  add: function(user, replay){
    if (replay) { return }
    
    if ($("#user_" + user.id).length < 1) {
      var presence = $('<li/>')
        .attr("id", "user_" + user.id)
        .attr('user_id', user.id)
        .attr('user_name', user.name)
        .html('<img alt="gary" src="/images/avatar_default.png" /> ' + user.name)
        .appendTo($('#people'));
        
      presence.animate({opacity: 1.0}, 400);
    }
  },
  
  remove: function(user, replay){
    if (replay){ return }
    
    $("#user_" + user.id).animate({opacity: 0.0}, 400, function(){ $(this).remove() });
  }
}