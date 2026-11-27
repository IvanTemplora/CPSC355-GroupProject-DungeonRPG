define(x29, fp)
define(x30, lr)

                .data
intro_fmt:      .string "Welcome to Dungeon RPG!\nEnter 1 to start!"
enemy_encounter_fmt: .string "Enemy encountered!\nHealth: %ld\n"
choices_fmt:    .string "1) Attack\n
                        2) Heal\n
                        3) Run\n"
fmt_in:         .string "%ld"
invalid_fmt:    .string "Invalid Choice\n"
run_fmt:        .string "Player decided to run\n"
enemy_dead_fmt: .string "Enemy has died\n"
player_dead_fmt:    .string "Player has died. Game over!\n"
player_win_fmt: .string "You have won the game!\n"

        .text
        .balign 4
        .global main
/* Introduce game
    - Initialize player
    - Initialize kill counter
    
    - Callee-Saved Register
        - x19 = Current enemy
        - x20 = Current Enemy Health
        - x21 = Kill Counter
 */
main:
        stp     x29, x30, [sp, -64]!
        mov     x29, sp

        str     x19, [fp, 16] // Current Enemy
        str     x20, [fp, 24] // Current Enemy Health
        str     x21, [fp, 32] // Kill Counter


        //Initialize Player
        bl      player_init
        mov     x21, #0

        //print intro
        ldr     x0, =intro_fmt
        bl      printf

        ldr     x0, =fmt_in
        bl      scanf
        
        //Check if player starts
        // if 1 (valid input) branch to create_enemy, else print invalid and branch back
        cmp     w0, 1
        b.eq    create_enemy
        bl      invalid

        b       main

/* Initialize enemy
 */
create_enemy:

    // Generate enemy
    bl      generate_enemy
    mov     x19, x0         //Set x19 to the enemy generated (x0)

    //Get Enemy health
    mov     x0, x19
    bl      get_max_health
    mov     x20, x0         // Set x20 to enemy health

    ldr     x0, =enemy_encounter_fmt
    bl      printf

    b       game_loop

/* subroutine for invalid input
 */
invalid:
    ldr     x0, =invalid_fmt
    bl      printf
    ret

/* Game start loop
    - generate enemy
    - ask for choice
        - Attack -> branch to combat_loop
        - Run -> branch to run
        - Heal -> branch to heal
 */
game_loop:

    //Give options
    ldr     x0, =choices_fmt
    bl      printf

    ldr     x0, =fmt_in
    bl      scanf

    /* Choice comparision
        1 = attack -> branch to combat_loop
        2 = heal -> branch to heal
        3 = run -> branch to heal
     */
    cmp     w0, 1
    bl      combat_loop
    cmp     w0, 2
    bl      heal
    cmp     w0, 3
    bl      run

    b       game_loop //Branch back to main if choice invalid

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
    //set x0 = enemy health, check if alive
    mov     x0, x20
    bl      is_enemy_alive
    cmp     w0, 0
    b.le    enemy_dead //If enemy health <= 0, go to enemy_dead

    bl      combat_player_attack

/* Run option
    - branch to game_loop: generate new enemy?
 */
run:
    // Print run dialogue -> branch to create enemy (restart)
    ldr     x0, =run_fmt
    bl      printf

    b       create_enemy


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
    add     x21, x21, #1

    ldr     x0, =enemy_dead_fmt
    bl      printf

    b       create_enemy

/* Game Over
    - Player has died
 */
game_over:
    ldr     x0, =player_dead_fmt
    bl      printf

    b       game_done

/* Game won
    - Player has won
 */
game_won:
    ldr     x0, =player_won_fmt
    bl      printf

    b       game_done

/* Game Done
 */
game_done:
        mov     x0, 0

        ldr     x19, [fp, 16]
        ldr     x20, [fp, 24]
        ldr     x21, [fp, 32]

        ldp     x29, x30, [sp], 64
        ret