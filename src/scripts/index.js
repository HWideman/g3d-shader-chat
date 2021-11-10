import '../styles/index.scss';
import Main from './main';

if (process.env.NODE_ENV === 'development') {
  require('../index.html');
}

window.onresize = () => {
  Main.onresize();
};

Main.init();

let numClicks = 0;
let singleClickTimer;
const handleClick = () => {
  numClicks++;
  if (numClicks === 1) {
    singleClickTimer = setTimeout(() => {
      numClicks = 0;
    }, 300);
  } else if (numClicks === 2) {
    clearTimeout(singleClickTimer);
    numClicks = 0;
  }
};

document.addEventListener("click", handleClick);

console.log('webpack starterkit');
