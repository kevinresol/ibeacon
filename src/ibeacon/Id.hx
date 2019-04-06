package ibeacon;

abstract Id(Int) from Int to Int {
	public var major(get, never):Int;
	public var minor(get, never):Int;
	
	public inline function new(major, minor)
		this = (minor & 0xffff) << 16 | (major & 0xffff);
		
	inline function get_major():Int
		return this & 0xffff;
		
	inline function get_minor():Int
		return this >>> 16;
	
	#if js
	public function toHex():String
		return untyped __js__('{0}.toString(16)', this);
	#end
}