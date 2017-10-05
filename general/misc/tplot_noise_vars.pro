;+
;NAME:
; tplot_noise_vars
;PURPOSE:
; generate Nvars tplot variables, with random noise for testing 
;CALLING SEQUENCE:
; tplot_names = tplot_noise_vars(nvars = nvars, time = time, $
;               nchan = nchan, ncounts = ncounts)
;INPUT:
; none explicit
;OUTPUT:
; tplot_names = an array of tplot names: 'test_var_nnnnnn', starting
; just after the highest value i.e., if you just created variable 99,
; then the first new variable will be variable 100. use del_data if
; you want to recreate variables
;KEYWORDS:
; nvars = number of variables, the default is 100, max is 999999L
; time = a time array, the default is systime()+indgen(3600), one hour
;        starting now. 
; nchan = number of channels in data, the default is 16
; ncounts = number of counts per channel, the output data is poisson
;           distributed given the number of counts. The default is 1
;           count per channel.
; nostore =  if set, don't create the variables, for testing
;HISTORY:
; 2017-08-24, jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: jimm $
;$LastChangedDate: 2017-08-25 10:52:03 -0700 (Fri, 25 Aug 2017) $
;$LastChangedRevision: 23830 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tplot_noise_vars.pro $
;-
Function tplot_noise_vars, nvars = nvars, time = time, $
                           nchan = nchan, ncounts = ncounts, $
                           nostore = nostore, _extra = _extra

  If(~keyword_set(nvars)) Then nvars = 1000L
  If(~keyword_set(time)) Then time = systime(/sec)+dindgen(3600.0)
  If(~keyword_set(nchan)) Then nchan = 16
  If(keyword_set(ncounts)) Then Begin
     If(n_elements(ncounts) Eq nchan) Then spec0 = ncounts $
     Else spec0 = fltarr(nchan)+ncounts[0]
  Endif Else spec0 = fltarr(nchan)+1.0
;create variables 1 by 1
  tn = tnames('test_var_*')
  If(is_string(tn)) Then Begin
     ntn = n_elements(tn)
     tmp = strsplit(tn[ntn-1], '_', /extract)
     j0 = long(tmp[2])+1
  Endif Else j0 = 0L
  v = findgen(nchan)
  varnames = 'test_var_'+string(j0+indgen(nvars), format = '(i6.6)')
  ntimes = n_elements(time)
  y = fltarr(ntimes, nchan) 
  t0 = systime(/sec)
  For j = 0, nvars-1 Do Begin
     For i = 0, nchan-1 Do y[*, i] = randomu(seed, ntimes, poisson = spec0[i])
     If(~keyword_set(nostore)) Then store_data, varnames[j], data = {x:time, y:y, v:v}
  Endfor
  If(~keyword_set(nostore)) Then Begin
     If(nchan gt 6) Then options, varnames, 'spec', 1, /default
     options, varnames, 'ytitle', 'counts', /default
  Endif
  dt = systime(/sec)-t0
  message, /info, ' Took: '+string(dt)+' seconds for: '+string(nvars)+' variables'
  Return, dt
End

     
