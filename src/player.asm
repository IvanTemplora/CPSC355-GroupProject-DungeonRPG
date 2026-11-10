define(fp, x29)
define(lr, x30)

// Player Stats
.global player_max_health
.global player_current_health
.global player_damage
.global player_level
.global player_defence

//Player get functions
.global get_player_curr_health
.global get_player_max_health
.global get_player_damage
.global get_player_defence

//need to finish
//Player stat change function
.global player_take_damage
.global player_deal_damage
.global player_change_weapon
.global player_change_armour
.global player_level_up

.global is_player_alive

    .data
    .balign 4
player_max_health:      .word 100
player_current_health:  .word 100
player_base_damage:     .word 15
player_level:           .word 1
player_base_defence:    .word 5
player_weapon:          .word 0
player_armour:          .word 0

    .text
    .balign 4

//Initialize player stats
.global player_init
player_init:
    /*For all Initialization
        - Load x9 with address of player stat variable
        - Set w10 with the number representing the stat
        - Store w10 (player stat number) into address of x9 (address of player stat variable)
     */
    
    // Max Health
    ldr     x9, =player_max_health
    mov     w10, #100
    str     w10, [x9]

    //Current health
    // When initializing, set current health to max health
    ldr     x9, =player_current_health
    mov     w10, [player_max_health]
    str     w10, [x9]

    //Damage
    ldr     x9, =player_base_damage
    mov     w10, #15
    str     w10, [x9]

    //Defence
    ldr     x9, =player_base_defence
    mov     w10, #10
    str     w10, [x9]

    //Level
    ldr     x9, =player_level
    mov     w10, #1
    str     w10, [x9]

    //Weapon (Starting weapon: fists)
    ldr     x9, =player_weapon
    mov     w10, #0
    str     w10, [x9]

    //Armour (Starting armour: none)
    ldr     x9, =player_armour
    mov     w10, #0
    str     w10, [x9]

    ret

/*
    For all get functions
        - Load x9 with address of player stat needed
        - Load x0 with x9 (player stat address)
        - Return player stat
 */

get_player_curr_health:
    ldr     x9, =player_current_health
    ldr     w0, x9
    ret

get_player_max_health:
    ldr     x9, =player_max_health
    ldr     w0, x9
    ret

.extern get_weapon_damage
get_player_damage:
    stp     fp, lr, [sp, -16]!
    mov     fp, sp

    //Get base damage
    ldr     x9, =player_base_damage 
    ldr     w10, x9

    //Get weapon damage
    ldr     x9, =player_weapon
    ldr     w0, x9

    bl      get_weapon_damage

    //Add Damages
    add     w0, w0, w10

    ldp     fp, lr, [sp], 16
    ret

.extern get_armour_value
get_player_defence:
    stp     fp, lr, [sp, -16]!
    mov     fp, sp

    //Get base defence
    ldr     x9, =player_base_defence
    ldr     w10, x9

    //Get armour defence
    ldr     x9, =player_armour
    ldr     w0, x9

    bl      get_armour_value

    //Add defences
    add     w0, w0, w10

    ldp     fp, lr, [sp], 16
    ret

//Checks if player is alive (returns 1 if yes, 0 if no)
is_player_alive:
    ldr     x9, =player_current_health
    ldr     w10, [x9]

    cmp     w10, #0
    b.gt    alive //Goes to alive branch if health is above 0 and will return 1 (alive)

    mov     w0, #0 //Else returns 0

    ret

alive:
    mov     w0, #1
    ret