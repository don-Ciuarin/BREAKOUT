.macro line x0, y0, x1, y1, col 
		movq	\x0, %rdi
		movq 	\y0, %rsi
		movq	\x1, %rdx
		movq 	\y1, %rcx
		movq 	\col, %r8
		call putLine
.endm

.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

platformX: .quad 145
platformY: .quad 176
platformSpeed: .quad 5

ballX: .quad 157
ballY: .quad 170
ballDX: .quad 1		
ballDY: .quad 2		
ballDXS: .quad 1		# The sign of the X displacement
ballDYS: .quad -1		# The sign of the Y displacement
ballSpeed: .quad 1
ballRest: .byte 1

is_A_pressed: .byte 0
is_D_pressed: .byte 0
is_SPACE_pressed: .byte 0

isBrick: .fill 54, 1, 1
nrBricks: .byte 54

currentScore: .quad 0
topScore: .quad 0

is_over: .byte 1

blackScreenPrinted: .byte 0

.section .game.text

gameInit:

	mov 	$0, %rdi
	mov 	$0x000000, %rsi
	call  	setPallette

	mov 	$1, %rdi
	mov 	$0xFFFFFF, %rsi
	call  	setPallette

	mov 	$2, %rdi
	mov 	$0xFF2C2C, %rsi
	call  	setPallette

	mov 	$3, %rdi
	mov 	$0x0015FF, %rsi
	call  	setPallette

	mov 	$4, %rdi
	mov 	$0x1CB800, %rsi
	call  	setPallette

	mov 	$5, %rdi
	mov 	$0xF6FF00, %rsi
	call  	setPallette

	movq	$39772, %rdi
	call	setTimer

	call	printBlackScreen

	ret

gameLoop:

	pushq	%rbx
	call	readInput

	cmpb	$1, is_over
	jne		1f
	cmpb	$1, is_SPACE_pressed
	jne		9f
	call	resetGame
	jmp		9f

	1:
	call	handleDifficulty
	call	clearScreen
	call	checkIfBallBegins
	call	handlePlatformMovement
	movq	ballSpeed, %rbx
	2:
		cmpq	$0, %rbx
		jle		2f
		call	handleBallMovement
		decq	%rbx
		jmp		2b
	2:

	9:
	call	printScreen
	popq	%rbx
	ret

resetGame:

	movb	$0, is_over
	movq	$145, platformX
	movq	$176, platformY
	movq	$157, ballX
	movq	$170, ballY
	movq	$1, ballDX
	movq	$2, ballDY
	movq	$1, ballDXS
	movq	$-1, ballDYS
	movb	$1, ballRest

	movq	$1, ballSpeed
	movq	$5, platformSpeed
	
	call	resetBricks

	call	printInit

	movq	$0, currentScore
	movb	$0, blackScreenPrinted

	ret

readInput:

	call	readKeyCode		# reading the key code
	cmpb	$0x39, %al		# if SPACE is pressed
	je		5f
	movb	$0, is_SPACE_pressed
	cmpb	$0x1E, %al		# if A is pressed
	je		1f
	cmpb	$0x9E, %al		# if A is released
	je		2f
	cmpb	$0x20, %al		# if D is pressed
	je		3f
	cmpb	$0xA0, %al		# if D is released
	je		4f

	jmp	9f

	1:
	movb	$1, is_A_pressed
	movb	$0, is_D_pressed
	jmp		9f

	2:
	movb	$0, is_A_pressed
	jmp		9f

	3:
	movb	$1, is_D_pressed
	movb	$0, is_A_pressed
	jmp		9f

	4:
	movb	$0, is_D_pressed
	jmp		9f

	5:
	movb	$1, is_SPACE_pressed
	jmp		9f

	9:
	ret

handleDifficulty:

	pushq	%rbx
	movq	currentScore, %rbx

	# 0 <= score < 20
	cmpq	$20, %rbx		
	jge		1f

	# default settings

	jmp		9f
	1:

	# 20 <= score < 60
	cmpq	$60, %rbx
	jge		1f
	
	movq	$2, ballSpeed
	movq	$6, platformSpeed

	jmp		9f
	1:

	# 60 <= score < 120
	cmpq	$120, %rbx
	jge		1f

	movq	$3, ballSpeed
	movq	$8, platformSpeed
	
	jmp		9f
	1:

	# 120 <= score < 200
	cmpq	$200, %rbx
	jge		1f

	movq	$4, ballSpeed
	movq	$10, platformSpeed
	
	jmp		9f
	1:

	# 200 <= score

	movq	$5, ballSpeed
	movq	$12, platformSpeed

	9:
	popq	%rbx
	ret

handlePlatformMovement:

	pushq	%rbx
	movq	platformSpeed, %rbx

	cmpb	$1, is_A_pressed
	je		1f

	cmpb	$1, is_D_pressed
	je		2f

	jmp		3f

	1:

	subq	%rbx, platformX		# Moving the platform left by 5px if A is pressed
	jmp		3f

	2:

	addq	%rbx, platformX		# Moving the platform right by 5px if D is pressed
	jmp		3f

	3:

	cmpq	$4, platformX		# Checking if its out of bonds and fixing it
	jg		4f
	movq	$5, platformX

	4:

	cmpq	$286, platformX		# Checking if its out of bonds and fixing it
	jl		9f
	movq	$285, platformX

	9:
	popq	%rbx
	ret

checkIfBallBegins:

	cmpb	$1, is_SPACE_pressed
	jne		9f
	movb	$0, ballRest

	9:
	ret

handleBallMovement:

	pushq	%rbx
	pushq	%r12

	# Checking if ball is resting on the platform
	movb	ballRest, %bl
	cmpb	$1, %bl
	jne		1f

	# Setting the balls position to the platform
	movq	platformX, %rbx
	addq	$12, %rbx
	movq	%rbx, ballX

	movq	platformY, %rbx
	subq	$6, %rbx
	movq	%rbx, ballY

	jmp		9f

	1:
	# Checking if ball hit the left wall
	cmpq	$5, ballX
	jg		1f
	movq	$1, ballDXS
	1:

	# Checking if ball hit the right wall
	cmpq	$309, ballX
	jl		1f
	movq	$-1, ballDXS
	1:

	# Checking if ball hit the top wall
	cmpq	$5, ballY
	jg		1f
	movq	$1, ballDYS
	1:

	# Checking if ball hit the bottom wall
	cmpq	$189, ballY
	jl		1f
	movq	$1, is_over
	jmp		9f
	1:

	call	handleBrickHit

	# Checking if ball hit the platform

	cmpq	$170, ballY		# Checking if its at or below the platform surface
	jl		1f
	cmpq	$172, ballY		# Checking if its at most 3 pixels below the surface
	jg		3f
	
	movq	platformX, %rbx
	subq	$5, %rbx
	cmpq	ballX, %rbx		# Checking if its to the right of the platforms left margin
	jg		1f
	movq	platformX, %rbx
	addq	$29, %rbx
	cmpq	ballX, %rbx		# Checking if its to the left of the platforms right margin
	jl		1f

	# INTERMETSSO - we have to check if we must reset the bricks

	cmpb	$0, nrBricks
	jg		4f
	call	resetBricks
	call	printBricks
	4:

	movq	$-1, ballDYS	# Changing the sign

	movq	platformX, %rbx
	addq	$3, %rbx
	cmpq	ballX, %rbx		# Checking if the ball is on the left side
	jl		2f
	movq	$2, ballDX
	movq	$1, ballDY
	jmp		1f

	2:

	movq	$-1, ballDYS	# Changing the sign
	movq	platformX, %rbx
	addq	$22, %rbx
	cmpq	ballX, %rbx		# Checking if the ball is on the right side
	jg		2f
	movq	$2, ballDX
	movq	$1, ballDY
	jmp		1f

	2:

	# If its neither, it means it is in the center
	movq	$1, ballDX
	movq	$2, ballDY
	jmp		1f

	3:		# Checking if weve hit a margin of the platform

	cmpq	$180, ballY		# If were pass the platform, we skip this step
	jg		1f

	# Checking if were between the 3 left pixels of the platform
	movq	platformX, %rbx
	subq	$6, %rbx
	cmpq	%rbx, ballX
	jl		3f
	addq	$3, %rbx
	cmpq	%rbx, ballX
	jg		3f
	movq	$2, ballDX
	movq	$1, ballDY	
	movq	$-1, ballDXS

	3:
	
	# Checking if were between the 3 right pixels of the platform
	movq	platformX, %rbx
	addq	$30, %rbx
	cmpq	%rbx, ballX
	jg		1f
	subq	$3, %rbx
	cmpq	%rbx, ballX
	jl		1f
	movq	$2, ballDX
	movq	$1, ballDY
	movq	$1, ballDXS


	1:

	movq	ballDX, %rax
	mulq	ballDXS
	addq	ballX, %rax
	movq	%rax, ballX

	movq	ballDY, %rax
	mulq	ballDYS
	addq	ballY, %rax
	movq	%rax, ballY

	9:
	popq	%r12
	popq	%rbx
	ret

handleBrickHit:

	pushq	%rbx
	pushq	%r12
	pushq	%r13
	pushq	%r14

	movq	$isBrick, %rbx
	movq	$15, %r12
	movq	$15, %r13

	1:	# row loop

		cmpq	$55, %r12
		jg		1f

		2: # column loop

			cmpq	$271, %r13
			jg		2f

			# actual section that i care about
			# r12 - x-position of the top left corner of the brick
			# r13 - y-position of the top left corner of the brick
			# rbx - position of the brick in the array

			cmpb	$0, (%rbx)		# if the brick is gone, we skip it
			je		3f

			# checking if were in the bounds of the brick

			movq	ballX, %r14
			addq	$6, %r14
			cmpq	%r13, %r14
			jl		3f

			movq	ballX, %r14
			subq	$30, %r14
			cmpq	%r13, %r14
			jg		3f

			movq	ballY, %r14
			addq	$6, %r14
			cmpq	%r12, %r14
			jl		3f

			movq	ballY, %r14
			subq	$6, %r14
			cmpq	%r12, %r14
			jg		3f

			# checking if weve hit the upper part of the brick

			movq	ballY, %r14
			addq	$6, %r14
			cmpq	%r12, %r14
			je		4f
			subq	$1, %r14		# (we are constantly checking for one more pixel because, because of the displacement vector, the ball can jump one pixel; therefore, we have to check for the first two layers of pixels)
			cmpq	%r12, %r14
			je		4f
			jne		5f
			4:		# if we hit it in this part:
			movq	$-1, ballDYS
			movb	$0, (%rbx)
			5:

			# checking if weve hit the lower part of the brick

			movq	ballY, %r14
			subq	$6, %r14
			cmpq	%r12, %r14
			je		4f
			addq	$1, %r14
			cmpq	%r12, %r14
			je		4f
			jne		5f
			4:		# if we hit it in this part:
			movq	$1, ballDYS
			movb	$0, (%rbx)
			5:

			# checking if weve hit the left part of the brick

			movq	ballX, %r14
			addq	$6, %r14
			cmpq	%r13, %r14
			je		4f
			subq	$1, %r14
			cmpq	%r13, %r14
			je		4f
			jne		5f
			4:		# if we hit it in this part:
			movq	$-1, ballDXS
			movb	$0, (%rbx)
			5:

			# checking if weve hit the right part of the brick

			movq	ballX, %r14
			subq	$30, %r14
			cmpq	%r13, %r14
			je		4f
			addq	$1, %r14
			cmpq	%r13, %r14
			je		4f
			jne		5f
			4:		# if we hit it in this part:
			movq	$1, ballDXS
			movb	$0, (%rbx)
			5:

			cmpb	$0, (%rbx)
			jne		3f
			movq	%r13, %rdi
			movq	%r12, %rsi
			call	deleteBrick

			3:
			addq	$32, %r13
			incq	%rbx
			jmp		2b

		2:

		movq	$15, %r13
		addq	$8, %r12
		jmp		1b

	1:

	9:
	popq	%r14
	popq	%r13
	popq	%r12
	popq	%rbx
	ret

deleteBrick:

	decb	nrBricks
	incq	currentScore
	call	handleDifficulty
	pushq	%rsi
	pushq	%rdi
	movq	$DEL_BRICK, %rdi
	popq	%rsi
	popq	%rdx
	call	removeBitmap
	ret

resetBricks:
	
	movb	$54, nrBricks

	pushq	%rbx
	pushq	%r12
	movq	$isBrick, %rbx
	movq	$1, %r12
	1:
		cmpq	$54, %r12
		jg		1f

		movb	$1, (%rbx)

		incq	%rbx
		incq	%r12
		jmp		1b
	1:
	popq	%r12
	popq	%rbx

	ret

printBricks:

	movq	$BRICKS, %rdi
	movq	$15, %rsi
	movq	$15, %rdx
	call	putBitmap
	ret

printInit:

	movq	$0, %rdi
	call	clrScreen

	call	printBricks

	call	printScreen
	ret

printScreen:

	cmpb	$1, is_over
	je		1f

	line	$4, $4, $315, $4, $1
	line	$315, $4, $315, $195, $1
	line	$315, $195, $4, $195, $1
	line	$4, $195, $4, $4, $1

	movq	$PLATFORM, %rdi
	movq	platformX, %rsi
	movq	platformY, %rdx
	call	putBitmap

	movq	$BALL, %rdi
	movq	ballX, %rsi
	movq	ballY, %rdx
	call	putBitmap

	jmp		9f

	1:

	call	printBlackScreen

	9:
	ret

printBlackScreen:

	cmpb	$1, blackScreenPrinted
	je 		9f

	pushq	%rbx
	movq	currentScore, %rbx
	cmpq	topScore, %rbx			# checking if we passed the top score
	jle		1f
	movq	%rbx, topScore
	1:
	popq	%rbx

	movq	$0, %rdi
	call	clrScreen

	movq	$GAME_NAME, %rdi
	movq	$27, %rsi
	movq	$30, %rdx
	call	putBitmap

	movq	$SPACE_PLAY, %rdi
	movq	$84, %rsi
	movq	$167, %rdx
	call	putBitmap

	movq	$SCORE_TEXT, %rdi
	movq	$28, %rsi
	movq	$108, %rdx
	call	putBitmap

	movq	currentScore, %rdi
	movq	$118, %rsi
	movq	$110, %rdx
	call	printNumber

	movq	topScore, %rdi
	movq	$108, %rsi
	movq	$127, %rdx
	call	printNumber

	movb	$1, blackScreenPrinted

	9:
	ret

printNumber:
	# rdi - the number
	# rsi - x axis of where to print
	# rdx - y axis of where to print

	pushq	%rbx
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%rcx

	movq	%rsi, %r12		# x axis
	movq	%rdx, %r13		# y axis
	movq	%rdi, %rbx		# the number

	movq	$0, %r14
	movq	$10, %rcx
	1:						# breaking into digits and storing them in the stack
		movq	$0, %rdx
		movq	%rbx, %rax
		divq	%rcx
		pushq	%rdx
		movq	%rax, %rbx
		incq	%r14

		cmpq	$0, %rbx
		jg		1b
	1:

	movq	$67, %rcx

	1:						# printing each digit
		cmpq	$0, %r14
		jle		1f

		popq	%rbx
		movq	%rbx, %rax
		mulq	%rcx			# two words + 63 pixels in each bit map - pointing to the right one
		movq	%rax, %rbx
		addq	$DIGITS, %rbx	# pointing to the right digit

		movq	%rbx, %rdi
		movq	%r12, %rsi
		movq	%r13, %rdx
		call	putBitmap

		addq	$9, %r12

		decq	%r14
		jmp		1b
	1:

	9:
	popq	%rcx
	popq	%r14
	popq	%r13
	popq	%r12
	popq	%rbx

	ret

clearScreen:

	movq	$PLATFORM, %rdi
	movq	platformX, %rsi
	movq	platformY, %rdx
	call	removeBitmap

	movq	$BALL, %rdi
	movq	ballX, %rsi
	movq	ballY, %rdx
	call	removeBitmap

	9:
	ret