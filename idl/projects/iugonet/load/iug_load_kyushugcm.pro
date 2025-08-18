;+
; PROCEDURE: IUG_LOAD_KYUSHUGCM
;   iug_load_kyushugcm, datatype=datatype, $
;                     calmethod=calmethod, $
;                     altitutde=altitude, $
;                     trange=trange, $
;                     verbose=verbose, $
;                     downloadonly=downloadonly, $
;                     no_download=no_download, $
;                     selparam_idx=selparam_idx, $
;                     selparam_dat=selparam_dat, $
;                     newname=newname
;
; PURPOSE:
;   Loads the Kyushu GCM simulation data.
;
; KEYWORDS:
;   datatype = output physical quantity. 
;           T: temperature
;           U: zonal wind
;           V: meridional wind
;           W: Vertical wind
;   calmethod = option of the calculation method.
;           j3: use JRA data as the boundary condition and 
;               the number of altitude grid is 150.
;               Now, only j3 is available.
;
;   altitude: If set, altitude is in km. Otherwise, pressure (in hPa) is used.
;   trange = (Optional) Time range of interest  (2 element array).
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it 
;           into variables.
;   /no_download: use only files which are online locally.
;   selparam_idx: a vector with 3 elements to identify the loaded component
;           when converting 3D data to 2D or 1D data.
;           1st element: geographic latitude
;           2nd: geographic longitude
;           3rd: altitude
;           For example, a vector [0, 0, 1] means that the altitude profile 
;           is loaded.
;   selparam_dat: a vector with 3 elements to identify the position 
;           when converting 3D data to 2D or 1D data.
;           1st element: geographic latitude
;           2nd: geographic longitude
;           3rd: altitude
;           For example, if selparam_idx=[0,0,1], selparam_dat=[35., 135., 0.] 
;           means that an altitude profile at glat=35 and glon=135 is loaded.
;   newname: if set, then the loaded tplot variable is renamed to newname.
;           This keyword is available only when selparam_idx is set.
;
; EXAMPLE:
;   iug_load_kyushugcm, datatype='t'
;
; NOTE: See the rules of the road.
;       The simulation data are 3D and have a large file size (about 100MB).
;       The large file size may cause long download time and out of memory 
;       depending on the situation.
;
; Written by Y.-M. Tanaka, Aug.16, 2013 (ytanaka at nipr.ac.jp)
;-

pro iug_load_kyushugcm, datatype=datatype, calmethod=calmethod, $
        altitude=altitude, trange=trange, verbose=verbose, downloadonly=downloadonly, $
	no_download=no_download, selparam_idx=selparam_idx, $
	selparam_dat=selparam_dat, newname=newname

;===== Keyword check =====
;----- default -----;
if ~keyword_set(downloadonly) then downloadonly=0

;----- datatype -----;
datatype_all=strsplit('T U V W', /extract)
if(not keyword_set(datatype)) then datatype='T'
if size(datatype,/type) eq 7 then begin
  datatype=ssl_check_valid_name(datatype,datatype_all, $
                                /ignore_case)
  if datatype[0] eq '' then return
endif else begin
  message,'DATATYPE must be of string type.',/info
  return
endelse
datatype=strupcase(datatype)
print, datatype

;----- calmethod -----;
calmethod_all=strsplit('j3 s1 s2 s3 d1 d2 d3', /extract)
if(not keyword_set(calmethod)) then calmethod='j3'
if size(calmethod,/type) eq 7 then begin
  calmethod=ssl_check_valid_name(calmethod,calmethod_all, $
                                 /ignore_case, /include_all)
  if calmethod[0] eq '' then return
endif else begin
  message,'CALMETHOD must be of string type.',/info
  return
endelse
calmethod=calmethod[0] ; Select the 1st one only
print, calmethod

;----- selparam_idx -----;
if keyword_set(selparam_idx) or keyword_set(selparam_dat) then begin
  if keyword_set(selparam_idx) xor keyword_set(selparam_dat) then begin
    message, 'Both selparam_idx and selparam_dat are required, if either one is set.'
    return
  endif else begin
    if n_elements(selparam_idx) ne 3 then begin
        message,'selparam_idx must be a integer vector with 3 elements.'
        return
    endif
    if n_elements(selparam_dat) ne 3 then begin
        message,'selparam_dat must be a vector with 3 elements.'
        return
    endif
  endelse
endif

;===== Download files, read data, and create tplot vars at each site =====
;----- Loop -----
for i=0,n_elements(datatype)-1 do begin

    ;----- Set parameters for file_retrieve and download data files -----;
    source = file_retrieve(/struct)
    source.local_data_dir = root_data_dir() + 'iugonet/nipr/'
    source.remote_data_dir = 'http://iugonet0.nipr.ac.jp/data/'
    if keyword_set(no_download) then source.no_download = 1
    if keyword_set(downloadonly) then source.downloadonly = 1
    if keyword_set(verbose) then source.verbose = 1

    relpathnames1 = file_dailynames(file_format='YYYY', trange=trange)
    relpathnames2 = file_dailynames(file_format='YYYYMMDD', trange=trange)
    relpathnames  = 'gcm/'+calmethod+'/'+datatype[i]+'/'+$
      relpathnames1 + '/KyushuGCM_'+calmethod+'_'+datatype[i]+'_'+$
      relpathnames2 + '_v??.cdf'

    files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

    filestest=file_test(files)
    if total(filestest) ge 1 then begin
      files=files(where(filestest eq 1))
    endif

    ;----- Print PI info and rules of the road -----;
    if(file_test(files[0])) then begin
      gatt = cdf_var_atts(files[0])
      print, '**************************************************************************************'
      ;print, gatt.project
      print, gatt.Logical_source_description
      print, ''
      print, 'PI: ', gatt.PI_name
      print, 'Affiliations: ', gatt.PI_affiliation
      print, ''
      print, 'Rules of the Road for Kyushu GCM Simulation Data:'
      print_str_maxlet, gatt.Rules_of_use
      print, ''
      print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
      print, '**************************************************************************************'
    endif

    ;----- Load data into tplot variables -----;
    if(downloadonly eq 0) then begin
      ;----- Rename tplot variables of hdz_tres -----;
      prefix_tmp='niprtmp_'
      cdf2tplot, file=files, verbose=source.verbose, prefix=prefix_tmp

      tplot_name_tmp=tnames(prefix_tmp+'*')
      len=strlen(tplot_name_tmp[0])

      if len eq 0 then begin
        ;----- Quit if no data have been loaded -----;
        print, 'No tplot var loaded for '+datatype[i]+'.'
      endif else begin
        ;----- Loop for params -----;
        for j=0, n_elements(tplot_name_tmp)-1 do begin
	  cdfi = cdf_load_vars(files[0], varformat='*',/convert_int1_to_int2 )
          idx=where(cdfi.vars.name eq 'glat' )
          if idx ge 0 then glat = *cdfi.vars[idx].dataptr
          idx=where(cdfi.vars.name eq 'glon' )
          if idx ge 0 then glon = *cdfi.vars[idx].dataptr
          if keyword_set(altitude) then begin
            idx=where(cdfi.vars.name eq 'alt' )
            if idx ge 0 then v3tmp = *cdfi.vars[idx].dataptr/1000. ; m --> km
            yrng=[0., 480.]
            ylog=0
            ysubstr='Altitude [km]'
          endif else begin
            idx=where(cdfi.vars.name eq 'pressure' )
            if idx ge 0 then v3tmp = *cdfi.vars[idx].dataptr
            yrng=[1000., 1.0e-9]
            ylog=1
            ysubstr='Pressure'
          endelse

          get_data, tplot_name_tmp[j], data=d, lim=lim, dlim=dlim
          store_data, tplot_name_tmp[j], /delete

          tplot_name_new='kyushugcm_'+datatype[i]
          store_data, tplot_name_new, data={x:d.x, y:d.y, v1:glat, v2:glon, v3:v3tmp}, $
		lim=lim, dlim=dlim
          undefine, d

          ;----- Missing data -1.e+31 --> NaN -----;
          tclip, tplot_name_new, -1e+5, 1e+5, /overwrite

          ;----- Set options -----;
          case datatype[i] of
            'T' : begin
              options, tplot_name_new, ztitle = 'Temperature [K]', $
                ytitle='Kyushu GCM!CTemperature!C'
            end
            'U' : begin
              options, tplot_name_new, ztitle = 'Zonal Wind [m/s]', $
                ytitle='Kyushu GCM!CZonal Wind!C'
            end
            'V' : begin
              options, tplot_name_new, ztitle = 'Meridional Wind [m/s]', $
                ytitle='Kyushu GCM!CMeridional Wind!C'
            end
            'W' : begin
              options, tplot_name_new, ztitle = 'Vertical Wind [m/s]', $
                ytitle='Kyushu GCM!CVertical Wind!C'
            end
          endcase

          ;----- Convert 3D data to 2D or 1D data -----;
          if keyword_set(selparam_idx) then begin
            conv3d, tplot_name_new, selparam_idx=selparam_idx, selparam_dat=selparam_dat, $
		newname=newname

            if keyword_set(newname) then begin
                store_data, tplot_name_new, /delete
            endif 

            if keyword_set(newname) then begin
                tvar_new=newname
            endif else begin
                tvar_new=tplot_name_new
            endelse

            idx1=where(selparam_idx eq 1)
            if n_elements(idx1) eq 1 then begin
              case idx1 of
                0: options, tvar_new, ysubtitle='Latitude [degree]', spec=1
                1: options, tvar_new, ysubtitle='Longitude [degree]', spec=1
                2: begin
                   options, tvar_new, ysubtitle=ysubstr, spec=1, ylog=ylog
                   ylim, tvar_new, yrng
                end
              endcase
            endif
          endif

        endfor
      endelse
    endif
endfor

return

end
