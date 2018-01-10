\ spi flash test functions 
\ p.brier@pbrier.nl
\ requires: spi.fs flash.fs
\

\ enable flash
fl_up

\ test ID functions
fl_up .x
fl_mid .x .x
fl_jid .x .x .x 
fl_uid .x .x .x .x .x .x .x .x

\ test read status
fl_st1 .x
fl_st2 .x



\ test read functions
fl_up
create buffer 16 cells allot 
buffer 8 0 0 fl_read

: hexdump 0 do buffer i 2 * + @ .x loop ;
: fl_dump 0 do buffer 8 i 8 * 0 fl_read cr 8 hexdump loop ; 
200 fl_dump



\ test write
fl_ce fl_wait
\ : write_test 0 do $10 $20 $30 $40 4  i 4 * 0 fl_write fl_wait loop ;
\ 10 write_test
\ 8 fl_dump
