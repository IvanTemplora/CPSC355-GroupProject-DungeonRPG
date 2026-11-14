.data
enemy_dmg_fmt: .string "The %s was hit. It's health is now %d.\n"
player_dmg_fmt: .string "The %s's attack lands. Your health is now %d.\n"

enemy_type_s = 16
enemy_health_s = 20
alloc = -(16 + 8) & -16
dealloc = -alloc

.text
.balign 4



.global combat
//main combat loop
combat:
stp x29, x30, [sp, alloc]!
mov x29, sp

str x0, [x29, enemy_type_s] //store enemy type in fp + 16
str x1, [x29, enemy_health_s] //store enemy health in fp + 20, should be max health to start

combat_loop:




mov x0, 0
ldp x29, x30, [sp], dealloc
ret

//takes an enemy's health and determines if combat loop should end. If either the player or enemy is dead, a 1 is returned, else 0 is returned.
is_combat_over:
stp x29, x30, [sp, -32]!
mov x29, sp

//assume enemy's health is in x0
bl is_enemy_alive
str x0, [x29, 16] //store flag for whether enemy is alive in fp + 16
bl is_player_alive

ldr x9, [x29, 16] //load flag for whether enemy is alive
xor x0, x9, x0 //x0 = is_player_alive xor is_enemy_alive
ldp x29, x30, [sp] 32
ret