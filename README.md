# MAC-Model
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
   
