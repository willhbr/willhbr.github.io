var options = [
  "Massive nerd",
  "Podcast junkie",
  "Web developer",
  "Allergic to Javascript",
  "Pebble wearer",
  "'Software engineer'",
  "Student",
  "<i>Shodan</i>",
  "Can use Vim",
  "Has a website",
  "App developer",
  "Tech enthusiast",
  "Stock Android evangelist"
];

var images = [
  "http://i.imgur.com/V32r4Wa.jpg",
  "http://i.imgur.com/EGAUTMC.jpg",
  "http://i.imgur.com/qBTY8ze.jpg"
]

var me = document.getElementById("me-description");
if(me != null) {
  var out = "";
  for(var i = 0; i < 3; i++) {
    var index = Math.floor(Math.random() * options.length);
    var str = options.splice(index, 1)[0];
    if(i < 2) {
        out += str + ". ";
    } else {
        out += str + ".";
    }
  }
  me.innerHTML = out;
}

if(true) {
  var index = Math.floor(Math.random() * images.length);
  document.documentElement.style.background = "url(" + images[index] + ") no-repeat center center fixed";
}
