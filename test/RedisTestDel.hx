package test;

import haxe.Timer;
import utest.Assert;
import redis.Redis;

class RedisTestDel extends utest.Test {
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
   * Test del single
   */
  public function testDelSingle():Void {
    Assert.isTrue(this.redis.set("foo", "bar"));
    Assert.equals(1, this.redis.del("foo"));
  }

  /**
   * Test del multiple
   */
  public function testDelMultiple():Void {
    Assert.isTrue(this.redis.set("foo", "bar"));
    Assert.isTrue(this.redis.set("bar", "foo"));
    Assert.equals(2, this.redis.del("foo", "bar"));
  }

  /**
   * Test del non existant
   */
  public function testDelNonExistant():Void {
    Assert.equals(0, this.redis.del("foo"));
  }
}
