lui 0,%r1
addi 42,%r1,%r2 ; r2 = 42
andi 17,%r2,%r3 ; r3 =  0
xori 9,%r2,%r4  ; r4 = 35
ori 9,%r2,%r5   ; r5 = 43
add %r4,%r5,%r6 ; r6 = 78
sub %r5,%r4,%r7 ; r7 = r5 - r4 = 8
jal lbl,%r1

skipped:
xor %r11,%r11,%r11
lw 0,%r11,%r16 ; r16 = 42
jalr 0,%r1,%r1

lbl:
xor %r10,%r10,%r10
xor %r1,%r1,%r1
addi 42,%r10,%r10 ; r10 = 42
sw %r10,0,%r1
jal skipped,%r1
lui 0,%r13

bne %r2,%r3,sub19

add3:
addi 3,%r16,%r17 ; r17 = 45
jal end,%r1
add5:
addi 5,%r16,%r17 ; r17 = 47
jal end,%r1
sub19:
addi -19,%r16,%r17 ; r17 = 23

end:
lui 0,%r13
