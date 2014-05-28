$(document).ready(function(){
  toggled = false;
  $(".contact-button").on("click", function(e){
    toggled = !toggled;
    if(toggled){
      $("body").css("background", "#ababab");
      $(".hide-section").css("display", "none");
    } else {
      $("body").css("background", "#ddd");
      $(".hide-section").css("display", "true");
    }
    // $(".hide-section").slideToggle(100);
    $("#more-info").slideToggle(300);
  });
});