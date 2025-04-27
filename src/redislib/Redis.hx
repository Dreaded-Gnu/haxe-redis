package redislib;

import haxe.Exception;
import sys.net.Host;
import sys.net.Socket;
#if (target.threaded)
import sys.thread.Mutex;
#end

/**
 * Main redis class for connecting and accessing redis
 */
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
  #if (target.threaded)
  private var socketMutex:Mutex;
  #end

  /**
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
    #if (target.threaded)
    this.socketMutex = new Mutex();
    #end
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
  private function validateOk(response:Any):Bool {
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
    #if !eval
    // wait for output
    var result:{read:Array<Socket>, write:Array<Socket>, others:Array<Socket>} = Socket.select(null, [this.sock,], null);
    // finally send command
    result.write[0].output.writeString(sb.toString());
    #else
    // finally send command
    this.sock.output.writeString(sb.toString());
    #end
  }

  /**
   * Receive helper
   * @params args
   * @return Any
   */
  private function receive(?args:Array<String>):Any {
    // handle not connected
    if (null == this.sock) {
      throw new Error('-ERR Not connected!');
    }
    #if !eval
    // wait for input
    var result:{read:Array<Socket>, write:Array<Socket>, others:Array<Socket>} = Socket.select([this.sock,], null, null);
    // read from socket
    var line:String = result.read[0].input.readLine();
    #else
    // read from socket
    var line:String = this.sock.input.readLine();
    #end
    // handle read line
    switch (line.charCodeAt(0)) {
      // string
      case "+".code:
        return line.substr(1);

      // int
      case ":".code:
        return Std.parseFloat(line.substr(1));

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
        var a:Array<Any> = new Array<Any>();
        for (i in 0...l) {
          a.push(receive(args));
        }
        return a;

      // error
      case "-".code:
        throw new Error('${line.substr(0)}. Parameters: ${args?.join(',')}');

      default:
        throw new Error('-ERR Unknown redis response!');
    }
  }

  /**
   * Issue a specific command with arguments
   * @param cmd
   * @param args
   * @return Any
   */
  public function command(cmd:String, ?args:Array<String>):Any {
    // acquire mutex
    #if (target.threaded)
    this.socketMutex.acquire();
    #end
    // send command
    this.send(cmd, args);
    // receive response
    var response:Any = this.receive(args);
    // release mutex
    #if (target.threaded)
    this.socketMutex.release();
    #end
    // return response
    return response;
  }

  /**
   * Connect to redis
   * @throws Error When authentication failed
   * @throws Error When database selection failed
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
    // set to non blocking and enable fast send
    this.sock.setBlocking(false);
    this.sock.setFastSend(true);
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
   * DEL
   * @param key Key to delete
   * @param ...keys Further keys to delete
   * @return Amount of deleted keys
   */
  public function del(key:String, ...keys:String):Int {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push fixed parameters
    param.push(key);
    // push variable parameter
    for (arg in keys) {
      param.push(arg);
    }
    // execute command and return result
    return cast(this.command('DEL', param), Int);
  }

  /**
   * FLUSHDB
   * @param async Perform flushdb async, defaults to false
   * @return True on successful flush of database
   * @throws Error When response from flushdb was invalid
   */
  public function flushdb(async:Bool = false):Bool {
    return this.validateOk(this.command('FLUSHDB', [async ? 'ASYNC' : 'SYNC',]));
  }

  /**
   * GET
   * @param key Key to get
   * @return String value of key or null if not set
   */
  public function get(key:String):String {
    return cast(this.command('GET', [key,]), String);
  }

  /**
   * HDEL
   * @param key Hashmap key
   * @param field Field to delete
   * @param ...arguments Further fields to delete
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

  /**
   * HEXISTS
   * @param key Hashmap key
   * @param field Field to check for existance
   * @return Returns one if field exists, else 0
   */
  public function hexists(key:String, field:String):Int {
    return cast(this.command('HEXISTS', [key, field,]), Int);
  }

  /**
   * HEXPIRE
   * @param key Hashmap key
   * @param expire Expire in seconds
   * @param option Expire options: NX, XX, GT, LT
   * @param field Field to set expire
   * @param ...arguments Further fields to set expire
   * @return Array<Int>
   */
  public function hexpire(key:String, expire:Int, option:String, field:String, ...arguments:String):Array<Int> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push(Std.string(expire));
    if (option == 'NX' || option == 'XX' || option == 'GT' || option == 'LT') {
      param.push(option);
    }
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HEXPIRE', param);
  }

  /**
   * HEXPIREAT
   * @param key Hashmap key
   * @param unixTimeStamp unix timestamp when to expire
   * @param option Expire options: NX, XX, GT or LT
   * @param field Field to set expire
   * @param ...arguments Further fields to set expire
   * @return Array<Int>
   */
  public function hexpireat(key:String, unixTimeStamp:Int, option:String, field:String, ...arguments:String):Array<Int> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push(Std.string(unixTimeStamp));
    if (option == 'NX' || option == 'XX' || option == 'GT' || option == 'LT') {
      param.push(option);
    }
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HEXPIREAT', param);
  }

  /**
   * HEXPIRETIME
   * @param key Hashmap key
   * @param field Field to get expire time
   * @param ...arguments Further fields to get expire times
   * @return Array<Int>
   */
  public function hexpiretime(key:String, field:String, ...arguments:String):Array<Int> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HEXPIRETIME', param);
  }

  /**
   * HGET
   * @param key Hashmap key
   * @param field Field to get value of
   * @return String value of field in hashmap or null if not existing
   */
  public function hget(key:String, field:String):String {
    return cast(this.command('HGET', [key, field,]), String);
  }

  /**
   * HGETALL
   * @param key Hashmap key
   * @return Array of field entry pairs
   */
  public function hgetall(key:String):Array<String> {
    return cast this.command('HGETALL', [key,]);
  }

  /**
   * HGETDEL
   * @param key hashmap key
   * @param field Field to get and delete
   * @param ...arguments Further fields to get and delete
   * @return Array of deleted values
   */
  public function hgetdel(key:String, field:String, ...arguments:String):Array<String> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HGETDEL', param);
  }

  /**
   * HGETEX
   * @param key Hashmap key
   * @param expire expire in seconds, milliseconds, unix time seconds or unix time milliseconds
   * @param option Expire options: EX, PX, EXAT, PXAT or PERSIST
   * @param field Field to get/clear expire
   * @param ...arguments Further fields to set expire
   * @return Array<String>
   */
  public function hgetex(key:String, expire:Float, option:String, field:String, ...arguments:String):Array<String> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    if (option == 'EX' || option == 'PX' || option == 'EXAT' || option == 'PXAT') {
      param.push(option);
      param.push(Std.string(Math.ffloor(expire)));
    } else if (option == 'PERSIST') {
      param.push(option);
    }
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HGETEX', param);
  }

  /**
   * HINCRBY
   * @param key Hashmap key
   * @param field Field to increment
   * @param increment Increment value
   * @return Int
   */
  public function hincrby(key:String, field:String, increment:Int):Int {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push(field);
    param.push(Std.string(increment));
    // return command result
    return cast(this.command('HINCRBY', param), Int);
  }

  /**
   * HINCRBYFLOAT
   * @param key Hashmap key
   * @param field Field to increment
   * @param increment Increment value
   * @return Float
   */
  public function hincrbyfloat(key:String, field:String, increment:Float):Float {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push(field);
    param.push(Std.string(increment));
    // return command result
    return Std.parseFloat(cast(this.command('HINCRBYFLOAT', param), String));
  }

  /**
   * HKEYS
   * @param key Hashmap key
   * @return Array of fields
   */
  public function hkeys(key:String):Array<String> {
    return cast this.command('HKEYS', [key,]);
  }

  /**
   * HLEN
   * @param key Hashmap keys
   * @return Hashmap length
   */
  public function hlen(key:String):Int {
    return cast(this.command('HLEN', [key,]), Int);
  }

  /**
   * HMGET
   * @param key Hashmap key
   * @param field Field to get
   * @param ...arguments Additional fields to get
   * @return Array<String>
   */
  public function hmget(key:String, field:String, ...arguments:String):Array<String> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HMGET', param);
  }

  /**
   * HMSET
   * @param key Hashmap key
   * @param field Field to set
   * @param value Value to set
   * @param ...arguments Additional fields and values to set
   * @return String
   */
  public function hmset(key:String, field:String, value:String, ...arguments:String):String {
    // handle invalid data
    if (0 != arguments.length % 2) {
      throw new Exception('Invalid additional arguments passed!');
    }
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push(field);
    param.push(value);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast(this.command('HMSET', param), String);
  }

  /**
   * HPERSIST
   * @param key Hashmap key
   * @param field Field to persist
   * @param ...arguments Further fields to persist
   * @return Array<Int>
   */
  public function hpersist(key:String, field:String, ...arguments:String):Array<Int> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HPERSIST', param);
  }

  /**
   * HPEXPIRE
   * @param key Hashmap key
   * @param expire Expire in milliseconds
   * @param option Expire options: NX, XX, GT, LT
   * @param field Field to set expire
   * @param ...arguments Further fields to set expire
   * @return Array<Float>
   */
  public function hpexpire(key:String, expire:Float, option:String, field:String, ...arguments:String):Array<Float> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push(Std.string(Math.ffloor(expire)));
    if (option == 'NX' || option == 'XX' || option == 'GT' || option == 'LT') {
      param.push(option);
    }
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HPEXPIRE', param);
  }

  /**
   * HPEXPIREAT
   * @param key Hashmap key
   * @param unixTimeMilliseconds unix timestamp in milliseconds when to expire
   * @param option Expire options: NX, XX, GT or LT
   * @param field Field to set expire
   * @param ...arguments Further fields to set expire
   * @return Array<Int>
   */
  public function hpexpireat(key:String, unixTimeMilliseconds:Float, option:String, field:String, ...arguments:String):Array<Int> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push(Std.string(Math.ffloor(unixTimeMilliseconds)));
    if (option == 'NX' || option == 'XX' || option == 'GT' || option == 'LT') {
      param.push(option);
    }
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HPEXPIREAT', param);
  }

  /**
   * HPEXPIRETIME
   * @param key Hashmap key
   * @param field Field to get expire time
   * @param ...arguments Further fields to get expire times
   * @return Array<Float>
   */
  public function hpexpiretime(key:String, field:String, ...arguments:String):Array<Float> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HPEXPIRETIME', param);
  }

  /**
   * HPTTL
   * @param key Hashmap key
   * @param field Field to get remaining ttl
   * @param ...arguments Further fields to get remaining ttl
   * @return Array<Float>
   */
  public function hpttl(key:String, field:String, ...arguments:String):Array<Float> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HPTTL', param);
  }

  /**
   * HSCAN
   * @param key hashmap key
   * @param cursor cursor
   * @param match match pattern
   * @param count count count option
   * @param novalues flag to indicate whether novalues shall be passed
   * @return Array key value pairs, first key is the count, ongoing value is a key value array
   */
  public function hscan(key:String, cursor:Int, match:Null<String> = null, count:Null<Int> = null, novalues:Bool = false):Array<Any> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push(Std.string(cursor));
    if (match != null) {
      param.push('MATCH');
      param.push(match);
    }
    if (count != null) {
      param.push("COUNT");
      param.push(Std.string(count));
    }
    if (novalues) {
      param.push("NOVALUES");
    }
    return cast this.command('HSCAN', param);
  }

  /**
   * HSET
   * @param key Hashmap key
   * @param field Field to set value
   * @param value Value to set
   * @param ...arguments Further key value pairs
   * @return Amount of set fields in hashmap
   * @throws Error When further arguments is not dividable by 2
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
   * HSETEX
   * @param key Hashmap key
   * @param option FNX or FXX or empty string
   * @param expire expire in seconds, milliseconds, unix time seconds or unix time milliseconds
   * @param expireOption EX, PX, EXAT, PXAT or KEEPTTL
   * @param field field to set
   * @param value value to set
   * @param ...arguments Further field value pairs to set expire
   * @return 0 for no fields are set, 1 for all fields are reset
   */
  public function hsetex(key:String, option:String, expire:Float, expireOption:String, field:String, value:String, ...arguments:String):Int {
    // handle invalid argument length
    if (arguments.length > 0 && arguments.length % 2 != 0) {
      throw new Error('-ERR Invalid amount of arguments passed!');
    }
    // validate option
    if ('FNX' != option && 'FXX' != option && '' != option) {
      throw new Error('-ERR Invalid amount of arguments passed!');
    }
    // validate expire option
    if ('' == expireOption || (['EX', 'PX', 'EXAT', 'PXAT', 'KEEPTTL'].indexOf(expireOption) == -1)) {
      throw new Error('-ERR Invalid amount of arguments passed!');
    }
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    if ('' != option) {
      param.push(option);
    }
    if (expireOption == 'EX' || expireOption == 'PX' || expireOption == 'EXAT' || expireOption == 'PXAT') {
      param.push(expireOption);
      param.push(Std.string(Math.ffloor(expire)));
    } else if (expireOption == 'KEEPTTL') {
      param.push(expireOption);
    }
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length / 2));
    param.push(field);
    param.push(value);
    for (arg in arguments) {
      param.push(arg);
    }
    return cast(this.command('HSETEX', param), Int);
  }

  /**
   * HSETNX
   * @param key Hashmap key
   * @param field Field to set value
   * @param value Value to set
   * @return 1 if set, 0 if already set
   */
  public function hsetnx(key:String, field:String, value:String):Int {
    return cast(this.command('HSETNX', [key, field, value,]), Int);
  }

  /**
   * HSTRLEN
   * @param key Hashmap key
   * @param field Field to get length of
   * @return Length of the field
   */
  public function hstrlen(key:String, field:String):Int {
    return cast(this.command('HSTRLEN', [key, field,]), Int);
  }

  /**
   * HTTL
   * @param key
   * @param field
   * @param ...arguments
   * @return Array with ttls
   */
  public function httl(key:String, field:String, ...arguments:String):Array<Int> {
    // setup param array
    var param:Array<String> = new Array<String>();
    // push params
    param.push(key);
    param.push('FIELDS');
    param.push(Std.string(1 + arguments.length));
    param.push(field);
    for (arg in arguments) {
      param.push(arg);
    }
    // return command result
    return cast this.command('HTTL', param);
  }

  /**
   * HVALS
   * @param key hashmap key
   * @return Array with values of hashmap
   */
  public function hvals(key:String):Array<String> {
    return cast this.command('HVALS', [key,]);
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
   * @param index Database to select
   * @return True on successful select of database
   * @throws Error When response of select was invalid
   */
  public function select(index:Int):Bool {
    return this.validateOk(this.command('SELECT', [Std.string(index),]));
  }

  /**
   * SET / SETEX
   * @param key Key to set
   * @param value Value to set
   * @param expire Optional expire in seconds
   * @return True on successful set of key
   * @throws Error When response from set/setex was invalid
   */
  public function set(key:String, value:String, ?expire:Int):Bool {
    if (null == expire) {
      return this.validateOk(this.command('SET', [key, value,]));
    }
    return this.validateOk(this.command('SETEX', [key, Std.string(expire), value,]));
  }

  /**
   * STRLEN
   * @param key Key to get string length
   * @return String length of key
   */
  public function strlen(key:String):Int {
    return cast(this.command('STRLEN', [key,]), Int);
  }
}
