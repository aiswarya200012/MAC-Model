# MAC-Model
The following design consists of a top module which performs MAC(Multiply-Accumulate) generation for inputs of the following data types:
1. S1: (A:int8,B:int8,C:int32) -> (MAC:int32)
2. S2: (A:bf16,B:bf16,C:fp32) -> (MAC:fp32)

In order to do so, we have split the whole design into three major modules.
1. int8 MAC module -> This module generates the MAC of type S1
2. fp32 MAC module -> This module generates the MAC of type S2
3. Top module -> This module instantiates the above two modules and feeds the inputs to them on the basis of the value of a select input S.

### Top Module
*************************TOP MODULE -> topModule ********************************<br>
The top module consists of the following methods:
1. getA- Used to register the 16 bit input A
2. getB- Used to register the 16 bit input B
3. getC- Used to register the 32 bit input C
4. getS- Used to register the 1 input S (Select signal)
5. sendout_mac - It is used to register the output, based on the value of S

The rule rl_mux_input, incorporates the functionality of the MUX's at the input. Based on the value of S, we feed the inputs to the appropriate MAC module. If S =1, MAC computation occurs for type S1(int8), if S=0, MAC computation occurs for type S2(fp32).

** If S=1, the LSB 8 bits are fed to the inputs A and B of the int8 MAC module. **

### int8 MAC Module
*************************int8 MAC module -> mkMult ******************************** <br>
The int8 MAC module consists of the following methods:
1. get_inp- Fetches the inputs A,B and C.
2. send_out- Registers the output generated MAC

Now,
The signed multiplication of two numbers A and B expressed in 2's complement form can be performed as shown in the following figure:

![lagrida_latex_editor](https://github.com/user-attachments/assets/f32628c0-1452-4088-9b49-a54ef78b8bff)

The above Equation, in operands form is illustrated as shown in the following figure.
![fig1](https://github.com/user-attachments/assets/54258d46-010b-4251-b276-877d50f97000)

As seen in case 1, we have a series of fixed 1 additions which need to be perfomed. Hence, simplifying the design further, we end up with case 2.Thus, instead of sign Extending the partial products, we can simply add (256) and (32768) after generating the partial products as specified in case 2. 

In the provided code, we perform the multiplication as follows.
1. Step 1. We generate all the 8 partial products while taking care of negating the AND terms where one of the bits is the MSB of one of the inputs, while the other bit is not.  Eg.(A7B0)
2. Step 2. We perform partial products addition.
3. Step 3. We add up the values (256) and (32768) which correspond to the 1's shown in the above figure.
4. Step 4. We append zeroes to the product and add C.

In the pipelined design, we have tried to split the whole code into chunks of equal delay as much as possible. The design flow is as shown in the following figure.
![fig2](https://github.com/user-attachments/assets/9a6b5a52-3269-4c80-97e0-ec8c320a669a)

Stage 1: We compute all the 8 partial products.i.e P[n] where n=0,1,..7
Stage 2: We parallely compute the sum 4 partial products parallely. Let this be S[0] = summation(P[n]) for n =0,1,2,3 and S[1] = summation(P[n]) for n =4,5,6,7.
Stage 3: We compute the sum of S[0] ,S[1] , x,y and C. Thereby giving us the final MAC.

As seen, Stage 2 involves three 16 bit additions while Stage 3 involves sequential two 16 bit additions and one 32 bit addition. Thereby balancing the delay of the two blocks to a specific extent.

### fp32 MAC Module
*************************fp32 MAC module -> mkMult_exp ******************************** <br>
The fp32 MAC module consists of the following methods:
1. get_input- Fetches the inputs A,B and C. It will split the inputs into the mantissa, exponent and sign bits.
2. send_output- Registers the output generated MAC and sends it out in IEEE Single precision format.

Floating point multiplication involves the following steps<br>
STEP 1: Mantissa Multiplication and Exponent Addition -> In this step, we multiply the mantissa of the two input operands A and B<br>
STEP 2: Mantissa Normalization -> In this step, we normalize the mantissa such that the product is always less than 2 and update the exponent accordingly.<br>
STEP 3: Mantissa rounding according to Round to nearest -> We use the round to nearest method to round the mantissa to 7 bits, as per the bfloat standard. The rounding off scheme works as follows:<br>
1. Find the Gaurd bits (G:8th bit), Round bit (R: 9th bit) and Sticky(S: OR of remaining bits) bit.
2. Now, if GRS = 100 : If 7th bit is 1, increment it, else round down
3.         GRS = 0xx : Round down
           GRS = 101,110,111: Increment the number by 1.
Therefore, we end up with the product in bfloat16 format.

Now, Floating point addition involves the following steps<br>
STEP 1: Exponent Equalization -> In this step, we make the exponent of the smaller number equal to the bigger number exponent and shift its mantissa to the right accordingly.<br>
STEP 2: Mantissa Addition/Subtraction -> In this step, add or subtract the two mantissa's on the basis of their sign bit.<br>
STEP 3: Mantissa Normalization -> In this step, we normalize the mantissa to a value less than 2.<br>
STEP 4: Mantissa rounding according to Round to nearest -> In this step, we round off the mantissa to a 23 bit value as per the round to nearest methodology explained above. <br>

******************************** Special Cases*****************************<br>
We have tried to handle the cases when the number is infinity or zero. 
1. Whenever, the exponent overflows, the number is set to infinity.
2. If, the exponent underflows, the number is set to 0.
3. If, any of the inputs(A,B,C) is infinity, the result is set to infinity.
4. If, either A or B is zero, we make the product zero.
5. If C is 0, the mantissa for C is passed as 0.0000 instead of 1.000000 for addition step.

The design is however not equipped to handle NAN and denormal numbers.

#### Pipelined design
The design has been pipelined as shown in the following figure. The intermediate results are stored in registers to allow for the total propogation delay to be split.
![fig3](https://github.com/user-attachments/assets/93eaff7d-a515-4aaa-b1fc-96e6fa0d6236)

In order, to be able to perform addition with the variable C in a pipelined design, we have stored it into registers for 2 clock cycles.
As of now, we have introduced only two stages of pipeline and not pipelined the nultiplication logic as well. This is done to ensure that in the top module, both int8 MAC module and fp32 MAC module give the output after the same number of clock cycles. 

## Testing and Validation

The folder consists of:
* BlueSpecs files (top_module.bsv, multiplier.bsv and multiplier_exp.bsv)
* Test input files (for corner cases and random test generation : "A.txt", "B.txt", "C.txt", <br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  fp MAC input files : "A_binary1.txt", "B_binary1.txt", "C_binary1.txt", <br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
int MAC input files: "A_binary2.txt", "B_binary2.txt", "C_binary2.txt") 
* test file (top.py) and python reference model for the design (mac_model.py)

### Python Reference Model
The reference model consists of two separate function, int MAC and floating point MAC. In each fuction, the model converts the bits into decimal value and then calculates the MAC output. The output decimal value is then converted back into bits. The floating point MAC model uses built-in functions to convert the bits into bfloat16 value.

In order to perform the verification appropriately, we have split the values given to each input into two separate lists.
1. Directed cases: These consist of infinity,-infinity,0,highest positive number, lowest negative number,-ve value,+value
2. Random cases: These consist of randomly generated values for A,B and C.

Having obtained these testcases for each input, we feed them to the bins to define the coverage. In order to get a full cross coverage, we run for loops to obtain all permutations for (A,B,C,S,enA,enB,enC,enS). This is then written to a file which provides the input to the DUT and the model.
*For faster performance, we have as of now set enB, enC as 1. However, these can also be varied as 0 or 1, if needed. Only it takes the system a lot of time to process.


### TEST FILE
    # s0. INFINITY CASE  
    # FOR C = INFINITY
    cornerA.append(int(0b0100000000000000)); # A = 2
    cornerB.append(int(0b0100000000000000)); # B = 2
    #cornerC.append(int(0b01000000000000000000000000000000))
    cornerC.append(int(0b01111111100000000000000000000000)) # C = INFINITY
    cornerS.append(int(0))
    
    # FOR A = INFINITY
    cornerA.append(int(0b0111111110000000)); # A = INFINITY
    cornerB.append(int(0b0100110000001111)); # B = 
    cornerC.append(int(0b01000001110010101100001010010000)) # C = 25.345001220703125
    cornerS.append(int(0))
    
    
    # 1. OVERFLOW CASE
    cornerA.append(int(0b0111100001111000)); # maximum bfloat16 value, just under infinity
    cornerB.append(int(0b0111100001111000)); # maximum bfloat16 value, just under infinity
    cornerC.append(int(0b01000001110010101100001010010000)) # C = 25.345001220703125
    cornerS.append(int(0))
    
    # 2. UNDERFLOW CASE
    cornerA.append(int(0b0001100111001010)); # A = 2.08863×10−23
    cornerB.append(int(0b0000010111001010)); # B = 2
    cornerC.append(int(0b01000001110010101100001010010000)) # C = 25.345001220703125
    cornerS.append(int(0))
    
    # 5. SIGN HANDLING CASE
    # positive * positive + positive
    cornerA.append(int(0b0100000111001010)); # A = 25.25
    cornerB.append(int(0b0100000000000000)); # B = 2
    cornerC.append(int(0b01000001110010101100001010010000)) # C = 25.345001220703125
    cornerS.append(int(0))
    
    # negative * negative + negative
    cornerA.append(int(0b1100000000010011)); # A = -2
    cornerB.append(int(0b1100000001100000)); # B = 2
    cornerC.append(int(0b11000001110010101100001010010000)) # C = -25.345001220703125
    cornerS.append(int(0))
    
    # positive * negative + positive
    cornerA.append(int(0b0100000011000000)); # A = 25.25
    cornerB.append(int(0b1100100000100000)); # B = -2
    cornerC.append(int(0b01000001110010101100001010010000)) # C = 25.345001220703125
    cornerS.append(int(0))
    
    # positive * positive + negative
    cornerA.append(int(0b0100000000111100)); # A = 25.25
    cornerB.append(int(0b0100001000000000)); # B = 2
    cornerC.append(int(0b11000001110010101100001010010000)) # C = -25.345001220703125
    cornerS.append(int(0))
    
    # 4. ZERO HANDLING CASE
    # 	WHEN A/B = 0
    cornerA.append(int(0b0000000000000000)); # A = 0
    cornerB.append(int(0b0000110111001010)); # B = 2
    cornerC.append(int(0b01000001110010101100001010010000)) # C = 25.345001220703125
    cornerS.append(int(0))
    
    # 	WHEN C = 0
    cornerA.append(int(0b0101100111001010)); # A = 25.25
    cornerB.append(int(0b0010010111001010)); # B = 2
    cornerC.append(int(0b00000000000000000000000000000000)) # C = 0
    cornerS.append(int(0))
    
    # 	WHEN A, B, C = 0
    cornerA.append(int(0b0000000000000000)); # A = 25.25
    cornerB.append(int(0b0000000000000000)); # B = 2
    cornerC.append(int(0b00000000000000000000000000000000)) # C = 0
    cornerS.append(int(0))
### How To Run
#### Pre-Requisites
* The system should have BlueSpec Compiler and python environment with the following libraries:
* Tensorflow
  ```
  pip install tensorflow
  ```
* numpy
  ```
  pip install numpy
  ```
* cocotb and cocotb_converge
  ```
  pip install cocotb==1.6.2
  pip install cocotb_coverage==1.1
  ```

#### Steps to run the code
1. In the terminal, enter the current directory and activate the python environment using the following code:
   ```
   pyenv activate py38
   ```
2. Enter the following commands for verilog generations and simulation of the test file
    ```
    make generate_verilog
    make simulate
    ```
  The command **make simulate** will test the cases in the **top.py** file and generates a **coverage_mac.yml** file. This file will store the coverage results for each input of the model.
  
3. To clean the generated files
   ```
   make clean_build
   ```
   
