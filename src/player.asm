define(fp, x29)
define(lr, x30)

// Player Stats
.global player_max_health
.global player_current_health
.global player_base_damage
.global player_level
.global player_base_defence

//Player get functions
.global get_player_curr_health
.global get_player_max_health
.global get_player_damage
.global get_player_defence

//Player stat change function
.global player_take_damage
.global player_change_weapon
.global player_change_armour
.global player_level_up

.global is_player_alive

    .data
    .balign 4
player_max_health:      .word 100   // Starting Max health = 100
player_current_health:  .word 100   // Starting Current health = 100
player_base_damage:     .word 12    // Starting base damage = 12
player_level:           .word 1     // Starting player level = 1
player_base_defence:    .word 0     // Starting base defenece = 0
player_weapon:          .word 0     
player_armour:          .word 0

weapon_change_fmt:      .string "Weapon changed to %s\n"
armour_change_fmt:      .string "Armour changed to %s\n"
level_up_fmt:           .string "Player has leveled up! Level is now %d\n"

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
    ldr     x9, =player_current_health      // Current health = max health
    str     w10, [x9]

    //Damage
    ldr     x9, =player_base_damage
    mov     w10, #12
    str     w10, [x9]

    //Defence
    ldr     x9, =player_base_defence
    mov     w10, #0
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
    ldr     w0, [x9]
    ret

get_player_max_health:
    ldr     x9, =player_max_health
    ldr     w0, [x9]
    ret

// Returns base player damage + weapon damage
.extern get_weapon_damage
get_player_damage:
    stp     fp, lr, [sp, -32]!
    mov     fp, sp
    str     w19, [sp, 16]

    //Get base damage
    ldr     x9, =player_base_damage 
    ldr     w19, [x9]

    //Get weapon damage
    ldr     x9, =player_weapon
    ldr     w0, [x9]
    bl      get_weapon_damage

    //Add Damages
    add     w0, w0, w19

    ldr     x19, [sp, 16]
    ldp     fp, lr, [sp], 32
    ret

// returns base player defence + armour defence
.extern get_armour_value
get_player_defence:
    stp     fp, lr, [sp, -32]!
    mov     fp, sp
    str     w19, [sp, 16]

    //Get base defence
    ldr     x9, =player_base_defence
    ldr     w19, [x9]

    //Get armour defence
    ldr     x9, =player_armour
    ldr     w0, [x9]
    bl      get_armour_value

    //Add defences
    add     w0, w0, w19

    ldr     x19, [sp, 16]
    ldp     fp, lr, [sp], 32
    ret

//Checks if player is alive (returns 1 if yes, 0 if no)
is_player_alive:
    ldr     x9, =player_current_health
    ldr     w10, [x9]

    cmp     w10, #0
    cset    w0, gt //return 1 if alive, 0 if dead
   
    ret

// Arguments: w0 (damage being taken)
// Returns players new health
player_take_damage:
    ldr     x9, =player_current_health // Load player current health
    ldr     w10, [x9]

    sub    w10, w10, w0 //W11 = current health (w10) - damage dealth (w0)
    str    w10, [x9] //Load new health and return
    
    ret

player_heal:
    ldr     x9, =player_current_health
    ldr     w10, [x9]
    add     w10, w10, w0

    ldr     x11, =player_max_health
    ldr     w11, [x11]

    cmp     w10, w11
    csel    w10, w10, w11, le

    str     w10, [x9]
    mov     w0, w10

    ret

.extern get_weapon_name
player_change_weapon:
    cmp     w0, 3
    b.hi    invalid_weapon_id

    stp     fp, lr, [sp, -16]!
    mov     fp, sp

    ldr     x9, =player_weapon // Load address of player_weapon into x9
    str     w0, [x9] //save address of new weapon from w0 into x9 (player_weapon)

    bl      get_weapon_name // Retrieve new weapon name

    // Print weapon change
    mov     x1, x0
    ldr     x0, =weapon_change_fmt
    bl      printf

    mov     w0, #0
    ldp     fp, lr, [sp], 16
    ret

invalid_weapon_id:
    mov     w0, -1
    ret

.extern get_armour_name
player_change_armour:
    cmp     w0, 3
    b.hi    invalid_armour_id

    stp     fp, lr, [sp, -16]!
    mov     fp, sp

    ldr     x9, =player_armour
    str     w0, [x9]

    bl      get_armour_name

    mov     x1, x0
    ldr     x0, =armour_change_fmt
    bl      printf

    mov     w0, #0
    ldp     fp, lr, [sp], 16
    ret

invalid_armour_id:
    mov     w0, -1
    ret

player_level_up:
    stp     fp, lr, [sp, -16]!
    mov     fp, sp

    ldr     x9, =player_max_health
    ldr     w10, [x9]
    add     w10, w10, #10
    str     w10, [x9]

    ldr     x9, =player_current_health
    ldr     w10, [x9]
    add     w10, w10, #5
    str     w10, [x9]

    ldr     x9, =player_level
    ldr     w10, [x9]
    add     w10, w10, #1
    str     w10, [x9]

    ldr     x9, =player_base_damage
    ldr     w10, [x9]
    add     w10, w10, #2
    str     w10, [x9]

    ldr     x9, =player_base_defence
    ldr     w10, [x9]
    add     w10, w10, #1
    str     w10, [x9]

    mov     w1, w10
    ldr     x0, =level_up_fmt:
    bl      printf

    ldp     fp, lr, [sp], 16
    ret