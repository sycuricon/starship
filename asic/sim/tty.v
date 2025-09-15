//  Copyright (c) by Ando Ki.
module tty #(parameter BAUD_RATE  = 115200, LOOPBACK=1)
(
   output  reg   STX,
   input   wire  SRX,
   input   wire  reset
);
   integer uart_file_desc;
   reg tick = 0;

   initial begin
     uart_file_desc = $fopen({`TOP_DIR, "/log/tty.log"}, "w");
   end

   localparam INTERVAL = (100000000/BAUD_RATE); // nsec

   reg [7:0] data  = 0;
   initial begin STX = 1'b1; end

   always @ (negedge SRX) begin
      if (!reset) begin
        tick = 1;
        #(100) tick = 0;
        receive(data);
        $write("%c", data); 
        $fflush();
        $fdisplay(uart_file_desc, "%c", data) ;
        $fflush();
        if (LOOPBACK) send(data);
      end
   end

   task receive;
        output [7:0] value;
        integer      x;
   begin
          #(INTERVAL*1.5 - 100);
          for (x=0; x<8; x=x+1) begin // LSB comes first
                  tick = 1;
                  #(100) tick = 0;
                  value[x] = SRX;
                  #(INTERVAL-100);
          end
   end
   endtask

   task send;
        input [7:0] value;
        integer     y;
   begin
        STX = 1'b0;
        #(INTERVAL);
        for (y=0; y<8; y=y+1) begin // LSB goes first
           STX = value[y];
           #(INTERVAL);
        end
        STX = 1'b1;
        #(INTERVAL);
   end
   endtask
endmodule
