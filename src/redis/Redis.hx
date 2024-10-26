package redis;

import sys.net.Host;
import sys.net.Socket;

class Redis {
  private static inline var TIMEOUT:Int = 5;
  private static inline var EOL:String = '\r\n';
  private static inline var OK:String = 'OK';
  private static inline var PONG:String = 'PONG';

  /**
   * Connection timeout
   */
  public var timeout(null, default):Int;

  /**
   * Redis host
   */
  public var host(default, null):String;

  /**
   * Redis port
   */
  public var port(default, null):Int;

  /**
   * Redis password
   */
  public var password(default, null):String;

  /**
   * Redis database
   */
  public var database(default, null):Int;

  private var sock:Socket;

  /**
   * Constructor
   * @param host redis instance host
   * @param port redis instance port
   * @param password redis password
   * @param database database to connect to
   */
  public function new(host:String, port:Int, password:String, database:Int) {
    this.host = host;
    this.port = port;
    this.password = password;
    this.database = database;
  }

  /**
   * Private setter for timeout
   * @param timeout
   * @return Int
   */
  private function set_timeout(timeout:Int):Int {
    // handle no socket means no connection
    if (this.sock == null) {
      throw new Error('-ERR Not connected!');
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
    if (Redis.OK != s) {
      throw new Error('-ERR Assertion failed: ${s}');
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
      throw new Error('-ERR Not connected!');
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
      throw new Error('-ERR Not connected!');
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
        throw new Error(line.substr(1));

      default:
        throw new Error('-ERR Unknown redis response!');
    }
  }

  /**
   * Issue a specific command with arguments
   * @param cmd
   * @param args
   * @return Dynamic
   */
  private function command(cmd:String, ?args:Array<String>):Dynamic {
    // send command
    this.send(cmd, args);
    // receive response
    return this.receive();
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
    // select database
    this.select(database);
  }

  /**
   * Disconnect from redis
   */
  public function disconnect():Void {
    // handle no socket open
    if (this.sock == null) {
      return;
    }
    // send quit command
    this.send('QUIT');
    // close connection
    this.sock.close();
    // unset socket
    this.sock = null;
  }

  /**
   * PING
   * @return True when result of ping equals pong, else false is returned
   */
  public function ping():Bool {
    return cast(this.command('PING'), String) == Redis.PONG;
  }

  /**
   * SELECT
   * @param index database to select
   * @return true on successful select of database
   * @throws Error When response of select was invalid
   */
  public function select(index:Int):Bool {
    return this.validateOk(this.command('SELECT', [Std.string(index),]));
  }

  /**
   * FLUSHDB
   * @param async perform flushdb async, defaults to false
   * @return true on successful flush of database
   * @throws Error when response from flushdb was invalid
   */
  public function flushdb(async:Bool = false):Bool {
    return this.validateOk(this.command('FLUSHDB', [async ? 'ASYNC' : 'SYNC',]));
  }

  /**
   * SET / SETEX
   * @param key key to set
   * @param value value to set
   * @param expire optional expire
   * @return true on successful set of key
   * @throws Error When response from set/setex was invalid
   */
  public function set(key:String, value:String, ?expire:Int):Bool {
    if (null == expire) {
      return this.validateOk(this.command('SET', [key, value,]));
    }
    return this.validateOk(this.command('SETEX', [key, Std.string(expire), value,]));
  }

  /**
   * GET
   * @param key key to get
   * @return String value of key or null if not set
   */
  public function get(key:String):String {
    return cast(this.command('GET', [key,]), String);
  }

  /**
   * STRLEN
   * @param key key to get string length
   * @return String length of key
   */
  public function strlen(key:String):Int {
    return cast(this.command('STRLEN', [key,]), Int);
  }

  /**
   * HGET
   * @param key hashmap key
   * @param field field to get value of
   * @return String value of field in hashmap or null if not existing
   */
  public function hget(key:String, field:String):String {
    return cast(this.command('HGET', [key, field,]), String);
  }

  /**
   * HSET
   * @param key hashmap key
   * @param field field to set value
   * @param value value to set
   * @param ...arguments further key value pairs
   * @return Amount of set fields in hashmap
   */
  public function hset(key:String, field:String, value:String, ...arguments:String):Int {
    // handle invalid argument length
    if (arguments.length > 0 && arguments.length % 2 != 0) {
      throw new Error('-ERR Invalid amount of arguments passed!');
    }
    // setup param array
    var param:Array<String> = new Array<String>();
    // push fixed parameters
    param.push(key);
    param.push(field);
    param.push(value);
    // push variable parameters
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result casted to int
    return cast(this.command('HSET', param), Int);
  }

  /**
   * HDEL
   * @param key hashmap key
   * @param field field to delete
   * @param ...arguments further fields to delete
   * @return Amount of deleted fields in hashset
   */
  public function hdel(key:String, field:String, ...arguments:String):Int {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push fixed parameters
    param.push(key);
    param.push(field);
    // push variable parameter
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast(this.command('HDEL', param), Int);
  }
}
