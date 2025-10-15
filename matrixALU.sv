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


module MatrixAlu(clk, dataBus, address, nRead, nWrite, nReset);
input logic clk, nRead, nWrite, nReset;
input logic [15:0] address;
inout logic [255:0] dataBus;

logic [3:0][3:0][15:0] source1;
logic [3:0][3:0][15:0] source2;
logic [3:0][3:0][15:0] result;
logic [15:0] statusIn;
logic statusOut, driveRslt, driveStOut;

assign dataBus = driveRslt ? result : driveStOut ? statusOut : 'hz ;

always_ff @ (negedge nReset) begin
    source1 <= 0;
    source2 <= 0;
    statusIn <= 0;
    result <= 0;
end

always_ff @ (posedge clk) begin
    case (address)
        16'h2000:source1 <= !nWrite ? dataBus : source1;
        16'h2001:source2 <= !nWrite ? dataBus : source2;
        16'h2E00:statusIn <= !nWrite ? dataBus : statusIn;
    endcase
end

always_ff @ (negedge clk) begin
    driveStOut = (!nRead && address[15:8] == 'h2F) ? 1 : 0;
    driveRslt = (!nRead && address[15:8] == 'h2D) ? 1 : 0;
end

always_comb begin
    for (int r = 0; r<4; r++)
        for (int c = 0; c<4; c++)
            case (statusIn)
                16'h2100:begin 
                        result[r][c] <= ( (source1[r][0]*source2[0][c]) + (source1[r][1]*source2[1][c]) + (source1[r][2]*source2[2][c]) + (source1[r][3]*source2[3][c]) );
                        statusOut = 1;
                    end                
                16'h2400:begin 
                        result[r][c] <= source1[r][c] + source2[r][c];
                        statusOut = 1;
                    end
                16'h2500:begin 
                        result[r][c] <= source1[r][c] - source2[r][c];
                        statusOut = 1;
                    end
                16'h2600:begin 
                        result[r][c] <= source1[c][r];
                        statusOut = 1;
                    end
                16'h2700:begin 
                        result[r][c] <= source1[r][c] * source2;
                        statusOut = 1;
                    end
                16'h2800:begin 
                        result[r][c] <= source1[r][c] * source2;
                        statusOut = 1;
                    end
                default:begin
                        result = 0;
                        statusOut = 0;
                end
            endcase
end


endmodule
