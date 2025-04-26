# redislib

Haxe redis implementation

## example

```haxe
import redislib.Redis;

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
    // issue a custom command
    trace(redis.command("GET", ["key1",])); // outputs: "value1"
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
* HSETNX
* HSTRLEN
* HTTL
* PING
* SELECT
* SET / SETEX
* STRLEN

Issue a not supported command requires to call public function `command` with the specific command and parameters.

## installation

Using redislib source install.

```bash
haxelib git redislib https://github.com/Dreaded-Gnu/haxe-redis
```

Using redislib normal install

```bash
haxelib install redislib
```
