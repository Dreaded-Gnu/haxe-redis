package test;

import haxe.Timer;
import utest.Assert;
import redislib.Redis;

class RedisTestHashmap extends utest.Test {
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
   * Test hdel
   */
  public function testHdel():Void {
    Assert.equals(1, this.redis.hset('myhash', 'field1', 'Hello'));
    Assert.equals(2, this.redis.hset('myhash', 'field2', 'Hi', 'field3', 'World'));
    Assert.equals(1, this.redis.hdel('myhash', 'field1'));
    Assert.equals(null, this.redis.hget('myhash', 'field1'));
    Assert.equals(0, this.redis.hdel('myhash', 'field1'));
    Assert.equals(2, this.redis.hdel('myhash', 'field2', 'field3'));
    Assert.equals(null, this.redis.hget('myhash', 'field2'));
    Assert.equals(null, this.redis.hget('myhash', 'field3'));
    Assert.equals(0, this.redis.hdel('myhash', 'field2', 'field3'));
  }

  /**
   * Test hexists
   */
  public function testHexists():Void {
    Assert.equals(1, this.redis.hset('myhash', 'field1', 'Hello'));
    Assert.equals(2, this.redis.hset('myhash', 'field2', 'Hi', 'field3', 'World'));
  }

  /**
   * Test hexpire
   */
  public function testHexpire():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<Int> = this.redis.hexpire('myhash', 300, '', 'field1', 'field2');
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    a = this.redis.hexpiretime('myhash', 'field1', 'field2', 'field3', 'field4');
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
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var timestamp:Int = Std.int(Sys.time()) + 3600;
    var a:Array<Int> = this.redis.hexpireat('myhash', timestamp, '', 'field1', 'field2');
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    a = this.redis.hexpiretime('myhash', 'field1', 'field2', 'field3', 'field4');
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
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<Int> = this.redis.hexpire('myhash', 300, '', 'field1', 'field2');
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    a = this.redis.hexpiretime('myhash', 'field1', 'field2', 'field3', 'field4');
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
    Assert.equals(1, this.redis.hset('myhash', 'field1', 'Hello'));
    Assert.equals(2, this.redis.hset('myhash', 'field2', 'Hi', 'field3', 'World'));
    Assert.equals('Hello', this.redis.hget('myhash', 'field1'));
    Assert.equals('Hi', this.redis.hget('myhash', 'field2'));
    Assert.equals('World', this.redis.hget('myhash', 'field3'));
    Assert.equals(null, this.redis.hget('nonexistant', 'asdf'));
    Assert.equals(null, this.redis.hget('myhash', 'asdf'));
  }

  /**
   * Test hgetall
   */
  public function testHgetall():Void {
    Assert.equals(1, this.redis.hset('myhash', 'field1', 'Hello'));
    Assert.equals(2, this.redis.hset('myhash', 'field2', 'Hi', 'field3', 'World'));
    var a:Array<String> = this.redis.hgetall('myhash');
    Assert.equals(6, a.length);
    Assert.equals('field1', a[0]);
    Assert.equals('Hello', a[1]);
    Assert.equals('field2', a[2]);
    Assert.equals('Hi', a[3]);
    Assert.equals('field3', a[4]);
    Assert.equals('World', a[5]);
    a = this.redis.hgetall('myhash2');
    Assert.equals(0, a.length);
  }

  /**
   * Test hkeys
   */
  public function testHkeys():Void {
    Assert.equals(1, this.redis.hset('myhash', 'field1', 'Hello'));
    Assert.equals(2, this.redis.hset('myhash', 'field2', 'Hi', 'field3', 'World'));
    var a:Array<String> = this.redis.hkeys('myhash');
    Assert.equals(3, a.length);
    Assert.equals('field1', a[0]);
    Assert.equals('field2', a[1]);
    Assert.equals('field3', a[2]);
    a = this.redis.hkeys('myhash2');
    Assert.equals(0, a.length);
  }

  /**
   * Test hlen
   */
  public function testHlen():Void {
    Assert.equals(1, this.redis.hset('myhash', 'field1', 'Hello'));
    Assert.equals(2, this.redis.hset('myhash', 'field2', 'Hi', 'field3', 'World'));
    Assert.equals(3, this.redis.hlen('myhash'));
    Assert.equals(0, this.redis.hlen('myhash2'));
  }

  /**
   * Test hset
   */
  public function testHset():Void {
    Assert.equals(1, this.redis.hset('myhash', 'field1', 'Hello'));
    Assert.equals(2, this.redis.hset('myhash', 'field2', 'Hi', 'field3', 'World'));
  }

  /**
   * Test hgetdel
   */
  public function testHgetdel():Void {
    Assert.equals(1, this.redis.hset('myhash', 'field1', 'Hello'));
    Assert.equals(1, this.redis.hgetdel('myhash', 'field1').length);
    Assert.equals(0, this.redis.hlen('myhash'));
  }

  /**
   * Test hgetex
   */
  public function testHgetex():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<String> = this.redis.hgetex('myhash', 300, 'EX', 'field1', 'field2');
    Assert.equals(2, a.length);
    Assert.equals('Hello', a[0]);
    Assert.equals('World', a[1]);
    var b:Array<Int> = this.redis.httl('myhash', 'field1', 'field2', 'field3', 'field4');
    Assert.equals(4, b.length);
    Assert.notEquals(0, b[0]);
    Assert.notEquals(-1, b[0]);
    Assert.notEquals(0, b[1]);
    Assert.notEquals(-1, b[1]);
    Assert.equals(-1, b[2]);
    Assert.equals(-2, b[3]);
  }

  /**
   * Test hincrby
   */
  public function testHincrby():Void {
    Assert.equals(1, this.redis.hset('myhash', 'field1', '5'));
    var val:Int = this.redis.hincrby('myhash', 'field1', 1);
    Assert.equals(6, val);
    Assert.equals(6, Std.parseInt(this.redis.hget('myhash', 'field1')));
  }

  /**
   * Test hincrbyfloat
   */
  public function testHincrbyfloat():Void {
    Assert.equals(1, this.redis.hset('myhash', 'field1', '10.50'));
    var val:Float = this.redis.hincrbyfloat('myhash', 'field1', 0.1);
    Assert.equals(10.6, val);
    Assert.equals(10.6, Std.parseFloat(this.redis.hget('myhash', 'field1')));
  }

  /**
   * Test hmset
   */
  public function testHmset():Void {
    Assert.equals('OK', this.redis.hmset('myhash', 'field1', 'Hello', 'field2', 'World'));
    var a:Array<String> = this.redis.hmget('myhash', 'field1', 'field2', 'nofield');
    Assert.equals(3, a.length);
    Assert.equals('Hello', a[0]);
    Assert.equals('World', a[1]);
    Assert.equals(null, a[2]);
  }

  /**
   * Test hmget
   */
  public function testHmget():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<String> = this.redis.hmget('myhash', 'field1', 'field2', 'nofield');
    Assert.equals(3, a.length);
    Assert.equals('Hello', a[0]);
    Assert.equals('World', a[1]);
    Assert.equals(null, a[2]);
  }

  /**
   * Test hpersist
   */
  public function testHpersist():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<Int> = this.redis.hexpire('myhash', 300, '', 'field1', 'field2');
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    a = this.redis.httl('myhash', 'field1', 'field2', 'field3', 'field4');
    Assert.equals(4, a.length);
    Assert.notEquals(0, a[0]);
    Assert.notEquals(-1, a[0]);
    Assert.notEquals(0, a[1]);
    Assert.notEquals(-1, a[1]);
    Assert.equals(-1, a[2]);
    Assert.equals(-2, a[3]);
    this.redis.hpersist('myhash', 'field1', 'field3');
    a = this.redis.httl('myhash', 'field1', 'field2', 'field3', 'field4');
    Assert.equals(4, a.length);
    Assert.equals(-1, a[0]);
    Assert.notEquals(0, a[1]);
    Assert.notEquals(-1, a[1]);
    Assert.equals(-1, a[2]);
    Assert.equals(-2, a[3]);
  }

  /**
   * Test hpexpire
   */
  @:timeout(5000)
  public function testHpexpire(async:utest.Async):Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<Float> = this.redis.hpexpire('myhash', 2000, '', 'field1', 'field2');
    for (entry in a) {
      Assert.equals(1, entry);
    }
    // delay one second
    Timer.delay(() -> {
      // now return should be 1
      Assert.equals(1, this.redis.hkeys('myhash').length);
      // mark async as done
      async.done();
    }, 2000);
  }

  /**
   * Test hpexpireat
   */
  @:timeout(5000)
  public function testHpexpireat(async:utest.Async):Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<Int> = this.redis.hpexpireat('myhash', Timer.stamp() * 1000 + 2000, '', 'field1', 'field2');
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    // delay one second
    Timer.delay(() -> {
      // now return should be 1
      Assert.equals(1, this.redis.hkeys('myhash').length);
      // mark async as done
      async.done();
    }, 2500);
  }

  /**
   * Test hpexpiretime
   */
  public function testHpexpiretime():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<Int> = this.redis.hexpire('myhash', 300, '', 'field1', 'field2');
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    var b:Array<Float> = this.redis.hpexpiretime('myhash', 'field1', 'field2', 'field3');
    Assert.equals(3, b.length);
    Assert.notNull(b[0]);
    Assert.notEquals(0, b[0]);
    Assert.notEquals(-1, b[0]);
    Assert.notNull(b[1]);
    Assert.notEquals(0, b[1]);
    Assert.notEquals(-1, b[1]);
    Assert.equals(-1, b[2]);
  }

  /**
   * Test hpttl
   */
  public function testHpttl():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<Int> = this.redis.hexpire('myhash', 300, '', 'field1', 'field2');
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    var b:Array<Float> = this.redis.hpttl('myhash', 'field1', 'field2', 'field3', 'field4');
    Assert.equals(4, b.length);
    Assert.notEquals(0, b[0]);
    Assert.notEquals(-1, b[0]);
    Assert.notEquals(0, b[1]);
    Assert.notEquals(-1, b[1]);
    Assert.equals(-1, b[2]);
    Assert.equals(-2, b[3]);
  }

  /**
   * Test httl
   */
  public function testHttl():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var a:Array<Int> = this.redis.hexpire('myhash', 300, '', 'field1', 'field2');
    Assert.equals(2, a.length);
    for (entry in a) {
      Assert.equals(1, entry);
    }
    a = this.redis.httl('myhash', 'field1', 'field2', 'field3', 'field4');
    Assert.equals(4, a.length);
    Assert.notEquals(0, a[0]);
    Assert.notEquals(-1, a[0]);
    Assert.notEquals(0, a[1]);
    Assert.notEquals(-1, a[1]);
    Assert.equals(-1, a[2]);
    Assert.equals(-2, a[3]);
  }

  public function testHsetnx():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    Assert.equals(0, this.redis.hsetnx('myhash', 'field1', 'foo'));
    Assert.equals(3, this.redis.hlen('myhash'));
    Assert.equals(1, this.redis.hsetnx('myhash', 'field4', 'foobar'));
    Assert.equals(4, this.redis.hlen('myhash'));
  }

  public function testHstrlen():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    Assert.equals(5, this.redis.hstrlen('myhash', 'field1'));
  }

  public function testHvals():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'field3', 'Bar'));
    var values:Array<String> = this.redis.hvals('myhash');
    Assert.equals(3, values.length);
    Assert.equals('Hello', values[0]);
    Assert.equals('World', values[1]);
    Assert.equals('Bar', values[2]);
  }

  public function testHsetex():Void {
    var timestamp:Float = Timer.stamp() * 1000 + 10000;
    Assert.equals(1, this.redis.hsetex('myhash', '', timestamp, 'PXAT', 'field1', 'Hello', 'field2', 'World'));
    var expire:Array<Float> = this.redis.hpexpiretime('myhash', 'field1', 'field2');
    Assert.equals(2, expire.length);
    Assert.equals(Math.ffloor(timestamp), expire[0]);
    Assert.equals(Math.ffloor(timestamp), expire[1]);
  }

  public function testHscan():Void {
    Assert.equals(3, this.redis.hset('myhash', 'field1', 'Hello', 'field2', 'World', 'asdf', 'Bar'));
    var scanResult:Array<Any> = this.redis.hscan('myhash', 0, 'field*');
    Assert.equals(2, scanResult.length);
    Assert.equals(0, Std.parseInt(scanResult[0]));
    var fieldValuePairs:Array<String> = scanResult[1];
    Assert.equals(4, fieldValuePairs.length);
    Assert.equals('field1', fieldValuePairs[0]);
    Assert.equals('Hello', fieldValuePairs[1]);
    Assert.equals('field2', fieldValuePairs[2]);
    Assert.equals('World', fieldValuePairs[3]);
  }
}
