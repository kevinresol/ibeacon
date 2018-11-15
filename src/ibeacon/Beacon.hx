package ibeacon;

import haxe.io.Bytes;

import tink.CoreApi;

/*

A standard BLE advertisement looks like the following (https://en.wikipedia.org/wiki/IBeacon)
and this library parses/builds the second part (Apple Defined iBeacon Data):

Byte 0-2: Standard BLE Flags

 Byte 0: Length :  0x02
 Byte 1: Type: 0x01 (Flags)
 Byte 2: Value: 0x06 (Typical Flags)
 
Byte 3-29: Apple Defined iBeacon Data

 Byte 3: Length: 0x1a
 Byte 4: Type: 0xff (Custom Manufacturer Packet)
 Byte 5-6: Manufacturer ID : 0x4c00 (Apple)
 Byte 7: SubType: 0x02 (iBeacon)
 Byte 8: SubType Length: 0x15
 Byte 9-24: UUID
 Byte 25-26: Major
 Byte 27-28: Minor
 Byte 29: Signal Power (calibrated power at 1m)

*/

@:structInit
class Beacon {
	public var uuid:Bytes;
	public var major:Int;
	public var minor:Int;
	public var measuredPower:Int;
	
	// ref: https://github.com/sandeepmistry/node-bleacon/blob/master/lib/bleacon.js
	public static function parse(bytes:Bytes):Outcome<Beacon, Error> {
		return if(
			bytes != null &&
			bytes.length >= 25 &&
			bytes.get(0) == 0x4c && // APPLE_COMPANY_IDENTIFIER (Little Endian)
			bytes.get(1) == 0x00 && // APPLE_COMPANY_IDENTIFIER (Little Endian)
			bytes.get(2) == 0x02 && // IBEACON_TYPE
			bytes.get(3) == 0x15    // EXPECTED_IBEACON_DATA_LENGTH
		 ) {
			Success({
				uuid: bytes.sub(4, 16),
				major: bytes.get(20) << 8 | bytes.get(21),
				minor: bytes.get(22) << 8 | bytes.get(23),
				measuredPower: {
					// uint8 to int8
					#if js 
						// http://blog.vjeux.com/2013/javascript/conversion-from-uint8-to-int8-x-24.html
						bytes.get(24) << 24 >> 24;
					#else
						var i = bytes.get(24);
						i > 127 ? i - 256 : i;
					#end
				},
			});
		} else {
			Failure(new Error('Not a iBeacon advertisement'));
		}
	}
	
	public function getAccuracy(rssi:Int):Float {
		return Math.pow(12.0, 1.5 * ((rssi / measuredPower) - 1));
	}
	
	public function getProximity(rssi:Int):Proximity {
		var accuracy = getAccuracy(rssi);
		return if (accuracy < 0) Unknown;
		else if (accuracy < 0.5) Immediate;
		else if (accuracy < 4.0) Near;
		else Far;
	}
	
	public function serialize():Bytes {
		var bytes = Bytes.alloc(25);
		bytes.set(0, 0x4c);
		bytes.set(1, 0x00);
		bytes.set(2, 0x02);
		bytes.set(3, 0x15);
		bytes.blit(4, uuid, 0, uuid.length);
		bytes.set(20, (major >> 8) & 0xff);
		bytes.set(21, major & 0xff);
		bytes.set(22, (minor >> 8) & 0xff);
		bytes.set(23, minor & 0xff);
		bytes.set(24, {
			// int8 to uint8
			#if js 
				// http://blog.vjeux.com/2013/javascript/conversion-from-uint8-to-int8-x-24.html
				measuredPower & 0xff;
			#else
				measuredPower < 0 ? measuredPower + 256 : measuredPower;
			#end
		});
		return bytes;
	}
	
	public function toString() {
		return 'iBeacon: uuid = ${uuid.toHex()}, major = $major, minor = $minor, measuredPower = $measuredPower';
	}
}

@:enum
abstract Proximity(Int) {
	var Unknown = 0;
	var Immediate = 1;
	var Near = 2;
	var Far = 3;
	
	public function toString() {
		return switch (cast this:Proximity) {
			case Unknown: 'Unknown';
			case Immediate: 'Immediate';
			case Near: 'Near';
			case Far: 'Far';
		}
	}
}