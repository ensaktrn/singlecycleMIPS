module processor;
reg [31:0] pc; //32-bit prograom counter
reg clk; //clock
reg [7:0] datmem[0:63], mem[0:63]; //32-size data and instruction memory (8 bit(1 byte) for each location)
wire [31:0] 
dataa,	//Read data 1 output of Register File
datab,  //Read data 2 output of Register File
datac,	//Read data 3 output of Register File
out2,		//Output of mux with ALUSrc control-mult2
out3,		//Output of mux with MemToReg control-mult3
out4,		//Output of mux with (Branch&ALUZero) control-mult4
sum,		//ALU result
extad,	//Output of sign-extend unit
adder1out,	//Output of adder which adds PC and 4-add1
adder2out,	//Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
sextad;	//Output of shift left 2 unit

// benim eklediklerim -enes
wire [31:0] alu_in_a, shamt_ext,lwsgt_addr,mem_addr,reg_write_data,swinc_data,swinc_plus1; 
wire nout, vout;
wire status_z, status_n, status_v;
wire pc_s0, pc_s1;
wire lwsgt_gt;
wire [31:0] lwsgt_write_data;
reg status_z_reg, status_n_reg, status_v_reg;
assign status_z = status_z_reg;
assign status_n = status_n_reg;
assign status_v = status_v_reg;

wire clean_flags;
wire balclean_taken;
wire [31:0] jump_target;
wire [31:0] pc_next;

// swn icin
wire swn_write;
wire final_memwrite;

//bnem icin
wire [31:0] not_dpack, bnem_temp, bnem_diff;
wire bnem_not_equal, bnem_taken;

wire [5:0] inst31_26;	//31-26 bits of instruction
wire [4:0] 
inst25_21,	//25-21 bits of instruction
inst20_16,	//20-16 bits of instruction
inst15_11,	//15-11 bits of instruction
out1;		//Write data input of Register File

wire [15:0] inst15_0;	//15-0 bits of instruction

wire [31:0] instruc,	//current instruction
dpack;	//Read data output of memory (data read from memory)

wire [2:0] gout;	//Output of ALU control unit
wire [4:0] old_out1;    //Output of first mux for write register selection, used as input for second mux which selects between old_out1 and $ra (5'b11111) based on balclean signal

wire zout,	//Zero output of ALU
pcsrc;	//Output of AND gate with Branch and ZeroOut inputs
//Control signals
wire regdst0,regdst1,alusrc,memtoreg0,memtoreg1,regwrite,memread,memwrite,branch,aluop1,aluop0,lwsgt,swinc,balclean, bnem, swn, swor, bnpos;
wire memaddr_s0; // control signals for memaddr mux
assign memaddr_s0 = lwsgt | bnem; 
//32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];

integer i;

assign jump_target =
    {adder1out[31:28], instruc[25:0], 2'b00}; //jump instruction (addr>>2 + PC+4)

assign clean_flags = (~status_z) & (~status_n) & (~status_v); //clean and gate
assign balclean_taken = balclean & clean_flags; // balclean signal ve clean and gate
assign bnpos_taken = bnpos & (status_z | status_n);

assign pc_s0 = pcsrc | balclean_taken | bnpos_taken; // inputs of branch mux
assign pc_s1 = balclean_taken| bnem_taken | bnpos_taken; // inputs of branch mux

// memwrite ile swn sinyali birlestiildi
assign swn_write = swn & status_n;
assign final_memwrite = memwrite | swn_write;

// datamemory connections
always @(posedge clk)
//write data to memory
if (final_memwrite)
begin 
//sum stores address,datab stores the value to be written
datmem[mem_addr[4:0]+3]=swinc_data[7:0];
datmem[mem_addr[4:0]+2]=swinc_data[15:8];
datmem[mem_addr[4:0]+1]=swinc_data[23:16];
datmem[mem_addr[4:0]]=swinc_data[31:24];
end

//instruction memory
//4-byte instruction
 assign instruc = {
    mem[pc[5:0]],
    mem[pc[5:0]+1],
    mem[pc[5:0]+2],
    mem[pc[5:0]+3]
};
 assign inst31_26=instruc[31:26];
 assign inst25_21=instruc[25:21];
 assign inst20_16=instruc[20:16];
 assign inst15_11=instruc[15:11];
 assign inst15_0=instruc[15:0];


// registers

assign dataa=registerfile[inst25_21];//Read register 1
assign datab=registerfile[inst20_16];//Read register 2
assign datac = registerfile[inst15_11]; // Read register 3
always @(posedge clk)
 registerfile[out1] = regwrite ? reg_write_data : registerfile[out1];//Write data to register

always @(posedge clk) // status register update
begin
    status_z_reg = zout;
    status_n_reg = nout;
    status_v_reg = vout;
end

//read data from memory, sum stores address
assign dpack={datmem[mem_addr[5:0]],datmem[mem_addr[5:0]+1],datmem[mem_addr[5:0]+2],datmem[mem_addr[5:0]+3]};

//multiplexers
//mux with RegDst control
mult4_to_1_5 regdst_mux(        //M1
    out1,
    instruc[20:16], // 00 rt
    instruc[15:11], // 01 rd
    5'b11111,       // 10 $31 for balclean
    5'b00000,       // 11 unused
    regdst0,
    balclean
);
//mux with ALUSrc control
mult2_to_1_32 mult2(out2, datab,extad,alusrc);  //M2

//mux with MemToReg control
mult4_to_1_32 mult3(        //M3
    out3,
    sum,        // 00 ALU result
    dpack,      // 01 Memory
    adder1out,  // 10 PC+4
    32'b0,      // 11 unused
    memtoreg0,
    memtoreg1
);

// lwsgt ve swn icin adres secimi
mult4_to_1_32 memaddr_mux(      //M4 
    mem_addr,
    sum,         // 00 ALU result
    lwsgt_addr,  // 01 rs + shamt
    dataa,       // 10 ReadData1 = rs
    32'b0,       // 11 unused
    memaddr_s0,       // s0
    swn          // s1
); 

// write memorye gidecek mux swinc ve swor icin
mult4_to_1_32 sw_data_mux(      //M5
    swinc_data,
    datab,        // 00 normal sw / swn
    swinc_plus1,  // 01 swinc
    datac,        // 10 swor
    32'b0,        // 11 unused
    swinc,        // s0
    swor          // s1
); 

mult2_to_1_32 lwsgt_wb_mux(     //M6
    reg_write_data,
    out3,   // lwsgt = 0 → eski write data
    lwsgt_write_data,    
    lwsgt
);

// branch, jump mux
mult4_to_1_32 pc_mux(    //M7
    out4,
    adder1out,      // 00 PC+4
    adder2out,      // 01 branch
    datac,          // 10 read register 3 
    jump_target,    // 11 jump
    pc_s0,
    pc_s1
);


// load pc
always @(posedge clk)
pc<=out4;

// alu, adder and control logic connections

//ALU unit
alu32 alu1(sum, dataa, out2, zout, nout, vout, gout); // ALU with status

//adder which adds PC and 4
adder add1(pc,32'h4,adder1out);     //Add1

//adder which adds PC+4 and 2 shifted sign-extend result
adder add2(adder1out,sextad,adder2out);  //Add2

//bnem
assign not_dpack = ~dpack;

adder bnem_add1(datab, not_dpack, bnem_temp);   //Add3
adder bnem_add2(bnem_temp, 32'h1, bnem_diff);   //Add4

assign bnem_not_equal = |bnem_diff;
assign bnem_taken = bnem & bnem_not_equal;
assign lwsgt_gt = (~bnem_diff[31]) & (|bnem_diff);
assign lwsgt_write_data = {31'b0, lwsgt_gt};

signext5_to_32 sext5(instruc[10:6], shamt_ext);

adder lwsgt_add(dataa, shamt_ext, lwsgt_addr);  //Add5
adder swinc_adder(datab, 32'h1, swinc_plus1);   //Add6

//Control unit
control cont(instruc[31:26],instruc[5:0],regdst0,regdst1,alusrc,memtoreg0,memtoreg1,regwrite,memread,memwrite,branch,
aluop1,aluop0,lwsgt, swinc, balclean, bnem, swn, swor, bnpos);

//Sign extend unit
signext sext(instruc[15:0],extad);

//ALU control unit
alucont ac(aluop1, aluop0, instruc[5:0], gout);

//Shift-left 2 unit
shift shift2(sextad,extad);

//AND gate
assign pcsrc=branch && zout; 

//initialize datamemory,instruction memory and registers
//read initial data from files given in hex
initial
begin
$readmemh("initDm.dat",datmem); //read Data Memory
$readmemh("initIM.dat",mem);//read Instruction Memory
$readmemh("initReg.dat",registerfile);//read Register File

	for(i=0; i<31; i=i+1)
	$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
	"Register[%0d]= %h",i,registerfile[i]);
end

initial
begin
    pc = 0;
    clk = 0;
    #1 pc = 0;      // t=0'daki yanlış negedge sonrası PC'yi tekrar düzelt
    #400 $finish;
end

initial
begin
    #5;
    forever #20 clk = ~clk;
end
initial 
begin
$monitor($time,
" PC %h INST %h balclean %b out1 %d RA %h REG6 %h",
pc, instruc, balclean, out1, registerfile[31], registerfile[6]);
end
endmodule

