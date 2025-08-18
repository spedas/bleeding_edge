pro mvn_lpw_prd_add_data,data,data_l2_x,data_l2_y,data_l2_dy,data_l2_v=data_l2_v,data_l2_dv=data_l2_dv,data_l2_boom=data_l2_boom,data_l2_flag=data_l2_flag,boom=boom
;fill in where we have information from data
 
 print,boom
 
 IF keyword_set(data_l2_v)   THEN aa = 1 else aa = 0 
 
 IF aa EQ 0 THEN $
          IF size(data, /type) EQ 8 THEN  BEGIN          
             index  = fltarr(n_elements(data.x))      
             FOR  i = 0,n_elements(data.x)-1 do begin
                 nn = where(data_l2_x EQ data.x(i),nq)
                 index[i] = nn          
             ENDFOR                
               data_l2_y(index)   = data.y
               data_l2_dy(index)  = data.dy
               IF keyword_set(data_l2_v)   THEN  data_l2_v(index)      = data.v 
               IF keyword_set(data_l2_dv)  THEN  data_l2_dv(index)     = data.dv
               IF keyword_set(data_l2_boom) THEN data_l2_boom(index)   = boom
               IF keyword_set(data_l2_flag) THEN data_l2_flag(index)   = double(data.flag)
          ENDIF   

 IF aa EQ 1 THEN $
          IF size(data, /type) EQ 8 THEN  BEGIN          
             index  = fltarr(n_elements(data.x))      
             FOR  i = 0,n_elements(data.x)-1 do begin
                 nn = where(data_l2_x EQ data.x(i),nq)
                 index[i] = nn          
             ENDFOR                
               data_l2_y(index,*)    = data.y
               data_l2_dy(index,*)   = data.dy
               data_l2_v(index,*)    = data.v 
               data_l2_dv(index,*)   = data.dv
               IF keyword_set(data_l2_boom) THEN data_l2_boom(index)   = boom
               IF keyword_set(data_l2_flag) THEN data_l2_flag(index)   = double(data.flag)
          ENDIF   


end