;+
;PROCEDURE:   swe_load_hires
;PURPOSE:
;  Special purpose loading routine for hires SWEA and MAG data.
;
;  First loads 32-Hz MAG data and determines the SCLK kernel version used to 
;  produce the data.  Next, SPICE is initialized using the same SCLK kernel, 
;  even if it's not the latest.  This ensures that MAG and SWEA data are 
;  synchronized to the millisecond level.  Next, SWEA data are loaded and 
;  inspected for hires data (tables 7, 8 and 9).  If hires data are found,
;  the flux method is used to determine the table number for each SPEC data 
;  product (see mvn_swe_getlut).  A summary plot is made with diagnostics
;  for the flux method, and the program exits.  At this point, the user should
;  inspect and correct any table assignment errors (see mvn_swe_fixlut).
;
;  The next step is performed by a separate routine: swe_make_hires.
;
;USAGE:
;  swe_load_hires, date
;
;INPUTS:
;       date:      Date to process, in any format accepted by time_double().
;                  Only the date (YYYY-MM-DD) is used; HH:MM:SS are ignored.
;
;KEYWORDS:
;       none
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-12-02 13:37:37 -0800 (Tue, 02 Dec 2025) $
; $LastChangedRevision: 33889 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_load_hires.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: swe_load_hires.pro
;-
pro swe_load_hires, date

  if (size(date,/type) eq 0) then begin
    print,"You must supply a date."
    return
  endif

; Load 32-Hz MAG data

  timespan, date
  mvn_mag_load, 'L2_FULL', sclk=sclk  ; get kernel used to produce MAG data
  get_data,'mvn_B_full',alim=lim
  maglev = strupcase(lim.level)
  mvn_swe_spice_init, sclk=sclk       ; same kernel used to produce MAG data
  maven_orbit_tplot, /load
  eph = maven_orbit_eph()
  mvn_mag_geom, var='mvn_B_full'
  mvn_mag_tplot, 'mvn_B_full_maven_mso'
  options,'mvn_mag_bamp','ytitle','|B| (nT)!c' + maglev
  options,'mvn_mag_l1_bamp','ysubtitle',''
  options,'mvn_B_full_maven_mso','ytitle','B (nT)!c' + maglev + ' MSO'
  options,'mvn_B_full_maven_mso','ysubtitle',''

; Load SWEA data

  mvn_swe_load_l0, /hires
  mvn_swe_sumplot, /loadonly, /lut
  get_data, 'TABNUM', data=tab, index=i  ; table number vs time
  if (i eq 0) then begin
    print,"Tplot variable TABNUM not found."
    return
  endif
  indx = where(tab.y gt 6, count)
  if (count eq 0L) then begin
    print,"No hires data."
    return
  endif

  print,""
  print,"Number of hires spectra: " + strtrim(string(count),2)
  print,""
  pans = ['alt2','hiav','loav','cratio','TABNUM','swe_a4']
  tplot, pans

end
