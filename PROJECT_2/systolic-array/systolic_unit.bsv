//package systolic_unit;

import top_module   :: *;


//******************************************************************************
//
//				INTERFACE
//
//******************************************************************************
interface Sys_Ifc;
	method Action getA(Bit#(16) a);
	method Action getB(Bit#(16) b);
	method Action getC(Bit#(32) c);
	method Action getS(Bit#(1) s);
	method Bit#(16) sendout_A();
	method Bit#(16) sendout_B();
	method Bit#(1) sendout_S();
	method Bit#(32) sendout_mac();
endinterface: Sys_Ifc

//******************************************************************************
//
//				MODULE DEFINITION
//
//******************************************************************************
(*synthesize*)
module systolicUnit (Sys_Ifc);
	Reg#(Bit#(16)) a       <- mkReg(0);
	Reg#(Bit#(16)) b       <- mkReg(0);
	Reg#(Bit#(32)) c       <- mkReg(0);
	Reg#(Bit#(1)) s        <- mkReg(0);

	Reg#(Bit#(32)) mac_out <- mkReg(0);	
	
	// TEMPORARY REGISTERS TO STORE A TO ALLOW COMPUTATION TO COMPLETE	
	Reg#(Bit#(16)) a_reg1       <- mkReg(0);
	Reg#(Bit#(16)) a_reg2       <- mkReg(0);
	Reg#(Bit#(16)) a_reg3       <- mkReg(0);
	Ifc mac_unit  <- topModule;
		
	//***************************** RULE DEFINITION *********************************
	// rule for instantiating the mac unit
	rule rl_mac_input ;
		mac_unit.getA(a);
		mac_unit.getB(b);
		mac_unit.getC(c);
		mac_unit.getS(s);
		
		a_reg1 <= a;
		a_reg2 <= a_reg1;
		a_reg3 <= a_reg2;			
	endrule: rl_mac_input
	
	
	//***************************** METHOD DEFINITION *********************************
	// for receiving A
	method Action getA(Bit#(16) a_inp) ;
		a        <= a_inp;
	endmethod
	
	// for receiving B
	method Action getB(Bit#(16) b_inp) ;
		b        <= b_inp;
	endmethod
	
	// for receiving C
	method Action getC(Bit#(32) c_inp) ;
		c        <= c_inp;
	endmethod
	
	// for receiving S
	method Action getS(Bit#(1) s_inp) ;
		s        <= s_inp;
	endmethod
	
	
	// to send out A
	method Bit#(16) sendout_A();		
		return a_reg3;
	endmethod
	
	// to send out B
	method Bit#(16) sendout_B();		
		return b;
	endmethod
	
	// to send out S
	method Bit#(1) sendout_S();		
		return s;
	endmethod
	
	// to send the output
	method Bit#(32) sendout_mac();		
		let mac_out = mac_unit.sendout_mac();
		return mac_out;
	endmethod

	
endmodule: systolicUnit
//endpackage: systolic_unit
