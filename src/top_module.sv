module present_crypto_top (
    // Глобальные сигналы
    input  logic        clk,
    input  logic        rst_n,
    // Интерфейс APB шины
    input  logic [7:0]  PADDR,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY
);

  // 1. Внутренние провода
  logic [63:0] connect_data_to_core;
  logic [79:0] connect_key_to_core;
  logic        connect_start;
  
  logic [63:0] connect_data_from_core;
  logic        connect_ready;

  // Фиксируем готовность шины APB
  assign PREADY = 1'b1;

  // 2. Подключение интерфейсного моста
  apb_slave_interface apb_bridge_inst (
      .clk        (clk),
      .rst        (rst_n),
      .addr       (PADDR),
      .sel        (PSEL),
      .enable     (PENABLE),
      .wr         (PWRITE),
      .wdata      (PWDATA),
      .rdata      (PRDATA),
      .ready      (),
      // Внутренние связи с ядром
      .cr_rdata   (connect_data_to_core),
      .cr_key     (connect_key_to_core),
      .cr_start   (connect_start),
      .cr_wdata   (connect_data_from_core),
      .cr_ready   (connect_ready)
  );

  // 3. Подключение криптоядра
  present_core crypto_core_inst (
      .clk        (clk),
      .rst_n      (rst_n),
      .core_data_in  (connect_data_to_core),
      .core_key_in   (connect_key_to_core),
      .core_start    (connect_start),
      .core_data_out (connect_data_from_core),
      .core_ready    (connect_ready)
  );

endmodule
