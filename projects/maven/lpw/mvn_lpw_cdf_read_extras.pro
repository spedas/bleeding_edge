;+
;Routine to decompress the miscellaneous data produced from the LPW CDF file mvn_lpw_lp_n_t_L2.
;
;Currently, this will produce separate tplot variables for:
;
;S/C potential
;Electron density
;Electron temperature.
;
;INPUTS:
;Tplot variable stored in tplot memory: mvn_lpw_lp_n_t_L2
;
;OUTPUTS:
;New tplot variables:
;mvn_lpw_lp_Ne_L2: electron density (/cc)
;mvn_lpw_lp_Te_L2: electron temperature (K)
;mvn_lpw_lp_Usc_L2: spacecraft potential (V)
;
;
;MODIFICATIONS:
;Created: 2015-04-14: CMF.
;2016-12-20: CMF: bring in data.info information from data structure.
;
;NOTES: as of last edit, must check input tplot variable has dl.xFieldnam present. Check final outputs - check default value is NaN.
;
;-
;

pro mvn_lpw_cdf_read_extras

;Check which variables are in tplot memory:
tplotnames = tnames()

if total(strmatch(tplotnames, 'mvn_lpw_lp_n_t_l2')) eq 1. then begin
    get_data, 'mvn_lpw_lp_n_t_l2', data=dd1, dlimit=dl, limit=ll   ;get data
    
    ;dd1 is [*,10]. First 3 columns are Ne, Te, Usc. This is hard coded in this code.
    ;The flag information will be applied to all three of the above
    
    time = dd1.x   ;grab data and upper / lower limits
    flag = dd1.flag
    if tag_exist(dd1, 'info') then info = dd1.info else info = fltarr(n_elements(dd1.x))  ;as people want to combine many days, need an array so that combining doesn't crash if some dates have this and some don't
    Nelectron   = dd1.y[*,0]
    NelectronDY = dd1.dy[*,0]
    NelectronDV = dd1.dv[*,0]
    Telectron   = dd1.y[*,1]
    TelectronDY = dd1.dy[*,1]
    TelectronDV = dd1.dv[*,1]
    Usc         = dd1.y[*,2]
    UscDY       = dd1.dy[*,2]
    UscDV       = dd1.dv[*,2]
    
    tags = tag_names(dl)
    if total(strmatch(tags, 'xFieldname', /fold_case) eq 1) then cdf1 = 1. else cdf1 = 0.  ;catch typo in version1 cdf file dlimit fields. If cdf1 eq 1 then found this typo.
    if cdf1 eq 1. then xfieldnameVAR = dl.xFieldname else xfieldnameVAR = dl.xFieldnam
    
    
    ;Produce tplot variables:
    
    ;===
    ;Ne:
    ;===
    data_l2 =  create_struct(  $             
      'x',    time,  $     ; double 1-D arr
      'y',    Nelectron,  $     ; most of the time float and 1-D or 2-D
      'dy',   NelectronDY,  $    ; same size as y
      'dv',   NelectronDV, $
      'flag', flag       ,  $     ;1-D
      'info', info  )
      
    ;-------------------------------------------
    dlimit_l2=create_struct(   $
      'Product_name',                  'MAVEN LPW electron density Calibrated level L2', $
      'Project',                       dl.Project, $
      'Source_name',                   dl.Source_name, $     ;Required for cdf production...
      'Discipline',                    dl.Discipline, $
      'Instrument_type',               dl.Instrument_type, $
      'Data_type',                     'CAL>calibrated',  $
      'Data_version',                  dl.Data_version, $  ;Keep this text string, need to add v## when we make the CDF file (done later)
      'Descriptor',                    dl.Descriptor, $
      'PI_name',                       dl.PI_name, $
      'PI_affiliation',                dl.PI_affiliation, $
      'TEXT',                          dl.TEXT, $
      'Mission_group',                 dl.Mission_group, $
      'Generated_by',                  dl.Generated_by,  $
      'Generation_date',               dl.Generation_date , $   ;Gives the date and time the data is derived and the CDF file was created - can be multiple times ponts
      'Rules_of_use',                  dl.Rules_of_use, $
      'Acknowledgement',               dl.Acknowledgement,   $
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'Electron density, per cc.', $    ;### ARE UNITS CORRECT? v/m?
      'v_catdesc',                     dl.v_catdesc, $    ;###
      'dy_catdesc',                    dl.dy_catdesc, $     ;###
      'dv_catdesc',                    dl.dv_catdesc, $   ;###
      'flag_catdesc',                  dl.flag_catdesc, $   ; ###
      'x_Var_notes',                   dl.x_Var_notes, $
      'y_Var_notes',                   dl.y_Var_notes, $
      'v_Var_notes',                   dl.v_Var_notes, $
      'dy_Var_notes',                  dl.dy_Var_notes, $
      'dv_Var_notes',                  dl.dv_Var_notes, $
      'flag_Var_notes',                dl.Flag_Var_notes, $
      'xFieldnam',                     xFieldnameVAR, $      ;###
      'yFieldnam',                     'Electron density derived from I-V fit', $
      'vFieldnam',                     dl.vFieldnam, $
      'dyFieldnam',                    dl.dyFieldnam, $
      'dvFieldnam',                    dl.dvFieldnam, $
      'flagFieldnam',                  dl.flagFieldnam, $
      'derivn',                        'NA', $    ;####
      'sig_digits',                    dl.sig_digits, $ ;#####
      'SI_conversion',                 dl.SI_conversion, $  ;####
      'MONOTON',                     dl.MONOTON, $
      'SCALEMIN',                    min(Nelectron, /nan), $
      'SCALEMAX',                    max(Nelectron, /nan), $        ;..end of required for cdf production.
      't_epoch'         ,            dl.t_epoch, $
      'Time_start'      ,            dl.Time_start, $
      'Time_end'        ,            dl.Time_end, $
      'Time_field'      ,            dl.Time_field, $
      'SPICE_kernel_version',        dl.SPICE_kernel_version, $
      'SPICE_kernel_flag',           dl.SPICE_kernel_flag, $
      'Flag_info'       ,            dl.flag_info, $
      'Flag_source'     ,            dl.flag_source, $
      'L0_datafile'     ,            dl.L0_datafile, $
      'cal_vers'        ,            dl.cal_vers ,$
      'cal_y_const1'    ,            dl.cal_y_const1, $
      'cal_y_const2'    ,            dl.cal_y_const2   ,$
      'cal_datafile'    ,            dl.cal_datafile, $
      'cal_source'      ,            dl.cal_source, $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[/cc]', $
      'cal_v_const1'    ,            dl.cal_v_const1, $
      'cal_v_const2'    ,            dl.cal_v_const2, $
      'zsubtitle'       ,            dl.zsubtitle)
    ;-------------------------------------------
    limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
      'char_size' ,                  ll.char_size   ,$
      'xtitle' ,                     ll.xtitle    ,$
      'ytitle' ,                     'Density [cm^-3]'    ,$
      'yrange' ,                     [min(Nelectron,/nan),max(Nelectron,/nan)]        ,$
      'noerrorbars',                  1, $
      'labels' ,                      '' ,$
      'colors' ,                      7 ,$  ;black
      'labflag' ,                     1)
    ;---------------------------------------------
    store_data,'mvn_lpw_lp_ne_l2',data=data_l2,limit=limit_l2,dlimit=dlimit_l2
    ;---------------------------------------------


    ;===
    ;Te:
    ;===
    data_l2 =  create_struct(  $
      'x',    time,  $     ; double 1-D arr
      'y',    Telectron,  $     ; most of the time float and 1-D or 2-D
      'dy',   TelectronDY,  $    ; same size as y
      'dv',   TelectronDV,  $
      'flag', flag    , $    ;1-D
      'info', info  )
    ;-------------------------------------------
    dlimit_l2=create_struct(   $
      'Product_name',                  'MAVEN LPW electron temperature Calibrated level L2', $
      'Project',                       dl.Project, $
      'Source_name',                   dl.Source_name, $     ;Required for cdf production...
      'Discipline',                    dl.Discipline, $
      'Instrument_type',               dl.Instrument_type, $
      'Data_type',                     'CAL>calibrated',  $
      'Data_version',                  dl.Data_version, $  ;Keep this text string, need to add v## when we make the CDF file (done later)
      'Descriptor',                    dl.Descriptor, $
      'PI_name',                       dl.PI_name, $
      'PI_affiliation',                dl.PI_affiliation, $
      'TEXT',                          dl.TEXT, $
      'Mission_group',                 dl.Mission_group, $
      'Generated_by',                  dl.Generated_by,  $
      'Generation_date',               dl.Generation_date, $   ;Gives the date and time the data is derived and the CDF file was created - can be multiple times ponts
      'Rules_of_use',                  dl.Rules_of_use, $
      'Acknowledgement',               dl.Acknowledgement,   $
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'Electron temperature, in Kelvin.', $    ;### ARE UNITS CORRECT? v/m?
      'v_catdesc',                     dl.v_catdesc, $    ;###
      'dy_catdesc',                    dl.dy_catdesc, $     ;###
      'dv_catdesc',                    dl.dv_catdesc, $   ;###
      'flag_catdesc',                  dl.flag_catdesc, $   ; ###
      'x_Var_notes',                   dl.x_Var_notes, $
      'y_Var_notes',                   dl.y_Var_notes, $
      'v_Var_notes',                   dl.v_Var_notes, $
      'dy_Var_notes',                  dl.dy_Var_notes, $
      'dv_Var_notes',                  dl.dv_Var_notes, $
      'flag_Var_notes',                dl.Flag_Var_notes, $
      'xFieldnam',                     xFieldnameVAR, $      ;###
      'yFieldnam',                     'Electron temperature derived from I-V fit', $
      'vFieldnam',                     dl.vFieldnam, $
      'dyFieldnam',                    dl.dyFieldnam, $
      'dvFieldnam',                    dl.dvFieldnam, $
      'flagFieldnam',                  dl.flagFieldnam, $
      'derivn',                        'NA', $    ;####
      'sig_digits',                    dl.sig_digits, $ ;#####
      'SI_conversion',                 dl.SI_conversion, $  ;####
      'MONOTON',                     dl.MONOTON, $
      'SCALEMIN',                    min(Telectron, /nan), $
      'SCALEMAX',                    max(Telectron, /nan), $        ;..end of required for cdf production.
      't_epoch'         ,            dl.t_epoch, $
      'Time_start'      ,            dl.Time_start, $
      'Time_end'        ,            dl.Time_end, $
      'Time_field'      ,            dl.Time_field, $
      'SPICE_kernel_version',        dl.SPICE_kernel_version, $
      'SPICE_kernel_flag',           dl.SPICE_kernel_flag, $
      'Flag_info'       ,            dl.flag_info, $
      'Flag_source'     ,            dl.flag_source, $
      'L0_datafile'     ,            dl.L0_datafile, $
      'cal_vers'        ,            dl.cal_vers ,$
      'cal_y_const1'    ,            dl.cal_y_const1, $
      'cal_y_const2'    ,            dl.cal_y_const2   ,$
      'cal_datafile'    ,            dl.cal_datafile, $
      'cal_source'      ,            dl.cal_source, $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[K]', $
      'cal_v_const1'    ,            dl.cal_v_const1, $
      'cal_v_const2'    ,            dl.cal_v_const2, $
      'zsubtitle'       ,            dl.zsubtitle)
    ;-------------------------------------------
    limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
      'char_size' ,                  ll.char_size   ,$
      'xtitle' ,                     ll.xtitle    ,$
      'ytitle' ,                     'Temperature [K]'    ,$
      'yrange' ,                     [min(Telectron,/nan),max(Telectron,/nan)]        ,$
      'noerrorbars',                  1, $
      'labels' ,                      '' ,$
      'colors' ,                      7 ,$  ;black
      'labflag' ,                     1)
    ;---------------------------------------------
    store_data,'mvn_lpw_lp_te_l2',data=data_l2,limit=limit_l2,dlimit=dlimit_l2
    ;---------------------------------------------


    ;====
    ;Usc:
    ;====
    data_l2 =  create_struct(  $
      'x',    time,  $     ; double 1-D arr
      'y',    Usc,  $     ; most of the time float and 1-D or 2-D
      'dy',   UscDY,  $    ; same size as y
      'dv',   UscDV,  $
      'flag', flag    , $       ;1-D
      'info', info)
    ;-------------------------------------------
    dlimit_l2=create_struct(   $
      'Product_name',                  'MAVEN LPW Spacecraft potential Calibrated level L2', $
      'Project',                       dl.Project, $
      'Source_name',                   dl.Source_name, $     ;Required for cdf production...
      'Discipline',                    dl.Discipline, $
      'Instrument_type',               dl.Instrument_type, $
      'Data_type',                     'CAL>calibrated',  $
      'Data_version',                  dl.Data_version, $  ;Keep this text string, need to add v## when we make the CDF file (done later)
      'Descriptor',                    dl.Descriptor, $
      'PI_name',                       dl.PI_name, $
      'PI_affiliation',                dl.PI_affiliation, $
      'TEXT',                          dl.TEXT, $
      'Mission_group',                 dl.Mission_group, $
      'Generated_by',                  dl.Generated_by,  $
      'Generation_date',               dl.Generation_date, $   ;Gives the date and time the data is derived and the CDF file was created - can be multiple times ponts
      'Rules_of_use',                  dl.Rules_of_use, $
      'Acknowledgement',               dl.Acknowledgement,   $
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'Spacecraft potential, in volts', $    ;### ARE UNITS CORRECT? v/m?
      'v_catdesc',                     dl.v_catdesc, $    ;###
      'dy_catdesc',                    dl.dy_catdesc, $     ;###
      'dv_catdesc',                    dl.dv_catdesc, $   ;###
      'flag_catdesc',                  dl.flag_catdesc, $   ; ###
      'x_Var_notes',                   dl.x_Var_notes, $
      'y_Var_notes',                   dl.y_Var_notes, $
      'v_Var_notes',                   dl.v_Var_notes, $
      'dy_Var_notes',                  dl.dy_Var_notes, $
      'dv_Var_notes',                  dl.dv_Var_notes, $
      'flag_Var_notes',                dl.Flag_Var_notes, $
      'xFieldnam',                     xFieldnameVAR, $      ;###
      'yFieldnam',                     'Spacecraft potential derived from I-V fit', $
      'vFieldnam',                     dl.vFieldnam, $
      'dyFieldnam',                    dl.dyFieldnam, $
      'dvFieldnam',                    dl.dvFieldnam, $
      'flagFieldnam',                  dl.flagFieldnam, $
      'derivn',                        'NA', $    ;####
      'sig_digits',                    dl.sig_digits, $ ;#####
      'SI_conversion',                 dl.SI_conversion, $  ;####
      'MONOTON',                     dl.MONOTON, $
      'SCALEMIN',                    min(Usc, /nan), $
      'SCALEMAX',                    max(Usc, /nan), $        ;..end of required for cdf production.
      't_epoch'         ,            dl.t_epoch, $
      'Time_start'      ,            dl.Time_start, $
      'Time_end'        ,            dl.Time_end, $
      'Time_field'      ,            dl.Time_field, $
      'SPICE_kernel_version',        dl.SPICE_kernel_version, $
      'SPICE_kernel_flag',           dl.SPICE_kernel_flag, $
      'Flag_info'       ,            dl.flag_info, $
      'Flag_source'     ,            dl.flag_source, $
      'L0_datafile'     ,            dl.L0_datafile, $
      'cal_vers'        ,            dl.cal_vers ,$
      'cal_y_const1'    ,            dl.cal_y_const1, $
      'cal_y_const2'    ,            dl.cal_y_const2   ,$
      'cal_datafile'    ,            dl.cal_datafile, $
      'cal_source'      ,            dl.cal_source, $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[V]', $
      'cal_v_const1'    ,            dl.cal_v_const1, $
      'cal_v_const2'    ,            dl.cal_v_const2, $
      'zsubtitle'       ,            dl.zsubtitle)
    ;-------------------------------------------
    limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
      'char_size' ,                  ll.char_size   ,$
      'xtitle' ,                     ll.xtitle    ,$
      'ytitle' ,                     'Spacecraft potential [V]'    ,$
      'yrange' ,                     [min(Usc,/nan),max(Usc,/nan)]        ,$
      'noerrorbars',                  1, $
      'labels' ,                      '' ,$
      'colors' ,                      7 ,$  ;black
      'labflag' ,                     1)
    ;---------------------------------------------
    store_data,'mvn_lpw_lp_vsc_l2',data=data_l2,limit=limit_l2,dlimit=dlimit_l2
    ;---------------------------------------------

    
    ;============
    ;Plot limits:
    ;============
    options, 'mvn_lpw_lp_ne_l2', ylog=1
    ylim, 'mvn_lpw_lp_ne_l2', 10., 1.e12
    options, 'mvn_lpw_lp_ne_l2', psym=1
    
    options, 'mvn_lpw_lp_te_l2', ylog=1
    ylim, 'mvn_lpw_lp_te_l2', 10., 1.E4
    options, 'mvn_lpw_lp_te_l2', psym=1
    
    ylim, 'mvn_lpw_lp_vsc_l2', -15, 5.
    options, 'mvn_lpw_lp_vsc_l2', psym=1
    
  
endif

end




