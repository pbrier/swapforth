\ SPI functions
\ p.brier@pbrier.nl

\ Uses port $0008 bits:
\   bit 0       CS
\   bit 1       MOSI
\   bit 2       SCK
\ and port $2000:
\   bit 2       MISO
\
   
\ 8 bit SPI Exchange (dout -- din)
: spix
     8 lshift
     8 0 do
       dup 0< 2 and            \ extract MS bit
       dup 8 io!               \ lower SCK, update MOSI        
       4 + 8 io!               \ raise SCK
       1 lshift                \ next bit
       $2000 io@ 4 and +       \ read MISO, accumulate
     loop
     2 rshift
;
: spi~  5 8 io! ; \ Deassert CS, Clock high ( -- )
: >spi  spix drop ;   \ write to SPI ( data -- )
: spi>  0 spix ;      \ read from SPI ( -- data )
: <spi> 0 spix drop ; \ dummy SPI write ( -- )


\ Micron N25Q032A SPI flash driver
\ winbond w25qxxx SPI flash functions
: fl_up spi~ $ab >spi <spi> <spi> <spi> spi> spi~ ; \ Wake up from powerdown ( -- ID )
: fl_mid $4b >spi <spi> <spi> <spi> spi> spi> spi~ ; \ Read ID ( -- MFG_ID DEV_ID)
: fl_uid $4b >spi <spi> <spi> <spi> <spi> 8 0 do spi> loop spi~ ; \ Read 64bit unique ID ( -- ID0 .. ID8)
: fl_jid $9f >spi spi> spi> spi> spi~ ; \ read Jedec ID ( -- capacity memtype manufacturer )
: fl_st1 $05 >spi spi> spi~ ; \ read status register 1 ( -- status )
: fl_st2 $35 >spi spi> spi~ ; \ read status register 2 ( -- status )
: fl_we $06 >spi spi~ ; \ set write enable ( -- )
: fl_wd $04 >spi spi~ ; \ set write disable ( -- )
: fl_ce fl_we $c7 >spi spi~ ; \ chip erase ( -- )
: fl_se fl_we $20 >spi dup 8 rshift $ff and >spi $ff and >spi spi~ ; \ sector erase ( addess[16:0] address[23:16 -- )
: fl_wait begin fl_st1 0 = until ; \ wait for end of write/erase ( -- )


\ read (n addess[16:0] address[23:16] -- data-n data-0)
: fl_read 
  $03 >spi 
  >spi 
  dup 8 rshift $ff and >spi  
  $ff and >spi 
  0 do spi> loop 
  spi~ 
; 

\ write ( d1 d2 .. dn n addess[16:0] address[23:16] -- )
: fl_write 
  fl_we
  $02 >spi 
  >spi 
  dup 8 rshift $ff and >spi  
  $ff and >spi 
  0 do >spi loop 
  spi~ 
; 








