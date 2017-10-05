;+
;This program takes a variable and sets zero values to the minimum
;nonzero value not NaN's though. Hacked from
;thm_spec_lim4overplot.pro, to account for problems in solar wind mode
;for probes B and C where there are short intervals with much larger
;energy ranges, which make for ugly plotting. In this case, if the
;value for ymin or ymax are present for less than 1 hour total,
;(actually 1/24 of the total number of time intervals) then ignore
;those values.
Pro thm_esa_lim4overplot, var, trange, zmin = zmin, zmax = zmax, zlog = zlog, $
                          ymin = ymin, ymax = ymax, ylog = ylog, $
                          overwrite = overwrite, _extra = _extra
;Version:
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-05-01 15:47:29 -0700 (Mon, 01 May 2017) $
; $LastChangedRevision: 23257 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_esa_lim4overplot.pro $
;-
  If(keyword_set(zmin)) Then zmin0 = zmin Else zmin0 = 0
  If(keyword_set(zmax)) Then zmax0 = zmax Else zmax0 = 0
  If(keyword_set(zlog)) Then zlog0 = zlog Else zlog0 = 0
  If(keyword_set(ymin)) Then ymin0 = ymin Else ymin0 = 0
  If(keyword_set(ymax)) Then ymax0 = ymax Else ymax0 = 0
  If(keyword_set(ylog)) Then ylog0 = ylog Else ylog0 = 0

  zminv = zmin0 & zmaxv = zmax0
  yminv = ymin0 & ymaxv = ymax0

;First, ditch zero energy values, this has been moved from
;thm_gen_overplot.pro
  get_data, var, data = d, dlim = dl, lim = al

  tr = time_double(trange)
  If(is_struct(d)) Then Begin
;This needs to be done for data only in the original time interval
     ss = where(d.x Ge tr[0] And d.x lt tr[1], nss)
     If(nss Gt 0) Then Begin
        dvss = d.v[ss, *]
        minval = min(dvss) > 0.10
;0 energy values will not plot correctly, so
;reset any energy = 0 points to 0.01 eV
        xxx = where(dvss lt 1.0, nxxx)
        If(nxxx Gt 0) Then Begin
           dvss[xxx] = 0.01
           d.v[ss, *] = dvss
           store_data, var, data = d
        Endif
;Y min and max
        If(yminv Eq 0) Then Begin
           yminv = min(dvss, /nan) ;need /nan for IDL pre 8.5
;test for not many times at these
;values, only do this once, but have
;some margin
           ymin_all = fltarr(nss)
;           For j = 0, nss-1 Do ymin_all[j] = min(dvss[j, *])
           ymin_all = min(dvss, dimension = 2, /nan)
           ss_yminv = where(ymin_all Le 2*yminv, nss_yminv)
           frac_ymin = float(nss_yminv)/nss
           If(frac_ymin Lt 1.0/24.0) Then Begin
              ss_not_yminv = where(ymin_all Gt 2.0*yminv, nss_not_yminv)
              If(nss_not_yminv Gt 0) Then yminv = min(ymin_all[ss_not_yminv])
           Endif
        Endif
        If(ymaxv Eq 0) Then Begin
           ymaxv = max(dvss, /nan)
           ymax_all = fltarr(nss)
;           For j = 0, nss-1 Do ymax_all[j] = max(dvss[j, *])
           ymax_all = max(dvss, dimension = 2, /nan)
           ss_ymaxv = where(ymax_all Ge ymaxv/2.0, nss_ymaxv)
           frac_ymax = float(nss_ymaxv)/nss
           If(frac_ymax Lt 1.0/24.0) Then Begin
              ss_not_ymaxv = where(ymax_all Lt ymaxv/2.0, nss_not_ymaxv)
              If(nss_not_ymaxv Gt 0) Then ymaxv = max(ymax_all[ss_not_ymaxv])
           Endif
        Endif
     Endif
;Z min and max
     vlv = where(finite(d.y) And (d.y Ne 0), nvlv)
     If(nvlv Gt 0) Then Begin
        If(zminv Eq 0) Then zminv = min(d.y[vlv], /nan)
        If(zmaxv Eq 0) Then zmaxv = max(d.y[vlv], /nan)
        y0 = where(d.y Eq 0, ny0)
        If(ny0 Gt 0) Then d.y[y0] = zminv
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

