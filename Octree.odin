package octree;

import "core:fmt"
import "core:slice"
import "core:math"
import "core:c"

//Linear octree implementation,
//The encoeded bits are stored like so:
// xyzs xyzs ... xyzs
// if there stop bit (s) is 1, then we must stop at that location, including the following 3 bit positions.
//So 0101 0000 ... 0000, means that the size of the voxel is the stop bits (level) in the encoding.
//It sadly also means that the final level om compression (where all blocks are the same is not representable).
//This is a small cost to pay for the benefit of the encoding as that level is comperession is the least significant.
//Exampels:
//Look at 4 bits at a time
//if the stop bit is high, stop loading any further but still include the currently loaded ones.
//in the case of : 0100 1111 ... 0000
//that would mean : dont stop, go x negative, y positive, z negative,
//following : stop, go x positive, y positive, z positive.
//Having the stop bit after the positional bits, we can easly compare encodings.
//Oberserve the following bits:
//1000 0100 0010 1001, this means go x, y, then z, and then x again and stop.
//If we would like to see if this is contained in the array, we first search for the range of encodings that caontain:
//100U UUUU UUUU UUUU, where U is undefined/don't care bits, once the range of all these have been esthablished
//We can check if the upper bound of the range and the lower bound of the range is the same
//if they are then the stop bit must also be 1. like so:
//1001 UUUU UUUU UUUU
//We can assert for this.
//if they are not, then the octants are not compressed to this level, instead, we continue the seach one level down.
//Now look for anything in the range:
//1000 010U UUUU UUUU
//If the one with the stop bit is found, then return that we have found the container octant.
//If not, then we can check the following
//1000 0100 001U UUUU
//and so on...

TRACY_ENABLE :: #config(TRACY_ENABLE, false)
import tracy "../tracy"

Iterator :: struct(Data_type : typeid) {
    index : int,
    octree : ^Octree(Data_type),
}

Octant :: struct(Holding : typeid) {
    encoding : u32,
    data : Holding,
}

Octree :: struct(Holding : typeid) {
    entries : [dynamic]Octant(Holding), //TODO try with soa
}

make_iterator :: proc(octree : ^Octree($Holding)) -> Iterator(Holding) {

    return Iterator(Holding){index = 0, octree = octree};
}

@(optimization_mode = "speed")
iterate :: proc(it : ^Iterator($Holding)) -> (key: [4]i16, val: Holding, cond: bool) {
    tracy.Zone();

    cond = it.index < len(it.octree.entries);
    
    if cond {
        e := it.octree.entries[it.index];
        x,y,z,stop:= _decode_morton(e.encoding);
        key = {x,y,z,stop};
        val = e.data;
        it.index += 1
    }
    
    return
}

init_octree :: proc(using o : ^Octree($Holding)) {

	_init_internal();

	//o.entries = make([dynamic]Octant(Holding));
}

@(optimization_mode = "speed")
set_at :: proc(using o : ^Octree($Holding), data : Holding, pos : [3]i16, loc := #caller_location) {
	tracy.Zone();
	
	seaching_for : u32 = get_encoding(pos.x, pos.y, pos.z, 1);

	//if not found index is return as where it would be.
	octant, found, index, level := find_container_octant(o, seaching_for);

	if !found {
		//fmt.printf("not found, insert at index : %32b\n", seaching_for);
		{
			tracy.ZoneN("inject at");
			inject_at(&entries, index, Octant(Holding){encoding = seaching_for, data = data});
		}
		//_check_sorted(o, index, loc);
		prune(o, index - 8, index + 8); //todo add range , index - 8, index + 8
	}
	else if found && level == 1 {
		entries[index].data = data;
		prune(o, index - 8, index + 8); //todo add range , index - 8, index + 8
	}
	else if found {
		//split_octant();
		//octant, found, index, level := find_container_octant(o, pos);
		//find it again and then set_at again maybe?
		panic("Unimplemented");
	}
	else{
		panic("Unimplemented");
	}

}

//Is only fast for very small octrees.
unordered_add :: proc(using o : ^Octree($Holding), data : Holding, pos : [3]i16, loc := #caller_location) {
    using slice;
	tracy.Zone();

    enc : u32 = get_encoding(pos.x, pos.y, pos.z, 1);
    append(&entries, Octant(Holding){encoding = enc, data = data});
}

find_container_octant :: proc{find_container_octant_encoding, find_container_octant_pos}

find_container_octant_pos :: proc(using o : ^Octree($Holding), pos : [3]i16) -> 
								(octant : Octant(Holding), found : bool, index : int, level : i16) {
	return find_container_octant_encoding(o, get_encoding(pos.x, pos.y, pos.z, 1));
}

@(optimization_mode = "speed")
find_container_octant_encoding :: proc(using o : ^Octree($Holding), seaching_for : u32) -> 
								(octant : Octant(Holding), found : bool, index : int, level : i16) {
	tracy.Zone();
	
	found = false;
	
    if len(entries) == 0 {
        return;
    }

	//_,_,_,l := _decode_morton(seaching_for);
	//assert(l == 1 || l == 2 || l == 4 || l == 8 || l == 16 || l == 32 || l == 64 || l == 128);
	
	//Binary search
	upper_bound := len(entries) - 1;
    lower_bound := 0;

   	for lower_bound <= upper_bound {

        index = (upper_bound + lower_bound) / 2;
        enc := entries[index].encoding;

		//fmt.printf("Looking at index : %v\n", index);

		if _does_encoding_contain_enconding(enc, seaching_for) {
            //Found
			fmt.printf("Found at index : %v for enc : %v : %#v\n", index, seaching_for, entries);
            found = true;
            octant = entries[index];
			
			x,y,z,l := _decode_morton(entries[index].encoding);
			level = l;

			if index != 0 {
				assert(entries[index - 1].encoding < seaching_for);
			}
			if index != len(entries) - 1 {
			 	assert(entries[index + 1].encoding > seaching_for);
			}
			return;
        }

        if  enc < seaching_for {
            lower_bound = index + 1;
        }
        else if enc > seaching_for {
            upper_bound = index - 1;
        }
    }
	
	index += 1;
	
	if index != 0 {
		if seaching_for < entries[index - 1].encoding {
			index -= 1;
		}
	}
	
	//linear search
	/*
	for e, i in entries {
		
		index = i;
		
		if e.encoding >= seaching_for { //TODO binary search

			//fmt.printf("Found barrier\n");
			
			if _does_encoding_contain_enconding(entries[index].encoding, seaching_for) {
				found = true;
				octant = entries[index];

				x,y,z,l := _decode_morton(entries[index].encoding);
				level = l;
			}
			
			return;
		}
	}
	
	index += 1;
	*/


	/* 
	/////////asserts////////////

	if index != 0 {
		assert(entries[index - 1].encoding < seaching_for);
	}
	if index < len(entries) - 1 {
		assert(entries[index + 1].encoding > seaching_for);
	}

	if index <= len(entries) - 1 {
		_,_,_,l := _decode_morton(entries[index].encoding);
		assert(l == 1 || l == 2 || l == 4 || l == 8 || l == 16 || l == 32 || l == 64 || l == 128);
		assert(entries[index].encoding >= seaching_for, 
			fmt.tprintf("at index : %v seaching_for : %v, while enntires %v!", index, seaching_for, entries[index]));
	}
	
	//fmt.printf("Found nothing index is at last pos : %v, len : %v\n", index, len(entries));
	*/

	return;
}

@(optimization_mode = "speed")
sort :: proc (using o : ^Octree($Holding)) {
	tracy.Zone();

    slice.sort_by(entries[:], proc(i : Octant(Holding), j : Octant(Holding)) -> bool {
		
        assert(i.encoding != j.encoding, fmt.tprintf("Encoding must not be the same in %v"));
        return i.encoding < j.encoding;
    });
}

@(optimization_mode = "speed")
prune_ranged :: proc(using o : ^Octree($Holding), lower : int, upper : int) {
    //Combines voxels of same type.
	tracy.Zone();

	lower : int = math.max(0, lower);
	upper : int = math.min(len(entries)-1, upper);

	Comb :: struct {
		index : int,
	};

	operations := make([dynamic]Comb, 0, 10, context.temp_allocator);

    for depth : i16 = 0; depth <= MAX_DEPTH; depth += 1 {
		
		new_low : int = len(entries);
		new_upp : int = 0;
		
		clear(&operations);

		mask := _get_mask(depth + 1, false);
		//fmt.printf("mask : %32b\n", mask);
		assert(mask != 0);
		same_cnt := 0;
        last_val : u32;
        last_data : Holding;
		{
			tracy.ZoneN("Searching zone");

			#no_bounds_check for i in lower..=upper { //TODO look 8 ahead, if it is not the same, then skip some of them (binary search forward?)
				e := entries[i];

				val : u32 = e.encoding & mask;
				x,y,z,s := _decode_morton(val);
				pos_val : [4]i16 = {x,y,z,s};

				if val == last_val && last_data == e.data && s != 0 {
					same_cnt += 1;

					//slow assert
					//assert(same_cnt <= 8, fmt.tprintf("same_cnt is higher then 8, val is : %v, encoding is : %32b, mask is : %32b\n", val, e.encoding, mask));

					if same_cnt == 8 {
						//fmt.printf("got to : %i, with level : %i, depth is : %i, val : %v\n", same_cnt, s, depth, pos_val);
						//there are 8 octants of same type inside a bigger octant
						//Now they should be combined.
						new_encoding := get_encoding(x, y, z, s << 1);
						
						comb : Comb = {
							index = i - 7,
						};
						append(&operations, comb);

						entries[comb.index] = Octant(Holding){encoding = new_encoding, data = e.data};
					}
				}
				else {
					same_cnt = 1;
				}
				
				last_val = val;
				last_data = e.data;
			}
		}

		{
			tracy.ZoneN("Combination execution");
			//becasuse we remove elements, we do it reverse, this keeps the ordering.
			#reverse for comb in operations {
				new_upp -= 7; // we remove 7 elements, and so we have to check 7 less.

				//fmt.printf("comb : %v\n", comb);
				//remove 7 elements, and replace the first one with the bigger octant.
				remove_range(&entries, comb.index + 1, comb.index + 8);

				//_check_sorted(o, comb.index);
				new_low = math.min(comb.index, new_low);
				new_upp = math.max(comb.index, new_upp);
			}
		}

        if len(operations) == 0 {
            break;
        }
		
		lower = math.max(0, new_low - 8);
		upper = math.min(len(entries) - 1, new_upp + 8);

    }
}

prune_octree :: proc(using o : ^Octree($Holding)) {
	prune_ranged(o, 0, len(entries) - 1);
}

prune :: proc{prune_ranged, prune_octree};

destroy_octree :: proc(using o : ^Octree($Holding)) {
	tracy.Zone();

	delete(o.entries);
}