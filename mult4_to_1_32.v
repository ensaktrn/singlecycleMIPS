module mult4_to_1_32(out, i0, i1, i2, i3, s0, s1);
output [31:0] out;
input [31:0] i0, i1, i2, i3;
input s0, s1;
wire [31:0] w0, w1;
mult2_to_1_32 m0(w0, i0, i1, s0);
mult2_to_1_32 m1(w1, i2, i3, s0);
mult2_to_1_32 m2(out, w0, w1, s1);
endmodule