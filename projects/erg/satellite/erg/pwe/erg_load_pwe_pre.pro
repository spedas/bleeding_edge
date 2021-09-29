;+
; PRO erg_load_pwe_pre
;
; The read program for Provisonal PWE data
;
; :Keywords:
;   get_suuport_data: Set to load support data in CDF data files.
;   trange: Set a time range to load data explicitly for the specified
;           time range.
;   downloadonly: If set, data files are downloaded and the program
;                exits without generating tplot variables.
;   no_download: Set to prevent the program from searching in the
;                remote server for data files.
;   verbose:  Set to make some commands in this program verbose.
;   uname: user ID to be passed to the remote server for
;          authentication.
;   passwd: password to be passed to the remote server for
;           authentication.
;
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_pwe_pre
;
; :Authors:
;   Masafumi Shoji ERG Science Center (E-mail: masafumi.shoji at nagoya-u.jp)
;
; $LastChangedDate: 2020-12-08 06:04:52 -0800 (Tue, 08 Dec 2020) $
; $LastChangedRevision: 29445 $
; https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/mep/erg_load_pwe_pre.pro $
;-

pro erg_load_pwe_pre, $
   trange=trange, $
   get_support_data = get_support_data, $
   downloadonly=downloadonly, $
   no_download=no_download, $
   verbose=verbose, $
   uname=uname, $
   passwd=passwd, $
   _extra=_extra

  ;Initialize
  erg_init 

  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then begin
     no_download = 0 
     
     if ~keyword_set(uname) then begin
        uname=''
        read, uname, prompt='Enter username: '
     endif
     
     if ~keyword_set(passwd) then begin
        passwd=''
        read, passwd, prompt='Enter passwd: '
     endif
  endif
     
  remotedir=!erg.remote_data_dir+'satellite/erg/pwe/merged/l2pre/'
  localdir =!erg.local_data_dir +'satellite/erg/pwe/merged/l2pre/'

  relfpathfmt = 'YYYY/erg_pwe_pre_YYYYMMDD_v??.cdf'
  relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)

;;;;;;;;; 
  files=spd_download(local_path=localdir,remote_file=relfpaths,remote_path = remotedir,no_download=no_download,$
                     _extra=source,authentication=2, url_username=uname, url_password=passwd, /last_version)
  filestest=file_test(files)
  if total(filestest) eq 0 then begin
    dprint, 'No data file was found.'
    return
  endif
  if keyword_set(downloadonly) then return

  datfiles=files[where(filestest eq 1)]
     
;;;;;;;;;;;;;;;;;;;;

  gt0:
  
  prefix = 'erg_pwe_pre_'
  cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
             verbose = verbose
  
  com=['OFA_E_spectra_132','OFA_B_spectra_132','HFA_H_spectra_e_mix','HFA_M_spectra_e_mix','HFA_L_spectra_e_mix','EFD_DPB_spectra']
  nm = ['OFA-E', 'OFA-B', 'HFA-H','HFA-M', 'HFA-L', 'EFD-DPB']
  yr = [[0.032,20.], [0.032,20.], [1e0, 1e4], [1e0, 1e4], [1e0, 1e4], [1., 224.]] 
  ylog =[1,1,1,1,1,1]

  zr = [[1e-10, 1e0], [1e-4, 1e3], [1e-10, 1e-3], [1e-10, 1e-3], [1e-10, 1e-3], [1e-10, 1e0]]
  zlog = [1,1,1,1,1,1]

  for i=0, n_elements(com)-1 do begin
     
     get_data, prefix+com[i], dlim=dlim
  
     options, prefix+com[i], 'ytitle', 'ERG PWE/'+nm[i]
     options, prefix+com[i], 'ysubtitle', 'frequency [kHz]'
     options, prefix+com[i], 'ztitle', dlim.ysubtitle
     options, prefix+com[i], 'ytickformat', '(F10.2)'
     options, prefix+com[i], yrange=[yr[0,i], yr[1,i]], ylog=ylog[i], ystyle=1
     options, prefix+com[i], zrange=[zr[0,i], zr[1,i]], zlog=zlog[i]

     if strcmp(nm[i],'HFA-H') or  strcmp(nm[i],'HFA-L') then $
        options, prefix+com[i], datagap = 10.
     if strcmp(nm[i],'HFA-M') then $
        options, prefix+com[i], datagap = 100.

  endfor

  options, prefix+'EFD_DPB_spectra', ztitle='[mV^2/m^2/Hz]', ysubtitle='frequency [Hz]'

  get_data, prefix+'HFA_L_spectra_e_mix', lim=lim
  store_data, prefix+'HFA-merged', data=tnames([prefix+'HFA_H_spectra_e_mix', prefix+'HFA_L_spectra_e_mix']), lim=lim
  options, prefix+'HFA-merged', ytitle='ERG PWE/HFA'
  

  gatt=cdf_var_atts(datfiles[0])

  print_str_maxlet, ' '
  print, '**********************************************************************'
  print, 'Information about ERG PWE Provisional CDF'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
  print, ''
  for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
  print, ''
  print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
  print, '**********************************************************************'
  
  
END
