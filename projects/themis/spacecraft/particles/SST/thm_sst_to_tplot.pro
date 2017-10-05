pro thm_sst_to_tplot,probes=probes, suffix=suffix

if not keyword_set(probes) then probes=['a','b','c','d','e']

if not keyword_set(suffix) then sf='' else sf=string(suffix)

for p=0,n_elements(probes)-1 do begin
    prb = probes[p]
    thx = 'th'+prb
    data_cache,thx+'_sst_raw_data',data,/get
    if not keyword_set(data) then continue
    dprint,dlevel=2,thx

    nan=0
    if ptr_valid(data.sif_064_time) then begin
       name = thx+'_psif'
       time = *data.sif_064_time
       y = total(thm_part_decomp16(*data.sif_064_data,nan=nan),2)
       store_data,name+'_ang'+sf,data={x:time , y:y ,  v:findgen(64) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,2e4], ystyle:1}
       y = total(thm_part_decomp16(*data.sif_064_data,nan=nan),3)
       store_data,name+'_en'+sf,data={x:time , y:y ,  v:findgen(16) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,1e5], ystyle:1}
;       y = total(y[*,
;       store_data,name_'_rate',data={x:time, y:y }
       y = total(y[*,0:11],2)
       store_data,name+'_tot'+sf,data={x:time , y:y  }, dlimit={ylog:1 , yrange:[1,1e6], ystyle:1}
       store_data,name+'_cnfg'+sf,data={x:time , y:*data.sif_064_cnfg  }, dlimit={ tplot_routine:'bitplot'}
       store_data,name+'_nspn'+sf,data={x:time , y:*data.sif_064_nspins  }, dlimit={ tplot_routine:'bitplot'}
       store_data,name+'_atten'+sf,data={x:time , y:*data.sif_064_atten  }, dlimit={ tplot_routine:'bitplot'}
       dprint,dlevel=2,name
    endif
    if ptr_valid(data.sef_064_time) then begin
       name = thx+'_psef'
       time = *data.sef_064_time
       y = total(thm_part_decomp16(*data.sef_064_data,nan=nan),2)
       store_data,name+'_ang'+sf,data={x:time , y:y ,  v:findgen(64) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,2e4], ystyle:1}
       y = total(thm_part_decomp16(*data.sef_064_data,nan=nan),3)
       store_data,name+'_en'+sf,data={x:time , y:y ,  v:findgen(16) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,1e5], ystyle:1}
       Y = total(y[*,0:11],2)
       store_data,name+'_tot'+sf,data={x:time , y:y }, dlimit={ylog:1 , yrange:[1,1e6], ystyle:1}
       store_data,name+'_atten'+sf,data={x:time , y:*data.sef_064_atten  }, dlimit={ tplot_routine:'bitplot'}
       dprint,dlevel=2,name
    endif
    if ptr_valid(data.seb_064_time) then begin
       name = thx+'_pseb'
       time = *data.seb_064_time
       y = total(thm_part_decomp16(*data.seb_064_data,nan=nan),2)
       store_data,name+'_ang'+sf,data={x:time , y:y ,  v:findgen(64) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,2e4], ystyle:1}
       y = total(thm_part_decomp16(*data.seb_064_data,nan=nan),3)
       store_data,name+'_en'+sf,data={x:time , y:y ,  v:findgen(16) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,1e5], ystyle:1}
       Y = total(y[*,0:11],2)
       store_data,name+'_tot'+sf,data={x:time , y:y }, dlimit={ylog:1 , yrange:[1,1e6], ystyle:1}
       store_data,name+'_atten'+sf,data={x:time , y:*data.seb_064_atten  }, dlimit={ tplot_routine:'bitplot'} 
       dprint,dlevel=2,name
    endif
    if ptr_valid(data.sir_001_time) then begin
       name = thx+'_psir'
       time = *data.sir_001_time
       y = thm_part_decomp16(*data.sir_001_data,nan=nan)
       store_data,name+'_en'+sf,data={x:time , y:y ,  v:findgen(16) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,1e5]}
       y = total(y[*,0:11],2)
       store_data,name+'_tot'+sf,data={x:time , y:y }, dlimit={ylog:1 , yrange:[1,1e6], ystyle:1}
       store_data,name+'_atten'+sf,data={x:time , y:*data.sir_001_atten  }, dlimit={ tplot_routine:'bitplot'}  
       dprint,dlevel=2,name
    endif
    if ptr_valid(data.sir_006_time)  then begin
       name = thx+'_psir6'
       time = *data.sir_006_time
       y = total(thm_part_decomp16(*data.sir_006_data,nan=nan),2)
       store_data,name+'_ang'+sf,data={x:time , y:y ,  v:findgen(6) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,2e4], ystyle:1}
       y = total(thm_part_decomp16(*data.sir_006_data,nan=nan),3)
       store_data,name+'_en'+sf,data={x:time , y:y ,  v:findgen(16) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,1e5], ystyle:1}
       y = total(y[*,0:11],2)
       store_data,name+'_tot'+sf,data={x:time , y:y  }, dlimit={ylog:1 , yrange:[1,1e6], ystyle:1}
       store_data,name+'_cnfg'+sf,data={x:time , y:*data.sir_006_cnfg  }, dlimit={ tplot_routine:'bitplot'}
       store_data,name+'_nspn'+sf,data={x:time , y:*data.sir_006_nspins  }, dlimit={ tplot_routine:'bitplot'}
       store_data,name+'_atten'+sf,data={x:time , y:*data.sir_006_atten  }, dlimit={ tplot_routine:'bitplot'}   
       dprint,dlevel=2,name
    endif
    if ptr_valid(data.ser_001_time)  then begin
       name = thx+'_pser'
       time = *data.ser_001_time
       y = thm_part_decomp16(*data.ser_001_data,nan=nan)
       store_data,name+'_en'+sf,data={x:time , y:y ,  v:findgen(16) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,1e5]}
       y = total(y[*,0:11],2)
       store_data,name+'_tot'+sf,data={x:time , y:y }, dlimit={ylog:1 , yrange:[1,1e6], ystyle:1}
       store_data,name+'_atten'+sf,data={x:time , y:*data.ser_001_atten  }, dlimit={ tplot_routine:'bitplot'}   
       dprint,dlevel=2,name
    endif
    if ptr_valid(data.ser_006_time)  then begin
       name = thx+'_pser6'
       time = *data.ser_006_time
       y = total(thm_part_decomp16(*data.ser_006_data,nan=nan),2)
       store_data,name+'_ang'+sf,data={x:time , y:y ,  v:findgen(6) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,2e4], ystyle:1}
       y = total(thm_part_decomp16(*data.ser_006_data,nan=nan),3)
       store_data,name+'_en'+sf,data={x:time , y:y ,  v:findgen(16) }, dlimit={spec:1,zlog:1 ,no_interp:1, zrange:[1,1e5], ystyle:1}
       y = total(y[*,0:11],2)
       store_data,name+'_tot'+sf,data={x:time , y:y  }, dlimit={ylog:1 , yrange:[1,1e6], ystyle:1}
       store_data,name+'_cnfg'+sf,data={x:time , y:*data.ser_006_cnfg  }, dlimit={ tplot_routine:'bitplot'}
       store_data,name+'_nspn'+sf,data={x:time , y:*data.ser_006_nspins  }, dlimit={ tplot_routine:'bitplot'}
       store_data,name+'_atten'+sf,data={x:time , y:*data.ser_006_atten  }, dlimit={ tplot_routine:'bitplot'}   
       dprint,dlevel=2,name
    endif

endfor


end
