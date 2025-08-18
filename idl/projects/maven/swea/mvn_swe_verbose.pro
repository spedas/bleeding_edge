;+
;PROCEDURE:   mvn_swe_verbose
;PURPOSE:
;  Sets the SWEA verbosity level.
;
;USAGE:
;  mvn_swe_verbose, level
;
;INPUTS:
;
;    level:         Verbosity level (0 = suppress most messages).
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-10-02 16:48:57 -0700 (Mon, 02 Oct 2017) $
; $LastChangedRevision: 24094 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_verbose.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_swe_verbose, level, getlev=getlev

  @mvn_swe_com

  if (size(swe_verbose,/type) eq 0) then swe_verbose = 0
  if (size(level,/type) gt 0) then swe_verbose = fix(level)
  getlev = swe_verbose

  return

end
