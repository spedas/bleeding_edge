;+
;FUNCTION:   mvn_swe_validlut
;PURPOSE:
;  Checks for valid sweep lookup tables (LUTs).  The valid
;  tables are: 3 (0xC0), 5 (0xCC) and 6 (0x82).  Table 3 is 
;  primary during cruise, and was superceded by table 5 during 
;  transition on Oct. 6, 2014.  Table 6 is very similar to 5, 
;  except that it enables V0.
;
;
;USAGE:
;  valid = mvn_swe_validlut(chksum)
;
;INPUTS:
;   chksum:    LUT checksum (see mvn_swe_sweep.pro)
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-01-09 16:37:53 -0800 (Mon, 09 Jan 2017) $
; $LastChangedRevision: 22543 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_validlut.pro $
;
;CREATED BY:    David L. Mitchell  02-01-15
;FILE: mvn_swe_validlut.pro
;-
function mvn_swe_validlut, chksum

  if (size(chksum,/type) eq 0) then return, 0
  return, (chksum eq 'C0'X) or (chksum eq 'CC'X) or (chksum eq '82'X)

end
