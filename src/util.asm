.text
.balign 4
.global seed_rand

seed_rand:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov x0, 0 //x0 = NULL
    bl time
    bl srand //seed RNG

    mov x0, 0 
    ldp x29, x30, [sp], 16
    ret

