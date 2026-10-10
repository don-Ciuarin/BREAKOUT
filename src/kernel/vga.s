/*
This file is part of gamelib-x64.

Copyright (C) 2021 Ciprian Stanciu

gamelib-x64 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

gamelib-x64 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with gamelib-x64. If not, see <http://www.gnu.org/licenses/>.
*/

.global setPallette
.global clrScreen
.global saveScreen
.global loadScreen
.global putDot
.global putLine
.global putBitmap

# void setPallette(int8 colorNr, int32 color)
#
# Modifies the colour pallette by replacing
# what colour a (colour) number stands for.
# Colour should be RGB in last 24 bits of register,
# it will get automatically truncated to 18bit RGB.
setPallette:
	push	%rbp
	mov		%rsp, %rbp

	# just change the pallette
	# by writing to the VGA DAC
	mov 	%rdi, %rax
	mov 	$0x3c8, %dx 	# Write mode register,
	out 	%al, %dx 		# set to colour id.

	mov 	$0x3c9, %dx

	mov		%rsi, %rax 		# get R from RGB
	and 	$0xFF0000, %rax
	shr 	$18, %rax 		# and reduce to 6bits
	out	 	%al, %dx

	mov 	%rsi, %rax 		# get G from RGB
	and 	$0xFF00, %rax
	shr 	$10, %rax 		# reduce to 6bits
	out 	%al, %dx

	mov 	%rsi, %rax 		# get B from RGB
	and 	$0xFF, %rax
	shr 	$2, %rax 		# reduce to 6bits
	out 	%al, %dx

	movq	%rbp, %rsp
	popq	%rbp
	ret

# void clrScreen(int32 color)
#
# Resets the entire screen to a given colour.
clrScreen:
	push	%rbp
	mov 	%rsp, %rbp

	mov 	$0xA0000, %rax	# set the starting address

1:	
	# Check if we are still in bounds
	cmp 	$0xAFA00, %rax
	ja		2f

	mov 	%dil, (%rax)	# set pixel
	inc		%rax			# advance pointer
	jmp     1b

2:
	mov		%rbp, %rsp
	pop 	%rbp
	ret

# void saveScreen(int64* addr)
#
# Saves the current content on the screen to a
# given memory address.
# TODO (fix memory, useless right now)
saveScreen:
	push	%rbp
	mov 	%rsp, %rbp

	mov 	$0xA0000, %rax	# set the starting address

1:	
	# Check if we are still in bounds
	cmp 	$0xAFA00, %rax
	ja		2f

	mov 	(%rdi), %sil
	mov     %sil, (%rax)	# set pixel
	inc 	%rax			# advance pointer
	inc 	%rdi
	jmp     1b

2:
	mov 	%rbp, %rsp
	pop 	%rbp
	ret

# void loadScreen(int64* addr)
#
# Loads a previously saved screen from
# a memory address.
# TODO (fix memory, useless right now)
loadScreen:
	push	%rbp
	mov 	%rsp, %rbp

	mov 	$0xA0000, %rax	# set the starting address

1:	
	# Check if we are still in bounds
	cmp 	$0xAFA00, %rax
	ja		2f

	mov 	(%rdi), %sil
	mov     %sil, (%rax)	# set pixel
	inc 	%rax			# advance pointer
	inc 	%rdi
	jmp     1b

2:
	mov 	%rbp, %rsp
	pop 	%rbp
	ret

# void putDot(int8 x, int8 y, int32 color)
# 
# Changes the colour of the pixel at coordinates (x, y). The resolution of
# the screen is 320 x 200, with 256 colours.
putDot:
	push	%rbp
	mov 	%rsp, %rbp

	# The address to write to is 0xA0000 + (320 * y + x)
	and 	$0x1FF, %rdi    # can be at most 319,
							# make sure it's at most 511
	and 	$0xFF, %rsi     # can be at most 200, etc
	shl 	$8, %rsi		# RSI = 256 * y
	mov 	%rsi, %rax		# RAX = 256 * y
	shr 	$2, %rsi		# RSI = 64 * y
	add 	%rsi, %rax		# RAX = 320 * y
	add 	%rdi, %rax      # RAX = 320 * y + x

	# Ensure the index on the screen is within bounds
	cmp 	$64000, %rax
	jae		1f

	mov 	$0xA0000, %rdi
	add 	%rax, %rdi		# RDI now holds the address of the pixel

	# Write the colour
	mov 	%dl, (%rdi)

1:
	mov 	%rbp, %rsp
	pop 	%rbp
	ret

# void putLine(int8 x0, int8 y0, int8 x1, int8 y1, int32 color)
#
# Draws a line between points (x0, y0) and (x1, y1) with the specified
# colour. Calls putLineLow / putLineHigh depending on the slope of the line.
# Look up Bresenham's line algorithm.
putLine:
	push	%rbp
	mov 	%rsp, %rbp

	push	%r12
	push	%r13

	mov 	%rdx, %rax	# RAX = x1
	sub 	%rdi, %rax	# RAX = x1 - x0
	mov 	%rax, %r9 	# R9 = x1 - x0
	sar 	$63, %r9	# R9 = -1 or 0 depeding on sign
	xor 	%r9, %rax	# RAX = x when x>0 or 1s complement when x<0
	sub 	%r9, %rax	# RAX = abs(x1 - x0)
	mov 	%rax, %r12 	# R12 = abs(x1 - x0)

	mov 	%rcx, %rax	# RAX = y1
	sub 	%rsi, %rax	# RAX = y1 - y0
	mov 	%rax, %r9 	# R9 = y1 - y0
	sar 	$63, %r9	# R9 = -1 or 0 depeding on sign
	xor 	%r9, %rax	# RAX = y when y>0 or 1s complement when y<0
	sub 	%r9, %rax	# RAX = abs(y1 - y0)
	mov 	%rax, %r13 	# R13 = abs(y1 - y0)

	cmp 	%r12, %r13
	jge 	1f
		# Here abs(y1 - y0) < abs(x1 - x0), so gentle slope
		cmp 	%rdi, %rdx
		jge 3f
			# x0 > x1, so we reverse coordinates
			xchg	%rdi, %rdx
			xchg	%rsi, %rcx
			call putLineLow
			jmp 4f
	3:	# x0 <= x1, so just call
		call putLineLow
	4:	jmp 2f

1:	# steep slope
	cmp 	%rsi, %rcx
	jge 3f
		# y0 > y1, so we reverse coordinates
			xchg	%rdi, %rdx
			xchg	%rsi, %rcx
		call putLineHigh
		jmp 2f
	3:	# y0 <= y1, so just call
		call putLineHigh
2:

    pop 	%r13
    pop 	%r12

	mov 	%rbp, %rsp
	pop 	%rbp
	ret


# void putLineLow(int8 x0, int8 y0, int8 x1, int8 y1, int32 color)
#
# Draws a line between points (x0, y0) and (x1, y1) with the specified
# colour, for gentle slopes. Look up Bresenham's line algorithm.
putLineLow:
	push	%rbp
	mov 	%rsp, %rbp

	# Save the callee-saved registers
	push	%r12
	push	%r13
	push	%r14
	push	%r15
	push 	%rbx

	# Put coordinates into callee-saved registers
	mov 	%rdi, %r12 		# R12 = x0
	mov 	%rsi, %r14 		# R14 = y0
	mov 	%rdx, %r13 		# R13 = x1
	mov 	%rcx, %r15		# R15 = y1

	sub 	$24, %rsp 		# reserve space for 3 stack quads
	mov 	%r8, 8(%rsp)	# put colour on stack

	mov 	%r13, %rdi 		# RDI = x1
	sub 	%r12, %rdi 		# RDI = x1 - x0 (dx)

	mov 	%r15, %rbx 		# RBX = y1
	sub 	%r14, %rbx 		# RBX = y1 - y0 (dy)
	shl 	$1, %rbx 		# RBX = 2 * dy

	# Check whether y increases or decreases
	cmp 	$0, %rbx
	jg 1f
		movq 	$-1, (%rsp)		# if dy < 0
		neg 	%rbx			# also flip dy
		jmp 2f
1:	movq	 $1, (%rsp)		# if dy > 0


	# repurpose R15 for D
2:	mov 	%rbx, %r15		# R15 = 2 * dy
	sub 	%rdi, %r15		# R15 = 2 * dy - dx (D)

	shl 	$1, %rdi 		# RDI = 2 * dx
	mov 	%rdi, 16(%rsp) 	# put 2 * dx on stack

	# repurpose x0 R12 as (current) x
	# and y0 R14 as (current) y
1: 	cmp 	 %r12, %r13		# loop while x <= x1
	jl 1f
		mov 	%r12, %rdi
		mov 	%r14, %rsi
		mov 	8(%rsp), %rdx
		call  	putDot   		# we have a point at (x, y)

		cmpq	$0, %r15 		# if D > 0 then we begin with row y+1
		jle 2f
			add 	(%rsp), %r14 	# y++/--
			sub 	16(%rsp), %r15	# D = D - 2 * dx
2:		add 	%rbx, %r15 		# D = D + 2 * dy
		inc 	%r12 			# x++
		jmp 1b 					# go back to loop
1:	

	add 	$24, %rsp 	# Deallocate the variables

	# Restore the callee-saved registers
	pop 	%rbx
	pop 	%r15
	pop		%r14
	pop 	%r13
	pop 	%r12

	mov 	%rbp, %rsp
	pop 	%rbp
	ret

# void putLineHigh(int8 x0, int8 y0, int8 x1, int8 y1, int32 color)
#
# Draws a line between points (x0, y0) and (x1, y1) with the specified
# colour, for when the line is steep. Look up Bresenham's line algorithm.
putLineHigh:
	push	%rbp
	mov 	%rsp, %rbp

	# Save the callee-saved registers
	push	%r12
	push	%r13
	push	%r14
	push	%r15
	push 	%rbx

	# Put coordinates into callee-saved registers
	mov 	%rdi, %r12 		# R12 = x0
	mov 	%rsi, %r14 		# R14 = y0
	mov 	%rdx, %r13 		# R13 = x1
	mov 	%rcx, %r15		# R15 = y1

	sub 	$24, %rsp 		# reserve space for 3 quads
	mov 	%r8, 8(%rsp)	# put colour on stack

	mov 	%r13, %rbx 		# RBX = x1
	sub 	%r12, %rbx 		# RBX = x1 - x0 (dx)
	shl 	$1, %rbx 		# RBX = 2 * dx

	# Check whether x increases or decreases
	cmp 	$0, %rbx
	jg 1f
		movq 	$-1, (%rsp)		# if dx < 0
		neg 	%rbx			# also flip dx
		jmp 2f
1:	movq 	 $1, (%rsp)		# if dx > 0

2:	mov 	%r15, %rdi 		# RDI = y1
	sub 	%r14, %rdi 		# RDI = y1 - y0 (dy)

	# repurpose R13 for D
	mov 	%rbx, %r13		# R13 = 2 * dx
	sub 	%rdi, %r13		# R13 = 2 * dx - dy (D)

	shl 	$1, %rdi 		# RDI = 2 * dy
	mov 	%rdi, 16(%rsp) 	# put 2 * dy on stack

	# repurpose x0 R12 as (current) x
	# and y0 R14 as (current) y
1: 	cmp 	 %r14, %r15		# loop while y <= y1
	jl 1f
		mov 	%r12, %rdi
		mov 	%r14, %rsi
		mov 	8(%rsp), %rdx
		call  	putDot   		# we have a point at (x, y)

		cmp 	$0, %r13 		# if D > 0 then we begin with column x+1
		jle 2f
			add 	(%rsp), %r12 	# x++/--
			sub 	16(%rsp), %r13	# D = D - 2 * dy
2:		add 	%rbx, %r13 		# D = D + 2 * dx
		inc 	%r14 			# y++
		jmp 1b 					# go back to loop
1:	

	add 	$24, %rsp 	# Deallocate the variables

	# Restore the callee-saved registers
	pop 	%rbx
	pop 	%r15
	pop 	%r14
	pop 	%r13
	pop 	%r12

	mov 	%rbp, %rsp
	pop 	%rbp
	ret

# void putBitmap(int64* addr, int8 x, int8 y)
#
# Draws a bitmap on a screen. The argument should be a pointer to
# the beginning of the memory address.
# The format should be width-Word height-Word Colour-Bytes[...]
# CARE: colour code 0 -> transparency
putBitmap:
	push	%rbp
	mov 	%rsp, %rbp

	push	%r12
	push	%r13
	push	%r14
	push	%r15

	mov 	%rdi, %r14		# move the memory pointer to R14

	mov 	$0, %r12
	mov 	(%r14), %r12w	# set R12 to width

	mov 	$0, %r13
	mov 	2(%r14), %r13w	# set R13 to height

	add 	$4, %r14		# set pointer to beginning of pixels

	mov 	$0xA0000, %rdi
	shl 	$8, %rdx		# RDX = 256 * y
	mov 	%rdx, %rax		# RAX = 256 * y
	shr 	$2, %rdx		# RDX = 64 * y
	add 	%rdx, %rax		# RAX = 320 * y
	add 	%rsi, %rax      # RAX = 320 * y + x
	add 	%rdi, %rax		
	mov 	%rax, %r15		# R15 = pointer to first pixel in VGA memory

	mov 	$0, %rdi		# RDI = iterator for height loop
2:	cmp 	%rdi, %r13
	jle		1f
		mov 	$0, %rsi 	# RSI = iterator for width loop
	3:	cmp 	%rsi, %r12
		jle	4f
			# ARIN FIXXX!!!
			# the following line was initally cmpq
			# changed it to cmpb
			# (cmpq doesnt corectly check if a BYTE is 0)
			cmpb	$0, (%r14)	# if pixel 0 then dont draw
			je 		5f
				mov 	(%r14), %al
				mov 	%al, (%r15)	# set pixel
		5:	inc 	%r14		# advance pointers
			inc 	%r15
			inc 	%rsi
			jmp 3b

	4:	mov 	$320, %rax
		sub 	%r12, %rax 	# RAX holds how many pixels to skip for next line (320-width)
		add 	%rax, %r15 	# update VGA pointer
		inc 	%rdi
		jmp 2b

1:	pop 	%r15
	pop 	%r14
	pop 	%r13
	pop 	%r12

	mov 	%rbp, %rsp
	pop 	%rbp
	ret

# ARIN FIXXX
# Clearing the entire screen then redrawing everything takes a LOT of time.
# Because of this, the screen sometimes flickers if the monitor refreshes
# just as the screen is being drawn.
# Therefore, instead of redrawing the whole screen, Im just deleting the
# sprites that change their position and redrawing their new position.
# The following method is a copy of putBitMap, but instead of drawing the
# bitmap, it sets all of its pixels to the background color (black)
removeBitmap:
	push	%rbp
	mov 	%rsp, %rbp

	push	%r12
	push	%r13
	push	%r14
	push	%r15

	mov 	%rdi, %r14		# move the memory pointer to R14

	mov 	$0, %r12
	mov 	(%r14), %r12w	# set R12 to width

	mov 	$0, %r13
	mov 	2(%r14), %r13w	# set R13 to height

	add 	$4, %r14		# set pointer to beginning of pixels

	mov 	$0xA0000, %rdi
	shl 	$8, %rdx		# RDX = 256 * y
	mov 	%rdx, %rax		# RAX = 256 * y
	shr 	$2, %rdx		# RDX = 64 * y
	add 	%rdx, %rax		# RAX = 320 * y
	add 	%rsi, %rax      # RAX = 320 * y + x
	add 	%rdi, %rax		
	mov 	%rax, %r15		# R15 = pointer to first pixel in VGA memory

	mov 	$0, %rdi		# RDI = iterator for height loop
2:	cmp 	%rdi, %r13
	jle		1f
		mov 	$0, %rsi 	# RSI = iterator for width loop
	3:	cmp 	%rsi, %r12
		jle	4f
			# ARIN FIXXX!!!
			# the following line was initally cmpq
			# changed it to cmpb
			# (cmpq doesnt corectly check if a BYTE is 0)
			cmpb	$0, (%r14)	# if pixel 0 then dont draw
			je 		5f
				mov 	$0, %al
				mov 	%al, (%r15)	# set pixel
		5:	inc 	%r14		# advance pointers
			inc 	%r15
			inc 	%rsi
			jmp 3b

	4:	mov 	$320, %rax
		sub 	%r12, %rax 	# RAX holds how many pixels to skip for next line (320-width)
		add 	%rax, %r15 	# update VGA pointer
		inc 	%rdi
		jmp 2b

1:	pop 	%r15
	pop 	%r14
	pop 	%r13
	pop 	%r12

	mov 	%rbp, %rsp
	pop 	%rbp
	ret