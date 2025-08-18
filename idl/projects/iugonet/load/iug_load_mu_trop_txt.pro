;+
;
;NAME:
;iug_load_mu_trop_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the standard observation data of the 
;  troposphere and lower stratsphere in the CSV format taken by the Middle and 
;  Upper atmosphere (MU) radar at Shigaraki and loads data into tplot format.
;
;SYNTAX:
; iug_load_ear_trop_txt, parameter=parameter, $
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
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
;  
;CODE:
; A. Shinbori, 19/09/2010.
;
;MODIFICATIONS:
; A. Shinbori, 24/03/2011.
; A. Shinbori, 13/11/2011.
; A. Shinbori, 26/12/2011.
; A. Shinbori, 31/01/2012.
; A. Shinbori, 19/12/2012.
; A. Shinbori, 27/07/2013.
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

pro iug_load_mu_trop_txt, parameter=parameter, $
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
;--- all unites (default)
unit_all = strsplit('m/s dB',' ', /extract)

;*******************
;Defition of height:
;*******************
height_zm=strsplit('1.998,2.145,2.293,2.441,2.589,2.736,2.884,3.032,3.179,3.327,3.475,3.623,3.770,3.918,4.066,4.213,4.361,4.509,4.657,4.804,'+$
                   '4.952,5.100,5.248,5.395,5.543,5.691,5.838,5.986,6.134,6.282,6.429,6.577,6.725,6.872,7.020,7.168,7.316,7.463,7.611,7.759,'+$
                   '7.907,8.054,8.202,8.350,8.497,8.645,8.793,8.941,9.088,9.236,9.384,9.531,9.679,9.827,9.975,10.122,10.270,10.418,10.565,'+$
                   '10.713,10.861,11.009,11.156,11.304,11.452,11.600,11.747,11.895,12.043,12.190,12.338,12.486,12.634,12.781,12.929,13.077,'+$
                   '13.224,13.372,13.520,13.668,13.815,13.963,14.111,14.259,14.406,14.554,14.702,14.849,14.997,15.145,15.293,15.440,15.588,'+$
                   '15.736,15.883,16.031,16.179,16.327,16.474,16.622,16.770,16.917,17.065,17.213,17.361,17.508,17.656,17.804,17.952,18.099,'+$
                   '18.247,18.395,18.542,18.690,18.838,18.986,19.133,19.281,19.429,19.576',',',/extract)
                   
 height_v=strsplit('2.025,2.175,2.325,2.475,2.625,2.775,2.925,3.075,3.225,3.375,3.525,3.675,3.825,3.975,4.125,4.275,4.425,4.575,4.725,4.875,'+$
                   '5.025,5.175,5.325,5.475,5.625,5.775,5.925,6.075,6.225,6.375,6.525,6.675,6.825,6.975,7.125,7.275,7.425,7.575,7.725,7.875,'+$
                   '8.025,8.175,8.325,8.475,8.625,8.775,8.925,9.075,9.225,9.375,9.525,9.675,9.825,9.975,10.125,10.275,10.425,10.575,10.725,'+$
                   '10.875,11.025,11.175,11.325,11.475,11.625,11.775,11.925,12.075,12.225,12.375,12.525,12.675,12.825,12.975,13.125,13.275,'+$
                   '13.425,13.575,13.725,13.875,14.025,14.175,14.325,14.475,14.625,14.775,14.925,15.075,15.225,15.375,15.525,15.675,15.825,'+$
                   '15.975,16.125,16.275,16.425,16.575,16.725,16.875,17.025,17.175,17.325,17.475,17.625,17.775,17.925,18.075,18.225,18.375,'+$
                   '18.525,18.675,18.825,18.975,19.125,19.275,19.425,19.575,19.725,19.875',',',/extract)

;---Data list which applies the above height data:
f_list=['19860317','19860318','19860319','19860320','19860321','19910209']

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
      file_format='YYYYMM/YYYYMMDD/'+$
                   'YYYYMMDD',trange=trange,times=times,/unique)+'.'+parameters[ii]+'.csv'
                   
     ;===============================
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/mu/troposphere/csv/'
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/data/data/ver01.0807_1.02/'
      
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
         
        ;---File search:
         fname=strsplit(strmid(file,16,17,/REVERSE_OFFSET),'.',/extract)
         idx=where(fname[0] eq f_list)

        ;---Open read file:
         openr,lun,file,/get_lun    
         
        ;=============================
        ;Read information of altitude:
        ;=============================
         readf, lun, s
    
        ;---Definition of altitude and data arraies:
         h_data = strsplit(s,',',/extract)     
         altitude = fltarr(120)
    
        ;---Enter the altitude information:
         if idx eq -1 then begin
            for j=0,n_elements(h_data)-2 do begin
               altitude[j] = float(h_data[j+1])
            endfor
         endif else begin
            if (fname[1] eq 'wwnd') or (fname[1] eq 'pwr1') or (fname[1] eq 'wdt1') then begin
               altitude = height_v
            endif else begin
               altitude = height_zm
            endelse
         endelse
         
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
               data2 = fltarr(1,120)+!values.f_nan
               
              ;---Get date and time information:
               year = strmid(data[0],0,4)
               month = strmid(data[0],5,2)
               day = strmid(data[0],8,2)
               hour = strmid(data[0],11,2)
               minute = strmid(data[0],14,2)  
                
              ;---Convert time from local time to unix time      
               time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+hour+':'+minute) - double(9) * 3600.0d
               
              ;---Replace missing value by NaN:
               d_num=n_elements(data)-1
               st_num=120-d_num
               for j=0L,n_elements(data)-2 do begin
                  a = float(data[j+1])
                  wbad = where(a eq 999,nbad)
                  if nbad gt 0 then a[wbad] = !values.f_nan
                  data2[0,st_num+j]=a
               endfor
               
              ;==============================
              ;Append array of time and data:
              ;==============================
               append_array, mu_time, time
               append_array, mu_data, data2
            endif
         endwhile 
         free_lun,lun
         
        ;==============================
        ;Append array of time and data:
        ;==============================
         append_array, mu_time2, mu_time
         append_array, mu_data2, mu_data 
         mu_time=0
         mu_data=0 
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
      if size(mu_data2,/type) eq 4 then begin
         if strmid(parameters[ii],0,2) eq 'pw' then o=1
         
        ;---Create tplot variables for each parameter:
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'M. Yamamoto'))
         store_data,'iug_mu_trop_'+parameters[ii],data={x:mu_time2, y:mu_data2, v:altitude},dlimit=dlimit

        ;----Edge data cut:
         time_clip,'iug_mu_trop_'+parameters[ii], init_time2[0], init_time2[1], newname = 'iug_mu_trop_'+parameters[ii]
        
        ;---Add options
         new_vars=tnames('iug_mu_trop_*')
         if new_vars[0] ne '' then begin          
            options,'iug_mu_trop_'+parameters[ii],ytitle='MU-trop!CHeight!C[km]',ztitle=parameters[ii]+'!C['+unit_all[o]+']'
            options,'iug_mu_trop_'+parameters[ii], labels='MU-trop [km]'
         endif
      endif  
       
     ;---Add options
      new_vars=tnames('iug_mu_trop_*')
      if new_vars[0] ne '' then options, 'iug_mu_trop_'+parameters[ii], 'spec', 1
    
     ;---Clear time and data buffer:
      mu_time=0
      mu_data=0
       
     ;---Add tdegap
      if new_vars[0] ne '' then tdegap, 'iug_mu_trop_'+parameters[ii],/overwrite
   endif
   
   jj=n_elements(local_paths)
  ;---Initialization of timespan for parameters:
   timespan, time_org
endfor

new_vars=tnames('iug_mu_trop_*')
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

