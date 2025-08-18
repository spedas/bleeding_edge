
;+
;PROCEDURE:   mvn_lpw_prd_euv
;
;Routine that takes EUV data and combines it with sc-attitude and produce one tplot variable for L2-production.
;Much of the calibration to get the data product into research quality product is made in this routine  
;The error information and flag information is taking also into consideration information from other sources such as spacecraft atitude.
;   The tplot variables mvn_lpw_euv must be loaded into tplot memory before running this routine. 
;   There are additional variables that need to be loaded
;   Presently this routine do not go an grab them if they are missing.
;
;INPUTS:         
; - None directly required by user. 
;   
;KEYWORDS:
; - make_cdf                                ;make one L2-cdf for the NASA DPS archive
;    dir_cdf                                ;choose where the cdf will be produced
; 
;EXAMPLE:
; mvn_lpw_prd_euv
;
;
;CREATED BY:   Laila Andersson  11-01-13
;FILE:         mvn_lpw_prd_euv.pro
;VERSION:      1.0
;LAST MODIFICATION: 
;
;-

pro mvn_lpw_prd_euv,dir_cdf=dir_cdf,make_cdf=make_cdf


  if keyword_set(dir_cdf) then dir_cdf=dir_cdf else dir_cdf=''

;---------------------------------------------------------------------------------------------------
;    Check which variables exists for this routine
;    for the moment all variables has to be loaded in all ready, this routine do not call on any other routines 
;---------------------------------------------------------------------------------------------------
t_routine = systime(1)

;Check tplot variables exist before calling them:
names = tnames(s)                               ;names is an array containing all tplot variable names currently in IDL memory.

missing_variable=' The following variables are missing: '

IF total(strmatch(names, 'mvn_lpw_euv')) EQ 1 THEN $ 
     get_data, 'mvn_lpw_euv', data=data1,limit=limit1,dlimit=dlimit1 ELSE missing_variable=[missing_variable,'mvn_lpw_euv was not found']

IF total(strmatch(names, 'mvn_lpw_euv_temp_C')) EQ 1 THEN $                            ;<---------- do not yet know the name, this rutine needs the SC to solar-angle information
     get_data, 'mvn_lpw_euv_temp_C', data=data_temp ELSE missing_variable=[missing_variable,'mvn_euv_temp was not found']

IF total(strmatch(names, 'mvn_sc_atitude')) EQ 1 THEN $                            ;<---------- do not yet know the name, this rutine needs the SC to solar-angle information
     get_data, 'mvn_sc_atitude', data=data_sc_att ELSE missing_variable=[missing_variable,'mvn_sc_atitude was not found']


IF n_elements(missing_variable) GT 1 then print,'mvn_lpw_prd_euv: ##### WARNING ###### ',missing_variable


;Check data is present in either the euv tplot variables
;Use IDLs size routine to determine if the data is a structure or not.
     type_1 = size(data1, /type) 
     type_sc_att = size(data_sc_att, /type)

IF (type_1 NE 8) then begin
     print,'mvn_lpw_prd_euv: There was no data found '
     return                                             ;<----------- does this work?????
ENDIF  
 

;NOTE: we need to check that the data comes from the same day......
; could it be done something like
; ...we might only check that the day is the same on all three files.......

      ;This currently crashes if s/c attitude isn't found: 
      ;   IF ((type_1 EQ 8) or (type_2 EQ 8)) and (type_sc_att EQ 8) then begin
      ;    IF min(data1.x) GT max(data_sc_att.x) OR min(data_sc_att.x) GT max(data1.x) THEN $
      ;     print,'mvn_lpw_prd_euv:### WARNING #### The SC attitude file are from another time period '
      ;     return                                             ;<----------- does this work?????
      ;      
      ;   ENDIF
 
;---------------------------------------------------------------------------------------------------
;       Variables found and read into memory
;---------------------------------------------------------------------------------------------------
 

;---------------------------------------------------------------------------------------------------
;                  Merge the dlimit and limit information for tplot production
;---------------------------------------------------------------------------------------------------
 
 ;limit=limit1               ; completely rewritten for this product, see below
 dlimit=dlimit1
 
 ; What final productas are saved in the tplot/CDF variable/file    <---- Frank what do we need?
 ll_labels=['Irr_a','Irr_b','Irr_c','Irr_d','temp_euv','D_a','D_b','D_c','D_d','M_a','M_b','M_c','M_c']  ; should we have something else???
 ll_colors=[      6,      2,      4,      5,         3,    1,    1,    1,    1,    1,    1,    1,    1]
 
 
;---------------------------------------------------------------------------------------------------
;                              dlimit and limit created
;---------------------------------------------------------------------------------------------------




;---------------------------------------------------------------------------------------------------
;                             Creating the data_l2 product:  
;                             Merge the data 
;                             Modify the error information with respect of atitude and other things
;                             Create a quality flag
;---------------------------------------------------------------------------------------------------
 
 ;produce the data arrays to put the information into
          
          nn1 = n_elements(data1.x)                                        ;number of elements            
          data_l2_x   =data1.x                          
          data_l2_y   =fltarr(nn1,n_elements(ll_labels))
          data_l2_dy  =fltarr(nn1,n_elements(ll_labels) )                                
          data_l2_flag=fltarr(nn1)                          ;this flag is created here and provide information of our confedence level of the value       

;  ################ to be written ######################## this is where total irradiance calibration is made 
; Frank and Phil needt to provide the input here!!!!
     
     ;file_name=dlimit.calib_file_euv  ;should contain the asciifile to read  ;### this currently crashes, commented out so CF can check CDF production
;  ################

;---------------------------------------------------------------------------------------------------
;                                end of creating the data_l2 product  
;---------------------------------------------------------------------------------------------------




;---------------------------------------------------------------------------------------------------
;                            Create the L2 tplot variables
;---------------------------------------------------------------------------------------------------
;------------------ Variables created not stored in CDF files -------------------    
    
; ##3    make one tplot variable with only the first four informations in it seperatealy ll_labels=['Irr_a','Irr_b','Irr_c','Irr_d']                           
 
;------------------ Variables created not stored in CDF files -------------------     
;------------------All information based on the SIS document-------------------         
                        
                ;-------------------- tplot variable 'mvn_lpw_euv_L2' ------------------- 
                ;--------------------- SIS name: LPW.calibrated.euv -------------------  
                ;-------------------  There will be 1 CDF file per day --------------------   
                data_l2 =  create_struct(         $      ; Which are used should follow the SIS-EUV document for this variable !! Look at: Table : Contents for LPW.calibrated.euv calibrated data file.         
                                         'x',    data_l2_x,  $     ; double 1-D arr
                                         'y',    data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   data_l2_dy,  $    ; same size as y
                                         ;'v',    data_l2_v,  $     ; same size as y
                                         ;'dv',   data_l2_dv,  $    ;same size as y
                                         'flag', data_l2_flag)     ;1-D 
                ;-------------------------------------------
                dlimit_l2=create_struct(   $             ; Which are used should follow the SIS-EUV document for this variable !! Look at: Table : Contents for LPW.calibrated.euv calibrated data file.   
                  'Product_name',                  'MAVEN LPW EUV Calibrated level '+ext, $
                  'Project',                       dlimit.Project, $
                  'Source_name',                   dlimit.Source_name, $     ;Required for cdf production...
                  'Discipline',                    dlimit.Discipline, $
                  'Instrument_type',               dlimit.Instrument_type, $
                  'Data_type',                     'CAL>calibrated',  $
                  'Data_version',                  dlimit.Data_version, $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                  'Descriptor',                    dlimit.Descriptor, $
                  'PI_name',                       dlimit.PI_name, $
                  'PI_affiliation',                dlimit.PI_affiliation, $
                  'TEXT',                          dlimit.TEXT, $
                  'Mission_group',                 dlimit.Mission_group, $
                  'Generated_by',                  dlimit.Generated_by,  $
                  'Generation_date',               dlimit.Generation_date+' # '+t_routine, $   ;Gives the date and time the data is derived and the CDF file was created - can be multiple times ponts
                  'Rules_of_use',                  dlimit.Rules_of_use, $
                  'Acknowledgement',               dlimit.Acknowledgement,   $
                  'Title',                         'MAVEN LPW EUV L2', $   ;####            ;As this is L0b, we need all info here, as there's no prd file for this
                  'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                  'y_catdesc',                     'EUV', $    ;### ARE UNITS CORRECT? v/m?
                  ;'v_catdesc',                     'test dlimit file, v', $    ;###
                  'dy_catdesc',                    'Error on the data.', $     ;###
                  ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                  'flag_catdesc',                  'test dlimit file, flag.', $   ; ###
                  'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                  'y_Var_notes',                   'EUV notes', $
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
                  'MONOTON',                     dlimit.MONOTON, $
                  'SCALEMIN',                    min(data_l2.y), $
                  'SCALEMAX',                    max(data_l2.y), $
                  't_epoch',                     dlimit.t_epoch, $   ; The spacecraft clock zero time represent that is used when converting the time in the packet headers to physical time
                  'Time_start',                  dlimit.time_start, $         ;  [time_sc(0)-t_epoch,          time_sc(0)] , $
                  'Time_end',                    dlimit.time_end,   $         ;  [time_sc(nn_pktnum-1)-t_epoch,time_sc(nn_pktnum-1)], $
                  'Time_field',                  dlimit.time_field, $         ;  ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00'], $
                  'SPICE_kernel_version',        dlimit.SPICE_kernel_version, $
                  'SPICE_kernel_flag',           dlimit.SPICE_kernel_flag, $
                  'L0_datafile',                 dlimit.L0_datafile , $  ; Gives the name of the L0 file used, if multiple variable use, this can be multiple names of the same or different files 
                  'cal_vers',                    dlimit.cal_vers+' # ', $;+pkt_ver ,$  ; Gives the calibration file version
                  'cal_y_const1' ,               'NA', $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  'cal_y_const2',                'NA', $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                  'cal_datafile',                'NA', $  ; If one or more calibration files has been used the file names is located here (file names of the calibration files included dates and version number of when the are created)
                  'cal_source',                  'Information from PKT: EUV-raw', $  ; Information of what has been considered in the data production (sc attitude, other instruments etc)   
                  'flag_info',                   'NA', $   ; Normally flag represent ‘confidence level’ if not stated differently. 0 no confidence at all. Can be used for aperture open/close etc.  
                  'flag_source',                 'NA', $   ; Information of what is considered when the flag is created (such as sc-atitude)
                  'xsubtitle',                   '[sec]', $  ;units
                  'ysubtitle',                   '[Raw Packet Information]')  ;units
                ;  'cal_v_const1',                'NA', $
                ;  'cal_v_const2',                'NA', $
                ;  'zsubtitle',                   'NA')                  
                  
                  
                 
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS-EUV document for this variable !! Look at: Table : Contents for LPW.calibrated.euv calibrated data file.   
                  'char_size' ,     1.2 ,$    
                  'xtitle' ,        'Time' ,$   
                  'ytitle' ,        'Different quantities, see labels' ,$   
                 ; 'yrange' ,        limit.yrange ,$   
                 ; 'ystyle'  ,       limit.ystyle ,$  
                 ; 'ylog'   ,        limit.ylog, $
                 ; 'ztitle' ,        limit.ztitle ,$   
                 ; 'zrange' ,        limit.zrange) ;,$
                 ; 'zlog'  ,         limit.zlog, $
                 ; 'spec'  ,         limit.spec, $    ;spectra = 1.
                  'labels' ,        ll_labels,$   ; not used for this product
                  'colors' ,        ll_colors,$   ; not used for this product 
                  'labflag' ,       1)   ; not used for this product                            
                ;---------------------------------------------
                store_data,'mvn_lpw_euv_l2',data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                ;---------------------------------------------    



;---------------------------------------------------------------------------------------------------
;                              end tplot production
;---------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------
;                              In case key-word CDF
;---------------------------------------------------------------------------------------------------

If (keyword_set(make_cdf)) Then $
             mvn_lpw_cdf_write, varlist='mvn_lpw_euv_l2', dir=dir_cdf

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------




end
;*******************************************************************

