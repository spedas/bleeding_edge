;+
;Helper function for LPW for mvn_gen_qlook
;Made changes to guard against missing data, jmm, 2014-03-25
;-
pro mvn_lpw_ql_3panels
  get_data,'mvn_lpw_euv',data=data0,limit=limit
  If(size(data0, /type) Eq 8) Then Begin
     data0.y[*,0]=(data0.y[*,0]-min(data0.y[*,0]) )*0.00004    +0 ;5    ; need to be corrected for later on 
     data0.y[*,1]=(data0.y[*,1]-min(data0.y[*,1]) )*0.0002    +0  ;5    ; need to be corrected for later on 
     data0.y[*,2]=(data0.y[*,2]-min(data0.y[*,2]) )*0.0002    +0  ;5    ; need to be corrected for later on
     data0.y[*,3]=(data0.y[*,3]-min(data0.y[*,3]) )*0.0002    +0  ;5    ; need to be corrected for later on
     store_data,'mvn_lpw_euv_diodes_ql',data=data0,limit=limit
  Endif Else dprint, 'No data for: mvn_lpw_euv'
     
  options,'mvn_lpw_euv_temp_C','psym',1 
  options,'mvn_lpw_euv_temp_C','colors',1 
  store_data,'mvn_lpw_euv_ql',data=['mvn_lpw_euv_diodes_ql','mvn_lpw_euv_temp_C']
  options,'mvn_lpw_euv_ql','ytitle','EUV diodes + Temp!C!C [Working Units]'
  options,'mvn_lpw_euv_ql','yrange',[-10,40]
  
  get_data,'mvn_lpw_spec_hf_pas',data=data3
  get_data,'mvn_lpw_spec_mf_pas',data=data2
  get_data,'mvn_lpw_spec_lf_pas',data=data1
  If(size(data1, /type) Eq 8) Then Begin
     nn=n_elements(data1.x)
     tmp_pwr=fltarr(nn,47+40+124)       
     tmp_fre=fltarr(nn,47+40+124)       
     tmp_pwr[*,0:46]=data1.y[*,0:46]
     tmp_fre[*,0:46]=data1.v[*,0:46]
     nn=n_elements(data1.x)
     If(size(data2, /type) Eq 8) Then Begin ;jmm, 2014-03-25
        nn_sort2=fltarr(nn)
        for i = 0, nn-1 do begin 
           tmp=min(abs(data1.x[i]-data2.x),nq) 
           nn_sort2[i]=nq
        endfor
        tmp_pwr[nn_sort2,47:86]=data2.y[nn_sort2,8:47]
        tmp_fre[nn_sort2,47:86]=data2.v[nn_sort2,8:47]
     Endif Else dprint, 'No data for: mvn_lpw_spec_mf_pas'
     If(size(data3, /type) Eq 8) Then Begin
        nn_sort3=fltarr(nn)
        for i = 0, nn-1 do begin 
           tmp=min(abs(data1.x[i]-data3.x),nq) 
           nn_sort3[i]=nq 
        endfor 
        tmp_pwr[nn_sort3,87:210]=data3.y[nn_sort3,4:127]
        tmp_fre[nn_sort3,87:210]=data3.v[nn_sort3,4:127]
     Endif Else dprint, 'No data for: mvn_lpw_spec_hf_pas'
     store_data,'mvn_lpw_wave_spec_ql',data={x:data1.x  , y:tmp_pwr,v:tmp_fre}
     options,'mvn_lpw_wave_spec_ql','ylog',1
     options,'mvn_lpw_wave_spec_ql','zlog',1
     options,'mvn_lpw_wave_spec_ql','spec',1
     options,'mvn_lpw_wave_spec_ql','ytitle','Wave Spectra !C !C PAS [Hz]'
     options,'mvn_lpw_wave_spec_ql','ztitle','Wave Power'
     ylim,'mvn_lpw_wave_spec_ql',0.25,2e6
     zlim,'mvn_lpw_wave_spec_ql',0.01,2e7
  Endif Else dprint, 'No data for: mvn_lpw_spec_lf_pas'

;fix the scale on htime
  get_data,'mvn_lpw_swp1_IV',limit=limit
  get_data,'mvn_lpw_htime_cap_lf',data=data
  IF(size(data, /type) Eq 8 && size(limit, /type) Eq 8) Then Begin
     IF n_elements(size(data)) GT 3  THEN data.y=(data.y+100) < (0.9*limit.yrange[1]) 
     store_data,'mvn_lpw_htime_cap2_lf',data=data
     options,'mvn_lpw_htime_cap2_lf','color',4   
     options,'mvn_lpw_htime_cap2_lf','psym',1 
;dy is a problems new variable 
     get_data,'mvn_lpw_pas_V2',data=data  
     If(size(data, /type) Eq 8) Then Begin
        store_data,'mvn_lpw_pas_V2_y',data={x:data.x,y:data.y}
        options,'mvn_lpw_pas_V2_y', 'color',1 
        options,'mvn_lpw_pas_V2_y','psym',1 
     Endif Else dprint, 'No data for: mvn_lpw_pas_V2'
  Endif
  store_data,'mvn_lpw_IV1_pasV2_ql',data=['mvn_lpw_swp2_IV','mvn_lpw_pas_V2_y','mvn_lpw_htime_cap2_lf']

  options,'mvn_lpw_IV1_pasV2_ql','yrange',[-60,60]
  options,'mvn_lpw_IV1_pasV2_ql','ystyle',1
  options,'mvn_lpw_IV1_pasV2_ql','zrange',[-1.e-7,6.e-7]
  options,'mvn_lpw_IV1_pasV2_ql','ytitle','Potential (I-V color) !C!C(blue SC) (HSBM green)'
  options,'mvn_lpw_IV1_pasV2_ql','ztitle','Current'
; ylim,'mvn_lpw_IV1_pasV2_ql',(limit.yrange[0]) > (-100),(limit.yrange[1]) > (+100)
   
;  options,'htime','charsize',1.6
;  options,'*ql','charsize',1.6
  
  options,'htime','xtitle','Time'

return
end
