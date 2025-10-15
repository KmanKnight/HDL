`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2025 09:31:16 PM
// Design Name: 
// Module Name: intALU
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


module IntegerAlu(clk, dataBus, address, nRead, nWrite, nReset);
input logic clk, nRead, nWrite, nReset;
input logic [15:0] address;
inout logic [255:0] dataBus;

logic [255:0] sources [1:0];
logic [255:0] result;
logic [15:0] statusIn;
logic statusOut, driveRslt, driveStOut;

assign dataBus = driveRslt ? result : driveStOut ? statusOut : 'hz ;

always_ff @ (negedge nReset) begin
    sources[0] = 0;
    sources[1] = 0;
    statusIn = 0;
    statusOut = 0;
    result = 0;
end

always_ff @ (posedge clk) begin
    case (address)
        16'h3000:sources[0] <= !nWrite ? dataBus[15:0] : sources[0];
        16'h3001:sources[1] <= !nWrite ? dataBus[15:0] : sources[1];
        16'h3E00:statusIn <= !nWrite ? dataBus : statusIn;
    endcase
end

always_ff @ (negedge clk) begin
    driveStOut = (!nRead && address[15:8] == 'h3F) ? 1 : 0;
    driveRslt = (!nRead && address[15:8] == 'h3D) ? 1 : 0;
end
always_comb begin
    case (statusIn)
        16'h3100:begin 
                result = sources[0][15:0] + sources[1][15:0]; 
                statusOut = 1;
            end
        16'h3200:begin
                result = sources[0][15:0] - sources[1][15:0];
                statusOut = 1;
            end
        16'h3300:begin 
                result = sources[0][15:0] * sources[1][15:0];
                statusOut = 1;    
            end
        16'h3400:begin 
                result = sources[0][15:0] / sources[1][15:0];
                statusOut = 1;    
            end
        16'h3A00:begin 
                result = sources[0] != sources[1];
                statusOut = 1;               
            end
        16'h3B00:begin 
                result = sources[0] == sources[1];
                statusOut = 1;               
            end
        16'h3C00:begin 
                result = sources[0] < sources[1];
                statusOut = 1;                
            end
        16'h3D00:begin 
                result = sources[0] > sources[1];
                statusOut = 1;                
            end
        default:begin 
                            result = 0;
                            statusOut = 0;
            end
    endcase

end



endmodule
