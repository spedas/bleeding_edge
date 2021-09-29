;+
; PRO  erg_load_orb_predict
;
; :Description:
;    The data read script for ERG Predicted Orbit data.
;
; :Params:
;
; :Keywords:
;    LEVEL: 'l2': Level-2
;           Default is 'l2'.
;    DATATYPE: 'spre': short-term predicted orbit
;              'mpre': middle-term predicted orbit
;              'lpre': long-term predicted orbit
;               'pre': short-term or long-term predicted orbit
;               Default is 'pre'.
;
; :Examples:
;    erg_load_orb_predict ; load predicted orbit data.
;
; :History:
;    Prepared by Kunihiro Keika, ISEE, Nagoya University in July 2016
;    2016/02/01: first protetype for 'erg_load_orb.pro'
;    2017/02/20: Cut the part of loading predicted orbit data from 'erg_load_orb.pro'
;                Pasted it to 'erg_load_orb_predict.pro'
;                by Mariko Teramoto, ISEE, Nagoya University
;    2018/01/17: Add the datatype options for spre, mpre, and lpre orbit data
;                by Mariko Teramoto, ISEE, Nagoya University
;
; :Author:
;   Mariko Teramoto, ISEE, Naogya Univ. (teramoto at isee.nagoya-u.ac.jp)
;   Kuni Keika, Department of Earth and Planetary Science,
;     Graduate School of Science,The University of Tokyo (keika at eps.u-tokyo.ac.jp)
;
; $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
; $LastChangedRevision: 27922 $
;-

pro erg_load_orb_predict, $
  level=level, $
  datatype=datatype, $
  trange=trange, $
  coord=coord, $
  get_support_data=get_support_data, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  verbose=verbose, $
  _extra=_extra

  ;Initialize the system variable for ERG
  erg_init

  ;Arguments and keywords
  if not keyword_set(level) then level='l2'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0

  ;
  if undefined(datatype) then datatype=[ 'pre' ]
  suf_list = [ 'pre', 'spre', 'mpre', 'lpre' ]
  sufs = ssl_check_valid_name( datatype, suf_list )
  for i=0, n_elements(sufs)-1 do begin
    suf = sufs[i] & if ~strlen(suf) then continue

    relfpath='orb/' +suf+ '/YYYY/erg_orb_' +suf+ '_l2_YYYYMMDD_v??.cdf'



    ;
    ; - - - FOR PREDICTED ORBIT DATA - - -
    ;Local and remote data file paths
    remotedir = !erg.remote_data_dir + 'satellite/erg/orb/'+suf+'/'

    ;
    localdir =    !erg.local_data_dir      + 'satellite/erg/orb/'+suf+'/'
    ;
    ;Relative file path
    relfpathfmt = 'YYYY/erg_orb_'+suf+'_' + level + '_YYYYMMDD_v??.cdf'
    ;
    ;Expand the wildcards for the designated time range
    relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
    ;
    ;Download data files
    datfiles = $
      spd_download( remote_file = relfpaths, $
      remote_path = remotedir, local_path = localdir, /last_version, $
      no_download=no_download, no_update=no_download, _extra=_extra )
    ;
    ;Read CDF files and generate tplot variables
    prefix = 'erg_orb_'+suf+'_'+level+'_'
    if ~downloadonly then $
      cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
      verbose = verbose

    tvar_pos = prefix+'pos_gsm'
    get_data, tvar_pos, data=data, dlim=dlim
    str_element, dlim, 'data_att.coord_sys', strmid(tvar_pos,2,3,/rev), /add
    store_data, tvar_pos, data=data, dlim=dlim


    remove_duplicated_tframe, tnames('erg_orb_'+suf+'_l2_*')

    ; - - - - OPTIONS FOR TPLOT VARIABLES - - - -
    options, prefix+'pos_'+['gse','gsm','sm'], 'labels', ['X','Y','Z']
    options, prefix+'pos_'+['gse','gsm','sm','rmlatmlt'], 'colors', [2,4,6]
    options, prefix+'pos_'+'rmlatmlt', 'labels', ['Re','MLAT','MLT']
    options, prefix+'pos_'+'eq', 'labels', ['Req','MLT']
    options, prefix+'pos_iono_'+['north','south'], 'labels', ['GLAT','GLON']
    options, prefix+'pos_blocal', 'labels', ['X','Y','Z']
    options, prefix+'pos_blocal', 'colors', [2,4,6]
    options, prefix+'pos_blocal_mag', 'labels', 'B(model)!C_at_ERG'
    options, prefix+'pos_beq','labels', ['X','Y','Z']
    options, prefix+'pos_beq', 'colors', [2,4,6]
    options, prefix+'pos_beq_mag', 'labels', 'B(model)!C_at_equator'
    options, prefix+'pos_b'+['local','eq']+'_mag', 'ylog', 1
    options, prefix+'pos_'+'Lm', 'labels', ['90deg','60deg','30deg']
    options, prefix+'pos_'+'Lm', 'colors', [2,4,6]
    options, prefix+'vel_'+['gse','gsm','sm'], 'labels', ['X[km/s]','Y[km/s]','Z[km/s]']
    options, prefix+'vel_'+['gse','gsm','sm'], 'colors', [2,4,6]

  endfor
  return
end


