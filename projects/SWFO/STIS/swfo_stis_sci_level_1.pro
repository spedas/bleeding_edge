; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-09-02 01:50:30 -0700 (Thu, 02 Sep 2021) $
; $LastChangedRevision: 30277 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_1.pro $

function  swfo_stis_sci_find_peaks,d,cbins,window = wnd,threshold=threshold
  nan = !values.d_nan
  peak = {a:nan, x0:nan, s:nan}
  if n_params() eq 0 then return,peak
  if not keyword_set(cbins) then cbins = dindgen(n_elements(d))

  if keyword_set(wnd) then begin
    mx = max(d,b)
    i1 = (b-wnd) > 0
    i2 = (b+wnd) < (n_elements(d)-1)
    ;    dprint,wnd
    pk = swfo_stis_sci_find_peaks(d[i1:i2],cbins[i1:i2],threshold=threshold)
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

function  swfo_stis_sci_find_peak,d,cbins,window = wnd,threshold=threshold
  nan = !values.d_nan
  peak = {a:nan, x0:nan, s:nan}
  if n_params() eq 0 then return,peak
  if not keyword_set(cbins) then cbins = dindgen(n_elements(d))

  if keyword_set(wnd) then begin
    mx = max(d,b)
    i1 = (b-wnd) > 0
    i2 = (b+wnd) < (n_elements(d)-1)
    ;    dprint,wnd
    pk = swfo_stis_sci_find_peak(d[i1:i2],cbins[i1:i2],threshold=threshold)
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



function swfo_stis_sci_level_1,strcts,format=format

  output = !null
  nd = n_elements(strcts)
  for i=0l,nd-1 do begin
    str = strcts[i]

    duration = str.duration
    p= replicate(swfo_stis_sci_find_peak(),2)   ; this is experimental

    res = 3
    sci_per =  1; str.noise_period
    sci_scale = 1.
    d = str.counts * 1.
;printdat,str
; printdat,noise_scale

    x = findgen(256)   * sci_scale
    for j=0,n_elements(p)-1 do begin
      p[j] = swfo_stis_sci_find_peak(d,x,window=2)
    endfor

    dprint,dlevel=4,p.s
    
    period = .87  ; approximate period (in seconds) of Version 64 FPGA
    rate  = str.counts/(str.duration * period) 

    sci = {  $
      time: str.time, $
      ;   met: str.met, $
      ;   tdiff: str.time_diff, $
      integration_time : duration * period, $
      ;   ccode:ccode,  $
      ;mapid:mapid,  $
      ;sci_per:noise_per,  $
      ;noise_res:noise_res,  $
      tot:p.a  ,            $
      x0:p.x0  ,  $
      sigma:p.s,  $
      ;   data:d, $
      ;    cfactor:cfactor, $
      valid:1 , $
      counts: str.counts,  $
      rate : rate , $
      gap: str.gap  }
      
    if nd eq 1 then   return, sci
    if i  eq 0 then   output = replicate(sci,nd) else output[i] = sci 

  endfor

  return,output
    
end


; 
; dat_l1 = swfo_stis_noise_level_1( nse.data.array)
; store_data,'nse_',data=dat_l1,tagnames='*'
