//******************************************************************************
//
//				STRUCT DEFINITIONS
//
//******************************************************************************
// for storing 8 bit addition result
typedef struct { Bit#(8) sum; 
		 Bit#(1) carry;
	       } Result_arith_8 deriving (Bits,Eq);
	       
// for storing 16 bit addition result	 
typedef struct { Bit#(16) sum; 
		 Bit#(1) carry;
	       } Result_arith_16 deriving (Bits,Eq);
	       
// for storing 32 bit addition result	       
typedef struct { Bit#(32) sum; 
		 Bit#(1) carry;
	       } Result_arith_32 deriving (Bits,Eq);

// for storing IEEE 754 number
typedef struct {
		Bit #(1) sign_val;
		Bit #(23) mantissa_val;
		Bit #(8) exponent_val;
	       }Result deriving (Bits,Eq);

// for storing IEEE 754 special case numbers	
typedef struct {
		Bit #(1) sign_val;
		Bit #(23) mantissa_val;
		Bit #(8) exponent_val;
		Bit #(1) exist;
	       } Result_exist deriving (Bits,Eq);

//******************************************************************************
//
//				INTERFACE
//
//******************************************************************************	
interface Ifc_multiplier;
	method Action get_input(Bit#(16) a, Bit#(16) b, Bit#(32) c);
	method Bit#(32) send_output();
endinterface



//******************************************************************************
//
//			       FUNCTIONS
//
//******************************************************************************
// 8 BIT RIPPLE CARRY ADDER
function Result_arith_8 ripple_carry_8_bit(Bit#(8) a, Bit#(8) b, Bit#(1) cin);
	Bit#(8) sum  = 0;
	Bit#(9) cout = 0;

	cout[0]      = cin;
	
	// Realizing addition functionality by means of XOR and AND gates
	for(Integer i = 0; i < 8;i = i+1)
	begin
		sum[i]    = (a[i] ^ b[i] ^ cout[i]);
		cout[i+1] = ((a[i] & b[i])|(b[i] & cout[i])|(cout[i] & a[i]));
	end
	
	Result_arith_8 result;
	result.sum   	  = sum;
	result.carry      = cout[8];
	
	return result;
endfunction: ripple_carry_8_bit



// 16 BIT RIPPLE CARRY ADDER
function Result_arith_16 ripple_carry_16_bit(Bit#(16) a, Bit#(16) b, Bit#(1) cin);
	Result_arith_8 sum1,sum2;
	Result_arith_16 result;
	
	sum1 = ripple_carry_8_bit(a[7:0],b[7:0],cin); // Finding the sum of lower 8 bits
	sum2 = ripple_carry_8_bit(a[15:8],b[15:8],sum1.carry); // Finding the sum of msb 8 bits
	
	result.sum[7:0]  = sum1.sum;
	result.sum[15:8] = sum2.sum;
	result.carry     = sum2.carry;
	
	return result;
endfunction: ripple_carry_16_bit




// 32 BIT RIPPLE CARRY ADDER
function Result_arith_32 ripple_carry_32_bit(Bit#(32) a, Bit#(32) b, Bit#(1) cin);
	Result_arith_16 sum1,sum2;
	Result_arith_32 sum_32;
	
	sum1 = ripple_carry_16_bit(a[15:0],b[15:0],cin);
	sum2 = ripple_carry_16_bit(a[31:16],b[31:16],sum1.carry);
	
	sum_32.sum[15:0]  = sum1.sum;
	sum_32.sum[31:16] = sum2.sum;
	sum_32.carry      = sum2.carry;
	
	return sum_32;
endfunction: ripple_carry_32_bit



//A Function for carrying out ieee 754 numbers addition 
function Result exponent_add(Bit#(24) inp_mantissaA, Bit#(24) inp_mantissaB, Bit#(8) inp_exponenta,Bit#(8) inp_exponentb, Bit#(1) inp_signa, Bit#(1) inp_signb);
	
	Bit#(32) mantissaG;
	Bit#(32) mantissaS;
	Bit#(8) exponentG;
	Bit#(8) exponentS;
	Bit#(1) signG;
	Bit#(1) signS;
	
	//Variables for temporary storing the mantissa during different stages of computation
	Bit#(33) mantissa1;
	Bit#(32) mantissa;
	Bit#(23) mantissa_temp;
	Bit#(8) exponent_temp;
	Bit#(1) sign_temp;
	Bit #(9) shift_count = 0; // Limit shifts and ensures loop termination
	
	Result_arith_32 addition_result;
	Result_arith_8 temp_addition_result;
	//Final output
	Result out;

	// Finding the greater number from A and B and assigning the appropriate variables
	if (inp_exponenta > inp_exponentb) 
	begin
		mantissaG = {inp_mantissaA, 8'b0};
		mantissaS = {inp_mantissaB, 8'b0};
		exponentG = inp_exponenta;
		exponentS = inp_exponentb;
		signG	  = inp_signa;
		signS	  = inp_signb;
	end
	else if (inp_exponenta < inp_exponentb)
	begin
		mantissaG = {inp_mantissaB, 8'b0};
		mantissaS = {inp_mantissaA, 8'b0};
		exponentG = inp_exponentb;
		exponentS = inp_exponenta;
		signG	  = inp_signb;
		signS	  = inp_signa;
	end
	else
	begin
		if(inp_mantissaB > inp_mantissaA)
		begin
			mantissaG = {inp_mantissaB, 8'b0};
			mantissaS = {inp_mantissaA, 8'b0};
			exponentG = inp_exponentb;
			exponentS = inp_exponenta;
			signG	  = inp_signb;
			signS	  = inp_signa;
		end
		else
		begin
			mantissaG = {inp_mantissaA, 8'b0};
			mantissaS = {inp_mantissaB, 8'b0};
			exponentG = inp_exponenta;
			exponentS = inp_exponentb;
			signG	  = inp_signa;
			signS	  = inp_signb;
		end		
	end
	
	//Converting the exponents to same power as the higher exponent
	while(exponentG != exponentS && shift_count <= 255)
	begin
		temp_addition_result = ripple_carry_8_bit(exponentS,8'b1,0);
		exponentS            = temp_addition_result.sum;
		mantissaS            = mantissaS >> 1;
		shift_count          = shift_count + 1;
	end

	// The resultant exponent becomes the higher exponent
	exponent_temp = exponentG;
	
	// Comparing the signs for addition/subtraction of mantissa
	if (signG == 0 && signS == 0) 
	begin
		addition_result  = ripple_carry_32_bit(mantissaS , mantissaG,0);
		mantissa1        = {addition_result.carry,addition_result.sum};
		sign_temp        = 1'b0;
	end
	else if (signG == 1 && signS == 1)
	begin
		addition_result  = ripple_carry_32_bit(mantissaS , mantissaG,0);
		mantissa1        = {addition_result.carry,addition_result.sum};
		sign_temp        = 1'b1;
	end
	else if (signG == 0 && signS == 1)
	begin
		if(mantissaG > mantissaS)
		begin
			mantissaG = {0,mantissaG>>1};
			mantissaS = {0,mantissaS>>1};
			addition_result  = ripple_carry_32_bit(mantissaG,~mantissaS,1);
			addition_result.sum = addition_result.sum <<1;
		end
		else
		begin
			mantissaG = {0,mantissaG>>1};
			mantissaS = {0,mantissaS>>1};
			addition_result  = ripple_carry_32_bit(~mantissaG,mantissaS,1);
			addition_result.sum = addition_result.sum <<1;
		end
		mantissa1        = {0,addition_result.sum};
		sign_temp        = 1'b0;
	end
	else 
	begin
		if(mantissaG > mantissaS)
		begin
			mantissaG = {0,mantissaG>>1};
			mantissaS = {0,mantissaS>>1};
			addition_result  = ripple_carry_32_bit(mantissaG,~mantissaS,1);
			addition_result.sum = addition_result.sum <<1;
		end
		else
		begin
			mantissaG = {0,mantissaG>>1};
			mantissaS = {0,mantissaS>>1};
			addition_result  = ripple_carry_32_bit(~mantissaG,mantissaS,1);
			addition_result.sum = addition_result.sum <<1;
		end
		mantissa1        = {0,addition_result.sum};
		sign_temp        = 1'b1;
	end

	/************Performing mantissa normalization***************/	
	 	
    	if(mantissa1[32] == 1) // Numbers of the form 1x.xxxxxxxxxx
    	begin
    		mantissa             = mantissa1[32:1];
		temp_addition_result = ripple_carry_8_bit(exponent_temp,8'b1,0); //incrementing the exponent by 1
		exponent_temp        = temp_addition_result.sum;
		//checking for exponent overflow
		if(temp_addition_result.carry == 1)
		begin
			exponent_temp = 8'b11111111; //setting the number to +infinity or -infinity
			mantissa      = 32'b0;
		end	
    	end
    	else
    	begin
    		mantissa    = mantissa1[31:0];
    		shift_count = 0;
		while(mantissa[31] == 0 &&  shift_count<=255)
		begin
			mantissa             = mantissa << 1;
			temp_addition_result = ripple_carry_8_bit(exponent_temp,8'b11111110,1); //decrementing the exponent by 1
			exponent_temp        = temp_addition_result.sum;
			shift_count          = shift_count + 1;
		end
		
	
	end
	
	//Temporarily fixing the exponent	
	out.exponent_val = exponent_temp;
	//checking if the exponent has reached 255, then setting the number to infinity
	if(exponent_temp == 255)
	begin
		mantissa = 32'b0;
	end
	
	/************Performing round to nearest zero***************/
	
	// Logic for performing rounding off 
	Bit#(2) gr = mantissa[7:6];
	Bit#(1) s  = mantissa[5] | mantissa[4] | mantissa[3] | mantissa[2] | mantissa[1] | mantissa[0];
	
	mantissa_temp = mantissa[30:8];
	
	//Case 1: GRS = 100, next bit == 1 round off, else round down
	if (gr[0]==0 && s==0 && gr[1] == 1)
	begin
		if (mantissa[8] == 0)
		begin
			mantissa_temp   = mantissa_temp;
		end
		else if (mantissa[8] == 1)
		begin
			addition_result = ripple_carry_32_bit(zeroExtend(mantissa_temp),32'b1,0);
			mantissa_temp   = addition_result.sum[22:0];
			if(addition_result.sum[23] == 1) // mantissa overflows
			begin
				temp_addition_result = ripple_carry_8_bit(out.exponent_val,8'b1,0);//incrementing the exponent 
				out.exponent_val     = temp_addition_result.sum;
				if(temp_addition_result.carry == 1) //exponent overflows
				begin
					out.exponent_val = 8'b11111111; //setting the number to +infinity or -infinity
					mantissa_temp    = 23'b0;	
				end
			end
		end
	end
	// if GRS = 0XX, round down
	else if (gr[1] == 0) 
	begin
		mantissa_temp = mantissa_temp;
	end
	// if GRS = 101, 110, 111, round off
	else 
	begin
		addition_result = ripple_carry_32_bit(zeroExtend(mantissa_temp),32'b1,0);
		mantissa_temp   = addition_result.sum[22:0];
		if(addition_result.sum[23] == 1) // mantissa overflows
		begin
			temp_addition_result = ripple_carry_8_bit(out.exponent_val,8'b1,0); //incrementing the exponent by 1
			out.exponent_val     = temp_addition_result.sum;
			if(temp_addition_result.carry == 1) //exponent overflows
			begin
				out.exponent_val = 8'b11111111; //setting the number to +infinity or -infinity
				mantissa_temp    = 23'b0;	
			end
		end
	end
	
	// Assigning the output value
	out.sign_val 	 = sign_temp;
	out.mantissa_val = mantissa_temp;
	
	
	return out;
	
endfunction: exponent_add

function Result exponent_cal(Bit#(8) mantissaB, Bit#(16) d, Bit#(24) mantissaC, Bit#(8) inp_exponenta,Bit#(8) inp_exponentb,Bit#(8) inp_exponentc, Bit#(1) signA, Bit#(1) signB, Bit#(1) signC);

	Bit#(16) product = 0;
	
	Result_arith_16 temp    = unpack(0);
	Result_arith_8 add_temp = unpack(0);	
	Bit #(8) shift_count    = 0;
	
	Bit#(16) a,b;
	//GENERATE a and b values
	a = {signA,inp_exponenta,d[6:0]};
	b = {signB,inp_exponentb,mantissaB[6:0]};
	
	Bit#(24) product_0=0;
	Bit#(9) result_exp;
	Result mac_out;
	Result out = unpack(0);
	Result_exist value_out = unpack(0);
	Bit#(8) inp_exponent   = 0;

	// CHECKING CORNER CASE IF ANY OF THE NUMBERS IS INFINITY
	value_out = special_case_inf(a, b, {signC,inp_exponentc,mantissaC[22:0]});
	
	//Adding up the input exponents of A and B
	Result_arith_8 result_temp = ripple_carry_8_bit(inp_exponenta, inp_exponentb,0); 
	result_exp                 = {result_temp.carry,result_temp.sum};

	//Checking if the result underflows
	if((result_exp <= 9'd127) && (value_out.exist == 0))
	begin
		//setting one of the numbers to zero such that product of A*B = 0, signifying underflow
		b[14:0] = 15'b0;			
	end
	else
	begin
		//Subtraction of 127 from the exponent addition result
		Result_arith_16 result_temp1;
		result_temp1 = ripple_carry_16_bit(zeroExtend(result_exp),signExtend(8'b10000000),1);
		
		inp_exponent = result_temp1.sum[7:0];
		
		//Setting the resultant number to infinity(+or-) if there is exponent overflow
		if(result_temp1.sum > 254 && value_out.exist == 0)
		begin
			value_out.exist        = 1;
			value_out.mantissa_val = 23'b0;
			value_out.exponent_val = 8'b11111111;
			value_out.sign_val     = signA^signB;
		end
	end

        // If true-> result is predetermined to be either +infinity or -infinity
	if(value_out.exist == 1)
	begin
		mac_out.mantissa_val = value_out.mantissa_val;
		mac_out.exponent_val = value_out.exponent_val;
		mac_out.sign_val     = value_out.sign_val;
		return mac_out;
	end
	else
	begin
				
		// CORNER CASE: if a or b is 0, result = 0
		if (a[14:0] == 15'b0 || b[14:0] == 15'b0)
		begin
			out.mantissa_val = 23'b0;
			out.exponent_val = 8'b0;
			out.sign_val     = a[15] ^ b[15];
			product_0        = {0,23'b0};	
		end
    		else
    		begin	
		// mantissa multiplication
		while(mantissaB != 0) 
		begin
			if (mantissaB[0] == 1) 
			begin
				temp    = ripple_carry_16_bit(product , d, 0);
				product = temp.sum;
			end
			d         = d << 1'b1; //Shifting the multiplicand to the right
			mantissaB = mantissaB >> 1'b1; // Shifting the multiplier to the left
		end
	
		/************Performing mantissa normalization***************/	
		if(product[15] == 1'b1)  // mantissa = 1x.xxxx
		begin
			out.mantissa_val = {product[14:0],8'd0};
			add_temp         = ripple_carry_8_bit(inp_exponent,8'b1,0);
			out.exponent_val = add_temp.sum;
			if(add_temp.carry == 1'b1) //signfies overflow condition, round off the result to infinity
			begin
				out.exponent_val = 8'b11111111;
				out.mantissa_val = 23'b0;
			end		
		end
		else if (product[14] == 1)  // mantissa = x1.xxxx
		begin
			out.exponent_val = inp_exponent;
			out.mantissa_val = {product[13:0],9'd0};
		end
		else 
		begin
			// Limit shifts and ensure termination
    			while(product[14] == 0 &&  shift_count<16)
			begin
				product      = product << 1;
				add_temp     = ripple_carry_8_bit(inp_exponent,8'b11111110,1); //decrementing the exponent by 1
				inp_exponent = add_temp.sum;
				shift_count  = shift_count + 1;
			end
		
			out.mantissa_val = {product[13:0],9'd0};
			out.exponent_val = inp_exponent;
		end
	
	
		/************Performing round to nearest zero***************/
		// As of now mantissa value is 23 bits. will change it first to 8 bit value - perform rounding operation and then pad zeroes and send out.
	
		// Logic for performing rounding off 
		Bit#(2) gr = out.mantissa_val[15:14];
		Bit#(1) s  = 0;
		
		for (Integer i = 0; i<=13;i=i+1)
		begin
			s = s | out.mantissa_val[i];
		end

		Bit#(7) mantissa_temp = out.mantissa_val[22:16];
	
		// if GRS = 100, next bit == 1 round off, else round down
		if (gr[0]==0 && s==0 && gr[1] == 1)
		begin
			if (out.mantissa_val[16] == 0)
			begin
				mantissa_temp = mantissa_temp;
			end
			else if (out.mantissa_val[16] == 1)
			begin
				add_temp      = ripple_carry_8_bit(zeroExtend(mantissa_temp),8'b1,0);
				mantissa_temp = add_temp.sum[6:0];
				if(add_temp.sum[7] == 1) // mantissa overflows
				begin
					add_temp         = ripple_carry_8_bit(out.exponent_val,8'b1,0);//incrementing the exponent 
					out.exponent_val = add_temp.sum;
					if(add_temp.carry == 1) //exponent overflows
					begin
						out.exponent_val = 8'b11111111; //setting the number to +infinity or -infinity
						mantissa_temp    = 7'b0;	
					end
				end
			end
		end
		// if GRS = 0XX, round down
		else if (gr[1] == 0) 
		begin
			mantissa_temp = mantissa_temp;
		end
		// if GRS = 101, 110, 111, round off
		else 
		begin
			add_temp      = ripple_carry_8_bit(zeroExtend(mantissa_temp),8'b1,0);
			mantissa_temp = add_temp.sum[6:0];
			if(add_temp.sum[7] == 1) // mantissa overflows
			begin
				add_temp         = ripple_carry_8_bit(out.exponent_val,8'b1,0);//incrementing the exponent 
				out.exponent_val = add_temp.sum;
				if(add_temp.carry == 1) //exponent overflows
				begin
					out.exponent_val = 8'b11111111; //setting the number to +infinity or -infinity
					mantissa_temp    = 7'b0;	
				end
			end
		end 
	
		out.mantissa_val = {mantissa_temp,16'b0};	
		out.sign_val     = signA^signB;
		product_0        = {1'b1, out.mantissa_val};
    	
    		end
    	
    		//CHECK IF C=0, SET THE MANTISSA OF C as 0
    		if(mantissaC[22:0] == 0 && inp_exponentc == 0)
    		begin
    			mantissaC[23] = 0;
    		end
    		mac_out = exponent_add(product_0,mantissaC,out.exponent_val,inp_exponentc,out.sign_val,signC);

		return mac_out;
	end

endfunction: exponent_cal

// for special cases
function Result_exist special_case_inf(Bit#(16) a, Bit#(16) b, Bit#(32) c);

	Result_exist out;
	out.mantissa_val = 0;
	out.exponent_val = 0;
	out.sign_val     = 0;
	out.exist        = 0;
	
	// CASE 1: if a or b or c = +infinity or -infinity, result = infinity 
	if (a[14:0] == 15'b111111110000000 || b[14:0] == 15'b111111110000000)
	begin
		out.mantissa_val = 23'b0;
		out.exponent_val = 8'b11111111;
		out.sign_val     = a[15] ^ b[15];
		out.exist        = 1'b1;		
	end
	
	// CASE 2: if c = infinity , result = infinity
	if (out.exist != 1)
	begin
		if(c[30:0] == 31'b1111111100000000000000000000000)
		begin
			out.mantissa_val = 23'b0;
			out.exponent_val = 8'b11111111;
			out.sign_val     = c[31];
			out.exist        = 1'b1;
		end
			
	end
	
	return out;
	
endfunction: special_case_inf

//******************************************************************************
//
//				   MODULE
//
//******************************************************************************
	
//(* synthesize *)
// MODULE
module mkMult_exp(Ifc_multiplier);

	// REGISTERS
	Reg#(Bit#(16)) d         <- mkReg(0);
	
	//REGISTERS FOR STORING THE MANTISSA
	Reg#(Bit#(8)) mantissaA  <- mkReg(0);
	Reg#(Bit#(8)) mantissaB  <- mkReg(0);
	Reg#(Bit#(24)) mantissaC <- mkReg(0);

	//REGISTERS FOR STORING THE EXPONENT
	Reg#(Bit#(8)) exponentA  <- mkReg(0);
	Reg#(Bit#(8)) exponentB  <- mkReg(0);
	Reg#(Bit#(8)) exponentC  <- mkReg(0);
	
	//REGISTERS FOR STORING THE SIGN 
	Reg#(Bit#(1)) signA      <- mkReg(0);
	Reg#(Bit#(1)) signB      <- mkReg(0);
	Reg#(Bit#(1)) signC      <- mkReg(0);
		

	//REGISTERS FOR STORING THE RESULT
	Reg#(Result) value       <- mkReg(unpack(0));
	
	
	// RULE for computing the product
	rule rl_compute;
		value <= exponent_cal(mantissaB,d,mantissaC,exponentA,exponentB,exponentC,signA,signB,signC);
	endrule: rl_compute
	
	// METHOD to receive inputs
	method Action get_input(Bit#(16) a, Bit#(16) b, Bit#(32) c);
		mantissaA <= {1,a[6:0]};
		mantissaB <= {1,b[6:0]};
		exponentA <= a[14:7];
		exponentB <= b[14:7];
		mantissaC <= {1,c[22:0]};
		exponentC <= c[30:23];
		signA     <= a[15];
		signB     <= b[15];
		signC     <= c[31];
		d         <= {8'b0,1,a[6:0]};
	endmethod
	
	// METHOD to send product
	method Bit#(32) send_output();
		return {value.sign_val, value.exponent_val, value.mantissa_val};
	endmethod
	
	
endmodule: mkMult_exp
