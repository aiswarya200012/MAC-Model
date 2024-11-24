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
