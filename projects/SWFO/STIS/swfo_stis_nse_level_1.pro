; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-03-13 02:11:23 -0700 (Mon, 13 Mar 2023) $
; $LastChangedRevision: 31620 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_nse_level_1.pro $

function swfo_stis_nse_level_1,strcts,format=format

  output = !null
  nd = n_elements(strcts)
  for i=0l,nd-1 do begin
    str = strcts[i]

    ddata = str.histogram
    p= replicate(swfo_stis_nse_find_peak(),6)

    noise_scale = 2.^(fix(str.noise_res) - 3)
    ;printdat,str
    ;printdat,noise_scale

    x = (findgen(10)-4.5) * noise_scale
    d = reform(ddata,10,6)
    for j=0,5 do begin
      ;p[j] = swfo_stis_nse_find_peak(d[*,j],x)
        p[j] = swfo_stis_nse_find_peak(d[0:8,j],x[0:8])   ; ignore end channel
    endfor

    dprint,dlevel=4,p.s
    mapid = 3
    str_element,str,'mapid',mapid

    noise = {  $
      time: str.time, $
      ;met: str.met, $
      ;tdiff: str.time_diff, $
      duration: str.duration, $
      ;ccode:ccode,  $
      ;mapid:mapid,  $
      noise_period:str.noise_period,  $
      noise_res:str.noise_res,  $
      total:p.a  ,            $
      baseline:p.x0  ,  $
      sigma:p.s,  $
      ;data:d, $
      ;cfactor:cfactor, $
      valid:1 , $
      gap: str.gap  }

    if nd eq 1 then   return, noise
    if i  eq 0 then   output = replicate(noise,nd) else output[i] = noise

  endfor

  return,output
end
