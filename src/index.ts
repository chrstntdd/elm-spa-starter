import '@/styles/index.css';

import { Main } from '@/Main.elm';

const app = Main.embed(document.getElementById('elm-root'));

const throttle = (func, delay) => {
  let timeout = null;
  return (...args) => {
    if (!timeout) {
      timeout = setTimeout(() => {
        func.call(this, ...args);
        timeout = null;
      }, delay);
    }
  };
};

app.ports.infoForOutside.subscribe(msg => {
  /* PATTERN MATCH ON THE INFO FOR OUTSIDE */
  switch (msg.tag) {
    case 'SaveModel':
      /* EVENTUALLY PERSIST THE MODEL TO SESSION STORAGE */
      const model = msg.data;
      window.sessionStorage.setItem('persisted-session', JSON.stringify(model));
      break;
    case 'ScrollTo':
      const element = document.getElementById(msg.data);
      window.scroll({
        top: element.offsetTop,
        left: 0,
        behavior: 'smooth'
      });
      break;
    case 'ErrorLogRequested':
      console.error(msg.data);
      break;
    default:
      console.log('default branch hit');
  }
});

/**
 * Wont be necessary in 0.19 with https://github.com/elm/browser which
 * should provide a first class solution for this feature instead
 * of using ports to get `screenData`.
 */
const sendScreenData = () => {
  const screenData = {
    scrollTop:
      window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0,
    pageHeight: Math.max(
      document.body.scrollHeight,
      document.body.offsetHeight,
      document.documentElement.clientHeight,
      document.documentElement.scrollHeight,
      document.documentElement.offsetHeight
    ),
    viewportHeight: document.documentElement.clientHeight,
    viewportWidth: document.documentElement.clientWidth
  };
  app.ports.infoForElm.send({ tag: 'ScrollOrResize', data: screenData });
};

(() => {
  sendScreenData();
  window.addEventListener('scroll', throttle(sendScreenData, 100));
  window.addEventListener('resize', throttle(sendScreenData, 100));
})();
