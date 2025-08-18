;+
;NAME:
;tres
;PURPOSE:
;returns the time resolution of a tplot variable, defined as the
;median value of the differences between time values from the data
;points, e.g. median(d.x[1:*]-d.x). Also will return a measure of how
;useful this value is, e.g. what fraction of the points are within 10%
;of the median value. Can be used for multiple variables.
;CALLING SEQUENCE:
; tres, tplot_var, delta_t, confidence = confidence, $
;                           closeto_fraction = closeto_fraction
;INPUT:
; tplot_var = a tplot variable name or number
;OUTPUT:
; delta_t = the time resolution, a median value. If the data variable
;           does not exist, or does not return a median, then the
;           result is -1
;KEYWORDS:
; confidence = the fraction of dt values that are close to (within
;              a certain percentage) of the returned value. A bad
;              value of this would make this not a good measure of the
;              time resolution of the full sample, and you may want
;              to work in batches.
; close_fraction = the fractional value that the values of time
;                    interval sizes need to be close to the median
;                    value to be called 'close'. E.g., values are
;                    considered close to the median if the value is 
;                    greater than 1-close_fraction and less than
;                    1+close_fraction times the median. The default
;                    is 0.01. 
; tplot_var_out = A set of tplot variable names, that correspond to
;                 the values of delta_t and confidence level if there
;                 are multiple tplot variables input as a globbed
;                 string or array.
;EXAMPLE:
; For THEMIS ESA data:
; 
; timespan, '2010-11-26'
; thm_load_esa,probe='a',level='l2',datatype='*velocity*gsm'
; tres, 'tha_pe??_velocity_gsm', delta_t, confidence = c, $
;       tplot_var_out = tplot_var_out
; For k = 0, n_elements(delta_t)-1 Do print, delta_t[k], c[k], '  ', tplot_var_out[k]
;       97.020038     0.765714  tha_peif_velocity_gsm
;       3.0318751     0.990622  tha_peef_velocity_gsm
;       3.0318747     0.999575  tha_peir_velocity_gsm
;       3.0318747     0.999647  tha_peer_velocity_gsm
;       3.0318732     0.991525  tha_peib_velocity_gsm
;       3.0318732     0.988764  tha_peeb_velocity_gsm
;
; For most of the datatypes the median value is ok, but the time
; resolution of the PEIF data varies for different modes, so this 
; is not a good resolution for that variable.
;
;HISTORY:
; 2018-11-26, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2018-11-26 14:59:03 -0800 (Mon, 26 Nov 2018) $
; $LastChangedRevision: 26176 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tres.pro $
;-
Pro tres, tplot_v, delta_t, confidence = confidence, $
          close_fraction = close_fraction, $
          tplot_var_out = tplot_v1, $
          _extra = _extra

;check input variables
  delta_t = -1
  tplot_v1 = tnames(tplot_v)
  If(~is_string(tplot_v1)) Then Begin
     dprint, 'Variable: '+string(tplot_v)+' Not Found'
     Return
  Endif
;For multiple tnames, call it recursively
  nv1 = n_elements(tplot_v1)
  If(nv1 Gt 1) Then Begin
     delta_t = dblarr(nv1)
     confidence = fltarr(nv1)
     For j = 0, nv1-1 Do Begin
        tres, tplot_v1[j], dtj, confidence = cj, $
              close_fraction = close_fraction, $
              _extra = _extra
        delta_t[j] = dtj & confidence[j] = cj
     Endfor
     Return
  Endif
;Only one variable, check the keyword    
  If(keyword_set(close_fraction)) Then ct = close_fraction $
  Else ct = 0.01
  If(ct Gt 1.0 Or ct Le 0.0) Then Begin
     dprint, 'Invalid close_fraction: '+string(ct)
     Return
  Endif
  
  get_data, tplot_v1, data = d
;The assumption is that d.x is monotonically increasing, but
;we'll insert a warning
  dt = d.x[1:*]-d.x
  oops = where(dt Lt 0.0, noops)
  If(noops gt 0) Then $
     dprint, 'Warning: data is not monotonic, '+tplot_v1
;median and confidence  
  delta_t = median(dt)
  cdt = ct*delta_t
  okv = where(dt Gt delta_t-cdt And dt Lt delta_t+cdt, nokv)
  confidence = float(nokv)/n_elements(dt)
;done
End
