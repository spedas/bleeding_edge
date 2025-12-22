pro annotate_modebar,SDT = sdt

if keyword_set(sdt) then begin
    bq = 'fields_modebar'
endif else begin
    bq = 'MODEBAR'
endelse

charsize = 0.9
xlegend = [1.,1.]*(!x.crange(1)+.01*(!x.crange(1)-!x.crange(0)))
ylegend = [0,1.5]
legend=['fast','slow']

if find_handle(bq) ne 0 then begin
    get_data,bq,data=mbar,dlimit=mbardlim
    tplot_panel,variable=bq,deltatime=dt
    xyouts,xlegend,ylegend,legend,/data, $
      color=bytescale(mbardlim.colors,range=mbardlim.zrange), $
      charsize=charsize
endif else begin
    message,'Modebar has not yet been stored...call ' + $
      'LOAD_FIELDS_MODEBAR first...',/continue
    return
endelse

return
end
        
