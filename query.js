const {join} = require('path');
const googleIt = require('google-it');

const Cache = require('promised-cache');
const cache = new Cache(join(__dirname, '.cache', 'search'), 3600 * 1000);

class NoResults extends Error {
  constructor(message) {
    super(message || 'No results found');
  }
};

module.exports.NoResults = NoResults;

module.exports.search = function search(query, disableCache = false) {
  return new Promise(async (resolve, reject) => {
    const cachedResult = disableCache ? undefined : await cache.get(query);
    if (cachedResult) {
      resolve(cachedResult);
    } else {
      googleIt({query, 'no-display': true}).then((results) => {
        if (Array.isArray(results) && results.length > 0) {
          resolve(results);
          if (!disableCache) {
            cache.set(query, results);
          }
        } else {
          reject(new NoResults(`No results found for: ${query}`));
        }
      }).catch(() => {reject(new NoResults(`No results found for: ${query}`))});
    }
  });
};
