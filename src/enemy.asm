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

.global generate_enemy
generate_enemy:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov x0, enemy_types //x0 = n
    bl get_rand_num_under_n

    //x0 should be the random number, so no need to set it to anything else
    ldp x29, x30, [sp], 16
    ret