
.text
.balign 4
.global main
main:
stp x29, x30, [sp, -16]!
mov x29, sp

//introduce game

//1.generate enemy(store health and type in stack) and start combat loop

//2.ask player what they'd like to do (attack, run, heal)
//2a. if player chooses to run, go back to step 1.
//2b. if player chooses to heal, go to step 3a.
//2c. if player chooes to attack go to 3b.

//3a. player heals themselves, then go to step 4
//3b. player attacks the enemy, update enemy health, then go to step 3c
//3c. check if enemy is dead (using is_enemy_alive)
//  if enemy is dead, go to step 6.
//  if enemy is not dead go to step 4.

/*
4. enemy attacks the player
5. check if the player is dead
    if player is dead end the game
    if player is not dead go to step 2.

6. Increment enemy killed counter
7. Generate a new item or armour as reward, ask player if they would like to take it, then go to step 2


*/


mov x0, 0
ldp x29, x30, [sp], 16
ret