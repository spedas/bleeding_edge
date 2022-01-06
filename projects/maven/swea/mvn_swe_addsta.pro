;+
;PROCEDURE:   mvn_swe_addsta
;PURPOSE:
;  Loads STATIC data and creates tplot variables using STATIC code.
;  By default APID's c0, c6, and ca are loaded.  This is sufficient
;  to generate energy and mass spectra.  Optionally, you can also 
;  load additional APID's.
;
;USAGE:
;  mvn_swe_addsta
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;    APID:          Additional APID's to load.  This procedure always 
;                   loads c0, c6, and ca.  For example, set this keyword
;                   to 'd0' (4D distributions) or 'd1' (4D distributions,
;                   burst) in order to calculate velocity distributions.
;
;    POTENTIAL:     Estimate the spacecraft potential from STATIC data.
;
;    PANS:          Named variable to hold an array of the tplot
;                   variable(s) created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-01-03 10:05:18 -0800 (Mon, 03 Jan 2022) $
; $LastChangedRevision: 30486 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addsta.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addsta, apid=apid, potential=potential, pans=pans, iv_level=iv_level

  dopot = keyword_set(potential)
  if (size(iv_level,/type) eq 0) then iv_level=0

; Load STATIC data

  sta_apid = ['c0','c6','c8','ca']
  if (size(apid,/type) eq 7) then sta_apid = [sta_apid, apid]
  sta_apid = sta_apid[uniq(sta_apid, sort(sta_apid))]

  mvn_sta_l2_load, sta_apid=sta_apid, iv_level=iv_level
  mvn_sta_l2_tplot,/replace
  
  pans = ['']
  
  get_data, 'mvn_sta_c0_E', index=i
  if (i gt 0) then begin
    pans = [pans, 'mvn_sta_c0_E']
    ylim,'mvn_sta_c0_E',4e-1,4e4
    options,'mvn_sta_c0_E','ytitle','sta c6!CEnergy!CeV'
  endif

  get_data, 'mvn_sta_c6_M', index=i
  if (i gt 0) then begin
    pans = [pans, 'mvn_sta_c6_M']
    options,'mvn_sta_c6_M','ytitle','sta c6!CMass!Camu'
  endif

  if (dopot) then begin
    get_data, 'mvn_sta_c6_scpot', index=i
    if (i eq 0) then mvn_sta_l2scpot
  endif

  if (n_elements(pans) gt 1) then pans = pans[1:*]

  return
  
end
