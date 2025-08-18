;+
; PRO  erg_load_xep_pre
;
; :Description:
;    The data read script for ERG/XEPe data in Provisional CDF.
;
; :Params:
;
; :Keywords:
;    uname: user ID to access the remote data repository for provisional CDF data files
;    passwd: password used with the above uname
;    downloadonly: Set to just download data files withoout loading data as tplot vars
;    no_download: Set not to download data files, instead check only the local directory
;
; :Examples:
;
; :History:
; 2017/08/25: rename 'erg_load_xep_pr.pro' to  'erg_load_xep_pre.pro'
; 2017/08/20: fixed some bugs
; 2016/02/01: first protetype
;
; :Author:
;   Y. Miyashita, ERG Science Center, ISEE, Nagoya Univ.
;   M. Teramoto, ERG Science Center, ISEE, Nagoya Univ.(erg-sc-core at isee.nagoya-u.ac.jp)
;
; $LastChangedDate: 2021-03-25 13:26:37 -0700 (Thu, 25 Mar 2021) $
; $LastChangedRevision: 29823 $
;-
pro erg_load_xep_pre, $
  level=level, $
  datatype=datatype, $
  trange=trange, $
  coord=coord, $
  get_support_data=get_support_data, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  verbose=verbose, $
  _extra=_extra , uname=uname, passwd=passwd


  ;Initialize the system variable for ERG
  erg_init

  ;Arguments and keywords
  lvl = 'pre'
  datatype = ''
  coord = ''
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0

  if ~keyword_set(uname) then begin
    uname=''
    read, uname, prompt='Enter username: '
  endif

  if ~keyword_set(passwd) then begin
    passwd=''
    read, passwd, prompt='Enter passwd: '
  endif


  ;*** load CDF ***
  ;--- Create (and initialize) a data file structure
  source=file_retrieve(/struct)

  ;--- Set parameters for the data file class
  source.local_data_dir = !erg.local_data_dir

  source.remote_data_dir=!erg.remote_data_dir


  ;Local and remote data file paths
  ;  dtype = strlowcase(datatype)
  ;  pos = strpos(dtype, '_energy')
  ;  if pos gt 0 then dtype = strmid( dtype, 0, pos )

  ;remotedir = 'https://'+uname+':'+passwd  $
  ;  + '@ergsc.isee.nagoya-u.ac.jp/data/ergsc/'+ $
  ;  'satellite/erg/xepe/l2pre/'
  remotedir =   !erg.remote_data_dir  + 'satellite/erg/xep/l2pre/'
  localdir =    !erg.local_data_dir   + 'satellite/erg/xep/l2pre/'

  ;Relative file path
  relpathnames1=file_dailynames(file_format='YYYY', trange=trange)
  relpathnames2=file_dailynames(file_format='YYYYMMDD', trange=trange)
  relfpathfmt = relpathnames1+'/erg_xep_' + lvl + '_' +relpathnames2+ '_v???.cdf'



  ;Expand the wildcards for the designated time range

  ;Download data files
  datfiles = $
    spd_download( remote_file = relfpathfmt, $
    remote_path = remotedir, local_path = localdir, /last_version ,no_download=no_download,$
    authentication=2, url_username=uname, url_password=passwd )
  if keyword_set(downloadonly) then return
  filestest=file_test(datfiles)

  if(total(filestest) ge 1) then begin
    datfiles=datfiles(where(filestest eq 1))

    ;Read CDF files and generate tplot variables
    prefix = 'erg_xep_'+lvl+'_'
    print,datfiles
    cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
      verbose = verbose

    get_data,prefix+'COUNT',data=xep_count,dlim=dlim
    label_name=strarr(12)
    for ist=0,3 do $
      label_name[ist]=strcompress(string(xep_count.v[0,ist,0],format='(i3.3)')+'-'+string(xep_count.v[0,ist,1],format='(i3.3)')+'keV')
    for ist=4,11 do $
      label_name[ist]=strcompress(string(xep_count.v[0,ist,0]/1000.,format='(f3.1)')+'-'+string(xep_count.v[0,ist,1]/1000.,format='(f3.1)')+'MeV')
    options,prefix+'COUNT',labels=label_name,labflag=-1
    store_data,prefix+'COUNT',data={x:xep_count.x,y:xep_count.y,v:(xep_count.v(*,*,0)+xep_count.v(*,*,1))/2000.}
    options,prefix+'COUNT',charsize=.95,spec=1
    options,prefix+'COUNT',ylog=1,zlog=1,ytitle='XEP!COMNI!Cprov.',ysubtitle='Energy [MeV]',$
      ztitle='[count/s]', ztickformat='pwr10tick'
    options,prefix+'COUNT','extend_y_edges', 1
    ylim,prefix+'COUNT',0.4,5.0


    ;--- print PI info and rules of the road
    gatt=cdf_var_atts(datfiles[0])

    print_str_maxlet, ' '
    print, '**********************************************************************'
    print, gatt.PROJECT
    print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
    print, ''
    print, 'Information about ERG XEP'
    print, ''
    print, 'PI: ', gatt.PI_NAME
    print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
    print, ''
    for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
    print, ''
    print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
    print, '**********************************************************************'
    print, ''

  endif
  
  return
end
