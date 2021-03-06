.thumb
@this hack takes r0 = character data in ram and returns a pointer to a 0-terminated list of skills (using the text buffer)
@supports 1 personal, 1 class, 4 learned
.set SkillsBuffer, 0x202b6d0 @0x202b156 @0x202a6ac
.set ClassSkillTable, PersonalSkillGetter+4
.set LevelUpSkillTable, ClassSkillTable+4
.set SkillsOffChecker, LevelUpSkillTable+4
.set VanillaClassSkillTable, SkillsOffChecker+4
.set SkillGetterHelper, VanillaClassSkillTable+4
.set BWLTable, 0x203e884

push {r4-r7,lr}
mov r4, r0 @save it
ldr r5, =SkillsBuffer


@personal skill first, if any (even if skills are off)
ldr r0, [r4]
ldrb r6, [r0, #4] @char number saved in r6 for later
mov r0, r6 @r0 = u8 charnumber
ldr r1, PersonalSkillGetter
mov lr, r1
.short 0xf800
cmp r0, #0
beq NoPersonal
  strb r0, [r5]
  add r5, #1
NoPersonal:

@now check if skills are off
mov r0, r4
ldr r1, SkillsOffChecker
mov lr, r1
.short 0xf800
cmp r0, #0
beq VanillaSkills

@class skill, if any
ldr r0, [r4,#4]
ldrb r0, [r0,#4] @class number
ldr r1, ClassSkillTable
ldrb r2, [r1, r0] @skll byte
cmp r2, #0
beq NoClass
  strb r2, [r5]
  add r5, #1
NoClass:

@learned skills, up to 4
cmp r6, #0x46
bhi GenericUnit
ldr r0, =BWLTable
lsl r1, r6, #4 @r1 = char*0x10
@ lsl r2, r1, #2 @r2 = char*8
@ add r1, r2     @r1 = char*10
add r0, r1
add r0, #1 @start at byte 1, not 0
mov r2, #0
LoopStart:
ldrb r1, [r0,r2]
cmp r1, #0
beq NextLoop
strb r1, [r5]
add r5, #1
NextLoop:
cmp r2, #3
bge TerminateList
add r2, #1
b LoopStart

GenericUnit: @grab the skills based on level i suppose
mov r0, r4
ldrb r7, [r0, #8] @level
ldr r1, [r0, #4] @class
ldrb r1, [r1, #4] @class number
ldr r2, LevelUpSkillTable
lsl r1, #2
add r1, r2
ldr r6, [r1] @pointer to list of skills
cmp r6, #0
beq TerminateList
CheckLoop:
  ldrb r0, [r6]
  cmp r0, #0
  beq TerminateList
  cmp r0, r7
  ble FoundSkill @if the skill is lower/equal level
  cmp r0, #0xFF
  beq FoundSkill @if the skill is level 255
  add r6, #2
  b CheckLoop
  FoundSkill:
    @r4 contains the unit pointer
  ldrb r1, [r6, #1] @r1 is the list
    ldr r0, SkillGetterHelper
    mov lr, r0
    mov r0, r4
    .short 0xf800
    mov r1, r0 @this randomizes it if the option was on

  strb r1, [r5]
  add r5, #1
  add r6, #2
  b CheckLoop

TerminateList:
mov r0, #0
strb r0, [r5]
mov r1, r5 @end of skill buffer
ldr r0, =SkillsBuffer
sub r1, r0 @number of skills

pop {r4-r7}
pop {r2}
bx r2

VanillaSkills:
@vanilla skills table
ldr r0, [r4,#4]
ldrb r0, [r0,#4] @class number
lsl r0, #1 @ table is 2 bytes per row
ldr r1, VanillaClassSkillTable
ldrb r2, [r1, r0] @2 skills per
strb r2, [r5]
add r5, #1
add r0, #1
ldrb r2, [r1, r0]
strb r2, [r5]
add r5, #1
b TerminateList

.ltorg
PersonalSkillGetter:
@POIN PersonalSkillTable
@POIN ClassSkillTable
@POIN VanillaClassSkillTable
