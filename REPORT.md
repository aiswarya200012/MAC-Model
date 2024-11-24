# Assignment 1
# MAC-Model

NAME : Priyanka Dangwal EE23M096,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Aiswarya C.S, EE23M064
       
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
2. Now, if GRS = 100 : If 7th bit is 1, increment it, else round down <br>
3. &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;GRS = 0xx : Round down <br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;GRS = 101,110,111: Increment the number by 1. <br>
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

# Assignment 2
# 4*4 Sysolic Array 
The given assignment consists of the construction of a 4*4 systolic array which allows for the multiplication of two 4*4 matrices. The matrices A and B can contain numbers in the following two formats:
1. S1: (A:int8,B:int8,C:int32) -> (MAC:int32)
2. S2: (A:bf16,B:bf16,C:fp32) -> (MAC:fp32)
In order to build up a 4*4 sysolic array using the MAC module designed previously, we follow the given steps:
### Systolic Unit Module
*************************Systolic Unit Module -> systolicUnit ********************************<br>
Step 1: Designing a systolic unit
A sysolic unit in our case consists of a design module with the following methods:
1. getA- Used to register the 16 bit input A
2. getB- Used to register the 16 bit input B
3. getC- Used to register the 32 bit input C
4. getS- Used to register the 1 input S (Select signal)
5. sendout_mac - It is used to register the output, based on the value of S
6. sendout_B - It is used to give out the registered input B after a clock cycle delay.
7. sendout_S - It is used to give out the registered input S after a clock cycle delay.
8. sendout_A - It is used to give out the registered input A after an additional 3 clock cycle delay.

Here, the value of B and S is passed out of the module after a delay of 1 clcok cycle.
MAC computation takes 3 clock cycles in an unpipelined module and hence, both A and MAC which are required to be used concurrently are passed out 3 clock cycles in an unpipelined module and 5 clock cycles later for a pipelined module.

### Top Module
*************************Top Module -> mkSystolic ********************************<br>
Step 2: Connecting the sysolic units in a grid fashion
In this step, the systolic units are connected in a 4*4 grid fashion. This is achieved using the module , which consists of the following methods:
1. getA - Used to register four input values of A being passed horizontally to the leftmost systolic units.
2. getB - Used to register four input values of B being passed vertically to the topmost systolic units.
3. getS - Used to register four input values of S being passed vertically to the topmost systolic units.
4. getStage - Used to register a control signal indicating stage of operation. (To hold B values constant)
5. sendout1 - Gives the entries of the first column as output.
6. sendout2 - Gives the entries of the second column as output.
7. sendout3 - Gives the entries of the third column as output.
8. sendout4 - Gives the entries of the fourth column as output.

Here,the value of B,S and mac is passed vertically downwards while the value of A gets passed horizontally.
The signal getStage is used to distinguish between the stages when B is being provided as input to be stored in the grid and when computation occurs. It helps in the storing of B in the systolic array unit. A counter could have also been used to achieve the desired functionality but it suffers from the drawback of limitation of output correctness based on input timing, thereby reducing the design flexibility..

## Operation and Testing Stages
***********************************Operation***************************************<br>
The computation occurs in the following stages:
1. Firstly, we feed in the value of S and the rows of the matrix B from downwards i.e 4 to 1 via the top level systolic array units.
2. During, this stage, getStage signal was set to 1, which is now further set to 0.
3. Now, we start feeding the matrix A into the design in the manner as specified in the design file. 
4. A delay of 4 clock cycles is deliberately introduced between each new set of A values to maintain concurrency with the MAC movement downwards.
5. Once all the inputs have been provided to the design, the resultant matrix is obtained with the elements coming at the output diagonally. 


   
