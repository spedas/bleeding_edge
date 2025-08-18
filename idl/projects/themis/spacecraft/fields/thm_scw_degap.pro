;+
;NAME:
; thm_scw_degap
;PURPOSE:
; Helper function for thm_cal_scm, this interpolates over short gaps
; in wave burst data, this is the default for L1 SCM data input
; as of 2020-05-18. Previously temp_scw_degap.pro
;INPUT:
; probe = ['a','b','c','d','e']
;KEYWORDS:
; max_degap_dt = maximum size for degap, the default is 0.20 seconds
;HISTORY:
; Originally temp_scw_degap, from 2014, renamed 2020-05-18
;$LastChangedBy: jimm $                                                          
;$LastChangedDate: 2020-05-18 12:57:52 -0700 (Mon, 18 May 2020) $               
;$LastChangedRevision: 28710 $                                                  
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_scw_degap.pro $
;-
Pro thm_scw_degap, probe, max_degap_dt = max_degap_dt, suffix = suffix, _extra = _extra

;Need hed and dq data
  If(is_string(suffix)) Then sfx = suffix[0] Else sfx = ''
  vh = 'th'+probe+'_scw_hed' ;no suffix on header variable
  vardq = 'th'+probe+'_scw_dq'+sfx
  get_data, vh, data = a
  If(~is_struct(a)) Then Return
  TMrate = 2.^(reform(a.y[*, 14]/16b)+1)
  If(max(tmrate) Ne 8192.0 Or min(tmrate) Ne 8192.0) Then Return ;only good for 8192.0
  get_data, vardq, data = dq
  If(~is_struct(dq)) Then Return
  xdq = dq.x & ydq = dq.y & vdq = dq.v
;hmmm
  dt0 = 1.0/8192.0
  var = 'th'+probe+'_scw'+sfx
  get_data, var,  data = d
  dt = d.x[1:*]-d.x
  If(keyword_set(max_degap_dt)) Then dt00 = max_degap_dt Else dt00 = 0.20
  ppp = where(dt lt dt00 And dt gt dt0)
  If(ppp[0] Eq -1) Then Return
  nppp = n_elements(ppp)
  x = d.x & y = d.y & v = d.v
;We will assume xdq=x here
  If(total(abs(xdq-x)) Gt 0) Then Return
  For j = 0, nppp-1 Do Begin
;the gap is between ppp[j] and ppp[j]+1
    dtj = x[ppp[j]+1]-x[ppp[j]]
    nfill = long(dtj/dt0)
    If(nfill Eq 1) Then Begin
        print, 'Gap of:'+string(dtj)+' seconds at time:'
        print, time_string(x[ppp[j]])
        print, 'Too small to fill'
        Continue                ;don't fill this small of a gap
    Endif

    tj = x[ppp[j]]+dt0*lindgen(nfill+1)
;The end points have data
    yj = intarr(nfill+1, 3)
    yj[0, *] = y[ppp[j], *]
    yj[nfill, *] = y[ppp[j]+1, *]
    ydqj = intarr(nfill+1, 2)
    ydqj[0, *] = ydq[ppp[j], *]
    ydqj[nfill, *] = ydq[ppp[j]+1, *]
    print, 'INTERPOLATED SCW:'
    For k = 0, 2 Do Begin
      yj[*, k] = interpol([yj[0, k], yj[nfill, k]], $
                           [tj[0], tj[nfill]], tj)
    Endfor
    For k = 0, 1 Do ydqj[*, k] = ydqj[0, k]
;append to the x and y arrays, we'll sort later
    x = [x, tj[1:nfill-1]]
    y = [y, yj[1:nfill-1, *]]
    xdq = [xdq, tj[1:nfill-1]]
    ydq = [ydq, ydqj[1:nfill-1, *]]
    print, time_string(tj[0], precision = 6)
    print, time_string(tj[nfill], precision = 6)
  Endfor

;Done, now sort in time
  ssx = bsort(x)
  x = x[ssx]
  y = y[ssx, *]
  xdq = xdq[ssx]
  ydq = ydq[ssx, *]
  store_data, var, data = {x:x, y:y, v:v}
  store_data, vardq, data = {x:xdq, y:ydq, v:vdq}

  Return
End
