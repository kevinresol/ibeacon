package;

import tink.unit.*;
import tink.testrunner.*;
import ibeacon.Beacon;
import haxe.io.Bytes;

using StringTools;
using tink.CoreApi;

class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new BeaconTest(),
    ])).handle(Runner.exit);
  }
  
}

@:asserts
class BeaconTest {
  public function new() {}
  
  public function parse() {
    var beacon = Beacon.parse(hex('4c000215fda50693a4e24fb1afcfc6eb076166882714143acd')).sure();
    asserts.assert(beacon.uuid.toHex() == 'fda50693a4e24fb1afcfc6eb07616688');
    asserts.assert(beacon.major == 10004);
    asserts.assert(beacon.minor == 5178);
    asserts.assert(beacon.measuredPower == -51);
    return asserts.done();
  }
  
  public function serialize() {
    var beacon:Beacon = {
      uuid: hex('fda50693a4e24fb1afcfc6eb07616688'),
      major: 10004,
      minor: 5178,
      measuredPower: -51
    }
    asserts.assert(beacon.serialize().toHex() == '4c000215fda50693a4e24fb1afcfc6eb076166882714143acd');
    return asserts.done();
  }
  
  function hex(s:String) {
    var len = s.length >> 1;
    var bytes = Bytes.alloc(len);
    for(i in 0...len) bytes.set(i, Std.parseInt('0x' + s.substr(i * 2, 2)));
    return bytes;
  }
}