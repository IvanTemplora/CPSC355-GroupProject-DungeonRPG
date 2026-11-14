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



mov x0, 0
ldp x29, x30, [sp], dealloc
ret