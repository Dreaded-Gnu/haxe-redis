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
   * Test hset
   */
  public function testHset():Void {
    Assert.equals(1, this.redis.hset("myhash", "field1", "Hello"));
    Assert.equals(2, this.redis.hset("myhash", "field2", "Hi", "field3", "World"));
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
}
