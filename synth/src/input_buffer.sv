`include "sys_defs.svh"

module input_buffer (
    input logic clk, rst,
    input logic [`IN_BUS_WIDTH-1:0] data_in,
    input logic [4:0] huff_size,
    input logic [3:0] vli_size,
    input logic wr_en, rd_en,

    output logic [15:0] top_bits,
    output logic [10:0] vli_symbol,
    output logic request, valid_out
);

logic [`IN_BUFF_SIZE-1:0] buffer, buffer_n;
logic [$clog2(`IN_BUFF_SIZE+1)-1:0] head, head_n, tail, tail_n, count, count_n;

assign request = count < (`IN_BUFF_SIZE - `IN_BUS_WIDTH);
assign valid_out = rd_en & (count > 0);

always_comb begin
    buffer_n = buffer;
    head_n = head;
    tail_n = tail;
    count_n = count;
    vli_symbol = 12'b0;

    // Writing buffer
    if (wr_en) begin
        for (int i = 0; i < `IN_BUS_WIDTH; ++i) begin
            buffer_n[(tail+i) % `IN_BUFF_SIZE] = data_in[i];
        end
        tail_n = (tail + `IN_BUS_WIDTH) % `IN_BUFF_SIZE;
        count_n += `IN_BUS_WIDTH;
    end
    
    // Reading buffer
    if (rd_en) begin
        head_n = (head + huff_size + vli_size) % `IN_BUFF_SIZE;
        count_n -= (huff_size + vli_size);
    end

    // Output top 16 bits to Huffman
    for (int i = 0; i < 16; ++i) begin
        top_bits[i] = buffer[(head+i) % `IN_BUFF_SIZE];
    end

    // Output VLI symbol generated by huffman
    for (int i = 0; i < vli_size; ++i) begin
        vli_symbol[i] = buffer[(head+huff_size+i) % `IN_BUFF_SIZE];
    end

end

always_ff @(posedge clk) begin
    if (rst) begin
        buffer <= `IN_BUFF_SIZE'b0;
        head <= 0;
        tail <= 0;
        count <= 0;
    end else begin
        buffer <= buffer_n;
        head <= head_n;
        tail <= tail_n;
        count <= count_n;
    end
end

endmodule
