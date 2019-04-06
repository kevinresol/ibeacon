package;

import tink.unit.*;
import tink.testrunner.*;
import ibeacon.Id;
import ibeacon.Beacon;
import haxe.io.Bytes;

using StringTools;
using tink.CoreApi;

class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new IdTest(),
      new BeaconTest(),
    ])).handle(Runner.exit);
  }
  
}

@:asserts
class IdTest {
  public function new() {}
  
  public function values() {
    var min = new Id(0, 0);
    asserts.assert(min.major == 0);
    asserts.assert(min.minor == 0);
    asserts.assert(min == 0);
    
    var max = new Id(0xffff, 0xffff);
    asserts.assert(max.major == 0xffff);
    asserts.assert(max.minor == 0xffff);
    asserts.assert(max == 0xffffffff);
    
    var id = new Id(0, 0xffff);
    asserts.assert(id.major == 0);
    asserts.assert(id.minor == 0xffff);
    asserts.assert(id == 0xffff0000);
    
    var id = new Id(0xffff, 0);
    asserts.assert(id.major == 0xffff);
    asserts.assert(id.minor == 0);
    asserts.assert(id == 0x0000ffff);
    
    var id = new Id(10016, 5178);
    asserts.assert(id.major == 10016);
    asserts.assert(id.minor == 5178);
    asserts.assert(id == 339355424);
    
    return asserts.done();
  }
}

@:asserts
class BeaconTest {
  public function new() {}
  
  public function parse() {
    var beacon = Beacon.tryParse(hex('4c000215fda50693a4e24fb1afcfc6eb076166882714143acd')).sure();
    asserts.assert(beacon.manufacturer == 0x004c);
    asserts.assert(beacon.uuid.toHex() == 'fda50693a4e24fb1afcfc6eb07616688');
    asserts.assert(beacon.id.major == 10004);
    asserts.assert(beacon.id.minor == 5178);
    asserts.assert(beacon.measuredPower == -51);
    return asserts.done();
  }
  
  public function serialize() {
    var beacon = new Beacon({
      manufacturer: 0x004c,
      uuid: hex('fda50693a4e24fb1afcfc6eb07616688'),
      id: new Id(10004, 5178),
      measuredPower: -51
    });
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