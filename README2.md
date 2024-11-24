## Assignment 2
## Testing and Validation
The folder consists of:
* BlueSpecs files (top.bsv, systolic_unit.bsv, top_module.bsv, multiplier.bsv and multiplier_exp.bsv)
* Test input files (for corner cases and random test generation : "A.txt" and "B.txt" <br>
* test file (top.py) and python reference model for the design (mac_model.py)

### Python Reference Model
The python reference model consists of one main function which takes the elements of matrix A and B as inputs and returns the resultant matrix after multiplication. It uses the basic three-loop matrix multiplication logic but, for computation, it uses two separate functions: int MAC and floating point MAC. Both the models convert the bits into decimal value and then calculates the MAC output. The output decimal value is then converted back into bits. The floating point MAC model uses built-in functions to convert the bits into bfloat16 value. 

In order to perform the verification appropriately, we have split the values given to each input into two separate lists.
1. Directed cases: These consist of infinity,-infinity,0,highest positive number, lowest negative number,-ve value,+value
2. Random cases: These consist of randomly generated values for A and B.

Having obtained these testcases for each input, we feed them to the bins to define the coverage. The generated outputs for A and B are  written to separate files which provides the input to the DUT and the model.
### Corner Case Validation
This model covers various corner cases, some of the cases are listed below:

CASE 1. When inputs are infinity
* A or B = +infinity
```
input_A -> 0b0111111110000000	Here, input_A is +infinity 
input_B -> 0b0001100111001010 
input_C -> 0b00011001110010100000000000000001 
OUTPUT  -> 0b01111111100000000000000000000000 ,i.e, +infinity
```

* C = +infinity
```
input_A -> 0b0111111101111111	
input_B -> 0b0001100111001010
input_C -> 0b01111111100000000000000000000000 Here, input_C is +infinity
OUTPUT  -> 0b01111111100000000000000000000000 ,i.e, +infinity
```
The model also takes care of the -infinity inputs. For these cases, the output will be -infinity.
CASE 2. When inputs are zero
* A or B = zero
```
input_A -> 0b0000000000000000	Here, A is zero
input_B -> 0b0001100111001010
input_C -> 0b00011001110010100000000000000001
OUTPUT  -> 0b00011001110010100000000000000001 ,i.e, input_C
```
* C = zero
```
input_A -> 0b0001100111001010	
input_B -> 0b0001100111001010
input_C -> 0b00000000000000000000000000000000 Here, input_C is +infinity
OUTPUT  -> 0b11001101100000000000000000000000 ,i.e, input_A * input_B 
```
* A, B and C = zero
```
input_A -> 0b0000000000000000	
input_B -> 0b0000000000000000
input_C -> 0b00000000000000000000000000000000 
OUTPUT  -> 0b00000000000000000000000000000000
```
### SIGN HANDLING

* Positive * Positive + Positive
```
input_A -> 0b0001100111001010	
input_B -> 0b0001100111001010
input_C -> 0b00011001110010100000000000000001 
```

* Positive * Negative + Positive
```
input_A -> 0b0001100111001010	
input_B -> 0b1100001110000001
input_C -> 0b00011001110010100000000000000001 
```

* Positive * Positive + Negative
```
input_A -> 0b0001100111001010	
input_B -> 0b0001100111001010
input_C -> 0b11000011100000011111100001111101 
```

* Negative * Negative + Negative
```
input_A -> 0b1100001110000001	
input_B -> 0b1100001110000001
input_C -> 0b11000011100000011111100001111101 
```

* Positive * Negative + Negative
```
input_A -> 0b0001100111001010	
input_B -> 0b1100001110000001
input_C -> 0b11000011100000011111100001111101 
```

* Negative * Negative + Positive
```
input_A -> 0b0001100111001010	
input_B -> 0b1100001110000001
input_C -> 0b11000011100000011111100001111101 
```
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
