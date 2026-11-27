/* item side of the game; holds:
- names and numbers for every weapon, armour, and potion
- item bag (only holds potions); 4 int array in .bss
- bag functions (these are the only things that can 
interact with the bag)

- equipped items (armour, weapons) are plain ints for
player.asm to keep track of; this file just holds item info
- any item of type 0 always means nothing; weapon 0 is fists, 
armour 0 means no armour equipped, potion 0 is empty slot

FUNCTIONS:
- call get_weapon_damage when calculating player attack damage;
        give it the weapon type index in w0 and bonus damage is 
        returned in w0 which you can add to base dmg

            mov     w0, w19
            bl      get_weapon_damage
            add     w21, w21, w0

- call get_armour_value when calculating damage player is taking
        give it the armour type index in w0 and damage blocked is 
        returned in w0 which you can sub from dmg taken

            mov     w0, w20
            bl      get_armour_value
            sub     w21, w21, w0

- call get_potion_heal to know how much HP a potion heals;
        give it the potion type index in w0 and this 
        returns the amount of HP the potion heals in w0,
        but doesnt do the healing

            mov     w0, 2
            bl      get_potion_heal

- call get_armour_name, get_weapon_name when printing the equpped items
        these return addresses of name strings in x0 that can be passed to %s
        just give the item type index in w0

            mov     w0, w19
            bl      get_weapon_name
            mov     x1, x0
            ldr     x0, =weapon_fmt
            bl      printf

- call loot_armour, loot_potion, loot_weapon for item drops
        returns a random item type in w0, you can call after a player wins
        a fight, just give it the highest item type index you want to be
        able to roll. You can increase the highest possible item type to
        as the player progresses so they can unlock better items

            mov     w0, 3
            bl      loot_weapon
            mov     w19, w0

- call offer_potion when a player finds a potion; give it the potion
        type (1 or 2) in w0. If the bag has space it goes straight in
        but if not the function will directly handle input from the 
        player and print out the bag and allow the player to choose
        a bag slot for the new potion, replacing what was previously
        there, or leave it behind. Returns the slot that the player
        chose (1-4) or 0 if the player left it behind in w0.

            mov     w0, 2
            bl      loot_potion
            bl      offer_potion
            cmp     w0, 0
            b.eq    potion_left_behind <-- not my function, just a placeholder for what you may want to call

- call bag_use_potion when the player wants to drink a potion
        this function doesnt receive the input from the player
        directly, put player input (bag slot of their choice 1-4) 
        in w0, and the function will empty that slot and return
        how much HP the potion heals in w0. This function does not
        do the healing, just returns how much health to add to player.

            ldr     x0, =slot_fmt
            ldr     x1, =typed_slot_m
            bl      scanf
            ldr     x9, =typed_slot_m
            ldr     w0, [x9]
            bl      bag_use_potion
            add     w22, w22, w0

- call bag_print to print the contents of the bag with slot numbers
        no input or output other than printed lines; you could call
        this right before bag_use_potion when the player wants to
        drink so they can see the slot numbers and bag contents before
        choosing a potion to drink

- call bag_wipe to make the bag empty;
        no input or output, you could use this when the game itself
        restarts while the program is still running (if theres a 
        respawn mechanic or something) or if you just want to troll
        the player */

define(fp, x29)
define(lr, x30)
define(table_address_reg, x9)
define(bag_address_reg, x10)
define(slot_index_reg, w11)
define(potion_in_slot_reg, w12)

define(type_count_reg, w1) // holds given item type count
// holds biggest type index value (type count minus 1) for RNG bounds
define(highest_valid_type_reg, w2)
define(typed_slot_address_reg, x9)

BAG_SLOTS = 4
NO_POTION = 0
BAG_FULL = -1

// used by loot roll functions as a boundary for RNG
WEAPON_TYPE_COUNT = 4
ARMOUR_TYPES_COUNT = 4
POTION_TYPES_COUNT = 3

potion_bag_slot_s = 16
potion_bag_alloc = -(16 + 4) & -16
potion_bag_dealloc = -potion_bag_alloc

offer_potion_type_s = 16
offer_potion_alloc = -(16 + 4) & -16
offer_potion_dealloc = -offer_potion_alloc

loot_item_type_alloc = -16
loot_item_type_dealloc = -loot_item_type_alloc

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
bag_full_fmt:        .string "The potion bag is full! You found a %s (heals %d).\n"
swap_prompt_fmt:     .string "Choose a slot (1-4) to swap it into, replacing the potion in that slot, or 0 to leave it: "
slot_input_fmt:      .string "%d"

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
typed_slot_m:  .skip 4 // reserve space for user input when swapping potions out in bag

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

/* Used by offer_potion Input is an int (1 or 2) in w0 which is the potion type and
output is the slot number of the bag that the potion went into (1-4)
or -1 if the bag is full. IMPORTANT: input is not checked
Overwrites x0, x10, x11, x12 
note: the slot numbers are 1-4 instead of index numbers 0-3 so that
they match what the player would type when using
bag_use_potion, and what the slot numbers show in bag_print */
    .balign 4
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
        stp     fp, lr, [sp, potion_bag_alloc]!
        mov     fp, sp

        ldr     x0, =bag_header_fmt
        bl      printf

        str     wzr, [fp, potion_bag_slot_s]

potion_bag_test:
        ldr     slot_index_reg, [fp, potion_bag_slot_s]
        cmp     slot_index_reg, BAG_SLOTS
        b.ge    potion_bag_done
        ldr     bag_address_reg, =bag_m

// read potion type, retrieve potion name for printing
        ldr     potion_in_slot_reg, [bag_address_reg, slot_index_reg, sxtw 2]
        ldr     table_address_reg, =potion_names_m
        ldr     x2, [table_address_reg, potion_in_slot_reg, sxtw 3]

        add     w1, slot_index_reg, 1 // index + 1 so that slots are numbered 1-4
        ldr     x0, =bag_slot_fmt
        bl      printf

        ldr     slot_index_reg, [fp, potion_bag_slot_s]
        add     slot_index_reg, slot_index_reg, 1
        str     slot_index_reg, [fp, potion_bag_slot_s]
        b       potion_bag_test

potion_bag_done:
        ldp     fp, lr, [sp], potion_bag_dealloc
        ret

/* loot drop functions (loot_weapon, loot_armour, loot_potion)
each loot function randomly picks an item from their respective
item category. Input is the highest item type you want the player
to be able to get, you could make it so that the player can only
get the best item types as the game goes on. Output is an item
type index from 1 to the highest allowed item type specified.
Overwrites w0, w1, w2, get_rand_num_under_n can overwrite any of x0-x18*/
        .balign 4
        .global loot_weapon
loot_weapon:
        mov     type_count_reg, WEAPON_TYPE_COUNT
        b       loot_item_type

        .balign 4
        .global loot_armour
loot_armour:
        mov     type_count_reg, ARMOUR_TYPES_COUNT
        b       loot_item_type

        .balign 4
        .global loot_potion
loot_potion:
        mov     type_count_reg, POTION_TYPES_COUNT
        b       loot_item_type

/* fixes the input number so it is a valid item type index and randomly
chooses a number below it. The chosen number is incremented
by 1 so that the result is not 0 and so that the maximum
allowed number can be rolled. Input is the upper limit in w0,
which if too large or too small is fixed in this function, and
w1 which is the amount of types the item has. Output is a random
type index in w0, anywhere from 1 to the upper limit. 0 cannot
be rolled since that indicates no item. Overwrites w0, w2, 
and get_rand_num_under_n can overwrite x0-x18 */
        .balign 4
loot_item_type:
        stp     fp, lr, [sp, loot_item_type_alloc]!
        mov     fp, sp

/* highest possible item type is item type count minus 1 since
we start from 0; if the caller asks for a higher number, lower
it to the highest possible item type. */
        sub     highest_valid_type_reg, type_count_reg, 1
        cmp     w0, highest_valid_type_reg
        b.le    loot_item_type_check_low
        mov     w0, highest_valid_type_reg

/* anything lower than 1 becomes 1; get_rand_num_under_n only handles
1 and above, so if n is 0 or less it returns garbage. */
loot_item_type_check_low:
        cmp     w0, 1
        b.ge    loot_item_type_roll
        mov     w0, 1

loot_item_type_roll:
        bl      get_rand_num_under_n
        add     w0, w0, 1

        ldp     fp, lr, [sp], loot_item_type_dealloc
        ret

/* this function gives the player a potion. If the bag has space the potion is automatically added
to their bag, if the bag is full, the function prints the bag contents and allows the player to
choose which potion to replace with the new potion they found, or to simply leave the potion behind.
Input is the potion type found (1 or 2) in w0, usually coming straight from loot_potion, and the
function also reads an int from the player. Output is the slot the potion ended up in (1-4), or 0 
if left behind, in w0. Overwrites x0, x1, x2, x9 to x12, printf and scanf can overwrite x0-x18. */
        .balign 4
        .global offer_potion
offer_potion:
        stp     fp, lr, [sp, offer_potion_alloc]!
        mov     fp, sp
        str     w0, [fp, offer_potion_type_s]

// just adds the potion if bag has space
        bl      bag_add_potion
        cmp     w0, BAG_FULL
        b.ne    offer_potion_done

// if bag is full, print information about the potion the player just found
        ldr     w0, [fp, offer_potion_type_s]
        bl      get_potion_name
        mov     x1, x0
        ldr     w0, [fp, offer_potion_type_s]
        bl      get_potion_heal
        mov     w2, w0
        ldr     x0, =bag_full_fmt
        bl      printf

// show the bag for the player to be able to see if and what to replace
        bl      bag_print
        ldr     x0, =swap_prompt_fmt
        bl      printf

// read slot, if the player didnt type a number the potion is left
        ldr     x0, =slot_input_fmt
        ldr     x1, =typed_slot_m
        bl      scanf
        cmp     w0, 1
        b.ne    offer_potion_leave

// empty slot that the player chose
        ldr     typed_slot_address_reg, =typed_slot_m
        ldr     w0, [typed_slot_address_reg]
        bl      bag_use_potion

// add found potion
        ldr     w0, [fp, offer_potion_type_s]
        bl      bag_add_potion
        cmp     w0, BAG_FULL
        b.ne    offer_potion_done

offer_potion_leave:
        mov     w0, 0

offer_potion_done:
        ldp     fp, lr, [sp], offer_potion_dealloc
        ret
