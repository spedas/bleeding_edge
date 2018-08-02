;+
;
;NAME:
;iug_load_mu_iono_drift_nc
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for ionospheric plasma drift velocity in netCDF format 
;  estimated from the incoherent scatter observation of the MU radar at Shigaraki 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_iono_drift_nc, downloadonly = downloadonly, $
;                          trange = trange, verbose=verbose
;
;KEYWOARDS:  
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
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

pro iug_load_mu_iono_drift_nc, downloadonly = downloadonly, $
   trange = trange, $
   verbose = verbose

;**************
;keyword check:
;**************
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
   file_names = file_dailynames(file_format='YYYY/YYYYMMDD',trange=trange,times=times,/unique)+'_drift.nc'
    
  ;===============================        
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/sgk/mu/ionosphere/drift/nc/'
   source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/isdata/data/drift/netcdf/'
  
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
    
      cdfid = ncdf_open(file,/NOWRITE)  ; Open the file
      glob = ncdf_inquire( cdfid )    ; Find out general info

     ;---Show user the size of each dimension
      print,'Dimensions', glob.ndims
      for i=0L,glob.ndims-1 do begin
         ncdf_diminq, cdfid, i, name,size
         if i EQ glob.recdim then  $
            print,'    ', name, size, '(Unlimited dim)' $
         else      $
            print,'    ', name, size  
      endfor

     ;---Now tell user about the variables
      print
      print, 'Variables'
      for m=0L,glob.nvars-1 do begin

        ;---Get information about the variable
         info = ncdf_varinq(cdfid, m)
         FmtStr = '(A," (",A," ) Dimension Ids = [ ", 10(I0," "),$)'
         print, FORMAT=FmtStr, info.name,info.datatype, info.dim[*]
         print, ']'

        ;---Get attributes associated with the variable
         for l=0L,info.natts-1 do begin
            attname = ncdf_attname(cdfid,m,l)
            ncdf_attget,cdfid,m,attname,attvalue
            print,' Attribute ', attname, '=', string(attvalue)
            if (info.name eq 'time') and (attname eq 'units') then time_data=string(attvalue)
         endfor
      endfor

     ;---Get time information:
      time_info=strsplit(time_data,' ',/extract)
      syymmdd=time_info[2]
      shhmmss=time_info[3]
      time_diff=strsplit(time_info[4],':',/extract)
      time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60 

     ;---Get the variable
      ncdf_varget, cdfid, 'lat', lat
      ncdf_varget, cdfid, 'lon', lon
      ncdf_varget, cdfid, 'obsdate', obsdate
      ncdf_varget, cdfid, 'beam', beam
      ncdf_varget, cdfid, 'az', az
      ncdf_varget, cdfid, 'ze', ze
      ncdf_varget, cdfid, 'time', time
      ncdf_varget, cdfid, 'Vperp_e', Vperp_e
      ncdf_varget, cdfid, 'Vperp_n', Vperp_n
      ncdf_varget, cdfid, 'Vpara_u', Vpara_u
      ncdf_varget, cdfid, 'Vz_ns', Vz_ns
      ncdf_varget, cdfid, 'Vz_ew', Vz_ew
      ncdf_varget, cdfid, 'Vd_b', Vd_b

     ;---Definition of arrary names
      unix_time = dblarr(n_elements(time))
                               
      for i=0L, n_elements(time)-1 do begin
        ;---Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)    
         unix_time[i] = double(time[i])+time_double(syymmdd+'/'+shhmmss)-time_diff2  
         
        ;---Replace missing value by NAN:      
         a = Vperp_e[i]            
         wbad = where(a eq 999.0,nbad)
         if nbad gt 0 then a[wbad] = !values.f_nan
         Vperp_e[i] =a
         b = Vperp_n[i]            
         wbad = where(b eq 999.0,nbad)
         if nbad gt 0 then b[wbad] = !values.f_nan
         Vperp_n[i] =b
         c = Vpara_u[i]            
         wbad = where(c eq 999.0,nbad)
         if nbad gt 0 then c[wbad] = !values.f_nan
         Vpara_u[i] =c
         d = Vz_ns[i]            
         wbad = where(d eq 999.0,nbad)
         if nbad gt 0 then d[wbad] = !values.f_nan
         Vz_ns[i] =d
         e = Vz_ew[i]            
         wbad = where(e eq 999.0,nbad)
         if nbad gt 0 then e[wbad] = !values.f_nan
         Vz_ew[i] =e                         
         for k=0L, n_elements(beam)-1 do begin                
            f = Vd_b[i,k]            
            wbad = where(f eq 999.0,nbad)
            if nbad gt 0 then f[wbad] = !values.f_nan
            Vd_b[i,k] =f
         endfor
      endfor
      
     ;==============================
     ;Append array of time and data:
     ;==============================
      append_array, site_time, unix_time
      append_array, Vperp_e_app, Vperp_e
      append_array, Vperp_n_app, Vperp_n
      append_array, Vpara_u_app, Vpara_u
      append_array, Vz_ns_app, Vz_ns
      append_array, Vz_ew_app, Vz_ew
      append_array, Vd_b_app, Vd_b
      
      ncdf_close,cdfid  ; done
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

   if size(Vperp_e_app,/type) eq 4 then begin
     ;---Create tplot variables for drift velocity and add options:
      dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'Y. Otsuka'))
      store_data,'iug_mu_iono_Vperp_e',data={x:site_time, y:Vperp_e_app},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_Vperp_e', init_time2[0], init_time2[1], newname = 'iug_mu_iono_Vperp_e'
      options,'iug_mu_iono_Vperp_e',ytitle='MU-iono!CVperp_e!C[m/s]'
      
      store_data,'iug_mu_iono_Vperp_n',data={x:site_time, y:Vperp_n_app},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_Vperp_n', init_time2[0], init_time2[1], newname = 'iug_mu_iono_Vperp_n'      
      options,'iug_mu_iono_Vperp_n',ytitle='MU-iono!CVperp_n!C[m/s]'
      
      store_data,'iug_mu_iono_Vpara_u',data={x:site_time, y:Vpara_u_app},dlimit=dlimit
      
      ;----Edge data cut:
      time_clip,'iug_mu_iono_Vpara_u', init_time2[0], init_time2[1], newname = 'iug_mu_iono_Vpara_u'            
      options,'iug_mu_iono_Vpara_u',ytitle='MU-iono!CVpara_u!C[m/s]'
      
      store_data,'iug_mu_iono_Vz_ns',data={x:site_time, y:Vz_ns_app},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_Vz_ns', init_time2[0], init_time2[1], newname = 'iug_mu_iono_Vz_ns'
      options,'iug_mu_iono_Vz_ns',ytitle='MU-iono!CVz_ns!C[m/s]'
      
      store_data,'iug_mu_iono_Vz_ew',data={x:site_time, y:Vz_ew_app},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_Vz_ew', init_time2[0], init_time2[1], newname = 'iug_mu_iono_Vz_ew'      
      options,'iug_mu_iono_Vz_ew',ytitle='MU-iono!CVz_ew!C[m/s]'
      
      store_data,'iug_mu_iono_Vd_b',data={x:site_time, y:Vd_b_app},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_Vd_b', init_time2[0], init_time2[1], newname = 'iug_mu_iono_Vz_ew'
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

;---Initialization of timespan for parameters:
timespan, time_org

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

