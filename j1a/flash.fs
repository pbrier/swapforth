\
\ flash.fs
\ Micron N25Q032A SPI flash driver
\ Winbond w25qxxx SPI flash functions
\ Requires spi.fs
\ p.brier@pbrier.nl
\
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

: fl_read (addr n addess[16:0] address[23:16] -- )
  $03 >spi 
  >spi 
  dup 8 rshift $ff and >spi  
  $ff and >spi 
  0 do dup i 2 * + spi> swap ! loop 
  spi~ 
; 
 
: fl_write ( addr n addess[16:0] address[23:16] -- )
  fl_we
  $02 >spi 
  >spi 
  dup 8 rshift $ff and >spi  
  $ff and >spi 
  0 do dup i 2 * + @ >spi loop 
  spi~ 
; 

