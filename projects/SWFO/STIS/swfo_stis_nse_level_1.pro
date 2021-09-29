; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-08-29 01:21:13 -0700 (Sun, 29 Aug 2021) $
; $LastChangedRevision: 30266 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_nse_level_1.pro $

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



function swfo_stis_nse_level_1,strcts,format=format

  output = !null
  nd = n_elements(strcts)
  for i=0l,nd-1 do begin
    str = strcts[i]

    ddata = str.nhist
    duration = 0u
    p= replicate(swfo_stis_nse_find_peak(),6)

    noise_res = str.noise_res 
    noise_scale = 2.^(fix(str.noise_res) - 3)
    noise_per = str.noise_period
;printdat,str
; printdat,noise_scale

    x = (findgen(10)-4.5)   * noise_scale
    d = reform(ddata,10,6)
    for j=0,5 do begin
      p[j] = swfo_stis_nse_find_peak(d[*,j],x)
      ;  p[j] = swfo_stis_find_peak(d[0:8,j],x[0:8])   ; ignore end channel
    endfor

    dprint,dlevel=4,p.s
    mapid = 3
    str_element,str,'mapid',mapid

    noise = {  $
      time: str.time, $
      ;   met: str.met, $
      ;   tdiff: str.time_diff, $
      duration: duration, $
      ;   ccode:ccode,  $
      ;mapid:mapid,  $
      noise_per:noise_per,  $
      noise_res:noise_res,  $
      tot:p.a  ,            $
      baseline:p.x0  ,  $
      sigma:p.s,  $
      ;   data:d, $
      ;    cfactor:cfactor, $
      valid:1 , $
      gap: str.gap  }
      
    if nd eq 1 then   return, noise
    if i  eq 0 then   output = replicate(noise,nd) else output[i] = noise 
      
  endfor
  
  return,output
end


; 
; dat_l1 = swfo_stis_noise_level_1( nse.data.array)
; store_data,'nse_',data=dat_l1,tagnames='*'
