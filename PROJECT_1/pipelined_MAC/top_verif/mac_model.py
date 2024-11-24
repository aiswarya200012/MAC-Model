import cocotb
from cocotb_coverage.coverage import *
import numpy as np
import tensorflow as tf
import struct
import random
#*************************************************************************************************
#					COVERAGE
#*************************************************************************************************

#****************** GENERATING RANDOM CASES AND CORNER CASE INPUT ********************************
random.seed(124)  
randomA    = random.sample(range(256,65534),k = 5) # Min value in range to ensure denormal numbers are not feeded as inputs
randomB    = random.sample(range(256,65534),k = 5) 
randomC    = random.sample(range(16777215,4294967294),k = 5)

# corner cases
list_A  = [0b0111111110000000, # A = +infinity 
	   0b1111111110000000, # A = -infinity 
	   0b0000000000000000, # A = zero 
	   0b0111111101111111, # A = highest positive value
	   0b1111111101111111, # A = lowest negative value
	   0b0001100111001010, # A = positive number
	   0b1100001110000001] # A = negative number
	  
list_B  = [0b0111111110000000, # B = +infinity 
	   0b1111111110000000, # B = -infinity 
	   0b0000000000000000, # B = zero 
	   0b0111111101111111, # B = highest positive value
	   0b1111111101111111, # B = lowest negative value
	   0b0001100111001010, # B = positive number
	   0b1100001110000001] # B = negative number 
	  
list_C  = [0b01111111100000000000000000000000, # C = +infinity
	   0b11111111100000000000000000000000, # C = -infinity
	   0b00000000000000000000000000000000, # C = zero
    	   0b01111111011111111111111111111111, # C = highest positive value
    	   0b11111111011111111111111111111111, # C = lowest negative value
    	   0b00011001110010100000000000000001, # C = positive number
	   0b11000011100000011111100001111101] # C = negative number
list_S  = [0,1];
list_EN_A = [1,0];
list_EN_B = [1];
list_EN_C = [1];
list_EN_S = [1,0];

# appending random generated numbers into the list
list_A.extend(randomA);
list_B.extend(randomB);
list_C.extend(randomC);


# file opening
File_objectA1  = open(r"A.txt","w",encoding = 'utf-8',newline='\n');
File_objectB1  = open(r"B.txt","w",encoding = 'utf-8',newline='\n');
File_objectC1  = open(r"C.txt","w",encoding = 'utf-8',newline='\n');
File_objectS1  = open(r"S.txt","w",encoding = 'utf-8',newline='\n');
File_objectEN_A1  = open(r"EN_A.txt","w",encoding = 'utf-8',newline='\n');
File_objectEN_B1  = open(r"EN_B.txt","w",encoding = 'utf-8',newline='\n');
File_objectEN_C1  = open(r"EN_C.txt","w",encoding = 'utf-8',newline='\n');
File_objectEN_S1  = open(r"EN_S.txt","w",encoding = 'utf-8',newline='\n');


#********************WRITING ALL PERMUTATIONS INTO THE FILES FOR GIVING INPUT*********************
for a in range(0,len(list_A)):
	for b in range(0,len(list_B)):
		for c in range(0,len(list_C)):
			for s in range(0,len(list_S)):
				for enA in range(0,len(list_EN_A)):
					for enB in range(0,len(list_EN_B)):
						for enC in range(0,len(list_EN_C)):
							for enS in range(0,len(list_EN_S)):
								File_objectA1.write(str(list_A[a])+'\n')
								File_objectB1.write(str(list_B[b])+'\n')
								File_objectC1.write(str(list_C[c])+'\n')
								File_objectS1.write(str(list_S[s])+'\n')
								File_objectEN_A1.write(str(list_EN_A[enA])+'\n')
								File_objectEN_B1.write(str(list_EN_B[enB])+'\n')
								File_objectEN_C1.write(str(list_EN_C[enC])+'\n')
								File_objectEN_S1.write(str(list_EN_S[enS])+'\n')
					
File_objectA1.close();
File_objectB1.close();			
File_objectC1.close();
File_objectS1.close();	
File_objectEN_A1.close();
File_objectEN_B1.close();
File_objectEN_C1.close();
File_objectEN_S1.close();
#****************************** DEFINING THE COVERAGE BINS ***************************************				
mac_coverage = coverage_section(
    CoverPoint( 'top.getA_a', 
    		vname='getA_a', 
    		bins  = list_A),
    CoverPoint( 'top.getB_b', 
    		vname='getB_b', 
    		bins  = list_B),
    CoverPoint(	'top.getC_c', 
    		vname='getC_c', 
    		bins  = list_C),
    CoverPoint( 'top.getS_s', 
    		vname='getS_s', 
    		bins = range(0,2)),
    CoverPoint( 'top.EN_A', 
    		vname='EN_A', 
    		bins = range(0,2)),
    CoverPoint( 'top.EN_B', 
    		vname='EN_B', 
    		bins = range(1,2)),
    CoverPoint( 'top.EN_C', 
    		vname='EN_C', 
    		bins = range(1,2)),
    CoverPoint( 'top.EN_S', 
    		vname='EN_S', 
    		bins = range(0,2)),
    CoverCross( 'top.cross_cover', 
    		items = ['top.getA_a', 'top.getB_b', 'top.getC_c','top.getS_s','top.EN_A','top.EN_B','top.EN_C','top.EN_S'])
)

#*************************************************************************************************
#					FUNCTIONS
#*************************************************************************************************
def twos_complement8bit_decimal(x):
	'''converts two's complement 8 bit integer to decimal'''
	if x >= 128:
		x = x - 256
	return x

def float32_to_bits(float_value: float) -> int:
	''' Convert float32 to its bit representation as an integer '''
	return struct.unpack('>I', struct.pack('>f', float_value))[0]

#****************************INT 8 MODEL**********************************************************
def intMAC_model(get_input_a: int, get_input_b: int, get_input_c: int) -> int:
	''' FUNCTION FOR INT MAC MODEL'''
	a 	= twos_complement8bit_decimal(get_input_a);
	b 	= twos_complement8bit_decimal(get_input_b);
	
	product = a*b;
	output  = product + get_input_c;
		
	result  = output
	
	return result & 0xFFFFFFFF
		
#**************************** FLOATING POINT MODEL ***********************************************
def fpMAC_model(get_input_a: int, get_input_b: int, get_input_c: int) -> int:
	''' FUNCTION FOR IEEE 754 MAC MODEL '''
	# Convert int inputs a and b to bfloat16
	bfloat_value  = tf.constant(get_input_a, dtype=tf.int32)  
	a_bfloat16    = tf.bitcast(bfloat_value, tf.bfloat16)
	
	bfloat_value  = tf.constant(get_input_b, dtype=tf.int32)  
	b_bfloat16    = tf.bitcast(bfloat_value, tf.bfloat16)
	
	# Convert int inputs c to float32
	float32_value = tf.constant(get_input_c, dtype=tf.int32)  
	c_float32     = tf.bitcast(float32_value, tf.float32)
	
	# multiplication of a and b
	result        = tf.multiply(a_bfloat16, b_bfloat16)
	
	# converting product into float32
	float_result  = tf.cast(result, tf.float32)
	
	# addition of product and c
	output        = result.numpy()[0] + c_float32.numpy();
	
	return float32_to_bits(output)

#*************************************************************************************************
#					TOP FUNCTION
#*************************************************************************************************
@mac_coverage
def mac_model(EN_A: int, EN_B: int, EN_C: int, EN_S: int, getA_a: int, getB_b: int, getC_c: int, getS_s: int) -> int:
	# if(EN_A or EN_B or EN_C or EN_S):
		# for intMac
		if(getS_s == 1):
			A = getA_a & 0xFF;
			B = getB_b & 0xFF;
			C = getC_c ;
			return intMAC_model(A,B,C);
		else:
			A = getA_a ;
			B = getB_b ;
			C = getC_c ;
			return fpMAC_model(A,B,C) & 0xFFFFFFFF;
	# return 0;
