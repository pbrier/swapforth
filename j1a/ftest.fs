\ spi flash test functions 
\ p.brier@pbrier.nl
\ requires: spi.fs flash.fs
\
\ test read
8 0 0 fl_read .x .x .x .x .x .x .x .x 
8 1 0 fl_read .x .x .x .x .x .x .x .x 
8 2 0 fl_read .x .x .x .x .x .x .x .x 

8 $2ff 0 fl_read cr .x .x .x .x .x .x .x .x 
8 $300 0 fl_read cr .x .x .x .x .x .x .x .x 
8 $301 0 fl_read cr .x .x .x .x .x .x .x .x 
8 $302 0 fl_read cr .x .x .x .x .x .x .x .x 

\ test functions
: fl_dump 0 do 8 i 8 * 0 fl_read cr 8 i * .x .x .x .x .x .x .x .x .x loop ; 

\ test ID functions
fl_up .x
fl_mid .x .x
fl_jid .x .x .x 
fl_uid .x .x .x .x .x .x .x .x

\ test read status
fl_st1 .x
fl_st2 .x

\ test write
fl_ce fl_wait
: write_test 0 do $10 $20 $30 $40 4  i 4 * 0 fl_write fl_wait loop ;
10 write_test
8 fl_dump




