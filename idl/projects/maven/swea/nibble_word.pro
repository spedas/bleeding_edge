;+
;FUNCTION:   nibble_word
;PURPOSE:
;  Converts an unsigned int into a 16-element byte array where the 
;  elements are the individual bits (0 or 1).  LSB is stored in 
;  element 0 and MSB is in element 15.  Note: if this function is 
;  fed a long, then it processes only the least significant word 
;  without crashing.  No error checking for maximum speed.
;
;  DEPRECIATED: Use nibble instead.
;
;USAGE:
;  bits = nibble_word(word)
;INPUTS:
;       word : A unsigned integer scalar.
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-07-15 16:04:00 -0700 (Wed, 15 Jul 2026) $
; $LastChangedRevision: 34645 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/nibble_word.pro $
;
;CREATED BY:	David L. Mitchell  01-15-98
;-
function nibble_word, word

  print, "Depreciated: use nibble instead."
  return, byte(ishft(word,-indgen(16)) mod 2B)

end
