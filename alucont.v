module alucont(aluop1, aluop0, funct, gout);

input aluop1, aluop0;
input [5:0] funct;
output reg [2:0] gout;

always @(*) begin
    if (~(aluop1 | aluop0))
        gout = 3'b010;      // lw/sw/swinc -> ADD

    else if (aluop0)
        gout = 3'b110;      // beq -> SUB

    else if (aluop1) begin  // R-type
        if (funct == 6'd21)
            gout = 3'b111;  // lwsgt -> SLT

        else if (funct == 6'd32)
            gout = 3'b010;  // add

        else if (funct == 6'd34)
            gout = 3'b110;  // sub

        else if (funct == 6'd36)
            gout = 3'b000;  // and

        else if (funct == 6'd37)
            gout = 3'b001;  // or

        else if (funct == 6'd42)
            gout = 3'b111;  // slt

        else
            gout = 3'b000;
    end
end

endmodule