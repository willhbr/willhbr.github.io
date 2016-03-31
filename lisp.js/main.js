function println() {
  var resultField = document.getElementById('result');
  var res = '';
  for(var i = 0; i < arguments.length; i++) {
    if(i !== 0) {
      res += ' ';
    }
    res += arguments[i];
  }
  resultField.innerHTML += res + '\n';
}

var doRun = function() {
  var text = document.getElementById('repl').innerHTML;
  document.getElementById('result').innerHTML = '';
  try {
    var atoms = parseProgram(text.trim());
    var code = '';
    for(var i = 0; i < atoms.length; i++) {
      code += generate(atoms[i]) + '\n';
    }
    document.getElementById('code-res').innerHTML = code;
    var result = eval(code);
    if(result !== undefined) {
      println('--');
      println(result);
    }
  } catch (err) {
    println(err);
  }
}

document.getElementById('run').onclick = doRun

var repl = document.getElementById('repl');
document.onkeydown = function(e) {
  if(e.keyCode === 9) {
    return false;
  } else if(e.keyCode === 13 && e.ctrlKey) {
    doRun();
    return false;
  }
}