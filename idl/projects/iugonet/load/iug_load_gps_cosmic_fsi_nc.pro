;+
;
;NAME:
;iug_load_gps_cosmic_fsi_nc
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the GPS-COSMIC radio occultation FSI data in the netCDF format
;  provided by UCAR and loads data into tplot format.
;
;SYNTAX:
; iug_load_gps_cosmic_fsi_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE (In): [1,...,5], Get more detailed (higher number) command line output.
;
;CODE:
; A. Shinbori, 14/05/2016.
;
;MODIFICATIONS:
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_gps_cosmic_fsi_nc, downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

  ;**********************
  ;Verbose keyword check:
  ;**********************
  if (not keyword_set(verbose)) then verbose = 2

  ;******************************************************************
  ;Loop on downloading files
  ;******************************************************************
  ;Get timespan, define FILE_NAMES, and load data:
  ;===============================================
  ;
  if ~size(fns,/type) then begin
    ;****************************
    ;Get files for ith component:
    ;****************************
    file_names = file_dailynames( $
      file_format='YYYY/RISHANA_YYYY.DOY' $
      ,trange=trange,times=times,/unique,/hour)+'.nc'

    ;===============================
    ;Define FILE_RETRIEVE structure:
    ;===============================
    source = file_retrieve(/struct)
    source.verbose=verbose
    source.local_data_dir = root_data_dir() + 'iugonet/rish/cosmic/fsi/v2_0/'
    source.remote_data_dir = 'http://database.rish.kyoto-u.ac.jp/arch/iugonet/data/GPS/cosmic/fsi/v2_0/nc/'

    ;=======================================================
    ;Get files and local paths, and concatenate local paths:
    ;=======================================================
    local_paths = spd_download(remote_file=file_names, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)
    local_paths_all = ~(~size(local_paths_all,/type)) ? $
      [local_paths_all, local_paths] : local_paths
    if ~(~size(local_paths_all,/type)) then local_paths=local_paths_all
  endif else file_names=fns

  ;--- Load data into tplot variables
  if (not keyword_set(downloadonly)) then downloadonly=0

  if (downloadonly eq 0) then begin

    ;===========================================================
    ;read data, and create tplot vars at each parameter:
    ;===========================================================
    ;Read the files:
    ;===============

    ;---Definition of time and parameters:
    Lat = 0
    Lon = 0
    Ref = 0
    Pres = 0
    Temp = 0

    ;==============
    ;Loop on files:
    ;==============
    for j=0L,n_elements(local_paths)-1 do begin
      file= local_paths[j]
      if file_test(/regular,file) then  dprint,'Loading the GPS-RO COSMIC FSI data: ',file $
      else begin
        dprint,'The GPS-RO cosmic FSI data ',file,' not found. Skipping'
        continue
      endelse

      cdfid = ncdf_open(file,/NOWRITE)  ; Open the file
      glob = ncdf_inquire( cdfid )    ; Find out general info

      ;---Show user the size of each dimension
      print,'Dimensions', glob.ndims
      for i=0L,glob.ndims-1 do begin
        ncdf_diminq, cdfid, i, name,size
        if i eq glob.recdim then  $
          print,'    ', name, size, '(Unlimited dim)' $
        else      $
          print,'    ', name, size
      endfor

      ;---Now tell user about the variables
      print
      print, 'Variables'
      for m=0L,glob.nvars-1 do begin

        ;---Get information about the variable
        info = ncdf_varinq(cdfid, m)
        FmtStr = '(A," (",A," ) Dimension Ids = [ ", 10(I0," "),$)'
        print, FORMAT=FmtStr, info.name,info.datatype, info.dim[*]
        print, ']'

        ;---Get attributes associated with the variable
        for l=0L,info.natts-1 do begin
          attname = ncdf_attname(cdfid,m,l)
          ncdf_attget,cdfid,m,attname,attvalue
          print,' Attribute ', attname, '=', string(attvalue)
          if info.name eq 'event' then begin
            if attname eq 'long_name' then long_name_lat = string(attvalue)
          endif
          if info.name eq 'z' then begin
            if attname eq 'units' then units_z = string(attvalue)
            if attname eq 'valid_range' then valid_range_z = float(attvalue)
            if attname eq 'long_name' then long_name_z = string(attvalue)
          endif
          if info.name eq 'gpsid' then begin
            if attname eq 'long_name' then long_name_gpsid = string(attvalue)
          endif
          if info.name eq 'leoid' then begin
            if attname eq 'long_name' then long_name_leoid = string(attvalue)
          endif
          if info.name eq 'time' then begin
            if attname eq 'units' then units_time = string(attvalue)
            if attname eq 'valid_range' then valid_range_time = float(attvalue)
            if attname eq 'long_name' then long_name_time = string(attvalue)
          endif
          if info.name eq 'lat' then begin
            if attname eq 'units' then units_lat = string(attvalue)
            if attname eq 'valid_range' then valid_range_lat = float(attvalue)
            if attname eq 'long_name' then long_name_lat = string(attvalue)
          endif
          if info.name eq 'lon' then begin
            if attname eq 'units' then units_Lon = string(attvalue)
            if attname eq 'valid_range' then valid_range_Lon = float(attvalue)
            if attname eq 'long_name' then long_name_Lon = string(attvalue)
          endif
          if info.name eq 'ref' then begin
            if attname eq 'units' then units_ref = string(attvalue)
            if attname eq 'valid_range' then valid_range_ref = float(attvalue)
            if attname eq 'long_name' then long_name_ref = string(attvalue)
          endif
          if info.name eq 'temp' then begin
            if attname eq 'units' then units_temp = string(attvalue)
            if attname eq 'valid_range' then valid_range_temp = float(attvalue)
            if attname eq 'long_name' then long_name_temp = string(attvalue)
          endif
          if info.name eq 'pres' then begin
            if attname eq 'units' then units_pres = string(attvalue)
            if attname eq 'valid_range' then valid_range_pres = float(attvalue)
            if attname eq 'long_name' then long_name_pres = string(attvalue)
          endif
          if info.name eq 'tan_lat' then begin
            if attname eq 'units' then units_tan_lat = string(attvalue)
            if attname eq 'valid_range' then valid_range_tan_lat = float(attvalue)
            if attname eq 'long_name' then long_name_tan_lat = string(attvalue)
          endif
          if info.name eq 'tan_lon' then begin
            if attname eq 'units' then units_tan_lon = string(attvalue)
            if attname eq 'valid_range' then valid_range_tan_lon = float(attvalue)
            if attname eq 'long_name' then long_name_tan_lon = string(attvalue)
          endif
        endfor
      endfor

      ;---Get the variable
      ncdf_varget, cdfid, 'event', event
      ncdf_varget, cdfid, 'z', height
      ncdf_varget, cdfid, 'gpsid', gpsid
      ncdf_varget, cdfid, 'leoid', leoid
      ncdf_varget, cdfid, 'time', time
      ncdf_varget, cdfid, 'lat', lat
      ncdf_varget, cdfid, 'lon', lon
      ncdf_varget, cdfid, 'ref', ref
      ncdf_varget, cdfid, 'pres', pres
      ncdf_varget, cdfid, 'temp', temp
      ncdf_varget, cdfid, 'tan_lat', tan_lat
      ncdf_varget, cdfid, 'tan_lon', tan_lon

      ;----Replace missing value of -999 by NaN:
      a = ref
      wbad = where(a eq -999,nbad)
      if nbad gt 0 then a[wbad] = !values.f_nan
      ref =a
      a = pres
      wbad = where(a eq -999,nbad)
      if nbad gt 0 then a[wbad] = !values.f_nan
      pres =a
      a = temp
      wbad = where(a le -200 or a ge 100.0,nbad)
      if nbad gt 0 then a[wbad] = !values.f_nan
      temp =a
      a = tan_lat
      wbad = where(a eq -999,nbad)
      if nbad gt 0 then a[wbad] = !values.f_nan
      tan_lat =a
      a = tan_lon
      wbad = where(a eq -999,nbad)
      if nbad gt 0 then a[wbad] = !values.f_nan
      tan_lon =a

     ;---Close netCDF file:
      ncdf_close,cdfid

     ;---Append the time and data:
      append_array,time_app, double(time)+time_double('1980-01-06/00:00:00')
      append_array,event_app, event
      append_array,gpsid_app, gpsid
      append_array,leoid_app, leoid
      append_array,lat_app, lat
      append_array,lon_app, lon
      append_array,ref_app, ref
      append_array,pres_app, pres
      append_array,temp_app, temp
      append_array,tan_lat_app, tan_lat
      append_array,tan_lon_app, tan_lon 
   endfor

  ;===============================
  ;====Store tplot variables======
  ;===============================
  ;---Acknowlegment string (use for creating tplot vars)
   acknowledgstring = 'If you acquire GPS radio occultation data, we ask that you acknowledge us in your use '$
      + 'of the data. This may be done by including text such as GPS radio occultation data provided by Research '$
      + 'Institute for Sustainable Humanosphere of Kyoto University. We would also appreciate receiving a copy of '$
      + 'the relevant publications. The distribution of GPS radio occultation data has been partly supported by '$
      + 'the IUGONET (Inter-university Upper atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '$
      + 'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'
  
   if size(event_app,/type) eq 4 then begin
      dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Tsuda'))
      store_data,'gps_ro_cosmic_fsi_event',data = {x:time_app, y:event_app},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_event', ytitle = 'Event number',spec=0
  
      store_data,'gps_ro_cosmic_fsi_gpsid',data = {x:time_app, y:gpsid_app},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_gpsid', ytitle = 'GPS satellite ID',spec=0
   
      store_data,'gps_ro_cosmic_fsi_leoid',data = {x:time_app, y:leoid_app},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_leoid', ytitle = 'LEO satellite ID',spec=0
   
      store_data,'gps_ro_cosmic_fsi_lat',data = {x:time_app, y:lat_app},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_lat', ytitle = 'Latitude [degree]',spec=0
   
      store_data,'gps_ro_cosmic_fsi_lon',data = {x:time_app, y:lon_app},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_lon', ytitle = 'Longitude [degree]',spec=0
   
      store_data,'gps_ro_cosmic_fsi_ref',data = {x:time_app, y:ref_app, v:height},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_ref', ytitle = 'Height [km]', ztitle = 'Refractivity [N]',spec=1,/noiso
   
      store_data,'gps_ro_cosmic_fsi_pres',data = {x:time_app, y:pres_app, v:height},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_pres', ytitle = 'Height [km]', ztitle = 'Dry air pressure [hPa]',spec=1,/noiso
   
      store_data,'gps_ro_cosmic_fsi_temp',data = {x:time_app, y:temp_app, v:height},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_temp', ytitle = 'Height [km]',ztitle = 'Dry air temperature [degree C]',spec=1,/noiso
   
      store_data,'gps_ro_cosmic_fsi_tan_lat',data = {x:time_app, y:tan_lat_app, v:height},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_tan_lat', ytitle = 'Height [km]',ztitle = 'Latitude of perigee point [degree]',spec=1,/noiso
   
      store_data,'gps_ro_cosmic_fsi_tan_lon',data = {x:time_app, y:tan_lon_app, v:height},dlimit=dlimit
      options, 'gps_ro_cosmic_fsi_tan_lon',ytitle = 'Height [km]', ztitle = 'Longitude of perigee point [degree]',spec=1,/noiso
  
     ;---Specify the height range of each parameter: 
      ylim,'gps_ro_cosmic_fsi_ref',0,40
      ylim,'gps_ro_cosmic_fsi_pres',0,40
      ylim,'gps_ro_cosmic_fsi_temp',0,40
      ylim,'gps_ro_cosmic_fsi_tan_lat',0,40
      ylim,'gps_ro_cosmic_fsi_tan_lon',0,40
  
     ;---Add tdegap
      tdegap,'gps_ro_cosmic_fsi_ref',/overwrite
      tdegap,'gps_ro_cosmic_fsi_pres',/overwrite
      tdegap,'gps_ro_cosmic_fsi_temp',/overwrite
      tdegap,'gps_ro_cosmic_fsi_tan_lat',/overwrite
      tdegap,'gps_ro_cosmic_fsi_tan_lon',/overwrite 
   endif
endif

;---Clear buffer:
time_app = 0
event_app = 0
gpsid_app = 0
leoid_app = 0
lat_app = 0
lon_app = 0
ref_app = 0
press_app = 0
temp_app = 0
tan_lat_app = 0
tan_lon_app = 0

end