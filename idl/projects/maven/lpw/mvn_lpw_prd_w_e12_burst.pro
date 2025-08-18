
;+
;PROCEDURE:   mvn_lpw_prd_w_E12_burst
;
;Routine takes E12 burst data (lf/mf/hf) produce a L2-product. 
;The error information and flag information is taking into consideration information from other sources such as spacecraft atitude.
;   There are additional variables that need to be loaded
;   Presently this routine do not go an grab them if they are missing.
;
;INPUTS:         
;     type                                   ;'lf','mf','hf'
;    ext                                     ;'l1a' 'l1b' or 'l2'  what level of quality to produce ('l2' is full information to be archived)
;   
;KEYWORDS:
; - make_cdf                                ;make one L2-cdf for the NASA DPS archive
;    dir_cdf                                ; where to put the cdf file
; 
;EXAMPLE:
; mvn_lpw_prd_w_E12_burst,type
;
;
;CREATED BY:   Laila Andersson 11-06-2013
;FILE:         mvn_lpw_prd_w_E12_burst.pro
;VERSION:      1.0
;LAST MODIFICATION: 
; 2014-05-22   L. Andersson   sigificant update and working
; 2015-04-09   T. McEnulty - getting ready for L2 production
;-

pro mvn_lpw_prd_w_e12_burst,type,ext

print,'Running: mvn_lpw_prd_w_e12_burst', ' ',type,' ',ext
t_routine    = SYSTIME(0) 
vers_prd     = 'version prd_w_e12_burst_'+type+' 1.0'  ; the version number of this routine
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
    variables=['mvn_lpw_hsbm2_'+type,'mvn_lpw_hsbm_matrix_'+type]                    ; second variable to use for flag information
    missing_variable =' The following variables are missing: '                     ; keep track if the data existed or not
    IF total(strmatch(names, variables[0])) EQ 1 THEN get_data,variables[0],data=data,limit=limit,dlimit=dlimit_merge  ELSE missing_variable=[missing_variable,variables[0]+' was not found']
    IF total(strmatch(names, variables[1])) EQ 1 THEN get_data,variables[1],data=data_pkt
    found_variables='found :'
    If size(data, /type) EQ 8 then found_variables=[found_variables,variables[0]]

    IF n_elements(found_variables) GT 1 THEN BEGIN                                  ;big loop         
;---------------------------------------------------------------------------------------------------
;                  Merge the dlimit and limit information for tplot production in a routine called mvn_lpw_prd_limit_dlimt
;---------------------------------------------------------------------------------------------------  
;                     not needed only one variable
;---------------------------------------------------------------------------------------------------
;                              dlimit and limit created
;---------------------------------------------------------------------------------------------------
 
 ;---------------------------------------------------------------------------------------------------
 ;                             Creating the data_l2 product:  
 ;                             Merge the data (not for this one since it only uses PAS?)
 ;                             Modify the error information with respect of attitude and other things, for L1b, L2
 ;                             Create a quality flag, for L1b, L2
 ;---------------------------------------------------------------------------------------------------      
          data_l2_x = data.x                                  ; data comes from 'mvn_lpw_hsbm_'+type                                                      
          data_l2_y = data.y
          data_l2_dy = data.dy
          
          data_l2_pkt_x = data_pkt.x                                  ; data comes from 'mvn_lpw_hsbm_matrix'+type
          data_l2_pkt_y = data_pkt.y
          data_l2_pkt_dy = data_pkt.dy
          
     
  ;------------------------------------------
  ;   calibration errorflag etc
  ;-----------------------------------------
  
  ;get the units correct
  dl=12.68  ; this is hardcoded in, distance between the tips  (hard coded for now, but will later pull from instrument constants)
  data_l2_y   = data_l2_y  *1000./dl   ;; 1000 to convert to mV, dl for the boom distance
  data_l2_dy  = data_l2_dy *1000./dl   ;; 1000 to convert to mV, dl for the boom distance
  ;-----------------------------------------


  
  
  IF  (ext EQ 'l2') THEN BEGIN      ;(ext EQ 'l2')
    IF strpos(dlimit_merge.spice_kernel_flag, 'not') eq -1  THEN $                               ; what aspects should be evaluates
      check_variables=['wake','sc_shadow','planet_shadow','sc_att','sc_pos','thrusters','gyros'] ELSE $
      check_variables=['thrusters','gyros']  ; for now

;to speed up, use only one time per packet

    mvn_lpw_prd_w_flag, data_l2_pkt_x,check_varariables,flag, flag_info, flag_source, vers_prd ,scale ; this is based on mag resolution

;need also to get the  mode into the flag
    
    get_data,'mvn_lpw_hsbm_'+type+'_mode',data=mode
    if n_elements(flag) NE n_elements(mode.y) then stanna
    flag = flag + mode.y/100  ;first 2 decimals on the flag values is the mode number

 ;now translate this packe information into all the points in the array 
  
    if type EQ 'lf' then ss=1024 else ss=4096
    data_l2_flag = 0.*data_l2_y

    tmp_nan=finite(data_l2_y, /nan)
    tmp_value = (70. * (abs(data_l2_dy/data_l2_y) LT 100) + 40. * (abs(data_l2_dy/data_l2_y) LT 1000)*(abs(data_l2_dy/data_l2_y) GE 100))*(abs(data_l2_dy/data_l2_y) LE 1000)

; ------these two steps could be merge when individual points is evaluated 
    for i=0,n_elements(flag)-1 do begin
      data_l2_flag[i*ss:i*ss+ss-1]=flag[i]      
    endfor    
    tmp_nan=finite(data_l2_y, /nan)
    tmp_value = (70. * (abs(data_l2_dy/data_l2_y) LT 100) + 40. * (abs(data_l2_dy/data_l2_y) LT 1000)*(abs(data_l2_dy/data_l2_y) GE 100))*(abs(data_l2_dy/data_l2_y) LE 1000)
    data_l2_flag  = scale *  tmp_value * (tmp_nan EQ 0) +data_l2_flag  
; ------ END these two steps could be merge when individual points is evaluated

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
 
;---------------------------------------------------------------------------------------------------
;                                end of creating the data_l2 product  
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
;                            Create the L2 tplot variables
;---------------------------------------------------------------------------------------------------
;------------------ Variables created not stored in CDF files -------------------    
;   
;                            None    
;                             
;------------------ Variables created not stored in CDF files -------------------     
;------------------All information based on the SIS document-------------------                              
;-------------------- tplot variable 'mvn_lpw_w_spec_L2' ------------------- 
;--------------------- SIS name: W_E12_burst ??    -------------------  
;-------------------  There will be 1 CDF file per day --------------------   
                data_l2 =  create_struct(  $             ; Which are used should follow the SIS document for this variable    
                                         'x',    data_l2_x,  $     ; double 1-D arr
                                         'y',    data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   data_l2_dy,  $    ; same size as y
                                         'flag', data_l2_flag)     ;1-D 
                ;-------------------------------------------
                 dlimit_l2=create_struct(   $                           
                   'Product_name',                  'MAVEN LPW E12 burst, level '+ext, $   ;; add lf, mf, hf?
                   'Project',                       dlimit_merge.Project, $
                   'Source_name',                   dlimit_merge.Source_name, $     ;Required for cdf production...
                   'Discipline',                    dlimit_merge.Discipline, $
                   'Instrument_type',               dlimit_merge.Instrument_type, $
                   'Data_type',                     'CAL>calibrated',  $
                   'Data_version',                  dlimit_merge.Data_version, $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                   'Descriptor',                    dlimit_merge.Descriptor, $
                   'PI_name',                       dlimit_merge.PI_name, $
                   'PI_affiliation',                dlimit_merge.PI_affiliation, $
                   'TEXT',                          dlimit_merge.TEXT, $
                   'Mission_group',                 dlimit_merge.Mission_group, $
                   'Generated_by',                  dlimit_merge.Generated_by,  $
                   'Generation_date',               dlimit_merge.Generation_date+' # '+t_routine, $   ;Gives the date and time the data is derived and the CDF file was created - can be multiple times ponts
                   'Rules_of_use',                  dlimit_merge.Rules_of_use, $
                   'Acknowledgement',               dlimit_merge.Acknowledgement,   $  
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'Electric Field burst [mV/m]', $    ;### ARE UNITS CORRECT? should be mv/m
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Uncertanty on the electric field (-/+)', $     ;###                     ;; don't know what do use for error, keep what is already there?
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'test dlimit file, flag.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Electric Field burst [mV/m]', $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'Uncertanty on the electric field (-/+)', $
                   ;'dv_Var_notes',                   'Error on frequency', $
                   'flag_Var_notes',                'Quality of electric field measurement.', $
                   'xFieldnam',                     'x: Time', $      ;###
                   'yFieldnam',                     'y: Electric Field burst [mV/m]', $
                   ;'vFieldnam',                     'v: More information', $
                   'dyFieldnam',                    'dy: Uncertanty on the electric field (-/+)', $
                   ;'dvFieldnam',                    'dv: More information', $
                   'flagFieldnam',                  'flag: Quality of Density (see also Flag_info/Flag_source)', $
                   'derivn',                        'N/A', $    ;####                       
                   'sig_digits',                    '# 2', $ ;#####                                                       ;; more?
                   'SI_conversion',                 'mV == 1E-3 V', $  ;####    
                   'MONOTON',                      'INCREASE', $
                   'SCALEMIN',                    min(data_l2_y), $
                   'SCALEMAX',                    max(data_l2_y), $        ;..end of required for cdf production.
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
                   'cal_y_const2'    ,            'N/A',$
                   'cal_datafile'    ,            'N/A', $                                             ;; what to put here?
                   'cal_source'      ,            dlimit_merge.cal_source+' # '+check_variables_str, $     
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[mV/m]');, $                   
;                   'cal_v_const1'    ,            'NA', $
;                   'cal_v_const2'    ,            'NA', $
;                   'zsubtitle'       ,            'NA') 
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
                  'char_size' ,                  limit.char_size   ,$    
                  'xtitle' ,                     limit.xtitle    ,$   
                  'ytitle' ,                     'E-field'    ,$   
                  'yrange' ,                     [-100.,100.]        ,$   
                  'ystyle'  ,                    1       , $
                  'noerrorbars',                 1 )
                 ; 'ylog'   ,                     1              ,$ 
                 ; 'ztitle' ,                     'Power' ,$   
                 ; 'zrange' ,                     [1e-2,1e6],$
                 ; 'zlog'  ,                      1  ,$
                 ; 'spec'  ,                      1  )
                 ; 'labels' ,                     limit.labels,$   ; not used for this product
                 ; 'colors' ,                     limit.colors,$   ; not used for this product 
                 ; 'labflag' ,                    limit.labflag)   ; not used for this product                    
                ;---------------------------------------------
                store_data,'mvn_lpw_w_e12_burst_'+type+'_'+ext,data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                ;---------------------------------------------    

;---------------------------------------------------------------------------------------------------
;                              end tplot production
;---------------------------------------------------------------------------------------------------
      
ENDIF ELSE print, '#### WARNING #### No data present; mvn_lpw_prd_w_e12_burst.pro skipped... ',type,' ',ext  


end
;*******************************************************************

