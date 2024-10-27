package test;

import utest.Assert;
import redis.Redis;

class RedisTestHashmap extends utest.Test {
  private var redis:Redis;

  /**
   * Setup test
   */
  public function setup():Void {
    this.redis = new Redis("localhost", 6379, "eYVX7EwVmmxKPCDmwMtyKVge8oLd2t81", 0);
    this.redis.connect();
    this.redis.flushdb();
  }

  /**
   * Teardown test
   */
  public function teardown():Void {
    this.redis.disconnect();
  }

  /**
   * Test hdel
   */
  public function testHdel():Void {
    Assert.equals(1, this.redis.hset("myhash", "field1", "Hello"));
    Assert.equals(2, this.redis.hset("myhash", "field2", "Hi", "field3", "World"));
    Assert.equals(1, this.redis.hdel("myhash", "field1"));
    Assert.equals(null, this.redis.hget("myhash", "field1"));
    Assert.equals(0, this.redis.hdel("myhash", "field1"));
    Assert.equals(2, this.redis.hdel("myhash", "field2", "field3"));
    Assert.equals(null, this.redis.hget("myhash", "field2"));
    Assert.equals(null, this.redis.hget("myhash", "field3"));
    Assert.equals(0, this.redis.hdel("myhash", "field2", "field3"));
  }

  /**
   * Test hexists
   */
  public function testHexists():Void {
    Assert.equals(1, this.redis.hset("myhash", "field1", "Hello"));
    Assert.equals(2, this.redis.hset("myhash", "field2", "Hi", "field3", "World"));
  }

  /**
   * Test hexpire
   */
  public function testHexpire():Void {
    Assert.equals(3, this.redis.hset("myhash", "field1", "Hello", "field2", "World", "field3", "Bar"));
    var a:Array<Dynamic> = this.redis.hexpire("myhash", 300, "", "field1", "field2");
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    a = this.redis.hexpiretime("myhash", "field1", "field2", "field3", "field4");
    Assert.equals(4, a.length);
    Assert.notEquals(0, a[0]);
    Assert.notEquals(-1, a[0]);
    Assert.notEquals(0, a[1]);
    Assert.notEquals(-1, a[1]);
    Assert.equals(-1, a[2]);
    Assert.equals(-2, a[3]);
  }

  /**
   * Test hexpireat
   */
  public function testHexpireat():Void {
    Assert.equals(3, this.redis.hset("myhash", "field1", "Hello", "field2", "World", "field3", "Bar"));
    var timestamp:Int = Std.int(Sys.time()) + 3600;
    var a:Array<Dynamic> = this.redis.hexpireat("myhash", timestamp, "", "field1", "field2");
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    a = this.redis.hexpiretime("myhash", "field1", "field2", "field3", "field4");
    Assert.equals(4, a.length);
    Assert.equals(timestamp, a[0]);
    Assert.equals(timestamp, a[1]);
    Assert.equals(-1, a[2]);
    Assert.equals(-2, a[3]);
  }

  /**
   * Test hexpiretime
   */
  public function testHexpiretime():Void {
    Assert.equals(3, this.redis.hset("myhash", "field1", "Hello", "field2", "World", "field3", "Bar"));
    var a:Array<Dynamic> = this.redis.hexpire("myhash", 300, "", "field1", "field2");
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    a = this.redis.hexpiretime("myhash", "field1", "field2", "field3", "field4");
    Assert.equals(4, a.length);
    Assert.notEquals(0, a[0]);
    Assert.notEquals(-1, a[0]);
    Assert.notEquals(0, a[1]);
    Assert.notEquals(-1, a[1]);
    Assert.equals(-1, a[2]);
    Assert.equals(-2, a[3]);
  }

  /**
   * Test hget
   */
  public function testHget():Void {
    Assert.equals(1, this.redis.hset("myhash", "field1", "Hello"));
    Assert.equals(2, this.redis.hset("myhash", "field2", "Hi", "field3", "World"));
    Assert.equals("Hello", this.redis.hget("myhash", "field1"));
    Assert.equals("Hi", this.redis.hget("myhash", "field2"));
    Assert.equals("World", this.redis.hget("myhash", "field3"));
    Assert.equals(null, this.redis.hget("nonexistant", "asdf"));
    Assert.equals(null, this.redis.hget("myhash", "asdf"));
  }

  /**
   * Test hgetall
   */
  public function testHgetall():Void {
    Assert.equals(1, this.redis.hset("myhash", "field1", "Hello"));
    Assert.equals(2, this.redis.hset("myhash", "field2", "Hi", "field3", "World"));
    var a:Array<Dynamic> = this.redis.hgetall("myhash");
    Assert.equals(6, a.length);
    Assert.equals("field1", a[0]);
    Assert.equals("Hello", a[1]);
    Assert.equals("field2", a[2]);
    Assert.equals("Hi", a[3]);
    Assert.equals("field3", a[4]);
    Assert.equals("World", a[5]);
    a = this.redis.hgetall("myhash2");
    Assert.equals(0, a.length);
  }

  /**
   * Test hkeys
   */
  public function testHkeys():Void {
    Assert.equals(1, this.redis.hset("myhash", "field1", "Hello"));
    Assert.equals(2, this.redis.hset("myhash", "field2", "Hi", "field3", "World"));
    var a:Array<Dynamic> = this.redis.hkeys("myhash");
    Assert.equals(3, a.length);
    Assert.equals("field1", a[0]);
    Assert.equals("field2", a[1]);
    Assert.equals("field3", a[2]);
    a = this.redis.hkeys("myhash2");
    Assert.equals(0, a.length);
  }

  /**
   * Test hlen
   */
  public function testHlen():Void {
    Assert.equals(1, this.redis.hset("myhash", "field1", "Hello"));
    Assert.equals(2, this.redis.hset("myhash", "field2", "Hi", "field3", "World"));
    Assert.equals(3, this.redis.hlen("myhash"));
    Assert.equals(0, this.redis.hlen("myhash2"));
  }

  /**
   * Test hset
   */
  public function testHset():Void {
    Assert.equals(1, this.redis.hset("myhash", "field1", "Hello"));
    Assert.equals(2, this.redis.hset("myhash", "field2", "Hi", "field3", "World"));
  }
}
