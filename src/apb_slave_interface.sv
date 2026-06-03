module apb_slave_interface(
  //Интерфейс связи с процессором
  input wire clk, rst, sel, enable, write,
  input wire[7:0] addr, //Адрес
  input wire[31:0] wdata, //Данные для записи
  output reg[31:0] rdata, //Данные для чтения
  output reg ready,

  //Интерфейс связи с криптоядром
  input wire[63:0] cr_wdata, //Зашифрованные данные от криптоядра
  input wire cr_ready, //Флаг готовности данных от криптоядра
  output reg[63:0] cr_rdata, //Данные для чтения криптоядром
  output reg[79:0] cr_key, //Ключ
  output reg cr_start //Старт работы криптоядра
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
    addr_map = mem_t'(addr);
  end
  
  //FSM
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      data_low <= 0; data_hi <= 0; key_lo <= 0; key_mi <= 0; key_hi <= 0; ready <= 1;
    end else begin
      case(state)
        START: begin
          if(enable && sel && write) begin
            if(data_count == 2 && key_count == 3) begin
              cr_start <= 1; state <= DATA_CR_OUT; ready <= 0;
            end else begin
              case(addr_map)
                DATA_LO: begin
                  data_lo <= wdata; data_count <= data_count + 1;
                end
                DATA_HI: begin
                  data_hi <= wdata; data_count <= data_count + 1;
                end
                KEY_LO: begin
                  key_lo <= wdata; key_count <= key_count + 1;
                end
                KEY_MI: begin
                  key_mi <= wdata; key_count <= key_count + 1;
                end
                KEY_HI: begin
                  key_hi <= wdata; key_count <= key_count + 1;
                end
              endcase
            end
          end
        end
        DATA_CR_OUT: begin
          if(cr_start) cr_start <= 0;
          if(cr_ready) begin
            crypto_data <= cr_wdata;
            ready <= 1; state <= START;
          end
        end
      endcase
    end
  end

  //Чтение
  always_comb begin
    rdata = 8'h0;
    if(enable && sel && !write) begin
      case(addr_map)              
        DATA_LO: rdata = data_lo; 
        DATA_HI: rdata = data_hi; 
        KEY_LO: rdata = key_lo;
        KEY_MI: rdata = key_mi; 
        KEY_HI: rdata = key_hi; 
        CRYPTO_DATA_LO: rdata = crypto_data[31:0];
        CRYPTO_DATA_HI: rdata = crypto_data[63:32];
        default: rdata = 8'h0;
      endcase
    end
  end
endmodule
