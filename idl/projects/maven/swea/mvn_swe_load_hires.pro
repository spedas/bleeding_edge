;+
;PROCEDURE:   mvn_swe_load_hires
;PURPOSE:
;  Restores SWEA hires data from save files.
;
;USAGE:
;  mvn_swe_load_hires
;
;INPUTS:
;       None.
;
;KEYWORDS:
;       TRANGE:    Time range to load, in any format accepted by time_double().
;                  If only one time is provided, one UT day of data is loaded
;                  that includes the time specified.
;
;                  If not specified, get the time range from the tplot common
;                  block (via timespan).
;
;       TPLOT:     Make a time series plot of the result.  Default = 1 (yes).
;
;       NOGUFF:    Don't ask questions; just do whatever this procedure thinks
;                  is necessary.  This may include (re-)initializing SPICE.
;
;NOTE: This procedure supercedes swe_restore_hires.pro.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-10-26 11:35:20 -0700 (Mon, 26 Oct 2026) $
; $LastChangedRevision: 35008 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_load_hires.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_swe_load_hires.pro
;-
pro mvn_swe_load_hires, trange=trange, tplot=tplot, noguff=noguff

  doplot = (n_elements(tplot) gt 0) ? keyword_set(tplot) : 1
  noguff = keyword_set(noguff)

; Initialize the environment and restore the data

  case n_elements(trange) of
      0  : ; do nothing -> get time range from tplot
      1  : timespan, time_string(trange, prec=-3), 1
    else : timespan, minmax(time_double(trange))
  endcase

  tplot_options, get=topt
  str_element, topt, 'trange_full', trange
  if (max(trange) eq 0D) then begin
    print, "You must supply a time range."
    return
  endif

  mvn_spice_stat, check=trange, summary=sinfo, /silent
  if (~sinfo.all_check) then begin
    yn = 'Y'
    if (~noguff) then begin
      print,"  SPICE not initialized or insufficient coverage."
      read, yn, prompt='  Initialize SPICE now (y|n) ? ', format='(a1)'
    endif
    if (strupcase(yn) eq 'Y') then begin
        tstart = time_string(min(trange) - 86400D, prec=-3)
        tstop = time_string(max(trange) + (2D*86400D), prec=-3)
        mvn_swe_spice_init, trange=[tstart,tstop], /force
        mvn_spice_stat, check=trange, summary=sinfo, /silent
    endif
  endif

  if (~sinfo.all_check) then begin
    print,"  Error initializing SPICE."
    return
  endif

  maven_orbit_tplot, /load

; Restore the data

  path = 'maven/data/sci/swe/l3/hires/YYYY/MM/'
  sname = 'swe_hires_YYYYMMDD.sav'
  sfile = mvn_pfp_file_retrieve(path+sname,trange=trange,/daily_names,/valid)
  indx = where(sfile ne '', count)
  case (count) of
      0  : return
      1  : mvn_swe_restore, file=sfile[indx]
    else : begin
             print,"  This routine can only process one file at a time."
             return
           end
  endcase

  tname = 'swe_hires_YYYYMMDD.tplot'
  tfile = mvn_pfp_file_retrieve(path+tname,trange=trange,/daily_names,/valid)
  indx = where(tfile ne '', count)
  case (count) of
      0  : return
      1  : tplot_restore, file=tfile[indx]
    else : begin
             print,"  This routine can only process one file at a time."
             return
           end
  endcase

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

    pans = ['mvn_swics_en_eflux','mvn_B_full_maven_mso','mvn_sun_bar',$
           'mvn_att_bar','swe_a3_bar',padpans,'TABNUM','swe_a4']
    tplot_options,'var_label',['alt','sza','lat']
    options,'alt','ytitle','ALT'
    options,'sza','ytitle','SZA'
    options,'lat','ytitle','LAT'
    tplot, pans
  endif

end
