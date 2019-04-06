package ibeacon;

import haxe.io.Bytes;
import tink.Chunk;

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
 Byte 5-6: Manufacturer ID : 0x4c00 (Apple) or 0x5900 (Nordic)
 Byte 7: SubType: 0x02 (iBeacon)
 Byte 8: SubType Length: 0x15
 Byte 9-24: UUID
 Byte 25-26: Major
 Byte 27-28: Minor
 Byte 29: Signal Power (calibrated power at 1m)

*/

typedef Data = {
	var manufacturer(default, never):Int;
	var uuid(default, never):Chunk;
	var id(default, never):Id;
	var measuredPower(default, never):Int;
}

@:forward
abstract Beacon(Data) from Data{
	public inline function new(data)
		this = data;
		
	public static inline function tryParse(bytes:Bytes):Outcome<Beacon, Error> {
		return Error.catchExceptions(parse.bind(bytes));
	}
	
	// ref: https://github.com/sandeepmistry/node-bleacon/blob/master/lib/bleacon.js
	public static function parse(bytes:Bytes):Beacon {
		if(
			bytes != null &&
			bytes.length >= 25 &&
			(
				(bytes.get(0) == 0x4c && bytes.get(1) == 0x00) || // APPLE_COMPANY_IDENTIFIER (Little Endian)
				(bytes.get(0) == 0x59 && bytes.get(1) == 0x00)  // NORDIC_COMPANY_IDENTIFIER (Little Endian)
			) &&
			bytes.get(2) == 0x02 && // IBEACON_TYPE
			bytes.get(3) == 0x15    // EXPECTED_IBEACON_DATA_LENGTH
		 ) {
			return new Beacon({
				manufacturer: bytes.get(1) << 8 | bytes.get(0),
				uuid: bytes.sub(4, 16),
				id: new Id(bytes.getInt32(20) << 8 | bytes.get(21), bytes.get(22) << 8 | bytes.get(23)),
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
		}
		
		throw 'Not a iBeacon advertisement';
	}
	
	public function getAccuracy(rssi:Int):Float {
		return Math.pow(12.0, 1.5 * ((rssi / this.measuredPower) - 1));
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
		bytes.set(0, this.manufacturer & 0xff);
		bytes.set(1, this.manufacturer >> 8 & 0xff);
		bytes.set(2, 0x02);
		bytes.set(3, 0x15);
		bytes.blit(4, this.uuid, 0, this.uuid.length);
		bytes.set(20, (this.id.major >> 8) & 0xff);
		bytes.set(21, this.id.major & 0xff);
		bytes.set(22, (this.id.minor >> 8) & 0xff);
		bytes.set(23, this.id.minor & 0xff);
		bytes.set(24, {
			// int8 to uint8
			#if js 
				// http://blog.vjeux.com/2013/javascript/conversion-from-uint8-to-int8-x-24.html
				this.measuredPower & 0xff;
			#else
				this.measuredPower < 0 ? this.measuredPower + 256 : this.measuredPower;
			#end
		});
		return bytes;
	}
	
	public function toString() {
		return 'iBeacon: uuid = ${this.uuid.toHex()}, major = ${this.id.major}, minor = ${this.id.minor}, measuredPower = ${this.measuredPower}';
	}
	
	#if tink_json
	
	@:to inline function toRepresentation():tink.json.Representation<Bytes> 
		return new tink.json.Representation(serialize());
		
	@:from static inline function ofRepresentation<T>(rep:tink.json.Representation<Bytes>):Beacon
		return parse(rep.get());
		
	#end
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