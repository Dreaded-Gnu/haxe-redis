package redis;

import haxe.Exception;

class Error extends Exception {
  /**
   * Constructor
   * @param message
   * @param previous
   * @param native
   */
  public function new(message:String, ?previous:Exception, ?native:Any):Void {
    super(message.substr(5), previous, native);
  }
}
