package test;

import utest.Assert;
import redislib.Redis;

class RedisTestGet extends utest.Test {
  private var redis:Redis;

  /**
   * Setup test
   */
  public function setup():Void {
    this.redis = new Redis('localhost', 6379, 'eYVX7EwVmmxKPCDmwMtyKVge8oLd2t81', 0);
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
   * Test get with previous set
   */
  public function testGet():Void {
    Assert.isTrue(this.redis.set('foo', 'bar'));
    Assert.equals('bar', this.redis.get('foo'));
  }

  /**
   * Test get where nothing was set before
   */
  public function testGetNotSet():Void {
    Assert.equals(null, this.redis.get('foo'));
  }
}
