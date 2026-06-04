module crypto_core(
  input wire clk, rst,
  crypto_intf.crypto_core cr_inf
);
  //Данные для состояния
  reg[63:0] state_data; //Внешние данные
  reg[79:0] state_key; //Значение ключа
  reg[5:0] count; //Счетчик

  //Необходимые регистры в ходе шифровки
  logic[63:0] state_xor;
  logic[63:0] sbox_out;
  
  //Измененные данные
  logic[63:0] next_data;
  logic[79:0] next_key;
  
  //Состояние FSM
  typedef enum logic[2:0]{IDLE, WORK, DONE} state_t;
  state_t state;

  //Шифрование
  //1. Инъекция секретного ключа в данные
  assign state_xor = state_data ^ state_key[79:16]; 

  //2. Замена
  always_comb begin
    for(int i = 0; i < 16; i = i + 1) sbox_out[4*i +: 4] = sbox_table(state_xor[4*i +: 4]);
  end

  //3. Перестановка
  always_comb begin
    for(int i = 0; i < 63; i = i + 1) begin
      next_data[(16*i) % 63] = sbox_out[i];
    end
    next_data[63] = sbox_out[63];
  end

  //4. Мутация ключа
  always_comb begin
    next_key = {state_key[18:0], state_key[79:19]};
    next_key[79:76] = sbox_table(next_key[79:76]);
    next_key[19:15] = next_key[19:15] ^ count;
  end
  
  //FSM
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      state_data <= 0; state_key <= 0; count <= 1;
      cr_inf.cr_ready <= 1;
    end else begin
      case(state)
        IDLE: begin
          if(cr_inf.cr_start) begin
            state_data <= cr_inf.cr_data; state_key <= cr_inf.cr_key;
            state <= WORK;
          end
          cr_inf.cr_ready <= 0;
        end
        WORK: begin
          if(count < 32) begin
            state_data <= next_data;
            state_key <= next_key;
            count <= count + 1;
          end else begin
            count <= 1;
            state_data <= state_data ^ state_key[79:16];
            state <= DONE;
          end
        end
        DONE: begin
          cr_inf.cr_wdata <= state_data;
          cr_inf.cr_ready <= 1;
          state <= IDLE;
        end
      endcase
    end
  end
endmodule
