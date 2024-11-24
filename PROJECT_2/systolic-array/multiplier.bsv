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


function Vector#(8, Bit#(8)) partial_prod(Bit#(8) a, Bit#(8) b);

	Vector#(8, Bit#(8)) partial_product;	
	for (Integer i = 0; i<=7;i=i+1)
		begin
			partial_product[i] = a & signExtend(b[i]);
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

//Generates the sum of the partial products along with c
function Result_arith_32 partial_sum(Bit#(8) a, Bit#(8) b,Bit#(32) c);

	Vector#(8, Bit#(8)) partial_product;
	//Generated Partial Products 
	partial_product = partial_prod(a,b);
	
	
	Bit #(16) temp;	
	Result_arith_16 result_add;
	Result_arith_32 sum1;
	
	//Default value initialization
	result_add.sum = 0;
	result_add.carry = 0;
	
	//Shifting the partial products and carrying out the addition appropriately
	for (Integer i = 0; i<=7;i=i+1)
	begin
		temp = zeroExtend(partial_product[i]);
		result_add = ripple_carry_16_bit(result_add.sum , (temp << i),0);
	end

	//Addition of 1's to account for signed multiplication 
	result_add = ripple_carry_16_bit(result_add.sum,32768,0);
	result_add = ripple_carry_16_bit(result_add.sum,256,0);
	
	//Adding C to the obtained product
	sum1.sum = signExtend(result_add.sum);
	sum1 = ripple_carry_32_bit(sum1.sum,c,0);
	
	return sum1;
endfunction: partial_sum


//(* synthesize *)
// MODULE
module mkMult(Multiplier_PL);
	// REGISTER
	Reg#(Bit#(8)) inp_A <- mkReg(0);
	Reg#(Bit#(8)) inp_B <- mkReg(0);
	Reg#(Bit#(32)) inp_C <- mkReg(0);
	
	
	Reg#(Result_arith_32) result <- mkReg(unpack(0));
	Reg#(Bit#(2)) state <- mkReg(0);
	
	// RULE 1: COMPUTING THE MAC
	rule rl_partial_product;
		result <= partial_sum(inp_A,inp_B, inp_C);
		state <= 2;
	endrule: rl_partial_product


	// METHOD to receive inputs
	method Action get_inp(Bit#(8) a, Bit#(8) b, Bit#(32) c) ;
		inp_A <= a;
		inp_B <= b;
		inp_C <= c;
		state<= 1;
	endmethod
	
	// METHOD to send product
	method Bit#(32) send_out();
			return result.sum;
	endmethod
	
endmodule: mkMult

