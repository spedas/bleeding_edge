;+
;FUNCTION:   nibble_word
;PURPOSE:
;  Converts an unsigned int into a 16-element byte array where the 
;  elements are the individual bits (0 or 1).  LSB is stored in 
;  element 0 and MSB is in element 15.  Note: if this function is 
;  fed a long, then it processes only the least significant word 
;  without crashing.  No error checking for maximum speed.
;USAGE:
;  bits = nibble_word(word)
;INPUTS:
;       word : A unsigned integer scalar.
;KEYWORDS:
;CREATED BY:	David L. Mitchell  01-15-98
;FILE:  nibble.pro
;VERSION:  1.2
;LAST MODIFICATION:  01-31-98
;-
function nibble_word, word

  return, byte(ishft(word,-indgen(16)) mod 2B)

end
