const marked = require('marked');
const TerminalRenderer = require('marked-terminal');

marked.setOptions({
  renderer: new TerminalRenderer()
});

module.exports.printMarkdown = function(markdown) {
  console.log(marked(markdown));
};
