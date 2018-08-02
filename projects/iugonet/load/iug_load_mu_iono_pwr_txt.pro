;+
;
;NAME:
;iug_load_mu_iono_pwr_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for ion and electron temperatures in text format 
;  estimated from the incoherent scatter observation of the MU radar at Shigaraki 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_iono_pwr_txt, parameter = parameter, downloadonly = downloadonly, $
;                          trange = trange, verbose=verbose
;
;KEYWOARDS:
;  PARAMETER = parameter name of echo power data taken by the MU incherent scatter mode.  
;          For example, iug_load_mu_iono_pwr_txt, parameter = 'pwr1'.
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
; A. Shinbori, 03/10/2012.
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

pro iug_load_mu_iono_pwr_txt, parameter = parameter, $
   downloadonly = downloadonly, $
   trange = trange, $
   verbose = verbose

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
parameter_all = strsplit('pwr1 pwr2 pwr3 pwr4',' ', /extract)

;--- check parameter
if(not keyword_set(parameter)) then parameter='all'
parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters

;**************************
;Loop on downloading files:
;**************************
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
h=0L
site_time=0
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
      file_names = file_dailynames(file_format='YYYY/YYYYMMDD',trange=trange,times=times,/unique)+'_'+parameters[ii]+'.txt'
    
     ;===============================        
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/sgk/mu/ionosphere/pwr/text/'
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/isdata/data/pwr/text/'
  
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

     ;---Definition of string variable:
      s=''
      
     ;======================================
     ;Loop on files (read the NetCDF files): 
     ;======================================
      for h=0L,n_elements(local_paths)-1 do begin
         file= local_paths[h]
         if file_test(/regular,file) then  dprint,'Loading the ionosphere data estimated from the incoherent scatter observation of the MU radar: ',file $
         else begin
            dprint,'The ionosphere data estimated from the incoherent scatter observation of the MU radar ',file,' not found. Skipping'
            continue
         endelse
    
        ;---Open read file:
         openr,lun,file,/get_lun

        ;========================
        ;Read the beam direction:
        ;========================        
         readf,lun,s
         temp = strsplit(s,",",/extract)
         az = temp[0]
         ze = temp[1]
   
        ;=====================
        ;Read the height data:
        ;=====================        
         readf,lun,s
         height = float(strsplit(s,',',/extract))
      
         while(not eof(lun)) do begin
           ;---Read the time data:
            readf,lun,s
            data=strsplit(s,' ',/extract)
            year = strmid(data[0],0,4)
            month = strmid(data[0],5,2)
            day = strmid(data[0],8,2)
            time = data[1]
            
           ;---Start time:
            stime = time_double(year+'-'+month+'-'+day+'/'+time)
            year = strmid(data[3],0,4)
            month = strmid(data[3],5,2)
            day = strmid(data[3],8,2)
            time = data[4]
            
           ;---End time:
            etime = time_double(year+'-'+month+'-'+day+'/'+time)
            mu_time = (stime+etime)/2.0D - time_double('1970-1-1/09:00:00')
         
           ;---Definition of temp. arraies: 
            pwr = fltarr(1,n_elements(height))
            
           ;---Replace missing value by NaN:
            pwr[0,*]= float(data[5:n_elements(height)-1+5])
            for j=0L,n_elements(height)-1 do begin       
               a = float(pwr[0,j])            
               wbad = where(a eq 999.0 ,nbad)
               if nbad gt 0 then a[wbad] = !values.f_nan
               pwr[0,j] =a
            endfor
                               
           ;==============================
           ;Append array of time and data:
           ;==============================
            append_array, site_time, mu_time
            append_array, pwr_app, pwr
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
                       + 'for Sustainable Humanosphere of Kyoto University. We would also' $
                       + 'appreciate receiving a copy of the relevant publications.The distribution of ' $
                       + 'ionogram data has been partly supported by the IUGONET (Inter-university Upper ' $
                       + 'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '$
                       + 'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'

      if size(pwr_app,/type) eq 4 then begin
        ;---Create tplot variable for echo power:
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'Y. Yamamoto'))
         store_data,'iug_mu_iono_'+parameters[ii],data={x:site_time, y:pwr_app,v:height},dlimit=dlimit
      
        ;----Edge data cut:
         time_clip,'iug_mu_iono_'+parameters[ii], init_time2[0], init_time2[1], newname = 'iug_mu_iono_'+parameters[ii]     
         options,'iug_mu_iono_'+parameters[ii],ytitle='MU-iono!CHeight!C[km]',ztitle= parameters[ii]+'!C[dB]'
         options,'iug_mu_iono_'+parameters[ii],spec=1
      
        ;---Add tdegap
         tdegap, 'iug_mu_iono_'+parameters[ii],dt=3600,/overwrite
      endif
  
     ;---Clear time and data buffer:
      site_time=0
      pwr_app=0
   endif
   jj=n_elements(local_paths)
  ;---Initialization of timespan for parameters:
   timespan, time_org
endfor

new_vars=tnames('iug_mu_iono_pwr*')
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
print, 'If you acquire the middle and upper atmosphere (MU) radar data, '
print, 'we ask that you acknowledge us in your use of the data. ' 
print, 'This may be done by including text such as MU data provided ' 
print, 'by Research Institute for Sustainable Humanosphere of Kyoto University. ' 
print, 'We would also appreciate receiving a copy of the relevant publications. '
print, 'The distribution of ionogram data has been partly supported by the IUGONET '
print, '(Inter-university Upper atmosphere Global Observation NETwork) project '
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, '
print, 'Sports, Science and Technology (MEXT), Japan.' 

end

