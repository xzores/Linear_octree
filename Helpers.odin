package octree;

import "core:slice"

MAX_DEPTH :: 7;
LEVEL_MASK : u32 : 0b1111;
CHAR_BIT :: 8; //8 bits in a u8

@(optimization_mode = "speed")
_encode_morton :: proc(x : i16, y : i16, z : i16, l : i16, loc := #caller_location) -> u32 {
	answer : u32 = 0;
	
	/*
    assert(x >= 0, 		"x under 0", loc);
    assert(x <= 255, 	"x over limits", loc);
    
	assert(y >= 0, 		"y under 0", loc);
    assert(y <= 255, 	"y over limits", loc);
	
	assert(z >= 0, 		"z under 0", loc);
    assert(z <= 255, 	"z over limits", loc);
	
	assert(l >= 0, 		"stopunder 0", loc);
    assert(l <= 255, 	"stopover limits", loc);
	*/

    ONE : u32 : 1;
    for i : u32 = 0; i < (size_of(u32)* CHAR_BIT) / 4; i+=1 {
        answer |= 	((u32(l) & (ONE << i)) << (3 * i + 0)) |
					((u32(z) & (ONE << i)) << (3 * i + 1)) |
                 	((u32(y) & (ONE << i)) << (3 * i + 2)) |
                 	((u32(x) & (ONE << i)) << (3 * i + 3));
    }

    return answer;
}

@(optimization_mode = "speed")
_decode_morton :: proc (encoding : u32, loc := #caller_location) -> (x : i16, y : i16, z : i16, l : i16) {

	for i : u32 = 0; i < CHAR_BIT; i+=1 {
		l |= i16((encoding & (u32(1) << (4 * i + 0))) >> (3 * i + 0));
		z |= i16((encoding & (u32(1) << (4 * i + 1))) >> (3 * i + 1));
		y |= i16((encoding & (u32(1) << (4 * i + 2))) >> (3 * i + 2));
		x |= i16((encoding & (u32(1) << (4 * i + 3))) >> (3 * i + 3));
	}

    return;
}

_get_mask :: proc (depth : i16, mask_off_stop : bool) -> u32 {
	
    mask : u32 = 0b1111_1111_1111_1111_1111_1111_1111_1111;

    for i : i16 = 0; i < depth; i+= 1 {
        mask = mask << 4;
    }
	
	if !mask_off_stop {
		mask = mask | (1 << u16(4 * (depth - 1)));
	}

    return mask;
}
