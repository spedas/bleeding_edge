;+
;
;NAME:
; iug_load_mu_meso_nc
;
;PURPOSE:
;  Queries the RISH servers for the standard observation data (netCDF format) of the 
;  mesosphere taken by the Middle and Upper atmosphere (MU) radar at Shigaraki 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_meso_nc, level=level, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:.
;  LEVEL = Observation data level. For example, iug_load_mu_meso_nc, level = 'org'.
;            The default is 'scr'.
;            When you set the level of 'org', the original data are stored in tplot variables.
;            When you set the level of 'scr', the screening data are stored in tplot variables.            
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
;  
;CODE:
; A. Shinbori, 14/07/2012.
;
;MODIFICATIONS:
; A. Shinbori, 12/11/2012.
; A. Shinbori, 24/12/2012.
; A. Shinbori, 24/01/2014.
; A. Shinbori, 09/08/2017.
; A. Shinbori, 30/11/2017.
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_mu_meso_nc, level = level, $
  downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2

;***********************
;Keyword check (trange):
;***********************
if not keyword_set(trange) then begin
  get_timespan, time_org
endif else begin
  time_org =time_double(trange)
endelse

;************
;Level check:
;************
;--- all levels (default)
level_all = strsplit('org scr',' ', /extract)

;--- check level
if (not keyword_set(level)) then level='all'
levels = ssl_check_valid_name(level, level_all, /ignore_case, /include_all)

print, levels

;**************************
;Loop on downloading files:
;**************************
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
for ii=0L, n_elements(levels)-1 do begin
  ;==============================================================
  ;Change time window associated with a time shift from UT to LT:
  ;==============================================================
   day_org = (time_org[1] - time_org[0])/86400.d
   day_mod = day_org + 1
   timespan, time_org[0] - 3600.0d * 9.0d, day_mod
   if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) + 9.0d * 3600.0d); for GUI
   
   if ~size(fns,/type) then begin
     ;****************************
     ;Get files for ith component:
     ;****************************
      file_names = file_dailynames( $
      file_format='YYYY/YYYYMM/'+$
                  'YYYYMMDD',trange=trange,times=times,/unique)+'.nc'
                  
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
      ;==============
      ;Loop on files: 
      ;==============
      for j=0L,n_elements(local_paths)-1 do begin
         file= local_paths[j]
         if file_test(/regular,file) then  dprint,'Loading the mesosphere observation data taken by the MU radar: ',file $
         else begin
            dprint,'The mesosphere observation data taken by the MU radar ',file,' not found. Skipping'
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

        ;---Get time information:
         time_info=strsplit(time_data,' ',/extract)
         syymmdd=time_info[2]
         shhmmss=time_info[3]
         time_diff=strsplit(time_info[4],':',/extract)
         time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60 
     
        ;---Get the variable
         ncdf_varget, cdfid, 'lat', lat
         ncdf_varget, cdfid, 'lon', lon
         ncdf_varget, cdfid, 'sealvl', sealvl
         ncdf_varget, cdfid, 'bmwdh', bmwdh
         ncdf_varget, cdfid, 'beam', beam
         ncdf_varget, cdfid, 'range', range
         ncdf_varget, cdfid, 'az', az
         ncdf_varget, cdfid, 'ze', ze
         ncdf_varget, cdfid, 'date', date
         ncdf_varget, cdfid, 'time', time
         ncdf_varget, cdfid, 'height_v', height_v
         ncdf_varget, cdfid, 'height_mz', height_mz
         ncdf_varget, cdfid, 'pwr', pwr
         ncdf_varget, cdfid, 'wdt', wdt
         ncdf_varget, cdfid, 'dpl', dpl
         ncdf_varget, cdfid, 'if_cond', if_cond
         ncdf_varget, cdfid, 'pnoise', pnoise

        ;---Get date information:
         year = fix(strmid(strtrim(string(date),1),0,4))
         month = fix(strmid(strtrim(string(date),1),4,2))
         day = fix(strmid(strtrim(string(date),1),6,2))
                           
        ;---Definition of arrary names
         unix_time = dblarr(n_elements(time))
         pwr1_mu=fltarr(n_elements(time),n_elements(range),n_elements(beam))
         wdt1_mu=fltarr(n_elements(time),n_elements(range),n_elements(beam))
         dpl1_mu=fltarr(n_elements(time),n_elements(range),n_elements(beam))
         if_cond_mu=lonarr(n_elements(time),n_elements(range),n_elements(beam))
         pnoise1_mu=fltarr(n_elements(time),n_elements(beam)) 
    
         for i=0L, n_elements(time)-1 do begin
           ;---Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)    
            unix_time[i] = double(time[i]) +time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+'00:00:00')-time_diff2
           
           ;---Replace missing value by NaN:                    
            for k=0L, n_elements(range)-1 do begin                       
               for l=0L, n_elements(beam)-1 do begin           
                  a = if_cond[i,k,l]
                  if levels[ii] eq 'scr' then begin            
                     if a gt 4 then begin
                        pwr[i,k,l] = !values.f_nan
                        wdt[i,k,l] = !values.f_nan 
                        dpl[i,k,l] = !values.f_nan           
                     endif
                  endif
                  pwr1_mu[i,k,l]=pwr[i,k,l]
                  wdt1_mu[i,k,l]=wdt[i,k,l]
                  dpl1_mu[i,k,l]=dpl[i,k,l]
                  pnoise1_mu[i,l]=pnoise[i,l]
               endfor 
            endfor
         endfor
    
        ;==============================
        ;Append array of time and data:
        ;==============================
         append_array, mu_time, unix_time
         append_array, pwr1, pwr1_mu
         append_array, wdt1, wdt1_mu
         append_array, dpl1, dpl1_mu
         append_array, pn1, pnoise1_mu

         ncdf_close,cdfid  ; done  
      endfor

     ;==============================================================
     ;Change time window associated with a time shift from UT to LT:
     ;==============================================================
      timespan, time_org
      get_timespan, init_time2
      if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) - 9.0d * 3600.0d); for GUI
      
      if n_elements(mu_time) gt 1 then begin
        ;---Definition of arrary names
         height = fltarr(n_elements(range),n_elements(beam))
         bname2=strarr(n_elements(beam))
         bname=strarr(n_elements(beam))
         pwr2_mu=fltarr(n_elements(mu_time),n_elements(range))
         wdt2_mu=fltarr(n_elements(mu_time),n_elements(range))
         dpl2_mu=fltarr(n_elements(mu_time),n_elements(range))
         pnoise2_mu=fltarr(n_elements(mu_time)) 
         
         height[*,0] = height_v
         height[*,1] = height_mz
         height[*,2] = height_mz
         height[*,3] = height_mz
         height[*,4] = height_mz
    
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

         if size(dpl1,/type) eq 4 then begin
           ;---Create tplot variable for echo power, spectral width, Doppler velocity and niose level:
            dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Nakamura'))                          
            for l=0L, n_elements(beam)-1 do begin
               bname2[l]=string(beam[l]+1)
               bname[l]=strsplit(bname2[l],' ', /extract)
               for i=0L, n_elements(mu_time)-1 do begin
                  for k=0L, n_elements(range)-1 do begin
                     pwr2_mu[i,k]=pwr1[i,k,l]
                  endfor
               endfor
               
              ;---Create tplot variable for echo power (beam 1-5): 
               store_data,'iug_mu_meso_pwr'+bname[l]+'_'+levels[ii],data={x:mu_time, y:pwr2_mu, v:height[*,l]},dlimit=dlimit

              ;----Edge data cut:
               time_clip,'iug_mu_meso_pwr'+bname[l]+'_'+levels[ii], init_time2[0], init_time2[1], newname = 'iug_mu_meso_pwr'+bname[l]+'_'+levels[ii]
                             
              ;---Add options;
               new_vars=tnames('iug_mu_meso_pwr*')
               if new_vars[0] ne '' then begin
                  options,'iug_mu_meso_pwr'+bname[l]+'_'+levels[ii],ytitle='MUR-meso!CHeight!C[km]',ztitle='pwr'+bname[l]+'-'+levels[ii]+'!C[dB]'
                  options, 'iug_mu_meso_pwr'+bname[l]+'_'+levels[ii],'spec',1
               endif            
               for i=0L, n_elements(mu_time)-1 do begin
                  for k=0L, n_elements(range)-1 do begin
                     wdt2_mu[i,k]=wdt1[i,k,l]
                  endfor
               endfor
               
              ;---Create tplot variable for spectral width (beam 1-5):
               store_data,'iug_mu_meso_wdt'+bname[l]+'_'+levels[ii],data={x:mu_time, y:wdt2_mu, v:height[*,l]},dlimit=dlimit

              ;----Edge data cut:
               time_clip,'iug_mu_meso_wdt'+bname[l]+'_'+levels[ii], init_time2[0], init_time2[1], newname = 'iug_mu_meso_wdt'+bname[l]+'_'+levels[ii]
               
              ;---Add options;
               new_vars=tnames('iug_mu_meso_wdt*')
               if new_vars[0] ne '' then begin
                  options,'iug_mu_meso_wdt'+bname[l]+'_'+levels[ii],ytitle='MUR-meso!CHeight!C[km]',ztitle='wdt'+bname[l]+'-'+levels[ii]+'!C[m/s]'
                  options, 'iug_mu_meso_wdt'+bname[l]+'_'+levels[ii],'spec',1
               endif
               for i=0L, n_elements(mu_time)-1 do begin
                  for k=0L, n_elements(range)-1 do begin
                     dpl2_mu[i,k]=dpl1[i,k,l]
                  endfor
               endfor  
               
              ;---Create tplot variable for Doppler velocity (beam 1-5):            
               store_data,'iug_mu_meso_dpl'+bname[l]+'_'+levels[ii],data={x:mu_time, y:dpl2_mu, v:height[*,l]},dlimit=dlimit

              ;----Edge data cut:
               time_clip,'iug_mu_meso_dpl'+bname[l]+'_'+levels[ii], init_time2[0], init_time2[1], newname = 'iug_mu_meso_dpl'+bname[l]+'_'+levels[ii]
              
              ;---Add options; 
               new_vars=tnames('iug_mu_meso_dpl*')
               if new_vars[0] ne '' then begin
                  options,'iug_mu_meso_dpl'+bname[l]+'_'+levels[ii],ytitle='MUR-meso!CHeight!C[km]',ztitle='dpl'+bname[l]+'-'+levels[ii]+'!C[m/s]'
                  options, 'iug_mu_meso_dpl'+bname[l]+'_'+levels[ii],'spec',1
               endif
               for i=0L, n_elements(mu_time)-1 do begin
                  pnoise2_mu[i]=pn1[i,l]
               endfor
               
              ;---Create tplot variable for noise level (beam 1-5):
               store_data,'iug_mu_meso_pn'+bname[l]+'_'+levels[ii],data={x:mu_time, y:pnoise2_mu},dlimit=dlimit

              ;----Edge data cut:
               time_clip,'iug_mu_meso_pn'+bname[l]+'_'+levels[ii], init_time2[0], init_time2[1], newname = 'iug_mu_meso_pn'+bname[l]+'_'+levels[ii]
              
              ;---Add options;
               new_vars=tnames('iug_mu_meso_pn*')
               if new_vars[0] ne '' then begin
                  options,'iug_mu_meso_pn'+bname[l]+'_'+levels[ii],ytitle='MUR-meso!Cpn'+bname[l]+'!C[dB]' 
               endif                 
            endfor
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
   mu_time=0
   pwr1 = 0
   wdt1 = 0
   dpl1 = 0
   pn1 = 0
   pwr2_mu = 0
   wdt2_mu = 0
   dpl2_mu = 0
   pnoise2_mu = 0

   ;---Initialization of timespan for parameters:
   timespan, time_org

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

