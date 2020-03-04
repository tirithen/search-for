#!/usr/bin/env node

const {search} = require('./query');
const {getContentFor} = require('./scrape');
const {printMarkdown} = require('./printMarkdown');

const startsWithDash = /^-{2}[^\s]+/;
const query = process.argv.slice(2).filter((arg) => !startsWithDash.test(arg)).join(' ').trim();

if (!query) {
  console.log('Usage: search [QUERY]');
  process.exit(0);
}

search(query).then((results) => {
  const firstResult = results[0];
  getContentFor(firstResult.link)
    .then(printMarkdown)
    .catch((error) => {
      console.error(error.message);
      process.exit(1);
    });
}).catch((error) => {
  console.error(error.message);
  process.exit(1);
});
