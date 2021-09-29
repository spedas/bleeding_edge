;+
; PRO  erg_load_mep_pre 
;
; :Description:
;    Script for loading provisional ERG/MEP data. 
;
; :Keywords:
;    species: 'e' for electron data (default), 'i' for ion data. 
;    datatype: 'omni' -> omniflux from Normal Mode (default). 
;              'tof'  -> ion flux from TOF mode.  
;    uname: User ID for MEP data. If not set, ID is requested as standard input. 
;    passwd: Password for MEP data. If not set, password is requested as standard input. 
;
; :Examples:
;    ;MEP-e
;    erg_load_mep_pre, species='e', uname='XXXXX', passwd='XXXXX' 
;    ;MEP-i Normal mode 
;    erg_load_mep_pre, species='i', datatype='omni', uname='XXXXX', passwd='XXXXX' 
;    ;MEP-i TOF mode 
;    erg_load_mep_pre, species='i', datatype='tof', uname='XXXXX', passwd='XXXXX'
;
; :History:
; 2017/07/19: Updated for provisional MEP-i TOF mode data. 
; 2017/07/10: Updated for provisional CDF files
; 2016/02/01: first protetype 
;
; :Author:
;   Kuni Keika, ERG Science Center, ISEE, Nagoya Univ. 
;               University of Tokyo (keika at eps.s.u-tokyo.ac.jp) 
;
; $LastChangedDate: 2021-03-25 13:26:37 -0700 (Thu, 25 Mar 2021) $
; $LastChangedRevision: 29823 $
;-
pro erg_load_mep_pre, $
  level=level, $
  datatype=datatype, $
  trange=trange, $
  coord=coord, $
  get_support_data=get_support_data, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  verbose=verbose, $
  _extra=_extra, $ 
  species=species, $ 
  uname=uname, passwd=passwd  
  
  ;Initialize the system variable for ERG 
  erg_init 
  
  ;Arguments and keywords 
  if not keyword_set(species) then species='e'
  if not keyword_set(level) then level='pre' 
  ;level = 'l2' 
  if not keyword_set(datatype) then datatype='omni'  
  ;datatype = '3dflux' 
  coord = ''
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0 

  ; ; ; ; USER NAME ; ; ; ; 
  if ~keyword_set(uname) then begin
     uname=''
     read, uname, prompt='Enter username: '
  endif
  ; ; ; ; PASSWD ; ; ; ;
  if ~keyword_set(passwd) then begin
     passwd=''
     read, passwd, prompt='Enter passwd: '
  endif
  
  ;Local and remote data file paths
  ;remotedir = !erg.remote_data_dir + 'satellite/erg/mep'+species+'/'+'l2'+level+'e/' 
  ;remotedir = 'https://'+uname+':'+passwd  $
               ;+ '@ergsc.isee.nagoya-u.ac.jp/data/ergsc/' + 'satellite/erg/mep'+species+'/'+'l2'+level+'e/' 
               ;+ '@ergsc.isee.nagoya-u.ac.jp/data/ergsc/' + 'satellite/erg/mep'+species+'/'+'l2'+level+'/' 
  remotedir = !erg.remote_data_dir + 'satellite/erg/mep'+species+'/'+'l2'+level+'/'

  ;localdir =    !erg.local_data_dir      + 'satellite/erg/mep'+species+'/'+'l2'+level+'e/' 
  localdir =    !erg.local_data_dir      + 'satellite/erg/mep'+species+'/'+'l2'+level+'/' 
  
  ;Relative file path 
  ;relfpathfmt = 'YYYY/MM/erg_mepe_' + level + '_' + datatype + '_' + 'YYYYMMDD_hh_v??.cdf'
  relfpathfmt = 'YYYY/MM/erg_mep'+species+'_' + level + '_' + datatype + '_' + 'YYYYMMDD_v??.cdf'
  
  ;Expand the wildcards for the designated time range 
  ;relfpaths = file_dailynames(file_format=relfpathfmt, /hour_res, trange=trange, times=times) 
  relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times) 
  print, 'RELFPATHS:', relfpaths 
  
  ;Download data files 
  datfiles = $
    spd_download(remote_file = relfpaths, $
                 remote_path = remotedir, local_path = localdir, $ 
                 /last_version, no_download=no_download, $ 
                 authentication=2, url_username=uname, url_password=passwd, $
                 _extra=source ) 
  ; SAMPLE FROM MGF ; 
  ;datfiles = $ 
  ;  spd_download(remote_file=relpathnames,remote_path = remotedir,no_download=no_download,$
  ;                 _extra=source,authentication=2, /last_version)

  
  ;Read CDF files and generate tplot variables 
  prefix = 'erg_mep'+species+'_' + datatype + '_' 
  print, 'DATFILES: ', datfiles 
  cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
    verbose = verbose 
  
  ;
  if not keyword_set(tof) then del_data, prefix+'FIDO' 
  ;
  ;OPTIONS 
  options, prefix+'*', 'ylog', 1
  options, prefix+'*', 'zlog', 1
  options, prefix+'*', 'spec', 1
  options, prefix+'*', 'yrange', [2,200] 
  options, prefix+'*', 'ystyle', 1
  options, prefix+'*', 'ysubtitle', '[keV]' 
  options, prefix+'*', 'ztitle', '[cm!U-2!Ns!U-1!Nsr!U-1!NkeV!U-1]' 
  options, prefix+'*', 'datagap', 35. 
  options, prefix+'*', ztickformat='pwr10tick', zticklen=-0.35
  ;For mepe_omni_FEDO
  vn = 'erg_mepe_omni_FEDO'
  if tnames(vn) eq vn then begin
    options, vn, ytitle='MEP-e!CFEDO!Cprov.'
    ylim, vn, 6, 100, 1
  endif
  ;For mepi_omni_F*PDO
  vns = tnames('erg_mepi_omni_F*DO')
  if vns[0] ne '' then begin
    ylim, vns, 5, 230, 1
    for n=0, n_elements(vns)-1 do begin
      options, vns[n], ytitle='MEP-i!C' + (strsplit(vns[n],'_',/ext))[3] +'!Cprov.'
    endfor
  endif
  ;For TOF data
  if datatype eq 'tof' then options, prefix+'*FIDU', 'ztitle', 'counts' 

  
  return
end

