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
;   
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-05-19 11:44:55 -0700 (Fri, 19 May 2017) $
; $LastChangedRevision: 23337 $
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

;******************************************************************
;Loop on downloading files
;******************************************************************
;Get timespan, define FILE_NAMES, and load data:
;===============================================
;
jj=0L
for ii=0L,n_elements(parameters)-1 do begin
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

     ;---Initialize data and time buffer
      ear_time=0
      ear_data=0

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
               year = strmid(data(0),0,4)
               month = strmid(data(0),5,2)
               day = strmid(data(0),8,2)
               hour = strmid(data(0),11,2)
               minute = strmid(data(0),14,2) 
                 
              ;---Convert time from local time to universal time      
               time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+string(hour)+':'+string(minute)) $
                       -time_double(string(1970)+'-'+string(1)+'-'+string(1)+'/'+string(7)+':'+string(0)+':'+string(0))
              
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

