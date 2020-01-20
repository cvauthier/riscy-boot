Processeur RISCy-boot:
----------------------
(git.eleves.ens.fr/cvauthier/riscy-boot)

Instructions pour la compilation :
---------------------------------

La version d'OCaml utilisée est la 4.05.0
Les packages suivants sont nécessaires :
- libsdl1.2-dev
- libsdl-image1.2-dev
- libsdl-mixer1.2-dev

Un binaire minijazz "mjc.byte" doit être placé dans le dossier netlists/ 
(c'est déjà fait mais le binaire est compilé pour OCaml 4.05.0)

Le script compile_all dans le répertoire principal réalise les actions suivantes :
- compilation de l'assembleur RISC
- compilation du transpileur netlist/C
- compilation des netlists du processeur en C
- compilation du programme C gérant la pendule
- exécution de la pendule

Contenu du projet :
------------------

- Assembleur : un programme qui assemble des fichiers .s contenant les
	instructions RISC ci-dessus avec une syntaxe ad hoc (en particulier il
	implémente un système de labels). Il est relativement
	simple (les messages d'erreur sont peu détaillés).

- Transpileur : un transpileur netlist/C. Une partie du code est reprise du
	squelette de simulateur fourni en TD. Prend un fichier .net en entrée et créé
	deux fichiers .c et .h à interfacer avec un programme C. Le fichier .h définit
	une structure State qui contient les données des registres/mémoires du
	processeur, et le fichier .c implémente une fonction compute_cycle qui prend
	en entrée un State* et les entrées du processeur et calcule un cycle, mettant
	à jour le State* et renvoyant les sorties de la netlist.
	Aucun effort d'optimisation n'est fait, cette tâche étant déléguée au
	compilateur GCC.
	(Remarque : le transpileur représente les données dans le "mauvais ordre", de
	sorte que le i-ème bit de poids fort d'un bus (de taille <= 8) correspond au
	i-ème bit de poids faible de l'octet dans lequel il est stocké. Interagir avec
	la mémoire du processeur dans le code C nécessite donc de faire un certain
	nombre de "bit reversal".)

- Netlists : netlists du processeur. Leur compilation utilise le préprocesseur C
	et le compilateur minijazz. Le fichier principale est "control.mj".

- Processeur : programme C principal gérant la pendule. L'interface graphique
	est codée avec la SDL (avec SDL_image et SDL_mixer).
	Par défaut, la pendule est en mode normal, et elle est initialisée à la date
	et l'heure du début de l'exécution.
	La touche Espace permet d'activer/désactiver le mode rapide.
	Les ressources utilisées ont été réalisées avec les logiciels GIMP et LMMS.

Description du processeur :
----------------------------

Architecture : RISC-V
Jeu d'instructions : sous-ensemble du "RV32I Base Instruction Set" :
- Chargement : LUI
- Sauts : JAL, JALR
- Branchements : BEQ, BNE, BLT, BGE
- Arithmétique : ADDI,XORI,ORI,ANDI,ADD,SUB,OR,AND,XOR
- Mémoire : LW,SW
-Autres : NOP

La mémoire (65536 octets) est composée de blocs de 4 octets. 
Afin d'éviter les complications causées par les accès mémoire non alignés, à
chaque accès mémoire, on ignore les deux bits de poids faible de l'adresse. On a
donc en pratique une RAM avec des adresses de 14 bits et des mots de 32 bits.

Les registres sont implémentés avec une RAM, pour une raison purement
pragmatique : l'accès aux registres se transpile ainsi en quelques lignes de C
au lieu de plusieurs dizaines de milliers pour une version utilisant
exclusivement des registres minijazz (une telle version est en commentaire dans
le fichier regs.mj).

