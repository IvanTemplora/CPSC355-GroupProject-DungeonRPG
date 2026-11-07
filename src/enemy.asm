.data
enemy1: .string "enemy1"
enemy2: .string "enemy2"
enemy3: .string "enemy3"
enemy4: .string "enemy4"
enemy5: .string "enemy5"
enemy6: .string "enemy6"
enemy7: .string "enemy7"
enemy8: .string "enemy8"

.balign 8
enemies: .dword enemy1, enemy2, enemy3, enemy4, enemy5, enemy6, enemy7, enemy8 //contains addresses for all enemy names; used to print enemy names

enemy_types = 8

.text
.balign 4

.global generate_enemy
generate_enemy:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov x0, enemy_types //x0 = n
    bl get_rand_num_under_n

    //x0 should be the random number, so no need to set it to anything else
    ldp x29, x30, [sp], 16
    ret

.global get_enemy_name
//takes an enemy type and returns the address to it's name as a string
get_enemy_name:
    mov x9, x0 //x9 = enemy type
    ldr x10, =enemies //x10 = address of name addresses
    ldr x0, [x10, x9, lsl 3] // x0 = address of string at enemy type
    ret
    


.global attack
//Takes an enemy type, and an armor type/bonus and returns the damage done by the enemy
attack:
stp x29, x30, [sp, -32]!
mov x29, sp

str x0, [x29, 16] //store enemy type at fp + 16
str x1, [x29, 20] //store armor bonus at fp + 20

//sample way for getting damage, not set in stone
mov x0, 5 //base damage max
bl get_rand_num_under_n

ldr w10, [x29, 16]//load enemy type from fp + 16
mov w9, 2
udiv w10, w10, w9  //w10 =enemy type / w9
add w0, w10, 1 // w0 = base damage + (enemy_type) / w9 + 1

ldr w10, [x29, 20] //load armor bonus from fp + 16
sub w0, w0, w10

csel w0, wzr, w0, lt //w0 = (w0 < 0) ? 0 : w0, ensures that negative damage is not dealt
ldp x29, x30, [sp], 32
ret