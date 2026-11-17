.data
enemy_dmg_fmt: .string "The %s was hit. It's health is now %d.\n"
player_dmg_fmt: .string "The %s's attack lands. Your health is now %d.\n"

enemy_alive: .byte 0
player_alive: .byte 0
player_flee: .byte 0

enemy_type_s = 16
enemy_health_s = 20
alloc = -(16 + 8) & -16
dealloc = -alloc

.text

//Takes an enemy's health and updates combat relevant flags
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

.balign 4
.global combat
//main combat loop, assume enemy type was passed in with x0, and enemy health with x1
combat:
stp x29, x30, [sp, alloc]!
mov x29, sp

str x0, [x29, enemy_type_s] //store enemy type in fp + 16
str x1, [x29, enemy_health_s] //store enemy health in fp + 20, should be max health to start

combat_loop:
ldr x0, [x29, enemy_health_s] //load enemy health
bl is_combat_over
cmp x0, 1 //flag == 1
b.eq combat_done



combat_done:
mov x0, 0
ldp x29, x30, [sp], dealloc
ret

//Checks status flags and determines if combat is over. Returns 1 if either enemy is dead or player is dead, 0 otherwise
is_combat_over:
ldr x9, =enemy_alive
ldrb w10, [x9] //w10 = is enemy alive

ldr x9, =player_alive
ldrb w11, [x9] //w11 = is player alive

and w9, w10, w11 //x9 = player_alive & enemy_alive
mvn w0, w9 //w0 = ~(player_alive & enemy_alive)

ret