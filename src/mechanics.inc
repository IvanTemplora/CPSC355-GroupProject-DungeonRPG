// mechanics.inc
/*
    the reason why this file exists is because it would be a giant pain
    to include practically everything below in every single file that needs it
    so this lets us call

    .include "mechanics.inc"
    
    at the top and have everything
    below be effectively accessible whenever required

    it just holds shared constants for mechanic removal that will be used
    every file that will interact with this mechanic in some manner
    should have .include "mechanics.inc" in it at the top before other useful things
*/

/*
    files that likely will use this:
    - inventory.asm
    - combat.asm
    - player.asm (if armor shenanigans)
*/

/*
    each mechanic that is added needs its constant here,
    then a message + reminder to add it in mechanics.asm
    

    message order needs to match bit order or there will be a 
    flag mismatch (i.e the flag gets triggered but wrong message shows up)
*/ 

// actual useful things start here
// these are just placeholders that i think will be implemented

        .equ MECH_ITEMS,    (1 << 0)    // inventory: using items
        .equ MECH_ARMOR,    (1 << 1)    // inventory/player: armor
        .equ MECH_WEAPONS,  (1 << 2)    // inventory: swapping weapons
        .equ MECH_FLEE,     (1 << 3)    // combat: running away
        .equ MECH_BLOCK,    (1 << 4)    // combat: blocking

        .equ MECH_COUNT,    5
        .equ ALL_MECHS,     0b11111     // all five bits set