package redislib;

import haxe.Int64;

class Helper {
  /**
   * Internal helper to append to string
   * @param str
   * @param val
   * @return String
   */
  private static function append(str:String, val:String):String {
    return '${str}${val}';
  }

  /**
   * Helper to convert float value to string without scientific notation
   * @param val
   * @return String
   */
  public static function floatToString(val:Float):String {
    // prepare result string
    var result:String = '';
    // handle negative
    if (0 > val) {
      result = append(result, '-');
      val *= -1;
    }
    // extract whole number
    var num:Int64 = Int64.fromFloat(val);
    // extract decimal part
    var dec:Float = val - Std.parseFloat(Int64.toStr(num));
    // build string out of num and dec
    result = append(result, Int64.toStr(num));
    // append decimal if set
    if (dec > 0) {
      result = append(result, '.');
      result = append(result, Std.string(dec).substr(2));
    }
    // finally return result
    return result;
  }
}
