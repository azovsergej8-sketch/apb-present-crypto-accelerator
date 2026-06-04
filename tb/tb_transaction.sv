class crypto_transaction;
  rand logic[31:0] data;
  rand logic[7:0] addr;
  static const logic[7:0] all_addr[] = {8'h00, 8'h01, 8'h02, 8'h03, 8'h04};
  static logic[7:0] avalaible_addr[$];
  
  
  function new();
    avalaible_addr = all_addr;
  endfunction
  
  constraint addr_c{
    addr inside {avalaible_addr};
  };

  function post_randomize();
    int idx = avalaible_addr.find_first_index(x) with (x == tr_type);
    if(idx >= 0) avalaible_addr.delete(idx);
    else avalaible_addr = all_addr;
  endfunction
endclass
