;+
;NAME:
;     mms_gen_multipng_plot
;PURPOSE:
;     Creates full day, 6 hour and 2 hour png files for data for a given
;     day.
; 
;     IMPORTANT NOTE: unlike the THEMIS version, this routine 
;       will probably not work properly if called without arguments;
;       please set the vars24, vars06 and vars02 keywords to the tvars
;       to include in the plot
;     
;CALLING SEQUENCE:
;     mms_gen_multipng_plot, filename_proto, date, directory=directory
;INPUT:
;     filename_proto = the first part of the eventual filename, e.g.,
;                  'tha_l2_overview', dates and times are appended to
;                  make up the full filename
;     date = the date for the data
;OUTPUT:
;     png files, with names directory+filename_proto+yyddmm_hshf.png,
;     where hshf refers to start and end hours for the plot.
;KEYWORDS:
;     directory = the output directory, remember the trailing slash....
;     vars24 = the variable names to plot for the full 24hr plot
; 
;     vars12 = the variable names to plot for the 12hr plots
;
;     vars06 = the variable names to plot for the 6hr plots
; 
;     vars02 = the variable names to plot for the 2hr plots
; 
;HISTORY:
; 14-july-2016, egrimes, forked for MMS QL plots
; 21-may-2008, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-07-26 15:49:12 -0700 (Tue, 26 Jul 2016) $
; $LastChangedRevision: 21547 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/quicklook/mms_gen_multipngplot.pro $
;-
Pro mms_gen_multipngplot, filename_proto, date0, directory = directory, $
                          vars24 = vars24, vars06 = vars06, vars02 = vars02, vars12 = vars12, $
                          burst_bar=burst_bar, fast_bar=fast_bar, window=win_idx, $
                          _extra = _extra

;No Error checking, Let this crash...
  date = time_string(date0)
  year = strmid(date, 0, 4)
  month = strmid(date, 5, 2)
  day = strmid(date, 8, 2)
  ymd = year+month+day

  date_double = time_double(date[0])
  if keyword_set(directory) then begin
    dir = directory[0]
    dir = strtrim(dir, 2)
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Ne '/' And ll Ne '\') Then dir = dir+'/'
  endif else dir = './'
;Full day plot
  tr24 = date_double+3600.0d0*[0, 24]
  If(keyword_set(vars24)) Then mms_tplot_quicklook, vars24, trange=tr24, burst_bar=burst_bar, fast_bar=fast_bar, window=win_idx $
     Else mms_tplot_quicklook,trange=tr24, burst_bar=burst_bar, fast_bar=fast_bar, window=win_idx
  makepng,dir+filename_proto+'_'+ymd+'_0024',/no_expose,_extra = _extra
;twelve-hour plots
  For j = 0, 1 Do Begin
    hrs0 = 12*j
    hrs1 = 12*j+12
    tr0 = date_double+3600.0d0*[hrs0, hrs1]
    If(keyword_set(vars12)) Then mms_tplot_quicklook, vars12, trange = tr0, burst_bar=burst_bar, fast_bar=fast_bar, window=win_idx $
    Else mms_tplot_quicklook, trange = tr0, burst_bar=burst_bar, fast_bar=fast_bar, window=win_idx
    hshf = string(hrs0, format = '(i2.2)')+string(hrs1, format = '(i2.2)')
    makepng, dir+filename_proto+'_'+ymd+'_'+hshf, /no_expose, _extra = _extra
  Endfor
;six-hour plots
  For j = 0, 3 Do Begin
    hrs0 = 6*j
    hrs1 = 6*j+6
    tr0 = date_double+3600.0d0*[hrs0, hrs1]
    If(keyword_set(vars06)) Then mms_tplot_quicklook, vars06, trange = tr0, burst_bar=burst_bar, fast_bar=fast_bar, window=win_idx $
    Else mms_tplot_quicklook, trange = tr0, burst_bar=burst_bar, fast_bar=fast_bar, window=win_idx
    hshf = string(hrs0, format = '(i2.2)')+string(hrs1, format = '(i2.2)')
    makepng, dir+filename_proto+'_'+ymd+'_'+hshf, /no_expose, _extra = _extra
  Endfor
;two-hour plots
  For j = 0, 11 Do Begin
    hrs0 = 2*j
    hrs1 = 2*j+2
    tr0 = date_double+3600.0d0*[hrs0, hrs1]
    If(keyword_set(vars02)) Then mms_tplot_quicklook, vars02, trange = tr0, burst_bar=burst_bar, fast_bar=fast_bar, window=win_idx $
    Else mms_tplot_quicklook, trange = tr0, burst_bar=burst_bar, fast_bar=fast_bar, window=win_idx
    hshf = string(hrs0, format = '(i2.2)')+string(hrs1, format = '(i2.2)')
    makepng, dir+filename_proto+'_'+ymd+'_'+hshf, /no_expose, _extra = _extra
  Endfor
;reset the time range to the full day
  tlimit, 0, 0
  Return
End
