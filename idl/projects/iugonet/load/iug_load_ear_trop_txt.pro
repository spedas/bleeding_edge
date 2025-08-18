;+
;
;NAME:
;iug_load_ear_trop_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the standard observation data of troposphere and stratsoohere
;  in the CSV format taken by the equatorial atmosphere radar (EAR)and loads data into
;  tplot format.
;
;SYNTAX:
; iug_load_ear_trop_txt, parameter=parameter, $
;                        downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS: 
;  PARAMETER = parameter name of EAR troposphere standard obervation data.  
;          For example, iug_load_ear_trop_txt, parameter = 'uwnd'.
;          The default is 'all', i.e., load all available parameters.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE (In): [1,...,5], Get more detailed (higher number) command line output.
;  
;CODE:
; A. Shinbori, 19/09/2010.
;
;MODIFICATIONS:
; A. Shinbori, 24/03/2011.
; A. Shinbori, 13/11/2011.
; A. Shinbori, 26/12/2011.
; A. Shinbori, 31/01/2011.
; A. Shinbori, 18/12/2011.
; A. Shinbori, 24/01/2014.
; A. Shinbori, 08/08/2017.
; A. Shinbori, 30/11/2017.
;   
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_ear_trop_txt, parameter=parameter, $
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
parameter_all = strsplit('uwnd vwnd wwnd pwr1 pwr2 pwr3 pwr4 pwr5 wdt1 wdt2 wdt3 wdt4 wdt5',' ', /extract)

;--- check site codes
if(not keyword_set(parameter)) then parameter='all'
parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters

;*****************
;Defition of unit:
;*****************
;--- all units (default)
unit_all = strsplit('m/s dB',' ', /extract)

;**************************
;Loop on downloading files:
;**************************
jj=0L
for ii=0L,n_elements(parameters)-1 do begin

  ;==============================================================
  ;Change time window associated with a time shift from UT to LT:
  ;==============================================================
   day_org = (time_org[1] - time_org[0])/86400.d
   day_mod = day_org + 1
   timespan, time_org[0] - 3600.0d * 7.0d, day_mod
   if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) + 7.0d * 3600.0d); for GUI
   
   if ~size(fns,/type) then begin
     ;****************************
     ;Get files for ith component:
     ;****************************
      file_names = file_dailynames( $
      file_format='YYYYMM/YYYYMMDD/'+$
                   'YYYYMMDD',trange=trange,times=times,/unique)+'.'+parameters[ii]+'.csv'
     
     ;===============================
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/ktb/ear/troposphere/csv/'
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/ear/data/data/ver02.0212/'
    
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

     ;---Definition of string variable:
      s=''

     ;==============  
     ;Loop on files: 
     ;==============
      for h=jj,n_elements(local_paths)-1 do begin
         file= local_paths[h]
         if file_test(/regular,file) then  dprint,'Loading EAR file: ',file $
         else begin
            dprint,'EAR file ',file,' not found. Skipping'
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
        
        ;=================
        ;Loop on readdata:
        ;=================
         while(not eof(lun)) do begin
            readf,lun,s
            ok=1
            if strmid(s,0,1) eq '[' then ok=0
            if ok && keyword_set(s) then begin
               dprint,s ,dlevel=5
               data = strsplit(s,',',/extract)
               data2 = fltarr(1,n_elements(data)-1)
                
              ;---Get date and time information:
               year = strmid(data[0],0,4)
               month = strmid(data[0],5,2)
               day = strmid(data[0],8,2)
               hour = strmid(data[0],11,2)
               minute = strmid(data[0],14,2) 
                 
              ;---Convert time from local time to universal time      
               time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+string(hour)+':'+string(minute)) - 7.0d * 3600.0d
              
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
               append_array, ear_time, time
               append_array, ear_data, data2
            endif
         endwhile 
         free_lun,lun  
      endfor

     ;==============================================================
     ;Change time window associated with a time shift from UT to LT:
     ;==============================================================
      timespan, time_org
      get_timespan, init_time2
      if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) - 7.0d * 3600.0d); for GUI
      
     ;==============================
     ;Store data in TPLOT variables:
     ;==============================
     ;---Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'The Equatorial Atmosphere Radar belongs to Research Institute for ' $
                       + 'Sustainable Humanosphere (RISH), Kyoto University and is operated by ' $
                       + 'RISH and National Institute of Aeronautics and Space (LAPAN) Indonesia. ' $
                       + 'Distribution of the data has been partly supported by the IUGONET ' $
                       + '(Inter-university Upper atmosphere Global Observation NETwork) project ' $
                       + '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, ' $
                       + 'Sports, Science and Technology (MEXT), Japan.'
      o=0
      if size(ear_data,/type) eq 4 then begin 
         if strmid(parameters[ii],0,2) eq 'pw' then o=1
        ;---Creat tplot variable for selected parameter:
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'H. Hashiguchi'))
         store_data,'iug_ear_trop_'+parameters[ii],data={x:ear_time, y:ear_data, v:altitude},dlimit=dlimit

         ;----Edge data cut:
         time_clip, 'iug_ear_trop_'+parameters[ii], init_time2[0], init_time2[1], newname = 'iug_ear_trop_'+parameters[ii]
        
        ;---Add options:
         new_vars=tnames('iug_ear_trop_'+parameters[ii])
         if new_vars[0] ne '' then begin          
            options,'iug_ear_trop_'+parameters[ii],ytitle='EAR-trop!CHeight!C[km]',ztitle=parameters[ii]+'!C['+unit_all[o]+']'       
            options, 'iug_ear_trop_'+parameters[ii], 'spec', 1
         endif
      endif   
    
     ;---Clear time and data buffer:
      ear_time=0
      ear_data=0
     
     ;---Add tdegap
      new_vars=tnames('iug_ear_trop_'+parameters[ii])
      if new_vars[0] ne '' then begin      
         tdegap, 'iug_ear_trop_'+parameters[ii],/overwrite
      endif
   endif
   jj=n_elements(local_paths)
  ;---Initialization of timespan for parameters-1:
   timespan, time_org
endfor

new_vars=tnames('iug_ear_trop_*')
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
print, 'The Equatorial Atmosphere Radar belongs to Research Institute for '
print, 'Sustainable Humanosphere (RISH), Kyoto University and is operated by '
print, 'RISH and National Institute of Aeronautics and Space (LAPAN) Indonesia. '
print, 'Distribution of the data has been partly supported by the IUGONET '
print, '(Inter-university Upper atmosphere Global Observation NETwork) project '
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, '
print, 'Sports, Science and Technology (MEXT), Japan.'

end

