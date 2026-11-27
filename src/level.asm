// Group 41 dungeon levels - Parsa G.

.equ LEVEL_NO_FLEE,      1
.equ LEVEL_NO_INVENTORY, 2

// Rooms cleared by the end of each stage.
.equ STAGE_1_END, 2
.equ STAGE_2_END, 4
.equ DUNGEON_END, 5

.text
.balign 4

.global level_get_room
.type level_get_room, %function
// In: x0 = rooms cleared.
// Out: x0 = stage, x1 = room, w2 = blocked actions.
// Stage 0 means victory. Stage -1 means an invalid count.
level_get_room:
    cmp x0, #STAGE_1_END
    b.lo .Lstage_one
    cmp x0, #STAGE_2_END
    b.lo .Lstage_two
    cmp x0, #DUNGEON_END
    b.lo .Lstage_three

    // Five cleared rooms wins the game.
    mov x1, #0
    mov w2, #0
    b.eq .Lvictory
    mov x0, #-1
    ret

.Lvictory:
    mov x0, #0
    ret

.Lstage_one:
    add x1, x0, #1
    mov x0, #1
    mov w2, #0
    ret

.Lstage_two:
    sub x1, x0, #(STAGE_1_END - 1)
    mov x0, #2
    mov w2, #LEVEL_NO_FLEE
    ret

.Lstage_three:
    sub x1, x0, #(STAGE_2_END - 1)
    mov x0, #3
    mov w2, #(LEVEL_NO_FLEE | LEVEL_NO_INVENTORY)
    ret
.size level_get_room, . - level_get_room

.global level_spawn_enemy
.type level_spawn_enemy, %function
// Call after seed_rand. Returns enemy type in x0 and HP in x1.
level_spawn_enemy:
    stp x29, x30, [sp, #-32]!
    mov x29, sp

    bl generate_enemy
    str x0, [sp, #16]       // Save the enemy type.
    bl get_max_health
    mov x1, x0
    ldr x0, [sp, #16]

    ldp x29, x30, [sp], #32
    ret
.size level_spawn_enemy, . - level_spawn_enemy

.section .note.GNU-stack,"",%progbits

