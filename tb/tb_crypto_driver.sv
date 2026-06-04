class crypto_driver;
  mailbox #(crypto_transaction) tr_fifo;
  
  function new( mailbox #(cache_transaction) addr_fifo);
    this.tr_fifo = addr_fifo;
  endfunction
  
  task drive(virtual core_intf.core cr_intf, event clk_e);
    cache_transaction tr;
    repeat(50) begin
      if(tr == null) begin
        tr = new();
        if(!tr.randomize()) $error("Randomization failed!");
      end
      @(clk_e);
      if(cr_intf.ready) begin
        cr_intf.core_addr <= #1 tr.addr;
        cr_intf.sel <= #1 1;
        cr_intf.enable <= #1 1;
        cr_intf.write <= #1 1;
        tr_fifo.put(tr);
        tr = null;
      end else begin
        r_intf.sel <= 0;
        cr_intf.enable <= 0;
        cr_intf.write <= 0;
      end
    end
  endtask
endclass
