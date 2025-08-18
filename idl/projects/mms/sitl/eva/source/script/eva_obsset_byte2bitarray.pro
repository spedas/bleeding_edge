; This program returns a 4-element array from a BYTE value.
; If [1,0,0,0] was returned, it means MMS-1 is selected but not the other three observatories.
; If [1,0,0,1] was returned, MMS-1 and MMS-4 are selected.
;
; $LastChangedBy: moka $
; $LastChangedDate: 2023-08-21 20:46:44 -0700 (Mon, 21 Aug 2023) $
; $LastChangedRevision: 32050 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/script/eva_obsset_byte2bitarray.pro $
FUNCTION eva_obsset_byte2bitarray, x, str=str
  compile_opt idl2
  
  array = [0,1,2,3]
  bitarray = (x and 2^array)/2^(array)
  
  if keyword_set(str) then begin
    s1 = (bitarray[0] eq 1) ? '1' : '-'
    s2 = (bitarray[1] eq 1) ? '2' : '-'
    s3 = (bitarray[2] eq 1) ? '3' : '-'
    s4 = (bitarray[3] eq 1) ? '4' : '-'
    return, s1+s2+s3+s4
  endif else begin
    return, bitarray 
  endelse
END