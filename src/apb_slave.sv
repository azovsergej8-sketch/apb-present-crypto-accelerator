module apb_slave(
  input wire clk, rst, valid_in,
  //Интерфейс связи с процессором
  core_intf.apb_slave core_inf,
  //Интерфейс связи с криптоядром
  crypto_intf.apb_slave crypto_inf
);
  //Данные к криптоядру
  logic[31:0] data_lo, data_hi;
  //Ключ
  logic[31:0] key_lo, key_mi;
  logic[15:0] key_hi;
  logic[62:0] crypto_data;
  
  //Счетчики полученных битов
  reg[2:0] data_count, key_count;
  
  //Вход на криптоядро
  always_comb begin
    cr_rdata = {data_hi, data_lo}; //Данные
  end
  always_comb begin
    cr_key = {key_hi, key_mi, key_lo}; //Ключ
  end

  //Состояние
  typedef enum logic[2:0]{START, DATA_CR_OUT} state_t;
  state_t state

  //Адресное пространство
  typedef enum logic[7:0]{DATA_LO = 8'h00, DATA_HI = 8'h01, KEY_LO = 8'h02, KEY_MI = 8'h03, KEY_HI = 8'h04, CRYPTO_DATA_LO = 8'h05, CRYPTO_DATA_HI = 8'h06} mem_t;
  mem_t addr_map;
  always_comb begin
    addr_map = mem_t'(core_inf.addr);
  end
  
  //FSM
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      data_low <= 0; data_hi <= 0; key_lo <= 0; key_mi <= 0; key_hi <= 0; core_inf.ready <= 1;
    end else begin
      case(state)
        START: begin
          if(core_inf.enable && core_inf.sel && core_inf.write) begin
            if(data_count == 2 && key_count == 3) begin
              cr_start <= 1; state <= DATA_CR_OUT; core_inf.ready <= 0;
            end else begin
              case(addr_map)
                DATA_LO: begin
                  data_lo <= core_inf.wdata; data_count <= data_count + 1;
                end
                DATA_HI: begin
                  data_hi <= core_inf.wdata; data_count <= data_count + 1;
                end
                KEY_LO: begin
                  key_lo <= core_inf.wdata; key_count <= key_count + 1;
                end
                KEY_MI: begin
                  key_mi <= core_inf.wdata; key_count <= key_count + 1;
                end
                KEY_HI: begin
                  key_hi <= core_inf.wdata; key_count <= key_count + 1;
                end
              endcase
            end
          end
        end
        DATA_CR_OUT: begin
          if(crypto_inf.cr_start) crypto_inf.cr_start <= 0;
          if(crypto_inf.cr_ready) begin
            crypto_data <= crypto_inf.cr_wdata;
            core_inf.ready <= 1; state <= START;
          end
        end
      endcase
    end
  end

  //Чтение
  always_comb begin
    core_inf.rdata = 8'h0;
    if(core_inf.enable && core_inf.sel && !core_inf.write) begin
      case(addr_map)              
        DATA_LO: core_inf.rdata = data_lo; 
        DATA_HI: core_inf.rdata = data_hi; 
        KEY_LO: core_inf.rdata = key_lo;
        KEY_MI: core_inf.rdata = key_mi; 
        KEY_HI: core_inf.rdata = key_hi; 
        CRYPTO_DATA_LO: core_inf.rdata = crypto_data[31:0];
        CRYPTO_DATA_HI: core_inf.rdata = crypto_data[63:32];
        default: core_inf.rdata = 8'h0;
      endcase
    end
  end
endmodule
