// Mark W. Welker
// project
// Spring 2023
//
//


module MainMemory(Clk,Dataout, address, nRead,nWrite, nReset);

//`include "params.vh"

input logic nRead,nWrite, nReset, Clk;
input logic [15:0] address;

inout logic [255:0] Dataout; // to the CPU 

  logic [255:0]MainMemory[14]; // this is the physical memory
  logic ItsMe; // the address bus is talkig to this module. used to enable tristate buffers.
  logic [255:0] MemToOutput; // this is a temporary data register to be set to go to the output. 

always_ff @(negedge Clk or negedge nReset)
begin
	if (~nReset) begin
	MainMemory[0] = 256'h0009_000c_0008_000d_0008_0003_000f_0009_000B_0013_0010_0007_000c_0005_000e_0006;
	MainMemory[1] = 256'h0007_0005_0007_0009_000c_0003_000e_0002_0010_0009_000f_0008_000c_0007_0004_0006;
	MainMemory[2] = 256'h0;
	MainMemory[3] = 256'h0;
	MainMemory[4] = 256'h0;
	MainMemory[5] = 256'h0;
	MainMemory[6] = 256'h0;
	MainMemory[7] = 256'h0;
	MainMemory[8] = 256'h0;
	MainMemory[9] = 256'h0;
	MainMemory[10] = 256'h4;
	MainMemory[11] = 256'he;
	MainMemory[12] = 256'h0;
	MainMemory[13] = 256'h0;
	
	
      MemToOutput=0;
	end

  else if(address[15:12] == 0) // talking to Instruction
		begin
			
			if (~nRead)begin
			  ItsMe = 1; // Only Drive Bus on read
				MemToOutput = MainMemory[address[11:0]]; // data will remain on dataout until it is changed.
			end
			if(~nWrite)begin
			ItsMe = 0; // only drive bus on read
		    MainMemory[address[11:0]] <= Dataout;
			end
		end
    else ItsMe = 0;
end 	

assign Dataout = ItsMe ? MemToOutput : 255'bz;
endmodule


