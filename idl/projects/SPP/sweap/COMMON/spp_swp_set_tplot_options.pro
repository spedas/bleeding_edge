
pro spp_swp_set_tplot_options,spec=spec

  clog = keyword_set(spec)
  crange = [.9,5000.]
  if keyword_set(spec) then begin
     ylim,'*rate*CNTS',-1,16,0
     options,'*rates*CNTS',spec=1,ystyle=3,symsize=.5,zrange=crange
     ;options,'*rates*CNTS_t',labels='CH'+strtrim(indgen(16),2),$
     ;        labflag=-1,yrange=[.01,100],/ylog,ystyle=3,psym=-1,symsize=.5
  endif else begin
     ;ylim,'*rate*CNTS',1,1,1
     options,'*rates*CNTS',spec=0,yrange=crange,ylog=1,$
             ystyle=3,psym=-1,symsize=.5
     ;options,'*rates*CNTS_t',labels='CH'+strtrim(indgen(16),2),$
     ;        labflag=-1,yrange=[.01,100],/ylog,ystyle=3,psym=-1,symsize=.5
  endelse
  options,'*events*',psym=3,ystyle=3
  store_data,'log_MSG',dlimit=struct(tplot_routine='strplot')
  options,'*MON*',/ynozero
  tplot_options,'local_time',1
  tplot_options,'xtitle','Pacific Time'
  store_data,'STOP_SPEC',data='spp_spanai_rates_STOP_CNTS',$
             dlimit=struct(spec=1,yrange=[-1,16],zrange=[.5,500],$
                           /zlog,ylog=0,/no_interp)
  store_data,'START_SPEC',data='spp_spanai_rates_START_CNTS',$
             dlimit=struct(spec=1,yrange=[-1,16],zrange=[.5,500],$
                           /zlog,ylog=0,/no_interp)
  ;tplot,' *CMD_REC *rate*CNTS
  ;*ACC
  ;*MCP *events*
  ;log_MSG'

  if 0 then begin
     options,'spp_spane_spec_CNTS',spec=0,yrange=[1,1000],$
             ylog=1,colors='mbcgdr'
  endif else begin
     options,'spp_spane_spec_CNTS',spec=1,yrange=[0,17],$
             ylog=0,zrange=[1,500.],zlog=1
  endelse

end
