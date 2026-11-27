
define(x29, fp)
define(x30, lr)

                .bss
                .balign 4
kill_count:     .skip 4

        .text
        .balign 4
        .global main
/* Introduce game
    - Initialize player
    - Initialize kill counter
 */
main:
        stp     x29, x30, [sp, -16]!
        mov     x29, sp

        //Initialize Player
        bl      player_init

        mov     x0, 0
        ldp     x29, x30, [sp], 16
        ret

/* Game start loop
    - generate enemy
    - ask for choice
        - Attack -> branch to combat_loop
        - Run -> branch to run
        - Heal -> branch to heal
 */
game_loop:

/* Combat loop (if attack is chosen)
    - Check if enemy dead
        - If dead -> branch to enemy_dead
            - level up?
    - Attack if enemy not dead -> continue in combat_loop
        - Calculate damage and change player stats
        - Check player alive or not
            - if alive -> branch to game_loop
            - if dead -> branch to game_over
 */
combat_loop:

/* Run option
    - branch to game_loop: generate new enemy?
 */
run:

/* Heal option
    - Heal player
        - change stats
 */
heal:

/* Player has killed enemy
    - Increment kill counter
    - Generate item as reward
        - ask to take or leave
    - branch back to game_loop
 */
enemy_dead: