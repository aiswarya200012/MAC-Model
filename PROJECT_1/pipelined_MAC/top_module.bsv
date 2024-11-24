package top_module;

import multiplier_exp   :: *;
import multiplier   :: *;

interface Ifc;
	method Action getA(Bit#(16) a);
	method Action getB(Bit#(16) b);
	method Action getC(Bit#(32) c);
	method Action getS(Bit#(1) s);
	method ActionValue#(Bit#(32)) sendout_mac();
endinterface: Ifc

(*synthesize*)
module topModule (Ifc);
	Reg#(Bit#(16)) a <- mkReg(0);
	Reg#(Bit#(16)) b <- mkReg(0);
	Reg#(Bit#(32)) c <- mkReg(0);
	Reg#(Bit#(1)) s <- mkReg(0);
	Reg#(Bit#(1)) s_temp <- mkReg(0);
	Reg#(Bit#(1)) s_temp1 <- mkReg(0);
	Reg#(Bit#(1)) s_temp2 <- mkReg(0);
	Reg#(Bit#(1)) s_temp3 <- mkReg(0);
	Reg#(Bit#(32)) mac_out <- mkReg(0);
	
	Reg#(Bool) got_A <- mkReg(False);
	Reg#(Bool) got_B <- mkReg(False);
	Reg#(Bool) got_C <- mkReg(False);
	Reg#(Bool) got_S <- mkReg(False);
	Reg#(Bool) validMAC <- mkReg(False);
	Reg#(Bool) validS <- mkReg(False);
	
	Ifc_multiplier mac_fp <- mkMult_exp;
	Multiplier_PL mac_int <- mkMult();	
	
	(* descending_urgency="rl_mux_input, s_storage_s1,s_storage_s2,s_storage_s3" *)
	rule rl_mux_input ;
		s_temp <= s;
		if(s ==1) begin
			mac_int.get_inp(a[7:0],b[7:0],c);
			validS <= True;
		end
		else begin
			mac_fp.get_input(a,b,c);
			validS <= True;
		end
	endrule: rl_mux_input
	
	rule s_storage_s1 ;
		s_temp1 <= s_temp;
		validMAC <= True;
	endrule: s_storage_s1
	
	rule s_storage_s2 ;
		s_temp2 <= s_temp1;
		validMAC <= True;
	endrule: s_storage_s2
	
	rule s_storage_s3 ;
		s_temp3 <= s_temp2;
		validMAC <= True;
	endrule: s_storage_s3
	
	method Action getA(Bit#(16) a_inp) ;
		a        <= a_inp;
		got_A    <= True;
		validMAC <= False;
	endmethod
	
	method Action getB(Bit#(16) b_inp) ;
		b        <= b_inp;
		got_B    <= True;
		validMAC <= False;
	endmethod
	
	method Action getC(Bit#(32) c_inp) ;
		c        <= c_inp;
		got_C    <= True;
		validMAC <= False;
	endmethod
	
	method Action getS(Bit#(1) s_inp) ;
		s        <= s_inp;
		got_S    <= True;
		validMAC <= False;
	endmethod
	
	method ActionValue#(Bit#(32)) sendout_mac();
		got_A <= False;
		got_B <= False;
		got_C <= False;
		got_S <= False;
		validS <= False;
		validMAC <= False;
		
		if(s_temp3 == 1)begin
			let mac_out = mac_int.send_out();
			return mac_out;
		end
		else begin
			let mac_out = mac_fp.send_output();
			return mac_out;
		end
		
	endmethod

endmodule: topModule
endpackage: top_module
