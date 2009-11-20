Talker.ImageFormatter = function() {
  var self = this;
  
  self.onMessageReceived = function(event){
    var image_expression = /(^https?:\/\/[^\s]+\.(?:gif|png|jpeg|jpg)$)/gi;
    var image_match = event.content.match(image_expression);
    
    if ($('#talker_image_preloading_div').length == 0){
      $("<div/>").attr('id', 'talker_image_preloading_div')
        .css({position:'absolute', top: '-100px', left: '-100px', height: '100px', width: '100px', overflow: 'hidden'})
        .appendTo(document.body);
    }
    
    if (image_match){
      var fallback = $('<a/>').attr('href', image_match[0]).attr('target', '_blank').html(image_match[0]);
      Talker.insertMessage(event, fallback);
      
      var img = $('<img/>').load(function(){
        $(this).remove();
        
        // detect size of last image.
        var imageForHeight = new Image();
        imageForHeight.src = image_match[0];

        window.setTimeout(function() { // give it time to figure out the height of the image.
          fallback.replaceWith(
                '<a href="' 
              + image_match[0]
              + '" target="_blank"><img src="' 
              + image_match[0]
              + '" style="max-height: 300px; max-width: ' + Talker.getMaxContentWidth() + ';" class="from_url" />'
              + '</a>'
          );
          
          Talker.trigger('MessageInsertion', event);
          
          Talker.trigger('Nudge', imageForHeight.height + 50); // + 50 for borders and container margins.
        }, 10);
      });
    
      $('#talker_image_preloading_div').append(
        img.attr('src', image_match[0])
      );

      return false;
    }
  }
  
  self.onMessageInsertion = function() {
    var maxWidth = Talker.getMaxContentWidth();
    
    Talker.getLastRow().find("img[class='from_url']").each(function(){
      $(this).css({'max-width': 'auto'});
      $(this).css({'max-width': maxWidth + 'px'});
    });
  }
  
  self.onResize = function() {
    var maxWidth = Talker.getMaxContentWidth();
    
    $("#log img[class='from_url']").each(function(){
      $(this).css({'max-width': 'auto'});
      $(this).css({'max-width': maxWidth + 'px'});
    });
  }
};
