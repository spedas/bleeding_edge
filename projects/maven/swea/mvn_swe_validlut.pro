;+
;FUNCTION:   mvn_swe_validlut
;PURPOSE:
;  Checks for valid sweep lookup tables (LUTs).  The valid
;  tables are: 3, 5 and 6.  Table 3 is primary during cruise,
;  and was superceded by table 5 during transition on Oct. 6,
;  2014.  Table 6 is very similar to 5, except that it enables
;  V0.
;
;  The high resolution tables (7 and 8) do not comform to the
;  PDS archive specification and will need to be handled
;  separately.
;
;USAGE:
;  valid = mvn_swe_validlut(lut)
;
;INPUTS:
;   lut:       Sweep table number.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-03-15 16:32:12 -0700 (Fri, 15 Mar 2019) $
; $LastChangedRevision: 26830 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_validlut.pro $
;
;CREATED BY:    David L. Mitchell  02-01-15
;FILE: mvn_swe_validlut.pro
;-
function mvn_swe_validlut, lut

  if (size(lut,/type) eq 0) then return, 0
  return, (lut eq 3B) or (lut eq 5B) or (lut eq 6B)

end
