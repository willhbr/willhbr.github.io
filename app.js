var options = [
  'Massive nerd',
  'Podcast junkie',
  'Allergic to JavaScript',
  'Ex-Pebble wearer',
  'Software engineer',
  'Employed',
  '<i>Nidan</i>',
  'Has a website',
  'Tech enthusiast',
  'Stock Android evangelist',
  "Doesn't really like Java",
  'Beard owner',
  'Programming language connoisseur',
  'Pun enthusiast',
  'SRE @ Google',
  'Batteries included',
  'Opinion sharer',
  'Can close Vim',
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
