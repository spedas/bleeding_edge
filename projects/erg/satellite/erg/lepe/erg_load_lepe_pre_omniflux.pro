;+
; PRO erg_load_lepe_pre_omniflux
;
; :Description:
;    To download and read an ERG/LEP-e provisional CDF data file
;
;
;
; :Keywords:
;    uname: user ID to access the remote data repository
;    passwd: password to access the remote data repository 
;    no_download: Set not to download data files 
;    no_update: Set not to overwrite the pre-existing data files in the local directory
;
; :Examples:
; IDL> timespan, '2017-04-01'
; IDL> erg_load_lepe_pre_omniflux, uname='*****', passwd='*****' 
;
; :History:
; 2017/07/01: Initial release
;
; :Author:
; Tomoaki Hori, ERG-SC, ISEE, Nagoya Univ.
; (E-mail: tomo.hori _at_ nagoya-u.jp )
;
; $LastChangedDate: 2021-03-25 13:26:37 -0700 (Thu, 25 Mar 2021) $
; $LastChangedRevision: 29823 $
;
;-
pro erg_load_lepe_pre_omniflux, $
  uname=uname, passwd=passwd, $
  no_download=no_download, no_update=no_update 
  
  ;Initialize the ERG data environment
  erg_init 
  
  ;Download data files from the remote data repository
  localdir = !erg.local_data_dir + 'satellite/erg/lepe/l2pre/omni/'
  remotedir = !erg.remote_data_dir + 'satellite/erg/lepe/l2pre/omni/'
  if undefined(uname) then uname = ''
  if undefined(passwd) then passwd = ''
  
  datfformat = 'YYYY/erg_lepe_pre_omniflux_YYYYMMDD_v??.cdf'
  relfnames = file_dailynames( file_format=datfformat, /unique, times=times) 
  l2cdffpath = spd_download( local_path=localdir, $
                  remote_path=remotedir, remote_file=relfnames, $
                  no_update=no_update, no_download=no_download, /last_ver, $
                  url_username=uname, url_password=passwd, authentication=2 )
  
  idx = where( file_test(l2cdffpath), nfiles )
  if nfiles eq 0 then begin
    print, 'Cannot find any L2 CDF file: ', l2cdffpath
    return
  endif
  
  l2cdffpath = l2cdffpath[idx]
  ;;dprint, l2cdffpath & return ;for debug
  
  
  prefix = 'erg_lepe_pre_'
  if ~keyword_set(datatype) then begin & datatype='*' & get_sup=1 & endif
  cdf2tplot, file=l2cdffpath, varformat=datatype, get_sup=get_sup, prefix=prefix
  if datatype ne '*' then return
  
  
  ;Modify attributes of the loaded tplot variables
  vn = prefix + 'FEDO'
  get_data, vn, data=d, dl=dl, lim=lim 
  idx = where( ~finite(d.y) or d.y lt 0. or d.y gt 1e+10, n )
  if n gt 0 then d.y[idx] = !values.f_nan
  store_data, vn, data={ x:d.x, y:d.y, v:total(d.v,2)/2 }, dl=dl, lim=lim
  zlim, vn, 0, 0, 1
  ylim, vn, 1e+1, 3e+4, 1 
  options, vn, ytitle='LEP-e!CProv.!CEnergy',ysubtitle='[eV]', $
    ztitle='omni count!C[cnt/s]', /ystyle, zticklen=-0.4, datagap=16.1
  
  vn = prefix + 'bgcnt_ratio'
  ylim, vn, 1e-2, 1e+2, 1
  options, vn, constant = 1.0, ytitle='Cnt!Dtotal!N/Cnt!Dbg!N!Cratio', datagap=16.1
  
  
  ;--- print PI info and rules of the road
  gatt=cdf_var_atts(l2cdffpath[0])

  print_str_maxlet, ' '
  print, '**********************************************************************'
  print, gatt.PROJECT
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
  print, ''
  print, 'Information about ERG LEP-e'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
  print, ''
  for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
  print, ''
  print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
  print, '**********************************************************************'
  print, ''
  
  
  return
end
