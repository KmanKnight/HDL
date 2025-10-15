`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/07/2025 08:54:43 AM
// Design Name: 
// Module Name: executionModule
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Execution(Clk, DataBus, address, nRead, nWrite, nReset);
input logic Clk, nReset;
inout logic [255:0] DataBus;
output logic nRead, nWrite;
output logic [15:0] address;

logic driveEn, passThrough;
logic [3:0][7:0] instruction;
logic [15:0] instructionAddress;
logic [255:0] DataBuffer;
logic [7:0][255:0] InternalReg;

assign DataBus = driveEn ? DataBuffer : 'z;


enum{Rst,RdInst,RdS1,RdS2,WrS1,WrS1_1,WrS2,WrSI,WrSI_1,WfR,RdRs,WrRs} state, nextstate;
enum{iALU,mALU,bALU,STOP} op;

initial begin
    nRead = 1;
    nWrite = 1;
    address = 0;
    driveEn = 0;
    DataBuffer = 'z;
    instruction = 'z;
    instructionAddress = 0;
    passThrough = 0;
end

always_ff @ (posedge Clk or negedge nReset) begin
    if (!nReset)
        state = Rst;
    else
        state = nextstate;
end

always_comb begin
    case (state)
        Rst:   begin 
            nextstate = RdInst;
            instructionAddress = 0;
            nRead = 1;
            nWrite = 1;
            driveEn = 0;
        end
        RdInst: begin 
            nWrite = 1;
            driveEn = 0;
            address = 'h1000+instructionAddress;
            nRead = 0;
            instruction = DataBus;
            nextstate = RdS1;
            case (instruction[3][7:4])
                'h0: op = mALU;
                'h1: op = iALU;
                'h2: op = bALU;
                'hf: op = STOP;
                default: op = op;
            endcase
            if (op == STOP)
                $stop;
        end
        RdS1:   begin
            if (instruction[1][7:4])
                    InternalReg[7] = InternalReg[instruction[1][3:0]];
            else begin
                address = (instruction[1][6:0] + ( instruction[1][7:6] ? 'h4000 : 0 ));
                InternalReg[7] = DataBus;
            end
            nextstate = RdS2;
         end
        RdS2:   begin
            if (instruction[3] == 'h07)
                InternalReg[6] = instruction[0];
            else if (instruction[0][7:4])
                InternalReg[6] = InternalReg[instruction[0][3:0]];
            else begin
                address = (instruction[0][6:0] + ( instruction[0][7:6] ? 'h4000 : 0 ));
                InternalReg[6] = DataBus;
            end
            nextstate = WrS1;
         end
        WrS1:   begin
            nRead = 1;
            address = ( op == iALU || op == bALU ? 'h3000 : 'h2000 );
            nextstate = WrS1_1;
         end
        WrS1_1: begin
            DataBuffer = InternalReg[7];
            driveEn = 1;
            nWrite = 0;
            nextstate = WrS2;
         end
        WrS2:   begin 
            address = ( op == iALU || op == bALU ? 'h3001: 'h2001 );
            DataBuffer = InternalReg[6];
            nextstate = WrSI;
        end
        WrSI: begin
            address = ( ( op == iALU || op == bALU ? 'h3E00 : 'h2E00));
            DataBuffer =  ( ( op == iALU || op == bALU ? 'h3000 : 'h2000) + ( ( op == bALU ? instruction[3][3:0] + 'hA : instruction[3][3:0] + 1 ) << 8 ) );
            nextstate = WfR;
        end
        WfR:    begin 
            nWrite = 1;
            driveEn = 0;
            address = ( ( op == iALU || op == bALU ? 'h3F00 : 'h2F00 ) );
            nRead = 0;
            if (DataBus) begin
                nextstate = RdRs;
            end else
                nextstate = WfR;
        end
        RdRs:   begin
            address = ( ( op == iALU || op == bALU ? 'h3D00 : 'h2D00));
            InternalReg[5] = DataBus;
            nextstate = WrRs;
        end
        WrRs:   begin 
            if (op != bALU) begin
                if (instruction[2][7:4])
                    InternalReg[instruction[2][3:0]] = InternalReg[5];
                else begin
                    nRead = 1;
                    address = (instruction[2][6:0]);
                    DataBuffer = InternalReg[5];
                    driveEn = 1;
                    nWrite = 0;
                end
                instructionAddress = instructionAddress + 1;
            end else begin
                if (InternalReg[5])
                    instructionAddress = instructionAddress + instruction[2];
                else
                    instructionAddress = instructionAddress + 1;
            end
            nextstate = RdInst;
        end
    endcase
    
end




endmodule
