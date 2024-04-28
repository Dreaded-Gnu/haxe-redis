package redis;

import haxe.Exception;
import sys.net.Host;
import sys.net.Socket;

class Connection {
  private static inline var TIMEOUT:Int = 5;
  private static inline var EOL:String = "\r\n";

  public var timeout(null, default):String;
  public var host(default, null):String;
  public var port(default, null):Int;
  public var password(default, null):String;

  private var sock:Socket = null;

  /**
   * Constructor
   * @param host 
   * @param port 
   */
  public function new(host:String, port:Int = 6379, password:String = '') {
    // cache host and port
    this.host = host;
    this.port = port;
    this.password = password;
  }

  /**
   * Connect to redis
   */
  public function connect():Void {
    // handle already connected
    if (this.sock != null) {
      return;
    }
    // create new socket and try to connect
    this.sock = new Socket();
    this.sock.setTimeout(TIMEOUT);
    this.sock.connect(new Host(this.host), this.port);
    // not empty password requires authentication
    if (this.password != '') {
      // validate auth command
      this.validateOk(this.command('AUTH', [this.password,]));
    }
  }

  /**
   * Disconnect socket
   */
  public function disconnect():Void {
    // handle no socket open
    if (this.sock == null) {
      return;
    }
    // send quit command
    this.send("QUIT");
    // close connection
    this.sock.close();
    // unset socket
    this.sock = null;
  }

  /**
   * Issue a specific command with arguments
   * @param cmd 
   * @param args 
   * @return Dynamic
   */
  public function command(cmd:String, ?args:Array<String>):Dynamic {
    // send command
    this.send(cmd, args);
    // receive response
    return this.receive();
  }

  /**
   * Ping redis server
   * @return Bool
   */
  public function ping():Bool {
    return cast(this.command("PING"), String) == "PONG";
  }

  /**
   * Select a database
   * @param index 
   * @return Bool
   */
  public function select(index:Int):Bool {
    return this.validateOk(this.command('SELECT', [Std.string(index),]));
  }

  /**
   * Set a key with optional expire
   * @param key key to set
   * @param value value to set
   * @param expire optional expire
   * @return Bool
   */
  public function set(key:String, value:String, ?expire:Int):Bool {
    if (null == expire) {
      return this.validateOk(this.command("SET", [key, value,]));
    }
    return this.validateOk(this.command("SETEX", [key, Std.string(expire), value,]));
  }

  /**
   * Get a key
   * @param key key to get
   * @return String
   */
  public function get(key:String):String {
    return cast(this.command("GET", [key,]), String);
  }

  /**
   * Get string length of a key
   * @param key 
   * @return Int
   */
  public function strlen(key:String):Int {
    return cast(this.command("STRLEN", [key,]), Int);
  }

  /**
   * Private setter for timeout
   * @param timeout 
   * @return Int
   */
  private function set_timeout(timeout:Int):Int {
    // handle no socket means no connection
    if (this.sock == null) {
      throw new Exception("Not connected!");
    }
    // set timeout
    this.sock.setTimeout(timeout);
    // return timeout set
    return timeout;
  }

  /**
   * Helper to check for response is okay
   * @param response 
   * @return Bool
   */
  private function validateOk(response:Dynamic):Bool {
    var s:String = cast(response, String);
    if ("OK" != s) {
      throw new Exception('Assertion failed: ${s}');
    }
    return true;
  }

  /**
   * Helper to build argument
   * @param arg 
   * @return String
   */
  private function buildArgument(arg:String):String {
    return '$$${arg.length}${EOL}${arg}${EOL}';
  }

  /**
   * Send a command with arguments
   * @param cmd 
   * @param args 
   */
  private function send(cmd:String, ?args:Array<String>):Void {
    // handle not connected
    if (null == this.sock) {
      throw new Exception("Not connected!");
    }
    // initialize args if null
    if (args == null) {
      args = [];
    }
    // string buffer for command
    var sb:StringBuf = new StringBuf();
    // add length
    sb.add('*${args.length + 1}${EOL}');
    // add command
    sb.add(this.buildArgument(cmd));
    // add arguments
    for (arg in args) {
      sb.add(this.buildArgument(arg));
    }
    // finally send command
    this.sock.output.writeString(sb.toString());
  }

  /**
   * Receive helper
   * @return Dynamic
   */
  private function receive():Dynamic {
    // handle not connected
    if (null == this.sock) {
      throw new Exception("Not connected!");
    }
    var line:String = this.sock.input.readLine();
    switch (line.charCodeAt(0)) {
      // string
      case "+".code:
        return line.substr(1);

      // int
      case ":".code:
        return Std.parseInt(line.substr(1));

      // bulk
      case "$".code:
        var l:Int = Std.parseInt(line.substr(1));
        if (l == -1) {
          return null;
        }
        // read string
        var r:String = this.sock.input.read(l).toString();
        // read eof
        this.sock.input.read(2);
        // return string
        return r;

      // multi
      case "*".code:
        var l:Int = Std.parseInt(line.substr(1));
        if (l == -1) {
          return null;
        }
        var a:Array<Dynamic> = new Array<Dynamic>();
        for (i in 0...l) {
          a.push(receive());
        }
        return a;

      // error
      case "-".code:
        throw new Exception(line.substr(1));

      default:
        throw new Exception("Unknown redis response!");
    }
  }
}
