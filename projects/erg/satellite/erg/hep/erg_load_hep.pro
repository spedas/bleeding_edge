;+
; PRO erg_load_hep 
;
; :Description:
;    Read HEP Lv2 CDF files and load the data as tplot variables. 
;
;:Params:
;
;:Keywords:
;  datatype: Data type to be loaded. Currently "omniflux" and "3dflux" are acceptable. 
;  trange: If a time range is set, timespan is executed with it at the end of this program
;  splitazim: Set to make tplot variables of raw count for each azimuthal channel 
;  datadir: Set a local directory path to search it for data files. If set, 
;            this routine won't search the remote data server. 
;  lineplot: Set to make tplot variables for line plots separately. 
;  azch_for_spinph: set the number of an azimuthal channel to make tplot variables 
;                   of flux for each spin phase separately. 
;  files: To set an explicit file path of data file
;  no_download: Set to prevent this program from downloading data files from the remote 
;               repository, usually working with remote_srv keyword. 
;  download_only: If set, the program finishes after downloading data files, not making tplot vars. 
;  get_enecntr: If a named variable is set, an array containing the central values of 
;               energy bins (by log-averaging) is returned.
;  get_filever: Set to create a tplot variable "erg_load_datalist"
;               containing the version information of data files
;  
;:History:
; 2018/08/02: ver.2 (for public release)
; 2018/05/20: ver.1 (1st release version)
; 2018/05/01: RC1 version
;
;:Author:
; Tomo Hori, ERG Science Center ( E-mail: tomo.hori _at_ nagoya-u.jp )
;
; Written by: T. Hori
;   $LastChangedDate: 2021-03-25 13:25:21 -0700 (Thu, 25 Mar 2021) $
;   $LastChangedRevision: 29822 $
;-
pro erg_load_hep, files=files, level=level, datatype=datatype, varformat=varformat, $
                  version=version, $
                  trange=trange, splitazim=splitazim, $
                  datadir=datadir, div_dene=div_dene, lineplot=lineplot, $
                  azch_for_spinph=azch_for_spinph, $
                  no_download=no_download, download_only=download_only, $
                  get_enecntr=get_enecntr, $
                  uname=uname, passwd=passwd, $
                  ror=ror, $
                  get_filever=get_filever, $
                  debug=debug
  
  if ~keyword_set(debug) then debug = 0
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;Initialize
  erg_init
  
  if undefined( azch_for_spinph ) then azch_for_spinph = -1 
  if azch_for_spinph lt 0 or azch_for_spinph gt 14 then azch_for_spinph = -1 
  if undefined(no_download) then no_download = 0
  if undefined(level) then level = 'l2'
  if undefined(datatype) then datatype = 'omniflux'
  datatype = strlowcase(datatype[0]) ;; currently datatype should be a single string
  if level eq 'l3' then datatype = 'pa' ;; only ps is supported for Lv. 3 data so far
  
  no_update = no_download

  if undefined(version) then version = 'v??_??' ;; the wildcard for loading the latest version
  
  
  if ~keyword_set(files) then begin
    
    datfformat = 'YYYY/MM/erg_hep_'+level+'_'+datatype+'_YYYYMMDD_'+version+'.cdf'
    relfnames = file_dailynames( file_format=datfformat, /unique, times=times)
   
   if undefined(datadir) then begin
    localdir = !erg.local_data_dir + 'satellite/erg/hep/'+level+'/'+datatype+'/'
    remotedir = 'https://' $
      + 'ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/hep/'+level+'/'+datatype+'/'
    authentication = 2 ;meaning Digest only
    ;;no_download = 0 & no_update = 0
   endif else begin
    localdir = datadir & remotedir = datadir  ; for rferg 
    no_download = 1 & no_update = 1 
    authentication = 0 ;No authentication is applied
   endelse
   
   if debug then dprint, 'localdir = '+localdir
   if debug then dprint, 'remotedir = '+remotedir
   if debug then dprint, 'relfnames = '+relfnames 
   
   files = spd_download( local_path=localdir, $
                         remote_path=remotedir, remote_file=relfnames, /last_version, $
                         no_download=no_download, no_update=no_update, $
                         authentication=authentication, url_username=uname, url_password=passwd) 
   
    if keyword_set(download_only) then return 
    
  endif
  
  ;Check if data files given exist
  idx = where( file_test(files), n ) 
  if n eq 0 then begin
    print, 'Cannot find data CDF files!'
    return 
  endif
  files = files[idx] 
  
  ;; Obtain the version information of data files
  if keyword_set(get_filever) then erg_export_filever, files
  
  ;Load the data and convert to tplot variables
  prefix = 'erg_hep_'+level+'_'
  fedtype = 'FEDU'
  if strcmp(datatype, 'omniflux') then fedtype = 'FEDO'
  
  if undefined(varformat) then varformat = '*'
  cdf2tplot, file=files, varformat=varformat, prefix=prefix
  
  if strlen(tnames(prefix+fedtype+'_L')) lt 1 then begin
    print, 'Tplot variables have not been loaded with unknown reason(s).'
    print, 'Program exited.'
    return
  endif

  get_enecntr = fltarr(16, 2) ;; 16 bin for HEP-L and 16 bin for HEP-H
  
  ;Modify tplot variables so that they are plotted by simple tplot command
  for i=0, 1 do begin
    case (i) of
      0: begin
        suf = 'L'
        enerng = [ 30., 1800. ] 
      end
      1: begin
        suf = 'H'
        enerng = [ 70., 2048. ]
      end
    endcase
    
    
    ;;;;;;;;;;;  For Level-2 data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    if level eq 'l2' then begin

      
      ;;OMNI-directional flux but integrated only over azim. channels
      if tnames(prefix+fedtype+'_'+suf) eq '' then continue 

      ;;Labels for livetime_ratio
      vn_livetime = prefix+'livetime_ratio_'+suf
      if tnames(vn_livetime) eq vn_livetime then begin
        options, vn_livetime, labels=['head1', 'head2', 'head3'], labflag=-1
        ylim, vn_livetime, 0.4, 1.0, 0
      endif
      
      ;;Substitute fill values with NaN 
      tclip, prefix+fedtype+'_'+suf, -1e+10, 1e+10, /overwrite 
      options, prefix+fedtype+'_'+suf, no_interp=1

      ;; Get the energy bins
      get_data, prefix+fedtype+'_'+suf, data=d
      enebin = d.v
      enecntr = 10^( total( alog10(enebin), 1 )/2 ) ;log average of energy bins
      
      if strcmp(datatype, '3dflux') then begin
        
        get_data, prefix+fedtype+'_'+suf, data=d, dl=dl, lim=lim 
        fedu = d.y & tfedu = d.x
        intflux = total( d.y, 3, /nan ) 
        time_intflux = d.x

        nene = n_elements(enecntr)
        if nene eq 16 then get_enecntr[*, i] = enecntr else get_enecntr[(16-nene):15, i] = enecntr
        dene = reform( enebin[1, *]-enebin[0, *] )
        if ~keyword_set(div_dene) then dene[*] = 1. 

        ene_vvals = enecntr 
        
        get_data, prefix+'sctno_'+suf, data=d & scno = d.y 
        idx = where( scno eq 0, sc0num ) 
        if sc0num lt 2 then begin
          print, 'Too few data for HEP_'+suf
          continue
        endif
        sc0time = time_intflux[idx]
        dt = sc0time[1:*]-sc0time
        sc0dt = [ dt, dt[n_elements(dt)-1] ] ;; the last value is duplicated!
        
        omniflux = fltarr( sc0num, n_elements(fedu[0, *, 0]) ) 
        time_omniflux = dblarr( sc0num ) 
        spno = long(scno) & spno[*] = 0
        for j=0L, sc0num-1 do begin
          ids = idx[j]
          if j lt sc0num-1 then ide = idx[j+1]-1 else ide = n_elements(spno)-1 
          time_omniflux[j] = tfedu[ids] ; or mean( tfedu[ids:ide],/nan )
          nsct = ide-ids+1
          flux = fedu[ ids:ide, *, * ]
          flg = finite(flux)
          valid = where( flg, nvalid) & if nvalid eq 0 then continue
          
          omniflux[j, *] = transpose(  $
                           total(total( flux, 1, /nan ), 2, /nan) $
                           / total(total( flg, 1        ), 2 )      $
                                    ) 
          spno[ ids:ide ] = j 
          
          if debug then begin
            if (j mod 1000) eq 0 then print, 'is H?', (suf eq 'H'), '   dt:', sc0dt[j]
          endif
        endfor
        
        store_data, prefix+'FEDO_'+suf, data={x:time_omniflux, y:omniflux, v:ene_vvals}, dl=dl, lim=lim
      endif else begin ;; for the case of datatype='omniflux'
        get_data, prefix+'FEDO_'+suf, data=d, dl=dl, lim=lim
        store_data, prefix+'FEDO_'+suf, data={x:d.x, y:d.y, v:enecntr}, dl=dl, lim=lim
      endelse

      ztitle = '[/cm!U2!N-str-s-keV]'
      options, prefix+'FEDO_'+suf, $
               spec=1, ystyle=1, ytitle='HEP-'+suf+'!Comniflux!CLv2!CEnergy', ysubtitle='[keV]', $
               ztitle=ztitle, zticklen=-0.4, zlog=1, ztickunits='scientific', $
               labels=string(fix(enecntr), '(I4)')+' keV', labflag=-1
      ylim, prefix+'FEDO_'+suf, enerng[0], enerng[1], 1  
      zlim, prefix+'FEDO_'+suf, 0, 0, 1
      tdegap, prefix+'FEDO_'+suf, /over
      
                                ;Generate tplot vars for plotting with broken lines
      if keyword_set(lineplot) then begin
        copy_data, prefix+'FEDO_'+suf, prefix+'FEDO_'+suf+'_line'
        options, prefix+'FEDO_'+suf+'_line', $
                 ytitle='HEP-'+suf, ysubtitle=ztitle, ytickunits='scientific', spec=0
        ylim, prefix+'FEDO_'+suf+'_line', 0, 0, 1
      endif

      ;; Skip the following part unless 3-D flux data are loaded.
      if strcmp(datatype, '3dflux') then begin
        
        
                                ;Split into each azimuthal channel 
        if keyword_set(splitazim) then begin
          get_data, prefix+'FEDU_'+suf, data=d, dl=dl, lim=lim
          for az=0, n_elements(d.y[0, 0, *])-1 do begin
            
            varnm = prefix+'FEDU_'+suf+'_az'+string(az, '(i2.2)')
            store_data, varnm, $
                        data={ x:d.x, y:reform(d.y[*, *, az]), v:ene_vvals }, dl=dl, lim=lim
            options, varnm, ytitle='HEP-'+suf+'!Cazm'+string(az, '(i2.2)')+'!CEnergy'
            
          endfor
          options, prefix+'FEDU_'+suf+'_az??', $
                   spec=1, ystyle=1, ysubtitle='[keV]', $
                   ztitle='[/cm!U2!N-sr-s-keV]', zticklen=-0.4, zlog=1, no_interp=1
          ylim, prefix+'FEDU_'+suf+'_az??', enerng[0], enerng[1], 1
          zlim, prefix+'FEDU_'+suf+'_az??', 0, 0, 1
        endif
        
                                ;Split data of a particular sensor channel into each spin phase
        if azch_for_spinph ne -1 then begin
          azch = azch_for_spinph 
          get_data, prefix+'FEDU_'+suf, data=d, dl=dl, lim=lim
          cntarr = d.y & cntt = d.x 
          get_data, prefix+'sctno_'+suf, data=d & scno = d.y
          uniqid = uniq(scno[ sort(scno) ])
          scno_list = ( scno[ sort(scno) ] )[ uniqid ]
          if n_elements(scno_list) gt 16 then dprint, 'scno is greater than 16!!'
          print, 'scno_list: ', scno_list
          
          for j=0, n_elements(scno_list)-1 do begin
            spn = scno_list[j] 
            if spn lt 0 or spn gt 15 then continue
            
            idx = where( scno eq spn, num ) 
            if num le 1 then continue
            
            cnt = reform( cntarr[ idx, *, azch ] ) / (  transpose(dene) ## replicate(1., num) )
            vn = prefix+'FEDU_'+suf+'_az'+string(azch, '(i2.2)')+'_sph'+string(spn, '(i2.2)')
            store_data, vn, $
                        data={x:cntt[idx], y:cnt, v:ene_vvals}, dl=dl, lim=lim 
            ztitle = '[/cm!U2!N-sr-s-keV]'
            options, vn, $
                     spec=1, ytitle='HEP-'+suf+'!Caz'+string(azch, '(i2.2)')+'!Csph'+string(spn, '(i2.2)'), $
                     ysubtitle='[keV]', ztitle=ztitle, zticklen=-0.4, zlog=1, no_interp=1
            options, vn, ztickunits='scientific'
            ylim, vn, enerng[0], enerng[1], 1
            zlim, vn, 0, 0, 1
            tdegap, vn, /over
            
          endfor
          
        endif
        
      endif
      

    endif ;; End of the Level-2 block
    
    
    ;;;;;;;;;;;  For Level-3 data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    if level eq 'l3' then begin
      
      ;;Skip unless data variables are properly loaded
      vn_fedu = prefix + fedtype + '_' + suf  ;;e.g., erg_hep_l3_FEDU_L
      if tnames(vn_fedu) eq '' then continue 
      
      ;;Substitute fill values with NaN 
      tclip, vn_fedu, -1e+10, 1e+10, /overwrite 
      options, vn_fedu, no_interp=1

      ;;Generate PA-time spectra for each energy
      get_data, vn_fedu, data=d, dl=dl, lim=lim
      pac = d.v2 & enebins = d.v1 
      enevals = reform(sqrt(enebins[0, *] * enebins[1, *]))
      if debug then help, enebins, enevals
      
      for iene=0, n_elements(enevals)-1 do begin
        vn = vn_fedu + '_paspec_ene' + string(iene, '(i02)')
        store_data, vn, data={x:d.x, y:reform( d.y[*, iene, *]), v:pac}, dl=dl, lim=lim
        options, vn, spec=1, ystyle=1, $
                 ytitle='HEP-'+suf+'!CEne'+string(iene, '(i02)')+'!C'+string(enevals[iene], '(i4)')+' keV'
      endfor
      vn = vn_fedu + '_paspec_ene??'
      ylim, vn, 0, 180, 0
      if suf eq 'L' then zlim, vn, 1e+2, 1e+6, 1 else zlim, vn, 1e+1, 1e+4, 1
      options, vn, spec=1, ysubtitle='PA [deg]', extend_y_edges=1, $
               ztickunits='scientific', zticklen=-0.4, $
               ztitle='[/keV/cm!U2!N/sr/s]'
      options, vn, ytickinterval=45., constant=[45., 90., 135.]
      options, vn, datagap=130.
      
      
    endif ;; End of the Level-3 block

    
  endfor
  
  
  
  ;;Set the time range for which a plot is drawn
  if keyword_set(trange) then timespan, trange 
  
  ;;--- print PI info and rules of the road
  if strcmp(datatype, '3dflux') or strcmp(datatype, 'pa') then vn = prefix+'FEDU_?' $
  else vn = prefix+'FEDO_?'
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
    
    if keyword_set(ror) then begin
      for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
      print, ''
      print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
    endif else begin
      print, '- The rules of the road (RoR) common to the ERG project: '
      print, '      https://ergsc.isee.nagoya-u.ac.jp/data_info/rules_of_the_road.shtml.en'
      print, '- RoR for HEP data: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Hep'
      if (level eq 'l3') then begin
        print, '- RoR for MGF data: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Mgf'
      endif
      print, ''
      print, 'Contact: erg_hep_info at isee.nagoya-u.ac.jp'
    endelse
    
    print, '**********************************************************************'
    print, ''

  endif


  
  return
end
