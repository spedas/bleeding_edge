;+
;
;NAME:
;iug_load_gps_atec
;
;PURPOSE:
;  Queries the ISEE servers for the absolute value of GPS TEC (Total Electron Content) data
;  provided from ISEE and and loads data into tplot format.
;
;SYNTAX:
;iug_load_gps_atec_isee, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
;CODE:
; A. Shinbori, 01/10/2021.
;
;MODIFICATIONS:
; A. Shinbori, 06/10/2021.
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL $
;-


pro iug_load_gps_atec, downloadonly=downloadonly, trange = trange, verbose = verbose

  ;*****************************
  ;***Keyword check (verbose)***
  ;*****************************
   if not keyword_set(verbose) then verbose = 2

   if ~size(fns,/type) then begin
     ;****************************
     ;Get files for ith component:
     ;****************************
      file_names = file_dailynames(file_format = 'YYYY/DOY/YYYYMMDDhh',trange = trange,times = times,hour = 1, /unique)+'_atec.nc'

     ;===============================
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose = verbose
      source.local_data_dir = root_data_dir() + 'iugonet/isee/gps/AGRID2/nc/'
      source.remote_data_dir = 'https://stdb2.isee.nagoya-u.ac.jp/GPS/shinbori/AGRID2/nc/'

     ;=======================================================
     ;Get files and local paths, and concatenate local paths:
     ;=======================================================
      local_paths = spd_download(remote_file=file_names, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)
      local_paths_all = ~(~size(local_paths_all,/type)) ? $
                        [local_paths_all, local_paths] : local_paths
      if ~(~size(local_paths_all,/type)) then local_paths=local_paths_all
   endif else file_names=fns

   if (not keyword_set(downloadonly)) then downloadonly = 0

   if (downloadonly eq 0) then begin
  
      for j=0L,n_elements(local_paths)-1 do begin
         file= local_paths[j]
         if file_test(/regular,file) then  dprint,'Loading GPS-ATEC file: ',file $
         else begin
            dprint,'GPS-ATEC file ',file,' not found. Skipping'
            continue
         endelse
    
         cdfid = ncdf_open(file,/NOWRITE)  ; Open the file
         glob = ncdf_inquire( cdfid )    ; Find out general info

        ;---Show user the size of each dimension
         print,'Dimensions', glob.ndims
         for i=0L,glob.ndims-1 do begin
            ncdf_diminq, cdfid, i, name,size
            if i EQ glob.recdim then  $
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
               if (info.name eq 'time') and (attname eq 'units') then time_data=string(attvalue)
            endfor
         endfor
 
        ;---Get the start time infomation from the attribute data:
         time_info=strsplit(time_data,' ',/extract)
         syymmdd=time_info[2]
         shhmmss=time_info[3]
         time_diff=strsplit(time_info[4],':',/extract)
         time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60 
    
        ;---Get the variable
         ncdf_varget, cdfid, 'time', time
         ncdf_varget, cdfid, 'lat', latitude
         ncdf_varget, cdfid, 'lon', longitude
         ncdf_varget, cdfid, 'atec', atec
    
        ;---Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)      
         unix_time = double(time) +time_double(string(syymmdd)+'/'+string(shhmmss))-double(time_diff2)

        ;---Replace missing value by NaN:             
         wbad = where(atec eq 999.0,nbad)
         if nbad gt 0 then atec[wbad] = !values.f_nan

        ;==============================
        ;=======Append array of time and data:
        ;==============================
         append_array, unix_time_app, unix_time
         append_array, atec_app, atec
 
        ;---Close netCDF file:
         ncdf_close, cdfid

      endfor
      ;==============================
      ;Store data in TPLOT variables:
      ;==============================
      ;---Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'Note: If you would like to use following data for scientific purpose,'+$
                         'please read and follow the DATA USE POLICY (https://stdb2.isee.nagoya-u.ac.jp/GPS/GPS-TEC/index.html)'+$
                         'The distribution of GPS-TEC data has been partly supported by the IUGONET'+$
                         '(Inter-university Upper atmosphere Global Observation NETwork) project'+$
                         '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, Sports, Science'+$
                         'and Technology (MEXT), Japan.'

      if size(atec_app,/type) eq 4 then begin
        ;---Create tplot variables and options for zonal wind:
        dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'Y. Otsuka'))
        store_data, 'iug_gps_atec', data = {x:unix_time_app,y:atec_app,glat:latitude,glon:longitude},dlimit=dlimit
        options, 'iug_gps_atec', ztitle = 'TEC [10!U16!N/m!U2!N]'
      endif
   endif
   new_vars=tnames('iug_gps_atec')
   if new_vars[0] ne '' then begin
     print,'******************************
     print, 'Data loading is successful!!'
     print,'******************************
   endif

   ;*************************
   ;Print of acknowledgement:
   ;*************************
   print, '****************************************************************
   print, 'Acknowledgement'
   print, '****************************************************************
   print, 'Note: If you would like to use following data for scientific purpose,
   print, 'please read and follow the DATA USE POLICY (https://stdb2.isee.nagoya-u.ac.jp/GPS/GPS-TEC/index.html)'
   print, 'The distribution of GPS-TEC data has been partly supported by the IUGONET'
   print, '(Inter-university Upper atmosphere Global Observation NETwork) project'
   print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, Sports, Science'
   print, 'and Technology (MEXT), Japan.'
 end