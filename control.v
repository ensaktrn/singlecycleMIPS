module control(
    in, funct,
    regdest, alusrc, memtoreg,
    regwrite, memread, memwrite,
    branch, aluop1, aluop2,
    lwsgt, swinc
);

input [5:0] in;
input [5:0] funct;

output regdest, alusrc, memtoreg;
output regwrite, memread, memwrite;
output branch, aluop1, aluop2;
output lwsgt, swinc;

wire rformat, lw, sw, beq;

assign rformat = ~|in;

assign lw  =  in[5] & ~in[4] & ~in[3] & ~in[2] &  in[1] &  in[0];
assign sw  =  in[5] & ~in[4] &  in[3] & ~in[2] &  in[1] &  in[0];
assign beq = ~in[5] & ~in[4] & ~in[3] &  in[2] & ~in[1] & ~in[0];

assign lwsgt = rformat & (funct == 6'd21);
assign swinc = (in == 6'd44);

assign regdest  = rformat;
assign alusrc   = lw | sw | swinc;
assign memtoreg = lw ;
assign regwrite = rformat | lw;
assign memread  = lw | lwsgt;
assign memwrite = sw | swinc;
assign branch   = beq;

assign aluop1   = rformat;
assign aluop2   = beq;

endmodule
