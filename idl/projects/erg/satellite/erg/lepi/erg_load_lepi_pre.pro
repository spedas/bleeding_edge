;+
; PRO  erg_load_lepi_pre
;
; :Description:
;    The data read script for ERG/LEPI data in Provisional CDF. 
;
; :Params:
; 
;
; :Keywords:
; 
;
; :Examples:
;
; :History:
; 2017/07/07: first protetype 
;
; :Author:
;   Y. Miyoshi, ERG Science Center, ISEE, Nagoya Univ. 
;   M. Teramoto, ERG Science Center, ISEE, Nagoya Univ.(erg-sc-core at isee.nagoya-u.ac.jp)
;
; $LastChangedDate: 2021-03-25 13:26:37 -0700 (Thu, 25 Mar 2021) $
; $LastChangedRevision: 29823 $
;-
pro erg_load_lepi_pre, $
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

 remotedir = !erg.remote_data_dir + 'satellite/erg/lepi/l2pre/omnicnt/'
 ;remotedir = 'https://'+uname+':'+passwd  $
 ;              + '@ergsc.isee.nagoya-u.ac.jp/data/ergsc/'+ $
 ;              'satellite/erg/lepi/l2pre/omnicnt/'
  localdir =    !erg.local_data_dir      + 'satellite/erg/lepi/l2pre/omnicnt/' 
  
  ;Relative file path 
      relpathnames1=file_dailynames(file_format='YYYY', trange=trange)
    relpathnames2=file_dailynames(file_format='YYYYMMDD', trange=trange) 
  relfpathfmt = relpathnames1+'/erg_lepi_' + lvl + '_omnicnt_' +relpathnames2+ '_v??.cdf'
  print,relfpathfmt



  ;Expand the wildcards for the designated time range 
  
  ;Download data files 
  datfiles = $
    spd_download( remote_file = relfpathfmt, $
      remote_path = remotedir, local_path = localdir, /last_version ,no_download=no_download,$
      url_username=uname, url_password=passwd, authentication=2)
  filestest=file_test(datfiles)

if(total(filestest) ge 1) then begin
  datfiles=datfiles(where(filestest eq 1))
  
  ;Read CDF files and generate tplot variables 
  prefix = 'erg_lepi_'+lvl+'_'
  cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
    verbose = verbose 

  ylim,prefix+'FPDO',0.005,30.0
  zlim,prefix+'FPDO',0.1,1000.
  options,prefix+'FPDO',/ylog
  options,prefix+'FPDO',/zlog
  options,prefix+'FPDO',ytitle='LEP-i!COMNI!Cprov.', ysubtitle='Energy [kev]', $
    ztitle='[count/s]',ztickformat='pwr10tick',zticklen=-0.35

  get_data,prefix+'FPDO',data=lepi_count,dlim=dlim

 

  ;--- print PI info and rules of the road
  gatt=cdf_var_atts(datfiles[0])

  print_str_maxlet, ' '
  print, '**********************************************************************'
  print, gatt.PROJECT
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
  print, ''
  print, 'Information about ERG LEPI'
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

