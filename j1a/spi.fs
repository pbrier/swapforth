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









