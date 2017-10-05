
pro spp_swp_reduce,tof_range=tof_range,tof_name=tof_name

  res =5.

  if 0 then begin
     reduce_timeres_data,'spp_spanai_rates_*CNTS',res ;,trange=tr
     get_data,'spp_spanai_rates_VALID_CNTS_t',data=d1
     get_data,'spp_spanai_rates_START_CNTS_t',data=d3
     get_data,'spp_spanai_rates_STOP_CNTS_t',data=d4
     dr =d1
     dr.y = d1.y/(d1.y+d3.y)
     store_data,'valid_start',data=dr
     dr.y = d1.y/(d1.y+d4.y)
     store_data,'valid_stop',data=dr
     dr.y = (d1.y+d3.y)/(d1.y+d4.y)
     store_data,'start_stop',data=dr
     dr.y = (d1.y+d4.y)/(d1.y+d3.y)
     store_data,'stop_start',data=dr
  endif
  
  if 1 then begin
     spp_apid_data,'3b9'x,apdata=ap
     a = *ap.dataptr
     for ch = 0 ,15 do begin
        test = a.channel eq ch
        if n_elements(tof_range) eq 2 then $
           test = test and $(a.tof le tof_range[1] and a.tof ge tof_range[0])
        w = where(test,nw)
        colors = bytescale(findgen(16))
        ;dl = {psym:3, colors=0}
        name =string(ch,format='("spanai_ch",i02,"_")')
        if keyword_set(tof_name) then name += tof_name+'_'
        if nw ne 0 then $
           store_data,name,data=a[w],tagnames='*',$
                      dlim={TOF:{psym:3,symsize:.4,colors:colors[ch] }}
        h=histbins(a[w].time,tb,binsize=double(res))
        store_data,name+'TOT',tb,h,dlim={colors:colors[ch]}
     endfor
     store_data,'spanai_all_TOT',data='spanai_ch??_TOT'

  endif

end


