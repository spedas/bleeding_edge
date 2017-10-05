;+
;This program takes a variable and sets zero values to the minimum
;nonzero value -- not NaN's though
Pro thm_spec_lim4overplot, var, zmin = zmin, zmax = zmax, zlog = zlog, $
                           ymin = ymin, ymax = ymax, ylog = ylog, $
                           overwrite = overwrite, _extra = _extra
;Version:
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-05-01 15:47:29 -0700 (Mon, 01 May 2017) $
; $LastChangedRevision: 23257 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_spec_lim4overplot.pro $
;-
  If(keyword_set(zmin)) Then zmin0 = zmin Else zmin0 = 0
  If(keyword_set(zmax)) Then zmax0 = zmax Else zmax0 = 0
  If(keyword_set(zlog)) Then zlog0 = zlog Else zlog0 = 0
  If(keyword_set(ymin)) Then ymin0 = ymin Else ymin0 = 0
  If(keyword_set(ymax)) Then ymax0 = ymax Else ymax0 = 0
  If(keyword_set(ylog)) Then ylog0 = ylog Else ylog0 = 0

  zminv = zmin0 & zmaxv = zmax0
  yminv = ymin0 & ymaxv = ymax0
  get_data, var, data = d, dlim = dl, lim = al
  If(size(d, /type) Eq 8) Then Begin
    vlv = where(finite(d.y) And (d.y Ne 0), nvlv)
    If(nvlv Gt 0) Then Begin
       If(zminv Eq 0) Then zminv = min(d.y[vlv], /nan)
       If(zmaxv Eq 0) Then zmaxv = max(d.y[vlv], /nan)
       y0 = where(d.y Eq 0, ny0)
       If(ny0 Gt 0) Then Begin
          d.y[y0] = zminv
       Endif
    Endif
    If(tag_exist(d, 'v')) Then Begin
       If(yminv Eq 0) Then yminv = min(d.v, /nan)
       If(ymaxv Eq 0) Then ymaxv = max(d.v, /nan)
    Endif
  Endif
  If(keyword_set(overwrite)) Then varnew = var $
  Else varnew = var+'_limited'
  store_data, varnew, data = d, dlim = dl, lim = al
  zlim, varnew, zminv, zmaxv, zlog0
  ylim, varnew, yminv, ymaxv, ylog0
  options, varnew, 'ystyle', 1
  Return
End

