 ;+
;PROCEDURE:   mvn_lpw_prd_lp_n_t
;
; Routine takes IV-cureves from both booms and combines them into one tplot variable for 
; L2-production.
; The default swp1 and swp2 are from different subcycles.
; The sweep length can vary but the number of points in the sweep is fixed
; There will be error both in the current and the sweep potential
; The error information and flag information is taking also into consideration information from 
; other sources such as spacecraft atitude.
;
;INPUTS:
;   date_in:  Chose the date number in format of YYYYMMDD (long). 
;   ext:     'l1a' 'l1b' or 'l2'  what level of quality to produce.
;            'l2' is full information to be archived
;
;KEYWORDS:
;   make_cdf   : set this keyword to create the cdf file of the product.
;   dir_cdf    : give cdf save directry with this keyward. Default is making cdf directory at the 
;                current directory ('./cdf/') otherwise.
;   lpw_cal_dir: give lpw calibration file save directory. Otherwise, default directory is
;                                   getenv('MVN_LOCAL_DATA_DIR')/data/sci/lpw/fitpar/year/month/
;   fit_type   : To run only one type of fitting process. Default is 'all'. otherwose, 'mm'or'ree'
;   
;EXAMPLE:
; mvn_lpw_prd_lp_n_t,'l1a'
;
;CREATED BY:   Laila Andersson  11-04-13
;FILE:         mvn_lpw_prd_lp_n_t.pro
;VERSION:      3.0
;LAST MODIFICATION:
; 2014-05-22   L. Andersson   sigificant update and working
; 2014-09-01   M. Morooka     add l0 analysis
; 2014-09-29   M. Morooka     minor change for text saving directory
; 2014-10-20   M. Morooka     update test automatic analysis version for l1a
; 2014-11-13   M. Morooka     update automatic analysis version for l1a.
; 2014-11-17   M. Morooka     Outer region fitting fixed to two components. (SW2)
;                             Impliment to create calibration text file.
; 2014-11-24   M. Morooka     Change givenU definition for ionosphere.
; 2014-12-19   M. Morooka     Add two electron component fitting to the dense plasma resion.
; 2015-01-11   M. Morooka     Adopt to the Chris's l0 data struct
; 2015-03-23   M. Morooka     Add clean result.
;-

;------- this_version_mvn_lpw_prd_lp_n_t ------------------
function this_version_mvn_lpw_prd_lp_n_t
  ver = 3.0
  prd_ver= 'version mvn_lpw_prd_lp_n_t: ' + string(ver,format='(F4.1)')
  return, prd_ver
end
;-------------------- this_version_mvn_lpw_prd_lp_n_t -----

;------- mvn_lpw_prd_lp_n_t_cal_version ------------------
function mvn_lpw_prd_lp_n_t_cal_version, cal_ver
  prd_ver= 'cal_version mvn_lpw_prd_lp_n_t: ' + string(cal_ver,format='(I02)')
  return, prd_ver  
end
;-------------------- mvn_lpw_prd_lp_n_t_cal_version -----

;------- check_tplot_var ----------------------------------
function check_tplot_var, prd, ground=ground

  if keyword_set(ground) eq 0 then ground = 0 ; This set to one for the first encounter test
  
  names = tnames(s)  ;names are arrays containing all tplot variable names currently in IDL memory.
  variables = REPLICATE({name:'',ex:0}, 8)
  variables[0].name = 'mvn_lpw_swp1_I1'
  variables[1].name = 'mvn_lpw_swp2_I2'
  variables[2].name = 'mvn_lpw_swp1_I1_pot'
  variables[3].name = 'mvn_lpw_swp2_I2_pot'
  variables[4].name = 'mvn_lpw_anc_mvn_pos_mso'
  variables[5].name = 'mvn_lpw_anc_mvn_att_mso'
  variables[6].name = 'mvn_lpw_anc_mvn_vel_mso'  
  variables[7].name = 'mvn_lpw_atr_mode' & ancmode = 7
  
  print, 'Check tplot variables:'
  for ii=0,n_elements(variables)-1 do begin
    IF total(strmatch(names, variables(ii).name)) EQ 1 THEN begin
      print, '   '+variables[ii].name+' ..... found.'
      variables(ii).ex = 1
    ENDIF else begin
      print, '   '+variables[ii].name+' ..... NOT exists.'
    Endelse
  endfor
  print, '------------------------------'
  
  ;----- _act_mode must be loaded ---------------------------------------------
  if not ground then begin
    if variables[ancmode].ex eq 0 then begin
      print, variables[ancmode].name+' must be loaded.'
      return, 0
    endif    
  endif
  ;----- if _swp1_I1 exist swp1_I1_pot must also exist ------------------------
  if (variables[0].ex + variables[2].ex) eq 1 then begin
    print, 'Both'+variables[0].name + variables[2].name+' must be loaded.'
    variables[0].ex = 0 & variables[2].ex = 0
  endif
  ;----- if _swp1_I2 exist swp1_I2_pot must also exist ------------------------
  if (variables[1].ex + variables[3].ex) eq 1 then begin
    print, 'Both'+variables[1].name + variables[3].name+' must be loaded.'
    variables[1].ex = 0 & variables[3].ex = 0
  endif
  ;----- if all _swp1_I1,_swp2_I2,_swp1_I1_pot,_swp2_I2_pot not exist no further procedure --------
  if (variables[0].ex + variables[1].ex + variables[2].ex + variables[3].ex) eq 0 then return, 0
  
  ;==============================================================================
  ; FOR THIS PART MUST BE ADDED
  ; ASK CHRIS ABOUT mvn_lpw_anc_eng
  ;==============================================================================
  ;----- load anc data for swp1 -----------------------------------------------
  ; if variables[0].ex then begin
  ;   get_data,variables[0].name,data=data,limit=limit,dlimit=dlimit
  ;   mvn_lpw_anc_eng, data.x
  ; endif
  
  return, variables
  
end
; ----------------------------------- check_tplot_var -----

;------- define_cal_filename ------------------------------
function define_cal_filename, l0file_name, ext, lpw_cal_dir=lpw_cal_dir

  sl = path_sep()  ;/ for unix, \ for Windows
  ;lpw_cal_dir = getenv('MVN_LOCAL_DATA_DIR') + '/data/sci/lpw/fitpar/'
  if keyword_set(lpw_cal_dir) then lpw_cal_dir = lpw_cal_dir + sl+'data'+sl+'sci'+sl+'lpw'+sl+'fitpar'+sl $
  else                             lpw_cal_dir = getenv('ROOT_DATA_DIR') + sl+'data'+sl+'sci'+sl+'lpw'+sl+'fitpar'+sl  
    
  pos = strpos(l0file_name,'l0')
  yyyyymmdd = double(strmid(l0file_name,pos+3,8))
  yyyy = string(fix(yyyyymmdd/10000),format=('(I04)'))
  mm   = string(fix((yyyyymmdd mod 10000)/100),format=('(I02)'))
  dd   = string(fix(yyyyymmdd mod 100),format=('(I02)'))
  lpw_cal_dir = lpw_cal_dir+yyyy+sl+mm+sl
  if strcmp(ext,'l1a') and file_test(lpw_cal_dir,/directory) eq 0 then file_mkdir, lpw_cal_dir
  ;l0file_ext = strmid(l0file_name,pos+3,strlen(l0file_name)-4-pos-3)
  l0file_ext = strmid(l0file_name,pos+3,8)
  ;----- Changed style as: mvn_lpw_fitpar_yyyymmdd_ext 2014-11-13 M.Morooka -------------
  ;mvn_lp_cal_file_head = lpw_cal_dir+'mvn_lpw_fitpar_'+ext+'_'+l0file_ext+'_v'
  mvn_lp_cal_file_head = lpw_cal_dir+'mvn_lpw_fitpar_'+l0file_ext+'_'+ext

  return, mvn_lp_cal_file_head

end
;-------------------------------- define_cal_filename -----

; ------ mvn_lpw_prd_lp_get_sweep_block_add ---------------
function mvn_lpw_prd_lp_get_sweep_block_add, data
  time = data.x
  sts = [0, where(-ts_diff(time,1) gt 2.0)+1]
  ets = [where(-ts_diff(time,1) gt 2.0), n_elements(time)-1]
  pt = [[sts],[ets]]
  return, pt
end
; ---------------- mvn_lpw_prd_lp_get_sweep_block_add -----

;------- extract_block ------------------------------------
function mvn_lpw_prd_lp_extract_block, time_in_org, time

  time_in = time_double(time_in_org)
  if n_elements(time_in) eq 1 then begin
    int = where(time le time_in) & int = int(n_elements(int)-1)
    stp = int & etp = -1
  endif else begin
    int = where(time ge time_in(0) and time le time_in(1))
    stp = int(0) & etp = int(n_elements(int)-1)
  endelse
  return, [stp,etp]
  
end
;-------------------------------------- extract_block -----

; ------ mvn_lpw_prd_lp_retrive_initial_slope -------------
function mvn_lpw_prd_lp_retrive_initial_slope, voltage, current
  ; temporal procedure to ignore the negative LP characteristics
  
  U = voltage & I = current
  
  ; ----- Linear fittig calibration -----
  U_lim = [-30, -5]
  val = where(U ge U_lim(0) AND U le U_lim(1))
  UL = U(val) & IL = I(val)
  ; ----- Apply Linear fitting -----
  coeff = linfit(UL,IL,yfit=u2)
  m = coeff(0) & b = coeff(1)
  ;print, m,b
  
  ;I_slp = m + b * U
  I_slp = b * U
  I_cal = I - I_slp
  
  data = create_struct('U',U,'I',I,'I_slp',I_slp,'I_res',I_cal,'coeff',[m,b])
  
  return, data
end
; -------------- mvn_lpw_prd_lp_retrive_initial_slope -----

;------- make_dlimit --------------------------------------
function make_dlimit, dlimit_org, data, prd_ver, flag_info, flag_source,ext, cal_ver

  dlimit_new=create_struct(   $
    'Product_name',                  'MAVEN LPW density and temperature Calibrated level '+ext, $
    'Project',                       dlimit_org.Project, $
    'Source_name',                   dlimit_org.Source_name, $     ;Required for cdf production...
    'Discipline',                    dlimit_org.Discipline, $
    'Instrument_type',               dlimit_org.Instrument_type, $
    'Data_type',                     'CAL>calibrated',  $
    'Data_version',                  dlimit_org.Data_version, $  ;Keep this text string, need to add v## when we make the CDF file (done later)
    'Descriptor',                    dlimit_org.Descriptor, $
    'PI_name',                       dlimit_org.PI_name, $
    'PI_affiliation',                dlimit_org.PI_affiliation, $
    'TEXT',                          dlimit_org.TEXT, $
    'Mission_group',                 dlimit_org.Mission_group, $
    'Generated_by',                  dlimit_org.Generated_by,  $
    'Generation_date',               dlimit_org.Generation_date+' # '+SYSTIME(0), $   ;Gives the date and time the data is derived and the CDF file was created - can be multiple times ponts
    'Rules_of_use',                  dlimit_org.Rules_of_use, $
    'Acknowledgement',               dlimit_org.Acknowledgement,   $
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
    'MONOTON',                     dlimit_org.MONOTON, $
    'SCALEMIN',                    min(data,/na), $
    'SCALEMAX',                    max(data,/na), $        ;..end of required for cdf production.
   ;'generated_date'  ,            dlimit_org.GENERATION_DATE + ' # ' + SYSTIME(0) ,$
    't_epoch'         ,            dlimit_org.t_epoch, $
    'Time_start'      ,            dlimit_org.Time_start, $
    'Time_end'        ,            dlimit_org.Time_end, $
    'Time_field'      ,            dlimit_org.Time_field, $
    'SPICE_kernel_version',        dlimit_org.SPICE_kernel_version, $
    'SPICE_kernel_flag',           dlimit_org.SPICE_kernel_flag, $
    'Flag_info'       ,            flag_info, $
    'Flag_source'     ,            flag_source, $
    'L0_datafile'     ,            dlimit_org.L0_datafile, $
    'cal_vers'        ,            dlimit_org.cal_vers+ ' # ' + cal_ver,$
    'cal_y_const1'    ,            dlimit_org.cal_y_const1, $
    'cal_y_const2'    ,            'Merge level:' +strcompress(1,/remove_all)   ,$
    'cal_datafile'    ,            ' TBD ', $
    'cal_source'      ,            dlimit_org.cal_source, $
    'xsubtitle'       ,            '[sec]', $
    'ysubtitle'       ,            '[misc]', $
    'cal_v_const1'    ,            'NA', $
    'cal_v_const2'    ,            'NA', $
    'zsubtitle'       ,            'NA')
    
  return, dlimit_new
end
;---------------------------------------- make_dlimit -----

;------- make_limit ---------------------------------------
function make_limit,   limit_org, data, str_arr, str_col
  ; Which are used should follow the SIS document for this variable !!
  ; Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
  
  ; Which are used should follow the SIS document for this variable !! 
  ; Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas 
  ; calibrated data file.
  new_limit=create_struct(   $  
    'char_size' ,                  limit_org.char_size   ,$
    'xtitle' ,                     limit_org.xtitle    ,$
    'ytitle' ,                     'Misc'    ,$
    'yrange' ,                     [min(data,/na),max(data,/na)]        ,$
    'noerrorbars',                  1, $
    'labels' ,                      str_arr,$
    'colors' ,                      str_col,$
    'spec'   ,                    0,$
    'labflag' ,                     1)

  return, new_limit
end
;----------------------------------------- make_limit -----

;------- tplot_upload -------------------------------------
function tplot_upload, swp_pp,str_arr,str_tname,str_col,limit,dlimit,prd_ver,flg, ext, prd_cal_ver, $
                       Dstr_arr=Dstr_arr
                       
  data_y    = fltarr(n_elements(swp_pp),n_elements(str_arr))
  data_dy   = fltarr(n_elements(swp_pp),n_elements(str_arr))
  for ii=0,n_elements(str_arr)-1 do begin
    n_tag = where( strcmp(tag_names(swp_pp),str_arr(ii),/fold_case) eq 1 )
    data_y(*,ii)  =  swp_pp.(n_tag)
  endfor
  
  if keyword_set(Dstr_srr) then begin
    if n_elements(str_arr) ne n_elements(Dstr_arr) then begin
      print, 'str_arr and Dstr_arr must be the same langth.'
      return, 0
    endif
    for ii=0,n_elements(Dstr_arr)-1 do begin
      n_tag = where( strcmp(tag_names(swp_pp),Dstr_arr(ii),/fold_case) eq 1 )
      data_dy(*,ii)  =  Dswp_pp.(n_tag)
    endfor
  endif else data_dy = make_array(n_elements(data_y), value=!values.F_Nan) ;data_dy = SQRT(abs(data_y))
  
  ; ---------- create data --------------------------------
  ; Which are used should follow the SIS document for this variable !!
  ; Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data filed.
  data_l2 =  create_struct(       $
    'x',    double(swp_pp.time),  $ ; double 1-D arr
    'y',    data_y,               $ ; most of the time float and 1-D or 2-D
    'dy',   data_dy,              $ ; same size as y
    'flag', swp_pp.flg)             ;1-D
  ; ---------- create dlimit ------------------------------
  dlimit_l2 = make_dlimit(dlimit, data_y, prd_ver, flg.flag_info, flg.flag_source,ext,prd_cal_ver)
  ; ---------- create limit -------------------------------
  limit_l2  = make_limit(limit,data_y,str_arr,str_col)
  
  store_data,str_tname,data=data_l2,limit=limit_l2,dlimit=dlimit_l2
  
  return, str_tname
end
;--------------------------------------- tplot_upload -----


;===== START MAIN PROCEDURE: mvn_lpw_prd_lp_n_t====================================================
pro mvn_lpw_prd_lp_n_t, date_in, ext, t_int=t_int, make_cdf=make_cdf, dir_cdf=dir_cdf, fit_type=fit_type, $
                        lpw_cal_dir=lpw_cal_dir, win=win, test=test, prb=prb
                        ;, l1b_auto=l1b_auto;, lpw_cal_filename=lpw_cal_filename

;------ the version number of this routine --------------------------------------------------------
  t_routine=SYSTIME(0) & prd_ver= this_version_mvn_lpw_prd_lp_n_t()
  print, '------------------------------' & print, prd_ver & print, '------------------------------'

;----- Various settings 1) ------------------------------------------------------------------------
  sl = path_sep()
  LPSTRUC_DIR =  getenv('MVN_LPW_SWP_DATA_DIR')
  FIT_MM_DIR  =  '~/data/maven/idl/'

;----- Check inputs -------------------------------------------------------------------------------
  ;----- 'date_in' -----
  if keyword_set(date_in) eq 0 then begin & doc_library, 'mvn_lpw_prd_lp_n_t' & retall & endif
  
  ;----- 'ext' -----
  if keyword_set(ext) eq 0 then begin & doc_library, 'mvn_lpw_prd_lp_n_t' & retall & endif
  IF size(ext, /type) NE 7 THEN BEGIN
    print, "### WARNING ###: Input 'ext' must be a string: l1a, l1b or l2. Returning."
    retall
  ENDIF
  ;----- 'dir_cdf' -----
  if keyword_set(dir_cdf) then begin
     if file_test(dir_cdf,/directory) eq 0 then begin print, dir_cdf+' not exists.' & return & endif
  endif
  
  ;----- 'fit_type' -----
  if keyword_set(fit_type) eq 0 then fit_type = 'all' else $
  if keyword_set(fit_type) ne 'mm' and keyword_set(fit_type) ne 'ree' then begin
    doc_library, 'mvn_lpw_prd_lp_n_t' & retall
  endif

;----- Various settings 2) ------------------------------------------------------------------------
  cal_ver = 0
  prd_cal_ver = mvn_lpw_prd_lp_n_t_cal_version(cal_ver)
  yy=date_in/10000 & mm=(date_in mod 10000)/100 & dd=date_in mod 100 & doy = ymd2dn(yy,mm,dd)
  date_in_char = string(date_in,format='(I08)')
  yy_char = string(yy,format='(I04)') &   mm_char = string(mm,format='(I02)') &
  dd_char = string(dd,format='(I02)')

;--------------------------------------------------------------------------------------------------
SWP_ANALYS_START:  
;==================================================================================================

;      SWEEP DATA ANALYSYS START

;==================================================================================================
  prb_ex = [0,0]
  for prb=1,2 do begin ;------------------------------------------------------------ loop prb -----
    prb_char      = string(prb,format='(I01)')

    ;----- Read l0 sweep data with S/C information ----------------------------
    lpstruc_file = LPSTRUC_DIR+'create_lpstruc/'+yy_char+sl+mm_char+sl+'lpstruc_'+date_in_char+'_b'+prb_char+'*.sav'
    lpstruc_file = file_search(lpstruc_file)
    if keyword_set(lpstruc_file) eq 0 then print, 'no lpstruc file.'
    if keyword_set(lpstruc_file) eq 0 then continue
    restore, filename=lpstruc_file
    Vl0 = strsplit(lpstruc_file,'/_.',/extract) & Vl0 = Vl0(n_elements(Vl0)-3)
    
    ;----- Read tplot value to reffer the dlimit information ------------------
    ;----- Check if l0 version is same ----------------------------------------
    case prb of
      1: get_data,'mvn_lpw_swp1_I1',data=I_data,limit=limit,dlimit=dlimit
      2: get_data,'mvn_lpw_swp2_I2',data=I_data,limit=limit,dlimit=dlimit
    end
    l0_datafile = dlimit.L0_DATAFILE
    Vl0_t = strsplit(l0_datafile,'_.',/extract) & Vl0_t = Vl0_t(n_elements(Vl0_t)-2)    
    if Vl0 ne Vl0_t then begin
      print, 'LPW l0 file ver. does not match.' & continue
    endif

    tp_lim = [0 , n_elements(lpstruc)-1]
    if keyword_set(t_int) then tp_lim = mvn_lpw_prd_lp_extract_block(t_int,lpstruc.time)
    if tp_lim(1) eq -1 then tp_lim(1) = n_elements(lpstruc)-1
    
    ind = indgen(tp_lim(1)+1-tp_lim(0), start=tp_lim(0)) 
    
    if fit_type eq 'all' or fit_type eq 'mm' then $
      swp_pp = mvn_lpw_prd_lp_n_t_mm(lpstruc(ind), prd_ver=prd_ver, lpstruc_filename=lpstruc_file, $
        /pp_save, lpstruc_dir=LPSTRUC_DIR)

    if fit_type eq 'all' or fit_type eq 'ree' then begin
      print, 'REE FITTING'
    endif    
    
    ; -------------- the 'w' flag routine is used here, the 'lp' routine might be the same or different
  ;  IF strpos(dlimit.spice_kernel_flag, 'not') eq -1 THEN $    ; what aspects should be evaluates
  ;    check_varariables=['wake','sc_shadow','planet_shadow','sc_att','sc_pos','thrusters','gyros'] ELSE $
  ;    check_varariables=['fake_flag']  ; for now

MVN_LPW_PRD_LP_ADD_FLG_INFO:
    ;********* mvn_lpw_prd_w_flag doesn't work for now. put dummy data instead ********************
    ;mvn_lpw_prd_w_flag, swp_pp.time,check_varariables,swp_pp.flg, flag_info, flag_source, flg_vers_prd  ; this is based on mag resolution
    ;swp_pp.flg = make_array(n_elements(swp_pp),value=0) 
    flag_info = '-' &  flag_source = '-' & flg_vers_prd = '-'
    flg = {flag_info:flag_info,flag_source:flag_source}

    ;----- Correct information --------------------------------------------------------------------
   ;prd_ver = swp_pp[tp_lim(0)].prd_ver + ' # '+ 'flg_vers: ' + flg_vers_prd
    prd_ver = prd_ver + ' # '+ 'flg_vers: ' + flg_vers_prd
    print, prd_ver

MVN_LPW_PRD_LP_CREATE_DATA_SET:
    ; ---------- create n_t data set --------------------------------------------------------------
    str_tname = 'mvn_lpw_prd_lp_n_t_'+string(prb,FORMAT='(I1)')+'_'+ext
     str_arr   = ['U0','U1','Usc','Ne_tot','Ne1','Ne2','Te','Te1','Te2','Neprox']
    Dstr_arr   = ['dU0','dU1','dUsc','dNe1','dNe1','dNe2','dTe','dTe1','dTe2','Neprox']
    str_col   = [ 4,    4,    0,   0,   2,    2,    0,    3,    3,   6]
    stored_tname = tplot_upload(swp_pp,str_arr,str_tname,str_col,limit,dlimit,prd_ver,flg,ext,prd_cal_ver,Dstr_arr=Dstr_arr)

    ; ----- Ne -----
    str_tname = 'mvn_lpw_prd_lp_ne_'+string(prb,FORMAT='(I1)')+'_'+ext
     str_arr   = ['Ne_tot','Ne1','Ne2','Neprox']
    Dstr_arr   = ['dNe1','dNe1','dNe2','Neprox']
    str_col   = [ 0,    1,    3,   4]
    stored_tname = tplot_upload(swp_pp,str_arr,str_tname,str_col,limit,dlimit,prd_ver,flg,ext,prd_cal_ver,Dstr_arr=Dstr_arr)
    ; ----- Usc -----
    str_tname = 'mvn_lpw_prd_lp_Usc_'+string(prb,FORMAT='(I1)')+'_'+ext
     str_arr   = ['U0','U1','Usc']
    Dstr_arr   = ['dU0','dU1','dUsc']
    str_col   = [ 0,    1,    3]
    stored_tname = tplot_upload(swp_pp,str_arr,str_tname,str_col,limit,dlimit,prd_ver,flg,ext,prd_cal_ver,Dstr_arr=Dstr_arr)

    ;----- Store calbration data ------------------------------------------------------------------
    ;if strcmp(ext,'l1b') then begin
    ;  err = store_l1a_cal_data(swp_pp,mvn_lp_cal_file_head,prb)
    ;endif
    
MVN_LPW_PRD_LP_ANALYS_END:    
    delvar, current, voltage, swp_time, dI, dV, limit, dlimit, swp_pp
    prb_ex(prb-1) = 1
  endfor  ;------------------------------------------------------------------------- loop prb -----

MVN_LPW_PRD_LP_MARGE_DATA:
  ;--------------------- Marge the data, limit, and dlimit information ----------------------------
  ;--------------------- for tplot production in a routine called mvn_lpw_prd_limit_dlimt ---------

  if prb_ex(0) and prb_ex(1) then begin ; both probe 1 and 2 avarable
    get_data,'mvn_lpw_prd_lp_n_t_1_'+ext,data=data1,limit=limit1,dlimit=dlimit1
    get_data,'mvn_lpw_prd_lp_n_t_2_'+ext,data=data2,limit=limit2,dlimit=dlimit2
    dlimit_merge = mvn_lpw_prd_merge_dlimit(['found :','mvn_lpw_prd_lp_n_t_1_'+ext,'mvn_lpw_prd_lp_n_t_2_'+ext])
    add_tsort = sort([data1.x,data2.x])
    data_marge   = {x:[data1.x,data2.x],y:[data1.y,data2.y],dy:[data1.dy,data2.dy],flag:[data1.flag,data2.flag]}
    data_marge.x = data_marge.x[add_tsort]    & data_marge.flag = data_marge.flag[add_tsort]
    data_marge.y = data_marge.y[add_tsort,*]  & data_marge.dy   = data_marge.dy[add_tsort,*]
    limit_marge  = make_limit(limit1, data_marge.y, limit1.labels, limit1.colors)
    store_data,'mvn_lpw_prd_lp_n_t_'+ext,data=data_marge,limit=limit_marge,dlimit=dlimit_marge
  endif else if prb_ex(0) then begin ; only probe 1 avarable
    get_data,'mvn_lpw_prd_lp_n_t_1_'+ext,data=data,limit=limit,dlimit=dlimit
    store_data,'mvn_lpw_prd_lp_n_t_'+ext,data=data,limit=limit,dlimit=dlimit
  endif else if prb_ex(1) then begin ; only probe 1 avarable
    get_data,'mvn_lpw_prd_lp_n_t_2_'+ext,data=data,limit=limit,dlimit=dlimit
    store_data,'mvn_lpw_prd_lp_n_t_'+ext,data=data,limit=limit,dlimit=dlimit
  endif

MVN_LPW_PRD_LP_CREATE_CDF:
  ;----- Store results into cdf files ---------------------------------------------------------------
  fname_elements = strsplit(dlimit.l0_datafile,'_.',/extract)
  cdf_filename = strjoin(fname_elements(4:5),'_')
  
  if keyword_set(make_cdf) then begin

    ;----- Define store directory. Keyword: dir_cdf, 
    ;      Default is to store in 'cdf' directory in the current directory.
    if ~keyword_set(dir_cdf) then begin
        dir_cdf = '.'+path_sep()+'cdf'+path_sep()
        if ~keyword_set(file_search(['.'+path_sep()+'cdf'+path_sep()])) then file_mkdir, 'cdf'
    endif
    ;----- Set full path instead of using './' for current directory.
    if strcmp(strmid(dir_cdf,0,1),'.') then begin 
        CD, C=c & dir_cdf = c+strmid(dir_cdf,1,strlen(dir_cdf)-1)
    endif
    ;----- Set '/' in the end just in case.
    if ~strcmp(strmid(dir_cdf,strlen(dir_cdf)-1,1),path_sep()) then dir_cdf = dir_cdf+path_sep()
    ;--------------------------------------------------------------------------------------------------

    mvn_lpw_cdf_write, varlist='mvn_lpw_prd_lp_n_t_'+ext, dir=dir_cdf, cdf_filename='mvn_lpw_prd_lp_n_t_'+cdf_filename
  endif
  ;--------------------------------------------------------------------------------------------------

end 
;==================================================================================================