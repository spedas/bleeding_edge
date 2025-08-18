;+
;NAME:
;	bits2
;PURPOSE:
;	Given a byte or integer, return a vector of 8 or 16 values
;	which are the binary representation of the value.
;INPUT:
;	invalue	- The byte or integer value to check
;OUTPUT:
;	bitarr	- The 8-element array with values set
;		  if the bit is set
;HISTORY:
;	Written 19-dec-1996, RAS after BITS by M.Morrison
;	but correcting negative integer problems and returning
;	32 byte arrays for longwords regardless of maximum value
;	17-feb-2001 loop index long.
;       9-apr-2009, jmm, replaced datatype call with size and case
;       statement hacked from bitplot.pro
;	
;-

PRO BITS2, invalue, BITARR, qprint

;
if (n_elements(qprint) eq 0) then qprint = 0
;
n = n_elements(invalue)
Case size(invalue, /type) of
    1:  nbit = 8
    2:  nbit = 16
    3:  nbit = 32
    12: nbit = 16
    13: nbit = 32
    14: nbit = 64
    15: nbit = 64
    Else: nb = 0
Endcase
bitarr = bytarr(nbit, n)
for i = 0L, n-1 do begin
    bitarr[0,i] = ishft( invalue(i), -indgen(nbit)) and 1b
    if qprint eq 1 then $
      print,string(/print, long(invalue(i)))+'  =  '+$
      string(/print,bitarr(nbit-1-indgen(nbit),i),format='(4(1x,4i1,1x,4i1))')
endfor

;

end
