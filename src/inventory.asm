/* item side of the game; holds:
- names and numbers for every weapon, armour, and potion
- item bag (only holds potions); 4 int array in .bss
- bag functions (these are the only things that can 
interact with the bag)

- equipped items (armour, weapons) are plain ints for
player.asm to keep track of; this file just holds item info
- any item of type 0 always means nothing; weapon 0 is fists, 
armour 0 means no armour equipped, potion 0 is empty slot

- call get_weapon_damage when calculating player attack damage
- call get_armour_value when calculating damage player is taking
- other callable functions: get_weapon_name, get_weapon_damage, 
get_armour_name, get_armour_value, get_potion_name, get_potion_heal,
bag_wipe, bag_add_potion, bag_use_potion and bag_print */

define(fp, x29)
define(lr, x30)
define(table_address_reg, x9)
define(bag_address_reg, x10)
define(slot_index_reg, w11)
define(potion_in_slot_reg, w12)

BAG_SLOTS = 4
NO_POTION = 0
BAG_FULL = -1

pb_slot_s = 16
pb_alloc = -(16 + 4) & -16
pb_dealloc = -pb_alloc

    .text
fists_name_m:        .string "Fists"
dagger_name_m:       .string "Dagger"
club_name_m:         .string "Club"
sword_name_m:        .string "Sword"
no_armour_name_m:    .string "No Armour"
vest_name_m:         .string "Leather Vest"
chain_name_m:        .string "Chain Mail"
plate_name_m:        .string "Iron Chestplate"
empty_slot_name_m:   .string "(empty)"
small_potion_name_m: .string "Small Potion"
large_potion_name_m: .string "Large Potion"
bag_header_fmt:      .string "Potions:\n"
bag_slot_fmt:        .string "  [%d] %s\n" // %s is the potion name

    .data
/* each list of items is an array; each element holds the address of an
item name (not the names themselves because they are all different sizes
and that makes it hard to traverse the array). The index of each item in
the array is the type number (0 = fists, 1 = dagger, 2 = club, 3 = sword) */
    .balign 8
weapon_names_m:  .dword fists_name_m, dagger_name_m, club_name_m, sword_name_m
armour_names_m:   .dword no_armour_name_m, vest_name_m, chain_name_m, plate_name_m
potion_names_m:  .dword empty_slot_name_m, small_potion_name_m, large_potion_name_m

// values of each item, list indexes are parallel with item names
    .balign 4
weapon_damage_m: .word 0, 1, 3, 5
armour_values_m:  .word 0, 1, 2, 3
potion_heal_m:   .word 0, 10, 25

    .bss
    .balign 4
bag_m:  .skip BAG_SLOTS * 4 // reserve space for bag

    .text

/* comment for all get functions:
two steps:
 - load address of the start of the list corresponding to the function
 - load entry number w0 from the list

 - none of these functions check for the validity of the type number;
 the numbers passed to these functions must come from within the code 
 
 - all take item index in w0
 - all overwrite x0 for the result (address of name for name getters
 and int values for value getters) and x9 for the list address*/

    .balign 4
    .global get_weapon_name
get_weapon_name:
        ldr     table_address_reg, =weapon_names_m
        ldr     x0, [table_address_reg, w0, sxtw 3]
        ret

    .balign 4
    .global get_weapon_damage
get_weapon_damage:
        ldr     table_address_reg, =weapon_damage_m
        ldr     w0, [table_address_reg, w0, sxtw 2]
        ret

    .balign 4
    .global get_armour_name
get_armour_name:
        ldr     table_address_reg, =armour_names_m
        ldr     x0, [table_address_reg, w0, sxtw 3]
        ret

    .balign 4
    .global get_armour_value
get_armour_value:
        ldr     table_address_reg, =armour_values_m
        ldr     w0, [table_address_reg, w0, sxtw 2]
        ret

    .balign 4
    .global get_potion_name
get_potion_name:
        ldr     table_address_reg, =potion_names_m
        ldr     x0, [table_address_reg, w0, sxtw 3]
        ret

    .balign 4
    .global get_potion_heal
get_potion_heal:
        ldr     table_address_reg, =potion_heal_m
        ldr     w0, [table_address_reg, w0, sxtw 2]
        ret

/* writes 0 into all four bag slots, not required to
use at the beginning of the game, only needed if you
 want to wipe the entire inventory mid game or if
the game restarts without the program ending; no input/output;
overwrites bag address in x10 and slot index in x11 */
    .balign 4
    .global bag_wipe
bag_wipe:
        ldr     bag_address_reg, =bag_m
        mov     slot_index_reg, 0

bag_wipe_test:
        cmp     slot_index_reg, BAG_SLOTS
        b.ge    bag_wipe_done
        // slot address = bag address + slot * 4 bytes
        str     wzr, [bag_address_reg, slot_index_reg, sxtw 2]
        add     slot_index_reg, slot_index_reg, 1
        b       bag_wipe_test
        
bag_wipe_done:
        ret

/* finds the first empty slot of the bag and puts a potion in it;
could be used when the player picks up a potion or receives one as
a reward. Input is an int (1 or 2) in w0 which is the potion type and
output is the slot number of the bag that the potion went into (1-4)
or -1 if the bag is full. IMPORTANT: input is not checked
Overwrites x0, x10, x11, x12 
note: the slot numbers are 1-4 instead of index numbers 0-3 so that
they match what the player would type when using
bag_use_potion, and what the slot numbers show in bag_print */
    .balign 4
    .global bag_add_potion
bag_add_potion:
        ldr     bag_address_reg, =bag_m
        mov     slot_index_reg, 0

// loop to check each slot starting from index 0 to see if slot is empty
bag_add_test:
        cmp     slot_index_reg, BAG_SLOTS
        b.ge    bag_add_full
        ldr     potion_in_slot_reg, [bag_address_reg, slot_index_reg, sxtw 2]
        cmp     potion_in_slot_reg, NO_POTION
        b.eq    bag_add_place
        add     slot_index_reg, slot_index_reg, 1
        b       bag_add_test

bag_add_place:
        str     w0, [bag_address_reg, slot_index_reg, sxtw 2]
        add     w0, slot_index_reg, 1
        b       bag_add_return

bag_add_full:
        mov     w0, BAG_FULL

bag_add_return:
        ret

/* empties a bag slot and returns how much HP the potion
in the slot should heal. This function does not actually
heal the player, just returns the required data to calculate that.
input is the potion slot number (1-4) that the player types.
output is the HP that the potion heals in w0 (10 for small, 25 for large)
or 0 can be returned in w0 if the bag slot is empty or invalid
overwrites x0, x9, x10, x11, x12 */
    .balign 4
    .global bag_use_potion
bag_use_potion:
        ldr     bag_address_reg, =bag_m
        sub     slot_index_reg, w0, 1 // turn typed number into index

// check for valid slot number since it comes from player input
        cmp     slot_index_reg, 0
        b.lt    bag_use_nothing
        cmp     slot_index_reg, BAG_SLOTS
        b.ge    bag_use_nothing

// read potion type, then empty slot, then check how much the selected potion heals
        ldr     potion_in_slot_reg, [bag_address_reg, slot_index_reg, sxtw 2]
        str     wzr, [bag_address_reg, slot_index_reg, sxtw 2]
        ldr     table_address_reg, =potion_heal_m
        ldr     w0, [table_address_reg, potion_in_slot_reg, sxtw 2]
        b       bag_use_return

bag_use_nothing:
        mov     w0, 0

bag_use_return:
        ret

/* prints entire bag in this format:
Potions:
    [1] Small Potion
    [2] (empty)
    [3] Small Potion
    [4] Large Potion
no input, no output, overwrites x0, x1, x2, x9, x10,
x11, x12, and printf may overwrite any of x0-x18 */
        .balign 4
        .global bag_print
bag_print:
        stp     fp, lr, [sp, pb_alloc]!
        mov     fp, sp

        ldr     x0, =bag_header_fmt
        bl      printf

        str     wzr, [fp, pb_slot_s]

pb_test:
        ldr     slot_index_reg, [fp, pb_slot_s]
        cmp     slot_index_reg, BAG_SLOTS
        b.ge    pb_done
        ldr     bag_address_reg, =bag_m

// read potion type, retrieve potion name for printing
        ldr     potion_in_slot_reg, [bag_address_reg, slot_index_reg, sxtw 2]
        ldr     table_address_reg, =potion_names_m
        ldr     x2, [table_address_reg, potion_in_slot_reg, sxtw 3]

        add     w1, slot_index_reg, 1 // index + 1 so that slots are numbered 1-4
        ldr     x0, =bag_slot_fmt
        bl      printf

        ldr     slot_index_reg, [fp, pb_slot_s]
        add     slot_index_reg, slot_index_reg, 1
        str     slot_index_reg, [fp, pb_slot_s]
        b       pb_test

pb_done:
        ldp     fp, lr, [sp], pb_dealloc
        ret
