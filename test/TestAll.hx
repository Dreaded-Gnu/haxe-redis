package test;

class TestAll {
  /**
   * Main function
   */
  public static function main() {
    utest.UTest.run([
      new RedisTestGetSet(),
      new RedisTestHashmap(),
      new RedisTestPing(),
      new RedisTestStrlen()
    ]);
  }
}
