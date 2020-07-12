module searchfor.app;

import searchfor.engines.google : googleSearch;
import searchfor.content : getPageContent;

void main(string[] argv) {
	import std.stdio;
	import std.array : join;

	auto query = join(argv[1 .. $], " ");
	auto results = googleSearch(query);
	if (results.length == 0) {
		throw new Exception("No results found");
	}

	auto content = getPageContent(results[0].url);
	writeln("Showing result from: ", results[0].url, "\n");
	writeln(content);
}
