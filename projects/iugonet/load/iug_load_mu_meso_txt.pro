;+
;
;NAME:
;iug_load_mu_meso_txt
;
;PURPOSE:
;  Queries the RISH servers for the standard observation data (CSV format) of the 
;  mesosphere taken by the Middle and Upper atmosphere (MU) radar at Shigaraki and 
;  loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_meso_txt, level=level, parameter=parameter, $
;                       downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  PARAMETER = Parameter name of MU mesosphere obervation data.  
;          For example, iug_load_mu_meso_txt, parameter1 = 'dpl1'.
;          The default is 'all', i.e., load all available parameters.
;  LEVEL = Choice of original and screening data of MU mesosphere obervation.  
;          For example, iug_load_mu_meso_txt, parameter2 = 'screening'.
;          The default is 'all', i.e., load all available parameters.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
;
;CODE:
; A. Shinbori, 25/07/2012.
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

pro iug_load_mu_meso_txt, parameter=parameter, $
   level=level, $
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

;****************
;Parameter check:
;****************
;--- all parameters (default)
parameter_all = strsplit('dpl1 dpl2 dpl3 dpl4 dpl5 pwr1 pwr2 pwr3 pwr4 pwr5 '+$
                          'wdt1 wdt2 wdt3 wdt4 wdt5 pn1 pn2 pn3 pn4 pn5',' ', /extract)

;--- check site codes
if (not keyword_set(parameter)) then parameter='all'
parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters


;************
;Level check:
;************
;--- all levels (default)
level_all = strsplit('org scr',' ', /extract)

;--- check parameters
if (not keyword_set(level)) then level='all'
levels = ssl_check_valid_name(level, level_all, /ignore_case, /include_all)

print, levels

;*****************
;Defition of unit:
;*****************
;--- all units (default)
unit_all = strsplit('m/s dB',' ', /extract)

;**************************
;Loop on downloading files:
;**************************

get_timespan, time_org

;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
jj=0L
for ii=0L,n_elements(levels)-1 do begin
   for iii=0,n_elements(parameters)-1 do begin
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
                     'YYYYMMDD',trange=trange,times=times,/unique)+'.'+parameters[iii]+'.csv'
        
        ;===============================
        ;Define FILE_RETRIEVE structure:
        ;===============================
         source = file_retrieve(/struct)
         source.verbose=verbose
         source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/sgk/mu/mesosphere/csv/'
         source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/mesosphere/data/text/'
    
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
        ;Read data, and create tplot vars at each parameter:
        ;===========================================================
        ;Read the files:
        ;===============
   
        ;---Definition of parameters:
         s=''
         
        ;==============
        ;Loop on files: 
        ;==============
         for h=jj,n_elements(local_paths)-1 do begin
            file= local_paths[h]
            if file_test(/regular,file) then  dprint,'Loading MU mesosphere file: ',file $
            else begin
               dprint,'MU mesosphere file ',file,' not found. Skipping'
               continue
            endelse  
            
           ;---Open read file: 
            openr,lun,file,/get_lun  
              
           ;===========================
           ;Read information of height:
           ;===========================  
            if (strmid(parameters[iii],0,2) ne 'pn') then begin        
               readf, lun, s
          
              ;---Definition of altitude and data arraies:
               h_data = strsplit(s,',',/extract)
               altitude = fltarr(n_elements(h_data)-1)
          
              ;---Enter the altitude information:
               for j=0L,n_elements(h_data)-2 do begin
                  altitude[j] = float(h_data[j+1])
               endfor
            endif
           
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
                  if (strmid(parameters[iii],0,2) ne 'pn') then data2 = fltarr(1,(n_elements(data)-1)/2)
              
                 ;---Get date and time information:
                  year = strmid(data[0],0,4)
                  month = strmid(data[0],5,2)
                  day = strmid(data[0],8,2)
                  hour = strmid(data[0],11,2)
                  minute = strmid(data[0],14,2) 
                  second = strmid(data[0],17,2)
                
                 ;---Convert time from local time to unix time:      
                  time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+hour+':'+minute+':'+second) - double(9) * 3600.0d

                 ;Replace missing value by NaN:
                  if (strmid(parameters[iii],0,2) ne 'pn') then begin
                     for j=0L,(n_elements(data)-2)/2 do begin
                        data2[0,j]=float(data[2*j+1])
                        a = float(data[2*j+1])
                        if levels[ii] eq 'scr' then begin
                           if_cond = fix(data[2*j+2])
                           wbad = where(if_cond ge 4,nbad)
                           if nbad gt 0 then a[wbad] = !values.f_nan
                        endif
                        data2[0,j]=a
                     endfor
                  endif
                  if (strmid(parameters[iii],0,2) eq 'pn') then begin   
                     data2=float(data[1])
                  endif

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
         acknowledgstring = 'The Equatorial Atmosphere Radar belongs to Research Institute for '+$
                            'Sustainable Humanosphere (RISH), Kyoto University and is operated by '+$
                            'RISH and National Institute of Aeronautics and Space (LAPAN) Indonesia. '+$
                            'Distribution of the data has been partly supported by the IUGONET '+$
                            '(Inter-university Upper atmosphere Global Observation NETwork) project '+$
                            '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, '+$
                            'Sports, Science and Technology (MEXT), Japan.'

         if strmid(parameters[iii],0,2) eq 'dp' then o=0
         if strmid(parameters[iii],0,2) eq 'wd' then o=0 
         if strmid(parameters[iii],0,2) eq 'pw' then o=1
         if strmid(parameters[iii],0,2) eq 'pn' then o=1
         
         if (size(mu_data,/type) eq 4) and (strmid(parameters[iii],0,2) ne 'pn') then begin
           ;---Create tplot variable for echo power, spectral width and Doppler velocity:
            dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Nakamura'))
            store_data,'iug_mu_meso_'+parameters[iii]+'_'+levels[ii],data={x:mu_time, y:mu_data, v:altitude},dlimit=dlimit

           ;----Edge data cut:
            time_clip,'iug_mu_meso_'+parameters[iii]+'_'+levels[ii], init_time2[0], init_time2[1], newname = 'iug_mu_meso_'+parameters[iii]+'_'+levels[ii]
           
           ;---Add options;
            new_vars=tnames('iug_mu_meso_'+parameters[iii]+'_'+levels[ii])
            if new_vars[0] ne '' then begin
               options,'iug_mu_meso_'+parameters[iii]+'_'+levels[ii],ytitle='MUR-meso!CHeight!C[km]',ztitle=parameters[iii]+'!C['+unit_all[o]+']'
               options,'iug_mu_meso_'+parameters[iii]+'_'+levels[ii], labels='MUR-meso [km]'         
               options, 'iug_mu_meso_'+parameters[iii]+'_'+levels[ii], 'spec', 1        
            endif       
         endif

         if (size(mu_data,/type) eq 4) and (strmid(parameters[iii],0,2) eq 'pn') then begin
           ;---Create tplot variable for noise level: 
            dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Nakamura'))
            store_data,'iug_mu_meso_'+parameters[iii],data={x:mu_time, y:mu_data},dlimit=dlimit

           ;----Edge data cut:
            time_clip,'iug_mu_meso_'+parameters[iii]+'_'+levels[ii], init_time2[0], init_time2[1], newname = 'iug_mu_meso_'+parameters[iii]+'_'+levels[ii]
           
           ;---Add options;
            new_vars=tnames('iug_mu_meso_'+parameters[iii])
            if new_vars[0] ne '' then begin
               options,'iug_mu_meso_'+parameters[iii],ytitle='MUR-meso!CNoise level!C[dB]'
               options,'iug_mu_meso_'+parameters[iii], labels='MUR-meso [km]'         
               options, 'iug_mu_meso_'+parameters[iii], 'spec', 0         
            endif       
         endif
                 
        ;---Clear time and data buffer:
         mu_time=0
         mu_data=0
      endif
      jj=n_elements(local_paths)
     ;---Initialization of timespan for parameters:
      timespan, time_org
   endfor
   jj=n_elements(local_paths)
  ;---Initialization of timespan for parameters:
   timespan, time_org
endfor
  
new_vars=tnames('iug_mu_meso_*')
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

