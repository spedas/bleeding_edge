;+
;
;NAME:
;iug_load_mu_meso_wind_nc
;
;PURPOSE:
;  Queries the RISH servers for the 1-hour average wind data (netCDF format) of the 
;  mesosphere taken by the Middle and Upper atmosphere (MU) radar at Shigaraki 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_meso_wind_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  LEVEL = Observation data level. For example, iug_load_mu_wind_meso_nc, level = 'org'.
;            For example, iug_load_mu_meso_txt, parameter2 = 'scr'.
;            The default is 'all', i.e., load all available level data.           
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output. 
;  
;CODE:
; A. Shinbori, 21/07/2012.
;
;MODIFICATIONS:
; A. Shinbori, 12/11/2012.
; A. Shinbori, 24/12/2012.
; A. Shinbori, 24/01/2014.
;  
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-05-19 11:44:55 -0700 (Fri, 19 May 2017) $
; $LastChangedRevision: 23337 $
; $URL $
;-

pro iug_load_mu_meso_wind_nc, level = level, $
  downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

;***********************
;Verbose keyword check:
;***********************
if (not keyword_set(verbose)) then verbose=2

;*************
;Level check:
;*************
;--- all levels (default)
level_all = strsplit('org scr',' ', /extract)

;--- check level
if (not keyword_set(level)) then level='all'
levels = ssl_check_valid_name(level, level_all, /ignore_case, /include_all)

print, levels

;******************************************************************
;Loop on downloading files
;******************************************************************
;Get timespan, define FILE_NAMES, and load data:
;===============================================
;
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
for ii=0L,n_elements(levels)-1 do begin
   if ~size(fns,/type) then begin
     ;****************************
     ;Get files for ith component:
     ;****************************
      file_names = file_dailynames( $
      file_format='YYYY/YYYYMM/'+$
                  'YYYYMMDD',trange=trange,times=times,/unique)+'.wnd.nc'
                  
     ;===============================
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/sgk/mu/mesosphere/nc/'
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/mesosphere/data/netcdf/'
      
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
   
     ;===================================================
     ;read data, and create tplot vars at each parameter:
     ;===================================================
     ;Read the files:
     ;===============
   
     ;---Definition of time and parameters:
      mu_time = 0
      uwind = 0
      vwind = 0
      wwind = 0
      flag_uwind = 0
      flag_vwind = 0
      flag_wwind = 0
      
      ;==============
      ;Loop on files: 
      ;==============
      for j=0L,n_elements(local_paths)-1 do begin
         file= local_paths[j]
         if file_test(/regular,file) then  dprint,'Loading the mesosphere wind data taken by the MU radar: ',file $
         else begin
            dprint,'The mesosphere wind data taken by the MU radar ',file,' not found. Skipping'
            continue
         endelse
    
         cdfid = ncdf_open(file,/NOWRITE)  ; Open the file
         glob = ncdf_inquire(cdfid)    ; Find out general info

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

        ;---Get time infomation:
         time_info=strsplit(time_data,' ',/extract)
         syymmdd=time_info[2]
         shhmmss=time_info[3]
         time_diff=strsplit(time_info[4],':',/extract)
         time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60 
     
        ;---Get the variable
         ncdf_varget, cdfid, 'lat', lat
         ncdf_varget, cdfid, 'lon', lon
         ncdf_varget, cdfid, 'sealvl', sealvl
         ncdf_varget, cdfid, 'range', range
         ncdf_varget, cdfid, 'date', date
         ncdf_varget, cdfid, 'time', time
         ncdf_varget, cdfid, 'height_v', height_v
         ncdf_varget, cdfid, 'height_mz', height_mz
         ncdf_varget, cdfid, 'uwnd', uwnd
         ncdf_varget, cdfid, 'vwnd', vwnd
         ncdf_varget, cdfid, 'wwnd', wwnd
         ncdf_varget, cdfid, 'flg_uwnd', flg_uwnd
         ncdf_varget, cdfid, 'flg_vwnd', flg_vwnd
         ncdf_varget, cdfid, 'flg_wwnd', flg_wwnd

        ;---Get date information:
         year = fix(strmid(strtrim(string(date),1),0,4))
         month = fix(strmid(strtrim(string(date),1),4,2))
         day = fix(strmid(strtrim(string(date),1),6,2))
                           
        ;---Definition of arrary names
         unix_time = dblarr(n_elements(time))
         
         for i=0L, n_elements(time)-1 do begin
           ;---Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)    
            unix_time[i] = double(time[i]) +time_double(syymmdd+'/'+shhmmss)-time_diff2
                               
            for k=0L, n_elements(range)-1 do begin
               if (uwnd[i,k] eq 999.0) then uwnd[i,k] = !values.f_nan
               if (vwnd[i,k] eq 999.0) then vwnd[i,k] = !values.f_nan
               if (wwnd[i,k] eq 999.0) then wwnd[i,k] = !values.f_nan  
               
               if levels[ii] eq 'org' then flg=2                               
               if levels[ii] eq 'scr' then flg=1
               a = flg_uwnd[i,k]            
               if (a ge flg) then uwnd[i,k] = !values.f_nan
               b = flg_vwnd[i,k]           
               if (b ge flg) then vwnd[i,k] = !values.f_nan         
               d = flg_wwnd[i,k]          
               if (d ge flg) then wwnd[i,k] = !values.f_nan              
            endfor
         endfor
         
        ;==============================
        ;Append array of time and data:
        ;==============================
         append_array, mu_time, unix_time
         append_array, mu_uwnd, uwnd
         append_array, mu_vwnd, vwnd
         append_array, mu_wwnd, wwnd
         ncdf_close,cdfid  ; done  
      endfor

      if n_elements(mu_time) gt 1 then begin
    
        ;==============================
        ;Store data in TPLOT variables:
        ;==============================      
        ;---Acknowlegment string (use for creating tplot vars):
         acknowledgstring = 'If you acquire the middle and upper atmospher (MU) radar data, '+ $
                            'we ask that you acknowledge us in your use of the data. This may be done by '+ $
                            'including text such as the MU data provided by Research Institute '+ $
                            'for Sustainable Humanosphere of Kyoto University. We would also '+ $
                            'appreciate receiving a copy of the relevant publications. '+ $
                            'The distribution of MU radar data has been partly supported by the IUGONET '+ $
                            '(Inter-university Upper atmosphere Global Observation NETwork) project '+ $
                            '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, '+ $
                            'Sports, Science and Technology (MEXT), Japan.'

         if size(mu_uwnd,/type) eq 4 then begin
           ;---Create tplot variable for zonal wind:
            dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Nakamura'))                          
            store_data, 'iug_mu_meso_uwnd_'+levels[ii],data={x:mu_time,y:mu_uwnd,v:height_mz},dlimit=dlimit
            
           ;---Add options:
            new_vars=tnames('iug_mu_meso_uwnd*')
            if new_vars[0] ne '' then begin
                  options,'iug_mu_meso_uwnd*', 'spec',1
                  options,'iug_mu_meso_uwnd*', ytitle='MUR-meso!CHeight!C[km]',ztitle='Zonal wind!C[m/s]'  
            endif
            
           ;---Create tplot variable for meridional wind:
            store_data, 'iug_mu_meso_vwnd_'+levels[ii],data={x:mu_time,y:mu_vwnd,v:height_mz},dlimit=dlimit
           
           ;---Add options:
            new_vars=tnames('iug_mu_meso_vwnd*')
            if new_vars[0] ne '' then begin
                  options,'iug_mu_meso_vwnd*', 'spec',1
                  options,'iug_mu_meso_vwnd*', ytitle='MUR-meso!CHeight!C[km]',ztitle='Meridional wind!C[m/s]' 
            endif
            
           ;---Create tplot variable for vertical wind:
            store_data, 'iug_mu_meso_wwnd_'+levels[ii],data={x:mu_time,y:mu_wwnd,v:height_v},dlimit=dlimit
           
           ;---Add options:
            new_vars=tnames('iug_mu_meso_wwnd*')
            if new_vars[0] ne '' then begin
                  options,'iug_mu_meso_wwnd*', 'spec',1
                  options,'iug_mu_meso_wwnd*', ytitle='MUR-meso!CHeight!C[km]',ztitle='Vertical wind!C[m/s]' 
            endif
           
           ;---Add tdegap:
            new_vars=tnames('iug_mu_meso_*')
            if new_vars[0] ne '' then begin
               tdegap,'iug_mu_meso_*',/overwrite
            endif 
            
           ;---Add ylim:
            new_vars=tnames('iug_mu_meso_*')
            if new_vars[0] ne '' then begin
               ylim,'iug_mu_meso_*',60,100
            endif                  
         endif    
         new_vars=tnames('iug_mu_meso_*')
         if new_vars[0] ne '' then begin    
            print,'******************************
            print,'Data loading is successful!!'
            print,'******************************
         endif
      endif
   endif

  ;---Clear time and data buffer:
   mu_time = 0
   mu_uwnd = 0
   mu_vwnd = 0
   mu_wwnd = 0
   
endfor      
;*************************
;Print of acknowledgement:
;*************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire the middle and upper atmosphere (MU) radar data,'
print, 'we ask that you acknowledge us in your use of the data.' 
print, 'This may be done by including text such as MU data provided' 
print, 'by Research Institute for Sustainable Humanosphere of Kyoto University.' 
print, 'We would also appreciate receiving a copy of the relevant publications.'
print, 'The distribution of MU radar data has been partly supported by the IUGONET'
print, '(Inter-university Upper atmosphere Global Observation NETwork) project'
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture,'
print, 'Sports, Science and Technology (MEXT), Japan.' 
        
end

