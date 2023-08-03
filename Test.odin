package octree;

import "core:fmt"
import "core:testing"
import "core:math"

Empty :: struct {
    state : u16
}

@test
test_encode_decode :: proc (t : ^testing.T) {

	stop : i16 = 1;
    for x : i16 = 0; x < 255; x += 1 {
		for y : i16 = 0; y < 255; y += 1 {
			for z : i16 = 0; z < 255; z += 1 {
				encoding := _encode_morton(x, y, z, stop);
				x2,y2,z2,s2 := _decode_morton(encoding);

				if x != x2 || y != y2 || z != z2 || stop != s2 {
					fmt.printf("v : (%v,%v,%v,%v), v2 : (%v,%v,%v,%v), encoding : %32b\n", stop,x,y,z, s2,x2,y2,z2, encoding);
				}

				testing.expect(t, (x == x2));
				testing.expect(t, (y == y2));
				testing.expect(t, (z == z2));
				testing.expect(t, (stop == s2));
			}
		}
	}
}

@test
test_add_prune :: proc (t : ^testing.T) {

    o : Octree(Empty);

    testing.expect(t, len(o.entries) == 0);

    unordered_add(&o, Empty{}, [3]i16{0,0,0});

    testing.expect(t, len(o.entries) == 1);

    unordered_add(&o, Empty{}, [3]i16{0,0,1});
    unordered_add(&o, Empty{}, [3]i16{0,1,0});
    unordered_add(&o, Empty{}, [3]i16{0,1,1});
    unordered_add(&o, Empty{}, [3]i16{1,0,0});
    unordered_add(&o, Empty{}, [3]i16{1,0,1});
    unordered_add(&o, Empty{}, [3]i16{1,1,0});
    unordered_add(&o, Empty{}, [3]i16{1,1,1});

    testing.expect(t, len(o.entries) == 8);

    prune(&o);

    testing.expect(t, len(o.entries) == 1);

    x,y,z,l := _decode_morton(o.entries[0].encoding);

    testing.expect(t, x == 0);
    testing.expect(t, y == 0);
    testing.expect(t, z == 0);
    testing.expect(t, l == 2, fmt.tprintf("l was : %v", l));

    unordered_add(&o, Empty{}, [3]i16{2,0,0});
    unordered_add(&o, Empty{}, [3]i16{2,0,1});
    unordered_add(&o, Empty{}, [3]i16{2,1,0});
    unordered_add(&o, Empty{}, [3]i16{2,1,1});
    unordered_add(&o, Empty{}, [3]i16{3,0,0});
    unordered_add(&o, Empty{}, [3]i16{3,0,1});
    unordered_add(&o, Empty{}, [3]i16{3,1,0});
    unordered_add(&o, Empty{}, [3]i16{3,1,1});

    testing.expect(t, len(o.entries) == 9);

    prune(&o);

    testing.expect(t, len(o.entries) == 2);

	x2,y2,z2,l2 := _decode_morton(o.entries[1].encoding);

	testing.expect(t, x2 == 2);
    testing.expect(t, y2 == 0);
    testing.expect(t, z2 == 0);
    testing.expect(t, l2 == 2);

    unordered_add(&o, Empty{}, [3]i16{0,2,0});
    unordered_add(&o, Empty{}, [3]i16{0,2,1});
    unordered_add(&o, Empty{}, [3]i16{0,3,0});
    unordered_add(&o, Empty{}, [3]i16{0,3,1});
    unordered_add(&o, Empty{}, [3]i16{1,2,0});
    unordered_add(&o, Empty{}, [3]i16{1,2,1});
    unordered_add(&o, Empty{}, [3]i16{1,3,0});
    unordered_add(&o, Empty{}, [3]i16{1,3,1});

    testing.expect(t, len(o.entries) == 10);

	unordered_add(&o, Empty{}, [3]i16{0,0,2});
    unordered_add(&o, Empty{}, [3]i16{0,0,3});
    unordered_add(&o, Empty{}, [3]i16{0,1,2});
    unordered_add(&o, Empty{}, [3]i16{0,1,3});
    unordered_add(&o, Empty{}, [3]i16{1,0,2});
    unordered_add(&o, Empty{}, [3]i16{1,0,3});
    unordered_add(&o, Empty{}, [3]i16{1,1,2});
    unordered_add(&o, Empty{}, [3]i16{1,1,3});

	testing.expect(t, len(o.entries) == 18);

	unordered_add(&o, Empty{}, [3]i16{2,2,0});
    unordered_add(&o, Empty{}, [3]i16{2,2,1});
    unordered_add(&o, Empty{}, [3]i16{2,3,0});
    unordered_add(&o, Empty{}, [3]i16{2,3,1});
    unordered_add(&o, Empty{}, [3]i16{3,2,0});
    unordered_add(&o, Empty{}, [3]i16{3,2,1});
    unordered_add(&o, Empty{}, [3]i16{3,3,0});
    unordered_add(&o, Empty{}, [3]i16{3,3,1});

	unordered_add(&o, Empty{}, [3]i16{2,0,2});
    unordered_add(&o, Empty{}, [3]i16{2,0,3});
    unordered_add(&o, Empty{}, [3]i16{2,1,2});
    unordered_add(&o, Empty{}, [3]i16{2,1,3});
    unordered_add(&o, Empty{}, [3]i16{3,0,2});
    unordered_add(&o, Empty{}, [3]i16{3,0,3});
    unordered_add(&o, Empty{}, [3]i16{3,1,2});
    unordered_add(&o, Empty{}, [3]i16{3,1,3});

	unordered_add(&o, Empty{}, [3]i16{0,2,2});
    unordered_add(&o, Empty{}, [3]i16{0,2,3});
    unordered_add(&o, Empty{}, [3]i16{0,3,2});
    unordered_add(&o, Empty{}, [3]i16{0,3,3});
    unordered_add(&o, Empty{}, [3]i16{1,2,2});
    unordered_add(&o, Empty{}, [3]i16{1,2,3});
    unordered_add(&o, Empty{}, [3]i16{1,3,2});
    unordered_add(&o, Empty{}, [3]i16{1,3,3});

	unordered_add(&o, Empty{}, [3]i16{2,2,2});
    unordered_add(&o, Empty{}, [3]i16{2,2,3});
    unordered_add(&o, Empty{}, [3]i16{2,3,2});
    unordered_add(&o, Empty{}, [3]i16{2,3,3});
    unordered_add(&o, Empty{}, [3]i16{3,2,2});
    unordered_add(&o, Empty{}, [3]i16{3,2,3});
    unordered_add(&o, Empty{}, [3]i16{3,3,2});
    unordered_add(&o, Empty{}, [3]i16{3,3,3});

	sort(&o);
	prune(&o);

	testing.expect(t, len(o.entries) == 1);
}

@test
test_find :: proc (t : ^testing.T) {

    o : Octree(Empty);

    testing.expect(t, len(o.entries) == 0);

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,0});
		assert(found == false);
	}

	unordered_add(&o, Empty{}, [3]i16{0,0,0});

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,0});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 0, 1));
		assert(index == 0);
		assert(level == 1);
	}

	unordered_add(&o, Empty{}, [3]i16{0,0,1});

	sort(&o);

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,0});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 0, 1));
		assert(index == 0);
		assert(level == 1);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,1});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 1, 1));
		assert(index == 1);
		assert(level == 1);
	}

    unordered_add(&o, Empty{}, [3]i16{0,1,0});
    unordered_add(&o, Empty{}, [3]i16{0,1,1});
    unordered_add(&o, Empty{}, [3]i16{1,0,0});
    unordered_add(&o, Empty{}, [3]i16{1,0,1});
    unordered_add(&o, Empty{}, [3]i16{1,1,0});
    unordered_add(&o, Empty{}, [3]i16{1,1,1});

	sort(&o);
	prune(&o);

	fmt.printf("&o : %v\n", &o);

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,0});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 0, 2));
		assert(index == 0);
		assert(level == 2);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,1});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 0, 2));
		assert(index == 0);
		assert(level == 2);
	}
}


@test
test_set_at :: proc (t : ^testing.T) {

    o : Octree(Empty);

    testing.expect(t, len(o.entries) == 0);

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,0});
		assert(found == false);
	}

	set_at(&o, Empty{}, [3]i16{0,0,0});

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,0});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 0, 1));
		assert(index == 0);
		assert(level == 1);
	}

	set_at(&o, Empty{}, [3]i16{0,0,1});

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,0});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 0, 1));
		assert(index == 0);
		assert(level == 1);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,1});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 1, 1));
		assert(index == 1);
		assert(level == 1);
	}

    set_at(&o, Empty{}, [3]i16{0,1,0});
    set_at(&o, Empty{}, [3]i16{0,1,1});
    set_at(&o, Empty{}, [3]i16{1,0,0});
    set_at(&o, Empty{}, [3]i16{1,0,1});
    set_at(&o, Empty{}, [3]i16{1,1,0});
    set_at(&o, Empty{}, [3]i16{1,1,1});

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,0});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 0, 2));
		assert(index == 0);
		assert(level == 2);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,0,1});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 0, 0, 2));
		assert(index == 0);
		assert(level == 2);
	}

	assert(len(o.entries) == 1);

	set_at(&o, Empty{}, [3]i16{0,10,12});
	set_at(&o, Empty{}, [3]i16{1,2,16});
	set_at(&o, Empty{}, [3]i16{0,2,4});
	set_at(&o, Empty{}, [3]i16{3,0,2});

	assert(len(o.entries) == 5);

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,10,12});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 10, 12, 1));
		assert(level == 1);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{1,2,16});
		assert(found == true);
		assert(octant.encoding == _encode_morton(1, 2, 16, 1));
		assert(level == 1);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{0,2,4});
		assert(found == true);
		assert(octant.encoding == _encode_morton(0, 2, 4, 1));
		assert(level == 1);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{3,0,2});
		assert(found == true);
		assert(octant.encoding == _encode_morton(3, 0, 2, 1));
		assert(level == 1);
	}

	set_at(&o, Empty{}, [3]i16{50,10,12});
	set_at(&o, Empty{}, [3]i16{2,23,16});
	set_at(&o, Empty{}, [3]i16{127,2,4});
	set_at(&o, Empty{}, [3]i16{5,12,147});

	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{50,10,12});
		assert(found == true);
		assert(octant.encoding == _encode_morton(50,10,12, 1));
		assert(level == 1);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{2,23,16});
		assert(found == true);
		assert(octant.encoding == _encode_morton(2,23,16, 1));
		assert(level == 1);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{127,2,4});
		assert(found == true);
		assert(octant.encoding == _encode_morton(127,2,4, 1));
		assert(level == 1);
	}
	{
    	octant, found, index, level := find_container_octant(&o, [3]i16{5,12,147});
		assert(found == true);
		assert(octant.encoding == _encode_morton(5,12,147, 1));
		assert(level == 1);
	}


}


/*
@test
test_mask :: proc (t : ^testing.T) {

    for stop: i16 = 0; stop<= 8; level+=1 {
        mask := _get_mask(level);
        
        goes_to : i16 = i16(math.pow(f32(2), f32(level)));
        fmt.printf("goes_to : %v, stop: %v, mask : %32b\n", goes_to, level, mask);

        for x : i16 = 0; x < goes_to; x += 1 {
            for y : i16 = 0; y < goes_to; y += 1 {
                for z : i16 = 0; z < goes_to; z += 1 {
                    encoding := _encode_morton(auto_cast x, auto_cast y, auto_cast z, level);
                    x2,y2,z2,l2 := _decode_morton(encoding & (mask | LEVEL_MASK));
                    
                    assert(x == x2);
                    assert(y == y2);
                    assert(z == z2);
                    assert(stop== l2);
                }
            }
        }
    }
}

@test
test_3 :: proc (t : ^testing.T) {

    o : Octree(Empty);

    testing.expect(t, len(o.entries) == 0);

    for x : i16 = 0; x < 255; x += 1 {
        for y : i16 = 0; y < 255; y += 1 {
            for z : i16 = 0; z < 255; z += 1 {
                octant, depth, found, index := _bin_search(&o, _encode_morton(x, y, z, 8));

                testing.expect(t, found == false);
            }
        }
    }

    unordered_add(&o, Empty{}, [3]i16{0,0,0});

    testing.expect(t, len(o.entries) == 1);

    for stop: i16 = 0; stop<= 7; level+=1 {
        for x : i16 = 0; x < 255; x += 1 {
            for y : i16 = 0; y < 255; y += 1 {
                for z : i16 = 0; z < 255; z += 1 {
                    sf := _encode_morton(x, y, z, level);
                    octant, depth, found, index := _bin_search(&o, sf);

                    if x == 0 && y == 0 && z == 0 && stop== 8 {
                        testing.expect(t, found == true);
                        testing.expect(t, depth == 7);
                        testing.expect(t, index == 0);
                    }
                    else {
                        testing.expect(t, found == false);
                    }
                }
            }
        }
    }

    testing.expect(t, len(o.entries) == 1);

    unordered_add(&o, Empty{}, [3]i16{0,0,1});
    unordered_add(&o, Empty{}, [3]i16{0,1,0});
    unordered_add(&o, Empty{}, [3]i16{0,1,1});
    unordered_add(&o, Empty{}, [3]i16{1,0,0});
    unordered_add(&o, Empty{}, [3]i16{1,0,1});
    unordered_add(&o, Empty{}, [3]i16{1,1,0});
    unordered_add(&o, Empty{}, [3]i16{1,1,1});

    testing.expect(t, len(o.entries) == 8);

    prune(&o);

    testing.expect(t, len(o.entries) == 1);

    for stop: i16 = 0; stop<= 8; level+=1 {
        for x : i16 = 0; x < 255; x += 1 {
            for y : i16 = 0; y < 255; y += 1 {
                for z : i16 = 0; z < 255; z += 1 {
                    sf := _encode_morton(x, y, z, level);
                    octant, depth, found, index := _bin_search(&o, sf);

                    if x == 0 && y == 0 && z == 0 && stop== 7 {
                        testing.expect(t, found == true);
                        testing.expect(t, depth == 6);
                        testing.expect(t, index == 0);
                    }
                    else {
                        if found == true {
                            shift := u32(8 - level) * 3;
                            fmt.printf("We unexpectedly found (%v,%v,%v,%v) with encoding %v, looking for encoding : %32b, no shift : %32b, shift amount : %v\n", x,y,z,level, octant.encoding, sf, _encode_morton(x, y, z, 8),shift);
                        }
                        testing.expect(t, found == false);
                    }
                }
            }
        }
    }

}
*/