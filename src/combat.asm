.data
enemy_dmg_fmt: .string "The %s was hit. It's health is now %d.\n"
player_dmg_fmt: .string "The %s's attack lands. Your health is now %d.\n"
player_heal_fmt: .string "You used a potion to heal yourself. Your health is now %d.\n"

enemy_alive: .byte 0 //flag for enemy being alive
player_alive: .byte 0 //flag for enemy being dead
player_flee: .byte 0 //flag for player fleeing


.text

//Takes an enemy's health and updates combat relevant flags
.balign 4
.global update_flags
update_flags:
stp x29, x30, [sp, -16]!
mov x29, sp

bl is_enemy_alive //assume x0 = enemy's health when subroutine is called
ldr x9, =enemy_alive
strb w0, [x9] //set enemy_alive flag

bl player_alive 
ldr x9, =player_alive
strb w0, [x9] //set player_alive flag, x0 = whether player is alive or not

mov x0, 0
ldp x29, x30, [sp], 16
ret

//Takes an enemy type, and determines the amount of damage done to the player (including reductions based on armor bonus). Print's player's new health
//called combat_enemy_attack to avoid naming with collision with subroutine in enemy.asm
.balign 4
.global combat_enemy_attack
combat_enemy_attack:
stp x29, x30, [sp, -48]!
mov x29, sp
str x19, [x29, 16] //store value in x19 on stack
mov x19, x0 //x19 = enemy type

bl get_player_defence
mov x1, x0 //x1 = player armour bonus
mov x0, x19 //x0 = enemy type
bl enemy_attack 

bl player_take_damage
str x20, [x29, 24] //store value in x20 on stack
mov x20, x0 //x20 = damage done by enemy

mov x0, x19
bl get_player_curr_health
str x21, [x29, 32] //store value in x21 on stack
mov w21, w0 //w21 = player's current health

mov x0, x19 //x0 = enemy type
bl get_enemy_name
mov x1, x0 //x1 = enemy's name as string
mov w2, w21 //pass in player's current health
ldr x0, =player_dmg_fmt
bl printf

ldr x19, [x29, 16] //restore x19
ldr x20, [x29, 24] //restore x20
ldr x21, [x29, 32] //restore x21

ldp x29, x30, [sp], 48
ret

//Takes an enemy's type, and current health and returns the enemy's new health after the player has attacked the enemy
.balign 4
.global combat_player_attack
combat_player_attack:
stp x29, x30, [sp, -48]!
mov x29, sp
str x19, [x29, 16] //store value in x19 on stack
mov x19, x0 //x19 = enemy type

str x20, [x29, 24] //store value in x20 on stack
mov x20, x1 //x20 = enemy health

bl get_player_damage
str x21, [x29, 32] //store value in x21 on stack
mov x21, x0 //x21 = damage done by player

mov x0, x19 //pass in enemy type
mov x1, x20 //pass in enemy health
mov x2, x21 //pass in damage done by player
bl take_damage //enemy take_damage
mov x20, x0 //x20 = new enemy health

mov x0, x19 //pass in enemy type
bl get_enemy_name //get address of enemy name as string
mov x1, x0//load enemy name as string
ldr x0, =enemy_dmg_fmt
mov x2, x20 // pass in new enemy health
bl printf

mov x0, x20 //return new enemy health
ldr x19, [x29, 16] //restore x19
ldr x20, [x29, 24] //restore x20
ldr x21, [x29, 32] //restore x21

ldp x29, x30, [sp], 48
ret

//Takes a bag slot number (1-4) and heals the player then prints the player's new health
.balign 4
.global combat_player_heal
combat_player_heal:
stp x29, x30, [sp, -32]!
mov x29, sp


bl bag_use_potion //assume slot number is in x0
bl player_heal //currently does not exist

bl get_player_curr_health
mov w1, w0 //w1 = player current health
ldr x0, =player_heal_fmt
bl printf

ldp x29, x30, [sp], 32
ret

//Checks status flags and determines if combat is over. Returns 1 if either enemy is dead or player is dead, 0 otherwise
.balign 4
.global is_combat_over
is_combat_over:
ldr x9, =enemy_alive
ldrb w10, [x9] //w10 = is enemy alive

ldr x9, =player_alive
ldrb w11, [x9] //w11 = is player alive

and w9, w10, w11 //x9 = player_alive & enemy_alive
mvn w0, w9 //w0 = ~(player_alive & enemy_alive)

ret