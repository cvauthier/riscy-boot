; Organisation mémoire :
; 0 : signal de l'horloge, passe à 1 chaque seconde
; 1 à 14 : chiffres dans l'ordre AAAA/MM/JJ:hh:mm:ss (données d'affichage)
; 15 à 18 : chiffres des années 
; 19 : mois
; 20 : jours
; 21 : heures
; 22 à 25 : chiffres mm:ss
; 40 à 49 : table valeur/affichage
; 50 à 61 : table jours/mois
; un chiffre - 7 bits, 1 par barre
; +--0--+
; |			|
; 1			2
; |			|
; +--3--+
; |			|
; 4			5
; |			|
; +--6--+

addi 10,%r0,%r31 ; constante 10
addi 6,%r0,%r30  ; constante 6
addi 24,%r0,%r29 ; constante 24
addi 12,%r0,%r28 ; constante 12

jal load_data,%r1

; Affichage initial
; Années
addi 60,%r0,%r10
addi 4,%r0,%r3
addi 76,%r0,%r5
while1:
lw 0,%r10,%r2
jal export_digit,%r1
addi 4,%r3,%r3
addi 4,%r10,%r10
blt %r10,%r5,while1

; Mois/jours/heures
addi 88,%r0,%r8
while2:
lw 0,%r10,%r2
jal export_small_nb,%r1
addi 4,%r3,%r3 ; export_small_nb ajoute 4 à r4
addi 4,%r10,%r10
blt %r10,%r8,while2

; Minutes/secondes
addi 88,%r0,%r10
addi 44,%r0,%r3
addi 104,%r0,%r5
while3:
lw 0,%r10,%r2
jal export_digit,%r1
addi 4,%r3,%r3
addi 4,%r10,%r10
blt %r10,%r5,while3

main_loop:
lw 0,%r0,%r1
beq %r0,%r1,main_loop
sw %r0,0,%r0

; Unités des secondes
addi 100,%r0,%r10 ; r10 - adresse de la valeur
addi 56,%r0,%r3   ; r3  - adresse de l'afficheur
lw 0,%r10,%r2     ; r2 - chiffre des unités
addi 1,%r2,%r2
blt %r2,%r31,end  ; r2 < 10
lui 0,%r2
sw %r2,0,%r10
jal export_digit,%r1

; Dizaines des secondes
addi 96,%r0,%r10
addi 52,%r0,%r3
lw 0,%r10,%r2
addi 1,%r2,%r2
blt %r2,%r30,end  ; r2 < 6
lui 0,%r2
sw %r2,0,%r10
jal export_digit,%r1

; Unités des minutes
addi 92,%r0,%r10
addi 48,%r0,%r3
lw 0,%r10,%r2
addi 1,%r2,%r2
blt %r2,%r31,end  ; r2 < 10
lui 0,%r2
sw %r2,0,%r10
jal export_digit,%r1

; Dizaines des minutes
addi 88,%r0,%r10
addi 44,%r0,%r3
lw 0,%r10,%r2
addi 1,%r2,%r2
blt %r2,%r30,end  ; r2 < 6
lui 0,%r2
sw %r2,0,%r10
jal export_digit,%r1

; Heures 
addi 84,%r0,%r10
addi 36,%r0,%r3
lw 0,%r10,%r2
addi 1,%r2,%r2
blt %r2,%r29,end2 ; r2 < 24
lui 0,%r2
sw %r2,0,%r10
jal export_small_nb,%r1

; Jours
addi 80,%r0,%r10
addi 28,%r0,%r3
lw 0,%r10,%r2
lw -4,%r10,%r13 ; r13 - mois
add %r13,%r13,%r13
add %r13,%r13,%r13 ; r13 *= 4
lw 196,%r13,%r13 ; r13 - nb de jours du mois
addi 1,%r2,%r2
bge %r13,%r2,end2
addi 1,%r0,%r2
sw %r2,0,%r10
jal export_small_nb,%r1

; Mois
addi 76,%r0,%r10
addi 20,%r0,%r3
lw 0,%r10,%r2
addi 1,%r2,%r2
bge %r28,%r2,end2 ; r2 <= 12
addi 1,%r0,%r2
sw %r2,0,%r10
jal export_small_nb,%r1

; Unités des années
addi 72,%r0,%r10 
addi 16,%r0,%r3   
lw 0,%r10,%r2     
addi 1,%r2,%r2
blt %r2,%r31,end  ; r2 < 10
lui 0,%r2
sw %r2,0,%r10
jal export_digit,%r1

; Dizaines des années
addi 68,%r0,%r10 
addi 12,%r0,%r3   
lw 0,%r10,%r2     
addi 1,%r2,%r2
blt %r2,%r31,end  ; r2 < 10
lui 0,%r2
sw %r2,0,%r10
jal export_digit,%r1

; Centaines des années
addi 64,%r0,%r10 
addi 8,%r0,%r3   
lw 0,%r10,%r2     
addi 1,%r2,%r2
blt %r2,%r31,end  ; r2 < 10
lui 0,%r2
sw %r2,0,%r10
jal export_digit,%r1

; Milliers des années
addi 60,%r0,%r10 
addi 4,%r0,%r3   
lw 0,%r10,%r2     
addi 1,%r2,%r2
blt %r2,%r31,end  ; r2 < 10
lui 0,%r2

end:
jal export_digit,%r1
sw %r2,0,%r10
jal main_loop,%r1

end2:
jal export_small_nb,%r1
sw %r2,0,%r10
jal main_loop,%r1

export_small_nb: ; affiche le nombre r2 (entre 0 et 99) aux adresses r3,r3+4
lui 0,%r4
addi 0,%r1,%r6
addi 0,%r2,%r7
blt %r2,%r31,end_while
while:
addi 1,%r4,%r4
addi -10,%r2,%r2
bge %r2,%r31,while
end_while:
addi 0,%r2,%r5
addi 0,%r4,%r2
jal export_digit,%r1
addi 4,%r3,%r3
addi 0,%r5,%r2
jal export_digit,%r1
addi 0,%r6,%r1
addi 0,%r7,%r2
jalr 0,%r1,%r1

export_digit: ; affiche le chiffre r2 à l'adresse r3
add %r2,%r2,%r4
add %r4,%r4,%r4 ; 4 * r2
lw 160,%r4,%r4
sw %r4,0,%r3
jalr 0,%r1,%r1

load_data:
addi 0x77,%r0,%r2 ; affichage pour 0 (barres 0,1,2,4,5,6)
sw %r2,160,%r0 ; 29 * 4 = 116
addi 0x24,%r0,%r2 ; affichage pour 1 (barres 2,5)
sw %r2,164,%r0
addi 0x5D,%r0,%r2 ; affichage pour 2 (barres 0,2,3,4,6)
sw %r2,168,%r0
addi 0x6D,%r0,%r2 ; affichage pour 3 (barres 9,2,3,5,6)
sw %r2,172,%r0
addi 0x2E,%r0,%r2 ; affichage pour 4 (barres 1,2,3,5)
sw %r2,176,%r0
addi 0x6B,%r0,%r2 ; affichage pour 5 (barres 0,1,3,5,6)
sw %r2,180,%r0
addi 0x7B,%r0,%r2 ; affichage pour 6 (barres 0,1,3,4,5,6)
sw %r2,184,%r0
addi 0x25,%r0,%r2 ; affichage pour 7 (barres 0,2,5)
sw %r2,188,%r0
addi 0x7F,%r0,%r2 ; affichage pour 8 (barres 0,1,2,3,4,5,6)
sw %r2,192,%r0
addi 0x6F,%r0,%r2 ; affichage pour 9 (barres 0,1,2,3,5,6)
sw %r2,196,%r0
addi 31,%r0,%r2
sw %r2,200,%r0 ; janvier
sw %r2,208,%r0 ; mars
sw %r2,212,%r0 ; mai
sw %r2,220,%r0 ; juillet
sw %r2,224,%r0 ; août
sw %r2,232,%r0 ; octobre
sw %r2,240,%r0 ; décembre
addi 30,%r0,%r2
sw %r2,212,%r0 ; avril
sw %r2,220,%r0 ; juin
sw %r2,228,%r0 ; septembre
sw %r2,236,%r0 ; novembre
addi 28,%r0,%r2
sw %r2,204,%r0 ; février
jalr 0,%r1,%r1

