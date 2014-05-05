$(document).ready(function(){
  $("#contact-button").on("click", function(e){
    $(".hide-section").slideToggle(100);
    $("#more-info").slideToggle(300);
  });
});