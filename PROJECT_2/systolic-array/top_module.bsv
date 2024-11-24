//package top_module;

import multiplier_exp   :: *;
import multiplier   :: *;

//******************************************************************************
//
//				INTERFACE
//
//******************************************************************************
interface Ifc;
	method Action getA(Bit#(16) a);
	method Action getB(Bit#(16) b);
	method Action getC(Bit#(32) c);
	method Action getS(Bit#(1) s);
	method Bit#(32) sendout_mac();
endinterface: Ifc

//******************************************************************************
//
//				TOP MODULE
//
//******************************************************************************

module topModule (Ifc);
	Reg#(Bit#(16)) a       <- mkReg(0);
	Reg#(Bit#(16)) b       <- mkReg(0);
	Reg#(Bit#(32)) c       <- mkReg(0);
	Reg#(Bit#(1)) s        <- mkReg(0);
	Reg#(Bit#(1)) s_temp   <- mkReg(0);
	Reg#(Bit#(1)) s_temp1  <- mkReg(0);
	Reg#(Bit#(32)) mac_out <- mkReg(0);
	
	Reg#(Bool) validMAC    <- mkReg(False);
	Reg#(Bool) validS      <- mkReg(False);
	
	Ifc_multiplier mac_fp  <- mkMult_exp;
	Multiplier_PL mac_int  <- mkMult;	
	
	(* descending_urgency="rl_mux_input, s_storage" *)
	
	//***************************** RULE DEFINITION *********************************
	// rule for getting the output according to S
	rule rl_mux_input ;
		s_temp <= s;
		if(s ==1) begin
			mac_int.get_inp(a[7:0],b[7:0],c);
		end
		else begin
			mac_fp.get_input(a,b,c);
		end
	endrule: rl_mux_input
	
	// rule to store S value
	rule s_storage ;
		s_temp1 <= s_temp;
	endrule: s_storage
	
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
	
	// to send the output
	method Bit#(32) sendout_mac();		
		if(s_temp1 == 1)begin
			let mac_out = mac_int.send_out();
			return mac_out;
		end
		else begin
			let mac_out = mac_fp.send_output();
			return mac_out;
		end
		
	endmethod

endmodule: topModule
//endpackage: top_module
