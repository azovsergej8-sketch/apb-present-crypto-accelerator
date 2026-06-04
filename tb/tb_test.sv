class test;
  virtual core_intf cr_if;
  virtual crypto_intf cryp_if;
  crypto_driver    drv;
  crypto_checker   chk;
  event clk_ev;

  function new(virtual core_intf c_if,  virtual crypto_intf crp_if,  mailbox #(crypto_transaction) addr_fifo, event clk_e);
    this.cr_if = c_if;
    this.cryp_if = crp_if;
    this.drv = new(addr_fifo);
    this.clk_ev = clk_e;
    this.chk = new(addr_fifo, this.clk_ev);
  endfunction

  task run();
    fork
      drv.drive(cr_if, clk_ev);
      chk.true_model(cr_if);
    join_any
    disable fork;
    $display("Тест завершен!");
  endtask
endclass
