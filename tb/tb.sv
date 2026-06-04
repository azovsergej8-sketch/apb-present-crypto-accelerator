module tb_top;
  logic clk = 0;
  logic rst = 1;
  always #5 clk = ~clk;
  event clk_ev;
  always@(posedge clk) -> clk_ev;
  
  initial begin
    rst = 1;
    #20 rst = 0; 
    #20 rst = 1; 
  end
  
  core_intf intermediate_core_io();
  mailbox #(crypto_transaction) addr_fifo;
  
  top_module dut(
    .clk     (clk),
    .rst_n   (rst),
    .cr_inf  (intermediate_core_io)
  );

  initial begin
    addr_fifo = new();
    test actual_test = new(intermediate_core_io, intermediate_mem_io, addr_fifo, clk_ev);
    actual_test.run();
    $finish;
  end
  
endmodule
