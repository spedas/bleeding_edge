
;+
;PROCEDURE:   mvn_lpw_prd_w_E12
;
;Routine takes active and passive E12 data, and combines them into one tplot variable for L2-production. 
;Act and Pas occur at different points in  the master cycle and so they never overlap in time. 
;They may have different time steps. 
;The error information and flag information is taking also into consideration information from other sources such as spacecraft atitude.
;   The tplot variables mvn_lpw_act_E12 and mvn_lpw_pas_E12 must be loaded into tplot memory before running this routine. 
;   Spacecraft attitude and position information will also be used if present.
;
;INPUTS:         
;
; - ext: file extension for the CDF file: L1a, L1b, L2
;   
;KEYWORDS:
; 
; 
;EXAMPLE:
; mvn_lpw_prd_w_E12
;
;
;CREATED BY:   Chris Fowler  10-23-13
;FILE:         mvn_lpw_prd_w_E12.pro
;VERSION:      1.0
;LAST MODIFICATION: 
;05-19-2014 CF: cleaned up layout, removed CDF save option (goes in a stand alone routine)
;
;-

pro mvn_lpw_prd_w_E12, ext


print,'Running: mvn_lpw_prd_w_E12 ',ext
t_routine    = SYSTIME(0) 
vers_prd     = 'version prd_w_E12  1.0'  ; the version number of this routine
;---------------------------------------------------------------------------------------------------
;Check Inputs:
;---------------------------------------------------------------------------------------------------
get_data,'mvn_lpw_pas5_e12',data=data
tmp=size(data)
if tmp[0] LT 1 then return
IF data.x[0] LT time_double('2014-12-20') THEN begin
print, "### WARNING ###: THe DC e12 is not good before 2015-12-20  Returning."
return
ENDIF 

IF size(ext, /type) NE 7 THEN BEGIN
    print, "### WARNING ###: Input 'ext' must be a string: l1a, l1b or l2. Returning."
    retall
ENDIF
;---------------------------------------------------------------------------------------------------
;    Check tplot variables exist before using them:
;---------------------------------------------------------------------------------------------------
    names = tnames(s)                                                              ;names is an array containing all tplot variable names currently in IDL memory.
    variables=['mvn_lpw_pas5_e12','mvn_lpw_act5_e12']
    missing_variable =' The following variables are missing: '                     ; keep track if the data existed or not

    IF total(strmatch(names, variables[0])) EQ 1 THEN get_data,variables[0],data=data0,limit=limit0,dlimit=dlimit0  ELSE missing_variable=[missing_variable,variables[0]+' was not found']
    IF total(strmatch(names, variables[1])) EQ 1 THEN get_data,variables[1],data=data1,limit=limit1,dlimit=dlimit1  ELSE missing_variable=[missing_variable,variables[1]+' was not found']
     found_variables='found :'
    If size(data0, /type) EQ 8 then found_variables=[found_variables,variables(0)]
    If size(data1, /type) EQ 8 then found_variables=[found_variables,variables(1)]
 
    IF n_elements(found_variables) GT 1 THEN BEGIN                                  ;big loop         
;---------------------------------------------------------------------------------------------------
;                  Merge the dlimit and limit information for tplot production in a routine called mvn_lpw_prd_limit_dlimt
;---------------------------------------------------------------------------------------------------  
       dlimit_merge = mvn_lpw_prd_merge_dlimit(found_variables)         
       get_data,found_variables(1),data=data,limit=limit                        ; use data for default time array and limit for limit_l2                     
;---------------------------------------------------------------------------------------------------
;                              dlimit and limit created
;---------------------------------------------------------------------------------------------------
 
 ;---------------------------------------------------------------------------------------------------
 ;                             Creating the data_l2 product:  
 ;                             Merge the data 
 ;                             Modify the error information with respect of atitude and other things, for L1b, L2
 ;                             Create a quality flag, for L1b, L2
 ;---------------------------------------------------------------------------------------------------      
        data_l2_x          =data0.x                                                            ; the default time array
        data_l2_y          =data0.y
        data_l2_dy         =data0.dy
        data_l2_flag       =1.0/10*data0.x*0+1+1*('mvn_lpw_act5_e12' EQ found_variables[1])    ; which is active and pasive  1=pas 2 =act
        IF n_elements(found_variables) GT 1 THEN BEGIN  
            data_l2_x          =[data0.x, data1.x]                                                              ; the default time array
            data_l2_y          =[data0.y, data1.y]        
            data_l2_dy         =[data0.dy, data1.dy] 
            data_l2_flag       =1.0/10*[data0.x*0+1, data1.x*0+2]    ; which is active and pasive  1=pas 2 =act
        endif
        tmp=sort(data_l2_x)
        data_l2_x=data_l2_x[tmp]
        data_l2_y=data_l2_y[tmp]
        data_l2_dy=data_l2_dy[tmp]
        data_l2_flag=data_l2_flag[tmp]
       
       ;---------------------------------------------------------------------------------------------------
       ;                  merge data
       ;---------------------------------------------------------------------------------------------------
         ;---------------------------------------------------------------------------------------------------
       ;                  get the units right
       ;---------------------------------------------------------------------------------------------------

       dl=12.68   ; this is hardcoded distance between the tips
       data_l2_y  = data_l2_y/dl  * 1000   ; units mV/m
       data_l2_dy = data_l2_dy/dl * 1000   ; units mV/m
       
       ;make sure if ither y or dy is Nan the other point are
       tmp=where(data_l2_y EQ !values.f_nan, nq)
       if nq GT 0 then data_l2_dy(tmp) = !values.f_nan
       tmp=where(data_l2_dy EQ !values.f_nan, nq)
       if nq GT 0 then data_l2_y(tmp) = !values.f_nan
                      
         ;------------------------------------------
         ;   calibration errorflag etc
         ;-----------------------------------------

         IF  (ext EQ 'l2') THEN BEGIN      ;(ext EQ 'l2')
           IF strpos(dlimit_merge.spice_kernel_flag, 'not') eq -1  THEN $                               ; what aspects should be evaluates
             check_variables=['wake','sc_shadow','planet_shadow','sc_att','sc_pos','thrusters','gyros'] ELSE $
             check_variables=['thrusters','gyros']  ; for now

           mvn_lpw_prd_w_flag, data_l2_x,check_varariables,flag, flag_info, flag_source, vers_prd ,scale ; this is based on mag resolution

         ENDIF     ELSE BEGIN  ;(ext EQ 'l1a') OR  (ext EQ 'l1b')
           ; this is just so we can do l1a and l1b data products
           check_variables =  'fake_flag'  ;
           flag_info         = ' The uncertanty of the values. 100 is the best quality '
           flag_source       = 'Example '+ ' mvn_lpw_anc_angles '+' mvn_lpw_anc_pos_mso '
           scale             = 1.0
           flag              = 0.0
         ENDELSE


         check_variables_str=check_variables[0]
         for i=1 , n_elements(check_variables)-1 do $
           check_variables_str=check_variables_str+' # '+check_variables[i]


          tmp_nan=finite(data_l2_y, /nan)
          tmp_value = (70. * (abs(data_l2_dy/data_l2_y) LT 100) + 40. * (abs(data_l2_dy/data_l2_y) LT 1000)*(abs(data_l2_dy/data_l2_y) GE 100))*(abs(data_l2_dy/data_l2_y) LE 1000)
          data_l2_flag  = scale *  tmp_value * (tmp_nan EQ 0) +data_l2_flag + flag  ; data_l2_flag above contain information of  which subcycle
   
   
         
      ;---------------------------------------------------------------------------------------------------
      ;                                end of creating the data_l2 product  
      ;---------------------------------------------------------------------------------------------------
      
      
      store_data,'e12_flag',data={x:data_l2_x,y:data_l2_flag}
      store_data,'e12_error',data={x:data_l2_x,y:data_l2_dy}
      
      ;---------------------------------------------------------------------------------------------------
      ;                            Create the L2 tplot variables
      ;---------------------------------------------------------------------------------------------------
      ;------------------ Variables created not stored in CDF files -------------------    
   
      ;------------------All information based on the SIS document-------------------         
                              
                    ;-------------------- tplot variable 'mvn_lpw_w_E12_L2' ------------------- 
                    ;--------------------- SIS name: LPW.calibrated.w_E12 -------------------  
                    ;-------------------  There will be 1 CDF file per day --------------------                    
                    data_l2 =  create_struct(        $       ; Which are used should follow the SIS document for this variable !! Look at: Table 13: : Contents for LPW.calibrated.w_E12, LPW.calibrated.w_E12_burst_lf, LPW.calibrated.w_E12_burst_mf, and LPW.calibrated.w_E12_burst_hf calibrated data files.     
                                             'x',     data_l2_x,  $     ; double 1-D arr
                                             'y',     data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                             'dy',    data_l2_dy,  $    ; same size as y
                                             ;'v',    data_l2_v,  $     ; same size as y
                                             ;'dv',   data_l2_dv,  $    ;same size as y
                                             'flag',  data_l2_flag)     ;1-D 
                    ;-------------------------------------------
                    ;Based off of dlimit_merge:
                dlimit_l2=create_struct(   $   
                   'Product_name',                'MVN LPW Electric Field data, level: '+ext, $                        
                   'Project',                     dlimit_merge.Project, $                          
                   'Source_name',                 dlimit_merge.Source_name, $     ;Required for cdf production...
                   'Discipline',                  dlimit_merge.Discipline, $
                   'Instrument_type',             dlimit_merge.Instrument_type, $
                   'Data_type',                   dlimit_merge.Data_type ,  $   
                   'Data_version',                dlimit_merge.Data_version, $ 
                   'Descriptor',                  dlimit_merge.Descriptor, $                 
                   'PI_name',                     dlimit_merge.PI_name, $
                   'PI_affiliation',              dlimit_merge.PI_affiliation, $
                   'TEXT',                        dlimit_merge.TEXT, $
                   'Mission_group',               dlimit_merge.Mission_group, $   
                   'Generated_by',                dlimit_merge.Generated_by, $
                   'Generation_date'  ,           dlimit_merge.generation_date + ' # ' + t_routine, $ 
                   'Rules_of_use',                dlimit_merge.Rules_of_use, $  
                   'Acknowledgement',             dlimit_merge.Acknowledgement, $                                  
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'Electric field data, in units of [mV/m]', $    ;### ARE UNITS CORRECT? v/m?
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Quality of Electric field.'+ flag_info, $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   ' Electric field' , $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'The value of dy is the +/- error value on the data.', $
                   ;'dv_Var_notes',                   'Error on frequency', $
                   'flag_Var_notes',                 'Quality of electric field measurement.', $
                   'xFieldnam',                     'x: Time', $      ;###
                   'yFieldnam',                     'y: Electric Field', $ 
                   ;'vFieldnam',                     'v: More information', $ 
                   'dyFieldnam',                     'dy: Error bar on electric field', $ 
                   ;'dvFieldnam',                    'dv: More information', $ 
                   'flagFieldnam',                  'flag: Quality of Density (see also Flag_info/Flag_source)', $ 
                   'derivn',                      'NA', $    ;####
                   'sig_digits',                  '# 2', $ ;#####
                   'SI_conversion',               ' 1 V/m = 1000 mV/m', $  ;####                                                                          
                   'Var_type',                    dlimit_merge.Var_type, $
                   'MONOTON', dlimit_merge.MONOTON, $
                   'SCALEMIN', min(data_l2_y), $
                   'SCALEMAX', max(data_l2_y), $        ;..end of required for cdf production.
                   't_epoch'         ,     dlimit_merge.t_epoch, $
                   'Time_start'      ,     dlimit_merge.Time_start, $
                   'Time_end'        ,     dlimit_merge.Time_end, $
                   'Time_field'      ,     dlimit_merge.Time_field, $
                   'SPICE_kernel_version', dlimit_merge.SPICE_kernel_version, $
                   'SPICE_kernel_flag',    dlimit_merge.SPICE_kernel_flag, $ 
                   'Flag_info'       ,     flag_info, $
                   'Flag_source'     ,     flag_source, $                      
                   'L0_datafile'     ,     dlimit_merge.L0_datafile , $ 
                   'cal_vers'        ,     dlimit_merge.cal_vers ,$     
                   'cal_y_const1'    ,     dlimit_merge.cal_y_const1 , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   'cal_y_const2'    ,     'Boom: ' +strcompress(dl,/remove_all)+' # '+check_variables_str  ,$
                   ;'cal_datafile'    ,     'No calibration file used' , $   ;not defined here    ;##### fill in blanks with 'NA'
                   'cal_source'      ,     'Merging: mvn_lpw_act_E12 and mvn_lpw_pas_E12', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[mV/m]')   ;, $                     
                   ;'cal_v_const1'    ,     dlimit.cal_v_const1 ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Merge level:' +strcompress(1,/remove_all) ,$  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[xx]')   ; units                         
                ;-------------  limit ---------------- 
                limit_l2=create_struct(   $              
                  'char_size' ,                  1.2   ,$    
                  'xtitle' ,                     limit.xtitle     ,$  
                  'ytitle' ,                     'E-field'    ,$  
                  'yrange' ,                     [-100.,100.]        ,$  
                  'ystyle'  ,                    1       , $
                  'noerrorbars',                 1 )                           
                  ;---------------------------------------------
                  store_data,'mvn_lpw_w_e12_'+ext,data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                  ;---------------------------------------------    
       
      ;---------------------------------------------------------------------------------------------------
      ;                              end tplot production
      ;---------------------------------------------------------------------------------------------------
      
ENDIF ELSE print, "#### WARNING #### No act or pas data present; mvn_lpw_prd_W_e12.pro skipped..."  ;over type_1 or type_2 eq 8

end
;*******************************************************************

