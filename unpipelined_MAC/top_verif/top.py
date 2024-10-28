# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import os
import random
from pathlib import Path
from mac_model import *

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

# SPECIAL CASE FILES
File_objectA    = open(r"A.txt","r");
File_objectB    = open(r"B.txt","r");
File_objectC    = open(r"C.txt","r");
File_objectS    = open(r"S.txt","r");
File_objectEN_A  = open(r"EN_A.txt");
File_objectEN_B  = open(r"EN_B.txt");
File_objectEN_C  = open(r"EN_C.txt");
File_objectEN_S  = open(r"EN_S.txt");

# INPUT FILES FOR FP MAC
File_objectA1   = open(r"A_binary1.txt","r");
File_objectB1   = open(r"B_binary1.txt","r");
File_objectC1   = open(r"C_binary1.txt","r");
File_objectMAC1 = open(r"MAC_binary1.txt","r");

# INPUT FILES FOR INT MAC
File_objectA2   = open(r"A_binary2.txt","r");
File_objectB2   = open(r"B_binary2.txt","r");
File_objectC2   = open(r"C_binary2.txt","r");
File_objectMAC2 = open(r"MAC_binary2.txt","r");

arr_model       = [];
arr_out         = [];

@cocotb.test()
async def test_mac(dut):
    """Test to check mac"""
    #***************************************** INITIAL SETUP ********************************************************/
    # set enable as 0
    dut.EN_getA.value = 0
    dut.EN_getB.value = 0
    dut.EN_getC.value = 0
    dut.EN_getS.value = 0

    clock = Clock(dut.CLK, 10, units="us")  # Create a 10us period clock on port clk
    # Start the clock. Start it low to avoid issues on the first RisingEdge
    cocotb.start_soon(clock.start(start_high=False))
    # set reset as 0
    dut.RST_N.value   = 0
    await RisingEdge(dut.CLK)
    # set reset as 1
    dut.RST_N.value   = 1
    
    # set enable as 1
    dut.EN_getA.value = 1
    dut.EN_getB.value = 1
    dut.EN_getC.value = 1
    dut.EN_getS.value = 1

    #***************************** TESTING FOR CORNER CASES AND RANDOM GENERATED INPUTS *****************************/
    # to store outputs
    arr_model_corner = [];
    arr_out_corner   = [];
    A_prev = 0;
    B_prev = 0;
    C_prev = 0;
    S_prev = 0;
    # to check the corner cases and sign handling 
    for i in range(0, 13824):
    	if(i < 13824):
    		dut.getA_a.value  = int((File_objectA.readline().strip()))
    		dut.getB_b.value  = int((File_objectB.readline().strip()))
    		dut.getC_c.value  = int((File_objectC.readline().strip()))
    		dut.getS_s.value  = int((File_objectS.readline().strip()))
    		dut.EN_getA.value = int((File_objectEN_A.readline().strip()));
    		dut.EN_getB.value = int((File_objectEN_B.readline().strip()));
    		dut.EN_getC.value = int((File_objectEN_C.readline().strip()));
    		dut.EN_getS.value = int((File_objectEN_S.readline().strip()));
    		await RisingEdge(dut.CLK)
    		A   = int(dut.getA_a.value)
    		B   = int(dut.getB_b.value)
    		C   = int(dut.getC_c.value)
    		S   = int(dut.getS_s.value)
    		enA = int(dut.EN_getA.value)
    		enB = int(dut.EN_getB.value)
    		enC = int(dut.EN_getC.value)
    		enS = int(dut.EN_getS.value)
    		en = enA & enB & enC & enS
    		
    		dut._log.info(f'{i+1} S: {S} enA : {enA} enB : {enB} enC : {enC} enS : {enS} en: {en}')
    		dut._log.info(f'     A: {bin(A)}, B: {bin(B)}, C: {bin(C)} s: {bin(S)}')
    		
    		# If enable = 0, pass the previous input into the python model
    		if enA == 0:
    			A      = A_prev
    		if enB == 0:
    			B      = B_prev
    		if enC == 0:
    			C      = C_prev
    		if enS == 0:
    			S      = S_prev
		# The output from the python model is stored in an array
    		model_out = mac_model(enA,enB,enC,enS,A,B,C,S);
    		arr_model_corner.append(model_out);
    		
    		# The output from the design is stored in an array
    		arr_out_corner.append(int(dut.sendout_mac.value));
    		
    		# storing the previous input 
    		A_prev = A;
    		B_prev = B;
    		C_prev = C;
    		S_prev = S;
    
    #Setting the enable to be 0 once all the inputs ae given 		
    dut.EN_getA.value = 1;
    dut.EN_getB.value = 1;
    dut.EN_getC.value = 1;
    dut.EN_getS.value = 1;
    
    # Storing the outputs of the last three clock cycles
    for j in range(0,3):
    	await RisingEdge(dut.CLK);
    	arr_out_corner.append(int(dut.sendout_mac.value));	
    
    # to validate the output - comparing both the arrays
    for i in range(3,len(arr_out_corner)):
    	dut._log.info(f'OUTPUT {bin(arr_out_corner[i])}  model: {bin(arr_model_corner[i-3])} ')
    	
    	# ignoring the NaN outputs
    	exponent_bits = arr_model_corner[i-3] & 0b01111111111111111111111111111111;
    	if (exponent_bits <= 2139095040):
    		assert int(arr_model_corner[i-3]>>2) == int(arr_out_corner[i]>>2), f' {i-2} : Counter Output Mismatch, Expected = {bin(arr_model_corner[i-3])} {int(arr_model_corner[i-3])} DUT = {bin(arr_out_corner[i])} {int(arr_out_corner[i])}' 
    	
    #Setting the enable to 1 for the file inputs
    dut.EN_getA.value = 1;
    dut.EN_getB.value = 1;
    dut.EN_getC.value = 1;
    dut.EN_getS.value = 1;
    
    # to chech the given input values		
    for i in range(0, 1000):
    	s = i%2;	
    	if (s == 1):
    		output           = int(File_objectMAC1.readline(),2);
    		dut.getA_a.value = int(File_objectA1.readline(),2)
    		dut.getB_b.value = int(File_objectB1.readline(),2)
    		dut.getC_c.value = int(File_objectC1.readline(),2)
    		dut.getS_s.value = int(s);
    		await RisingEdge(dut.CLK)	
    		A = int(dut.getA_a.value)
    		B = int(dut.getB_b.value)
    		C = int(dut.getC_c.value)
    		S = int(dut.getS_s.value)
    	else:
    		output = int(File_objectMAC2.readline(),2)
    		dut.getA_a.value = int(File_objectA2.readline(),2)
    		dut.getB_b.value = int(File_objectB2.readline(),2)
    		dut.getC_c.value = int(File_objectC2.readline(),2)
    		dut.getS_s.value = int(s);
    		await RisingEdge(dut.CLK)	
    		A = int(dut.getA_a.value)
    		B = int(dut.getB_b.value)
    		C = int(dut.getC_c.value)
    		S = int(dut.getS_s.value)
    	enA = int(dut.EN_getA.value)
    	enB = int(dut.EN_getB.value)
    	enC = int(dut.EN_getC.value)
    	enS = int(dut.EN_getS.value)
    	en = enA & enB & enC & enS
		
    	counter_out = mac_model(enA,enB,enC,enS,A,B,C,S);
    	arr_model.append(counter_out);    
    	
    	if(i >= 3):
    	    arr_out.append(int(dut.sendout_mac.value));
    	    dut._log.info(f'output {int(dut.sendout_mac.value)}')
    
    #Setting the enable to be 0 once all the inputs ae given 		
    dut.EN_getA.value = 1;
    dut.EN_getB.value = 1;
    dut.EN_getC.value = 1;
    dut.EN_getS.value = 1;
    
    # Storing the outputs of the last three clock cycles
    for j in range(0,3):
    	await RisingEdge(dut.CLK);
    	arr_out.append(int(dut.sendout_mac.value));
    	
    # compare outputs	    
    for i in range(0,1000):
    	assert int(arr_model[i]) == int(arr_out[i]), f'Counter Output Mismatch, Expected = {bin(arr_model[i])} DUT = {bin(arr_out[i])}'
    
    # stores the coverage in "coverage_mac.yml"	
    coverage_db.export_to_yaml(filename="coverage_mac.yml")
   

