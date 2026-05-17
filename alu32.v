module alu32(sum, a, b, zout, nout, vout, gin);

output reg [31:0] sum;
input [31:0] a, b;
input [2:0] gin;

output reg zout;
output reg nout;
output reg vout;

reg [31:0] less;

always @(a or b or gin)
begin
    vout = 0;

    case(gin)
        3'b010: begin // ADD
            sum = a + b;
            vout = (~a[31] & ~b[31] & sum[31]) |
                   ( a[31] &  b[31] & ~sum[31]);
        end

        3'b110: begin // SUB
            sum = a + 1 + (~b);
            vout = (~a[31] &  b[31] & sum[31]) |
                   ( a[31] & ~b[31] & ~sum[31]);
        end

        3'b111: begin // SLT
            less = a + 1 + (~b);
            if (less[31])
                sum = 32'b1;
            else
                sum = 32'b0;

            vout = 0;
        end

        3'b000: begin // AND
            sum = a & b;
            vout = 0;
        end

        3'b001: begin // OR
            sum = a | b;
            vout = 0;
        end

        default: begin
            sum = 32'bx;
            vout = 1'bx;
        end
    endcase

    zout = ~(|sum);   // Zero flag
    nout = sum[31];   // Negative flag
end

endmodule