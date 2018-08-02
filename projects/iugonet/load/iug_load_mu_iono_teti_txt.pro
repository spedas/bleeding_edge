;+
;
;NAME:
;iug_load_mu_iono_teti_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for ion and electron temperatures in text format 
;  estimated from the incoherent scatter observation of the MU radar at Shigaraki 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_iono_teti_txt, downloadonly = downloadonly, $
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

pro iug_load_mu_iono_teti_txt, downloadonly = downloadonly, $
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

;**************************
;Loop on downloading files:
;**************************
;==============================================================
;Change time window associated with a time shift from UT to LT:
;==============================================================
day_org = (time_org[1] - time_org[0])/86400.d
day_mod = day_org + 1
timespan, time_org[0] - 3600.0d * 9.0d, day_mod
if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) + 9.0d * 3600.0d); for GUI

;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
h=0L
site_time=0
if ~size(fns,/type) then begin 
  ;****************************
  ;Get files for ith component:
  ;****************************       
   file_names = file_dailynames(file_format='YYYY/YYYYMMDD',trange=trange,times=times,/unique)+'_teti.txt'
    
  ;===============================        
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/sgk/mu/ionosphere/teti/text/'
   source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/isdata/data/teti/text/'
  
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

     ;=====================
     ;Read the loop number:
     ;=====================        
      readf,lun,s
      n=fix(s)
   
     ;=====================
     ;Read the height data:
     ;=====================        
      readf,lun,s
      height = float(strsplit(s,' ',/extract))
      
      for i=0L, n-1 do begin
        ;---Read the time data:
         readf,lun,s
         time_data=strsplit(s,' ',/extract)
         year = strmid(time_data[0],0,4)
         month = strmid(time_data[0],5,2)
         day = strmid(time_data[0],8,2)
         time = time_data[1]
         
        ;---Start time:
         stime = time_double(year+'-'+month+'-'+day+'/'+time)
         year = strmid(time_data[3],0,4)
         month = strmid(time_data[3],5,2)
         day = strmid(time_data[3],8,2)
         time = time_data[4]
         
        ;---End time:
         etime = time_double(year+'-'+month+'-'+day+'/'+time)
         mu_time = (stime+etime)/2.0D - time_double('1970-1-1/09:00:00')
         
        ;---Definition of temp. arraies: 
         ti = fltarr(1,n_elements(height))
         te = fltarr(1,n_elements(height))
         er_ti = fltarr(1,n_elements(height))
         er_te = fltarr(1,n_elements(height))
         er_tr = fltarr(1,n_elements(height))
         snr = fltarr(1,n_elements(height))
        
        ;---Replace missing value by NaN:         
         for j=0L,n_elements(height)-1 do begin
            readf,lun,s
            temp_data=float(strsplit(s,' ',/extract))        
            a = float(temp_data[0])            
            wbad = where(a eq 999.0 or fix(temp_data[2]) eq 3,nbad)
            if nbad gt 0 then a[wbad] = !values.f_nan
            ti[0,j] =a
            b = float(temp_data[1])            
            wbad = where(b eq 999.0 or fix(temp_data[2]) eq 3,nbad)
            if nbad gt 0 then b[wbad] = !values.f_nan
            te[0,j] =b
            c = float(temp_data[3])            
            wbad = where(c eq 999.0 or fix(temp_data[2]) eq 3,nbad)
            if nbad gt 0 then c[wbad] = !values.f_nan
            er_ti[0,j] =c
            d = float(temp_data[4])            
            wbad = where(d eq 999.0 or fix(temp_data[2]) eq 3,nbad)
            if nbad gt 0 then d[wbad] = !values.f_nan
            er_te[0,j] =d
            e = float(temp_data[5])            
            wbad = where(e eq 999.0 or fix(temp_data[2]) eq 3,nbad)
            if nbad gt 0 then e[wbad] = !values.f_nan
            er_tr[0,j] =e
            f = float(temp_data[6])            
            wbad = where(f eq 999.0 or fix(temp_data[2]) eq 3,nbad)
            if nbad gt 0 then f[wbad] = !values.f_nan
            snr[0,j] =f
         endfor
                               
        ;==============================
        ;Append array of time and data:
        ;==============================
         append_array, site_time, mu_time
         append_array, ti_app, ti
         append_array, te_app, te
         append_array, er_ti_app, er_ti
         append_array, er_te_app, er_te
         append_array, er_tr_app, er_tr
         append_array, snr_app, snr
      endfor
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

   if size(ti_app,/type) eq 4 then begin
     ;---Create tplot variables for temperature:
      dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'Y. Yamamoto'))
      store_data,'iug_mu_iono_ti',data={x:site_time, y:ti_app,v:height},dlimit=dlimit
      
     ;----Edge data cut:
      time_clip,'iug_mu_iono_ti', init_time2[0], init_time2[1], newname = 'iug_mu_iono_ti'      
      options,'iug_mu_iono_ti',ytitle='MU-iono!CHeight!C[km]',ztitle='Ion temp.!C[K]'
      options,'iug_mu_iono_ti',spec=1
     
      store_data,'iug_mu_iono_te',data={x:site_time, y:te_app,v:height},dlimit=dlimit
       
     ;----Edge data cut:
      time_clip,'iug_mu_iono_te', init_time2[0], init_time2[1], newname = 'iug_mu_iono_te'     
      options,'iug_mu_iono_te',ytitle='MU-iono!CHeight!C[km]',ztitle='Electron temp.!C[K]'
      options,'iug_mu_iono_te',spec=1
     
      store_data,'iug_mu_iono_er_ti',data={x:site_time, y:er_ti_app,v:height},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_er_ti', init_time2[0], init_time2[1], newname = 'iug_mu_iono_er_ti'     
      options,'iug_mu_iono_er_ti',ytitle='MU-iono!CHeight!C[km]',ztitle='Ion temp. Error!C[K]'
      options,'iug_mu_iono_er_ti',spec=1
     
      store_data,'iug_mu_iono_er_te',data={x:site_time, y:er_te_app,v:height},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_er_te', init_time2[0], init_time2[1], newname = 'iug_mu_iono_er_te'     
      options,'iug_mu_iono_er_te',ytitle='MU-iono!CHeight!C[km]',ztitle='Electron temp. Error!C[K]'
      options,'iug_mu_iono_er_te',spec=1
     
      store_data,'iug_mu_iono_er_tr',data={x:site_time, y:er_tr_app,v:height},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_er_tr', init_time2[0], init_time2[1], newname = 'iug_mu_iono_er_tr'     
      options,'iug_mu_iono_er_tr',ytitle='MU-iono!CHeight!C[km]',ztitle='Te/Ti Error!C[K]'
      options,'iug_mu_iono_er_tr',spec=1
     
      store_data,'iug_mu_iono_snr',data={x:site_time, y:snr_app,v:height},dlimit=dlimit
 
     ;----Edge data cut:
      time_clip,'iug_mu_iono_snr', init_time2[0], init_time2[1], newname = 'iug_mu_iono_snr'     
      options,'iug_mu_iono_snr',ytitle='MU-iono!CHeight!C[km]',ztitle='SNR!C[dB]'
      options,'iug_mu_iono_snr',spec=1

     ;---Add tdegap
      tdegap, 'iug_mu_iono_ti',dt=3600,/overwrite
      tdegap, 'iug_mu_iono_te',dt=3600,/overwrite
      tdegap, 'iug_mu_iono_er_ti',dt=3600,/overwrite
      tdegap, 'iug_mu_iono_er_te',dt=3600,/overwrite
      tdegap, 'iug_mu_iono_er_tr',dt=3600,/overwrite
      tdegap, 'iug_mu_iono_snr',dt=3600,/overwrite 
   endif
  
  ;---Clear time and data buffer:
   site_time=0
   ti_app=0
   te_app=0
   er_ti_app=0
   er_te_app=0
   er_tr_app=0
   snr_app=0
endif

;---Initialization of timespan for parameters:
timespan, time_org

new_vars=tnames('iug_mu_iono_ti')
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

