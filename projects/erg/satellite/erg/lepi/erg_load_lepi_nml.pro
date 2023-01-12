;+
; PRO erg_load_lepi_nml
;
; The read program for Level-2 and Level-3 LEP-i Normal mode data
;
; :Keywords:
;   level: level of data products. 'l2' is used to load Level-2 LEP-i data. 
;   'l3' is used to load Level-3 LEP-i data.
;   datatype: types of data products. For Level-2, 'omniflux','3dflux' 
;             are acceptable. For Level-3, currently only 'pa' is allowed.
;   varformat: If set a string with wildcards, only variables with
;              matching names are extrancted as tplot variables.
;   varformat: If set a string with wildcards, only variables with
;              matching names are extracted as tplot variables.
;   get_suuport_data: Set to load support data in CDF data files.
;                     (e.g., spin_phase, mode_reduction)
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
;   localdir: Set a local directory path to save data files in the
;             designated directory.
;   remotedir: Set a remote directory in the URL form where the
;              program will look for data files to download.
;   datafpath: If set a full file path of CDF file(s), then the
;              program loads data from the designated CDF file(s), ignoring any
;              other options specifying local/remote data paths. 
;   split_channel: Set to generate a F?DU tplot variable for each channel separately
;
; :Examples:
;   IDL> timespan, '2017-04-02'
;   IDL> erg_load_lepi_nml ;; omniflux data
;   IDL> erg_load_lepi_nml,datatype='3dflux' ;; 3D flux data
;   IDL> erg_load_lepi_nml,level='l3',;;Level 3 pitch angle 
;   distribution (PAD) data. Default is PA-T diagram
;
;
; :Authors:
;   Yoshi Miyoshi, ERG Science Center (E-mail: miyoshi at isee.nagoya-u.ac.jp)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-01-11 10:09:14 -0800 (Wed, 11 Jan 2023) $
; $LastChangedRevision: 31399 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/lepi/erg_load_lepi_nml.pro $
;-

pro erg_load_lepi_nml, $
   debug=debug, $
   level=level, $
   datatype=datatype, $
   varformat=varformat, $
   get_support_data=get_support_data, $
   trange=trange, $
   downloadonly=downloadonly, no_download=no_download, $
   verbose=verbose, $
   uname=uname, passwd=passwd, $
   localdir=localdir, $
   remotedir=remotedir, $
   datafpath=datafpath, $
   split_channel=split_channel, $
   _extra=_extra 

  
  ;;Initialize the user environmental variables for ERG
  erg_init


  ;;Arguments and keywords
  if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
  if ~keyword_set(level) then level = 'l2'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0

  
  ;; ; ; ; USER NAME ; ; ; ; 
  if keyword_set(datafpath) or keyword_set(no_download) then begin
     uname = ' ' & passwd = ' '  ;;padding with a blank
  endif 


if (level eq 'l2') then begin

  if ~keyword_set(datatype) then datatype = 'omniflux'
  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
     localdir = !erg.local_data_dir + 'satellite/erg/lepi/' $
                + level + '/' + datatype + '/'
  endif
  if ~keyword_set(remotedir) then begin
     remotedir = !erg.remote_data_dir + 'satellite/erg/lepi/' $
                 + level + '/' + datatype + '/'
  endif
  
  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir
  
  ;;Relative file path
  cdffn_prefix = 'erg_lepi_'+level+'_'+datatype+'_'
  relfpathfmt = 'YYYY/MM/' + cdffn_prefix+'YYYYMMDD_v??_??.cdf'
  
  ;;Expand the wildcards for the designated time range
  relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
  if debug then print, 'RELFPATHS: ', relfpaths
  
  ;;Download data files
  if keyword_set(datafpath) then datfiles = datafpath else begin
    datfiles = $
       spd_download( local_path=localdir $
                     , remote_path=remotedir, remote_file=relfpaths $
                     , no_download=no_download, /last_version $
                     , url_username=uname, url_password=passwd $
                   )
 endelse
  idx = where( file_test(datfiles), nfile )
  if nfile eq 0 then begin
     print, 'Cannot find any data file. Exit!'
     return
  endif
  datfiles = datfiles[idx]                 ;;Clip empty strings and non-existing files
  if keyword_set(downloadonly) then return ;;Stop here if downloadonly is set
  
  ;;Species to be loaded
  spcs = strsplit(/ext, 'P HE O' )
  
  ;;Read CDF files and generate tplot variables
  prefix = 'erg_lepi_' + level + '_' + datatype + '_'
  cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data, $
             varformat=varformat, verbose=verbose
  
  
  ;;Options for F?DO tplot variables
  if strcmp( datatype[0], 'omniflux' ) then begin
     vns_fido = [ 'FPDO', 'FHEDO', 'FODO'] 
     for i=0, n_elements(vns_fido)-1 do begin
        vn_fido = prefix+vns_fido[i]
        if tnames(vn_fido) eq '' then continue
        
        options, vn_fido, $
                 spec=1, $
                 ysubtitle='[keV/q]', $
                 ztickformat='pwr10tick', $
                 extend_y_edges=1, $
                 datagap=120., $
                 zticklen=-0.4
        get_data, vn_fido, dl=dl
        options, vn_fido, $
                 ztitle='['+dl.cdf.vatt.units+']', $
                 ytitle='ERG!CLEP-i/NML!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
        ylim, vn_fido, .01, 30., 1
        zlim, vn_fido, 0, 0, 1
     endfor
     
     
     gatt=cdf_var_atts(datfiles[0])
     goto, ROR
     
;     print_str_maxlet, ' '
;     print, '**********************************************************************'
;     print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
;     print, ''
;     print, 'Information about ERG LEPi'
;     print, ''
;     print, 'PI: ', gatt.PI_NAME
;     print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
;     print, ''
;     print, ''
;     for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
;     print, ''
;     print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
;     print, '**********************************************************************'
     
     return ;; finishes here if omniflux is set. 
  endif
  ;;END: Options for F?DO tplot variables
  
  
  ;;Options for tplot variables
  vns_fidu = [ 'FPDU',  'FPDU_sub', 'FHEDU', 'FHEDU_sub', 'FODU', 'FODU_sub'] 
  vns_fiedu = [ 'FPEDU', 'FPEDU_sub', 'FHEEDU', 'FHEEDU_sub', 'FOEDU', 'FOEDU_sub']
  vns_cnt = ['FPDU_COUNT_RAW','FPDU_COUNT_RAW_sub', 'FHEDU_COUNT_RAW','FHEDU_COUNT_RAW_sub', 'FODU_COUNT_RAW', 'FODU_COUNT_RAW_sub']
  
  vns = prefix + [ vns_fidu, vns_fiedu, vns_cnt ]  ;;common to flux/count arrays
  vns = tnames(vns) & if vns[0] eq '' then return
  
  options, vns, $
           spec=1, $
           ysubtitle='[keV/q]', $
           ztickformat='pwr10tick',$
           extend_y_edges=1,$
           datagap=60., $
           zticklen=-0.4
  
  for i=0, n_elements(vns)-1 do begin
     if tnames(vns[i]) eq '' then continue
     get_data, vns[i], data=data, dl=dl, lim=lim
     !null=where(tag_names(data) eq 'V1', cnt) ;;; added by MS
     if cnt eq 0 then continue ;;; added by MS
     if strmid(vns[i],2,3,/reverse_offset) ne 'sub' then begin        
        store_data, vns[i], data={x:data.x, y:data.y[*,0:29,*,*], $
                                  v:data.v1[0:29], $
                                  v2:indgen(8), $
                                  v3:indgen(16) },dl=dl,lim=lim
     endif else begin
        store_data, vns[i], data={x:data.x, y:data.y[*,0:29,*,*], $
                                  v:data.v1[0:29], $
                                  v2:indgen(7)+8, $
                                  v3:indgen(16) },dl=dl,lim=lim
     endelse
     options, vns[i], ztitle='['+dl.cdf.vatt.units+']', $
              ytitle='ERG!CLEP-i/NML!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
     ylim, vns[i], 0.01, 30., 1
     zlim, vns[i], 0, 0, 1
  endfor
  ;;The unit of differential flux is explicitly set for ztitle currently.
  vns = tnames(prefix+vns_fidu)
  if vns[0] ne '' then options, vns, ztitle='[/s-cm!U2!N-sr-keV/q]'
  ;;The unit of differential energy flux is explicitly set for ztitle.
  vns = tnames(prefix+vns_fiedu)
  if vns[0] ne '' then options, vns, ztitle='[keV/s-cm!I2!N-sr-keV]'
  
  
  ;;Generate separate tplot variables for the channels
  if keyword_set(split_channel) then begin
     for j=0, n_elements(vns_fidu)-1 do begin
        if tnames(prefix+vns_fidu[j]) eq '' then continue
        
        get_data, prefix+vns_fidu[j], data=d, dl=dl, lim=lim
        for i=0, n_elements(d.y[0, 0, *, 0])-1 do begin
           vn = prefix+vns_fidu[j]+'_channel'+string(i, '(i02)')
           store_data, vn, data={x:d.x, y:reform(d.y[*, 0:29, i, *]), v:d.v[0:29], v2:indgen(16)}, dl=dl, lim=lim
           options, vn, ytitle='ERG!CLEP-i/NML!C'+vns_fidu[j]+'!Cchannel'+string(i, '(i02)')+'!CEnergy'
        endfor
     endfor
     
  endif
  
  gatt=cdf_var_atts(datfiles[0])
  goto, ROR
  
;  print_str_maxlet, ' '
;  print, '**********************************************************************'
;  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
;  print, ''
;  print, 'Information about ERG LEPi'
;  print, ''
;  print, 'PI: ', gatt.PI_NAME
;  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
;  print, ''
;  print, ''
;  for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
;  print, ''
;  print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
;  print, '**********************************************************************'
 endif
  

if (level eq 'l3') then begin
    ;;Arguments and keywords
    if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
    if ~keyword_set(datatype) then datatype = 'pa'
    if ~keyword_set(downloadonly) then downloadonly = 0
    if ~keyword_set(no_download) then no_download = 0

  datatype = 'pa'
  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
     localdir = !erg.local_data_dir + 'satellite/erg/lepi/' $
                + level + '/' + datatype + '/'
  endif
  if ~keyword_set(remotedir) then begin
     remotedir = !erg.remote_data_dir + 'satellite/erg/lepi/' $
                 + level + '/' + datatype + '/'
  endif
  
  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir
  
  ;;Relative file path
  cdffn_prefix = 'erg_lepi_'+level+'_'+datatype+'_'
  relfpathfmt = 'YYYY/MM/' + cdffn_prefix+'YYYYMMDD_v??_??.cdf'
  
  ;;Expand the wildcards for the designated time range
  relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
  if debug then print, 'RELFPATHS: ', relfpaths
  
  ;;Download data files
  if keyword_set(datafpath) then datfiles = datafpath else begin
    datfiles = $
       spd_download( local_path=localdir $
                     , remote_path=remotedir, remote_file=relfpaths $
                     , no_download=no_download, /last_version $
                     , url_username=uname, url_password=passwd $
                   )
 endelse
  idx = where( file_test(datfiles), nfile )
  if nfile eq 0 then begin
     print, 'Cannot find any data file. Exit!'
     return
  endif
  datfiles = datfiles[idx]                 ;;Clip empty strings and non-existing files
  if keyword_set(downloadonly) then return ;;Stop here if downloadonly is set
  
  ;;Species to be loaded
  spcs = strsplit(/ext, 'P HE O' )
  
  ;;Read CDF files and generate tplot variables
  prefix = 'erg_lepi_' + level + '_' + datatype + '_'
; cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data, $ ;            varformat=varformat, verbose=verbose
  cdf2tplot, file=datfiles, prefix=prefix,get_support_data=get_support_data,$
  varformat=varformat, verbose=verbose

  for imass=0,2 do begin 
  ;;Options for tplot variables
  vns = ''
  append_array, vns, prefix+['F'+spcs[imass]+'DU']  ;;common to flux arrays

  get_data, vns, data=ori_data, dl=dl, lim=lim ; get data from tplot variable
  flux = ori_data.y
  energy_arr = ori_data.v1
  pa_arr = ori_data.v2

  n_chn = n_elements(energy_arr)
  for jene = 0, n_chn -1 do begin
    vn = prefix+'pabin_'+string(jene, '(i02)')+'_'+'F'+spcs[imass]+'DU'
    store_data, vn, data={x:ori_data.x, y:reform(flux[*,jene,*]), v:pa_arr}
    options,vn,spec=1
    options, vn, ztitle='['+dl.cdf.vatt.units+']'
    options,vn,datagap=120.
    options,vn,zlog=1
    zlim, vn, 0, 0
    ylim,vn,0.0,180.0
    options, vn, $
    ytitle='ERG LEP-i '+ spcs[imass] + '!C'+string(energy_arr[jene],'(f9.2)')+' keV!CPitch angle' 
    options,vn,ysubtitle='[deg]',ytickinterval=30
  endfor
 endfor
 
 gatt=cdf_var_atts(datfiles[0])
 goto, RoR


endif

ROR:
;--- print PI info and rules of the road
gatt=cdf_var_atts(datfiles[0])
; storing data information
if (keyword_set(get_filever)) then erg_export_filever, datfiles

print_str_maxlet, ' '
print, '**************************************************************************'
print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 75
print,'DATA TYPE= ',strmid(gatt.data_type,15)
print, ''
print, 'Information about ERG LEPi'
print, ''
print, 'PI: ', gatt.PI_NAME
print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 75
print, ''
print, 'RoR of ERG project common: https://ergsc.isee.nagoya-u.ac.jp'
if (level eq 'l3') then begin
  print, 'RoR of LEPi L3: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Lepi'
  print, 'RoR of MGF L2: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Mgf'
endif else print, 'RoR of LEPi L2: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Lepi'
print, 'Contact: erg_lepi_info at isee.nagoya-u.ac.jp'
print, '**************************************************************************'

  return
end
