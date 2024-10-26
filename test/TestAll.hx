package test;

class TestAll {
  /**
   * Main function
   */
  public static function main() {
    utest.UTest.run([new RedisTest()]);
  }
}
