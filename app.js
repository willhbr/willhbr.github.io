$(document).ready(function(){
  toggled = false;
  $(".contact-button").on("click", function(e){
    toggled = !toggled;
    if(toggled){
      $("body").css("background", "#ababab");
    } else {
      $("body").css("background", "#ddd");
    }
    $(".hide-section").slideToggle(100);
    $("#more-info").slideToggle(300);
  });
});