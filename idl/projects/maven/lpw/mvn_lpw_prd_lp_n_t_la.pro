
;+
;PROCEDURE:   mvn_lpw_prd_lp_n_t_la
;
; Routine takes IV-cureves from both booms and combines them into one tplot variable for L2-production. 
; The default swp1 and swp2 are from different subcycles.
; The sweep length can vary but the number of points in the sweep is fixed
; There will be error both in the current and the sweep potential
; The error information and flag information is taking also into consideration information from other sources such as spacecraft atitude.
;
;INPUTS:         
;   ext                                     ;'l1a' 'l1b' or 'l2'  what level of quality to produce ('l2' is full information to be archived)
;   
;KEYWORDS:
; 
;EXAMPLE:
; mvn_lpw_prd_lp_IV,'l1a'
;
;
;CREATED BY:   Laila Andersson  11-04-13
;FILE:         mvn_lpw_prd_lp_IV.pro
;VERSION:      1.0
;LAST MODIFICATION: 
; 2014-05-22   L. Andersson   sigificant update and working
;
;-

pro mvn_lpw_prd_lp_n_t_la,ext

print,'Running: mvn_lpw_prd_lp_n_t_la',' ',ext
t_routine    = SYSTIME(0) 
vers_prd     = 'version prd_lp_n_t  1.0'  ; the version number of this routine
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
    variables=['mvn_lpw_swp1_IV','mvn_lpw_swp2_IV']
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
            
       mvn_lpw_prd_lp_n_t,'NeTeUsc'
       get_data,'mvn_lpw_prd_IV',data=data_01
       get_data,'mvn_lpw_prd_Ne',data=data_02
       get_data,'mvn_lpw_prd_Te',data=data_03
       get_data,'mvn_lpw_prd_Usc',data=data_04
       data_l2_x       = data_01.x
       data_l2_y       = fltarr(n_elements(data_l2_x),10)
       data_l2_dy      = fltarr(n_elements(data_l2_x),10)
       data_l2_flag    = fltarr(n_elements(data_l2_x))
       data_l2_y(*,0)  =  data_04.y(*,0)
       data_l2_dy(*,0) =  SQRT(abs(data_04.y(*,0)))
       data_l2_y(*,1)  =  data_04.y(*,1)
       data_l2_dy(*,1) =  SQRT(abs(data_04.y(*,1)))
       data_l2_y(*,2)  =  data_04.y(*,2)
       data_l2_dy(*,2) =  SQRT(abs(data_04.y(*,2)))
       data_l2_y(*,3)  =  data_02.y(*,0)
       data_l2_dy(*,3) =  SQRT(abs(data_02.y(*,0)))
       data_l2_y(*,4)  =  data_02.y(*,1)
       data_l2_dy(*,4) =  SQRT(abs(data_02.y(*,1)))
       data_l2_y(*,5)  =  data_02.y(*,2)
       data_l2_dy(*,5) =  SQRT(abs(data_02.y(*,2)))
       data_l2_y(*,6)  =  data_03.y(*,0)
       data_l2_dy(*,6) =  SQRT(abs(data_03.y(*,0))) 
       data_l2_y(*,7)  =  data_03.y(*,1)
       data_l2_dy(*,7) =  SQRT(abs(data_03.y(*,1))) 
       data_l2_y(*,8)  =  data_03.y(*,2) 
       data_l2_dy(*,8) =  SQRT(abs(data_03.y(*,2)))
       data_l2_y(*,9)  =  data_03.y(*,2) *0.0   ; proxy
       data_l2_dy(*,9) =  data_03.y(*,2) *0.0    ; proxy      
       str_arr=['u0','u1','usc','ne','ne1','ne2','Te','Te1','Te2','nsc']  
       str_col=[ 4,    4,    0,   0,   2,    2,    0,    3,    3,   6]          
 
    
; -------------- I here use the 'w' flag routine, the 'lp' routine might be the same or different
       IF strpos(dlimit_merge.spice_kernel_flag, 'not') eq -1 THEN $                               ; what aspects should be evaluates
           check_varariables=['wake','sc_shadow','planet_shadow','sc_att','sc_pos','thrusters','gyros'] ELSE $  
           check_varariables=['fake_flag']  ; for now    
         mvn_lpw_prd_w_flag, data_l2_x,check_varariables,data_l2_flag, flag_info, flag_source, vers_prd  ; this is based on mag resolution                    
; -------------- merge the data        
 
               
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
;--------------------- SIS name: LPW.calibrated.w_spec (act/pas) -------------------  
;-------------------  There will be 1 CDF file per day --------------------   
                data_l2 =  create_struct(  $             ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data filed.    
                                         'x',    data_l2_x,  $     ; double 1-D arr
                                         'y',    data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   data_l2_dy,  $    ; same size as y
                                         'flag', data_l2_flag)     ;1-D 
                ;-------------------------------------------
                 dlimit_l2=create_struct(   $                           
                   'Product_name',                  'MAVEN LPW density and temperature Calibrated level '+ext, $
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
                   'Title',                         'MAVEN LPW n, T: L2', $   ;####            ;As this is L0b, we need all info here, as there's no prd file for this
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'n, T', $    ;### ARE UNITS CORRECT? v/m?
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'test dlimit file, flag.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'ExB notes', $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'The value of dy is the +/- error value on the data.', $
                   ;'dv_Var_notes',                   'Error on frequency', $
                   'flag_Var_notes',                'Flag variable', $
                   'xFieldnam',                     'x: More information', $      ;###
                   'yFieldnam',                     'y: More information', $
                   'vFieldnam',                     'v: More information', $
                   'dyFieldnam',                    'dy: More information', $
                   'dvFieldnam',                    'dv: More information', $
                   'flagFieldnam',                  'flag: More information', $
                   'derivn',                        'Equation of derivation', $    ;####
                   'sig_digits',                    '# sig digits', $ ;#####
                   'SI_conversion',                 'Convert to SI units', $  ;#### 
                   'MONOTON',                     dlimit_merge.MONOTON, $
                   'SCALEMIN',                    min(data_l2_y), $
                   'SCALEMAX',                    max(data_l2_y), $        ;..end of required for cdf production.
                   'generated_date'  ,            dlimit_merge.generated_date + ' # ' + t_routine ,$
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
                   'cal_datafile'    ,            ' TBD ', $
                   'cal_source'      ,            dlimit_merge.cal_source, $     
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[misc]', $                   
                   'cal_v_const1'    ,            'NA', $
                   'cal_v_const2'    ,            'NA', $
                   'zsubtitle'       ,            'NA') 
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
                  'char_size' ,                  limit.char_size   ,$    
                  'xtitle' ,                     limit.xtitle    ,$   
                  'ytitle' ,                     'Misc'    ,$   
                  'yrange' ,                     [min(data_l2_y,/na),max(data_l2_y,/na)]        ,$   
                  'noerrorbars',                  1, $  
                  'labels' ,                      str_arr,$   
                  'colors' ,                      str_col,$   
                  'labflag' ,                     1)                      
                ;---------------------------------------------
                store_data,'mvn_lpw_lp_n_t_'+ext,data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                ;---------------------------------------------    

;---------------------------------------------------------------------------------------------------
;                              end tplot production
;---------------------------------------------------------------------------------------------------
      
ENDIF ELSE print, "#### WARNING #### No data present; mvn_lpw_prd_lp_IV.pro skipped..."  


end
;*******************************************************************

