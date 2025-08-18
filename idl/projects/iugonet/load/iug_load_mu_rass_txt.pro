;+
;
;NAME:
;iug_load_mu_rass_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the special observation data of the 
;  RASS in the CSV format taken by the Middle and 
;  Upper atmosphere (MU) radar at Shigaraki and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_rass_txt, parameter=parameter, $
;                        downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  PARAMETER = parameter name of MU troposphere standard obervation data.  
;          For example, iug_load_mu_trop_txt, parameter = 'uwnd'.
;          The default is 'all', i.e., load all available parameters.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
;CODE:
; A. Shinbori, 22/06/2013.
;
;MODIFICATIONS:
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

pro iug_load_mu_rass_txt, parameter=parameter, $
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

;***********
;parameters:
;***********
;--- all parameters (default)
parameter_all = strsplit('uwnd vwnd wwnd temp',' ', /extract)

;--- check site codes
if(not keyword_set(parameter)) then parameter='all'
parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters

;*****************
;Defition of unit:
;*****************
;--- all units (default)
unit_all = strsplit('m/s degree',' ', /extract)

;**************************
;Loop on downloading files:
;**************************
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
;Definition of parameter:
jj=0L
for ii=0L,n_elements(parameters)-1 do begin
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
      file_format='YYYY/YYYYMMDD/YYYYMMDD',trange=trange,times=times,/unique)+'.'+parameters[ii]+'.csv'
     
     ;===============================
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/mu/rass/csv/'
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/rass/data/csv/'
    
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
     ;Loop on read data, and create tplot vars at each parameter
     ;===========================================================
     ;Read the files:
     ;===============
   
     ;---Definition of string variable:
      s=''

     ;---Initialize data and time buffer
      mu_time=0
      mu_data=0
     
     ;============= 
     ;Loop on files: 
     ;==============
      for h=jj,n_elements(local_paths)-1 do begin
         file= local_paths[h]
         if file_test(/regular,file) then  dprint,'Loading MU file: ',file $
         else begin
            dprint,'MU file',file,'not found. Skipping'
            continue
         endelse
          
        ;---Open read file:    
         openr,lun,file,/get_lun    
         
        ;=============================
        ;Read information of altitude:
        ;=============================
         readf, lun, s
    
        ;---Definition of altitude and data arraies:
         h_data = strsplit(s,',',/extract)     
         altitude = fltarr(n_elements(h_data)-1)
    
        ;---Enter the altitude information:
         for j=0L,n_elements(h_data)-2 do begin
            altitude[j] = float(h_data[j+1])
         endfor
                  
        ;==================
        ;Loop on read data:
        ;==================
         while(not eof(lun)) do begin
            readf,lun,s
            ok=1
            if strmid(s,0,1) eq '[' then ok=0
            if ok && keyword_set(s) then begin
               dprint,s ,dlevel=5
               data = strsplit(s,',',/extract)
               data2 = fltarr(1,n_elements(data)-1)
               
              ;---Get date and time information:
               u=strsplit(data[0],' ',/extract)
               date=strsplit(u[0],'-',/extract)
               year = date[2]
               month = date[1]
               day = date[0]
               if month eq 'JAN' then month ='01'
               if month eq 'FEB' then month ='02'
               if month eq 'MAR' then month ='03'
               if month eq 'APR' then month ='04'
               if month eq 'MAY' then month ='05'
               if month eq 'JUN' then month ='06'
               if month eq 'JUL' then month ='07'
               if month eq 'AUG' then month ='08'
               if month eq 'SEP' then month ='09'
               if month eq 'OCT' then month ='10'
               if month eq 'NOV' then month ='11'
               if month eq 'DEC' then month ='12' 
                
              ;---Convert time from local time to unix time      
               time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+u[1]) - double(9) * 3600.0d
              
              ;---Replace missing value by NaN:
               for j=0L,n_elements(h_data)-2 do begin
                  a = float(data[j+1])
                  wbad = where(a eq 999,nbad)
                  if nbad gt 0 then a[wbad] = !values.f_nan
                  data2[0,j]=a
               endfor
               
              ;==============================
              ;Append array of time and data:
              ;==============================
               append_array, mu_time, time
               append_array, mu_data, data2
            endif
         endwhile 
         free_lun,lun  
      endfor

     ;==============================================================
     ;Change time window associated with a time shift from UT to LT:
     ;==============================================================
      timespan, time_org
      get_timespan, init_time2
      if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) - 9.0d * 3600.0d); for GUI
     ;==============================
     ;Store data in TPLOT variables:
     ;==============================
     ;---Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'If you acquire the middle and upper atmospher (MU) radar data, ' $
                       + 'we ask that you acknowledge us in your use of the data. This may be done by ' $
                       + 'including text such as the MU data provided by Research Institute ' $
                       + 'for Sustainable Humanosphere of Kyoto University. We would also ' $
                       + 'appreciate receiving a copy of the relevant publications. '$
                       + 'The distribution of MU radar data has been partly supported by the IUGONET '$
                       + '(Inter-university Upper atmosphere Global Observation NETwork) project '$
                       + '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, '$
                       + 'Sports, Science and Technology (MEXT), Japan.'
       o=0
       if size(mu_data,/type) eq 4 then begin
          if strmid(parameters[ii],0,4) eq 'temp' then o=1
         
         ;---Create tplot variables for each parameter:
          dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'J. Furumoto'))
          store_data,'iug_mu_rass_'+parameters[ii],data={x:mu_time, y:mu_data, v:altitude/1000.0},dlimit=dlimit

         ;----Edge data cut:
          time_clip,'iug_mu_rass_'+parameters[ii], init_time2[0], init_time2[1], newname = 'iug_mu_rass_'+parameters[ii]
         
         ;---Add options:
          new_vars=tnames('iug_mu_rass_*')
          if new_vars[0] ne '' then begin          
             options,'iug_mu_rass_'+parameters[ii],ytitle='MU-rass!CHeight!C[km]',ztitle=parameters[ii]+'!C['+unit_all[o]+']'
             options,'iug_mu_rass_'+parameters[ii], labels='MU-rass [km]'
          endif
       endif   
      
      ;---Add options:
       new_vars=tnames('iug_mu_rass_*')
       if new_vars[0] ne '' then options, 'iug_mu_rass_'+parameters[ii], 'spec', 1
    
      ;Clear time and data buffer:
       mu_time=0
       mu_data=0
       
      ;Add tdegap
       if new_vars[0] ne '' then tdegap, 'iug_mu_rass_'+parameters[ii],dt=600, /overwrite
   endif
 
  jj=n_elements(local_paths)
 ;---Initialization of timespan for parameters:
  timespan, time_org
endfor

new_vars=tnames('iug_mu_rass_*')
if new_vars[0] ne '' then begin
   print,'*****************************
   print,'Data loading is successful!!'
   print,'*****************************
endif

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

