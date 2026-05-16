module processor;
reg [31:0] pc; //32-bit prograom counter
reg clk; //clock
reg [7:0] datmem[0:31],mem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)
wire [31:0] 
dataa,	//Read data 1 output of Register File
datab,	//Read data 2 output of Register File
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

wire zout,	//Zero output of ALU
pcsrc,	//Output of AND gate with Branch and ZeroOut inputs
//Control signals
regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop0,lwsgt, swinc;

//32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];

integer i;

// datamemory connections

always @(posedge clk)
//write data to memory
if (memwrite)
begin 
//sum stores address,datab stores the value to be written
datmem[mem_addr[4:0]+3]=swinc_data[7:0];
datmem[mem_addr[4:0]+2]=swinc_data[15:8];
datmem[mem_addr[4:0]+1]=swinc_data[23:16];
datmem[mem_addr[4:0]]=swinc_data[31:24];
end

//instruction memory
//4-byte instruction
 assign instruc={mem[pc[4:0]],mem[pc[4:0]+1],mem[pc[4:0]+2],mem[pc[4:0]+3]};
 assign inst31_26=instruc[31:26];
 assign inst25_21=instruc[25:21];
 assign inst20_16=instruc[20:16];
 assign inst15_11=instruc[15:11];
 assign inst15_0=instruc[15:0];


// registers

assign dataa=registerfile[inst25_21];//Read register 1
assign datab=registerfile[inst20_16];//Read register 2
always @(posedge clk)
 registerfile[out1] = regwrite ? reg_write_data : registerfile[out1];//Write data to register

//read data from memory, sum stores address
assign dpack={datmem[mem_addr[5:0]],datmem[mem_addr[5:0]+1],datmem[mem_addr[5:0]+2],datmem[mem_addr[5:0]+3]};

//multiplexers
//mux with RegDst control
mult2_to_1_5  mult1(out1, instruc[20:16],instruc[15:11],regdest);

//mux with ALUSrc control
mult2_to_1_32 mult2(out2, datab,extad,alusrc);

//mux with MemToReg control
mult2_to_1_32 mult3(out3, sum,dpack,memtoreg);

//mux with (Branch&ALUZero) control
mult2_to_1_32 mult4(out4, adder1out,adder2out,pcsrc);

mult2_to_1_32 mux_lwsgt_a(alu_in_a,
    dataa,   // lwsgt = 0
    dpack,   // lwsgt = 1
    lwsgt
);

mult2_to_1_32 memaddr_mux(mem_addr, sum, lwsgt_addr, lwsgt); //lwsgt için adres hesaplaması

mult2_to_1_32 lwsgt_wb_mux(
    reg_write_data,
    out3,   // lwsgt = 0 → eski write data
    sum,    // lwsgt = 1 → ALU result, yani SLT sonucu 0/1
    lwsgt
);

mult2_to_1_32 swinc_mux(swinc_data,datab,swinc_plus1,swinc); //swinc için yazılacak veriyi hesaplama

// load pc
always @(negedge clk)
pc=out4;

// alu, adder and control logic connections

//ALU unit
alu32 alu1(sum, alu_in_a, out2, zout, gout); //lwsgt icin degistirdim

//adder which adds PC and 4
adder add1(pc,32'h4,adder1out);

//adder which adds PC+4 and 2 shifted sign-extend result
adder add2(adder1out,sextad,adder2out);

signext5_to_32 sext5(instruc[10:6], shamt_ext);

adder lwsgt_add(dataa, shamt_ext, lwsgt_addr);
adder swinc_adder(datab, 32'h1, swinc_plus1);

//Control unit
control cont(instruc[31:26],instruc[5:0],regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,
aluop1,aluop0,lwsgt, swinc);

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
" PC %h INST %h SUM %h REG4 %h REG6 %h DM28 %h %h %h %h",
pc, instruc, sum, registerfile[4], registerfile[6],
datmem[28], datmem[29], datmem[30], datmem[31]);
end
endmodule

