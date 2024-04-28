import utest.Runner;
import utest.ui.Report;
import utest.Assert;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.crypto.BaseCode;
import redis.Connection;

class Test {
  public static function main() {
    utest.UTest.run([
      new ConnectTest()]);
  }
}

class ConnectTest extends utest.Test {
  public function testMin() {
  }
}
