package octree;

import "core:fmt"
import "core:slice"
import "core:sync"

import math_big "core:math/big"

_init_mutex : sync.Mutex;
_is_init : bool = false;
morton_encodings : [256][256][256][8]u32;
morton_decodings : map[u32][256][256][256][8]u8;

get_encoding ::  proc(x : i16, y : i16, z : i16, l : i16) -> u32{
	
	//depth := math_big.ilog2(l);
	//return morton_encodings[x][y][z][depth];

	return _encode_morton(x,y,z,l);
}

_init_internal :: proc() {

	/* 
	sync.lock(&_init_mutex);
	defer sync.unlock(&_init_mutex);

	if !_is_init {
		for x in 0..=255 {
			for y in 0..=255  {
				for z in 0..=255  {
					for l in 0..=7  {
						morton_encodings[x][y][z][l] = _encode_morton(i16(x),i16(y),i16(z),i16(1 << u16(l - 1)));
					}
				}
			}
		}
	}

	_is_init = true;
	*/
}

_check_sorted :: proc(using o : ^Octree($Holding), index : int, loc := #caller_location) {
	if index != 0 {
		x,y,z,l := _decode_morton(entries[index].encoding);
		x2,y2,z2,l2 := _decode_morton(entries[index - 1].encoding);
		assert(entries[index - 1].encoding <= entries[index].encoding, 
			fmt.tprintf("Entries not sorted, at index : %v is %v, at index %v is %v\n Pos : (%v,%v,%v,%v), pos2 : (%v,%v,%v,%v)",
					index, entries[index].encoding, index - 1, entries[index - 1].encoding, x,y,z,l, x2,y2,z2,l2), loc);
	}
	if index != len(entries) - 1 {
		x,y,z,l := _decode_morton(entries[index].encoding);
		x2,y2,z2,l2 := _decode_morton(entries[index + 1].encoding);
		assert(entries[index + 1].encoding >= entries[index].encoding, 
			fmt.tprintf("Entries not sorted, at index : %v is %v, at index %v is %v\n Pos : (%v,%v,%v,%v), pos2 : (%v,%v,%v,%v)",
					index, entries[index].encoding, index + 1, entries[index + 1].encoding, x,y,z,l, x2,y2,z2,l2), loc);
	}
}

_does_encoding_contain_enconding :: proc(container : u32, child : u32) -> bool {

	for i := MAX_DEPTH; i >= 0; i -= 1 {
		m : u32 = u32(i) * 4;
        p_data : u32 = (container & (0b1111 << m)) >> m;
		c_data : u32 = (child & (0b1111 << m)) >> m;
		s : bool = (p_data & 1) != 0;
		p_data = p_data >> 1;
		c_data = c_data >> 1;

		if p_data != c_data {
			return false;
		}
		if s == true {
			return true;
		}
    }

	return false;
	//unreachable();
}