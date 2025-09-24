`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*
TODO:
CREATE IDLE STATE MACHINE LOGIC
    Instruction fetch 
    Instruction decode
CREATE STOP STATE LOGIC
    $finish
TEST FUNCTIONALITY
*/
//////////////////////////////////////////////////////////////////////////////////


module executionEngine(clk, dataBus, address, nRead, nWrite, nReset);
// REGISTERS AND PORTS
input logic clk;
output logic nRead, nWrite;
inout wire nReset;
inout wire [255:0] dataBus;
output logic [15:0] address;

logic [255:0] registers [5:0];
logic [255:0] dataBuffer;
logic [7:0] count;
logic [7:0] instructionAddress;
logic nResetBuffer;
logic driveEn, driveRst;
logic [3:0][7:0] instruction;

assign nReset = driveRst ? nResetBuffer : 'z;
assign dataBus = driveEn ? dataBuffer : 'z;

enum {idle, intALU, branchALU, matrixALU, resetting} state;
//////////////////////////////////////////
// INITIAL VALUES
initial begin
    driveEn = 0;
    driveRst = 0;
    count = 0;
    instructionAddress = 0;
    nRead = 1;
    nWrite = 1;
    nResetBuffer = 1;
    address = 'z;
    dataBuffer = 'z;
    instruction = 'z;
end
//////////////////////////////////////////
// RESET LOGIC
always @ (negedge nReset) begin
    state <= nReset ? state : resetting;
end
//////////////////////////////////////////
// STATE BUS MANIPULATIONS
always @ (posedge clk) begin
    #10
    case (state)
        resetting: begin
            driveRst = 1;
            case (count)
                0: begin 
                    address='h0000;   
                    nResetBuffer<=0;  
                    count<=count+1; 
                   end
                1: begin 
                    address='h1000;   
                    nResetBuffer<=0;  
                    count<=count+1; 
                   end
                default: begin 
                          instructionAddress=0; 
                          address=('h1000 + instructionAddress);       
                          state<=idle;   
                          nRead=0;   
                          nWrite=1;   
                          driveRst=0;   
                          count<=0;      
                         end
            endcase
        end
        idle:begin 
            case(count)
                0: begin nRead=1;
                    case (instruction[3][7:4])
                        'h0: state = matrixALU;
                        'h1: state = intALU;
                        'h2: state = branchALU;
                        default: $finish;
                    endcase
                   count<=0;
                   address=(instruction[1][6:0] + ( instruction[1][7:6] ? 'h4000 : 0 )); 
                   nRead=0;
                   end
            endcase      
        end
        intALU:begin
            case(count)
                0: begin 
                    address=(instruction[0][6:0] + ( instruction[0][7:6] ? 'h4000 : 0 )); 
                    nRead=0; 
                    count<=count+1;  
                   end
                1: begin 
                    address='h3000; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[0]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                2: begin 
                    address='h3001; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[1]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                3: begin 
                    address=('h3000 + ( (instruction[3][3:0]+1) << 8) ); 
                    nRead=0; 
                    nWrite=1; 
                    driveEn=0; 
                    count<=count+1; 
                   end
                4: begin 
                    address=(instruction[2][6:0] + ( instruction[2][7:6] ? 'h4000 : 0 )); 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[2]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                5: begin 
                    address=('h1000 + instructionAddress);       
                    state<=idle; 
                    nRead=0;     
                    nWrite=1;   
                    driveEn=0;   
                    count<=0; 
                    instructionAddress<=instructionAddress+1; 
                   end
            endcase
        end
        branchALU:begin
            case(count)
                0: begin 
                    address=(instruction[0][6:0] + ( instruction[0][7:6] ? 'h4000 : 0 )); 
                    nRead=0; 
                    count<=count+1;  
                   end
                1: begin 
                    address='h3000; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[0]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                2: begin 
                    address='h3001; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[1]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                3: begin 
                    address=('h3000 + ( (instruction[3][3:0]+10) << 8) ); 
                    nRead=0; 
                    nWrite=1; 
                    driveEn=0; 
                    count<=count+1; 
                   end
                4: begin 
                    instructionAddress=registers[2]==1?instructionAddress+instruction[2]:instructionAddress+1; 
                    address=('h1000 + instructionAddress);       
                    state<=idle; 
                    nRead=0; 
                    nWrite=1;   
                    driveEn=0;   
                    count<=0; 
                   end
            endcase
        end
        matrixALU:begin
            case(count)
                0: begin 
                    address=(instruction[0][6:0] + ( instruction[0][7:6] ? 'h4000 : 0 )); 
                    nRead=0; 
                    count<=count+1;  
                   end
                1: begin 
                    address='h2000; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[0]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                2: begin 
                    address='h2001; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[1]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                3: begin 
                    address=('h2000 + ( (instruction[3][3:0]+1) << 8) ); 
                    nRead=0;
                    nWrite=1; 
                    driveEn=0; 
                    count<=count+1; 
                   end
                4: begin 
                    address=(instruction[2][6:0] + ( instruction[2][7:6] ? 'h4000 : 0 )); 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[2]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                5: begin 
                    address=('h1000 + instructionAddress);       
                    state<=idle;   
                    nRead=0;   
                    nWrite=1;   
                    driveEn=0;   
                    count<=0; 
                    instructionAddress<=instructionAddress+1; 
                   end
            endcase
        end
    endcase
end
//////////////////////////////////////////
// STATE REGISTER SAVING

always_ff @ (posedge clk) begin
    case(count)
        0: if (state == idle) instruction <= dataBus[31:0];
              else registers[0] <= dataBus;
        1: registers[1] <= instruction[3][3:0] == 7 ? instruction[0] : dataBus;
        4: registers[2] <= dataBus;
    endcase
end
//always @ (posedge clk) begin
//    case (state)
//        idle:begin
//            case(count)
//                0:instruction=dataBus[31:0];
//            endcase
//        end
//        intALU:begin
//            case(count)
//                0: registers[0] = dataBus;
//                1: registers[1] = dataBus;
//                4: registers[2] = dataBus;
//            endcase
//        end
//        branchALU:begin
//            case(count)
//                0: registers[0] = dataBus;
//                1: registers[1] = dataBus;
//                4: registers[2] = dataBus;
//            endcase
//        end
//        matrixALU:begin
//            case(count)
//                0: registers[0] = dataBus;
//                1: registers[1] = instruction[3][3:0] == 7 ? instruction[0] : dataBus;
//                4: registers[2] = dataBus;
//            endcase
//        end
//    endcase
//end

endmodule
