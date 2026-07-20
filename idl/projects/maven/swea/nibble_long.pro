;+
;FUNCTION:   nibble_long
;PURPOSE:
;  Converts an unsigned long into a 32-element byte array where the 
;  elements are the individual bits (0 or 1).  LSB is stored in 
;  element 0 and MSB is in element 32.  No error checking for maximum 
;  speed.
;
;  DEPRECIATED: Use nibble instead.
;
;USAGE:
;  bits = nibble_long(lword)
;INPUTS:
;       lword : A unsigned long scalar.
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-07-15 16:04:00 -0700 (Wed, 15 Jul 2026) $
; $LastChangedRevision: 34645 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/nibble_long.pro $
;
;CREATED BY:	David L. Mitchell  02-06-11
;-
function nibble_long, lword

  print, "Depreciated: use nibble instead."
  return, byte(ishft(lword,-indgen(32)) mod 2B)

end
