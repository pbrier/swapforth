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
\ ADRESS  0010: address 
\ ADDRESS 0020: data
\ ADDRESS 0040: control {A17, A16, SRAM_nOE, SRAM_nWE, SRAM_DIR}, DIR=1 ==> OUTPUT
\ WRITE: Set nWE LOW, data dir to output, set data, set address, set nWE HIGH (on /WE low --> /WE high), data is clocked in
\ READ: Set data dir to input, set address, CS=LOW, read data 

\  write: data adress --
: sramw
$10 io!
$20 io!
$4 $0040 io!
$5 $0040 io!
$6 $0040 io!
$4 $0040 io!
;

\ read: address -- data
: sramr
$0010 io!
$6 $0040 io!
$0020 io@
$4 $0040 io!
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








