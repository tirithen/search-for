module searchfor.cache;

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
