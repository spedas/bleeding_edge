;+
;
;PROCEDURE:       SWFO_NOAA_LOAD
;
;PURPOSE:         Loads SOLAR-1 (SWFO) netCDF files from NOAA National Centers for Environmental Information (NCEI),
;                 (formerly the National Geophysical Data Center: NGDC).
;
;INPUTS:          None.
;
;KEYWORDS:
;
;      TYPE:      Specifies the data type(s) to be loaded.
;                 Default is type = 'sci_mag-l3'. 
; 
;        ID:      If type = 'swpc', specifies the spacecraft ID.
;                 Default is id = 'active'.
;
;    TRANGE:      Specifies the time range to be loaded.
;
;      DATA:      Returns the actual data to be loaded from the netCDF file(s).
;
;LOCAL_DATA_DIR:  Specifies where to archive the downloaded file(s).
;
;     TNAME:      Returns the string array of created tplot variables.
;
;CREATED BY:      Takuya Hara on 2026-07-06.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-08-19 15:40:19 -0700 (Wed, 19 Aug 2026) $
; $LastChangedRevision: 34778 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_noaa_load.pro $
;
;-
function swfo_noaa_load_netcdf, ncfile
  for fileindex = 0, n_elements(ncfile)-1 do begin
    if file_test(ncfile[fileindex]) eq 0 then begin
        dprint, 'Invalid netCDF file found in netCDF_load_vars -- file not found: ' + ncfile[fileindex]
        if fileindex eq n_elements(ncfile)-1 then return, -1 else continue
    endif
    file = ncdf_open(ncfile[fileindex])
    inquire = ncdf_inquire(file)
    ; the number of dimensions defined in the netCDF file
    ndims = inquire.ndims
    ; the number of variables defined in the netCDF file
    nvars = inquire.nvars
    ; the number of global attributes defined in the netCDF file
    ngatts = inquire.ngatts
    ; the ID of the unlimited dimension, if there is one. this is likely to be 
    ; the dimension where the temporal data is stored
    id_unlimited_dim = inquire.recdim
    ; check that the data dimension is greater than zero
    
    if size(netCDFi, /type) ne 8 then begin ; check that 'netCDFi' structure doesn't already exist
        ; structure to be returned with data from netCDF file
        netCDFi = { filename: ncfile[fileindex] }
    
        ; loop through and store the global attributes
        for j = 0, ngatts-1 do begin
            ; inquire about this global attribute
            attrName = ncdf_attname(file, j, /global)
            attrInq = ncdf_attinq(file, attrName, /global)
            ncdf_attget, file, attrName, val, /global
            ; val is returned in bytes, need to convert to a string
            if size(val, /type) eq 1 then valString = string(byte(val)) else valString = val
            if j eq 0 then begin
                ; create global attribute structure
                gattr = create_struct(attrName, valString)
            endif else begin
                ; add to the global attribute structure
                str_element, gattr, attrName, valString, /add_rep
            endelse
        endfor
        ; store global attributes in the netCDFi structure
        str_element, netCDFi, 'g_attributes', gattr, /add_rep
        
        ; store number of variables in the netCDFi structure
        str_element, netCDFi, 'nv', nvars, /add_rep

        ; loop through and store the variables
        for i = 0, nvars-1 do begin
            ; inquire about a variable
            varinq = ncdf_varinq(file, i)
    
            data = {name: varinq.name, datatype: varinq.datatype, ndims: varinq.ndims, natts: varinq.natts, dimids: varinq.dim}
            ; loop through the variable attributes
            ;undefine, var_str ;This needs to be reinitialized for each variable so that attributes are not retained, 2015-05-22, jmm
            ;  meant to do the same thing as above, except without the seemingly arbitrary crashes on GOES data with some machines
            var_str = create_struct('kludge', 1) 

            for k = 0, varinq.natts-1 do begin
                var_attr_name = ncdf_attname(file, i, k)
                var_attr_inq = ncdf_attinq(file, i, var_attr_name)
                ncdf_attget, file, i, var_attr_name, attrval
                str_element, var_str, var_attr_name, string(byte(attrval)), /add_rep
            endfor
            ; get the data for this variable
            varsid = ncdf_varid(file,varinq.name) 
            ncdf_varget, file, varsid, value
            if ndimen(value) eq 2 then value = transpose(value)
            str_element, var_str, 'dataptr', ptr_new(value), /add_rep
            newdata = create_struct(data, var_str)
            if i eq 0 then begin
                vars = create_struct(newdata.name, newdata)
            endif else begin
                str_element, vars, newdata.name, newdata, /add_rep
            endelse
            str_element, netCDFi, 'vars', vars, /add_rep
        endfor
    endif else begin ; 'netCDFi' structure exists, add data from the next file to the current structure
        for i = 0, nvars-1 do begin
            varinq = ncdf_varinq(file, i)
            if tag_exist(netCDFi.vars, varinq.name) then begin
                olddata = *netCDFi.vars.(i).dataptr
                
                varsid = ncdf_varid(file,varinq.name) 
                ncdf_varget, file, varsid, value

                if ndimen(value) eq 2 then value = transpose(value)
                
                newdata = array_concat(value, olddata)
                ptr_free, netCDFi.vars.(i).dataptr
                netCDFi.vars.(i).dataptr = ptr_new(newdata)
            endif 
        endfor
    endelse
    ; close the netCDF file
    ncdf_close, file
  endfor
  return, netCDFi
end

FUNCTION swfo_noaa_file_retrieve, trange=trange, prod=prod, verbose=verbose, remote_path=rpath
  url = 'https://www.ncei.noaa.gov/cloud-access/space-weather-portal/api/v1/files?'
  url += 'prod=' + prod + '_solar1&' + 'start_time=' + time_string(trange[0], tformat='YYYY-MM-DDThh:mm:ssZ') + $
         '&end_time=' + time_string(trange[1], tformat='YYYY-MM-DDThh:mm:ssZ')

  ; Examples:
  ; https://www.ncei.noaa.gov/cloud-access/space-weather-portal/api/v1/files?prod=sci_mag-l3_solar1&start_time=2026-06-25T00:00:00Z&end_time=2026-07-07T00:00:00Z
  
  retry:
  undefine, result
  cmd = 'curl -s ' + "'" + url + "'" 
  SPAWN, cmd, result
  status = EXECUTE('info = JSON_PARSE(result)')
  IF status EQ 0 THEN GOTO, retry
  
  nfiles = N_ELEMENTS(info['data'])
  FOR i=0, nfiles-1 DO BEGIN
     rfile = info['data', i, 'file_link']
     append_array, rpath, (rfile.split(prod))[0]
     append_array, files, rfile.replace(rpath[-1], '')
  ENDFOR 

  IF undefined(files) THEN files = ''
  RETURN, files
END
  
PRO swfo_noaa_load, type=type, id=id, trange=trange, data=data, verbose=verbose, tname=tname, $
                    no_download=no_download, no_update=no_update, local_data_dir=local_data_dir

  tnow = SYSTIME(/sec)
  COMPILE_OPT IDL2
  
  IF undefined(type) THEN type = 'sci_mag-l3' ; SOLAR-1 MAG L3 1-sec & 1-min average (science-quiality)
  IF undefined(trange) THEN get_timespan, trange
  IF is_string(trange) THEN trange = time_double(trange)
  IF is_string(local_data_dir) THEN ldir = local_data_dir ELSE ldir = root_data_dir()
  url = 'https://archive.data.noaa.gov/satellite-spaceweather/SWFO/SOLAR-1/'
  nan = !values.f_nan
  
  FOR it=0, N_ELEMENTS(type)-1 DO BEGIN
     IF (type[it]).tolower() EQ 'swpc' THEN BEGIN
        IF undefined(id) THEN id = 'active'
        undefine, swind, imf
        url = 'https://tlv-swpc.woc.noaa.gov/hapi/data?id=' + id + '-plasma-pt1m&parameters=speed,density,temperature,quality,source&'
        url += 'time.min='  + time_string(trange[0], tformat='YYYY-MM-DDThh:mm:ssZ') + $
               '&time.max=' + time_string(trange[1], tformat='YYYY-MM-DDThh:mm:ssZ')

        cmd = 'curl -s ' + "'" + url + "'" 
        SPAWN, cmd, swind
        
        url = 'https://tlv-swpc.woc.noaa.gov/hapi/data?id=' + id + '-mag-pt1m&parameters=bt,bx_gsm,by_gsm,bz_gsm,theta_gsm,phi_gsm,quality,source&'
        url += 'time.min='  + time_string(trange[0], tformat='YYYY-MM-DDThh:mm:ssZ') + $
               '&time.max=' + time_string(trange[1], tformat='YYYY-MM-DDThh:mm:ssZ')

        cmd = 'curl -s ' + "'" + url + "'" 
        SPAWN, cmd, imf

        swind = (STRSPLIT(swind[1:*], ',', /extract)).toarray()
        imf   = (STRSPLIT(imf[1:*], ',', /extract)).toarray()

        prefix = 'swfo_swpc'
        twind  = time_double(swind[*, 0], tformat='YYYY-MM-DDThh:mm:ssZ')
        store_data, prefix + '_dens', data={x: twind, y: FLOAT(swind[*, 2])}, dlim={ytitle: 'SOLAR-1!CSWPC', ysubtitle: 'N [cm!E-3!N]'}
        store_data, prefix + '_velc', data={x: twind, y: FLOAT(swind[*, 1])}, dlim={ytitle: 'SOLAR-1!CSWPC', ysubtitle: 'V [km/s]'}
        store_data, prefix + '_temp', data={x: twind, y: FLOAT(swind[*, 3]) * (!const.k / !const.e)}, dlim={ytitle: 'SOLAR-1!CSWPC', ysubtitle: 'T [eV]'}

        tclip, prefix + '_dens', 1.e-10, 1.e4, /overwrite
        tclip, prefix + '_velc', 1.e-10, 1.e4, /overwrite
        
        timf = time_double(imf[*, 0], tformat='YYYY-MM-DDThh:mm:ssZ')
        store_data, prefix + '_bgsm', data={x: timf, y: FLOAT(imf[*, 2:4])}, dlim={ytitle: 'SOLAR-1!CSWPC', ysubtitle: 'B_GSM [nT]', labels: ['X', 'Y', 'Z'], labflag: -1, colors: 'bgr', constant: 0.}
        cotrans, prefix + '_bgsm', prefix + '_bgse', /gsm2gse
        options, prefix + '_bgse', ytitle='SOLAR-1!CSWPC', ysubtitle='B_GSE [nT]', /def
        store_data, prefix + '_btot', data={x: timf, y: FLOAT(imf[*, 1])}, dlim={ytitle: 'SOLAR-1!CSWPC', ysubtitle: '|B| [nT]'}
     ENDIF ELSE BEGIN
        rfiles = swfo_noaa_file_retrieve(trange=trange, prod=type[it], verbose=verbose, remote_path=rpath)
        lpath  = 'swfo/noaa/'
     
        IF undefined(rpath) THEN BEGIN
           dprint, dlevel=2, verbose=verbose, 'No remote SOLAR-1 files found.'
           RETURN
        ENDIF 

        FOR fi=0, N_ELEMENTS(rfiles)-1 DO $
           append_array, files, spd_download( $
                         remote_file=rfiles[fi], remote_path=rpath[fi], local_path=ldir + lpath + (rpath[fi]).replace(url, ''), $
                         no_download=no_download, no_updata=no_upate, /last_version, /valid_only, file_mode='666'o, dir_mode='777'o)
     
        
        w = WHERE(files NE '', nw)
        IF nw EQ 0 THEN BEGIN
           dprint, dlevel=2, verbose=verbose, 'No SOLAR-1 files found.'
           RETURN
        ENDIF ELSE BEGIN
           files = files[w]
           nfile = nw
        ENDELSE 
        undefine, rpath
        
        ncdfi = swfo_noaa_load_netcdf(files)

        CASE type[it] OF
           'sci_mag-l3': BEGIN
              prefix = 'swfo_sci_mag_l3'
              
              time = (*ncdfi.vars.time_min.dataptr)/1.d6 + time_double('1958')
              bgse = (*ncdfi.vars.b_gse_min.dataptr)
              
              btot = SQRT(TOTAL(bgse * bgse, 2))

              w = WHERE(btot GT 1.e4, nw)
              IF nw GT 0 THEN bgse[w, *] = !values.f_nan
              IF nw GT 0 THEN btot[w]    = !values.f_nan
              
              store_data, prefix + '_gse', data={x: time, y: bgse}, dlim={ytitle: 'SOLAR-1', ysubtitle: 'B_GSE [nT]', labels: ['X', 'Y', 'Z'], labflag: -1, colors: 'bgr', constant: 0.}
              store_data, prefix + '_tot', data={x: time, y: btot}, dlim={ytitle: 'SOLAR-1', ysubtitle: '|B| [nT]'}
           END 
           'swips-l3-avg1m': BEGIN ; Not yet available
              dprint, dlevel=2, verbose=verbose, 'This product is not yet available.'
              ;time = (*ncdfi.vars.time.dataptr)/1.d3
              ;dens = *ncdfi.vars.proton_density.dataptr
              ;velc = *ncdfi.vars.proton_speed.dataptr
              ;temp = *ncdfi.vars.proton_temperature.dataptr
              
              ;vvec = [ [*ncdfi.vars.proton_vx_gse.dataptr], [*ncdfi.vars.proton_vy_gse.dataptr], [*ncdfi.vars.proton_vz_gse.dataptr] ]
              
              ;prefix = 'swfo_swips_'
              ;store_data, prefix + type[it] + '_proton_dens', data={x: time, y: dens}, dlim={ytitle: 'SOLAR-1', ysubtitle: 'N [cm!E-3!N]'}
              ;store_data, prefix + type[it] + '_proton_velc', data={x: time, y: velc}, dlim={ytitle: 'SOLAR-1', ysubtitle: 'V [km/s]'}
              ;store_data, prefix + type[it] + '_proton_vgse', data={x: time, y: vvec}, dlim={ytitle: 'SOLAR-1', ysubtitle: 'V_GSE [km/s]', labels: ['X', 'Y', 'Z'], labflag: -1, colors: 'bgr', constant: 0.}
              ;store_data, prefix + type[it] + '_proton_temp', data={x: time, y: temp * (!const.k / !const.e)}, dlim={ytitle: 'SOLAR-1', ysubtitle: 'T [eV]'}
           END
           ELSE: BEGIN
              dprint, dlevel=2, verbose=verbose, 'This product is not yet available.'
              RETURN
           END
        ENDCASE

        str_element, data, type[it], TEMPORARY(ncdfi), /add
        undefine, inst
     ENDELSE 
  ENDFOR

  tname = tnames('*', create_time=ctime)
  w = WHERE(ctime GT tnow, nw)
  IF nw GT 0 THEN tname = tname[w] ELSE undefine, tname
  
  RETURN
END 
