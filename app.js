var options = [
  'Massive nerd',
  'Podcast junkie',
  'Rails developer',
  'Allergic to Javascript',
  'Ex-Pebble wearer',
  "'Software engineer'",
  'Student',
  '<i>Shodan</i>',
  'Has a website',
  'Tech enthusiast',
  'Stock Android evangelist',
  "Doesn't really like Java",
  'Beard owner',
  'Programming language connoisseur'
];

var me = document.getElementById('me-description');
if (me != null) {
  var out = '';
  for (var i = 0; i < 3; i++) {
    var index = Math.floor(Math.random() * options.length);
    var str = options.splice(index, 1)[0];
    out += str + '. ';
  }
  me.innerHTML = out;
}
