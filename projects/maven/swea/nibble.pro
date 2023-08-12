;+
;FUNCTION:   nibble
;PURPOSE:
;  Converts a byte, integer, long, or long64 into an N-element
;  byte array where the elements are the individual bits (0 or 1).
;  LSB is stored in element 0, and MSB is stored in element N-1.
;
;  Normally, one would decompose an unsigned integer into its bits,
;  where each bit provides the on/off state of some flag or switch.
;  However, it also works on signed integers, which introduces an
;  ambiguity, for example:
;
;    65533 = FF FD = 1 1 1 1 1 1 1 1 - 1 1 1 1 1 1 0 1
;       -3 = FF FD = 1 1 1 1 1 1 1 1 - 1 1 1 1 1 1 0 1
;
;  When using signed integers, the interpretation of the result is
;  left to the user!
;
;USAGE:
;  bits = nibble(i)
;
;INPUT:
;       i  : A scalar of type byte, integer, long, or long64.
;            Can be signed or unsigned.
;
;OUTPUT:
;     bits : An N-element byte array, where N = 8, 16, 32, or 64,
;            depending on the input data type.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-11 09:09:54 -0700 (Fri, 11 Aug 2023) $
; $LastChangedRevision: 31985 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/nibble.pro $
;
;CREATED BY:	David L. Mitchell,  January 1998
;-
function nibble, i

  case size(i,/type) of
      1  : nbits = 8   ; byte
      2  : nbits = 16  ; int
      3  : nbits = 32  ; long
     12  : nbits = 16  ; uint
     13  : nbits = 32  ; ulong
     14  : nbits = 64  ; long64
     15  : nbits = 64  ; ulong64
    else : begin
             print,"nibble: argument must be an integer"
             return, -1
           end
  endcase

  return, byte(ishft(i,-indgen(nbits)) mod 2B)

end
