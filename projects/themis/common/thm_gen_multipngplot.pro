;+
;NAME:
; thm_gen_multipng_plot
;PURPOSE:
; Creates full day, 6 hour and 2 hour png files for data for a given
; day, Note that the data must have already been plotted for this
; routine to work properly. It calls tplot without arguments.
;CALLING SEQUENCE:
; thm_gen_multipng_plot, filename_proto, date, directory=directory
;INPUT:
; filename_proto = the first part of the eventual filename, e.g.,
;                  'tha_l2_overview', dates and times are appended to
;                  make up the full filename
; date = the date for the data
;OUTPUT:
; png files, with names directory+filename_proto+yyddmm_hshf.png,
; where hshf refers to start and end hours for the plot.
;KEYWORDS:
; directory = the output directory, remember the trailing slash....
; vars24 = the variable names to plot for the full 24hr plot, the
;          default is to call tplot without any inputs
; vars06 = the variable names to plot for the 6hr plots, the
;          default is to call tplot without any inputs
; vars02 = the variable names to plot for the 2hr plots, the
;          default is to call tplot without any inputs
;HISTORY:
; 21-may-2008, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: nikos $
; $LastChangedDate: 2015-03-26 11:16:29 -0700 (Thu, 26 Mar 2015) $
; $LastChangedRevision: 17191 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_gen_multipngplot.pro $
;-
Pro thm_gen_multipngplot, filename_proto, date0, directory = directory, $
                          vars24 = vars24, vars06 = vars06, vars02 = vars02, $
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
  If(keyword_set(vars24)) Then tplot, vars24, trange=tr24 Else tplot,trange=tr24
  makepng,dir+filename_proto+'_'+ymd+'_0024',/no_expose,_extra = _extra
;six-hour plots
  For j = 0, 3 Do Begin
    hrs0 = 6*j
    hrs1 = 6*j+6
    tr0 = date_double+3600.0d0*[hrs0, hrs1]
    If(keyword_set(vars06)) Then tplot, vars06, trange = tr0 $
    Else tplot, trange = tr0
    hshf = string(hrs0, format = '(i2.2)')+string(hrs1, format = '(i2.2)')
    makepng, dir+filename_proto+'_'+ymd+'_'+hshf, /no_expose, _extra = _extra
  Endfor
;two-hour plots
  For j = 0, 11 Do Begin
    hrs0 = 2*j
    hrs1 = 2*j+2
    tr0 = date_double+3600.0d0*[hrs0, hrs1]
    If(keyword_set(vars02)) Then tplot, vars02, trange = tr0 $
    Else tplot, trange = tr0
    hshf = string(hrs0, format = '(i2.2)')+string(hrs1, format = '(i2.2)')
    makepng, dir+filename_proto+'_'+ymd+'_'+hshf, /no_expose, _extra = _extra
  Endfor
;reset the time range to the full day
  tlimit, 0, 0
  Return
End
