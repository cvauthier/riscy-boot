Architecture du processeur :
----------------------------

Architecture : RISC-V
Jeu d'instructions : sous-ensemble du "RV32I Base Instruction Set"

Instructions prévues (d'autres pourront éventuellement être ajoutées) :
----------------------
Chargement :
- LUI
Sauts :
- JAL
- JALR
Branchements :
- BEQ
- BNE
- BLT
- BGE
Arithmétique :
- ADDI
- ADD
- SUB
- XORI
- XOR
- ORI
- OR
- ANDI
- AND
Mémoire :
- LW
- SW
Autres :
- NOP

Mémoire :
---------
La mémoire est composée de blocs de 4 octets chacun. 
Il est prévu que tout accès mémoire se fasse en ignorant les deux bits de poids faible de l'adresse.
Les 32 registres RV32I, ainsi que pc, seront tous implémentés.


