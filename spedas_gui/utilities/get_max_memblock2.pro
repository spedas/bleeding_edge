;+
;NAME:
; get_max_memblock2.pro
; 
;PURPOSE:
; Returns size of largest contiguous block of memory available to IDL in
; megabytes.
; 
; This function is intended to be used as a guide to determine how much data
; can be stored in a single operation without IDL returning an "Unable to 
; allocate memory" error.  The block size returned is not necessarily the
; largest block in RAM.  It might be partially or completely located in virtual
; memory/disk swap space, in which case performance might suffer if that block
; is used.
; 
; Note that the returned value is only a snapshot in time.  Since other things
; can be going on with the OS and other applications, the size of the largest
; free memory block can increase or decrease in the time between calling this
; function and attempting to fill that block with data.  It is up to the
; programmer to decide what percentage of the returned value is safe to use.  
; 
;CALLING SEQUENCE:
; maxBlockSize = get_max_memblock()
; 
;INPUT:
; None
;KEYWORDS:
; maxblock_in = the size of the initial value of the max blocksize in
;               bytes, the default is 12 Gigabytes worth. Note that a
;               long64 integer is needed if the value is larger than 2
;               gBytes.
;OUTPUT:
; Size of largest contiguous memory block available to IDL in
; megabytes.
;Modification HISTORY:
; jmm, 3-feb-2009, hacked get_max_memblock--changed method to bisection
; 
;-

function get_max_memblock2, maxblock_in = maxblock_in

  compile_opt idl2, hidden

  MB = 2L^20                    ; one megabyte
  cblockSize = MB * 2047        ; two gigabytes
  If(keyword_set(maxblock_in)) Then maxblock = maxblock_in Else Begin
    maxblock = long64(cblockSize)*16 ;32 gigabytes
  Endelse
  minblock = MB
  midblock = maxblock           ;start by checking the max blocksize
  err = 0
; Error handler
  catch, err
; decrease size of midblock if unable to allocate byte array
  if(err ne 0) then begin
    maxblock = midblock
    midblock = (maxblock+minblock)/2L
  Endif
  wait, 0.0001          ; give user a chance to cntrl-break in windows

try_midblock:
  dprint,dlevel=4,  'Trying: ', 8*ishft(midblock, -20)
  memoryPointer = ptr_new(lon64arr(midblock, /nozero), /no_copy)
;If you're here, then midblock worked, so increase minblock to
;midblock and try again
  ptr_free, memoryPointer
  minblock = midblock
  If(maxblock Gt (minblock+2*MB)) Then Begin
    midblock = (maxblock+minblock)/2L
    Goto, try_midblock
  Endif Else Begin
;Keep the value of midblock that worked
    maxBlockSize = ishft(midblock, -20)
    return, 8*maxBlockSize
  Endelse

;You should never get here
  message, 'Failed....'

end
