	
.globl main

# x3 will ALWAYS contain the base address of
# the display memory
# heap begins at 0x1000 (I hope I won't override it)
# ball position can stay in s0, s1 (x, y)
# s2 will contain the left paddle and s3 will contian the right one
# s4, s5 will contain the ball's velocity


main:

	lui x3, 0x4000
	jal print_logo
	
	addi s0, zero, 15
	addi s1, zero, 15
	addi s2, zero, 11
	addi s3, zero, 11
	addi s4, zero, 1
	addi s5, zero, 1
	
	jal redraw_all
	
loop:
	jal redraw_update
	jal x0, loop
	
	
	
end:	jal x0, end


wait:
	beq a0, zero, wait_end
	addi a0, a0, -1
	b wait
	
wait_end:
	ret
	
	# ----------------- REDRAW ALL -----------------

redraw_all:
	# t0 is the row we're drawing
	addi t0, zero, 32
	
	
l1:	
	# Decrement
	addi t0, t0, -1
	
	# And this is the result
	addi t1, zero, 0
	
	# Draw ball
	bne t0, s1, after_ball
	lui t2, 0x80000
	srl t1, t2,  s0

after_ball:
	
	# Paddle size + 1
	addi t2, zero, 3
	# Draw left paddle
	sub t3, t0, s2
	bgeu t3, t2, after_lpaddle
	lui t3, 0x40000
	add t1, t1, t3
after_lpaddle:
	sub t3, t0, s3
	bgeu t3, t2, after_rpaddle
	addi t1, t1, 2

after_rpaddle:
	slli t2, t0, 2
	add t2, t2, x3
	sw  t1, 0(t2)
	bne t0, zero, l1

	ret
	
	# ----------------- UPDATE -----------------

	# Right paddle
redraw_update:
	lbu t0, 0x100(x3)
	
	andi t1, t0, 0x3
	beq  t1, zero, after_rpaddle1
	
	addi t1, t1, -2
	
	blt  t1, zero, L1
	# < 0 => UP
	beq  s3, zero, after_rpaddle1		# Can't go any higher
	addi s3, s3, -1
	slli t1, s3, 2
	
	add  t1, t1, x3				# t1 = address of first paddle row
	lw   t2, 0(t1)
	addi t2, t2, 2				# Add paddle pixel
	sw   t2, 0(t1)
	lw   t3, 12(t1)
	addi t3, t3, -2				# Remove paddle pixel
	sw   t3, 12(t1)		
	b after_rpaddle1
L1:
	# > 0 => DOWN
	addi  t1, s3, -29			# Last pixel is in position 32 - 3 = 29
	beq  t1, zero, after_rpaddle1
	addi s3, s3, 1
	slli t1, s3, 2
	add  t1, t1, x3				# t1 = address of first paddle row
	lw   t2, -4(t1)
	addi t2, t2, -2				# Add paddle pixel
	sw   t2, -4(t1)
	lw   t3, 8(t1)
	addi t3, t3, 2				# Remove paddle pixel
	sw   t3, 8(t1)		
	
	
after_rpaddle1:

	# Left paddle

	srli t1, t0, 2
	beq  t1, zero, after_lpaddle1
	
	addi t1, t1, -2
	
	blt  t1, zero, L2
	# < 0 => UP
	beq  s2, zero, after_lpaddle1		# Can't go any higher
	addi s2, s2, -1
	slli t1, s2, 2
	
	add  t1, t1, x3				# t1 = address of first paddle row
	lw   t2, 0(t1)
	lui  t0, 0x40000
	add  t2, t2, t0				# Add paddle pixel
	sw   t2, 0(t1)
	lw   t3, 12(t1)
	sub  t3, t3, t0				# Remove paddle pixel 
	sw   t3, 12(t1)		
	b after_lpaddle1
L2:
	# > 0 => DOWN
	addi t1, s2, -29			# Last pixel is in position 32 - 3 = 29
	beq  t1, zero, after_lpaddle1
	addi s2, s2, 1
	slli t1, s2, 2
	add  t1, t1, x3				# t1 = address of first paddle row
	lw   t2, -4(t1)
	lui  t0, 0x40000
	sub  t2, t2, t0 			# Add paddle pixel
	sw   t2, -4(t1)
	lw   t3, 8(t1)
	add  t3, t3, t0				# Remove paddle pixel
	sw   t3, 8(t1)		

after_lpaddle1:
	
	# TBall
	
	add t0, s0, s4
	add t1, s1, s5
	addi t2, zero, 32
	
	bge  t1, zero, not_over
	addi t1, zero, 0
	addi s5, zero, 1
	b after_y_checks
not_over:
	blt  t1, t2, after_y_checks
	addi t1, zero, 31
	addi s5, zero, -1

after_y_checks:
	
	# Now x checks
	bge  t0, zero, not_left
	addi t0, zero, 0
	addi s4, zero, 1
	b after_paddle_checks
not_left:
	blt  t0, t2, after_x_checks
	addi t0, zero, 31
	addi s4, zero, -1
	b after_paddle_checks

after_x_checks:
	
	# Now paddle checks (OMG this will be soo slow)
	addi t2, zero, 1
	bne  t0, t2, not_lpaddle
	sub  t2, t1, s2
	addi t3, zero, 3 # Paddle size
	bgeu t2, t3, after_paddle_checks
	addi t0, t0, 1
	addi s4, zero, 1
	b after_paddle_checks
	
not_lpaddle:
	
	addi t2, zero, 30
	bne  t0, t2, after_paddle_checks
	sub  t2, t1, s3
	addi t3, zero, 3 # Paddle size
	bgeu t2, t3, after_paddle_checks
	addi t0, t0, -1
	addi s4, zero, -1
	
after_paddle_checks:

	# Ok now delete old pixel, add new pixel
	slli t3, s1, 2
	add  t3, t3, x3
	lw   t4, 0(t3)
	lui  t5, 0x80000
	srl  t6, t5, s0
	xor  t4, t4, t6
	sw   t4, 0(t3)
	
	slli t3, t1, 2
	add  t3, t3, x3
	lw   t4, 0(t3)
	srl  t6, t5, t0
	xor  t4, t4, t6
	sw   t4, 0(t3)

	addi s0, t0, 0
	addi s1, t1, 0

	ret
	
	# ----------------- PRINT LOGO -----------------

print_logo:
	# Why haven't I implemented .data?
	
	sw      zero,0(x3)
        li      t0,0x57673a80
        sw      t0,4(x3)
        li      t0,0x75542a80
        sw      t0,8(x3)
        li      t0,0x57563380
        sw      t0,12(x3)
        li      t0,0x55542900
        sw      t0,16(x3)
        li      t0,0x55673b00
        sw      t0,20(x3)
        sw      zero,24(x3)
        sw      zero,28(x3)
        li      t0,0x77777000
        sw      t0,32(x3)
        li      t0,0x55442000
        sw      t0,36(x3)
        li      t0,0x65772000
        sw      t0,40(x3)
        li      t0,0x55112000
        sw      t0,44(x3)
        li      t0,0x57777000
        sw      t0,48(x3)
        sw      zero,52(x3)
        li      t0,0x47774bb8
        sw      t0,56(x3)
        li      t0,0x455468a8
        sw      t0,60(x3)
        li      t0,0x45766928
        sw      t0,64(x3)
        li      t0,0x45645a28
        sw      t0,68(x3)
        li      t0,0x77574bb8
        sw      t0,72(x3)
        sw      zero,76(x3)
        li      t0,0x54b801f0
        sw      t0,80(x3)
        li      t0,0x569002e8
        sw      t0,84(x3)
        li      t0,0x569005f4
        sw      t0,88(x3)
        li      t0,0x55900f1e
        sw      t0,92(x3)
        li      t0,0x74b80a0a
        sw      t0,96(x3)
        li      t0,0x00000a0a
        sw      t0,100(x3)
        li      t0,0x57770ffe
        sw      t0,104(x3)
        li      t0,0x755406ac
        sw      t0,108(x3)
        li      t0,0x556604a4
        sw      t0,112(x3)
        li      t0,0x55540208
        sw      t0,116(x3)
        li      t0,0x575701f0
        sw      t0,120(x3)
        sw      zero,124(x3)
	
	ret











