;+
;
;NAME:
;iug_load_ear_iono_fr_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the FAI observation data in the CSV format 
;  taken by the equatorial atmosphere radar (EAR) and loads data into
;  tplot format.
;
;SYNTAX:
; iug_load_ear_iono_fr_txt, parameter1=parameter1, parameter2=parameter2 $
;                           downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  PARAMETER1 = first parameter name of EAR FAI obervation data.  
;          For example, iug_load_ear_iono_fr_txt, parameter1 = 'fb1p16a'.
;          The default is 'all', i.e., load all available parameters.
;  PARAMETER2 = second parameter name of EAR FAI obervation data.  
;          For example, iug_load_ear_iono_fr_txt, parameter2 = 'dpl1'.
;          The default is 'all', i.e., load all available parameters.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE (In): [1,...,5], Get more detailed (higher number) command line output.
;  
;DATA AVAILABILITY:
;  Please check the following homepage of the time schedule of field-aligned irregularity (FAI) observation 
;  before you analyze the FAI data using this software. 
;  http://www.rish.kyoto-u.ac.jp/ear/data-fai/index.html#data
;
;CODE:
; A. Shinbori, 19/09/2010.
;
;MODIFICATIONS:
; A. Shinbori, 24/03/2011.
; A. Shinbori, 06/10/2011.
; A. Shinbori, 31/01/2012.
; A. Shinbori, 17/12/2012.
; A. Shinbori, 01/08/2013.
; A. Shinbori, 18/08/2013.
; A. Shinbori, 24/01/2014.
; A. Shinbori, 08/08/2017.
; A. Shinbori, 30/11/2017.
; A. Shinbori, 16/02/2018.
;   
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_ear_iono_fr_txt, parameter1=parameter1, $
  parameter2=parameter2, $
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
;parameters1:
;************
;--- all parameters1 (default)
parameter1_all = strsplit('fb1p16a fb1p16b fb1p16c fb1p16d fb1p16e fb1p16f fb1p16g fb1p16h fb1p16i '+$
                          'fb1p16j1 fb1p16j2 fb1p16j3 fb1p16j4 fb1p16j5 fb1p16j6 fb1p16j7 fb1p16j8 fb1p16j9 '+$
                          'fb1p16j10 fb1p16j11 fb1p16k1 fb1p16k2 fb1p16k3 fb1p16k4 fb1p16k5 fb8p16 fb8p16k1 fb8p16k2 '+$
                          'fb8p16k3 fb8p16k4 fb1p16m2 fb1p16m3 fb1p16m4 fb8p16m1 fb8p16m2 ',$
                          ' ', /extract)

;--- check parameter1
if(not keyword_set(parameter1)) then parameter1='all'
parameters = ssl_check_valid_name(parameter1, parameter1_all, /ignore_case, /include_all)

print, parameters

;************
;parameters2:
;************
;--- all parameters2 (default)
parameter2_all = strsplit('dpl1 dpl2 dpl3 dpl4 dpl5 dpl6 dpl7 dpl8 pwr1 pwr2 pwr3 pwr4 pwr5 '+$
                          'pwr6 pwr7 pwr8 wdt1 wdt2 wdt3 wdt4 wdt5 wdt6 wdt7 wdt8 pn1 pn2 pn3 '+$
                          'pn4 pn5 pn6 pn7 pn8',' ', /extract)

;--- check parameter2
if(not keyword_set(parameter2)) then parameter2='all'
parameters2 = ssl_check_valid_name(parameter2, parameter2_all, /ignore_case, /include_all)

print, parameters2

;*****************
;Defition of unit:
;*****************
;--- all units (default)
unit_all = strsplit('m/s dB',' ', /extract)

;**************************
;Loop on downloading files:
;**************************
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
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
                   file_format='YYYY/YYYYMMDD/'+$
                   'YYYYMMDD',trange=trange,times=times,/unique)+'.fai'+parameters[ii]+'.csv.tar.gz'
  
     ;===============================
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/ktb/ear/fai/f_region/csv/'
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/ear/data-fai/data/csv/'
    
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
  
  
   for iii=0L,n_elements(parameters2)-1 do begin   

      if (downloadonly eq 0) then begin

        ;===================================================
        ;read data, and create tplot vars at each parameter:
        ;===================================================
        ;Read the files:
        ;===============
   
        ;Definition of string variable:
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
            
           ;---Untar the donwloaded csv files:
            file_untar, file
           
           ;---Open read file:
            file2 = strmid(file,0,strlen(file)-10) + parameters2[iii]+'.csv'
            openr,lun,file2,/get_lun 
            
           ;==========================
           ;Read information of range:
           ;==========================              
            readf, lun, s  
            
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
          
           ;Enter the missing value:
            for j=0L,n_elements(altitude)-1 do begin
               b = altitude[j]
               wbad = where(b eq 0,nbad)
               if nbad gt 0 then b[wbad] = !values.f_nan
               altitude[j]=b
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
                  data2 = fltarr(1,n_elements(data)-1)+!values.f_nan
                  
                 ;---Get date and time information:
                  year = strmid(data[0],0,4)
                  month = strmid(data[0],5,2)
                  day = strmid(data[0],8,2)
                  hour = strmid(data[0],11,2)
                  minute = strmid(data[0],14,2)
                  
                 ;---Convert time from local time to unix time      
                  time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+hour+':'+minute) - 7.0d * 3600.0d
                 
                 ;Replace missing value by NaN:
                  for j=0L,n_elements(data)-2 do begin
                     a = float(data[j+1])
                     wbad = where(a eq -999,nbad)
                     if nbad gt 0 then a[wbad] = !values.f_nan
                     data2[0,j]=a
                  endfor
                  
                 ;=============================
                 ;Append data of time and data:
                 ;=============================
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
  
         if size(pwr1,/type) eq 4 then begin
            if strmid(parameters2[iii],0,2) eq 'dp' then o=0
            if strmid(parameters2[iii],0,2) eq 'wd' then o=0 
            if strmid(parameters2[iii],0,2) eq 'pw' then o=1
            if strmid(parameters2[iii],0,2) eq 'pn' then o=1
           
           ;---Create tplot variables for each parameter:
            dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'M. Yamamoto'))
            store_data,'iug_ear_fai'+parameters[ii]+'_'+parameters2[iii],data={x:ear_time, y:ear_data, v:altitude},dlimit=dlimit

           ;----Edge data cut:
            time_clip, 'iug_ear_fai'+parameters[ii]+'_'+parameters2[iii], init_time2[0], init_time2[1], newname = 'iug_ear_fai'+parameters[ii]+'_'+parameters2[iii]
    
           ;---Add options:
            new_vars=tnames('iug_ear_fai'+parameters[ii]+'_'+parameters2[iii])
            if new_vars[0] ne '' then begin
               options,'iug_ear_fai'+parameters[ii]+'_'+parameters2[iii],ytitle='EAR-FAI!CHeight!C[km]',ztitle=parameters2[iii]+'!C['+unit_all[o]+']'
               options,'iug_ear_fai'+parameters[ii]+'_'+parameters2[iii], labels='EAR-FAI F-region [km]'   
               if strmid(parameters2[iii],0,2) ne 'np' then options, 'iug_ear_fai'+parameters[ii]+'_'+parameters2[iii], 'spec', 1         
            endif
         endif 
      
        ;---Clear time and data buffer:
         ear_time=0
         ear_data=0

        ;---Add tdegap    
         new_vars=tnames('iug_ear_fai*')
         if new_vars[0] ne '' then begin    
           tdegap, 'iug_ear_fai'+parameters[ii]+'_'+parameters2[iii],/overwrite
         endif
      endif
     ;---Initialization of timespan for parameters-2:
      timespan, time_org
   endfor
  ;---Initialization of timespan for parameters-1:
   timespan, time_org
endfor
  
new_vars=tnames('iug_ear_fai*')
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

