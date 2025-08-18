;+
;PROCEDURE:   mvn_lpw_prd_w_flag
;
;Routine to produce flag information for lpw wave data. Routine uses lpw timeseries, along with s/c position and pointing and engineering
;data, to determine a quality flag for the data.
;
;INPUTS:         
;  data_x = input LPW timeseries array to flag at each time step
;  check_variables = array containing strings of variables to check 
;   
;KEYWORDS:
;  /plots  -  to create plots of each flag variable and save to jpgs (right now hard-coded to save to Tess's computer)
; 
;EXAMPLE:
; get_data,'mvn_lpw_spec_hf_pas',data=data
; mvn_lpw_prd_w_flag,data.x
;
;OUTPUT:
; flag: (double array) example: 100.123456789  (integer represents the overall quality flag, 0=bad, 100=good)
;     14 decimals after integer quality flag representing:
;         1-boom (1 or 2) or ACT/PAS  depending on the product (pas=1, act=2)
;         2-number represents issues with identifying double peak, etc (flags from Dave’s routine)
;         3,4-attitude (with respect to Sun/Zsc and s/c velocity vector)
;         5-shadow (0=no shadow, 1=100% in Mars shadow, 2 is sunset or sunrise (400 km alt at terminator), 3 means the shadow difference on the boom is > 20%
;         6-s/c wake (0=booms aren’t in wake, 1=boom 1 in s/c wake, 2=boom 2 in s/c wake)
;         7-thrusters (0=no problems, 1=thrusters firing)
;         8-reaction wheels (0=no problems, 1=all wheels running within 0.1 Hz at the same time)
;         9-14-bias,guard,stub encoded into 6 digits
; flag_info: string describing the flag
; flag_source: which variables were used to produce the flag
; vers_prd: the version of this routine that was used to produce the flags
;
;CREATED BY:   Chris Fowler  05-19-14
;FILE:         mvn_lpw_prd_w_flag.pro
;VERSION:      1.0
;LAST MODIFICATION: 
;
; 2015-03-27   T. McEnulty modified to get thruster, reaction wheel, eclipse, wake, bias/guard/stub and store 14 decimals for the quality flag (V1.0)


pro mvn_lpw_prd_w_flag, data_x,check_variables,total_flag,flag_info,flag_source,vers_prd,scale,plots=plots                                  

        vers_prd= 'Version mvn_lpw_w_flag V1.0'                                          ;<------- the version number of this routine

        date=strmid(time_string(data_x(0)),0,10)                                         ;<------- start date of input timeseries
        
        flag_info     = 'The uncertainty of the values with a scale of 0-100. 100 is the best quality. ' + $
                       ' Use data with flag value above 50.  For decimals see instrument SIS.'


;;  ################################################################################################
;;  #############################  Get eph and eng data for input timeseries #######################
;;  ################################################################################################
        
    mvn_lpw_anc_spacecraft, data_x                                                                             

    mvn_lpw_anc_eng, data_x    
     
    mvn_lpw_anc_boom, data_x
     
    mvn_lpw_anc_probe_settings, dac_values                                                ;<-- (dac_values is the output 6 digit guard/stub/bias encoded number)
      
    flag=make_array(n_elements(data_x),15,/double,value=0)                                ;<------ initilize matrix to store flag values in
           


;;  ################################################################################################
;;  ###############  Make sure that all of the eph/pointing tplot variables are present ############
;;  ################################################################################################
       
            names = tnames()                                                                ;<------ list of tplot variables currently loaded 
            missing_variable = 'The following spacecraft data are missing: '
   ; __         
         IF total(strmatch(names, 'mvn_lpw_anc_mvn_angles')) EQ 1 THEN BEGIN                ;<------ MAVEN solar angle
            sc_angle = 1.                                                                   
            get_data, 'mvn_lpw_anc_mvn_angles', data=data_angles,limit=limit_ang, dlimit=dlimit_ang 
            type_angles = size(data_angles, /type)
         ENDIF ELSE BEGIN
            sc_angle = 0.  
            missing_variable=[missing_variable,'mvn_lpw_anc_mvn_angles was not found']
            type_angles = -999
         ENDELSE
   ; __ 
         IF total(strmatch(names, 'mvn_lpw_anc_mvn_pos_mso')) EQ 1 THEN BEGIN               ;<------ MAVEN position in Mars MSO frame
            sc_pos = 1.  
            get_data, 'mvn_lpw_anc_mvn_pos_mso', data=data_pos_mso, limit=limit_pos, dlimit=dlimit_pos 
            type_pos_mso = size(data_pos_mso, /type)
         ENDIF ELSE BEGIN
            sc_pos = 0. 
            missing_variable=[missing_variable,'mvn_lpw_anc_mvn_pos_mso was not found']
            type_pos_mso = -999
         ENDELSE
   ; __ 
         IF total(strmatch(names, 'mvn_lpw_anc_mvn_vel_sc_mso')) EQ 1 THEN BEGIN                ;<------ MAVEN velocity in s/c coordinates frame
            sc_vel = 1.  
            get_data, 'mvn_lpw_anc_mvn_vel_sc_mso', data=data_vel_sc, limit=limit_vel, dlimit=dlimit_vel 
            type_vel_sc = size(data_vel_sc, /type)
         ENDIF ELSE BEGIN
            sc_vel = 0. 
            missing_variable=[missing_variable,'mvn_lpw_anc_mvn_vel_sc_mso was not found']
            type_vel_sc = -999
         ENDELSE
; __
         IF total(strmatch(names, 'mvn_lpw_anc_sun_pos_mvn')) EQ 1 THEN BEGIN                ;<------ MAVEN solar position
           sun_pos = 1.
           get_data, 'mvn_lpw_anc_sun_pos_mvn', data=data_sun_pos,limit=limit_sun_pos, dlimit=dlimit_sun_pos
           type_sun_pos = size(data_sun_pos, /type)
         ENDIF ELSE BEGIN
           sun_pos = 0.
           missing_variable=[missing_variable,'mvn_lpw_anc_sun_pos_mvn was not found']
           type_sun_pos = -999
         ENDELSE
; __
         IF total(strmatch(names, 'mvn_lpw_anc_boom_shadow')) EQ 1 THEN BEGIN                ;<------ MAVEN boom shadow info from mvn_lpw_anc_boom
           boom = 1.
           get_data, 'mvn_lpw_anc_boom_shadow', data=data_boom, limit=limit_boom, dlimit=dlimit_boom
           type_boom = size(data_boom, /type)
         ENDIF ELSE BEGIN
           boom = 0.
           missing_variable=[missing_variable,'mvn_lpw_anc_boom_shadow']
           type_boom = -999
         ENDELSE
; __
         IF total(strmatch(names, 'mvn_lpw_anc_boom_wake')) EQ 1 THEN BEGIN                 ;<------ MAVEN boom wake info from mvn_lpw_anc_boom
           wake = 1.
           get_data, 'mvn_lpw_anc_boom_wake', data=data_wake, limit=limit_wake, dlimit=dlimit_wake
           type_wake = size(data_wake, /type)
         ENDIF ELSE BEGIN
           wake = 0.
           missing_variable=[missing_variable,'mvn_lpw_anc_boom_wake']
           type_wake = -999
         ENDELSE
; __
         IF total(strmatch(names, 'mvn_lpw_anc_acs')) EQ 1 THEN BEGIN                       ;<------ MAVEN acs thruster info
           asc = 1.
           get_data, 'mvn_lpw_anc_acs', data=data_asc, limit=limit_asc, dlimit=dlimit_asc
           type_asc = size(data_asc, /type)
         ENDIF ELSE BEGIN
           asc = 0.
           missing_variable=[missing_variable,'mvn_lpw_anc_acs']
           type_asc = -999
         ENDELSE
; __
         IF total(strmatch(names, 'mvn_lpw_anc_rel_rw')) EQ 1 THEN BEGIN                    ;<------ MAVEN reaction wheel info
           wheel = 1.
           get_data, 'mvn_lpw_anc_rel_rw', data=data_wheel, limit=limit_wheel, dlimit=dlimit_wheel
           type_wheel = size(data_wheel, /type)
         ENDIF ELSE BEGIN
           wheel = 0.
           missing_variable=[missing_variable,'mvn_lpw_anc_rel_rw']
           type_wheel = -999
         ENDELSE
; __
         IF total(strmatch(names, 'mvn_lpw_atr_dac_raw')) EQ 1 THEN BEGIN                    ;<------ MAVEN bias/guard/stub settings info
           dac = 1.
           get_data,'mvn_lpw_atr_dac_raw', data=data_dac, limit=limit_dac, dlimit=dlimit_dac
           type_dac = size(data_dac, /type)
         ENDIF ELSE BEGIN
           dac = 0.
           missing_variable=[missing_variable,'mvn_lpw_atr_dac_raw']
           type_dac = -999
         ENDELSE



         IF n_elements(missing_variable) GT 1 then print,'mvn_lpw_prd_w_flag: ##### WARNING ###### ',missing_variable




;;  ################################################################################################
;;  ########  Make sure that each of the input times has position data within 24 hours #############
;;  ################################################################################################

      if sc_pos eq 1 then begin
        if abs(data_x[0] - data_pos_mso.x[0]) gt 86600.D then begin                                 ;give 200 sec extra just in case
          print, "#### WARNING #### s/c position data greater than 24 hours from act/pas data."
          print, "s/c position data not included..."
          skip_pos = 1
          endif else skip_pos = 0.                                                                  ;don't skip pos                
          endif else skip_pos = 1                                                                   ;skip position data

      if sc_angle eq 1 then begin
        if abs(data_x[0] - data_angles.x[0]) gt 86600.D then begin
          print, "#### WARNING #### Solar angle data greater than 24 hours from act/pas data."
          print, "Solar angle data not included..."
          skip_angle = 1                 
          endif else skip_angle = 0. 
          endif else skip_angle = 1 
          
     if sc_vel eq 1 then begin
            if abs(data_x[0] - data_vel_sc.x[0]) gt 86600.D then begin
              print, "#### WARNING #### S/c velocity data greater than 24 hours from act/pas data."
              print, "S/c velocity data not included..."
              skip_vel = 1
            endif else skip_vel = 0.
          endif else skip_vel = 1
          
     if boom eq 1 then begin
            if abs(data_x[0] - data_boom.x[0]) gt 86600.D then begin
              print, "#### WARNING #### Boom shadow data greater than 24 hours from act/pas data."
              print, "Boom shadow data not included..."
              skip_angle = 1
            endif else skip_shadow = 0.
          endif else skip_shadow= 1
          
     if wake eq 1 then begin
            if abs(data_x[0] - data_wake.x[0]) gt 86600.D then begin
              print, "#### WARNING #### Boom wake data greater than 24 hours from act/pas data."
              print, "Boom wake data not included..."
              skip_wake = 1
            endif else skip_wake = 0.
          endif else skip_wake = 1
          
     if asc eq 1 then begin
            if abs(data_x[0] - data_asc.x[0]) gt 86600.D then begin
              print, "#### WARNING #### Thruster data greater than 24 hours from act/pas data."
              print, "Thruster data not included..."
              skip_thruster = 1
            endif else skip_thruster = 0.
          endif else skip_thruster = 1
                   
    if wheel eq 1 then begin
            if abs(data_x[0] - data_wheel.x[0]) gt 86600.D then begin
              print, "#### WARNING #### Reaction wheel data greater than 24 hours from act/pas data."
              print, "Reaction wheel data not included..."
              skip_wheel = 1
            endif else skip_wheel = 0.
          endif else skip_wheel = 1
          
    if dac eq 1 then begin
            if abs(data_x[0] - data_dac.x[0]) gt 86600.D then begin
              print, "#### WARNING #### DAC bias/guard/stub data greater than 24 hours from act/pas data."
              print, "DAC bias/guard/stub data data not included..."
              skip_dac = 1
            endif else skip_dac = 0.
          endif else skip_dac= 1




;;  ################################################################################################
;;  ########  Create flag_source that tells what variables were available to check #################
;;  ################################################################################################

        IF (type_pos_mso EQ 8) THEN pos_flag = 'MAVEN position used' ELSE pos_flag = 'MAVEN position unavailable'
        IF (type_angles EQ 8) THEN angle_flag = 'MAVEN solar angle used' ELSE angle_flag = 'MAVEN solar angle unavailable'
        IF (type_vel_sc EQ 8) THEN vel_flag = 'MAVEN s/c velocity used' ELSE vel_flag = 'MAVEN s/c velocity unavailable'
        IF (type_asc EQ 8) THEN asc_flag = 'MAVEN thruster info used' ELSE asc_flag = 'MAVEN thruster info unavailable'
        IF (type_wheel EQ 8) THEN wheel_flag = 'MAVEN reaction wheel data used' ELSE wheel_flag = 'MAVEN reaction wheel data unavailable'
        IF (type_dac EQ 8) THEN dac_flag = 'MAVEN bias/guard/stub data used' ELSE dac_flag = 'MAVEN bias/guard/stub data unavailable'
        
        
        
        flag_source = pos_flag + ' # ' + angle_flag + ' # ' + vel_flag + ' # ' + asc_flag + ' # ' + wheel_flag + ' # ' + dac_flag
         
                     
              

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~ Populate flag decimal values for each possible issue ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


;;  ################################################################################################
;;  ##  Decimal 1 ##  boom (1 or 2) or ACT/PAS  depending on the product (pas=1, act=2) ############
;;  ################################################################################################

              ;; this decimal is added in prd_w_n.pro
              ;; can add ACT/PAS decimal directly in prd_w_spec
              
              flag[*,1]=0                                                                                       ;<-----------example for testing, add in other routines




;;  #####################################################################################################################
;;  ##  Decimal 2 ##  number represents issues with identifying double peak, etc (flags from Dave’s routine) ############
;;  #####################################################################################################################
        
              ;; add this decimal in the prd_w_n routine 
              
              flag[*,2]=0                                                                                        ;<----- example for testing, add in other routines
        
        
        
        
;;  ################################################################################################
;;  ##  Decimal 3 and 4 ##  attitude (0-9) ###############################################
;;  ################################################################################################


if (skip_angle eq 0.) and (skip_vel eq 0.) then begin
       
      get_data,'mvn_lpw_anc_mvn_angles', data=angle1                                 ;<------ Decimal 3. Break up by 20 degrees for digits 1-9 (0 means we don't have any info)
        ;;    1: 0-20, 2: >20-40, 3: >40-60, 4: >60-80, 5: >80-100, 6: >100-120, 7: >120-140, 8: >140-160, 9: >160-180 
              
if keyword_set(plots) then begin
window,1
plot,angle1.y[*,0], yrange=[0,180], psym=4, title='angle 1 from anc_mvn_angles'
endif

        flag(*,3)=ceil(angle1.y[*,0]/20)
    
        get_data, 'mvn_lpw_anc_mvn_vel_sc_mso', data=vsc                                  ;<------ Decimal 4. Break up by 20 degrees for digits 1-9 (0 means we don't have any info)
        ;;    1: 0-40, 2: >40-80, 3: >80-120, 4: >120-160, 5: >160-200, 6: >200-240, 7: >240-280, 8: >280-320, 9: >320-360       
        
        angle2=atan(vsc.y[*,2]/abs(vsc.y[*,2])*sqrt(vsc.y[*,0]^2+vsc.y[*,2]^2),vsc.y[*,1])*180/!pi          
        angle2[where(angle2 lt 0)]=angle2[where(angle2 lt 0)]+360 

if keyword_set(plots) then begin
window,2
plot,angle2, yrange=[0,360], psym=4,title='angle 2 from anc_mvn_vel_sc_mso'
endif
        flag(*,4)=ceil(angle2[*,0]/40)        

            limit=create_struct('yrange',[0,10],'psym',4)
                  
        store_data, 'mvn_lpw_attitude_flags', data={x:data_x, y:flag(*,3:4)}, limit=limit


if keyword_set(plots) then begin       
window,3
tplot,['mvn_lpw_attitude_flags','mvn_lpw_anc_mvn_angles','mvn_lpw_anc_mvn_vel_sc_mso']
  
filename='/Users/temc2959/Desktop/LPW_daily_check_tplot/flags/attitude_'+date+'.jpg'
WRITE_JPEG,filename, TVRD(/TRUE), /TRUE, quality=100
endif
  
 endif ELSE print, "#### WARNING #### No attitude info, attitude flag skipped..." 
 
        
;  ###############################################################################################
;  ##  Decimal 5 ##  shadow (0=no shadow, 1=100% in Mars shadow,                    ##############
;  ########################  2 = sunset or sunrise (use 400 km alt at terminator),  ##############
;  ########################  3 = there is more than 20% shadow difference btn booms ##############
;  ########################  4 = there is s/c shadow on boom 1  ?                   ##############
;  ########################  5 = there is s/c shadow on boom 2  ?                   ##############
;  ###############################################################################################
    
if (skip_pos eq 0.) and (skip_shadow eq 0.) then begin
    
         nele_pos = n_elements(data_pos_mso.x)
 
         FOR aa = 0, nele_pos-1 DO IF (data_pos_mso.y[aa,0] LT 0.) AND (sqrt(data_pos_mso.y[aa,1]^2 + data_pos_mso.y[aa,2]^2) LT 1+400/3390.D) AND (sqrt(data_pos_mso.y[aa,1]^2 + data_pos_mso.y[aa,2]^2) GT 1.D) THEN flag(aa,5)=2. ;in atm. ecclipse   
         FOR aa = 0, nele_pos-1 DO IF (data_pos_mso.y[aa,0] LT 0.) AND (sqrt(data_pos_mso.y[aa,1]^2 + data_pos_mso.y[aa,2]^2) LT 1.D) THEN flag(aa,5)=1. ;in full ecclipse 

if keyword_set(plots) then begin
window,0
plot,flag(*,5),title='Mars shadow',psym=4
endif    

         get_data,'mvn_lpw_anc_boom_shadow',data=shadow_perc
         diff=abs(shadow_perc.y[*,2]-shadow_perc.y[*,0])                                    ; difference in the % shading of the booms
         FOR aa = 0, nele_pos-1 DO IF (diff[aa] GT 20) THEN flag(aa,5)=3.                   ; there is a larger than 20% difference in boom shadowing   
            
;         mvn_lpw_anc_boom, data_x    
;         get_data,'mvn_lpw_anc_boom_shadow_desc', data=boom_shadow              ; mvn_lpw_anc_boom_wake: boom is in shadow or not, 1: in wake, 0: out of wake (1st column is sensor 1, 2nd is sensor 2)
;         
;         FOR aa = 0, nele_pos-1 DO IF (boom_shadow.y[aa,0] NE 7) THEN flag(aa,5)=4. ; sensor 1 has some shadow
;         FOR aa = 0, nele_pos-1 DO IF (boom_shadow.y[aa,1] NE 7) THEN flag(aa,5)=5. ; sensor 2 has some shadow 
            

        limit=create_struct(           $
            'ytitle' ,   'Eclipse'    ,$
            'yrange' ,   [0,4]        ,$
            'psym'  ,    4             )

          store_data, 'mvn_lpw_eclipse_flag', data={x:data_x, y:flag[*,5]}, limit=limit

if keyword_set(plots) then begin 
window,5          
tplot,['mvn_lpw_eclipse_flag','mvn_lpw_anc_boom_shadow','mvn_lpw_anc_mvn_pos_mso']
  
filename='/Users/temc2959/Desktop/LPW_daily_check_tplot/flags/eclipse_'+date+'.jpg'
WRITE_JPEG,filename, TVRD(/TRUE), /TRUE, quality=100         
endif

endif ELSE print, "#### WARNING #### No position or boom shadow info, eclipse flag skipped..." 



;;  ################################################################################################
;;  ##  Decimal 6 ##  s/c wake (0=no s/c wake, 1=boom 1 in s/c wake, 2=boom 2 in s/c wake) #########
;;  ################################################################################################

if (skip_wake eq 0.) then begin 
                
         get_data,'mvn_lpw_anc_boom_wake', data=wake                            ; mvn_lpw_anc_boom_wake: boom is in wake or not
                                                                                ; (1: in wake, 0: out of wake (1st column is sensor 1, 2nd is sensor 2))
         FOR aa = 0, nele_pos-1 DO IF (wake.y[aa,0] EQ 1) THEN flag[aa,6]=1.           ; sensor 1 in s/c wake
         FOR aa = 0, nele_pos-1 DO IF (wake.y[aa,1] EQ 1) THEN flag[aa,6]=2.           ; sensor 2 in s/c wake
 
         limit=create_struct('yrange' ,[0,2],'psym',4)
                  
         store_data, 'sc_wake_flag', data={x:data_x, y:flag[*,6]}, limit=limit

if keyword_set(plots) then begin
window,6
tplot, ['sc_wake_flag','mvn_lpw_anc_boom_wake']    

filename='/Users/temc2959/Desktop/LPW_daily_check_tplot/flags/wake_'+date+'.jpg'
WRITE_JPEG,filename, TVRD(/TRUE), /TRUE, quality=100
endif
  
endif ELSE print, "#### WARNING #### No wake info, wake flag skipped..." 


;;  ################################################################################################
;;  ##################  Decimal 7 #####  0=NONE, 1=THRUSTERS  ######################################
;;  ################################################################################################

if skip_thruster eq 0. then begin
  
        get_data,'mvn_lpw_anc_acs',data=acs
        get_data,'mvn_lpw_anc_tcm',data=tcm
        
        thruster_time=[acs.x,tcm.x]
        
        for i=0,n_elements(thruster_time)-1 do begin         
           test_time=where(abs(make_array(n_elements(data_x),/double,value=thruster_time(i))-data_x) lt 4)  ;; modify 4 to be the number of seconds away from the thruster you want to flag           
           flag[test_time,7]=1 
        endfor          

        limit=create_struct(           $
          'yrange' ,   [0,2]        ,$
          'psym'  ,    4             )
                  
        store_data, 'mvn_lpw_thruster_flag', data={x:data_x, y:flag[*,7]}, limit=limit

if keyword_set(plots) then begin        
window,7
tplot, ['mvn_lpw_thruster_flag','mvn_lpw_anc_acs','mvn_lpw_anc_tcm']
        
filename='/Users/temc2959/Desktop/LPW_daily_check_tplot/flags/thrusters_'+date+'.jpg'
WRITE_JPEG,filename, TVRD(/TRUE), /TRUE, quality=100   

endif

endif ELSE print, "#### WARNING #### No thruster info, thruster flag skipped..." 
        
        
;;  ################################################################################################
;;  ##################  Decimal 8 #####  0=NONE, 1=REACTION WHEELS #################################
;;  ################################################################################################
 
if skip_wheel eq 0. then begin 
               
        get_data,'mvn_lpw_anc_rel_rw',data=rw 
        
        wheel_flag=make_array(n_elements(rw.x),/integer,value=0)
       
       for p=0,n_elements(rw.x)-1 do begin        
        if rw.y(p,1)+rw.y(p,2)+rw.y(p,3) LT 0.3 then begin        
        ;if (rw.y(p,1) LT 0.5) || (rw.y(p,2) LT 0.5) || (rw.y(p,3) LT 0.5) then begin  ;; look for if just 1 wheel is close to the others          
           wheel_flag(p)=1        
        endif       
       endfor
        
        wheel_time=rw.x[wheel_flag]       
        
        for i=0,n_elements(wheel_time)-1 do begin
          test_time2=where(abs(make_array(n_elements(data_x),/double,value=wheel_time(i))-data_x) lt 2)  ;; modify 2 to be the number of seconds away from the thruster you want to flag
        endfor

      ;flag[test_time2,8]=1                                                                        ;<------ un-comment back to 1 after we figure out exactly what testtime2 should be
      flag[test_time2,8]=0

if keyword_set(plots) then begin      
window,4
plot,flag[*,8], title='wheel flag, should be all zeros for now', psym=4, yrange=[0,2]


      limit=create_struct('yrange',[0,2],'psym',4)
                
      store_data, 'mvn_lpw_wheels_flag', data={x:data_x, y:flag[*,8]}, limit=limit

window,8
tplot, ['mvn_lpw_wheels_flag','mvn_lpw_anc_rel_rw']

filename='/Users/temc2959/Desktop/LPW_daily_check_tplot/flags/wheels_'+date+'.jpg'
WRITE_JPEG,filename, TVRD(/TRUE), /TRUE, quality=100
endif

endif ELSE print, "#### WARNING #### No reaction wheel info, wheel flag skipped..." 



;;  ########################################################################################################
;;  ##  Decimal 9-14 ####BIAS/GUARD/STUB VALUE encoded into 6 digits with 'mvn_lpw_anc_probe_settings#######
;;  ########################################################################################################

if skip_dac eq 0. then begin

      for i=0,n_elements(data_x)-1 do begin                                             ;<------ at each data_x point find the closest time of bias/guard/stub
        closest_time=where(min(abs(make_array(n_elements(dac_values.x),/double,value=data_x(i))-dac_values.x)))
        flag[i,9]=dac_values.y(closest_time)                                                ;<------ dac_values.y is the 6 digits, values.x is the timeseries  
      endfor                                                                               
   
if keyword_set(plots) then begin      
window,9
   tplot,['DAC','DAC_lpg','DAC_wg','DAC_lps','DAC_ws']                                 ;<------ these tplot variables are created in the mvn_lpw_anc_probe_settings  

filename='/Users/temc2959/Desktop/LPW_daily_check_tplot/flags/surface_pots_'+date+'.jpg'
WRITE_JPEG,filename, TVRD(/TRUE), /TRUE, quality=100

print, 'value stored in flag ='
print,flag[0,9]

print, 'equal to in binary'
print,flag[0,9],format='(b)'

endif

      ;; add check to make sure that the output 6 digit number can be converted back to the bias/guard/stub values?
    
endif ELSE print, "#### WARNING #### No dac info, bias/guard/stub value skipped..." 


;;  ################################################################################################
;;  #####  Scale to output to modify total flag number in prd routines #############################
;;  ################################################################################################

; flag: (double array) example: 100.123456789  (integer represents the overall quality flag, 0=bad, 100=good)
;     11 decimals after integer quality flag representing:
;                 1-boom (1 or 2) or ACT/PAS  depending on the product (pas=1, act=2)
;         2-number represents issues with identifying double peak, etc (flags from Dave’s routine)
;         3,4-attitude (with respect to Sun/Zsc and s/c velocity vector)
;         5-shadow (0=no shadow, 1=100% in Mars shadow, 2 is sunset or sunrise (400 km alt at terminator), 3 is the shadow difference on the boom is > 20%
;         6-s/c wake (0=booms aren’t in wake, 1=boom 1 in s/c wake, 2=boom 2 in s/c wake)
;         7-thrusters (0=no problems, 1=thrusters firing)
;         8-reaction wheels (0=no problems, 1=all wheels running within 0.1 Hz at the same time)

    flag[*,0] = 0                                                           ;<------ for now put as zero and then add flags in the prd_spec and prd_w_n routines
    scale=make_array(n_elements(data_x),/float,value=1)                     ;<------ later make 0-1 depending on the issues identified in this routine

   for i=0,n_elements(data_x)-1 do begin
;      if flag[i,2] gt 0 then scale(i)=0       ;<------taking into account double peaks, etc
;      if flag[i,5] eq 3 then scale(i)=0                            ;<------taking into account s/c shadow
;      if flag[i,6] gt 0 then scale(i)=0                             ;<------taking into account s/c wake
       if flag[i,7] gt 0 then scale(i)=0                                          ;<------taking into account bad data due to thrusters
;      if flag[i,8] gt 0 then scale(i)=0                                     ;<------taking into account bad data due to wheels
    endfor


    store_data, 'scale', data={x:data_x, y:scale}


;    limit=create_struct(           $
;      'yrange' ,   [0,100]        ,$
;      'psym'  ,    4             )
;
;   store_data, 'quality_flag', data={x:data_x, y:flag[*,0]}, limit=limit
;
;if keyword_set(plots) then begin
;window,12
;tplot, ['quality_flag','mvn_lpw_spec_hf_pas']
;
;filename='/Users/temc2959/Desktop/LPW_daily_check_tplot/flags/quality_'+date+'.jpg'
;WRITE_JPEG,filename, TVRD(/TRUE), /TRUE, quality=100
;endif


;;  ################################################################################################
;;  #####  Building final number to output including the decimals  #################################
;;  ################################################################################################

    total_flag=make_array(n_elements(data_x),/double,value=0)

    for i=0,n_elements(total_flag)-2 do begin 
      total_flag[i]=flag[i,0]+flag[i,1]/10.0D +flag[i,2]/100.0D +flag[i,3]/1000.0D +flag[i,4]/10000.0D 
      total_flag[i]=total_flag[i]+flag[i,5]/1.E5+flag[i,6]/1.E6+flag[i,7]/1.E7+flag[i,8]/1.E8+flag[i,9]/1.E14                  ;/1.E9
      ;total_flag[i]=total_flag[i]+flag[i,10]/1.E10+flag[i,11]/1.E11+flag[i,12]/1.E12+flag[i,13]/1.E13+flag[i,14]/1.E14
    endfor


if keyword_set(plots) then begin 
    tplot_save,filename='/Users/temc2959/Desktop/LPW_daily_check_tplot/flags/data/flag_data_'+date   
print, 'testing to make sure that total_flag is saving the decimals correctly'
print,[flag[0,*],flag[n_elements(total_flag)/2,*]]
print,total_flag[0],format='(d20.14)'
print,total_flag[n_elements(total_flag)/2],format='(d20.14)'

flag_test=total_flag*scale

store_data, 'quality_flag', data={x:data_x, y:flag_test}
window,13

options, 'quality_flag',title='for test where you put in a flag of 100, it should drop to zero when there are thrusters'
options,'scale',psym=2
tplot,['quality_flag','mvn_lpw_thruster_flag', 'scale']

endif
    
end


