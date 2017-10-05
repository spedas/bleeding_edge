;+
;
;NAME:
;iug_load_mu_iono_drift_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for ionospheric plasma drift velocity in text format 
;  estimated from the incoherent scatter observation of the MU radar at Shigaraki 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_iono_drift_txt, downloadonly = downloadonly, $
;                          trange = trange, verbose=verbose
;
;KEYWOARDS:  
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
;  
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-05-19 11:44:55 -0700 (Fri, 19 May 2017) $
; $LastChangedRevision: 23337 $
; $URL $
;-

pro iug_load_mu_iono_drift_txt, downloadonly = downloadonly, $
   trange = trange, $
   verbose = verbose

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2

;******************************************************************
;Loop on downloading files
;******************************************************************
;Get timespan, define FILE_NAMES, and load data:
;===============================================
;
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
h=0L
site_time=0    
if ~size(fns,/type) then begin 
  ;****************************
  ;Get files for ith component:
  ;****************************       
   file_names = file_dailynames(file_format='YYYY/YYYYMMDD',trange=trange,times=times,/unique)+'_drift.txt'
    
  ;===============================        
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/sgk/mu/ionosphere/drift/text/'
   source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/isdata/data/drift/text/'
  
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

  ;---Definition of string variable amd array:
   s=''
   Vd_b=fltarr(1,4)
   
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
        
     ;=================
     ;Loop on readdata:
     ;=================
      while(not eof(lun)) do begin
         readf,lun,s
         ok=1
         if strmid(s,0,1) eq '[' then ok=0
         if ok && keyword_set(s) then begin
            dprint,s ,dlevel=5
            data = strsplit(s,' ',/extract)
         
           ;---Get date and time information
            year = data[0]
            month = data[1]
            day = data[2]
            hour = data[3]
  
           ;---Convert time from LT to UT      
            time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+hour+':00:00') $
                   -time_double(string(1970)+'-'+string(1)+'-'+string(1)+'/'+string(9)+':'+string(0)+':'+string(0)) 
         
           ;---Replace missing value by NAN:      
            a = float(data[4])            
            wbad = where(a eq 999.0,nbad)
            if nbad gt 0 then a[wbad] = !values.f_nan
            Vperp_e =a
            b = float(data[5])            
            wbad = where(b eq 999.0,nbad)
            if nbad gt 0 then b[wbad] = !values.f_nan
            Vperp_n =b
            c = float(data[6])            
            wbad = where(c eq 999.0,nbad)
            if nbad gt 0 then c[wbad] = !values.f_nan
            Vpara_u =c
            d = float(data[7])            
            wbad = where(d eq 999.0,nbad)
            if nbad gt 0 then d[wbad] = !values.f_nan
            Vz_ns =d
            e = float(data[8])            
            wbad = where(e eq 999.0,nbad)
            if nbad gt 0 then e[wbad] = !values.f_nan
            Vz_ew =e                           
            for k=9, n_elements(data)-1 do begin                
               f = float(data[k])            
               wbad = where(f eq 999.0,nbad)
               if nbad gt 0 then f[wbad] = !values.f_nan
               Vd_b[k-9] =f
            endfor
         endif
         
        ;==============================
        ;Append array of time and data:
        ;==============================
         append_array, site_time, time
         append_array, Vperp_e_app, Vperp_e
         append_array, Vperp_n_app, Vperp_n
         append_array, Vpara_u_app, Vpara_u
         append_array, Vz_ns_app, Vz_ns
         append_array, Vz_ew_app, Vz_ew
         append_array, Vd_b_app, Vd_b
      endwhile 
      free_lun,lun     
   endfor  
   
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

   if size(Vperp_e_app,/type) eq 4 then begin
      ;---Create tplot variables for drift velocity and add options:
      dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'Y. Otsuka'))
      store_data,'iug_mu_iono_Vperp_e',data={x:site_time, y:Vperp_e_app},dlimit=dlimit
      options,'iug_mu_iono_Vperp_e',ytitle='MU-iono!CVperp_e!C[m/s]'
      store_data,'iug_mu_iono_Vperp_n',data={x:site_time, y:Vperp_n_app},dlimit=dlimit
      options,'iug_mu_iono_Vperp_n',ytitle='MU-iono!CVperp_n!C[m/s]'
      store_data,'iug_mu_iono_Vpara_u',data={x:site_time, y:Vpara_u_app},dlimit=dlimit
      options,'iug_mu_iono_Vpara_u',ytitle='MU-iono!CVpara_u!C[m/s]'
      store_data,'iug_mu_iono_Vz_ns',data={x:site_time, y:Vz_ns_app},dlimit=dlimit
      options,'iug_mu_iono_Vz_ns',ytitle='MU-iono!CVz_ns!C[m/s]'
      store_data,'iug_mu_iono_Vz_ew',data={x:site_time, y:Vz_ew_app},dlimit=dlimit
      options,'iug_mu_iono_Vz_ew',ytitle='MU-iono!CVz_ew!C[m/s]'
      store_data,'iug_mu_iono_Vd_b',data={x:site_time, y:Vd_b_app},dlimit=dlimit
      options,'iug_mu_iono_Vd_b',ytitle='MU-iono!CVd_b!C[m/s]'
   endif
  
  ;---Clear time and data buffer:
   site_time=0
   Vperp_e_app=0
   Vperp_n_app=0
   Vpara_u_app=0
   Vz_ew_app=0
   Vz_ns_app=0
   Vd_b_app=0
   
  ;---Add tdegap
   tdegap, 'iug_mu_iono_Vperp_e',dt=3600,/overwrite
   tdegap, 'iug_mu_iono_Vperp_n',dt=3600,/overwrite
   tdegap, 'iug_mu_iono_Vpara_u',dt=3600,/overwrite
   tdegap, 'iug_mu_iono_Vz_ew',dt=3600,/overwrite
   tdegap, 'iug_mu_iono_Vz_ns',dt=3600,/overwrite
   tdegap, 'iug_mu_iono_Vd_b',dt=3600,/overwrite 
  
endif

new_vars=tnames('iug_mu_iono_V*')
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

