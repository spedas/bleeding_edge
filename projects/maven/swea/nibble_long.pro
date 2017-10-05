;+
;FUNCTION:   nibble_long
;PURPOSE:
;  Converts an unsigned long into a 32-element byte array where the 
;  elements are the individual bits (0 or 1).  LSB is stored in 
;  element 0 and MSB is in element 32.  No error checking for maximum 
;  speed.
;USAGE:
;  bits = nibble_long(lword)
;INPUTS:
;       lword : A unsigned long scalar.
;KEYWORDS:
;CREATED BY:	David L. Mitchell  02-06-11
;FILE:  nibble_long.pro
;VERSION:  1.0
;LAST MODIFICATION:  06-02-11
;-
function nibble_long, lword

  return, byte(ishft(lword,-indgen(32)) mod 2B)

end
