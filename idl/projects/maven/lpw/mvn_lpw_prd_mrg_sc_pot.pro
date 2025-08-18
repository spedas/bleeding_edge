
;+
;PROCEDURE:   mvn_lpw_prd_mrg_sc_pot
;
;Routine takes V1 and V2 data from all subcycles and combine them to one product.
;Note for some sub-cycles both V1 and V2 is produced simultaniously.
;Presently the sc_pot derived from the IV-sweep -fit is not used   
;The cadence change between the different sub-cycles and the different operation modes
;The error information and flag information is taking also into consideration information from other sources such as spacecraft atitude.
;   The tplot variables must be loaded into tplot memory before running this routine. 
;   Presently this routine do not go an grab them if they are missing.
;
;INPUTS:         
;   ext                                     ;'l1a' 'l1b' or 'l2'  what level of quality to produce ('l2' is full information to be archived)
;   
;KEYWORDS:
; 
;EXAMPLE:
; mvn_lpw_prd_mrg_sc_pot
;
;
;CREATED BY:   Laila Andersson 11-04-2013
;FILE:         mvn_lpw_prd_mrg_sc_pot.pro
;VERSION:      2.1
;LAST MODIFICATION:
; 2014-05-22   L. Andersson   sigificant update and working 
; 2015-05-22   L. Andersson   update to get the L2 working
;
;-

pro mvn_lpw_prd_mrg_sc_pot,ext

print,'Running: mvn_lpw_prd_mrg_sc_pot',' ',ext
t_routine    = SYSTIME(0) 
vers_prd     = 'version prd_mrg_sc_pot 2,1'  ; the version number of this routine
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
    variables=['mvn_lpw_swp1_V2','mvn_lpw_swp2_V1','mvn_lpw_act_V1','mvn_lpw_pas_V1','mvn_lpw_act_V2','mvn_lpw_pas_V2']
    missing_variable =' The following variables are missing: '                     ; keep track if the data existed or not

    IF total(strmatch(names, variables[0])) EQ 1 THEN get_data,variables[0],data=data0,limit=limit0,dlimit=dlimit0  ELSE missing_variable=[missing_variable,variables[0]+' was not found']
    IF total(strmatch(names, variables[1])) EQ 1 THEN get_data,variables[1],data=data1,limit=limit1,dlimit=dlimit1  ELSE missing_variable=[missing_variable,variables[1]+' was not found']
    IF total(strmatch(names, variables[2])) EQ 1 THEN get_data,variables[2],data=data2,limit=limit2,dlimit=dlimit2  ELSE missing_variable=[missing_variable,variables[2]+' was not found']
    IF total(strmatch(names, variables[3])) EQ 1 THEN get_data,variables[3],data=data2,limit=limit3,dlimit=dlimit3  ELSE missing_variable=[missing_variable,variables[3]+' was not found']
    IF total(strmatch(names, variables[4])) EQ 1 THEN get_data,variables[4],data=data3,limit=limit4,dlimit=dlimit4  ELSE missing_variable=[missing_variable,variables[4]+' was not found']
    IF total(strmatch(names, variables[5])) EQ 1 THEN get_data,variables[5],data=data4,limit=limit5,dlimit=dlimit5  ELSE missing_variable=[missing_variable,variables[5]+' was not found']
    found_variables='found :'
    If size(data0, /type) EQ 8 then found_variables=[found_variables,variables(0)]
    If size(data1, /type) EQ 8 then found_variables=[found_variables,variables(1)]
    If size(data2, /type) EQ 8 then found_variables=[found_variables,variables(2)]
    If size(data3, /type) EQ 8 then found_variables=[found_variables,variables(3)]
    If size(data4, /type) EQ 8 then found_variables=[found_variables,variables(4)]
    If size(data5, /type) EQ 8 then found_variables=[found_variables,variables(5)]

    IF n_elements(found_variables) GT 1 THEN BEGIN                                  ;big loop         
;---------------------------------------------------------------------------------------------------
;                  Merge the dlimit and limit information for tplot production in a routine called mvn_lpw_prd_limit_dlimt
;---------------------------------------------------------------------------------------------------  
       dlimit_merge = mvn_lpw_prd_merge_dlimit(found_variables)         
       get_data,found_variables(1),data=data,limit=limit,dlimit=dlimit                        ; use data for default time array and limit for limit_l2                     
;---------------------------------------------------------------------------------------------------
;                              dlimit and limit created
;---------------------------------------------------------------------------------------------------
 
 ;---------------------------------------------------------------------------------------------------
 ;                             Creating the data_l2 product:  
 ;                             Merge the data 
 ;                             Modify the error information with respect of atitude and other things, for L1b, L2
 ;                             Create a quality flag, for L1b, L2
 ;---------------------------------------------------------------------------------------------------      
 
 if 'n' EQ 'y' then begin    ; later on I will use V1 and V2 ..... but for now only LP
  
 
          data_l2_x=data.x                                                               ; the default time array
          mvn_lpw_prd_add_time,data_l2_x,data0
          mvn_lpw_prd_add_time,data_l2_x,data1
          mvn_lpw_prd_add_time,data_l2_x,data2
          mvn_lpw_prd_add_time,data_l2_x,data3
          mvn_lpw_prd_add_time,data_l2_x,data4
          mvn_lpw_prd_add_time,data_l2_x,data5  
 
 endif 
 
 get_data,'mvn_lpw_lp_n_t_'+ext,data=data,dlimit=dlimit_merge
 
 tmp=size(data)
 if tmp[0] GT 0 then begin

 data_l2_x    = data.x
 data_l2_y    = data.y[*,2] 
 data_l2_dy   = abs(data.dv[*,2])
 data_l2_dv   = abs(data.dy[*,2])
 data_l2_flag = data.flag  ; .1 and .2 means LP-boom1 and LP-boom-2
 
 ; later on .3 .4 .5 will be used for V1 pas/act/swp  .6 .7. 8. for V2 pas/act/swp
; tmp=where(data_l2_y GT -0or data_l2_y LT -30,nq)
; if nq GT 0 then begin
;     data_l2_y[tmp]    = !values.f_nan
;     data_l2_dy[tmp]   = !values.f_nan
;     data_l2_dv[tmp]   = !values.f_nan
;     data_l2_flag[tmp] = !values.f_nan
; endif
                         

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

                         data_l2_flag   =  scale*data_l2_flag ; + flag  ; data_l2_flag above contain information of  which source

tmp=where(finite(data.y) EQ 0,nq)
if nq GT 1 then begin
  data_l2_dy(tmp)   = !values.f_nan
  data_l2_dv(tmp)   = !values.f_nan
  data_l2_flag(tmp) = !values.f_nan
endif



  ;---------------------------------------------------------------------------------------------------
  ;        mvn_lpw_prd_mrg_sc_calib,data_l2_x,data_l2_flag,data0,data1,data2,data3,data4,data5,data_l2_y,data_l2_dy   
  ;---------------------------------------------------------------------------------------------------
 
  
  
  
;---------------------------------------------------------------------------------------------------
;                                end of creating the data_l2 product  
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
;                            Create the L2 tplot variables
;---------------------------------------------------------------------------------------------------
;------------------ Variables created not stored in CDF files -------------------    
;   

store_data,'mrgsc_flag' ,data={x:data_l2_x,y:data_l2_flag}

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
                                         'dv',   data_l2_dy,  $    ; same size as y
                                         'flag', data_l2_flag)     ;1-D 
                ;-------------------------------------------
                 dlimit_l2=create_struct(   $                           
                   'Product_name',                  'MAVEN LPW SC potential level '+ext, $
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
                   'y_catdesc',                     'Spacecraft potential [V]', $    ;### ARE UNITS CORRECT? v/m?
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Upper Uncertainty of potential', $     ;###
                   'dv_catdesc',                    'Lower Uncertainty of potential', $   ;###
                   'flag_catdesc',                  'Quality of Potential.'+ flag_info, $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'SC Potential', $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                   'Upper Uncertainty of potential', $
                   'dv_Var_notes',                   'Lower Uncertainty of potential', $
                   'flag_Var_notes',                'Quality Flag', $
                   'xFieldnam',                     'x: Time', $      ;###
                   'yFieldnam',                     'y: SC Potential', $
                  ; 'vFieldnam',                     'v: More information', $
                   'dyFieldnam',                    'dy: Error Upper', $
                   'dvFieldnam',                    'dv: Error Lower', $
                   'flagFieldnam',                  'flag: Quality of Potential (see also Flag_info/Flag_source)', $
                   'derivn',                        ' NA', $    ;####
                   'sig_digits',                    '2 sig digits', $ ;#####
                   'SI_conversion',                 'Convert to SI units [V=V]', $  ;####
                   'MONOTON',                     dlimit_merge.MONOTON, $
                   'SCALEMIN',                    min(data_l2_y), $
                   'SCALEMAX',                    max(data_l2_y), $        ;..end of required for cdf production.
                   't_epoch'         ,            dlimit_merge.t_epoch, $
                   'Time_start'      ,            dlimit_merge.Time_start, $
                   'Time_end'        ,            dlimit_merge.Time_end, $
                   'Time_field'      ,            dlimit_merge.Time_field, $
                   'SPICE_kernel_version',        dlimit_merge.SPICE_kernel_version, $
                   'SPICE_kernel_flag',           dlimit_merge.SPICE_kernel_flag, $ 
                   'Flag_info'       ,            dlimit_merge.flag_info, $   ;<----- fix
                   'Flag_source'     ,            dlimit_merge.flag_source, $  ;<----- fix                    
                   'L0_datafile'     ,            dlimit_merge.L0_datafile, $ 
                   'cal_vers'        ,            dlimit_merge.cal_vers+ ' # ' + vers_prd,$     
                   'cal_y_const1'    ,            dlimit_merge.cal_y_const1, $
                   'cal_y_const2'    ,            'Merge level:' +strcompress(1,/remove_all)   ,$
                   'cal_datafile'    ,            'NA', $
                   'cal_source'      ,             dlimit_merge.cal_source, $     
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[V]') ;, $                   
                   ;'cal_v_const1'    ,            'NA', $
                   ;'cal_v_const2'    ,            'NA' , $
                   ;'zsubtitle'       ,            'NA') 
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
                  'char_size' ,                  limit.char_size   ,$    
                  'xtitle' ,                     limit.xtitle    ,$   
                  'ytitle' ,                     'SC pot'    ,$   
                  'yrange' ,                     [-20,20]        ,$ ; [min(data_l2_y),max(data_l2_y)]        ,$   
                  'ystyle'  ,                    1        ,$ 
                  'noerrorbars',                 1)
                  ;'ylog'   ,                     1              ,$ 
                  ;'ztitle' ,                     'Power' ,$   
                  ;'zrange' ,                     [1e-2,1e6],$
                  ;'zlog'  ,                      1  ,$
                  ;'spec'  ,                      1  )
                 ; 'labels' ,        limit.labels,$   ; not used for this product
                 ; 'colors' ,        limit.colors,$   ; not used for this product 
                 ; 'labflag' ,       limit.labflag)   ; not used for this product                    
                ;---------------------------------------------
                store_data,'mvn_lpw_mrg_sc_pot_'+ext,data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                ;---------------------------------------------    


               options,'mvn_lpw_mrg_sc_pot_'+ext,psym=1


;---------------------------------------------------------------------------------------------------
;                              end tplot production
;---------------------------------------------------------------------------------------------------
ENDIF ELSE print,' There was no Tplot variable from mvn_lpw_prd_lp_n_t '
      
ENDIF ELSE print, "#### WARNING #### No act or pas data present; mvn_lpw_prd_w_spec.pro skipped..."  

end
;*******************************************************************

