

function mav_sep_noise_decom,msg,hkppkt=hkp,last_noise=last
    if msg.valid eq 0 then return, 0
    lastdata =keyword_set(last) ? last.data : 0u
    ddata = msg.data - lastdata
    noise_res = keyword_set(hkp) ? hkp.noise_res   : 0b
    noise_per = keyword_set(hkp) ? hkp.noise_per   : 0b
    noise_flags=keyword_set(hkp) ? hkp.noise_flags : 0u

    p= replicate(find_peak(),6)
    
    x = (dindgen(10)-4.5) * ( 2d ^ (noise_res-3))
    d = reform(ddata,10,6)
    for j=0,5 do begin
;        p[j] = find_peak(d[*,j],x)
        p[j] = find_peak(d[0:8,j],x[0:8])   ; ignore end channel
    endfor
    sepnoise = {time    :    msg.time,      $
             flags      :   noise_flags   ,  $
             res        :   noise_res                 ,  $
             per        :   noise_per   ,  $
             tot        :   p.a  ,$
             baseline   :   p.x0 ,$
             sigma      :   p.s  ,$
             ddata      :   ddata,  $
             eff        :   p.a * (noise_per #  replicate(1,6)),   $
             data       :   msg.data    }
   if (abs(msg.time - systime(1)) lt 10) && scope_level() le 7 then begin
;        printdat,scope_level()
        ps = get_plot_state()
        wi,6
        cols = [1,2,3,4,0,6]
        plot,sepnoise.ddata,psym=10
        for i=0,5 do oplot,[10,10]*i+4,[0,200],col=cols[i]
        restore_plot_state,ps
   endif
   return,sepnoise
end

