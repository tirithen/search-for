module searchfor.options;

import searchfor.search : SearchEngine;

struct Options {
  SearchEngine engine = SearchEngine.duckduckgo;
}

Options getOptionsOrPrintHelp(string[] argv) {
  import std : getopt, defaultGetoptPrinter;
  import core.stdc.stdlib : exit;

  auto options = Options();

  auto helpInformation = getopt(argv, "engine|e",
      "[duckduckgo|google] Search engine to use (default duckduckgo)", &options.engine);

  if (helpInformation.helpWanted) {
    defaultGetoptPrinter("Usage: search [FLAG]... QUERY...\n\nSearch the web from the terminal.\n\nOptions:",
        helpInformation.options);
    exit(0);
  }

  return options;
}
