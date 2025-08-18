;+
;
;NAME:
;iug_load_mu_iono_pwr_nc
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for ion and electron temperatures in netCDF format 
;  estimated from the incoherent scatter observation of the MU radar at Shigaraki 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_iono_pwr_nc, downloadonly = downloadonly, $
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
; A. Shinbori, 02/10/2012.
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

pro iug_load_mu_iono_pwr_nc, downloadonly = downloadonly, $
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
   file_names = file_dailynames(file_format='YYYY/YYYYMMDD',trange=trange,times=times,/unique)+'_pwr.nc'
    
  ;===============================        
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/sgk/mu/ionosphere/pwr/nc/'
   source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/isdata/data/pwr/netcdf/'
  
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
            if (info.name eq 'stime') and (attname eq 'units') then time_data=string(attvalue)
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
      ncdf_varget, cdfid, 'stime', stime
      ncdf_varget, cdfid, 'etime', etime
      ncdf_varget, cdfid, 'beam', beam
      ncdf_varget, cdfid, 'az', az
      ncdf_varget, cdfid, 'ze', ze
      ncdf_varget, cdfid, 'height', height
      ncdf_varget, cdfid, 'pwr', pwr


     ;---Definition of arrary names
      unix_time = dblarr(n_elements(stime))
      center_time = (stime+etime)/2.0                         
      for i=0L, n_elements(center_time)-1 do begin
        ;---Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)    
         unix_time[i] = double(center_time[i])+time_double(syymmdd+'/'+shhmmss)-time_diff2 
         
        ;---Replace missing value by NAN:      
         for j=0L, n_elements(beam)-1 do begin
            for k=0L, n_elements(height[*,0])-1 do begin
               a = pwr[k,i,j]            
               wbad = where(a eq -999.0,nbad)
               if nbad gt 0 then a[wbad] = !values.f_nan
               pwr[k,i,j] =a
            endfor
         endfor
      endfor
      
      pwr1 = pwr[*,*,0]
      pwr2 = pwr[*,*,1]
      pwr3 = pwr[*,*,2]
      pwr4 = pwr[*,*,3]
     
     ;---Transpose of pwr1-4 data
      pwr1 = transpose(pwr1)
      pwr2 = transpose(pwr2)
      pwr3 = transpose(pwr3)
      pwr4 = transpose(pwr4)

     ;==============================
     ;Append array of time and data:
     ;==============================
      append_array, site_time, unix_time
      append_array, pwr1_app, pwr1
      append_array, pwr2_app, pwr2
      append_array, pwr3_app, pwr3
      append_array, pwr4_app, pwr4
      
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

   if size(pwr1_app,/type) eq 4 then begin
     ;---Create tplot variable for echo power: 
      dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'Y. Yamamoto'))
      store_data,'iug_mu_iono_pwr1',data={x:site_time, y:pwr1_app,v:height[*,0]},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_pwr1', init_time2[0], init_time2[1], newname = 'iug_mu_iono_pwr1'
      options,'iug_mu_iono_pwr1',ytitle='MU-iono!CHeight!C[km]',ztitle='pwr1!C[dB]'
      options,'iug_mu_iono_pwr1',spec=1
     
      store_data,'iug_mu_iono_pwr2',data={x:site_time, y:pwr2_app,v:height[*,1]},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_pwr2', init_time2[0], init_time2[1], newname = 'iug_mu_iono_pwr2'     
      options,'iug_mu_iono_pwr2',ytitle='MU-iono!CHeight!C[km]',ztitle='pwr2!C[dB]'
      options,'iug_mu_iono_pwr2',spec=1
     
      store_data,'iug_mu_iono_pwr3',data={x:site_time, y:pwr3_app,v:height[*,2]},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_pwr3', init_time2[0], init_time2[1], newname = 'iug_mu_iono_pwr3'     
      options,'iug_mu_iono_pwr3',ytitle='MU-iono!CHeight!C[km]',ztitle='pwr3!C[dB]'
      options,'iug_mu_iono_pwr3',spec=1
     
      store_data,'iug_mu_iono_pwr4',data={x:site_time, y:pwr4_app,v:height[*,3]},dlimit=dlimit

     ;----Edge data cut:
      time_clip,'iug_mu_iono_pwr4', init_time2[0], init_time2[1], newname = 'iug_mu_iono_pwr4'     
      options,'iug_mu_iono_pwr4',ytitle='MU-iono!CHeight!C[km]',ztitle='pwr4!C[dB]'
      options,'iug_mu_iono_pwr4',spec=1      
   
     ;---Add tdegap
      tdegap, 'iug_mu_iono_pwr1',dt=3600,/overwrite
      tdegap, 'iug_mu_iono_pwr2',dt=3600,/overwrite
      tdegap, 'iug_mu_iono_pwr3',dt=3600,/overwrite
      tdegap, 'iug_mu_iono_pwr4',dt=3600,/overwrite 
   endif
  
  ;---Clear time and data buffer:
   site_time=0
   pwr1_app=0
   pwr2_app=0
   pwr3_app=0
   pwr4_app=0
endif

;---Initialization of timespan for parameters:
timespan, time_org

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

