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
get_armour_name, get_armour_value, get_potion_name, get_potion_heal */

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
        
