;+
; PRO  erg_load_orb_l3
;
; :Description:
;    The data read script for ERG Definitive Orbit Level-3 data.
;
; :Params:
;
; :Keywords:
;    model: Default is 'op' for OP77Q model. 't89' loads T89 model, 'ts04' is for TS04 model
;    uname: user ID to be passed to the remote server for authentication.
;    passwd: password to be passed to the remote server for authentication.
;    previous: if user wants to load previous version of L3 orbit files having a time resolution of 6 sec, please set this keyword.
;   get_filever: Get data file version.
;
; :Examples:
;    erg_load_orb_l3  ; load orbit Level-3 data (using OP77Q).
;    erg_load_orb_l3, model='t89' ; load orbit Level-3 data (using T89).
;
; :History:
;    Prepared by Kunihiro Keika, ISEE, Nagoya University in July 2016
;    2016/02/01: first protetype
;    2017/02/20: Cut the part of loading predicted orb data in 'erg_load_orb.pro'
;                Pasted it to 'erg_load_orb_predict.pro'
;                by Mariko Teramoto, ISEE, Nagoya University
;    2017/10/31: rewirte for Orbit Level-3 data (OP77Q)
;                by Tzu-Fang Chang, ISEE, Nagoya University
;    2018/07/04: update for Orbit Level-3 data (T89)
;                by Tzu-Fang Chang, ISEE, Nagoya University
;    2019/02/14: update for Orbit Level-3 data (OP77Q and T89)
;                by Tzu-Fang Chang, ISEE, Nagoya University
;    2019/02/14: update for Orbit Level-3 data (OP77Q and T89)
;                by Tzu-Fang Chang, ISEE, Nagoya University
;
; :Author:
;   Chae-Woo Jun, ISEE, Nagoya University (chae-woo at isee.nagoya-u.ac.jp)
;   Tzu-Fang Chang, ISEE, Nagoya University (jocelyn at isee.nagoya-u.ac.jp)
;   Mariko Teramoto, ISEE, Naogya Univ. (teramoto at isee.nagoya-u.ac.jp)
;   Kuni Keika, Department of Earth and Planetary Science,
;     Graduate School of Science,The University of Tokyo (keika at eps.u-tokyo.ac.jp)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-01-11 10:09:14 -0800 (Wed, 11 Jan 2023) $
; $LastChangedRevision: 31399 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/orb/erg_load_orb_l3.pro $
;-

pro erg_load_orb_l3, $
  t89=t89, $
  trange=trange, $
  model=model,$
  uname=uname, passwd=passwd, $
  previous=previous,$
  get_support_data=get_support_data, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  localdir=localdir,$
  get_filever=get_filever,$
  verbose=verbose, $
  _extra=_extra 
  

  ;Initialize the system variable for ERG 
  erg_init 
  
  level = 'l3'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0 
  
  if ~keyword_set(previous) then begin
    ; load new L3 orbit data
    if ~keyword_set(model) then model = 'op'
    if in_set(model,'op') || in_set(model,'t89') || in_set(model,'ts04')then begin
      ;======================================================================================================================
      ; L3 OP77Q model
      ;======================================================================================================================
      if in_set(model, 'op') then begin
        remotedir = !erg.remote_data_dir +'satellite/erg/orb/l3/opq/'
        ;help, parse_url(remotedir)
        ;
        if ~keyword_set(localdir) then localdir = !erg.local_data_dir + 'satellite/erg/orb/l3/opq/'
        ;
        ;Relative file path
        relfpathfmt = 'YYYY/MM/erg_orb_' + level + '_op_YYYYMMDD_v??.cdf'
        model_name = 'OP77Q'
      endif

      ;======================================================================================================================
      ; L3 T89 model
      ;======================================================================================================================
      if in_set(model, 't89') then begin
        remotedir = !erg.remote_data_dir +'satellite/erg/orb/l3/t89/'
        ;help, parse_url(remotedir)
        ;
        if ~keyword_set(localdir) then localdir = !erg.local_data_dir + '/satellite/erg/orb/l3/t89/'
        
        ;
        ;Relative file path
        relfpathfmt = 'YYYY/MM/erg_orb_' + level + '_t89_YYYYMMDD_v??.cdf'
        model_name = 'T89'
      endif

      ;======================================================================================================================
      ; L3 TS04 model
      ;======================================================================================================================
      if in_set(model, 'ts04') then begin
        remotedir = !erg.remote_data_dir +'satellite/erg/orb/l3/ts04/'
        ;help, parse_url(remotedir)
        ;
        if ~keyword_set(localdir) then localdir = !erg.local_data_dir + '/satellite/erg/orb/l3/ts04/'
        ;
        ;Relative file path
        relfpathfmt = 'YYYY/MM/erg_orb_' + level + '_ts04_YYYYMMDD_v??.cdf'
        model_name = 'TS04'
      endif
      
      ;Expand the wildcards for the designated time range
      relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
      ;
      ;Download data files
      datfiles = spd_download( remote_file = relfpaths, $
        remote_path = remotedir, local_path = localdir, /last_version, $
        url_username=uname, url_password=passwd,$
        no_download=no_download, no_update=no_download, _extra=_extra )

      idx = where( file_test(datfiles), nfile )
      dat_files= datfiles[idx]
      if nfile eq 0 then begin
        print, 'Cannot find any data file. Exit!'
        return
      endif
      ;
      ;Read CDF files and generate tplot variables
      prefix = 'erg_orb_'+level+'_';+model+'_'
      if ~downloadonly then $
        cdf2tplot, file = dat_files, prefix = prefix, get_support_data = get_support_data, $
        verbose = verbose
        
      if  total(strlen(tnames('erg_orb_l3_*_'+model)) gt 1) eq 8 then begin
        remove_duplicated_tframe, tnames('erg_orb_l3_*_'+model)

        ; - - - - OPTIONS FOR TPLOT VARIABLES - - - -
        options,  prefix+'pos_lmc_'+model, ytitle='Lmc ('+model_name+')',ysubtitle='[dimensionless]'
        options,  prefix+'pos_lstar_'+model, ytitle='Lstar ('+model_name+')',ysubtitle='[dimensionless]'
        options,  prefix+'pos_I_'+model, ytitle='I ('+model_name+')',ysubtitle='[Re]'
        options,  prefix+'pos_blocal_'+model, ytitle='Blocal ('+model_name+')',ysubtitle='[nT]'
        options,  prefix+'pos_beq_'+model, ytitle='Beq ('+model_name+')',ysubtitle='[nT]'
        options,  prefix+'pos_eq_'+model, ytitle='Eq_pos ('+model_name+'Q)',ysubtitle='[Re Hour]'
        options,  prefix+'pos_iono_north_'+model, ytitle='footprint_north ('+model_name+')',ysubtitle='[deg. deg.]'
        options,  prefix+'pos_iono_south_'+model, ytitle='footprint_south ('+model_name+')',ysubtitle='[deg. deg.]'

        options,  prefix+'pos_lmc_'+model, 'labels', ['90deg','80deg','70deg','60deg','50deg','40deg','30deg','20deg','10deg']
        options,  prefix+'pos_lstar_'+model, 'labels', ['90deg','80deg','70deg','60deg','50deg','40deg','30deg','20deg','10deg']
        options,  prefix+'pos_I_'+model, 'labels', ['90deg','80deg','70deg','60deg','50deg','40deg','30deg','20deg','10deg']
        options,  prefix+'pos_'+'eq_'+model, 'labels', ['Re','MLT']
        options,  prefix+'pos_iono_'+['north_'+model,'south_'+model], 'labels', ['GLAT','GLON']
        options,  prefix+'pos_b'+['local_'+model,'eq_'+model], 'ylog', 1
        options,  prefix+'pos_b'+['local_'+model,'eq_'+model], 'labels', '|B|'
      endif
      
    endif else begin
      dprint, 'ERROR: please insert the correct model name: "op" for OP77Q, "t89" for T89 and "ts04" for TS04.'
      return
    endelse
  endif else begin
    
    ; load previous L3 orbit data
    ; - - - FOR CONFIRMED ORBIT DATA - - -
    ;Local and remote data file paths
    ;remotedir = !erg.remote_data_dir + 'satellite/erg/orb_pre/'
    ;remotedir = 'http://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/orb_pre/'
    if ~keyword_set(t89) then begin
      remotedir = 'http://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/orb/l3/'
      ;help, parse_url(remotedir)
      ;
      localdir = !erg.local_data_dir + 'satellite/erg/orb/l3/'
      ;
      ;Relative file path
      relfpathfmt = 'YYYY/erg_orb_' + level + '_YYYYMMDD_v??.cdf'
      ;
      ;Expand the wildcards for the designated time range
      relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
      ;
      ;Download data files
      datfiles = spd_download( remote_file = relfpaths, $
        remote_path = remotedir, local_path = localdir, /last_version, $
        no_download=no_download, no_update=no_download, _extra=_extra )
      ;
      idx = where( file_test(datfiles), nfile )
      dat_files= datfiles[idx]
      if nfile eq 0 then begin
        print, 'Cannot find any data file. Exit!'
        return
      endif
      ;Read CDF files and generate tplot variables
      prefix = 'erg_orb_'+level+'_'

      if ~downloadonly then $
        cdf2tplot, file = dat_files, prefix = prefix, get_support_data = get_support_data, $
        verbose = verbose

      if  total(strlen(tnames('erg_orb_l3_*_op')) gt 1) eq 8 then begin
        remove_duplicated_tframe, tnames('erg_orb_l3_*_op')

        ; - - - - OPTIONS FOR TPLOT VARIABLES - - - -
        options,  prefix+'pos_lmc_op', ytitle='Lmc (OP77Q)',ysubtitle='[dimensionless]'
        options,  prefix+'pos_lstar_op', ytitle='Lstar (OP77Q)',ysubtitle='[dimensionless]'
        options,  prefix+'pos_I_op', ytitle='I (OP77Q)',ysubtitle='[Re]'
        options,  prefix+'pos_blocal_op', ytitle='Blocal (OP77Q)',ysubtitle='[nT]'
        options,  prefix+'pos_beq_op', ytitle='Beq (OP77Q)',ysubtitle='[nT]'
        options,  prefix+'pos_eq_op', ytitle='Eq_pos (OP77Q)',ysubtitle='[Re Hour]'
        options,  prefix+'pos_iono_north_op', ytitle='footprint_north (OP77Q)',ysubtitle='[deg. deg.]'
        options,  prefix+'pos_iono_south_op', ytitle='footprint_south (OP77Q)',ysubtitle='[deg. deg.]'

        options,  prefix+'pos_lmc_op', 'labels', ['90deg','80deg','70deg','60deg','50deg','40deg','30deg','20deg','10deg']
        options,  prefix+'pos_lstar_op', 'labels', ['90deg','80deg','70deg','60deg','50deg','40deg','30deg','20deg','10deg']
        options,  prefix+'pos_I_op', 'labels', ['90deg','80deg','70deg','60deg','50deg','40deg','30deg','20deg','10deg']
        options,  prefix+'pos_'+'eq_op', 'labels', ['Re','MLT']
        options,  prefix+'pos_iono_'+['north_op','south_op'], 'labels', ['GLAT','GLON']
        options,  prefix+'pos_b'+['local_op','eq_op'], 'ylog', 1
        options,  prefix+'pos_b'+['local_op','eq_op'], 'labels', '|B|'

      endif else print,'Orb L3 CDF file (OP77Q) has not been created yet!'

    endif
    ;
    ;======================================================================================================================
    ;
    if keyword_set(t89) then begin
      remotedir = 'http://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/orb/l3_t89/'
      ;help, parse_url(remotedir)
      ;
      ;localdir =    !erg.local_data_dir      + 'satellite/erg/orb/'
      localdir = !erg.local_data_dir + 'satellite/erg/orb/l3_t89/'
      ;
      ;Relative file path
      relfpathfmt = 'YYYY/erg_orb_' + level + '_t89_YYYYMMDD_v??.cdf'
      ;
      ;Expand the wildcards for the designated time range
      relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
      ;
      ;Download data files
      datfiles = spd_download( remote_file = relfpaths, $
        remote_path = remotedir, local_path = localdir, /last_version, $
        no_download=no_download, no_update=no_download, _extra=_extra )
      
      idx = where( file_test(datfiles), nfile )
      dat_files= datfiles[idx]
      if nfile eq 0 then begin
        print, 'Cannot find any data file. Exit!'
        return
      endif
      ;
      ;Read CDF files and generate tplot variables
      prefix = 'erg_orb_'+level+'_'

      if ~downloadonly then $
        cdf2tplot, file = dat_files, prefix = prefix, get_support_data = get_support_data, $
        verbose = verbose

      if  total(strlen(tnames('erg_orb_l3_*_t89')) gt 1) eq 8 then begin
        remove_duplicated_tframe, tnames('erg_orb_l3_*_t89')

        ; - - - - OPTIONS FOR TPLOT VARIABLES - - - -
        options,  prefix+'pos_lmc_t89', ytitle='Lmc (T89)',ysubtitle='[dimensionless]'
        options,  prefix+'pos_lstar_t89', ytitle='Lstar (T89)',ysubtitle='[dimensionless]'
        options,  prefix+'pos_I_t89', ytitle='I (T89)',ysubtitle='[Re]'
        options,  prefix+'pos_blocal_t89', ytitle='Blocal (T89)',ysubtitle='[nT]'
        options,  prefix+'pos_beq_t89', ytitle='Beq (T89)',ysubtitle='[nT]'
        options,  prefix+'pos_eq_t89', ytitle='Eq_pos (T89)',ysubtitle='[Re Hour]'
        options,  prefix+'pos_iono_north_t89', ytitle='footprint_north (T89)',ysubtitle='[deg. deg.]'
        options,  prefix+'pos_iono_south_t89', ytitle='footprint_south (T89)',ysubtitle='[deg. deg.]'

        options,  prefix+'pos_lmc_t89', 'labels', ['90deg','80deg','70deg','60deg','50deg','40deg','30deg','20deg','10deg']
        options,  prefix+'pos_lstar_t89', 'labels', ['90deg','80deg','70deg','60deg','50deg','40deg','30deg','20deg','10deg']
        options,  prefix+'pos_I_t89', 'labels', ['90deg','80deg','70deg','60deg','50deg','40deg','30deg','20deg','10deg']
        options,  prefix+'pos_'+'eq_t89', 'labels', ['Re','MLT']
        options,  prefix+'pos_iono_'+['north_t89','south_t89'], 'labels', ['GLAT','GLON']
        options,  prefix+'pos_b'+['local_t89','eq_t89'], 'ylog', 1
        options,  prefix+'pos_b'+['local_t89','eq_t89'], 'labels', '|B|'

      endif else print,'Orb L3 CDF file (T89) has not been created yet!'

    endif
  endelse
    
  ;--- print PI info and rules of the road
  gatt=cdf_var_atts(dat_files[0])
  ; storing data information
  if (keyword_set(get_filever)) then erg_export_filever, dat_files

  print_str_maxlet, ' '
  print, '**************************************************************************'
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 75
  print, ''
  print, 'Information about ERG L3 orbit'
  print, ''
  print, 'RoR of ERG project common: https://ergsc.isee.nagoya-u.ac.jp'
  print, 'Contact: erg-sc-core at isee.nagoya-u.ac.jp'
  print, '**************************************************************************'  
  
  return
end
