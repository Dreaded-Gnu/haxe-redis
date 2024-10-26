package test;

class TestAll {
  /**
   * Main function
   */
  public static function main() {
    utest.UTest.run([
      new RedisTestDel(),
      new RedisTestGet(),
      new RedisTestHashmap(),
      new RedisTestPing(),
      new RedisTestSet(),
      new RedisTestStrlen()
    ]);
  }
}
