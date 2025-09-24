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

logic [255:0] dataBuffer, registers [5:0];
logic [3:0][7:0] instruction;
logic [7:0] instructionAddress, count;
logic driveEn, driveRst, nResetBuffer;

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
always @ (negedge clk) begin
    case (state)
        resetting: begin
            driveRst = 1;
            case (count)
                0: begin //Drive RST pin for main memory resetting it to default values
                    address='h0000;   
                    nResetBuffer<=0;  
                    count<=count+1; 
                   end
                1: begin //Drive RST for insturction memory
                    address='h1000;   
                    nResetBuffer<=0;  
                    count<=count+1; 
                   end
                default: begin //set state to IDLE, reset all variables and start reading first instruction
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
                0: begin nRead=1; //Decode instruction and set the State, read the first source
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
                0: begin //Read the second source
                    address=(instruction[0][6:0] + ( instruction[0][7:6] ? 'h4000 : 0 )); 
                    nRead=0; 
                    count<=count+1;  
                   end
                1: begin //Load S1 into S1 of the int ALU
                    address='h3000; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[0]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                2: begin //Load S2 into S2 of the int ALU
                    address='h3001; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[1]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                3: begin //Read the result by asserting the right address
                    address=('h3000 + ( (instruction[3][3:0]+1) << 8) ); 
                    nRead=0; 
                    nWrite=1; 
                    driveEn=0; 
                    count<=count+1; 
                   end
                4: begin //Write the result to the destination
                    address=(instruction[2][6:0] + ( instruction[2][7:6] ? 'h4000 : 0 )); 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[2]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                5: begin //Read the next instruction, reset all variables to default values.
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
                0: begin //Read second source
                    address=(instruction[0][6:0] + ( instruction[0][7:6] ? 'h4000 : 0 )); 
                    nRead=0; 
                    count<=count+1;  
                   end
                1: begin //Load S1 into S1 of int ALU
                    address='h3000; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[0]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                2: begin //Load S2 into S2 of int ALU
                    address='h3001; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[1]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                3: begin // Do comparison and read result
                    address=('h3000 + ( (instruction[3][3:0]+10) << 8) ); 
                    nRead=0; 
                    nWrite=1; 
                    driveEn=0; 
                    count<=count+1; 
                   end
                4: begin //Branch if result is 1, otherwise continue to next instruction and read
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
                0: begin //Read S2
                    address=(instruction[0][6:0] + ( instruction[0][7:6] ? 'h4000 : 0 )); 
                    nRead=0; 
                    count<=count+1;  
                   end
                1: begin //Load S1 to S1 of matrixALU
                    address='h2000; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[0]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                2: begin //Load S2 to S2 of matrixALU
                    address='h2001; 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[1]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                3: begin //Read result
                    address=('h2000 + ( (instruction[3][3:0]+1) << 8) ); 
                    nRead=0;
                    nWrite=1; 
                    driveEn=0; 
                    count<=count+1; 
                   end
                4: begin //Load result into destination address
                    address=(instruction[2][6:0] + ( instruction[2][7:6] ? 'h4000 : 0 )); 
                    nRead=1; 
                    nWrite=0; 
                    dataBuffer = registers[2]; 
                    driveEn=1; 
                    count<=count+1; 
                   end
                5: begin //Read next instruction
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
always_ff @ (posedge clk) begin //Saving values from dataBus into internal registers at set times
    case(count)
        0: if (state == idle) instruction <= dataBus[31:0];
              else registers[0] <= dataBus;
        1: registers[1] <= instruction[3][3:0] == 7 ? instruction[0] : dataBus;
        4: registers[2] <= dataBus;
    endcase
end
//////////////////////////////////////////


endmodule
