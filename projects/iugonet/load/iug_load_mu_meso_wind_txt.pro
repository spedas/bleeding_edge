;+
;
;NAME:
;iug_load_mu_meso_wind_txt
;
;PURPOSE:
;  Queries the RISH servers for the 1-hour average wind data (CSV format) of the 
;  mesosphere taken by the Middle and Upper atmosphere (MU) radar at Shigaraki 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_meso_wind_txt,downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  PARAMETER = parameter name of wind data in the mesosphere.  
;          For example, iug_load_mu_meso_wind_txt, parameter = 'uwnd'.
;          The default is 'all', i.e., load all available parameters.
;  LEVEL = Observation data level. For example, iug_load_mu_wind_meso_txt, level = 'org'.
;            The default is 'all', i.e., load all available levels.
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
; A. Shinbori, 25/07/2012.
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

pro iug_load_mu_meso_wind_txt, parameter=parameter, $ 
   level=level, $
   downloadonly=downloadonly, $
   trange=trange, $
   verbose=verbose

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2

;*****************
;Parameter check:
;*****************
;--- all parameters (default)
parameter_all = strsplit('uwnd vwnd wwnd',' ', /extract)

;--- check parameters
if (not keyword_set(level)) then parameter='all'
parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters


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
jj=0L
for ii=0L,n_elements(levels)-1 do begin
   for iii=0,n_elements(parameters)-1 do begin
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
         source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/sgk/mu/mesosphere/wind/csv/'
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

        ;---Initialize data and time buffer
         mu_time=0
         mu_data=0
      
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
                  data2 = fltarr(1,(n_elements(data)-1)/2)
                 
                 ;---Get date and time information:
                  year = strmid(data(0),0,4)
                  month = strmid(data(0),5,2)
                  day = strmid(data(0),8,2)
                  hour = strmid(data(0),11,2)
                  minute = strmid(data(0),14,2) 
                
                 ;---Convert time from local time to unix time:      
                  time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+hour+':'+minute) $
                          -time_double(string(1970)+'-'+string(1)+'-'+string(1)+'/'+string(9)+':'+string(0)+':'+string(0))

                 ;Replace missing value by NaN:
                  for j=0L,(n_elements(data)-2)/2 do begin
                     data2[0,j]=float(data[2*j+1])
                     a = float(data[2*j+1])
                     if levels[ii] eq 'original' then begin
                        if_cond = fix(data[2*j+2])
                        wbad = where(if_cond ge 2,nbad)
                        if nbad gt 0 then a[wbad] = !values.f_nan
                     endif
                     if levels[ii] eq 'screening' then begin
                        if_cond = fix(data[2*j+2])
                        wbad = where(if_cond ge 1,nbad)
                        if nbad gt 0 then a[wbad] = !values.f_nan
                     endif
                     data2[0,j]=a
                  endfor

                 ;=============================
                 ;Append data of time and data:
                 ;=============================
                  append_array, mu_time, time
                  append_array, mu_data, data2
               endif
            endwhile 
            free_lun,lun  
         endfor

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
         
         if (size(mu_data,/type) eq 4) then begin
           ;Create tplot variable for wind data:
            dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Nakamura'))
            store_data,'iug_mu_meso_'+parameters[iii]+'_'+levels[ii],data={x:mu_time, y:mu_data, v:altitude},dlimit=dlimit
           
           ;---Add options:
            new_vars=tnames('iug_mu_meso_'+parameters[iii]+'_'+levels[ii])
            if new_vars[0] ne '' then begin
               options,'iug_mu_meso_'+parameters[iii]+'_'+levels[ii],ytitle='MUR-meso!CHeight!C[km]',ztitle=parameters[iii]+'!C[m/s]'
               options,'iug_mu_meso_'+parameters[iii]+'_'+levels[ii], labels='MUR-meso [km]'         
               options, 'iug_mu_meso_'+parameters[iii]+'_'+levels[ii], 'spec', 1        
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
                 
        ;---Clear time and data buffer:
         mu_time=0
         mu_data=0
     
      endif
      jj=n_elements(local_paths)
   endfor
   jj=n_elements(local_paths)
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

