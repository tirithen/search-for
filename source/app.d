T cacheWrite(T)(string key, T data) {
	import std.file : File, mkdirRecurse;

	const directory = "~/.cache/search-for";
	const filename = directory ~ "/" ~ key;

	mkdirRecurse(directory);

	auto file = File(filename, "w");
	file.rawWrite(data);
	file.close();
}

import std.typecons : Nullable;
import core.time : Duration;

Nullable!T cacheRead(T)(string key, Duration maxAge = Duration.max) {
	import std.file : File, timeLastModified;
	import std.datetime.systime : Clock;

	const directory = "~/.cache/search-for";
	const filename = directory ~ "/" ~ key;

	Nullable!T nil;

	try {
		const modified = timeLastModified(filename);
		const today = Clock.currTime();
		if (today - modified > maxAge) {
			return nil;
		}

		T cached;

		auto file = File(filename, "r");
		file.rawRead(&cached);
		file.close();

		return cached;
	} catch (Exception exception) {
	}

	return nil;
}

const defaultUserAgent = "Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0";

struct SearchResult {
	string title;
	string description;
	string url;
}

SearchResult[] googleSearch(string query, string userAgent = defaultUserAgent) {
	const cacheKey = query ~ "|" ~ userAgent;
	const cacheResult = cacheRead!(SearchResult[])(cacheKey);
	if (!(cacheResult is null)) {
		return cacheResult;
	}

	SearchResult[] results;

	try {
		import std.uri : encode;
		import std.string : strip;

		import arsd.dom : Document;
		import arsd.http2 : HttpClient, Uri, HttpVerb;

		auto url = "https://www.google.com/search?q=" ~ query.encode;

		auto client = new HttpClient();
		client.userAgent = userAgent;

		auto request = client.navigateTo(Uri(url), HttpVerb.GET);
		auto response = request.waitForCompletion();

		auto document = new Document();
		document.parseGarbage(cast(string) response.content);

		foreach (element; document.querySelectorAll("div.rc")) {
			auto heading = element.querySelector("h3");
			auto description = element.querySelector(".st");
			auto link = element.querySelector("a");
			results ~= SearchResult(heading.innerText.strip,
					description.innerText.strip, link.getAttribute("href"));
		}
	} catch (Exception exception) {
	}

	cacheWrite(cacheKey, results);

	return results;
}

SearchResult[] duckduckgoSearch(string query, string userAgent = defaultUserAgent) {
	const cacheKey = query ~ "|" ~ userAgent;
	const cacheResult = cacheRead!(SearchResult[])(cacheKey);
	if (!(cacheResult is null)) {
		return cacheResult;
	}

	SearchResult[] results;

	try {
		import std.uri : encode;
		import std.string : strip;

		import arsd.dom : Document;
		import arsd.http2 : HttpClient, Uri, HttpVerb;

		auto url = "https://html.duckduckgo.com/html/?q=" ~ query.encode;

		auto client = new HttpClient();
		client.userAgent = userAgent;

		auto request = client.navigateTo(Uri(url), HttpVerb.GET);
		auto response = request.waitForCompletion();

		auto document = new Document();
		document.parseGarbage(cast(string) response.content);

		foreach (element; document.querySelectorAll(".result")) {
			auto heading = element.querySelector(".result__title");
			auto description = element.querySelector(".result__snippet");
			auto link = heading.querySelector("a");
			results ~= SearchResult(heading.innerText.strip,
					description.innerText.strip, link.getAttribute("href"));
		}
	} catch (Exception exception) {
	}

	cacheWrite(cacheKey, results);

	return results;
}

string getPageContent(string url, string userAgent = defaultUserAgent) {
	try {
		import std.string : strip;
		import std.regex : regex, replaceAll;

		import arsd.dom : Document;
		import arsd.http2 : HttpClient, Uri, HttpVerb;

		auto client = new HttpClient();
		client.userAgent = userAgent;

		auto request = client.navigateTo(Uri(url), HttpVerb.GET);
		auto response = request.waitForCompletion();

		auto document = new Document();
		document.parseGarbage(cast(string) response.content);

		foreach (selector; ["[role=\"main\"]", "main", "#main", "#content", "body"]) {
			auto element = document.querySelector(selector);
			if (element is null) {
				continue;
			}

			auto elementContent = element.innerText.strip;
			if (elementContent.length > 0) {
				const reduceNewLinePattern = regex(r"\n\s+\n", "g");
				return elementContent.replaceAll(reduceNewLinePattern, "\n\n");
			}
		}
	} catch (Exception exception) {
	}

	return "";
}

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
