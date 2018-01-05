\ olimex Ice40 HX1k example with j1a 16bit SwapForth processor 
\ pbrier@pbrier.nl

\ display button io state as hex 
: .buttons
begin
  $2000 io@ .x
again
;

\ display dio3 istate as hex 
: .dio3
begin
  $0001 io@
  .x
again
;

\ output buttons to leds and terminal
: .bleds
begin
  $2000 io@
  2 rshift
  3 xor
  dup .x
  $0004 io!
again
;


\ test the digital outputs, generate square wave on each pin, D0=max freq, D1=Fmax/2 .. D15=Fmax/2^15
: testio
$ffff 2 io!
begin
  65535 0 do
    i 1 io!
  loop
again
;

\ write data to external SRAM
\ ADRESS  0010: data (i/o)
\ ADDRESS 0020: data (dir)
\ ADDRESS 0040: address & CS/R/W {SA12, SA11, SA10, SA9, SA8, SA7, SA6, SA5, SA4, SA3, SA2, SA1, SA0, SRAM_nOE, SRAM_nWE, SRAM_nCS}
\ WRITE: Set data dir to output, keep CS LOW, set data, set address, on (/WE low --> /WE high), data is clocked in
\ READ: Set data dir to input, set address, CS=LOW, read data 

\  write: data adress --
: sramw
swap
$FFFF $0020 io! 
$0006 $0040 io!
$0010 io!
dup
3 lshift $0004 or $0040 io! 
3 lshift $0006 or $0040 io! 
;

\ read: address -- data
: sramr
$0000 $0020 io! 
3 lshift 2 or $0040 io!
$0010 io@
;


$11 1 sramw
$22 2 sramw
$33 3 sramw
1 sramr .x
2 sramr .x
3 sramr .x

: sram_fill
$FFF 0 do
  i dup dup sramw
  .x
loop
;
sram_fill

: sram_check
$FFF 0 do
  i sramr .x
loop ;
sram_check

words








