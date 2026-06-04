module present_crypto_top (
    input  logic clk,
    input  logic rst_n,
    // Интерфейс APB шины
    core_intf cr_inf
);
  crypto_intf cryp_inf;
  
  apb_slave apb_bridge_inst (
      .clk        (clk),
      .rst        (rst_n),
      .core_inf   (cr_inf.apb_slave),
      .crypto_inf (cryp_inf.apb_slave)
  );

  crypto_core crypto_core_inst (
      .clk      (clk),
      .rst      (rst_n),
      .cr_inf   (cryp_inf.crypto_core)
  );

endmodule
