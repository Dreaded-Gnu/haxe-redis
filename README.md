# haxe-redis

Haxe redis implementation

## example

```haxe
import redis.Redis;

class Sample {
  /**
   * Main entry point
   */
  static function main()
  {
    var redis:Redis = new Redis("localhost", 6739, "", 0);
    // set some keys
    redis.set("key1", "value1");
    redis.set("key2", "value2");
    // fetch set keys
    trace(redis.get("key2")); // outputs: "value2"
    trace(redis.get("key1")); // outputs: "value1"
  }
}
```

## supported commands

Currently supported commands

* DEL
* GET
* HDEL
* HEXISTS
* HEXPIRE
* HEXPIREAT
* HEXPIRETIME
* HGET
* HGETALL
* HGETDEL
* HGETEX
* HINCRBY
* HINCRBYFLOAT
* HKEYS
* HLEN
* HMGET
* HMSET
* HPERSIST
* HPEXPIRE
* HPEXPIREAT
* HPEXPIRETIME
* HPTTL
* HSET
* PING
* SELECT
* SET / SETEX
* STRLEN

## installation

haxe-redis is currently not published to haxelib, so to install you've to use git install.

```bash
haxelib git haxe-redis https://github.com/Dreaded-Gnu/haxe-redis
```
