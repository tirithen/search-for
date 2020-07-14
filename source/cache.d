module searchfor.cache;

void cacheWrite(T)(string key, T data) {
  import std.file : write, mkdirRecurse;
  import std.base64 : Base64;
  import std.conv : to;
  import std.path : expandTilde;
  import msgpack : pack;

  const directory = "~/.cache/search".expandTilde;
  mkdirRecurse(directory);

  const filename = directory ~ "/" ~ Base64.encode(cast(ubyte[]) key);
  write(filename, pack(data));
}

import std.typecons : Nullable;
import core.time : Duration;

Nullable!T cacheRead(T)(string key, Duration maxAge = Duration.max) {
  import std.file : read, timeLastModified;
  import std.base64 : Base64;
  import std.conv : to;
  import std.datetime.systime : Clock;
  import std.path : expandTilde;
  import msgpack : unpack;

  const directory = "~/.cache/search".expandTilde;
  const filename = directory ~ "/" ~ Base64.encode(cast(ubyte[]) key);

  Nullable!T nil;

  try {
    const modified = timeLastModified(filename);
    const today = Clock.currTime();
    if (today - modified > maxAge) {
      return nil;
    }

    ubyte[] data = cast(ubyte[]) read(filename);
    T cached = data.unpack!T();

    return cast(Nullable!T) cached;
  } catch (Exception exception) {
  }

  return nil;
}
