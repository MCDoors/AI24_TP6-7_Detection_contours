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

		mov r11, [rsp + 40]	; On stocke dans le registre r9, l'adresse du pixel de img_temp2 dans lequel on veut stocker le résultat. ATTENTION les contours ne sont pas comptés (32 de shadow space + 8 pour être au dessus de img_temp2

		;***************************************
		;				  TP5				   *
		;***************************************

		push	rbx	;les registres rbx,rbp,rdi,rsi,rsp,r12,r13,r14,r15 doivent être sauvegardés par l'appelé, le reste est sauvegardé par l'appelant
		push	rbp
		push	rdi
		push	rsi
		push	rsp
		push	r12
		push	r13
		push	r14
		push	r15

		; Le passage de paramètre suis la convension fastcall 64
		; Les 4 premiers arguments sont passés dans rcx, rdx, r8 et r9 et le reste est mis sur la pile
		; biWidth	-> rcx
		; biHeight	-> rdx
		; img_src	-> r8
		; img_temp1	-> r9
		; Les 4 premiers sont dans le shadow space
		
		; ********* IL FAUT LES METTRES, POURQUOI CA MARCHE ? SUREMENT HISTOIRE DU CALL
		
		; img_temp2	-> [rsp + 32]
		; img_dest	-> [rsp + 40]
		
		mov r12, rcx		; On sauvegarde les deux premiers paramètres (ds le shadow space) dans la pile NON
		mov r15, rdx		; Après les paramètres précédents (img_temp2 et img_dest) puisqu'il sont déjà pris.
		
		
		imul rcx, rdx	; Le nombre de pixel.
		dec rcx		; Nombre de pixel - 1 (Parade pour le problème r8) ; Devient donc l'adresse de la fin de l'image.

		
color:
		cmp rcx, 0
		je init_registres ; Dès qu'on a le niveau de gris, on passe au TP6
		
		movzx rax, byte ptr [r8 + rcx*4]		; byte ptr [r8 + 4*rcx] BLEU
		shl rax, 8		; On déplace le byte ptr de 8 vers la gauche (et donc ce qui avait à la place du byte ptr devient des 0) Tout ce qui est à gauche disparaît.
		imul rax, 1Dh
		mov r13, rax
		
		movzx rax, byte ptr [r8 + rcx*4 + 1]	; VERT
		shl rax, 8
		imul rax, 96h
		add r13, rax
		
		movzx rax, byte ptr [r8 + rcx*4 + 2]	; ROUGE
		shl rax, 8
		imul rax, 4Ch
		add r13, rax
		
		; r13 = 4C * Rouge + 96 * Vert + 1D * Bleu
		
		shr r13, 16		; On déplace le r13 de 16 bits vers la droite (on supprime donc la moitié) (en gros meme délire que la virgule)
		
		mov byte ptr [r9 + rcx*4], r13b		; On stocke dans B et la technique du niveau gris.
		mov byte ptr [r9 + rcx*4 + 1], 0
		mov byte ptr [r9 + rcx*4 + 2], 0
		mov byte ptr [r9 + rcx*4 + 3], 0
		
		dec rcx	; Décrémentation de l'index du pixel.
		cmp rcx, 0
		jne color

		;***************************************
		;				TP6/7				   *
		;***************************************
		
		; Q3.2

init_registres:				; Q3.2

		mov r8, r9			; On stocke dans le registre r8, l'adresse du premier pixel auquel appliquer le masque (Source)
		mov r9, r11			; On récupère l'argument du shadow space

		mov r10, r12		; On stocke dans r10, la taille d'une ligne en pixel (la taille d'une ligne, c'est le nombre de colonnes).
		
		
		; rax = 4*biWidth + 4
		mov rax, 4
		mul r10
		add rax, 4				
		
		mov rdx, r15		; Utile ? on y touche jamais rdx
		sub rdx, 2				; On enlève les 2 dernières colonnes
		
		; ********** ATTENTION, histoire du double mot de 32 bits !
		; (LE CODE POUR 4*(biWidth+1))
		
		
		; Q3.3
		; rdx : nombre de lignes initialisé à la nbtotallignes-2
		; rcx : nombre de colonnes initialisé à nbtotalcolonnes-2
		; puisque les contours sont retirés en raison de la matrice de convolution de Sobel
		
		; INITIALISATION DE rdx ET rcx
		
		;mov	rax, rdx	; rax  = biHeight Registre tampon qui garde en mémoire le nombre de lignes.
		
		; Q3.3.1
		
		
		;mov rdx, rcx	; rdx = biWidth (le nombre de lignes)
		;sub rdx, 2		; rdx = biWidth - 2 (le nombre de lignes - 2) ; Initialisation de rdx au début du traitement de l'image
		
		; Quelle valeur affecter à r8 à la fin du traitement d'une ligne pour passer à la ligne suivante ?
		; r8 - 2 dernières colonnes
		
		
		; Quelle valeur affecter à r9 à la fin du traitement d'une ligne pour passer à la ligne suivante ?
		; r9 - 1 dernière colonne
		
lignes:
		
		cmp rdx,0
		je fin_pour_lignes
		mov rcx, r12		
		sub rcx, 2				; On enlève les deux derniers pixels à chaque fois.
		
		; On parcourt à l'envers ??
		add	r8, 1		; Passer au pixel suivant
		; Des que r8 < col - 2
		; On passe à la ligne suivante
		
colonnes:
		
		cmp rcx, 0
		je fin_pour_colonnes
		
		;Gx
		mov rbx, 0								; Résultat du pixel (b22 = m11a11 + m12a12 + ... + m33a33)
		
		movzx rax, byte ptr [r8]				; |-1|  |  | (-1*[r8]) (1 er pixel du masque de convolution)
		imul rax, -1							; |  |  |  |
		add rbx, rax							; |  |  |  |
		
		movzx rax, byte ptr [r8 + 8]
		add rbx, rax;
		
		
		movzx rax, byte ptr [r8 + r10*4]
		imul rax, -2
		add rbx, rax
		
		
		movzx rax, byte ptr [r8 + r10*4 + 8]
		imul rax, 2
		add rbx, rax
		
		movzx rax, byte ptr [r8 + r10*8]
		imul rax, -1
		add rbx, rax
		
		movzx rax, byte ptr [r8 + r10*8 + 8]
		imul rax, -1
		add rbx, rax
		
		cmp rbx, 0 ; Puis vérifier si c'est positif
		jl valeur_absolue_Gx ; si c'est négatif, alors on va a valeur absolue pour changer le signe

valeur_absolue_Gx:
		
		cmp rbx, 0
		jge calcul_Gy
		imul rbx, -1

calcul_Gy:

		mov r14, rbx		; Sauvegarde de Gx
		
		mov rbx, 0			; Réinitialisation de rbx à 0 pour stocker le résultat de Gy
		
		movzx rax, byte ptr [r8]
		add rbx, rax
		
		movzx rax, byte ptr [r8 + 4]
		imul rax, 2
		add rbx, rax
		
		movzx rax, byte ptr [r8 + 8]
		add rbx, rax
		
		movzx rax, byte ptr [r8 + r10*8]
		imul rax, -1
		add rbx, rax
		
		movzx rax, byte ptr [r8 + r10*8 + 4]
		imul rax, -2
		add rbx, rax
		
		movzx rax, byte ptr [r8 + r10*8 + 8]
		imul rax, -1
		add rbx, rax
		
		cmp rbx, 0
		jl valeur_absolue_Gy

valeur_absolue_Gy:

		cmp rbx, 0
		jge inversion_intensite
		imul rbx, -1

inversion_intensite:

		mov r14, rbx		; add r14, rbx ; Sauvegarde de Gx
		
		imul r14, -1
		add r14, 255
		
		cmp r14, 0
		jl G_negatif

G_negatif:
		
		cmp r14, 0
		jge image_resultante
		mov r14, 0 ; Si G < 0 alors G = 0

image_resultante:

		mov byte ptr [r9], r14b
		mov byte ptr [r9 + 1], r14b
		mov byte ptr [r9 + 2], r14b
		mov byte ptr [r9 + 3], 0
		
		; Pixel suivant
		add r8, 4
		add r9, 4
		dec rcx
		jmp colonnes

fin_pour_colonnes:

		dec rdx
		add r8, 8
		add r9, 8
		jmp lignes

fin_pour_lignes:
		
		; Q3.3.2
		
		
		;mov rcx, rax	; rcx = biHeight (le nombre de colonnes)
		;sub rcx, 2		; rcx = biHeight - 2 (le nombre de colonnes - 2) ; Initialisation de rcx au début du traitement de chaque ligne
		
		; tant que r9 < dernier pixel de la ligne alors continuer, sinon passer à deux pixels après


		pop		r15
		pop		r14
		pop		r13
		pop		r12
		pop		rsp
		pop		rsi
		pop		rdi
		pop		rbp
		pop		rbx
		
		;La fonction ne retourne rien
		ret						; Retour à la fonction d'appel
process_image_asm   endp

end
