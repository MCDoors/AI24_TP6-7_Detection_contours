; Nicolas HUET
; Guillaume NIBERT

; image.asm
;
; AI24 - TP Assembleur 2 à 5
;
; Réalise le traitement d'une image bitmap 32 bits par pixel.

title image.asm

.code

; **********************************************************************
; Sous-programme _process_image_asm 
; 
; Réalise le traitement d'une image 32 bits.
; 
; Le passage des paramètres respecte les conventions fastcall x64 sous 
; Windows. La fonction prend les paramètres suivants, dans l'ordre :
;  - biWidth : largeur d'une ligne en pixels (32 bits non signé)
;  - biHeight de l'image en lignes (32 bits non signé)
;  - img_src : adresse du premier pixel de l'image source
;  - img_temp1 : adresse du premier pixel de l'image temporaire 1
;  - img_temp2 : adresse du premier pixel de l'image temporaire 2
;  - img_dest : adresse du premier pixel de l'image finale

public  process_image_asm
process_image_asm 	proc		; Point d'entrée de la fonction

		mov r11, [rsp + 40]		; Sauvegarde l'adresse du premier pixel de img_temp2.

		;***************************************
		;				  TP5				   *
		;***************************************

		push	rbx		; Les registres rbx, rbp, rdi, rsi, rsp, r12, r13, r14, r15 doivent être sauvegardés par l'appelé, le reste est sauvegardé par l'appelant
		push	rbp
		push	rdi
		push	rsi
		push	r12
		push	r13
		push	r14
		push	r15

		; Le passage de paramètre suis la convension fastcall x64
		; Les 4 premiers arguments sont passés dans rcx, rdx, r8 et r9 et le reste est mis sur la pile
		; biWidth	-> rcx
		; biHeight	-> rdx
		; img_src	-> r8
		; img_temp1	-> r9
				
		; img_temp2	-> [rsp + 40]
		; img_dest	-> [rsp + 48]
		
		mov r12, rcx	; On sauvegarde le premier paramètre dans le registre r12 car rdx est modifié après.
		mov r15, rdx	; biHeight nombre de lignes
		
		imul rcx, rdx	; Calcul du nombre de pixel dans l'image et sauvegarde dans le registre rcx
		dec rcx			; Nombre de pixel - 1 (Parade pour le problème r8) ; Devient donc l'adresse de la fin de l'image.

		
; Boucle en partant du dernier pixel jusqu'au premier pixel.
color:
		
		movzx rax, byte ptr [r8 + rcx*4]		; BLEU
		imul rax, 1Dh							; Réalise la multiplication suivante : 1Dh * "Bleu"
		mov r13, rax							; r13 stocke le résultat du niveau de gris
		
		movzx rax, byte ptr [r8 + rcx*4 + 1]	; VERT (même démarche)
		imul rax, 96h
		add r13, rax
		
		movzx rax, byte ptr [r8 + rcx*4 + 2]	; ROUGE (même démarche)
		imul rax, 4Ch
		add r13, rax
		
		; Après ces instructions : r13 = 4C * Rouge + 96 * Vert + 1D * Bleu
		
		shr r13, 8								; On déplace le r13 de 8 bits vers la droite (on supprime donc la moitié), pour la virgule
		
		mov byte ptr [r9 + rcx*4], r13b			; On stocke dans Bleu et la technique du niveau gris, pour les autres composantes on met 0 comme indiqué dans le TP
		mov byte ptr [r9 + rcx*4 + 1], 0
		mov byte ptr [r9 + rcx*4 + 2], 0
		mov byte ptr [r9 + rcx*4 + 3], 0
		
		dec rcx	; Décrémentation de l'index du pixel pour passer au traitement du pixel suivant (le précédent puisqu'on parcourt l'image de la fin vers le début)
		cmp rcx, 0	; Tant que rcx n'est pas égal à 0...
		jne color	; ...On continue à réaliser la technique du niveau du gris sur les pixels restants à traiter.

		;***************************************
		;				TP6/7				   *
		;***************************************

		mov r8, r9			; On stocke dans le registre r8, l'adresse du premier pixel auquel appliquer le masque (Source)
		mov r9, r11			; On stocke dans le registre r9, l'adresse du pixel de img_temp2 dans lequel on veut stocker le résultat. ATTENTION les contours ne sont pas comptés !
		mov r10, r12		; On stocke dans r10, la taille d'une ligne en pixel (cf ligne 54) (la taille d'une ligne, c'est le nombre de colonnes)..
		
		
		; rax = 4*biWidth + 4
		mov rax, 4
		mul r10
		add rax, 4
		
		add r9, rax
		
		mov rdx, r15 
		sub rdx, 2				; On enlève les 2 dernières lignes
		
		; Q3.3
		
		; rdx : nombre de lignes initialisé à la nbtotallignes-2
		; rcx : nombre de colonnes initialisé à nbtotalcolonnes-2
		; Puisque les contours sont retirés en raison de la matrice de convolution de Sobel
		
		; Q3.3.1
		
		; Quelle valeur affecter à r8 à la fin du traitement d'une ligne pour passer à la ligne suivante ?
		; A la fin du traitement d’une ligne, pour passer à la ligne suivante, on ajoute 8 octets à r8 car on saute 2 pixels (rappel : 1 pixel correspond à 4 octets).
		
		; Quelle valeur affecter à r9 à la fin du traitement d'une ligne pour passer à la ligne suivante ?
		; A la fin du traitement d’une ligne, pour passer à la ligne suivante, on ajoute 8 octets à r9 car on saute 2 pixels (rappel : 1 pixel correspond à 4 octets).
		
		; Q3.3.2
		
		; r8 et r9 sont incrémentés de 4 pour passer au pixel suivant.
		
lignes:
		
		cmp rdx, 0			; S'il ne reste plus de ligne...
		je fin_pour_lignes	; ...alors, on termine l'agorithme.
		mov rcx, r12		; Récupération du nombre de colonnes (cf ligne 54)
		sub rcx, 2			; On enlève les deux derniers pixels à chaque fois.
		
		; Des que r8 < col - 2
		; On passe à la ligne suivante ("r8 = r8 + 8")

colonnes:
		
		cmp rcx, 0				; S'il ne reste plus de colonnes...
		je fin_pour_colonnes	; ...alors on passe à la ligne suivante, première colonne.
		
		;Calcul de |Gx|
		mov r15, 0								; Résultat du pixel (b22 = m11a11 + m12a12 + ... + m33a33)
		
		movzx rax, byte ptr [r8]				; |-1|  |  | (-1*[r8]) (1 er pixel du masque de convolution).						 |  | 0|  |
		neg rax									; |  |  |  | En toute rigueur mathématique il faudrait s'occuper des 0 :			 |  | 0|  |
		add r15, rax							; |  |  |  | Informatiquement parlant, ça fait des calculs supplémentaires inutiles	 |  | 0|  |
		
		movzx rax, byte ptr [r8 + 8]			; |  |  | 1|
		add r15, rax;							; |  |  |  |
												; |  |  |  |
		
		movzx rax, byte ptr [r8 + r10*4]		; |  |  |  |
		imul rax, -2							; |-2|  |  |
		add r15, rax							; |  |  |  |
		
		
		movzx rax, byte ptr [r8 + r10*4 + 8]	; |  |  |  |
		imul rax, 2								; |  |  | 2|
		add r15, rax							; |  |  |  |
		
		movzx rax, byte ptr [r8 + r10*8]		; |  |  |  |
		neg rax									; |  |  |  |
		add r15, rax							; |-1|  |  |
		
		movzx rax, byte ptr [r8 + r10*8 + 8]	; |  |  |  |
		add r15, rax							; |  |  |  |
												; |  |  | 1|
		
		cmp r15, 0 	; Puis vérifier si c'est positif
		jge calcul_Gy ; si c'est positif ou égal à 0, alors on saute à calcul_Gy pour changer le signe sinon, on passe le code 

		neg r15 ; Gestion de la valeur absolue de Gx

calcul_Gy:

		mov r14, r15		; Sauvegarde de |Gx|
		
		mov r15, 0			; Réinitialisation de r15 à 0 pour stocker le résultat de Gy
		
		movzx rax, byte ptr [r8]				; | 1|  |  |
		add r15, rax							; |  |  |  |
												; |  |  |  |
		
		movzx rax, byte ptr [r8 + 4]			; |  | 2|  |
		imul rax, 2								; |  |  |  |
		add r15, rax							; |  |  |  |
		
		movzx rax, byte ptr [r8 + 8]			; |  |  | 1|
		add r15, rax							; |  |  |  |
												; |  |  |  |
		
		movzx rax, byte ptr [r8 + r10*8]		; |  |  |  |
		imul rax, -1							; |  |  |  |
		add r15, rax							; |-1|  |  |
		
		movzx rax, byte ptr [r8 + r10*8 + 4]	; |  |  |  |
		imul rax, -2							; |  |  |  |
		add r15, rax							; |  |-2|  |
		
		movzx rax, byte ptr [r8 + r10*8 + 8]	; |  |  |  |
		imul rax, -1							; |  |  |  |
		add r15, rax							; |  |  |-1|
		
		; |  |  |  |
		; | 0| 0| 0| Comme tout à l'heure, on ne fait pas les calculs pour 0
		; |  |  |  |
		
		cmp r15, 0 ; Idem que pour |Gx|
		jge inversion_intensite

		neg r15	; Gestion de la valeur absolue de Gy

inversion_intensite:    	; cf Algo p2/4 du TP (ligne : G <- 255 - G)

        add r14, r15        ; Sauvegarde de |G|
        neg r14
        add r14, 255
        
        cmp r14, 0			; Si G >= 0......
        jge image_resultante; ......On stocke dans le pixel de destination

        mov r14, 0 ; ......Sinon G < 0 alors G = 0 puis on stocke dans le pixel de destination.

image_resultante:

		mov byte ptr [r9], r14b
		mov byte ptr [r9 + 1], r14b
		mov byte ptr [r9 + 2], r14b
		mov byte ptr [r9 + 3], 0
		
		; Pixel suivant de l'image source et de l'image de destination
		add r8, 4
		add r9, 4
		dec rcx
		jmp colonnes

fin_pour_colonnes: ; On passe à la ligne suivante

		dec rdx
		add r8, 8
		add r9, 8
		jmp lignes

fin_pour_lignes:

		; On remet la pile à l'état initial
		pop		r15
		pop		r14
		pop		r13
		pop		r12
		pop		rsi
		pop		rdi
		pop		rbp
		pop		rbx
		
		;La fonction ne retourne rien
		ret						; Retour à la fonction d'appel
process_image_asm   endp

end
