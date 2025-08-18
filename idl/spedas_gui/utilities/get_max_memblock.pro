;+
;NAME:
; get_max_memblock.pro
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
;
;OUTPUT:
; Size of largest contiguous memory block available to IDL in megabytes.
; 
;-

function get_max_memblock

compile_opt idl2, hidden

MB = 2L^20  ; one megabyte
cblockSize = MB * 2047  ; two gigabytes

; Error handler
catch, err

; decrease size of biggest block if unable to allocate byte array below
if (err ne 0) then cBlockSize = cBlockSize - MB

wait, 0.0001  ; give user a chance to cntrl-break in windows

; if no error from trying to allocate byte array, then we've found the largest
; free block
memoryPointer = ptr_new(bytarr(cBlockSize, /nozero), /no_copy)
maxBlockSize = ishft(cBlockSize, -20)
 
ptr_free, memoryPointer

return, maxBlockSize

end
