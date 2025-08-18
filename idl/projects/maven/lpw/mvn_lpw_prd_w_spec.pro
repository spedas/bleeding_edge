
;+
;PROCEDURE:   mvn_lpw_prd_w_spec
;
;Takes LF, MF, and HF spectra (from act or pas) and combines them into one tplot spectra for L2-production.  
;The error information and flag information is taking also into consideration information from other sources such as spacecraft atitude.
;   The tplot variables mvn_lpw_act_E12 and mvn_lpw_pas_E12 must be loaded into tplot memory before running this routine. 
;   There are additional variables that need to be loaded
;   Presently this routine do not go an grab them if they are missing.
;
;INPUTS:         
; - type                                    ;'act'or 'pas' which subcycle to work with 
;   ext                                     ;'l1a' 'l1b' or 'l2'  what level of quality to produce ('l2' is full information to be archived)
;   
; 
;EXAMPLE:
; mvn_lpw_prd_w_spec,type,ext
;
;
;CREATED BY:   Laila Andersson  03-30-15
;FILE:         mvn_lpw_prd_w_spec.pro
;VERSION:      1.2
;LAST MODIFICATION: 
; 2014-05-22   L. Andersson   sigificant update and working
; 2015-03-30   L. Andersson    update to make the firs L2 production
;-

pro mvn_lpw_prd_w_spec,type,ext


print,'Running: mvn_lpw_prd_w_spec', ' ',type,' ',ext
t_routine    = SYSTIME(0) 
vers_prd     = 'version prd_w_spec_'+type+' 1.2'  ; the version number of this routine
;---------------------------------------------------------------------------------------------------
;Check Inputs:
;---------------------------------------------------------------------------------------------------
IF size(ext, /type) NE 7 THEN BEGIN
    print, "### WARNING ###: Input 'ext' must be a string: l1a, l1b or l2. Returning."
    retall
ENDIF
;---------------------------------------------------------------------------------------------------
;    Check tplot variables exist before using them:
;---------------------------------------------------------------------------------------------------
    names = tnames(s)                                                              ;names is an array containing all tplot variable names currently in IDL memory.
    variables=['mvn_lpw_spec2_lf_'+type,'mvn_lpw_spec2_mf_'+type,'mvn_lpw_spec2_hf_'+type]
    variables2=['mvn_lpw_spec_lf_'+type+'_mode','mvn_lpw_spec_mf_'+type+'_mode','mvn_lpw_spec_hf_'+type+'_mode']
   missing_variable =' The following variables are missing: '                     ; keep track if the data existed or not

    IF total(strmatch(names, variables[0])) EQ 1 THEN get_data,variables[0],data=data0,limit=limit0,dlimit=dlimit0  ELSE missing_variable=[missing_variable,variables[0]+' was not found']
    IF total(strmatch(names, variables[1])) EQ 1 THEN get_data,variables[1],data=data1,limit=limit1,dlimit=dlimit1  ELSE missing_variable=[missing_variable,variables[1]+' was not found']
    IF total(strmatch(names, variables[2])) EQ 1 THEN get_data,variables[2],data=data2,limit=limit2,dlimit=dlimit2  ELSE missing_variable=[missing_variable,variables[2]+' was not found']
    found_variables='found :'
    If size(data0, /type) EQ 8 then found_variables=[found_variables,variables(0)]
    If size(data1, /type) EQ 8 then found_variables=[found_variables,variables(1)]
    If size(data2, /type) EQ 8 then found_variables=[found_variables,variables(2)]

    IF n_elements(found_variables) GT 1 THEN BEGIN                                  ;big loop         
;---------------------------------------------------------------------------------------------------
;                  Merge the dlimit and limit information for tplot production in a routine called mvn_lpw_prd_limit_dlimt
;---------------------------------------------------------------------------------------------------  
       dlimit_merge = mvn_lpw_prd_merge_dlimit(found_variables)         
       get_data,found_variables(1),data=data,limit=limit,dlimit=dlimit                        ; use data for default time array and limit for limit_l2                     
       get_data,variables2(0),data=data_mode                                            ; use data for default time array and limit for limit_l2                     
       get_data,'mvn_lpw_'+type+'_V1',data=datV1                                            ; use data for default time array and limit for limit_l2                     
       get_data,'mvn_lpw_'+type+'_V2',data=datV2                                            ; use data for default time array and limit for limit_l2                     
;---------------------------------------------------------------------------------------------------
;                              dlimit and limit created
;---------------------------------------------------------------------------------------------------
 
 ;---------------------------------------------------------------------------------------------------
 ;                             Creating the data_l2 product:  
 ;                             Merge the data 
 ;                             Modify the error information with respect of atitude and other things, for L1b, L2
 ;                             Create a quality flag, for L1b, L2
 ;---------------------------------------------------------------------------------------------------      
       data_l2_x=data.x                                                               ; the default time array to be rewritten
     ;  mvn_lpw_prd_add_time,data_l2_x,data0
       mvn_lpw_prd_add_time,data_l2_x,data1, 'spectra'
       mvn_lpw_prd_add_time,data_l2_x,data2, 'spectra'; ----- get the new frequency spectra: might be moved into a seperate routine if so mvn_lpw_pdr_w_spec_merge ----- 


; ----- this is where the frequencies is selected ------
          nn=n_elements(data_l2_x)
          f1_lf   = 0
          f2_lf   = 47 ;of 56
          f1_mf   = 4
          f2_mf   = 47 ;of 56
          f1_hf   = 4
          f2_hf   = 127 ; of 128
          ff_no   = f2_lf-f1_lf+1   +  f2_mf-f1_mf+1 + f2_hf-f1_hf+1    ; how many frequencies
          ff_aa   = [0,(f2_lf-f1_lf),(f2_lf-f1_lf+1),(f2_lf-f1_lf+1)+(f2_mf-f1_mf),(f2_lf-f1_lf+1)+(f2_mf-f1_mf+1),ff_no-1]
;----------------
          data_l2_y                          = fltarr(nn,ff_no)
          data_l2_dy                         = fltarr(nn,ff_no)
          data_l2_v                          = fltarr(nn,ff_no)
          data_l2_dv                         = fltarr(nn,ff_no) 
          data_l2_flag                       = dblarr(nn)
          data_l2_mode                       = fltarr(nn)         
          data_l2_cycle                      = fltarr(nn)

    if min(data0.dv)                lt 0 then stanna
    if min(data1.dv)                lt 0 then stanna
    if min(data2.dv)                lt 0 then stanna
            
            
          nnV1=n_elements(datV1.x)     
          nnV2=n_elements(datV2.x)     
          IF size(data0, /type) EQ 8 THEN  BEGIN          
             index  = fltarr(n_elements(data0.x))         
             indexV  = fltarr(n_elements(data0.x))      
             FOR  i = 0,n_elements(data0.x)-1 do begin
                 tmp=min(abs(data_l2_x - data0.x(i)),nn)
                 index[i] = nn                      
                 tmp = min(abs(datV1.x-data0.x(i)),nnV1)
                 tmp = min(abs(datV2.x-data0.x(i)),nnV2)
                 indexV[i] = (mean( datV1.y[ (nnV1-10)>0 : (nnV1+10)<(nnV1-1) ] GT -20)*(mean(datV1.y[ (nnV1-10)>0 : (nnV1+10)<(nnV1-1) ]) LT 20))* $
                             (mean( datV2.y[ (nnV2-10)>0 : (nnV2+10)<(nnV2-1) ] GT -20)*(mean(datV2.y[ (nnV2-10)>0 : (nnV2+10)<(nnV2-1) ]) LT 20))                
             ENDFOR                
               data_l2_y( index,ff_aa[0]:ff_aa[1])   = data0.y(*,f1_lf:f2_lf) 
               data_l2_dy(index,ff_aa[0]:ff_aa[1])   = data0.dy(*,f1_lf:f2_lf)
               data_l2_v( index,ff_aa[0]:ff_aa[1])   = data0.v(*,f1_lf:f2_lf)
               data_l2_dv(index,ff_aa[0]:ff_aa[1])   = data0.dv(*,f1_lf:f2_lf)
               
          ;;   data_l2_flag(index)   = 80. - 25 * (total(data0.y(*,f1_lf:f2_lf),2 ) LT 1e-10)   
               data_l2_flag(index)   = 80. - 25 * (total(data0.y(*,f1_lf:f2_lf),2 ) LT 1e-9)
      ENDIF   
          ;remove data when V1 and V2 is at extreme from LF frequency band
           tmp=where(indexV EQ 0,nq)
           FOR i=ff_aa[0],ff_aa[1] do  data_l2_y[tmp,i]=!values.f_nan
                
          IF size(data1, /type) EQ 8 THEN  BEGIN
             index  = fltarr(n_elements(data1.x))      
             FOR  i = 0,n_elements(data1.x)-1 do begin
                 tmp=min(abs(data_l2_x - data1.x(i)),nn)
                 index[i] = nn          
            ENDFOR                
               data_l2_y(index,ff_aa[2]:ff_aa[3])   = data1.y(*,f1_mf:f2_mf)
               data_l2_dy(index,ff_aa[2]:ff_aa[3])  = data1.dy(*,f1_mf:f2_mf)
               data_l2_v(index,ff_aa[2]:ff_aa[3])   = data1.v(*,f1_mf:f2_mf)
               data_l2_dv(index,ff_aa[2]:ff_aa[3])  = data1.dv(*,f1_mf:f2_mf)
          ENDIF      
          IF size(data2, /type) EQ 8 THEN  BEGIN
              index  = fltarr(n_elements(data2.x))      
             FOR  i = 0,n_elements(data2.x)-1 do begin
                 tmp=min(abs(data_l2_x - data2.x(i)),nn)
                 index[i] = nn          
            ENDFOR                
               data_l2_y(index,ff_aa[4]:ff_aa[5])   = data2.y(*,f1_hf:f2_hf) 
               data_l2_dy(index,ff_aa[4]:ff_aa[5])  = data2.dy(*,f1_hf:f2_hf)
               data_l2_v(index,ff_aa[4]:ff_aa[5])   = data2.v(*,f1_hf:f2_hf)
               data_l2_dv(index,ff_aa[4]:ff_aa[5])  = data2.dv(*,f1_hf:f2_hf)
          ENDIF        
          
                   
           index2  = fltarr(n_elements(data_l2_x)) 
           FOR  i = 0,n_elements(data_l2_x)-1 do begin
                 nn2 = min(abs(data_mode.x-data_l2_x(i)),nq2)
                 index2[i] = nq2          
           ENDFOR                
           
        ;   data_l2_flag[*] =  80 * ((data_mode.y[index2] NE 8)) + (type EQ 'pas')/10 + 1.0*(total(data_l2_y,2) GT 1e-4)/100 
           
          tmp=where(data_mode.y[index2] EQ 8,nq) ; The instrument is not in electric field mode
          FOR i=0,ff_no-1 do  begin
                  data_l2_y[tmp,i]=!values.f_nan
          ENDFOR
           
 
          
          if min(data_l2_dy)                lt 0 then stanna
          if min(data_l2_dv)                lt 0 then stanna

 
                      
  ;------------------------------------------
  ;   calibration errorflag etc
  ;-----------------------------------------
  
     IF  (ext EQ 'l2') THEN BEGIN      ;(ext EQ 'l2')    
       IF strpos(dlimit_merge.spice_kernel_flag, 'not') eq -1  THEN $                               ; what aspects should be evaluates
           check_varariables=['wake','sc_shadow','planet_shadow','sc_att','sc_pos','thrusters','gyros'] ELSE $
           check_varariables=['fake_flag']  ; for now
          
       mvn_lpw_prd_w_flag, data_l2_x,check_varariables,flag, flag_info, flag_source, vers_prd ,scale ; this is based on mag resolution
    
      
              
      ENDIF     ELSE BEGIN  ;(ext EQ 'l1a') OR  (ext EQ 'l1b') 
           ; this is just so we can do l1a and l1b data products            
           check_varariables =  'fake_flag'  ;
           flag_info         = ' The uncertanty of the values 100. is the best quality '
           flag_source       = 'Example '+ ' mvn_lpw_anc_angles '+' mvn_lpw_anc_pos_mso '
           scale             = 1.0
           flag              = 0.0      
      ENDELSE          

      ;bad_lf=  (total(data_l2_y[*,1:46],2,/nan) GT 1e-11)     ;if there is data in the lf range
      ;bad_hf=  (total(data_l2_y[*,150:215],2,/nan) LT 1e-11)  ;that tehe gain has been corrected for
      bad_lf=  (total(data_l2_y[*,1:46],2,/nan) GT 1e-10)     ;if there is data in the lf range
      bad_hf=  (total(data_l2_y[*,150:215],2,/nan) LT 1e-10)  ;that there gain has been corrected for

      data_l2_flag  = DOUBLE( scale * data_l2_flag * bad_lf * bad_hf + (1+(type EQ 'pas'))/10 + 1.0 * bad_lf/100 + 3.0 * bad_hf/100+ flag ) 


;print,1.0*(total(data_l2_y,2) GT 1e-4)/100
;print,' ####', (1+(type EQ 'pas'))/10 , ' $$$ ',type

;---------------------------------------------------------------------------------------------------
;                                end of creating the data_l2 product  
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
;                            Create the L2 tplot variables
;---------------------------------------------------------------------------------------------------
;------------------ Variables created not stored in CDF files -------------------    
; 
store_data,'spec_flag',data={x:data_l2_x,y:data_l2_flag} 
store_data,'spec_decimal',data={x:data_l2_x,y:flag}

                       
;                             
;------------------ Variables created not stored in CDF files -------------------     
;------------------All information based on the SIS document-------------------                              
;-------------------- tplot variable 'mvn_lpw_w_spec_L2' ------------------- 
;--------------------- SIS name: LPW.calibrated.w_spec (act/pas) -------------------  
;-------------------  There will be 1 CDF file per day --------------------   
                data_l2 =  create_struct(  $             ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data filed.    
                                         'x',    data_l2_x,  $     ; double 1-D arr
                                         'y',    data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   data_l2_dy,  $    ; same size as y
                                         'v',    data_l2_v,  $     ; same size as y
                                         'dv',   data_l2_dv,  $    ;same size as y  <--- here this is frequemcy width
                                         'flag', data_l2_flag)     ;1-D 
                ;-------------------------------------------
                 dlimit_l2=create_struct(   $                           
                   'Product_name',                'MVN LPW Electric field Spectra, Level: '+ext, $                        
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
                   'y_catdesc',                     'y: Spectra power [(V/m)^2/Hz]', $    ;### ARE UNITS CORRECT? v/m?
                   'v_catdesc',                     'v: Center Frequency [Hz]', $    ;###
                   'dy_catdesc',                    'dy: Uncertainty in Power [(V/m)^2/Hz]', $     ;###
                   'dv_catdesc',                    'dv: Frequency Width [Hz]', $   ;###
                   'flag_catdesc',                  'Quality of Wave power.'+ flag_info, $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'For mode: '+strtrim(type,2), $
                   'v_Var_notes',                   'Center Frequency ', $
                   'dy_Var_notes',                  'Uncertainty in Power [(V/m)^2/Hz]', $
                   'dv_Var_notes',                  'Frequency width [Hz]', $
                   'flag_Var_notes',                'Quality flag', $
                   'xFieldnam',                     'x: Time', $      ;###
                   'yFieldnam',                     'y: Power', $ 
                   'vFieldnam',                     'v: Frequency', $ 
                   'dyFieldnam',                    'dy: dPower', $ 
                   'dvFieldnam',                    'dv: Frequency width', $ 
                   'flagFieldnam',                  'flag: Quality', $ 
                   'derivn',                         'NA', $ ;dlimit_merge.derivn, $    ;####
                   'sig_digits',                     2, $ ;dlimit_merge.sig_digits, $ ;#####
                   'SI_conversion',                  'NA', $ ; dlimit_merge.SI_conversion, $  ;####                                                                          
                   'Var_type',                       'data', $;dlimit_merge.Var_type, $
                   'MONOTON',                     dlimit_merge.MONOTON, $
                   'SCALEMIN',                    min(data_l2_v), $
                   'SCALEMAX',                    max(data_l2_v), $        ;..end of required for cdf production.
                   't_epoch'         ,            dlimit_merge.t_epoch, $
                   'Time_start'      ,            dlimit_merge.Time_start, $
                   'Time_end'        ,            dlimit_merge.Time_end, $
                   'Time_field'      ,            dlimit_merge.Time_field, $
                   'SPICE_kernel_version',        dlimit_merge.SPICE_kernel_version, $
                   'SPICE_kernel_flag',           dlimit_merge.SPICE_kernel_flag, $ 
                   'Flag_info'       ,            flag_info, $
                   'Flag_source'     ,            flag_source, $                      
                   'L0_datafile'     ,            dlimit_merge.L0_datafile, $ 
                   'cal_vers'        ,            dlimit_merge.cal_vers+ ' # ' + vers_prd,$     
                   'cal_y_const1'    ,            dlimit_merge.cal_y_const1, $
                   'cal_y_const2'    ,            'Merge level:' +strcompress(1,/remove_all)   ,$
                   'cal_datafile'    ,            dlimit_merge.cal_datafile, $
                   'cal_source'      ,            dlimit_merge.cal_source, $     
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[Hz]', $                   
                   'cal_v_const1'    ,            dlimit_merge.cal_v_const1, $
                   'cal_v_const2'    ,            'Merge level:' +strcompress(f1_lf,/remove_all)+' '+strcompress(f2_lf,/remove_all)+' '+strcompress(f1_mf,/remove_all)+' ' $
                                                                  +strcompress(f2_mf,/remove_all)+' '+strcompress(f1_hf,/remove_all)+' '+strcompress(f2_hf,/remove_all) , $
                   'zsubtitle'       ,            '[(V/m)^2/Hz]') 
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
                  'char_size' ,                  limit.char_size   ,$    
                  'xtitle' ,                     limit.xtitle    ,$   
                  'ytitle' ,                     'Frequency ('+type+')'    ,$   
                  'yrange' ,                     [1,2e6]        ,$   
                  'ystyle'  ,                    1        ,$ 
                  'ylog'   ,                     1              ,$ 
                  'ztitle' ,                     'Power [(V/m)^2/Hz]' ,$   
                  'zrange' ,                     [1e-14,1e-5],$
                  'zlog'  ,                      1  ,$
                  'spec'  ,                      1  )
                 ; 'noerrorbars',     limit_merge.noerrorbars, $  ; not used for this product
                 ; 'labels' ,        limit.labels,$   ; not used for this product
                 ; 'colors' ,        limit.colors,$   ; not used for this product 
                 ; 'labflag' ,       limit.labflag)   ; not used for this product                    
                ;---------------------------------------------
                store_data,'mvn_lpw_w_spec_'+type+'_'+ext,data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                ;---------------------------------------------    


options, '*spec*'+ext,  no_interp = 1
options, '*spec*'+ext,  DATAGAP   = 256


;---------------------------------------------------------------------------------------------------
;                              end tplot production
;---------------------------------------------------------------------------------------------------
      
ENDIF ELSE print, "#### WARNING #### No act or pas data present; mvn_lpw_prd_w_spec.pro skipped..."  

end
;*******************************************************************

