const LM = 'light', DM = 'dark', AU = 'auto';
const setTheme = (preference) => {
  let classList = document.body.classList;
  classList.remove(LM + '-mode', DM + '-mode');
  if (preference == LM) {
    classList.add(LM + '-mode');
  } else if (preference == DM) {
    classList.add(DM + '-mode');
  }
};

const orderDark = [AU, LM, DM];
const orderLight = [AU, DM, LM];
const newPreference = (oldpref) => {
  let mm = window.matchMedia;
  let list = mm && mm('(prefers-color-scheme: dark)').matches ? orderDark : orderLight;
  let idx = list.indexOf(oldpref) + 1;
  return list[idx % 3];
};

addEventListener('load', () => {
  const PT = 'theme-toggle';
  let toggle = document.getElementById(PT);
  let preference = localStorage.getItem(PT) || AU;
  toggle.innerText = preference;
  toggle.onclick = () => {
    let pref = preference;
    preference = newPreference(preference);
    setTheme(preference);
    localStorage.setItem(PT, preference);
    toggle.innerText = preference;
  };

  Array.from(document.querySelectorAll('.post-body a.footnote')).forEach(foot => {
    let ref = document.getElementById(foot.getAttribute('href').substr(1));
    if (ref) {
      foot.setAttribute('title', ref.innerText.trim());
    }
  });
});
