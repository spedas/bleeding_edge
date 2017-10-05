;+
;FUNCTION:   nibble
;PURPOSE:
;  Converts a byte into an 8-element byte array where the elements are
;  the individual bits (0 or 1).  LSB is stored in element 0 and MSB is
;  in element 7.  Note: if this function is fed an integer or a long,
;  then it processes only the least significant byte without crashing.
;  No error checking for maximum speed.
;USAGE:
;  bits = nibble(byte)
;INPUTS:
;       byte : A byte scalar.
;KEYWORDS:
;CREATED BY:	David L. Mitchell  01-15-98
;FILE:  nibble.pro
;VERSION:  1.2
;LAST MODIFICATION:  01-31-98
;-
function nibble, byte

  return, ishft(byte,-indgen(8)) mod 2B

end
