class crypto_checker;
  mailbox #(crypto_transaction) addr_fifo;
  event clk_ev;
  
  //Конструктор
  function new(mailbox #(cache_transaction) addr_fi, event clk_e);
    this.addr_fifo = addr_fi;
    this.clk_ev = clk_e;
  endfunction

  //Сравнение
  task true_model(virtual crypto_intf cr_inf);
    forever begin
      //Данные к криптоядру
      logic[31:0] data_lo, data_hi;
      logic[63:0] cr_data;
      //Ключ
      logic[31:0] key_lo, key_mi;
      logic[15:0] key_hi;
      logic[79:0] cr_key;
      //Необходимые регистры в ходе шифровки
      logic[63:0] state_xor;
      logic[63:0] sbox_out;
      //Измененные данные
      logic[63:0] next_data;
      logic[79:0] next_key;
      
      @(posedge cr_inf.cr_start);
      for(int i = 0; i < 5; i = i+1) begin
        crypto_transaction local_tr;
        addr_fifo.get(local_tr);
        case(local_tr.addr)
          8'h00: begin
            data_lo = local_tr.data;
          end
          8'h01: begin
            data_hi = local_tr.data;
          end
          8'h02: begin
            key_lo = local_tr.data;
          end
          8'h03: begin
            key_mi = local_tr.data;
          end
          8'h04: begin
            key_hi = local_tr.data;
          end
        endcase
      end
      int count = 1;
      cr_data = {data_hi, data_lo};
      cr_key = {key_hi, key_mi, key_lo};
      state_data = cr_data;
      state_key = cr_key;
      for(; count < 32; count = count + 1) begin
        state_xor = state_data ^ state_key[79:16];
        for(int i = 0; i < 16; i = i + 1) sbox_out[4*i +: 4] = sbox_table(state_xor[4*i +: 4]);
        for(int i = 0; i < 63; i = i + 1) begin
          next_data[(16*i) % 63] = sbox_out[i];
        end
        next_data[63] = sbox_out[63];
        //Мутация ключа
        next_key = {state_key[18:0], state_key[79:19]};
        next_key[79:76] = sbox_table(next_key[79:76]);
        next_key[19:15] = next_key[19:15] ^ count;
        state_data = next_data;
        state_key = next_key;
      end
      state_data = state_data ^ state_key[79:16];
      @(posedge cr_inf.cr_ready);
      $display("[INF_TR] Testing transaction. Key: %h | Data: %h", cr_key, cr_data);
      if(state_data == cr_inf.cr_wdata) begin
        $display("[CHECKER_OK]  Match! Key: %h | Data: %h", cr_key, cr_data);
      end else begin
        $error("[CHECKER_FAIL] MISMATCH! Key: %h | Exp: %h | Got: %h", cr_key, cr_data, cr_inf.cr_wdata);
      end
    end
  endtask
endclass
