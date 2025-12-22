pro mbar4particles,orbit
;
; get modebar from ac fields cdf by orbit number
;
load_fa_k0_acf,orbit=orbit
default_ac_limits
;
; load a blank bar if something goes wrong...
;
if find_handle('MODEBAR') eq 0 then begin
    get_data,'el_0',data=tmp
    
    mbardat = {x:tmp.x,y:bytarr(n_elements(tmp.x),3),v:bindgen(3)}
    store_data,'MODEBAR', data= mbardat, $
      dlimit={ystyle:1,panel_size:0.17, $
              yticks:1,ytickv:[0,1],ytickname:[' ',' '], $
              ytitle:' ',no_color_scale:1,y_no_interp:1, $
              spec:1,legend:['NO MODE','NO MODE '],ylegend:[0,1], $
              colors:[255b,127b],$
              zrange:var_range(mbardat.y),ticklen:0,x_no_interp:1}
endif
;
; reset panel size to look good with particles
;
options,'MODEBAR','panel_size',0.22

return
end



