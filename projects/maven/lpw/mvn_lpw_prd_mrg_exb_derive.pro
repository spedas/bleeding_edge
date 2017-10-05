pro mvn_lpw_prd_mrg_exb_derive,data0,data1,flag1,data_x,data_y,data_dy,data_flag,data_names,data_colors

; this is where the poynting flux are derived
; get data0 on data1 resolution 

; then filter the two the same way and get dE and dB

; then derive the poynting flux with lower temporal  resolution
  
; evaluate the error with help of flag1    
   
   
   ;fejk some data
   index=long(lindgen(n_elements(data1.x)/64)*64)
       
    nn          = n_elements(index)
    data_names  = ['Poynting_msox','Poynting_msoy','Poynting_msoz','dB_msox','dB_msoy','dB_msoz', $
                         'dE_msox','dE_msoy','dE_msoz','B_msox','B_msoy','B_msoz']
    data_colors = [ 6,6,6,4,4       ,    4, 2,2 , 2,1,1 , 1] 
    data_x   = dblarr(nn)
    data_y   = fltarr(nn,n_elements(data_names))
    data_dy  = fltarr(nn,n_elements(data_names))
    data_flag= fltarr(nn)
      
     data_x      = data1.x(index)
     data_y(*,0) = data1.y(index) * 1.00
     data_y(*,1) = data1.y(index) * 1.04
     data_y(*,2) = data1.y(index) * 1.08
     data_y(*,3) = data1.y(index) * 1.20
     data_y(*,4) = data1.y(index) * 1.24
     data_y(*,5) = data1.y(index) * 1.28
     data_y(*,6) = data1.y(index) * 1.40
     data_y(*,7) = data1.y(index) * 1.44
     data_y(*,8) = data1.y(index) * 1.48
     data_y(*,9) = data1.y(index) * 1.60
     data_y(*,10) = data1.y(index) * 1.64
     data_y(*,11) = data1.y(index) * 1.68
     data_dy     = data_y*0.1
     data_flag   = flag1(index)
 
 end