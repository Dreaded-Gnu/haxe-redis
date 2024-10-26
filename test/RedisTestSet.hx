package test;

import haxe.Timer;
import utest.Assert;
import redis.Redis;

class RedisTestSet extends utest.Test {
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
   * Test set
   */
  public function testSet():Void {
    Assert.isTrue(this.redis.set("foo", "bar"));
  }

  /**
   * Test set with expire
   */
  @:timeout(5000)
  public function testSetExpire(async:utest.Async):Void {
    // set with expire of one second
    Assert.isTrue(this.redis.set("foo", "bar", 1));
    // assert equals
    Assert.equals("bar", this.redis.get("foo"));
    // delay one second
    Timer.delay(() -> {
      // now return should be null
      Assert.equals(null, this.redis.get("foo"));
      // mark async as done
      async.done();
    }, 2000);
  }
}
