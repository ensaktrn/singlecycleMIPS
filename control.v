module control(
    in, funct,
    regdst0, regdst1, alusrc, memtoreg0, memtoreg1,
    regwrite, memread, memwrite,
    branch, aluop1, aluop2,
    lwsgt, swinc, balclean
);

input [5:0] in;
input [5:0] funct;

output regdst0, regdst1, alusrc, memtoreg0, memtoreg1;
output regwrite, memread, memwrite;
output branch, aluop1, aluop2;
output lwsgt, swinc, balclean;

wire rformat, lw, sw, beq;

assign rformat = ~|in;

assign lw  =  in[5] & ~in[4] & ~in[3] & ~in[2] &  in[1] &  in[0];
assign sw  =  in[5] & ~in[4] &  in[3] & ~in[2] &  in[1] &  in[0];
assign beq = ~in[5] & ~in[4] & ~in[3] &  in[2] & ~in[1] & ~in[0];

assign lwsgt = rformat & (funct == 6'd21);
assign swinc = (in == 6'd44);
assign balclean =  ~in[5] & in[4] & ~in[3] & ~in[2] & in[1] & in[0];

assign regdst0 = rformat;
assign regdst1 = balclean;
assign alusrc   = lw | sw | swinc;
assign memtoreg0 = lw;
assign memtoreg1 = balclean;
assign regwrite = rformat | lw | balclean;
assign memread  = lw | lwsgt;
assign memwrite = sw | swinc;
assign branch   = beq;

assign aluop1   = rformat;
assign aluop2   = beq;

endmodule
