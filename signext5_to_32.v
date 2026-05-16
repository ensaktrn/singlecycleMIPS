module signext5_to_32(in, out);
input [4:0] in;
output [31:0] out;

assign out = {{27{in[4]}}, in};

endmodule