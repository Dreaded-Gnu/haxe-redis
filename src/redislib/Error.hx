package redislib;

import haxe.Exception;

/**
 * Error exception
 */
class Error extends Exception {
  /**
   * Constructor
   * @param message exception message
   */
  public function new(message:String):Void {
    super(message.substr(5), null, null);
  }
}
