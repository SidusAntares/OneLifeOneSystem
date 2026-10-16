module seg_decoder #(
    parameter integer SCAN_CYCLE = 100_000 // 扫描周期，单位为时钟周期数
)(
    input wire clk,
    input wire rst_n,
    input wire [5:0] hour,
    input wire [5:0] minute,
    input wire [5:0] second,

    output reg [6:0] seg, // 7段数码管的段选信号
    output reg [5:0] an   // 7段数码管的位选信号
);

    reg [31:0] scan_counter;
    reg [2:0] scan_index;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_counter <= 0;
            scan_index <= 0;
        end else begin
            if (scan_counter == SCAN_CYCLE - 1) begin
                scan_counter <= 0;
                scan_index <= (scan_index + 1) % 6; // 循环扫描6位数码管
            end else begin
                scan_counter <= scan_counter + 1;
            end
        end
    end

    always @(*) begin
        case (scan_index)
            3'd0: begin seg = decode_digit(hour / 10); an = 6'b111110; end // 小时十位
            3'd1: begin seg = decode_digit(hour % 10); an = 6'b111101; end // 小时个位
            3'd2: begin seg = decode_digit(minute / 10); an = 6'b111011; end // 分钟十位
            3'd3: begin seg = decode_digit(minute % 10); an = 6'b110111; end // 分钟个位
            3'd4: begin seg = decode_digit(second / 10); an = 6'b101111; end // 秒钟十位
            3'd5: begin seg = decode_digit(second % 10); an = 6'b011111; end // 秒钟个位
            default: begin seg = 7'b1111111; an = 6'b111111; end // 默认状态，所有段灭，所有位灭
        endcase
    end

    function [6:0] decode_digit(input [4:0] digit);
        case (digit)
            4'd0: decode_digit = 7'b1000000;
            4'd1: decode_digit = 7'b1111001;
            4'd2: decode_digit = 7'b0100100;
            4'd3: decode_digit = 7'b0110000;
            4'd4: decode_digit = 7'b0011001;
            4'd5: decode_digit = 7'b0010010;
            4'd6: decode_digit = 7'b0000010;
            4'd7: decode_digit = 7'b1111000;
            4'd8: decode_digit = 7'b0000000;
            4'd9: decode_digit = 7'b0010000;
            default: decode_digit = 7'b1111111; // 默认状态，所有段灭
        endcase
    endfunction
endmodule