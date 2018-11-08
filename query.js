const {join} = require('path');
const google = require('google');

const Cache = require('promised-cache');
const cache = new Cache(join(__dirname, '.cache', 'search'), 3600 * 1000);

module.exports.NoResults = class NoResults extends Error {
  constructor(message) {
    super(message || 'No results found');
  }
};

module.exports.search = function search(query, disableCache = false) {
  return new Promise(async (resolve, reject) => {
    const cachedResult = disableCache ? undefined : await cache.get(query);
    if (cachedResult) {
      resolve(cachedResult);
    } else {
      google(query, (error, result) => {
        if (error) {
          reject(error);
        } else if (Array.isArray(result.links) && result.links.length > 0) {
          resolve(result.links);
          if (!disableCache) {
            cache.set(query, result.links);
          }
        } else {
          reject(new NoResults(`No results found for: ${query}`));
        }
      });
    }
  });
};
