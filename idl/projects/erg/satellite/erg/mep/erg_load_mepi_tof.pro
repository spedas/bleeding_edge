;+
; PRO erg_load_mepi_tof
;
; The read program for Level-2 MEP-i Time-of-flight (TOF) mode data
;
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_mepi_tof
;   IDL> erg_load_mepi_tof, datatype='raw'
;
; :Authors:
;   Tomo Hori, ERG Science Center (E-mail: tomo.hori at nagoya-u.jp)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2021-03-25 13:25:21 -0700 (Thu, 25 Mar 2021) $
; $LastChangedRevision: 29822 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/mep/erg_load_mepi_tof.pro $
;-
pro erg_load_mepi_tof, $
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
   tofspec=tofspec, $
   get_filever=get_filever, $
   _extra=_extra 

  
  ;;Initialize the user environmental variables for ERG
  erg_init

  ;;Arguments and keywords
  if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
  if ~keyword_set(level) then level = 'l2'
  if ~keyword_set(datatype) then datatype = 'flux'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0

  case strlowcase(datatype[0]) of
    'flux': dtype = 'tofflux'
    'raw': dtype = 'tofraw'
    else: begin
      print, "Datatype given is invalid! It should be either 'flux' or 'raw'."
      print, 'EXIT!'
      return
    endelse
  endcase
  
  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
    localdir = !erg.local_data_dir + 'satellite/erg/mepi/' $
               + level + '/tof/'
  endif
  if ~keyword_set(remotedir) then begin
    remotedir = !erg.remote_data_dir + 'satellite/erg/mepi/' $
                + level + '/tof/'
  endif
  
  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir

  ;;Relative file path
  cdffn_prefix = 'erg_mepi_'+level+'_'+dtype+'_'
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

  ;;Obtain the version information of data files
  if keyword_set(get_filever) then erg_export_filever, datfiles
  
  ;;Read CDF files and generate tplot variables
  prefix = 'erg_mepi_' + level + '_' + dtype + '_'
  cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data, $
             varformat=varformat, verbose=verbose

  ;; ---------- for TOF-flux data ---------- ;;

  if strcmp( dtype, 'tofflux' ) then begin
    
    ;;Options for tplot variables
    vns_fidu = [ 'FPDU', 'FHE2DU', 'FHEDU', 'FOPPDU', 'FODU', 'FO2PDU' ] 
    vns_cnt = 'count_raw_' + strsplit(/ext, 'P HE2 HE OPP O O2P' )
    
    vns = prefix + [ vns_fidu, vns_cnt ]  ;;common to flux/count arrays
    vns = tnames(vns) & if vns[0] eq '' then return
    
    options, vns, spec=1, ysubtitle='[keV/q]', ztickunits='scientific', extend_y_edges=1, $
             datagap=33., zticklen=-0.4
    for i=0, n_elements(vns)-1 do begin
      if tnames(vns[i]) eq '' then continue
      get_data, vns[i], data=0, dl=dl, lim=lim
      options, vns[i], ztitle='['+dl.cdf.vatt.units+']', $
               ytitle='ERG!CMEP-i/TOF!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
      ylim, vns[i], 4., 190., 1
      zlim, vns[i], 0, 0, 1
    endfor
    ;;The unit of differential flux is explicitly set for ztitle currently.
    vns = tnames(prefix+vns_fidu)
    if vns[0] ne '' then options, vns, ztitle='[/s-cm!U2!N-sr-keV/q]'
    ;;The unit of differential energy flux is explicitly set for ztitle.
    vns = tnames(prefix+vns_cnt)
    if vns[0] ne '' then options, vns, ztitle='[cnt/smpl]'
    
    ;;Generate the omni-directional flux (F?DO) 
    for i=0, n_elements(vns_fidu)-1 do begin
      vn = prefix + vns_fidu[i] 
      vn_fido = vn & strput, vn_fido, 'O', strlen(vn_fido)-1
      if tnames(vn) eq '' then continue 
      
      get_data, vn, data=d, dl=dl, lim=lim
      nanode = n_elements( d.y[0, 0, *] )
      is_finite = finite( d.y )
      id = where( is_finite, nid )
      if nid gt 0 then begin
        store_data, vn_fido, data={x:d.x, y:total( d.y, 3, /nan)/total( is_finite, 3 ), $
                                   v:d.v1}, lim=lim
        spcs_str = vns_fidu[i] & strput, spcs_str, 'O', strlen(spcs_str)-1 
        options, vn_fido, ytitle='ERG!CMEP-i/TOF!C'+spcs_str+'!CEnergy'
      endif
    endfor

  endif

  ;; ---------- for TOF-raw data ---------- ;;

  if strcmp( dtype, 'tofraw' ) then begin

    vns_cnt = [ 'count' ]
    vns_fidu = [ 'FIDU' ]
    
    vns = prefix + [ vns_fidu, vns_cnt ]  ;;common to flux/count arrays
    vns = tnames(vns) & if vns[0] eq '' then return
    
    options, vns, spec=1, ztickunits='scientific', extend_y_edges=1, $
             datagap=33., zticklen=-0.4
    for i=0, n_elements(vns)-1 do begin
      if tnames(vns[i]) eq '' then continue
      get_data, vns[i], data=d, dl=dl, lim=lim
      store_data, vns[i], data={x:d.x, y:d.y, v1:d.v1, v2:d.v2, v3:findgen(512)+0.5}, lim=lim
      options, vns[i], ztitle='['+dl.cdf.vatt.units+']' ;;, $
               ;; ytitle='ERG!CMEP-i/TOF!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
      zlim, vns[i], 0, 0, 1
    endfor
    
    ;;Generate TOF spectra
    if keyword_set( tofspec ) then begin

      vns = prefix + [ vns_fidu, vns_cnt ]
      
      for i=0, n_elements(vns)-1 do begin
        vn = vns[i] 
        if tnames(vn) eq '' then continue 
        
        get_data, vn, data=d, dl=dl, lim=lim
        nanode = n_elements( d.y[0, 0, *, 0] )
        ntof = n_elements( d.y[0, 0, 0, *] )
        nene = n_elements( d.y[0, *, 0, 0] )
        enes = d.v1 & tofs = d.v3
        
        for iene=0, nene-1 do begin

          dat = reform( d.y[*, iene, *, *] ) ;; [ (n_ti), 4, 512 ]
          ene = enes[iene] ;; [keV/q]
          is_finite = finite( dat )
          id = where( is_finite, nid )
          if nid gt 0 then begin
            newvn = vn + '_tofspec_sv' + string( iene, '(i02)' )
            store_data, newvn, data={x:d.x, y:total( dat, 2, /nan)/total( is_finite, 2 ), $
                                       v:tofs}, lim=lim
            ene_str = string( ene, '(i3)' ) + ' keV/q'
            options, newvn, ytitle='ERG!CMEP-i/TOF!C'+ene_str+'!C', ysubtitle='[TOF unit]', ystyle=1
            ylim, newvn, 0, ntof, 0
          endif
        endfor
        
      endfor
      
    endif






  endif

  ;; Display the data policy statements on the user's screen
  vn = (tnames(vns))[0]
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


  
