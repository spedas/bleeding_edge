;+
; PRO erg_load_mepe
;
; The read program for Level-2 MEP-e data 
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   datatype: types of data products. Currently only 'omniflux' and '3dflux' are acceptable.
;   varformat: If set a string with wildcards, only variables with
;              matching names are extrancted as tplot variables.
;   get_suuport_data: Set to load support data in CDF data files.
;                     (e.g., mode_reduction)
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
;   split_apd: Set to generate a FEDU tplot variable for each APD
;   split_energy: Set to generate a FEDU tplot variable for each energy
;             channel (only for Lv.3 PA data)
;   split_pa: Set to generate a FEDU tplot variable for each pitch
;             angle bin (only for Lv.3 PA data)
;   get_filever: Set to create a tplot variable "erg_load_datalist"
;                containing the version information of data files
;
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_mepe
;   IDL> erg_load_mepe, datatype='omniflux'
;
; :Authors:
;   Tomo Hori, ERG Science Center (E-mail: tomo.hori at nagoya-u.jp)
;
; $LastChangedDate: 2023-01-11 10:09:14 -0800 (Wed, 11 Jan 2023) $
; $LastChangedRevision: 31399 $
;-
pro erg_load_mepe, $
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
   split_apd=split_apd, $
   split_energy=split_energy, $
   split_pa=split_pa, $
   get_filever=get_filever, $
   _extra=_extra 

  
  ;;Initialize the user environmental variables for ERG
  erg_init

  ;;Arguments and keywords
  if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
  if ~keyword_set(level) then level = 'l2'
  if ~keyword_set(datatype) then datatype = 'omniflux'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0
  level = strlowcase(level)
  if level eq 'l3' then begin
    if undefined(datatype) then  datatype = 'pa'
  endif

  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
    localdir = !erg.local_data_dir + 'satellite/erg/mepe/' $
               + level + '/' + datatype + '/'
  endif
  if ~keyword_set(remotedir) then begin
    remotedir = !erg.remote_data_dir + 'satellite/erg/mepe/' $
                + level + '/' + datatype + '/'
  endif
  
  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir

  ;;Relative file path
  cdffn_prefix = 'erg_mepe_'+level+'_'+datatype+'_'
  relfpathfmt = 'YYYY/MM/' + cdffn_prefix+'YYYYMMDD_v*.cdf'
  
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
  datfiles = datfiles[idx] ;;Clip empty strings and non-existing files
  if keyword_set(downloadonly) then return ;;Stop here if downloadonly is set

  ;;Obtain the version information of data files
  if keyword_set(get_filever) then erg_export_filever, datfiles
  
  ;;Read CDF files and generate tplot variables
  prefix = 'erg_mepe_' + level + '_' + datatype + '_'
  cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data, $
             varformat=varformat, verbose=verbose
  
  
  ;;Options for tplot variables
  vns = ''
  if total(strcmp( datatype, '3dflux' )) then $
     append_array, vns, prefix+['FEDU', 'FEDU_n', 'FEEDU', 'count_raw']  ;;common to flux/count arrays
  if total(strcmp( datatype, 'omniflux')) then $
     append_array, vns, prefix+'FEDO'
  if level eq 'l3' and total(strcmp( datatype, 'pa' )) then $
     append_array, vns, prefix+['FEDU', 'count_raw']
  options, vns, spec=1, ysubtitle='[keV]', ztickunits='scientific', extend_y_edges=1, $
           datagap=17., zticklen=-0.4
  
  for i=0, n_elements(vns)-1 do begin
    if tnames(vns[i]) eq '' then continue
    get_data, vns[i], data=data, dl=dl, lim=lim
    if vns[i] eq prefix+'FEDO' then begin  ;; L2 omniflux
      store_data, vns[i], data={x:data.x, y:data.y, v:data.v }, dl=dl, lim=lim
      options, vns[i], ztitle='[/s-cm!U2!N-sr-keV]'
    endif else if vns[i] eq prefix+'FEDU' then begin  ;; L2 3dflux or L3 3dflux
      store_data, vns[i], data={x:data.x, y:data.y, v1:data.v1, v2:data.v2, $
                                v3:indgen(16) }, dl=dl, lim=lim
      options, vns[i], ztitle='['+dl.cdf.vatt.units+']'
    endif else if level eq 'l3' and datatype eq 'pa' and vns[i] eq prefix+'FEDU' then begin  ;; L3 PA flux
      store_data, vns[i], data={x:data.x, y:data.y, v1:data.v1, v2:data.v2} $
                               , dl=dl, lim=lim
      options, vns[i], ztitle='['+dl.cdf.vatt.units+']'      
    endif
    options, vns[i], ytitle='ERG!CMEP-e!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
    ylim, vns[i], 6., 100., 1
    zlim, vns[i], 0, 0, 1
  endfor

  ;; Skip just below unless the 3dflux or PA flux variables are loaded.
  if total(strcmp( vns, prefix+'FEDU' )) gt 0 then begin
    
    if datatype eq '3dflux' then begin  ;; L2 3dflux or L3 3dflux data

      ;;The unit of differential flux is explicitly set for ztitle currently.
      options, prefix+['FEDU', 'FEDU_n'], ztitle='[/s-cm!U2!N-sr-keV]'
      
      ;;Generate the omni-directional flux (FEDO)
      get_data, prefix+'FEDU', data=d, dl=dl, lim=lim
      store_data, prefix+'FEDO', data={x:d.x, y:total(total( d.y, 2, /nan), 3, /nan)/(32*16), v:d.v2}, lim=lim
      options, prefix+'FEDO', ytitle='ERG!CMEP-e!CFEDO!CEnergy'
      
      ;;Generate separate tplot variables for APDs
      if keyword_set(split_apd) then begin
        
        get_data, prefix+'FEDU', data=d, dl=dl, lim=lim
        for i=0, n_elements(d.y[0, 0, 0, *])-1 do begin
          vn = prefix+'FEDU_apd'+string(i, '(i02)')
          store_data, vn, data={x:d.x, y:reform(d.y[*, *, *, i]), v1:d.v1, v2:d.v2}, dl=dl, lim=lim
          options, vn, ytitle='ERG!CMEP-e!CFEDU!CAPD'+string(i, '(i02)')+'!CEnergy'
        endfor
      
      endif

    endif else if datatype eq 'pa' then begin ;; L3 PA flux data
      
      ;;The unit of differential flux is explicitly set for ztitle currently.
      options, prefix+['FEDU'], ztitle='[/s-cm!U2!N-sr-keV]'

      ;;Generate separate tplot variables for energy channels
      if keyword_set(split_energy) then begin
        get_data, prefix+'FEDU', data=d, dl=dl, lim=lim
        for i=0, n_elements(d.y[0, *, 0])-1 do begin
          vn = prefix+'FEDU_ene' + string(i, '(i02)' )
          store_data, vn, data={x:d.x, y:reform(d.y[*, i, *]), v:d.v2}, dl=dl, lim=lim
          options, vn, ytitle='ERG!CMEP-e!CFEDU!CEne'+string(i, '(i02)')+'!C', ysubtitle='PA [deg]'
          options, vn, ytickinterval=45, yminor=3, constant=[90]
          ylim, vn, 0, 180, 0
        endfor
      endif
      
      ;;Generate separate tplot variables for PA bins
      if keyword_set(split_pa) then begin
        get_data, prefix+'FEDU', data=d, dl=dl, lim=lim
        for i=0, n_elements(d.y[0, 0, *])-1 do begin
          paval = d.v2[i]  ;; pitch angle
          vn = prefix+'FEDU_pa' + string(i, '(i02)' )
          store_data, vn, data={x:d.x, y:reform(d.y[*, *, i]), v:d.v1}, dl=dl, lim=lim
          options, vn, ytitle='ERG!CMEP-e!CFEDU!CPA: '+strtrim(string(paval, '(i3)'), 2)+'!C', ysubtitle='[keV]'
        endfor
      endif
      
    endif
    
  endif


  ;;--- print PI info and rules of the road
  if strcmp(datatype, '3dflux') or strcmp(datatype, 'pa') then vn = prefix+'FEDU' $
  else vn = prefix+'FEDO'
  vn = (tnames(vn))[0]
  if vn ne '' then begin
    get_data, vn, dl=dl
    gatt = dl.cdf.gatt
    
    print_str_maxlet, ' '
    print, '**********************************************************************'
    print, ''
    print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
    print, 'PI: ', gatt.PI_NAME
    print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
    print, ''
    print, '- The rules of the road (RoR) common to the ERG project: '
    print, '      https://ergsc.isee.nagoya-u.ac.jp/data_info/rules_of_the_road.shtml.en'
    print, '- RoR for MEP-e data: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Mepe'
    if (level eq 'l3') then begin
      print, '- RoR for MGF data: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Mgf'
    endif
    print, ''
    print, 'Contact: erg_mep_info at isee.nagoya-u.ac.jp'
    print, '**********************************************************************'
    print, ''

  endif
  

  return
end
