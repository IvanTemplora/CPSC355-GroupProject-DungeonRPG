.text
.balign 4

.global seed_rand
seed_rand:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov x0, 0 //x0 = NULL
    bl time
    bl srand //seed RNG

    mov x0, 0 //doesn't return anything, just seeds rand (ideally)
    ldp x29, x30, [sp], 16
    ret

.global get_rand_num_under_n
//takes a positive integer n and returns a random number that is less than an integer value n but greater than 0
get_rand_num_under_n:
    stp x29, x30, [sp, -32]!
    mov x29, sp

    str x0, [x29, 16] //store x0 at fp + 16
    bl rand

    ldr x9, [x29, 16] //loads n into x9
    //must use x register here as random numbers tend to be large
    udiv x10, x0, x9 //x10 = random number / n, quotient    
    msub w11, w10, w9, w0 // w11 = random number - quotient*n, remainder

    mov w0, w11 //w0 = remainder
    ldp x29, x30, [sp], 32
    ret