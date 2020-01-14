lui 0,%r1
addi 42,%r1,%r2
andi 17,%r2,%r3 ; résultat : 0
xori 9,%r2,%r4 ; résultat : 35
ori 9,%r2,%r5 ; résultat : 43
add %r4,%r5,%r6 ; résultat : 78
sub %r5,%r4,%r7 ; résultat : r5 - r4 = 8
jal skipped,%r1

add3:
addi 3,%r10,%r10
jalr 0,%r1,%r1

skipped:
xor %r10,%r10,%r10
jal add3,%r1
lui 0,%r13

