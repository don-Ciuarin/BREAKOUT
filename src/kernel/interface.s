/*
This file is part of gamelib-x64.

Copyright (C) 2014 Tim Hegeman

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

.global setTimer
.global readKeyCode

.section .kernel

# void setTimer(int16 reloadValue)
#
# The timer used by this library continually counts down from the reloadValue
# and fires an interrupt whenever this counter reaches zero. As the timer has
# a clock of 1193182 Hz, the interrupt rate is (1193182 / reloadValue) Hz.
# E.g., for 60 Hz the reloadValue should be set to 19886.
#
# Note: this library uses the legacy PIT, which is not guaranteed to reach
#       more than 100 Hz on physical machines. (100 Hz is typically used by
#       operating systems to schedule processes.)
setTimer:
	pushq	%rbp
	movq	%rsp, %rbp

	movb	$0x36, %al
	outb	%al, $0x43

	movq	%rdi, %rax
	outb	%al, $0x40
	xchgb	%al, %ah
	outb	%al, $0x40

	movq	%rbp, %rsp
	popq	%rbp
	ret

# int8 readKeyCode()
#
# Reads a single byte from the keyboard buffer. If a byte could be read,
# it is returned in the lowest 8 bits of the return value. Otherwise, 0
# is returned. For information on how to interpret these bytes, look up
# PS2 scan codes.
readKeyCode:
	pushq	%rbp
	movq	%rsp, %rbp

	call	ps2_getkey
	movq	$0, %rax
	or		%r8, %r8
	jz		1f
	movzx	%r8b, %rax

1:
	movq	%rbp, %rsp
	popq	%rbp
	ret

