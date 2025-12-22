window.addEventListener('load', () => {
  Array.from(document.querySelectorAll('a.footnote')).forEach(foot => {
    foot.addEventListener('click', event => {
      let ref = document.getElementById(foot.getAttribute('href').substr(1));
      if (!('popover' in HTMLElement.prototype) || !ref) return;
      event.preventDefault();
      foot.classList.add('clicked');
      let popover = document.createElement('div');
      popover.classList.add('footnote-popover');
      popover.popover = 'auto';
      let inner = document.createElement('div');
      inner.innerHTML = ref.innerHTML;
      popover.appendChild(inner);
      document.body.appendChild(popover);
      popover.showPopover();
      popover.addEventListener('toggle', e => {
        if (e.newState === 'closed') {
          foot.classList.remove('clicked');
          popover.remove();
        }
      });
    });
  });
});
