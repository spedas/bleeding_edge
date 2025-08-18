;+
;PROCEDURE:   mvn_swe_clear
;PURPOSE:
;  Clears the swe_dat common block.
;
;     swe_hsk:  slow housekeeping
;     a0:       3D survey
;     a1:       3D archive
;     a2:       PAD survey
;     a3:       PAD archive
;     a4:       ENGY survey
;     a5:       ENGY archive
;     a6:       fast housekeeping
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-03-15 16:00:57 -0700 (Fri, 15 Mar 2019) $
; $LastChangedRevision: 26826 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_clear.pro $
;
;CREATED BY:	David L. Mitchell  2013-07-26
;FILE:  mvn_swe_clear.pro
;-
pro mvn_swe_clear

  @mvn_swe_com

  a0 = 0
  a1 = 0
  a2 = 0
  a3 = 0
  a4 = 0
  a5 = 0
  a6 = 0

  pfp_hsk    = 0
  swe_hsk    = 0
  swe_3d     = 0
  swe_3d_arc = 0
  swe_mag1   = 0
  swe_mag2   = 0
  swe_sc_pot = 0

  mvn_swe_engy     = 0
  mvn_swe_engy_arc = 0
  
  mvn_swe_pad     = 0
  mvn_swe_pad_arc = 0

  swe_fpad        = 0
  swe_fpad_arc    = 0
  
  mvn_swe_3d     = 0
  mvn_swe_3d_arc = 0

  swe_chksum        = 0
  swe_active_chksum = 0

  swe_tabnum        = 0
  swe_active_tabnum = 0

  return

end
