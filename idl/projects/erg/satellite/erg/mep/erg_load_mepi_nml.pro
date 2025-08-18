;+
; PRO erg_load_mepi_nml
;
; The read program for Level-2 MEP-i Normal mode data
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   datatype: types of data products. Currently only '3dflux' is acceptable.
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
;   split_anode: Set to generate a F?DU tplot variable for each anode
;   get_filever: Set to create a tplot variable "erg_load_datalist"
;                containing the version information of data files
;
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_mepi_nml, uname='?????', pass='?????'
;
; :Authors:
;   Tomo Hori, ERG Science Center (E-mail: tomo.hori at nagoya-u.jp)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-01-11 10:09:14 -0800 (Wed, 11 Jan 2023) $
; $LastChangedRevision: 31399 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/mep/erg_load_mepi_nml.pro $
;-
pro erg_load_mepi_nml, $
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
   split_anode=split_anode, $
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
  if level eq 'l3' and undefined(datatype) then datatype = '3dflux'

  
  ;; ; ; ; USER NAME ; ; ; ; 
  if undefined(uname) and undefined(passwd) then begin & uname = ' ' & passwd = ' ' & endif
  if keyword_set(datafpath) or keyword_set(no_download) then begin
    uname = ' ' & passwd = ' '  ;;padding with a blank
  endif 
  if ~keyword_set(uname) then begin
     uname=''
     read, uname, prompt='Enter username: '
  endif
  ;; ; ; ; PASSWD ; ; ; ;
  if ~keyword_set(passwd) then begin
     passwd=''
     read, passwd, prompt='Enter passwd: '
  endif

  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
    localdir = !erg.local_data_dir + 'satellite/erg/mepi/' $
               + level + '/' + datatype + '/'
  endif
  if ~keyword_set(remotedir) then begin
    remotedir = !erg.remote_data_dir + 'satellite/erg/mepi/' $
                + level + '/' + datatype + '/'
  endif
  
  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir

  ;;Relative file path
  cdffn_prefix = 'erg_mepi_'+level+'_'+datatype+'_'
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
  datfiles = datfiles[idx] ;;Clip empty strings and non-existing files
  if keyword_set(downloadonly) then return ;;Stop here if downloadonly is set

  ;;Obtain the version information of data files
  if keyword_set(get_filever) then erg_export_filever, datfiles
  
  ;;Species to be loaded
  spcs = strsplit(/ext, 'P HE2 HE OPP O O2P' )
   
  ;;Read CDF files and generate tplot variables
  prefix = 'erg_mepi_' + level + '_' + datatype + '_'
  cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data, $
             varformat=varformat, verbose=verbose

  ;;Options for F?DO tplot variables
  if strcmp( datatype[0], 'omniflux' ) then begin
    vns_fido = [ 'FPDO', 'FHE2DO', 'FHEDO', 'FOPPDO', 'FODO', 'FO2PDO', $
               'FPDO_tof', 'FHE2DO_tof', 'FHEDO_tof', 'FOPPDO_tof', 'FODO_tof', 'FO2PDO_tof' ] 
    for i=0, n_elements(vns_fido)-1 do begin
      vn_fido = prefix+vns_fido[i]
      if tnames(vn_fido) eq '' then continue

      smode = ( strpos( vn_fido, 'tof' ) gt 0 ? 'TOF' : 'NML' )
      
      options, vn_fido, $
               spec=1, ysubtitle='[keV/q]', ztickformat='pwr10tick', extend_y_edges=1, $
               datagap=33., zticklen=-0.4
      get_data, vn_fido, dl=dl
      options, vn_fido, $
               ztitle='['+dl.cdf.vatt.units+']', ytitle='ERG!CMEP-i/'+smode+'!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
      ylim, vn_fido, 4., 190., 1
      zlim, vn_fido, 0, 0, 1
    endfor
    
    goto, to_show_ror ;; finishes after shoing the RoR 
  endif
  
  
  ;;Options for tplot variables
  vns_fidu = [ 'FPDU', 'FHE2DU', 'FHEDU', 'FOPPDU', 'FODU', 'FO2PDU' ] 
  vns_fiedu = [ 'FPEDU', 'FHE2EDU', 'FHEEDU', 'FOPPEDU', 'FOEDU', 'FO2PEDU' ]
  vns_cnt = 'count_raw_' + strsplit(/ext, 'P HE2 HE OPP O O2P' )

  if datatype eq '3dflux' then begin
    vns = prefix + [ vns_fidu, vns_fiedu, vns_cnt ]  ;;common to flux/count arrays
  endif else begin
    vns = prefix + [ vns_fidu, vns_cnt ] ;; only for L3 PA flux data
  endelse
  vns = tnames(vns) & if vns[0] eq '' then return
  
  options, vns, spec=1, ysubtitle='[keV/q]', ztickunits='scientific', extend_y_edges=1, $
           datagap=33., zticklen=-0.4
  for i=0, n_elements(vns)-1 do begin
    if tnames(vns[i]) eq '' then continue
    get_data, vns[i], data=data, dl=dl, lim=lim

    ;; Replace fill values with NaN
    id = where( ~finite(data.y) or data.y lt -0.1, nid )
    if nid gt 0 then data.y[id] = !values.f_nan

    if datatype eq '3dflux' then begin
      store_data, vns[i], data={x:data.x, y:data.y, v1:data.v1, v2:data.v2, $
                                v3:indgen(16) }, dl=dl, lim=lim
    endif else begin
      store_data, vns[i], data={x:data.x, y:data.y, v1:data.v1, v2:data.v2 } $
                  , dl=dl, lim=lim
    endelse
    
    options, vns[i], ztitle='['+dl.cdf.vatt.units+']', $
             ytitle='ERG!CMEP-i/NML!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
    ylim, vns[i], 4., 190., 1
    zlim, vns[i], 0, 0, 1
  endfor
  ;;The unit of differential flux is explicitly set for ztitle currently.
  vns = tnames(prefix+vns_fidu)
  if vns[0] ne '' then options, vns, ztitle='[/s-cm!U2!N-sr-keV/q]'
  ;;The unit of differential energy flux is explicitly set for ztitle.
  vns = tnames(prefix+vns_fiedu)
  if vns[0] ne '' then options, vns, ztitle='[keV/s-cm!I2!N-sr-keV]'
  
  ;;Generate the omni-directional flux (F?DO)
  if datatype eq '3dflux' then begin ;; for L2/3 3dflux data
    
    for i=0, n_elements(vns_fidu)-1 do begin
      vn = prefix + vns_fidu[i] 
      vn_fido = vn & strput, vn_fido, 'O', strlen(vn_fido)-1
      if tnames(vn) eq '' then continue 
      
      get_data, vn, data=d, dl=dl, lim=lim
      nsmpl = total(total( finite(d.y), 2), 3)
      store_data, vn_fido, data={x:d.x, y:total(total( d.y, 2, /nan), 3, /nan)/(nsmpl), v:d.v2}, lim=lim
      spcs_str = vns_fidu[i] & strput, spcs_str, 'O', strlen(spcs_str)-1 
      options, vn_fido, ytitle='ERG!CMEP-i/NML!C'+spcs_str+'!CEnergy'
    endfor
    
    ;;Generate separate tplot variables for the anodes
    if keyword_set(split_anode) then begin
      for j=0, n_elements(vns_fidu)-1 do begin
        if tnames(prefix+vns_fidu[j]) eq '' then continue
        
        get_data, prefix+vns_fidu[j], data=d, dl=dl, lim=lim
        for i=0, n_elements(d.y[0, 0, 0, *])-1 do begin
          vn = prefix+vns_fidu[j]+'_anode'+string(i, '(i02)')
          store_data, vn, data={x:d.x, y:reform(d.y[*, *, *, i]), v1:d.v1, v2:d.v2}, dl=dl, lim=lim
          options, vn, ytitle='ERG!CMEP-i/NML!C'+vns_fidu[j]+'!Canode'+string(i, '(i02)')+'!CEnergy'
        endfor
      endfor
      
    endif

  endif

  if level eq 'l3' and datatype eq 'pa' then begin ;; for L3 PA flux data
    
    ;;Generate separate tplot variables for energy channels
    if keyword_set(split_energy) then begin
      foreach fidunm, vns_fidu do begin
        vn_fidu = prefix+fidunm
        if tnames(vn_fidu) eq '' then continue

        get_data, vn_fidu, data=d, dl=dl, lim=lim
        for i=0, n_elements(d.y[0, *, 0])-1 do begin
          vn = vn_fidu +'_ene'+string(i, '(i02)')
          store_data, vn, data={x:d.x, y:reform(d.y[*, i, *]), v:d.v2}, dl=dl, lim=lim
          options, vn, ytitle='ERG!CMEP-i/NML!C'+fidunm+'!CEne'+string(i, '(i02)')+'!C'
          options, vn, ysubtitle='PA [deg]', ytickinterval=45., yminor=3, constant=[90.]
          ylim, vn, 0, 180, 0
        endfor
        
      endforeach
    endif

    ;;Generate separate tplot variables for PA bins
    if keyword_set(split_pa) then begin
      foreach fidunm, vns_fidu do begin
        vn_fidu = prefix+fidunm
        if tnames(vn_fidu) eq '' then continue

        get_data, vn_fidu, data=d, dl=dl, lim=lim
        for i=0, n_elements(d.y[0, 0, *])-1 do begin
          paval = d.v2[i]
          vn = vn_fidu +'_pa'+string(i, '(i02)')
          store_data, vn, data={x:d.x, y:reform(d.y[*, *, i]), v:d.v1}, dl=dl, lim=lim
          options, vn, ytitle='ERG!CMEP-i/NML!C'+fidunm+'!CPA: '+strtrim(string(paval, '(i3)'), 2)+'!C'
        endfor
        
      endforeach
    endif
    
  endif

  
  to_show_ror: 
  ;;--- print PI info and rules of the road
  if strcmp(datatype, '3dflux') or strcmp(datatype, 'pa') then vn = prefix+'F*DU' $
  else vn = prefix+'F*DO'
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
    print, '- RoR for MEP-i data: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Mepi'
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
