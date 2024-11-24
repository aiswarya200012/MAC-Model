import Vector::*;

typedef struct {Bit#(16) sum; Bit#(1) carry;}Result_arith_16 deriving (Bits,Eq);
typedef struct {Bit#(32) sum; Bit#(1) carry;}Result_arith_32 deriving (Bits,Eq);

interface Multiplier_PL;
  method Action get_inp(Bit#(8) a, Bit#(8) b,Bit#(32) c);
  method Bit#(32) send_out();
endinterface: Multiplier_PL


// 16 BIT RIPPLE CARRY ADDER
function Result_arith_16 ripple_carry_16_bit(Bit#(16) a, Bit#(16) b, Bit#(1) cin);
	Bit#(16) sum = 0;
	Bit#(17) cout = 0;

	cout[0] = cin;
	
	for(Integer i = 0; i<16;i=i+1)
	begin
		sum[i] = (a[i] ^ b[i] ^ cout[i]);
		cout[i+1] = ((a[i] & b[i])|(b[i] & cout[i])|(cout[i] & a[i]));
	end
	
	Result_arith_16 result;
	result.sum = sum;
	result.carry = cout[16];
	
	return result;
endfunction: ripple_carry_16_bit

// 32 BIT RIPPLE CARRY ADDER
function Result_arith_32 ripple_carry_32_bit(Bit#(32) a, Bit#(32) b, Bit#(1) cin);
	Result_arith_16 sum1,sum2;
	Result_arith_32 sum_32;
	
	sum1 = ripple_carry_16_bit(a[15:0],b[15:0],cin);
	sum2 = ripple_carry_16_bit(a[31:16],b[31:16],sum1.carry);
	
	sum_32.sum[15:0] = sum1.sum;
	sum_32.sum[31:16] = sum2.sum;
	sum_32.carry = sum2.carry;
	
	return sum_32;
endfunction: ripple_carry_32_bit

//Function for generating the partial products
function Vector#(8, Bit#(8)) partial_prod(Bit#(8) a, Bit#(8) b);

	Vector#(8, Bit#(8)) partial_product;	
	for (Integer i = 0; i<=7;i=i+1)
		begin
			partial_product[i] = a & signExtend(b[i]);
			//Case if we take AND of the MSB of any of the numbers with a non sign bit
			if(i!=7)
			begin
				
				partial_product[i][7] = ~partial_product[i][7];
			end
			else
			begin
				for(Integer j = 0; j<=6;j=j+1)
				begin
				partial_product[i][j] = ~partial_product[i][j];
				end
			end
		end
	
	return partial_product;
	
endfunction: partial_prod

//Function generates the sum of the partial products, (4 at a time)
function Result_arith_16 partial_sum(Vector#(4, Bit#(8)) partial_product,Integer level);
	
	Bit #(16) temp;	
	Result_arith_16 result_add;
	
	//Default value initialization
	result_add.sum = 0;
	result_add.carry = 0;
	
	//Shifting the partial products and carrying out the addition appropriately
	for (Integer i = 0; i<=3;i=i+1)
	begin
		temp = zeroExtend(partial_product[i]);
		result_add = ripple_carry_16_bit(result_add.sum , (temp << (i+level*4)),0);
	end
	
	return result_add;
endfunction: partial_sum

//Function to add the sum of the two sections of the partial products and C, Also the additional bits needed for signed multiplication
function Result_arith_32 summation(Bit#(16) result1,Bit#(16) result2,Bit#(32) c);

	Result_arith_16 result_add;
	Result_arith_32 result;
	
	//Addition of the two summed up partial products
	result_add = ripple_carry_16_bit(result1,result2,0);
	
	//Addition of 1's to account for signed multiplication 
	result_add = ripple_carry_16_bit(result_add.sum,32768,0);
	result_add = ripple_carry_16_bit(result_add.sum,256,0);
	
	//Adding C to the obtained product
	result.sum = signExtend(result_add.sum);
	result = ripple_carry_32_bit(result.sum,c,0);
	
	return result;
endfunction: summation

//(* synthesize *)
// MODULE
module mkMult(Multiplier_PL);
	// REGISTER
	Reg#(Bit#(8)) inp_A <- mkReg(0);
	Reg#(Bit#(8)) inp_B <- mkReg(0);
	Reg#(Bit#(32)) inp_C <- mkReg(0);
	
	Reg#(Bit#(32)) c_out1 <- mkReg(0); 
	Reg#(Bit#(32)) c_out2 <- mkReg(0); 
	Reg#(Bit#(32)) c_out3 <- mkReg(0); 
	
	Reg#(Result_arith_32) result <- mkReg(unpack(0));
	
	Reg#(Result_arith_16) result1 <- mkReg(unpack(0));
	Reg#(Result_arith_16) result2 <- mkReg(unpack(0));
	
	Reg#(Vector#(8, Bit#(8))) partial_product <- mkReg(replicate(0));
	Reg#(Vector#(4, Bit#(8))) partial_product1 <- mkReg(replicate(0));
	
	// RULE 1: GENERATING THE PARTIAL PRODUCTS
	rule rl_partial_product;
		partial_product<= partial_prod(inp_A,inp_B);
		c_out1 <= inp_C;	// C gets stored to account for the delay in the processing of A and B multiplication
	endrule: rl_partial_product

	// RULE 2: STAGE 1 OPERATIONS
	rule rl_product_sum1;
		result1 <= partial_sum(unpack({partial_product[3],partial_product[2],partial_product[1],partial_product[0]}),0);
		result2 <= partial_sum(unpack({partial_product[7],partial_product[6],partial_product[5],partial_product[4]}),1);
		c_out2 <= c_out1;
	endrule: rl_product_sum1

	//RULE 3: STAGE 2 OPERATIONS
	rule rl_product_sum2;
		result <= summation(result1.sum,result2.sum,c_out2);
	endrule: rl_product_sum2
	

	// METHOD to receive inputs
	method Action get_inp(Bit#(8) a, Bit#(8) b, Bit#(32) c);
		inp_A <= a;
		inp_B <= b;
		inp_C <= c;

	endmethod
	
	// METHOD to send product
	method Bit#(32) send_out() ;
		return result.sum;
	endmethod
	
endmodule: mkMult

