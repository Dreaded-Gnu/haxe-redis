package test;

import utest.Assert;
import redislib.Redis;

class RedisTestStrlen extends utest.Test {
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
   * Test strlen
   */
  public function testStrlen():Void {
    Assert.isTrue(this.redis.set("foo", "bar"));
    Assert.equals(3, this.redis.strlen("foo"));
  }
}
