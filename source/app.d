module searchfor.app;

import searchfor.cache : cacheRead, cacheWrite;
import searchfor.search : search, SearchResult;

string getContent(string url) {
	import core.time : days;
	import searchfor.content : getPageContent;

	string content;

	const cachedContent = cacheRead!string(url, 1.days);

	if (cachedContent.isNull) {
		content = getPageContent(url);
		if (content.length > 0) {
			cacheWrite(url, content);
		}
	} else {
		content = cast(string) cachedContent.get;
	}

	return content;
}

string getQuery(string[] argv) {
	import std.array : join;
	import std.algorithm.searching : startsWith;

	string[] queryParts;
	foreach (argument; argv[1 .. $]) {
		if (!argument.startsWith("--")) {
			queryParts ~= argument;
		}
	}

	return join(queryParts, " ");
}

void main(string[] argv) {
	import searchfor.options : getOptionsOrPrintHelp;

	auto options = getOptionsOrPrintHelp(argv);

	auto query = getQuery(argv);

	auto searchResults = search(query, options.engine);
	if (searchResults.length == 0) {
		throw new Error("No search results found for query: " ~ query);
	}

	string content;
	string source;
	foreach (searchResult; searchResults) {
		source = searchResult.url;
		content = getContent(source);
		if (content.length > 0) {
			break;
		}
	}

	import arsd.terminal : Terminal, ConsoleOutputType, Color;
	import std.stdio;

	auto terminal = Terminal(ConsoleOutputType.linear);
	terminal.color(Color.white, Color.green);
	terminal.writeln("Source: ", source, "\n");
	terminal.color(Color.DEFAULT, Color.DEFAULT);
	terminal.writeln(content);
}
