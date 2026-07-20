;+
;PROCEDURE:   binhex
;PURPOSE:
;  Takes a signed or unsigned integer or an array of bits and displays it
;  as binary, hex, and decimal. 
;
;USAGE:
;  binhex, i
;
;INPUTS:
;       i:         An integer scalar of any type up to 32 bits (signed or 
;                  unsigned).  The correct binary and hex will be displayed
;                  for both positive and negative integers.
;
;                  The input can also be an array of up to 32 bits (0 or 1),
;                  with MSB at index 0.  This allows you to type an array of
;                  bits in the same order that they would appear on a page.
;                  For example:
;
;                        binhex, [1,1,0,1,0,1,0,1]
;
;                  produces the following output (with MSB on the left):
;
;                          213 = D5 = 1 1 0 1 0 1 0 1
;
;                  Note that nibble.pro returns an array of bits with LSB at
;                  index 0, so you must reverse the output of nibble as an
;                  input to binhex:
;
;                        binhex, reverse(nibble('D5'x))
;                          213 = D5 = 1 1 0 1 0 1 0 1
;
;                  When an array of bits represents a signed integer, there
;                  is an ambiguity since binhex does not know the data type.
;                  For example:
;
;                                     MSB                             LSB
;                      65533 = FF FD = 1 1 1 1 1 1 1 1 - 1 1 1 1 1 1 0 1
;                         -3 = FF FD = 1 1 1 1 1 1 1 1 - 1 1 1 1 1 1 0 1
;
;                  Use keyword SIGNED to interpret the array of bits as a
;                  signed integer (INT, LONG).  Otherwise, it will be 
;                  interpreted as an unsigned integer (BYTE, UINT, ULONG).
;                  See explanation of SIGNED below.
;
;KEYWORDS:
;    SIGNED:       Set this keyword if the input array of bits represents a
;                  signed integer.  The number of bits determines whether
;                  the data type is INT (<= 16 bits) or LONG (> 16 bits).
;
;                  Any unspecified bits are assumed to be zero, which means
;                  that MSB will be zero, and the result will be positive.
;                  For example:
;
;                     i = [1,0,1,1]  ; interpreted as [0,0,0,0,1,0,1,1]
;                     binhex, i
;                       11 = 0B = 0 0 0 0 1 0 1 1
;                     binhex, i, /signed
;                       11 = 0B = 0 0 0 0 1 0 1 1
;
;                     i = [1,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1]
;                     binhex, i
;                       32779 = 80 0B = 1 0 0 0 0 0 0 0 - 0 0 0 0 1 0 1 1
;                     binhex, i, /signed
;                      -32757 = 80 0B = 1 0 0 0 0 0 0 0 - 0 0 0 0 1 0 1 1
;
;                  If not set, the input is assumed to be unsigned.
;
;SEE ALSO:
;    nibble:       Converts an integer into an N-element byte array where the
;                  elements are the individual bits (0 or 1).  LSB is stored 
;                  in element 0, and MSB is stored in element N-1.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-07-15 15:57:23 -0700 (Wed, 15 Jul 2026) $
; $LastChangedRevision: 34644 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/binhex.pro $
;
;CREATED BY:	David L. Mitchell  June 2011
;-
pro binhex, k, signed=signed

; Determine whether i is an integer scalar or an array of bits

  i = k
  sz = size(i)
  n = sz[n_elements(sz)-1]  ; number of elements
  t = sz[n_elements(sz)-2]  ; data type

  if (t eq 0) then begin
    print, "binhex: you must input an integer"
    return
  endif

  if ((t gt 3) and (t lt 12)) then begin
    print, "binhex: only integers"
    return
  endif

; Convert array of bits into an integer

  if (n gt 1) then begin
    if (n gt 32) then begin
      print, "binhex: too many bits (32 max)"
      return
    endif
    indx = where((i lt 0) or (i gt 1), count)
    if (count gt 1) then begin
      print, "binhex: bits must be 0 or 1"
      return
    endif
    p = reverse(2UL^(ulindgen(n)))
    x = ulong(i[n-1])
    for j=(n-2),0,-1 do x += ulong(i[j])*p[j]
    if keyword_set(signed) then begin
      if ((n eq 16) && i[0]) then x = long(x) - 65536L
      if ((n eq 32) && i[0]) then x = long(long64(x) - 4294967296LL)
    endif
    i = x
  endif

; Output i as decimal, hex, and binary

  if ((abs(i) lt 256UL) and (i ge 0)) then begin
    j = byte(i)
    bits = reverse(nibble(j))
    print,i,j,bits,format='(i4," = ",Z2.2," =",8(i2))'
    return
  endif

  if (abs(i) lt 65536UL) then begin
    j = uint(i)
    bits = reverse(nibble(j))
    bytes = ishft(j,[-8,0]) mod 256
    print,i,bytes,bits,format='(i6," = ",2(Z2.2," "),"=",8(i2)," -",8(i2))'
    return
  endif

  if (abs(i) le 4294967295ULL) then begin
    j = ulong(i)
    bits = reverse(nibble(j))
    bytes = ishft(j,[-24,-16,-8,0]) mod 256
    print,i,bytes,bits,format='(i11," = ",4(Z2.2," "),"=",3(8(i2)," -"),8(i2))'
    return
  endif

  print, "Integer too big!"

end
