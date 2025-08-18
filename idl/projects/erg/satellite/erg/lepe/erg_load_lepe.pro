;+
; PRO erg_load_lepe
;
; The read program for Level-2 and Level-3 LEP-e data
;
; :Note:
;    In order to let users easily plot the spectrum, flux and count arrays are sorted
;    in ascending order in terms of energy and saved in tplot variables. The actual
;    order of energy step is stored in data variable FEDU_Energy. Please refer to it
;    to derive the exact timing of each energy step within a spin phase.
;
; : IMPORTANT NOTE
;   This load procedure drops invalid packet data before constructing tplot variables.
;   The detail information is written in the following ERG-SC wiki.
;   (URL: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Lepe)
;
; :Keywords:
;   level: level of data products. 'l2' is used to load Level-2 LEP-e data. 'l3' is used to load Level-3 LEP-e data.
;   datatype: types of data products. For Level-2, '3dflux', '3dflux_finech' and 'omniflux' is allowed and default is 'omniflux'. For Level-3, currently only 'pa' is allowed.
;   varformat: If set a string with wildcards, only variables with
;              matching names are extrancted as tplot variables.
;   get_support_data: Set to load support data in CDF data files.
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
;   split_ch: Set to generate a FEDU tplot variable for each Channel only for Level-2 3Dflux data.
;   sorting_ene_chn: Set to sort energy channel only for Level-2 3Dflux data. 
;   et_diagram: Get energy-time diagram
;   only_fedu: only FEDU is extrancted as tplot variables.
;   get_filever: Get data file version.
;   (PLEASE do not use this keyword if you want to do the "part_product" process.)
;
;
; :Examples:
;  IDL> timespan,'2017-03-24'
;  IDL> erg_load_lepe  ;;omniflux data
;  IDL> erg_load_lepe,datatype='3dflux'   ;;3D flux data
;  IDL> erg_load_lepe,datatype='3dflux_finech'   ;;3D flux data
;  IDL> erg_load_lepe,datatype='3dflux',/split_ch   ;;3D flux data for each Channel
;  IDL> erg_load_lepe,datatype='3dflux',/sorting_ene_chn   ;;sorting energy channel and apply to 3Dflux data
;  IDL> erg_load_lepe,level='l3'   ;;Level 3 pitch angle distribution (PAD) data. Default is PA-T diagram
;  IDL> erg_load_lepe,level='l3',/et_diagram   ;;Level 3 pitch angle distribution (PAD) data for energy-time diagram for each pitch angle bin.
;
;
; :Authors:
;   Tomo Hori, ERG Science Center (E-mail: tomo.hori at nagoya-u.jp)
;   Tzu-Fang Chang, ERG Science Center (E-mail: jocelyn at isee.nagoya-u.ac.jp)
;   Chae-Woo Jun, ERG Science Center (E-mail: chae-woo at isee.nagoya-u.ac.jp)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-01-11 10:09:14 -0800 (Wed, 11 Jan 2023) $
; $LastChangedRevision: 31399 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/lepe/erg_load_lepe.pro $
;-
pro erg_load_lepe, $
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
  sorting_ene_chn=sorting_ene_chn,$
  split_ch=split_ch, $
  et_diagram=et_diagram, $
  get_filever=get_filever,$
  only_fedu=only_fedu,$
  fine=fine,$
  _extra=_extra

  ;;Initialize the user environmental variables for ERG
  erg_init

  ;;check data level
  if ~keyword_set(level) then level = 'l2'

  if (level eq 'l2') then begin
    ;;Arguments and keywords
    if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
    if ~keyword_set(datatype) then datatype = 'omniflux'
    if ~keyword_set(downloadonly) then downloadonly = 0
    if ~keyword_set(no_download) then no_download = 0
    if keyword_set(fine) then datatype = '3dflux_finech'
    
    ;;Local and remote data file paths
    if ~keyword_set(localdir) then begin
      localdir = !erg.local_data_dir + 'satellite/erg/lepe/' $
        + level + '/' + datatype + '/'
    endif
    if ~keyword_set(remotedir) then begin
      remotedir = !erg.remote_data_dir + 'satellite/erg/lepe/' $
        + level + '/' + datatype + '/'
    endif

    if debug then print, 'localdir = '+localdir
    if debug then print, 'remotedir = '+localdir
    
    ;;Relative file path
    ;cdffn_prefix = 'erg_lepe_'+level+'_'+datatype+'_' ;
    cdffn_prefix = 'erg_lepe_l2_'+datatype+'_' ; for l2new
    relfpathfmt = 'YYYY/MM/' + cdffn_prefix+'YYYYMMDD_v**_**.cdf'

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

    ;;Read CDF files and generate tplot variables
    prefix = 'erg_lepe_' + level + '_' + datatype + '_'
    cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data, $
      varformat=varformat, verbose=verbose
    
    ;;Options for tplot variables
    vns = ''
    if total(strcmp( datatype, '3dflux' )) then $
      append_array, vns, prefix+['FEDU','Count_rate','BG_count']  ;;common to flux/count arrays
    if total(strcmp( datatype, '3dflux_finech' )) then $
      append_array, vns, prefix+['FEDU','Count_rate','BG_count']  ;;common to flux/count arrays
    if total(strcmp( datatype, 'omniflux')) then $
      append_array, vns, prefix+'FEDO'  ;;Omni flux array
    options, vns, spec=1, ysubtitle='[eV]', ztickformat='pwr10tick', extend_y_edges=1, $
      datagap=17., zticklen=-0.4
      
    for i=0, n_elements(vns)-1 do begin
      if tnames(vns[i]) eq '' then continue
      ;; drop invalid time intervals
      get_data, vns[i], data=ori_data, dl=dl, lim=lim ; get data from tplot variable
      
      ; get time interval
      get_timespan,tr
      cor_ad = where(ori_data.x gt tr[0] and ori_data.x lt tr[1],ndata)
      
      ;;sorted flux and count arrays for plotting the spectrum
      if vns[i] eq prefix+'FEDO' then begin
        time = ori_data.x[cor_ad] 
        flux = ori_data.y[cor_ad,*]
        ene_ch = ori_data.v[cor_ad,*,*]
        
        ene = total(ene_ch,2)/2
        for n = 0, n_elements(time)-1 do begin
          sort_idx=sort(ene[n,*])
          flux[n,*]=flux[n,sort_idx]
          ene[n,*]=ene[n,sort_idx]
        endfor
        
        store_data, vns[i], data={x:time, y:flux, v:ene }, dl=dl, lim=lim
        options, vns[i], ztitle='[/s-cm!U2!N-sr-eV]',ytitle='ERG!CLEP-e!CFEDO!CEnergy'
        options, vns[i], ztitle='['+dl.cdf.vatt.units+']'
        options, vns[i], ytitle='ERG!CLEP-e!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
        zlim, vns[i], 1, 1e6, 1
        ylim, vns[i], 19, 21*1e+3, 1
      endif else begin
        ; FEDU
        time = ori_data.x[cor_ad]
        flux = ori_data.y[cor_ad,*,*,*]
        ene_ch = ori_data.v1[cor_ad,*,*]
        ene = total(ene_ch,2)/2
        if (keyword_set(sorting_ene_chn)) then begin
          for n = 0, n_elements(data.x)-1 do begin
            sort_idx=sort(ene[n,*])
            data.y[n,*,*,*]=data.y[n,sort_idx,*,*]
            ene[n,*]=ene[n,sort_idx]
          endfor
        endif

        store_data, vns[i], data={x:time, y:flux, v:ene, v2:ori_data.v2, $
          v3:indgen(16) }, dl=dl, lim=lim
        options, vns[i], ztitle='['+dl.cdf.vatt.units+']'
        options, vns[i], ytitle='ERG!CLEP-e!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
        zlim, vns[i], 1, 1e6, 1
        ylim, vns[i], 19, 21*1e+3, 1
      endelse
      ylim, vns[i], 1e+1, 3e+4, 1
      zlim, vns[i], 0, 0, 1
    endfor
    
    ;; Exit here unless the 3dflux variables are loaded.
    if total(strcmp( vns, prefix+'FEDU' )) eq 0 then goto, ROR

    ;;Generate separate tplot variables for Channels
    if keyword_set(split_ch) then begin
      get_data, prefix+'FEDU', data=d, dl=dl, lim=lim
      for i=0, n_elements(d.y[0, 0, *, 0])-1 do begin
        if i lt 5 then vn = prefix+'FEDU_ch'+string(i+1, '(i02)')
        if i gt 6 then vn = prefix+'FEDU_ch'+string(i+11, '(i02)')
        if i eq 5 then vn = prefix+'FEDU_chA'
        if i eq 6 then vn = prefix+'FEDU_chB'
        store_data, vn, data={x:d.x, y:reform(d.y[*, *, i, *]), v:d.v, v2:indgen(16)}, dl=dl, lim=lim
        if i lt 5 then options, vn, ytitle='ERG!CLEP-e!CFEDU_Ch'+string(i+1, '(i02)')+'!CEnergy'
        if i gt 6 then options, vn, ytitle='ERG!CLEP-e!CFEDU_Ch'+string(i+11, '(i02)')+'!CEnergy'
        if i eq 5 then options, vn, ytitle='ERG!CLEP-e!CFEDU_ChA!CEnergy'
        if i eq 6 then options, vn, ytitle='ERG!CLEP-e!CFEDU_ChB!CEnergy'
      endfor
    endif
  endif

 ; load l3 PAD CDF file
  if (level eq 'l3') then begin
    ;;Arguments and keywords
    if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
    if ~keyword_set(datatype) then datatype = 'pa'
    if ~keyword_set(downloadonly) then downloadonly = 0
    if ~keyword_set(no_download) then no_download = 0
    
    if keyword_set(fine) then datatype = 'pa_fine'

    ;;Local and remote data file paths
    if ~keyword_set(localdir) then begin
      localdir = !erg.local_data_dir + 'satellite/erg/lepe/' $
        + level + '/' + datatype + '/'
    endif
    if ~keyword_set(remotedir) then begin
      remotedir = !erg.remote_data_dir + 'satellite/erg/lepe/' $
        + level + '/' + datatype + '/'
    endif

    if debug then print, 'localdir = '+localdir
    if debug then print, 'remotedir = '+localdir
    
    ;;Relative file path
    ;cdffn_prefix = 'erg_lepe_'+level+'_'+datatype+'_' ;
    cdffn_prefix = 'erg_lepe_l3_'+datatype+'_' ; for l3 PAD
    relfpathfmt = 'YYYY/MM/' + cdffn_prefix+'YYYYMMDD_v**_**.cdf'

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

    ;;Read CDF files and generate tplot variables
    prefix = 'erg_lepe_' + level + '_' + datatype + '_'
    cdf2tplot, file=datfiles, prefix=prefix, /get_support_data, $
      varformat=varformat, verbose=verbose,varname = varname
    
    ;;Options for tplot variables
    vns = ''
    append_array, vns, prefix+['FEDU']  ;;common to flux/count arrays
    ;append_array, vns, prefix+['N_Energy']  ;;common to flux/count arrays
    
    if (vns eq '') then begin
      print, 'The variable of FEDU cannot be found in this CDF file.'
      return
    endif else begin
      ;; drop invalid time intervals
      ;get_data, vns, data=data, dl=dl, lim=lim
      get_data, vns, data=ori_data, dl=dl, lim=lim ; get data from tplot variable
      ;get_data, vns[1], data=ori_n_E;, dl=dl, lim=lim ; get data from tplot variable
      ;del_data,[vns[0],vns[1]];prefix+'*'

      ; get time interval
      get_timespan,tr
      cor_ad = where(ori_data.x gt tr[0]-600d and ori_data.x lt tr[1]+600d,ndata)
      
      time = ori_data.x[cor_ad]
      flux = ori_data.y[cor_ad,*,*]
      energy_channel = ori_data.v1[cor_ad,*,*]
      energy_arr = total(energy_channel,2,/nan)/2
      pa_arr = ori_data.v2;[5.625,16.875,28.125,39.375,50.625,61.875,73.125,84.375,95.625,106.875,118.125,129.375,140.625,151.875,163.125,174.375]

      ;    ; skip the lose cone mode (number of energy channel less than 5) for L3 data
      ;    LC_ad = where(corrected_n_eng gt 31, count_LC)
      ;    if (count_LC gt 0) then begin
      ;      flux[LC_ad,*,*] = !values.F_nan
      ;      energy_channel[LC_ad,*,*] = !values.F_nan
      ;    endif

      store_data,vns,data={x:time, y:flux, v1:energy_channel, v2:pa_arr}, dl=dl, lim=lim
      options, vns, spec=1, ysubtitle='[eV]', ztickformat='pwr10tick', extend_y_edges=1, $
        datagap=17., zticklen=-0.4
      zlim, vns, 1, 1e6, 1
      ylim, vns, 19, 21*1e+3, 1
      
      if ~keyword_set(only_fedu) then begin
        ; store L3 data into tplot variables. Default is pitch angle-time diagram. If set a keyword of 'et_diagram', then return energy-time diagrams for each pitch angle bin.
        if ~keyword_set(et_diagram) then begin
          dim = size(energy_arr,/dim)
          n_chn = dim[1]
          for j = 0, n_chn -1 do begin
            vn = prefix+'enech_'+string(j+1, '(i02)')
            store_data, vn, data={x:time, y:reform(flux[*,j,*]), v:pa_arr}, dl=dl, lim=lim
            options, vn, ztitle='['+dl.cdf.vatt.units+']'
            options, vn, ytitle='ERG LEP-e!C'+string(energy_arr[0,j],'(f9.2)')+' eV!CPitch angle', YSUBTITLE = '[deg]', yrange=[0,180],ytickinterval=30
            ylim, vn, 0, 180, 0
            zlim, vn, 1, 1e6, 1

          endfor
        endif else begin
          n_chn = n_elements(pa_arr)
          for j = 0, n_chn -1 do begin
            vn = prefix+'pabin_'+string(j+1, '(i02)')
            store_data, vn, data={x:time, y:reform(flux[*,*,j]), v:energy_arr}, dl=dl, lim=lim
            options, vn, ztitle='['+dl.cdf.vatt.units+']'
            options, vn, ytitle='ERG LEP-e!c'+string(pa_arr[j],'(f7.3)')+' deg!CEnergy'
            zlim, vn, 1, 1e6, 1
            ylim, vn, 19, 21*1e+3, 1
          endfor
        endelse
      endif
    endelse
  endif
  
  ROR:
  ;--- print PI info and rules of the road
  gatt=cdf_var_atts(datfiles[0])
  ; storing data information
  if (keyword_set(get_filever)) then erg_export_filever, datfiles
  
  print_str_maxlet, ' '
  print, '**************************************************************************'
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 75
  print, ''
  print, 'Information about ERG LEPe'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 75
  print, ''
  print, 'RoR of ERG project common: https://ergsc.isee.nagoya-u.ac.jp'
  if (level eq 'l3') then begin 
    print, 'RoR of LEPe L3: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Lepe'
    print, 'RoR of MGF L2: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Mgf'
  endif else print, 'RoR of LEPe L2: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Lepe' 
  print, 'Contact: erg_lepe_info at isee.nagoya-u.ac.jp'
  print, '**************************************************************************'

  return
end
