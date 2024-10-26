package test;

import haxe.Timer;
import utest.Runner;
import utest.ui.Report;
import utest.Assert;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.crypto.BaseCode;
import redis.Redis;

class RedisTest extends utest.Test {
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
   * Test ping
   */
  public function testPing():Void {
    Assert.isTrue(this.redis.ping());
  }

  /**
   * Test set
   */
  public function testSet():Void {
    Assert.isTrue(this.redis.set("foo", "bar"));
  }

  /**
   * Test get with previous set
   */
  public function testGet():Void {
    Assert.isTrue(this.redis.set("foo", "bar"));
    Assert.equals("bar", this.redis.get("foo"));
  }

  /**
   * Test get where nothing was set before
   */
  public function testGetNotSet():Void {
    Assert.equals(null, this.redis.get("foo"));
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

  /**
   * Test strlen
   */
  public function testStrlen():Void {
    Assert.isTrue(this.redis.set("foo", "bar"));
    Assert.equals(3, this.redis.strlen("foo"));
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
}
