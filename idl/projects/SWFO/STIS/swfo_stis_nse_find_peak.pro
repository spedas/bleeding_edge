; $LastChangedBy: ali $
; $LastChangedDate: 2022-08-05 15:12:17 -0700 (Fri, 05 Aug 2022) $
; $LastChangedRevision: 31000 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_nse_find_peak.pro $

function  swfo_stis_nse_find_peak,d,cbins,window = wnd,threshold=threshold
  nan = !values.d_nan
  peak = {a:nan, x0:nan, s:nan}
  if n_params() eq 0 then return,peak
  if not keyword_set(cbins) then cbins = dindgen(n_elements(d))

  if keyword_set(wnd) then begin
    mx = max(d,b)
    i1 = (b-wnd) > 0
    i2 = (b+wnd) < (n_elements(d)-1)
    ;    dprint,wnd
    pk = swfo_stis_nse_find_peak(d[i1:i2],cbins[i1:i2],threshold=threshold)
    return,pk
  endif
  if keyword_set(threshold) then begin
    dprint,'not functioning'
  endif

  t = total(d)
  avg = total(d * cbins)/t
  sdev = sqrt(total(d*(cbins-avg)^2)/t)
  peak.a=t
  peak.x0=avg
  peak.s=sdev
  return,peak
end