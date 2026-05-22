module control(
    in, funct,
    regdst0, regdst1, alusrc, memtoreg0, memtoreg1,
    regwrite, memread, memwrite,
    branch, aluop1, aluop2,
    lwsgt, swinc, balclean, bnem, swn, swor, bnpos
);

input [5:0] in;
input [5:0] funct;

output regdst0, regdst1, alusrc, memtoreg0, memtoreg1;
output regwrite, memread, memwrite;
output branch, aluop1, aluop2;
output lwsgt, swinc, balclean, bnem, swn, swor, bnpos;

wire rformat, lw, sw, beq;

assign rformat = ~|in;

assign lw  =  in[5] & ~in[4] & ~in[3] & ~in[2] &  in[1] &  in[0];
assign sw  =  in[5] & ~in[4] &  in[3] & ~in[2] &  in[1] &  in[0];
assign beq = ~in[5] & ~in[4] & ~in[3] &  in[2] & ~in[1] & ~in[0];

assign lwsgt = rformat & (funct == 6'd21);
assign swinc = (in == 6'd44);
assign balclean =  ~in[5] & in[4] & ~in[3] & ~in[2] & in[1] & in[0];
assign bnem = rformat & (funct == 6'd25);
assign swn = (in == 6'd38);
assign swor = rformat & (funct == 6'd46);
assign bnpos = (in == 6'd24);

assign regdst0 = rformat;
assign regdst1 = balclean;
assign alusrc   = lw | sw | swinc;
assign memtoreg0 = lw;
assign memtoreg1 = balclean;
assign regwrite = (rformat & ~bnem & ~swor) | lw | balclean;
assign memread  = lw | lwsgt | bnem;
assign memwrite = sw | swinc | swor;   //swn eklenecek mi?
assign branch   = beq;
assign aluop1   = rformat;
assign aluop2   = beq;

endmodule
