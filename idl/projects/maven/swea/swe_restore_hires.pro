;+
;PROCEDURE:   swe_restore_hires
;PURPOSE:
;  Restores SWEA hires data from save files.
;
;USAGE:
;  swe_restore_hires
;
;INPUTS:
;       date:      Date to restore, in any format accepted by time_double().
;                  Only the date (YYYY-MM-DD) is used; HH:MM:SS are ignored.
;
;KEYWORDS:
;       TPLOT:     Make a time series plot of the result.  Default = 1 (yes).
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-12-04 14:59:15 -0800 (Thu, 04 Dec 2025) $
; $LastChangedRevision: 33902 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_restore_hires.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: swe_restore_hires.pro
;-
pro swe_restore_hires, date, tplot=tplot

  doplot = (n_elements(tplot) gt 0) ? keyword_set(tplot) : 1

; Determine the save filenames from the date

  if (size(date,/type) eq 0) then begin
    print,"You must supply a date."
    return
  endif

  date = time_double(date)
  day = round(date[sort(date)]/86400D, /L64)  ; round time(s) to nearest day
  date = time_string(day*86400LL, prec=-3)
  yyyymmdd = strmid(date[0],0,4) + strmid(date[0],5,2) + strmid(date[0],8,2)
  path = root_data_dir() + 'maven/data/sci/swe/l3/hires/'
  fname = path + 'swe_hires_' + yyyymmdd

; Initialize the environment and restore the data

  timespan, date
  mvn_swe_spice_init, /force
  maven_orbit_tplot, /load

  sfile = fname + '.sav'
  finfo = file_info(sfile)
  if ~finfo.exists then begin
    print,"Save file not found: ",sfile
    return
  endif
  mvn_swe_restore, file=sfile

  tfile = fname + '.tplot'
  finfo = file_info(tfile)
  if ~finfo.exists then begin
    print,"Tplot save file not found: ",tfile
    return
  endif
  tplot_restore, file=tfile

; Determine which hires energies are present

  padpans = ['']
  morepadpans = padpans

  i = find_handle('swe_pad_resample_200eV_merge')
  if (i gt 0) then begin
    padpans = [padpans, 'swe_pad_resample_200eV_merge', 'flux_200a']
    morepadpans = [morepadpans, 'flux_200', 'flux_200n']
  endif

  i = find_handle('swe_pad_resample_50eV_merge')
  if (i gt 0) then begin
    padpans = [padpans, 'swe_pad_resample_50eV_merge', 'flux_50a']
    morepadpans = [morepadpans, 'flux_50', 'flux_50n']
  endif

  i = find_handle('swe_pad_resample_125eV_merge')
  if (i gt 0) then begin
    padpans = [padpans, 'swe_pad_resample_125eV_merge', 'flux_125a']
    morepadpans = [morepadpans, 'flux_125', 'flux_125n']
  endif

  if (n_elements(padpans) eq 1) then begin
    print,"Crikey!  I restored the data but can't find any hires variables at 50, 125, or 200 eV."
    return
  endif

  padpans = padpans[1:*]
  morepadpans = morepadpans[1:*]

; Plot the data

  if (doplot) then begin
    device, window_state=wstate
    tplot_options, get=topt
    str_element, topt, 'window', Twin, success=ok
    if (not ok) then if (!d.window ge 0) then Twin = !d.window else Twin = 0
    if (wstate[Twin]) then wset,Twin else win,Twin,/f

    pans = ['mvn_swics_en_eflux','mvn_mag_l1_bamp','mvn_B_full_maven_mso','mvn_sun_bar',$
           'mvn_att_bar','swe_a3_bar',padpans,'TABNUM','swe_a4']
    tplot_options,'var_label',['alt','sza','lat']
    options,'alt','ytitle','ALT'
    options,'sza','ytitle','SZA'
    options,'lat','ytitle','LAT'
    tplot, pans
  endif

end
