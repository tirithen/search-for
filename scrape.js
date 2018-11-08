const {join} = require('path');
const puppeteer = require('puppeteer');
const turndownService = new require('turndown')();

const Cache = require('promised-cache');
const cache = new Cache(join(__dirname, '.cache', 'content'), 3600 * 1000);

module.exports.NoContent = class NoContent extends Error {
  constructor(message) {
    super(message || 'No content found');
  }
};

module.exports.getContentFor = function getContentFor(url, disableCache = false) {
  return new Promise(async (resolve, reject) => {
    const cachedContent = disableCache ? undefined : await cache.get(url);
    if (cachedContent) {
      resolve(cachedContent);
    } else {
      const browser = await puppeteer.launch({args: ['--no-sandbox', '--disable-setuid-sandbox']});
      const page = await browser.newPage();
      await page.goto(url);

      const html = await page.evaluate(() => {
        function cleanContent(content) {
          const list = content.querySelectorAll('script,style,link');
          list.forEach((element) => {
            element.parentElement.removeChild(element);
          });
        }

        let contentHTML;
        const MAIN_CONTENT_SELECTORS = '[role="main"],main,#main,#content,#main-content,.main,.content,body';

        const selectors = MAIN_CONTENT_SELECTORS.trim().split(/\s*,+\s*/);
        let content;
        for (let index = 0;  index < selectors.length; index++) {
          const selector = selectors[index];
          const content = document.querySelector(selector);
          if (content) {
            cleanContent(content);
            contentHTML = content.innerHTML;
            break;
          }
        }

        return contentHTML;
      });

      const markdown = turndownService.turndown(html);

      if (markdown) {
        resolve(markdown);
        if (!disableCache) {
          cache.set(url, markdown);
        }
      } else {
        reject(new NoContent(`No content found for: ${url}`));
      }

      browser.close();
    }
 });
};
