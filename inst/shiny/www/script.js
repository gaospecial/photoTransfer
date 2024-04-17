Shiny.addCustomMessageHandler('triggerZoom', function(message) {
  $('#imageDisplay').zoom();
});

Shiny.addCustomMessageHandler('focusImageLabel', function(message){
  $('#imageLabel').focus();
});
