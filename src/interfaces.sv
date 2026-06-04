//Интерфейс связи с процессором
interface core_intf();
  logic sel, enable, write;
  logic[7:0] addr; //Адрес
  logic[31:0] wdata; //Данные для записи
  logic[31:0] rdata; //Данные для чтения
  logic ready;

  modport apb_slave(
    input sel, enable, write, addr, wdata;
    output rdata, ready;
  );

  modport core(
    input rdata, ready;
    output sel, enable, write, addr, wdata;
  );
endinterface

//Интерфейс связи с криптоядром
interface crypto_intf();
  logic[63:0] cr_wdata; //Зашифрованные данные от криптоядра
  logic cr_ready; //Флаг готовности данных от криптоядра
  logic[63:0] cr_rdata; //Данные для чтения криптоядром
  logic[79:0] cr_key; //Ключ
  logic cr_start //Старт работы криптоядра

  modport apb_slave(
    input cr_wdata, cr_ready;
    output cr_rdata, cr_key, cr_start;
  );

  modport crypto_core(
    output cr_wdata, cr_ready;
    input cr_rdata, cr_key, cr_start;
  );
endinterface
