import cocotb
from cocotb_coverage.coverage import *
import numpy as np
import tensorflow as tf
import struct
import random
import itertools
import copy
#*************************************************************************************************
#					COVERAGE
#*************************************************************************************************

#****************** GENERATING RANDOM CASES AND CORNER CASE INPUT ********************************
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
	   
# random cases	
casesA = [];
casesB = [];   

for i in range(16): 
	random.seed(1 + i) 
	randomA = random.sample(range(256,65534),k = 193) # Min value in range to ensure denormal numbers are not feeded as inputs
	randomA.extend(list_A);
	random.shuffle(randomA)
	casesA.append(randomA);
	
	randomB = random.sample(range(256,65534),k = 193)
	randomB.extend(list_B);
	random.shuffle(randomB)
	casesB.append(randomB);
	

list_S  = [0,1];
list_EN_A = [1,0];
list_EN_B = [1];
list_EN_C = [1];
list_EN_S = [1,0];

# Generating main list
index = 0;
ListA = [0 for i in range(len(casesA)*len(casesA[0]))]
ListB = [0 for i in range(len(casesB)*len(casesB[0]))]
for j in range(len(casesA[0])):
	for i in range(len(casesA)):
		ListA[index] = casesA[i][j];
		ListB[index] = casesB[i][j];
		index = index + 1

# randomise S
list_S    = random.choices(range(2),k = int(len(ListA)/16));

# file opening
File_objectA1  = open(r"A.txt","w",encoding = 'utf-8',newline='\n');
File_objectB1  = open(r"B.txt","w",encoding = 'utf-8',newline='\n');
File_objectS1  = open(r"S.txt","w",encoding = 'utf-8',newline='\n');

#********************WRITING ALL PERMUTATIONS INTO THE FILES FOR GIVING INPUT*********************
for i in range(len(ListA)):
	File_objectA1.write(str(ListA[i])+'\n')
	File_objectB1.write(str(ListB[i])+'\n')
	
	if i%16 == 0:
		File_objectS1.write(str(list_S[int(i/16)])+'\n')
					
File_objectA1.close();
File_objectB1.close();			
File_objectS1.close();
	

#****************************** DEFINING THE COVERAGE BINS ***************************************				
mac_coverage = coverage_section(
    CoverPoint( 'top.getA_a00', vname='getA_a00', bins  = casesA[0]),
    CoverPoint( 'top.getA_a01', vname='getA_a01', bins  = casesA[1]),
    CoverPoint( 'top.getA_a02', vname='getA_a02', bins  = casesA[2]),
    CoverPoint( 'top.getA_a03', vname='getA_a03', bins  = casesA[3]),
    CoverPoint( 'top.getA_a10', vname='getA_a10', bins  = casesA[4]),
    CoverPoint( 'top.getA_a11', vname='getA_a11', bins  = casesA[5]),
    CoverPoint( 'top.getA_a12', vname='getA_a12', bins  = casesA[6]),
    CoverPoint( 'top.getA_a13', vname='getA_a13', bins  = casesA[7]),
    CoverPoint( 'top.getA_a20', vname='getA_a20', bins  = casesA[8]),
    CoverPoint( 'top.getA_a21', vname='getA_a21', bins  = casesA[9]),
    CoverPoint( 'top.getA_a22', vname='getA_a22', bins  = casesA[10]),
    CoverPoint( 'top.getA_a23', vname='getA_a23', bins  = casesA[11]),
    CoverPoint( 'top.getA_a30', vname='getA_a30', bins  = casesA[12]),
    CoverPoint( 'top.getA_a31', vname='getA_a31', bins  = casesA[13]),
    CoverPoint( 'top.getA_a32', vname='getA_a32', bins  = casesA[14]),
    CoverPoint( 'top.getA_a33', vname='getA_a33', bins  = casesA[15]),
    CoverPoint( 'top.getB_b00', vname='getB_b00', bins  = casesB[0]),
    CoverPoint( 'top.getB_b01', vname='getB_b01', bins  = casesB[1]),
    CoverPoint( 'top.getB_b02', vname='getB_b02', bins  = casesB[2]),
    CoverPoint( 'top.getB_b03', vname='getB_b03', bins  = casesB[3]),
    CoverPoint( 'top.getB_b10', vname='getB_b10', bins  = casesB[4]),
    CoverPoint( 'top.getB_b11', vname='getB_b11', bins  = casesB[5]),
    CoverPoint( 'top.getB_b12', vname='getB_b12', bins  = casesB[6]),
    CoverPoint( 'top.getB_b13', vname='getB_b13', bins  = casesB[7]),
    CoverPoint( 'top.getB_b20', vname='getB_b20', bins  = casesB[8]),
    CoverPoint( 'top.getB_b21', vname='getB_b21', bins  = casesB[9]),
    CoverPoint( 'top.getB_b22', vname='getB_b22', bins  = casesB[10]),
    CoverPoint( 'top.getB_b23', vname='getB_b23', bins  = casesB[11]),
    CoverPoint( 'top.getB_b30', vname='getB_b30', bins  = casesB[12]),
    CoverPoint( 'top.getB_b31', vname='getB_b31', bins  = casesB[13]),
    CoverPoint( 'top.getB_b32', vname='getB_b32', bins  = casesB[14]),
    CoverPoint( 'top.getB_b33', vname='getB_b33', bins  = casesB[15]),
    CoverPoint( 'top.getS_s', vname='getS_s', bins = range(0,2)),
    
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
def mac_model(getA_a: int, getB_b: int, getC_c: int, getS_s: int) -> int:
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
	
@mac_coverage
def mult_model(getA_a00: int, getA_a01: int, getA_a02: int, getA_a03: int, getA_a10: int, getA_a11: int, getA_a12: int, getA_a13: int, getA_a20: int, getA_a21: int, getA_a22: int, getA_a23: int, getA_a30: int, getA_a31: int, getA_a32: int, getA_a33: int, getB_b00: int, getB_b01: int, getB_b02: int, getB_b03: int, getB_b10: int, getB_b11: int, getB_b12: int, getB_b13: int, getB_b20: int, getB_b21: int, getB_b22: int, getB_b23: int, getB_b30: int, getB_b31: int, getB_b32: int, getB_b33: int, getS_s: int) -> int:

	getA_a = [[getA_a00,getA_a01,getA_a02,getA_a03] , 
		  [getA_a10,getA_a11,getA_a12,getA_a13] , 
		  [getA_a20,getA_a21,getA_a22,getA_a23] , 
		  [getA_a30,getA_a31,getA_a32,getA_a33]];
	
	getB_b = [[getB_b00,getB_b01,getB_b02,getB_b03] , 
	 	  [getB_b10,getB_b11,getB_b12,getB_b13] , 
	 	  [getB_b20,getB_b21,getB_b22,getB_b23] , 
	 	  [getB_b30,getB_b31,getB_b32,getB_b33]];
	print(getA_a)	
	print(getB_b)  
	result = [[0,0,0,0],
		  [0,0,0,0],
		  [0,0,0,0],
		  [0,0,0,0]];
	for i in range(4):
		for j in range(4):
			for k in range(4):
				if k == 0:
					result[i][j] = mac_model(getA_a[i][k], getB_b[k][j], 0, getS_s)
				else:
					result[i][j] = mac_model(getA_a[i][k], getB_b[k][j], result[i][j], getS_s) 
	
	return result

	

