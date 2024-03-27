.data
matrix: .byte 5, 6, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 
        1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0

output_print: .asciiz "Output"	
result_print: .asciiz "The number of the 1s on the largest island is "	

.text
main: 
	la $s0, matrix	# load matrix address
	
	# printing output_print
    	la $a0, output_print 
   	li $v0, 4              
   	syscall
   	
	# print 2d array
	jal print_array

	# search function call
	move $a0, $s0				
	jal search
	
	# saving return of search function
 	move $s0, $v0	
	
	# printing result_print
    	la $a0, result_print 
   	li $v0, 4              
   	syscall
    	# printing number of biggest 1`s island
    	move $a0, $s0  
        li $v0, 1             
        syscall
        
        # exiting program
    	li $v0, 10            
    	syscall       
    	        
search:
	addi $sp,$sp,-4 # creating memory 
   	sw $ra, 0($sp)  # storing return address
	
	lb $s1, 0($a0)	# load array[0], total row num
	lb $s2, 1($a0)	# load aray[1], total col num
	
	li $s3, 0	# max size of island of 1`s
	
	li $t0, 0	# i=0
outer_loop:
	# if i >= totalRowNo, exit outer loop			
	bge $t0, $s1, end_outer_loop
	
	li $t1, 0	# j=0
inner_loop:	
	# if j >= totalColNo, exit inner loop
	bge $t1, $s2, end_inner_loop
	
	# calculate index [2+i*totalColNo+j] for array access
	mul $t2, $t0, $s2	# i * totalColNo
    	add $t2, $t2, $t1       # i*totalColNo + j
    	addi $t2, $t2, 2        # 2 + i*totalColNo + j
	
	# load array[2 + i*totalColNo + j]
    	add $t3, $s0, $t2       # calculate the index
    	lb $t4, 0($t3)          # load the value
    	
    	# check if array[2 + i*totalColNo + j]==1
    	# if not equal continue to next inner loop
    	bne $t4, 1, next_inner_loop
    	
    	# calling recursice_count after we find 1
    	addi $sp,$sp,-8 # creating memory 
   	sw $t0, 0($sp)  # storing current row
   	sw $t1, 4($sp)  # storing current col
    	move $a0, $t0	# passing i, current row we are at
    	move $a1, $t1 	# passing j, current col we are at
    	jal recursive_count
    	lw $t0, 0($sp)	# restoring i, current row we are at
    	lw $t1, 4($sp)	# restoring j, current col we are at
	addi $sp,$sp,8	# adjusting stack pointer    	
    	
    	# if return value is bigger than current max size of island
    	# set max as return value else continue to next inner loop
    	bgt $v0, $s3, set_max	 	
    	b next_inner_loop							
set_max:
	move $s3, $v0

next_inner_loop:
	addi $t1, $t1,1 # increment j
    	j inner_loop              
    	
end_inner_loop:	
	addi $t0, $t0,1	# increment i
	j outer_loop
						
end_outer_loop:
	lw $ra, 0($sp)	# restoring return address
	addi $sp,$sp,4	# adjusting stack pointer
	move $v0, $s3   # returning max size of island of 1`s
	jr $ra		# return
	
# $a0 current row, $a1 current col
# $s0 matrix addres, $s1 total row num, $s2 total col num.
# this function recursively counts 1s on an island	
recursive_count:	
	addi $sp, $sp, -8	# creating memory 
	sw $ra, 0($sp)		# storing return address
	sw $s4, 4($sp)		# storing totalNumOf 1s of caller
	
	li $s4, 1		# current total no of 1s
	
	# calculating index of this element in array then setting 
	# it to 0, so when we call the next recursive_count
	# it wont count this element again and again.
	# to find our index we need to find:
	# ( 2 + (row * totalColNo) + col)	
	mul $t0, $a0, $s2	# row * totalColNo(in $s2)
	add $t0, $t0, $a1	# + col
	addi $t0, $t0, 2	# + 2 because of first 2 elements in array
	add $t0, $t0, $s0	# calculating address in the array($s0 matrix address)
	li $t1, 0		
	sb $t1, 0($t0)		# store value of this element as 0
	
	# searching if element above is 1
	bgtz $a0, check_above	# checking if row > 0, so we dont exceed array 
	b end_check_above						
check_above:
	move $t0, $s0      	# load array address into $t0
    	addi $t0, $t0, 2   	# move to array[2]
    	addi $t1, $a0, -1	# row-1(to go to upper element)    
    	mul $t1, $t1, $s2       # (row-1) * totalColNo
    	add $t1, $t1, $a1       # ((row-1) * totalColNo) + col
   	add $t0, $t1, $t0       # 2 + ((row-1) * totalColNo) + col
    	lb $t1, 0($t0)          # load array[2 + (row-1)*totalColNo + col]
    	# if array[2 + (row-1)*totalColNo + col] == 0, skip recursion
    	beq $t1, $zero, end_check_above 
   	addi $a0, $a0, -1       # decrement row
    	jal recursive_count     # recursively call recursiveCount
    	add $a0, $a0, 1         # restore row
    	add $s4, $s4, $v0       # currentCount + currentCountOfElementAbove
end_check_above:
	# searching if element below is 1
	addi $t0, $s1, -1	# totalRowNo-1
	blt $a0, $t0, check_below # row < totalRowNo-1, if there are more rows below
	b end_check_below
check_below:
	move $t0, $s0       	# load array address into $t0
    	addi $t0, $t0, 2   	# move to array[2]
    	addi $t1, $a0, +1	# row+1(to go to element below)    
    	mul $t1, $t1, $s2       # (row+1) * totalColNo
    	add $t1, $t1, $a1       # ((row+1) * totalColNo) + col
   	add $t0, $t1, $t0       # 2 + ((row+1) * totalColNo) + col
    	lb $t1, 0($t0)          # load array[2 + (row+1)*totalColNo + col]
    	# if array[2 + (row+1)*totalColNo + col] == 0, skip recursion
    	beq $t1, $zero, end_check_below 
   	addi $a0, $a0, 1        # increment row
    	jal recursive_count     # recursively call recursiveCount
    	add $a0, $a0, -1        # restore row
    	add $s4, $s4, $v0    	# currentCount + currentCountOfElementBelow
end_check_below:	
	# searching if element in left is 1
	bgtz $a1, check_left	# checking if col > 0, so we dont exceed array 
	b end_check_left
check_left:	
	move $t0, $s0       	# load array address into $t0
    	addi $t0, $t0, 2   	# move to array[2]
    	mul $t1, $a0, $s2       # row * totalColNo
    	addi $t2, $a1, -1	# col-1, to go to left block
    	add $t1, $t1, $t2       # (row * totalColNo) + col-1
   	add $t0, $t1, $t0       # 2 + (row * totalColNo) + col-1
    	lb $t1, 0($t0)          # load array[2 + row*totalColNo + col-1]
    	# if array[2 + row*totalColNo + col-1] == 0, skip recursion
    	beq $t1, $zero, end_check_left 
   	addi $a1, $a1, -1       # decrement col
    	jal recursive_count     # recursively call recursiveCount
    	add $a1, $a1, 1         # restore col
    	add $s4, $s4, $v0       # currentCount + currentCountOfLeftElement
end_check_left:
	# searching if element in right is 1
	addi $t0, $s2, -1	# totalColNo-1
	blt $a1, $t0, check_right # col < totalColNo-1, if there are more cols in right
	b end_check_right
check_right:
	move $t0, $s0       	# load array address into $t0
    	addi $t0, $t0, 2   	# move to array[2]
    	mul $t1, $a0, $s2       # row * totalColNo
    	addi $t2, $a1, 1	# col+1, to go to right block
    	add $t1, $t1, $t2       # (row * totalColNo) + col+1
   	add $t0, $t1, $t0       # 2 + (row * totalColNo) + col+1
    	lb $t1, 0($t0)          # load array[2 + row*totalColNo + col+1]
    	# if array[2 + row*totalColNo + col+1] == 0, skip recursion
    	beq $t1, $zero, end_check_right
   	addi $a1, $a1, 1        # increment col
    	jal recursive_count     # recursively call recursiveCount
    	add $a1, $a1, -1        # restore col
    	add $s4, $s4, $v0       # currentCount + currentCountOfLeftElement
end_check_right:		
	move $v0, $s4		# setting return value to currentNoOf 1s	
	lw $s4, 4($sp)		# restoring currentNoOf1s of caller
	lw $ra, 0($sp)		# restoring return address
	addi $sp, $sp, 8	# putting stack pointer back to initial point	
	jr $ra			# return						


# this function prints array in 2d
print_array:
	addi $sp,$sp,-4 # creating memory 
   	sw $ra, 0($sp)  # storing return address
	
	lb $s1, 0($s0)	# load array[0], total row num
	lb $s2, 1($s0)	# load aray[1], total col num
		
	mul $s1, $s1, $s2	# rows*cols	
	li $s3, 0	# i = 0
loop:
	bge $s3, $s1, exit_loop	# if( i >= row*col) leave for loop	
	
	# get the modulo to check if we need to go to next row 
	# if(i % cols == 0) then we need to print newline
	div $s3, $s2
	mfhi $t0
	
	# branch to same_row if (i % cols != 0)
	bne $t0, $zero, same_row
		
	# printing newline
	li $a0, 10  # ASCII value of a newline is "10"
    	li $v0, 11  
    	syscall    	
same_row:	
	# printing current number in array
	# i+2 because first 2 elements in array are row and col
	add $t0, $s3, 2	 	# i+2
	add $t0, $t0, $s0	# array[i+2]
	lb $a0, 0($t0)		# load array[i+2]
        li $v0, 1             
        syscall
		
	add $s3, $s3, 1	# increment i
	b loop
	
exit_loop:
	# printing newline
	li $a0, 10  # ASCII value of a newline is "10"
    	li $v0, 11  
    	syscall
    
	lw $ra, 0($sp)		# restoring return address
	addi $sp, $sp, 4	# putting stack pointer back to initial point	
	jr $ra			# return	
    	
	

	