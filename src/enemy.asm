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
    