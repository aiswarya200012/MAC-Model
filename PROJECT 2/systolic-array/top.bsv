package top;
import systolic_unit ::*;
// INTERFACE
interface Ifc_systolic;
	method Action getA(Bit#(16) a1_inp, Bit#(16) a2_inp, Bit#(16) a3_inp, Bit#(16) a4_inp);
	method Action getB(Bit#(16) b1_inp, Bit#(16) b2_inp, Bit#(16) b3_inp, Bit#(16) b4_inp);
	method Action getS(Bit#(1) s1_inp, Bit#(1) s2_inp, Bit#(1) s3_inp, Bit#(1) s4_inp);
	method Action getState(Bit#(1) state);
	method ActionValue#(Bit#(32)) sendout1();
	method ActionValue#(Bit#(32)) sendout2();
	method ActionValue#(Bit#(32)) sendout3();
	method ActionValue#(Bit#(32)) sendout4();
endinterface: Ifc_systolic


//MODULE 
(*synthesize*)
module mkSystolic(Ifc_systolic);
	//register initialising
	Reg#(Bit#(16)) a1 <- mkReg(0);
	Reg#(Bit#(16)) a2 <- mkReg(0);
	Reg#(Bit#(16)) a3 <- mkReg(0);
	Reg#(Bit#(16)) a4 <- mkReg(0);
	Reg#(Bit#(16)) b1 <- mkReg(0);
	Reg#(Bit#(16)) b2 <- mkReg(0);
	Reg#(Bit#(16)) b3 <- mkReg(0);
	Reg#(Bit#(16)) b4 <- mkReg(0);

	Reg#(Bit#(1)) s1 <- mkReg(0);
	Reg#(Bit#(1)) s2 <- mkReg(0);
	Reg#(Bit#(1)) s3 <- mkReg(0);
	Reg#(Bit#(1)) s4 <- mkReg(0);
	
	Reg#(Bool) got_A <- mkReg(False);
	Reg#(Bool) got_B <- mkReg(False);
	Reg#(Bool) got_S <- mkReg(False);
	
	Reg#(Bit#(3)) counter <- mkReg(0);
	Reg#(Bool) validOUT <- mkReg(False);
	Reg#(Bit#(1)) curr_state <- mkReg(0);
	
	Sys_Ifc mac1 <- systolicUnit;
	Sys_Ifc mac2 <- systolicUnit;
	Sys_Ifc mac3 <- systolicUnit;
	Sys_Ifc mac4 <- systolicUnit;
	Sys_Ifc mac5 <- systolicUnit;
	Sys_Ifc mac6 <- systolicUnit;
	Sys_Ifc mac7 <- systolicUnit;
	Sys_Ifc mac8 <- systolicUnit;
	Sys_Ifc mac9 <- systolicUnit;
	Sys_Ifc mac10 <- systolicUnit;
	Sys_Ifc mac11 <- systolicUnit;
	Sys_Ifc mac12 <- systolicUnit;
	Sys_Ifc mac13 <- systolicUnit;
	Sys_Ifc mac14 <- systolicUnit;
	Sys_Ifc mac15 <- systolicUnit;
	Sys_Ifc mac16 <- systolicUnit;
	
	
	//RULE
	rule rl_mult1;
		//ROW 1	
		//mac 1
		mac1.getA(a1);
		if (curr_state  == 1)
			mac1.getB(b1);
		mac1.getC(0);
		mac1.getS(s1);
	endrule: rl_mult1
	
	rule rl_mult2;	
		//mac 2
		Bit#(16) a = mac1.sendout_A();
		mac2.getA(a);
		if (curr_state  == 1)
			mac2.getB(b2);
		mac2.getC(0);
		mac2.getS(s2);
	endrule: rl_mult2
	
	rule rl_mult3;
		//mac 3
		mac3.getA(mac2.sendout_A());
		if (curr_state  == 1)
			mac3.getB(b3);
		mac3.getC(0);
		mac3.getS(s3);
	endrule: rl_mult3
		
	rule rl_mult4;
		//mac 4
		mac4.getA(mac3.sendout_A());
		if (curr_state  == 1)
			mac4.getB(b4);
		mac4.getC(0);
		mac4.getS(s4);
	endrule: rl_mult4
	
		//ROW 2
	rule rl_mult5;
		//mac 5
		mac5.getA(a2);
		if (curr_state  == 1)
			mac5.getB(mac1.sendout_B());
		mac5.getC(mac1.sendout_mac());
		mac5.getS(mac1.sendout_S());
	endrule: rl_mult5
		
	rule rl_mult6;
		//mac 6
		mac6.getA(mac5.sendout_A());
		if (curr_state  == 1)
			mac6.getB(mac2.sendout_B());
		mac6.getC(mac2.sendout_mac());
		mac6.getS(mac2.sendout_S());
	endrule: rl_mult6
	
	rule rl_mult7;
		//mac 7
		mac7.getA(mac6.sendout_A());
		if (curr_state  == 1)
			mac7.getB(mac3.sendout_B());
		mac7.getC(mac3.sendout_mac());
		mac7.getS(mac3.sendout_S());
	endrule: rl_mult7
	
	rule rl_mult8;
		//mac 8
		mac8.getA(mac7.sendout_A());
		if (curr_state  == 1)
			mac8.getB(mac4.sendout_B());
		mac8.getC(mac4.sendout_mac());
		mac8.getS(mac4.sendout_S());
	endrule: rl_mult8
	
		//ROW 3
		//mac 9
	rule rl_mult9;
		mac9.getA(a3);
		if (curr_state  == 1)
			mac9.getB(mac5.sendout_B());
		mac9.getC(mac5.sendout_mac());
		mac9.getS(mac5.sendout_S());
	endrule: rl_mult9
	
		//mac 10
	rule rl_mult10;
		mac10.getA(mac9.sendout_A());
		if (curr_state  == 1)
			mac10.getB(mac6.sendout_B());
		mac10.getC(mac6.sendout_mac());
		mac10.getS(mac6.sendout_S());
	endrule: rl_mult10
		
		//mac 11
	rule rl_mult11;
		mac11.getA(mac10.sendout_A());
		if (curr_state  == 1)
			mac11.getB(mac7.sendout_B());
		mac11.getC(mac7.sendout_mac());
		mac11.getS(mac7.sendout_S());
	endrule: rl_mult11
		//mac 12
	rule rl_mult12;
		mac12.getA(mac11.sendout_A());
		if (curr_state  == 1)
			mac12.getB(mac8.sendout_B());
		mac12.getC(mac8.sendout_mac());
		mac12.getS(mac8.sendout_S());
	endrule: rl_mult12
	
		//ROW 4
		//mac 13
	rule rl_mult13;
		mac13.getA(a4);
		if (curr_state  == 1)
			mac13.getB(mac9.sendout_B());
		mac13.getC(mac9.sendout_mac());
		mac13.getS(mac9.sendout_S());
	endrule: rl_mult13
	
		//mac 14
	rule rl_mult14;
		mac14.getA(mac13.sendout_A());
		if (curr_state  == 1)
			mac14.getB(mac10.sendout_B());
		mac14.getC(mac10.sendout_mac());
		mac14.getS(mac10.sendout_S());
	endrule: rl_mult14
	
		//mac 15
	rule rl_mult15;
		mac15.getA(mac14.sendout_A());
		if (curr_state  == 1)
			mac15.getB(mac11.sendout_B());
		mac15.getC(mac11.sendout_mac());
		mac15.getS(mac11.sendout_S());
	endrule: rl_mult15
	
		//mac 16
	rule rl_mult16;
		mac16.getA(mac15.sendout_A());
		if (curr_state  == 1)
			mac16.getB(mac12.sendout_B());
		mac16.getC(mac12.sendout_mac());
		mac16.getS(mac12.sendout_S());
		
		validOUT <= True;
	endrule : rl_mult16
	//method definitions
	method Action getA(Bit#(16) a1_inp, Bit#(16) a2_inp, Bit#(16) a3_inp, Bit#(16) a4_inp);
		a1 <= a1_inp;
		a2 <= a2_inp;
		a3 <= a3_inp;
		a4 <= a4_inp;
		got_A <= True;
	endmethod
	
	method Action getB(Bit#(16) b1_inp, Bit#(16) b2_inp, Bit#(16) b3_inp, Bit#(16) b4_inp);
		b1 <= b1_inp;
		b2 <= b2_inp;
		b3 <= b3_inp;
		b4 <= b4_inp;
		got_B <= True;
	endmethod
	

	method Action getS(Bit#(1) s1_inp, Bit#(1) s2_inp, Bit#(1) s3_inp, Bit#(1) s4_inp);
		s1 <= s1_inp;
		s2 <= s2_inp;
		s3 <= s3_inp;
		s4 <= s4_inp;
		got_S <= True;
	endmethod
	method Action getState(Bit#(1) state);
		curr_state <= state;
	endmethod
	method ActionValue#(Bit#(32)) sendout1();
		return mac13.sendout_mac();
	endmethod
	
	method ActionValue#(Bit#(32)) sendout2();
		return mac14.sendout_mac();
	endmethod
	
	method ActionValue#(Bit#(32)) sendout3();
		return mac15.sendout_mac();
	endmethod
	
	method ActionValue#(Bit#(32)) sendout4();
		return mac16.sendout_mac();
	endmethod
endmodule : mkSystolic
endpackage: top
