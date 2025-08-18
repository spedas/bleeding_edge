pro mvn_lpw_prd_mrg_sc_calib,data_l2_x,data_l2_flag,data0,data1,data2,data3,data4,data5,data_l2_y,data_l2_dy

;there is where we merge 6 different packet information, has to be done with the information of atitude

          nn=n_elements(data_l2_x)
          data_l2_y                          = fltarr(nn)
          data_l2_dy                         = fltarr(nn)
          data_l2_so                         = fltarr(nn)
         ;------------------------------------------------- 
         ;here calibrate each individual data varible 
         ;------------------------------------------------- 
         
          
           ;start with the products that we know is not at the same time 
            ;    variables=['mvn_lpw_swp2_V1','mvn_lpw_act_V1','mvn_lpw_pas_V1','mvn_lpw_swp1_V2','mvn_lpw_act_V2','mvn_lpw_pas_V2']
         
         
          mvn_lpw_prd_add_data,data0,data_l2_x,data_l2_y,data_l2_dy
          mvn_lpw_prd_add_data,data3,data_l2_x,data_l2_y,data_l2_dy
            
           ;now work with where we need to compare
                   
           dat_1=data1
           dat_2=data4
           IF (size(dat_1, /type) EQ 8) + (size(dat_2, /type) EQ 8) EQ 1 THEN BEGIN ; check if both exist
                IF  (size(dat_1, /type) EQ 8) THEN data=dat_1 ELSE data=dat_2
                mvn_lpw_prd_add_data,data,data_l2_x,data_l2_y,data_l2_dy
           ENDIF ELSE BEGIN
            
             for i=0,n_elements(data_l2_x)-1 do BEGIN   ; this loop should be able to be written better keep this loop here because how we merge the points are important
                  nn1 = where(data_l2_x(i) EQ dat_1.x,nq1)                     ;nq1 can only be 1 or 0                
                  nn2 = where(data_l2_x(i) EQ dat_2.x,nq2)
                   If nq1+nq2 EQ 2 THEN BEGIN   ; just did som weithing
                       data_l2_y(i) = dat_1.y(nn1) * dat_2.dy(nn2)/(dat_1.dy(nn1)+dat_2.dy(nn2)) + $
                                      dat_2.y(nn2) * dat_1.dy(nn1)/(dat_1.dy(nn1)+dat_2.dy(nn2))
                      data_l2_dy(i) = dat_1.dy(nn1) * dat_2.dy(nn2)/(dat_1.dy(nn1)+dat_2.dy(nn2)) + $
                                      dat_2.dy(nn2) * dat_1.dy(nn1)/(dat_1.dy(nn1)+dat_2.dy(nn2))
                   ENDIF ELSE BEGIN
                      If nq1 EQ 1 THEN BEGIN
                          data_l2_y(i)   = data1.y(nn1)
                          data_l2_dy(i)  = data1.dy(nn1)                     
                      ENDIF 
                       If nq2 EQ 1 THEN BEGIN
                          data_l2_y(i)   = data4.y(nn2)
                          data_l2_dy(i)  = data4.dy(nn2)                     
                      ENDIF 
                  ENDELSE
           ENDFOR 
           ENDELSE     
                            

end