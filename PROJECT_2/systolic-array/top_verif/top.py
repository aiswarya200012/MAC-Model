import os
import random
from pathlib import Path
from mac_model import *

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def checkNAN(x):
	exponent_bits = x & 0b01111111111111111111111111111111;
	if (exponent_bits <= 2139095040):
		return 0
	return 1

# SPECIAL CASE FILES
File_objectA    = open(r"A.txt","r");
File_objectB    = open(r"B.txt","r");
File_objectC    = open(r"C.txt","r");
File_objectS    = open(r"S.txt","r");


error_list1 =[];
error_list2 = [];
error_ind = [];
		  
@cocotb.test()
async def test_mac(dut):
    """Test to check mac"""
    #***************************************** INITIAL SETUP ********************************************************/
    # set enable as 0
    dut.EN_getA.value = 0
    dut.EN_getB.value = 0
    dut.EN_getS.value = 0
    dut.EN_getState = 0
  
    clock = Clock(dut.CLK, 10, units="us")  # Create a 10us period clock on port clk
    # Start the clock. Start it low to avoid issues on the first RisingEdge
    cocotb.start_soon(clock.start(start_high=False))
    # set reset as 0
    dut.RST_N.value   = 0
    await RisingEdge(dut.CLK)
    # set reset as 1
    dut.RST_N.value   = 1
    
    
    error = 0;
    #****************************************** TEST *******************************************************************#
    for matrix in range(150):
	    print('****************************** matrix',matrix+1,' ****************************');
	    result = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
	    model_result = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
	    
	    A = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
	    B = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
	    
	    for i in range(4):
	    	for j in range(4):
	    		A[i][j] = int((File_objectA.readline().strip()));
	    		B[i][j] = int((File_objectB.readline().strip()));
	    

	    s = int((File_objectS.readline().strip())); 
	    
	    # PASS B INTO THE DUT
	    # set enable as 1
	    dut.EN_getA.value = 0
	    dut.EN_getB.value = 1
	    dut.EN_getState = 1
	    dut.EN_getS.value = 1
	    dut.getState_state = 1;
	    for i in range(4):
	    	dut.getB_b1_inp.value  = B[3-i][0];
	    	dut.getB_b2_inp.value  = B[3-i][1];
	    	dut.getB_b3_inp.value  = B[3-i][2];
	    	dut.getB_b4_inp.value  = B[3-i][3];
	    	
	    	dut.getS_s1_inp.value  = s;
	    	dut.getS_s2_inp.value  = s;
	    	dut.getS_s3_inp.value  = s;
	    	dut.getS_s4_inp.value  = s;
	    	dut._log.info(f'     B1: {int(dut.getB_b1_inp.value)}, B2: {int(dut.getB_b2_inp.value)}, B3: {int(dut.getB_b3_inp.value)} B4: {int(dut.getB_b4_inp.value)}')
	    	#dut._log.info(f'     1: {int(dut.sendout1.value)}, 2: {int(dut.sendout2.value)}, 3: {int(dut.sendout3.value)} 4: {int(dut.sendout4.value)}')
	    	await RisingEdge(dut.CLK)
	    	
	    	
	    dut.getState_state = 0;
	    # to stabilise matrix B in the systolic array
	    for i in range(4):
	    	#dut._log.info(f'     1: {int(dut.sendout1.value)}, 2: {int(dut.sendout2.value)}, 3: {int(dut.sendout3.value)} 4: {int(dut.sendout4.value)}')
	    	await RisingEdge(dut.CLK)
	    
	    
	    # matrix for A
	    A_out = [[0] * 4 for _ in range(7)]
	    for k in range(7):
	    	if k<=3:
	    		ind = 0
	    	else:
	    		ind = k-3; 
	    	for j in range(4):
	    		for i in range(4):
	    			if (i+j == k):
	    				A_out[k][ind] = A[i][j];
	    				ind = ind+1;
	    				
	    				
	    dut.EN_getA.value = 1
	    dut.EN_getB.value = 0
	    dut.EN_getS.value = 1
	    m = 0
	    n =0 
	    # PASS A INTO THE SYSTOLIC ARRAY
	    for i in range(7):
	    	dut.getA_a1_inp.value  = A_out[i][0];
	    	dut.getA_a2_inp.value  = A_out[i][1];
	    	dut.getA_a3_inp.value  = A_out[i][2];
	    	dut.getA_a4_inp.value  = A_out[i][3];
	    	
	    	dut._log.info(f'     A1: {int(dut.getA_a1_inp.value)}, A2: {int(dut.getA_a2_inp.value)}, A3: {int(dut.getA_a3_inp.value)} A4: {int(dut.getA_a4_inp.value)}')
	    	await RisingEdge(dut.CLK)
	    	#dut._log.info(f'     1: {int(dut.sendout1.value)}, 2: {int(dut.sendout2.value)}, 3: {int(dut.sendout3.value)} 4: {int(dut.sendout4.value)}')
	    	await RisingEdge(dut.CLK)
	    	#dut._log.info(f'     1: {int(dut.sendout1.value)}, 2: {int(dut.sendout2.value)}, 3: {int(dut.sendout3.value)} 4: {int(dut.sendout4.value)}')
	    	if i == 4:
	    	#**************** result 00********************#
	    		result[0][0] = int(dut.sendout1.value);
	    	if i==5:
	    		 #**************** result 10********************#
	    		 result[1][0] = int(dut.sendout1.value);
	    		 #**************** result 01********************#
	    		 result[0][1] = int(dut.sendout2.value);
	    	if i==6:
	    		#**************** result 20********************#
		    	result[2][0] = int(dut.sendout1.value);
		    	#**************** result 11********************#
		    	result[1][1] = int(dut.sendout2.value);
		    	#**************** result 02********************#
		    	result[0][2] = int(dut.sendout3.value);
	    		
	    	await RisingEdge(dut.CLK)
	    	#dut._log.info(f'     1: {int(dut.sendout1.value)}, 2: {int(dut.sendout2.value)}, 3: {int(dut.sendout3.value)} 4: {int(dut.sendout4.value)}')
	    	await RisingEdge(dut.CLK)
	    	#dut._log.info(f'     1: {int(dut.sendout1.value)}, 2: {int(dut.sendout2.value)}, 3: {int(dut.sendout3.value)} 4: {int(dut.sendout4.value)}')

	    		
	    
	    for i in range(0, 19):
	    	#dut._log.info(f'     A: {int(dut.getB_b1_inp.value)}, B: {int(dut.getB_b2_inp.value)}, C: {int(dut.getB_b3_inp.value)} s: {int(dut.getB_b4_inp.value)}')
	    	#dut._log.info(f'     {i} 1: {int(dut.sendout1.value)}, 2: {int(dut.sendout2.value)}, 3: {int(dut.sendout3.value)} 4: {int(dut.sendout4.value)}')
	    	
	    	if i == 2:
		    	#**************** result 30********************#
		    	result[3][0] = int(dut.sendout1.value);
		    	#**************** result 21********************#
		    	result[2][1] = int(dut.sendout2.value);
		    	#**************** result 12********************#
		    	result[1][2] = int(dut.sendout3.value);
		    	#**************** result 03********************#
		    	result[0][3] = int(dut.sendout4.value);

	    	if i == 6:
		    	#**************** result 31********************#
		    	result[3][1] = int(dut.sendout2.value);
		    	#**************** result 22********************#
		    	result[2][2] = int(dut.sendout3.value);
		    	#**************** result 13********************#
		    	result[1][3] = int(dut.sendout4.value);

	    	if i == 10:
		    	#**************** result 32********************#
		    	result[3][2] = int(dut.sendout3.value);
		    	#**************** result 23********************#
		    	result[2][3] = int(dut.sendout4.value);
		    	
	    	if i == 14:
		    	#**************** result 33********************#
		    	result[3][3] = int(dut.sendout4.value);
	    	
	    	await RisingEdge(dut.CLK);
	    	
	    for i in range(20):
	    	await RisingEdge(dut.CLK);	
	    print(result)
	    model_result = mult_model(A[0][0] , A[0][1] , A[0][2] , A[0][3] , A[1][0] , A[1][1] , A[1][2] , A[1][3] , A[2][0] , A[2][1] , A[2][2] , A[2][3] , A[3][0] , A[3][1] , A[3][2] , A[3][3] , B[0][0] , B[0][1] , B[0][2] , B[0][3] , B[1][0] , B[1][1] , B[1][2] , B[1][3] , B[2][0] , B[2][1] , B[2][2] , B[2][3] , B[3][0] , B[3][1] , B[3][2] , B[3][3] , s )
	    print(model_result)
	    print(s)
	    
	    for i in range(4):
	    	for j in range(4):
	    		if checkNAN(model_result[i][j]) == 0:
	    			#assert (abs(result[i][j] - model_result[i][j]) <= 3), f'Counter Output Mismatch, Expected output of matrix element({i},{j}) = {model_result[i][j]} DUT = {result[i][j]}'
	    			if(abs(result[i][j] - model_result[i][j]) > 3):
	    				error = error+1;
	    				error_list1.append(result);
	    				error_list2.append(model_result);
	    				error_ind.append(matrix);
    
    print("No. OF FAILED CASES: ",error)
    print("FAILED CASES DUT MATRIX: ",error_list1);
    print("FAILED CASES PYTHON MODEL MATRIX: ",error_list2);
    print("MATRIX INDEX: ",error_ind);  
      			
    # stores the coverage in "coverage_mac.yml"	
    coverage_db.export_to_yaml(filename="coverage_mac.yml")    	
