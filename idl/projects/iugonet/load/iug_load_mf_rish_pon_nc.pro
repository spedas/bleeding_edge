;+
;
;NAME:
;iug_load_mf_rish_pon_nc
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the observation data (uwind, vwind, wwind)
;  in the NetCDF format taken by the MF radar at Pontianak and loads data into
;  tplot format.
;
;SYNTAX:
; iug_load_mf_rish_pon_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
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
; A. Shinbori, 24/01/2013.
;
;MODIFICATIONS:
;
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_mf_rish_pon_nc, downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

;**************
;keyword check:
;**************
if ~keyword_set(verbose) then verbose=2

;******************************************************************
;Loop on downloading files
;******************************************************************
;Get timespan, define FILE_NAMES, and load data:
;===============================================
;
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
if ~size(fns,/type) then begin
  ;****************************
  ;Get files for ith component:
  ;****************************
   file_names = file_dailynames( $
   file_format='YYYY/YYYYMMDD',trange=trange,times=times,/unique)+'_fca.nc'
  
  ;===============================            
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/pon/mf/nc/'
   source.remote_data_dir = 'http://database.rish.kyoto-u.ac.jp/arch/iugonet/data/mf/pontianak/nc/'
  
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
 
  ;---Initialize data and time buffer
   pon_time=0
   zon_wind=0
   mer_wind=0
   ver_wind=0
   height = fltarr(41)
  
   for j=0L,n_elements(local_paths)-1 do begin
      file= local_paths[j]
      if file_test(/regular,file) then  dprint,'Loading pontianak file: ',file $
      else begin
         dprint,'pontianak file ',file,' not found. Skipping'
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
 
     ;---Get the start time infomation from the attribute data:
      time_info=strsplit(time_data,' ',/extract)
      syymmdd=time_info[2]
      shhmmss=time_info[3]
      time_diff=strsplit(time_info[4],':',/extract)
      time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60 
    
     ;---Get the variable
      ncdf_varget, cdfid, 'time', time
      ncdf_varget, cdfid, 'height', height
      ncdf_varget, cdfid, 'uwind', uwind
      ncdf_varget, cdfid, 'vwind', vwind
      ncdf_varget, cdfid, 'wwind', wwind
    
     ;---Definition of arrary names
      uwind_pon=fltarr(n_elements(time),n_elements(height))
      vwind_pon=fltarr(n_elements(time),n_elements(height))
      wwind_pon=fltarr(n_elements(time),n_elements(height))

     ;---Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)      
      unix_time = double(time) +time_double(string(syymmdd)+'/'+string(shhmmss))-double(time_diff2)
      
      for i=0L, n_elements(time)-1 do begin
         uwind_pon[i,*]=uwind[i,*]
         vwind_pon[i,*]=vwind[i,*]
         wwind_pon[i,*]=wwind[i,*]
        
        ;---Replace missing value by NaN: 
         a = uwind_pon[i,*]            
         wbad = where(a eq -9999,nbad)
         if nbad gt 0 then a[wbad] = !values.f_nan
         uwind_pon[i,*] =a
         b = vwind_pon[i,*]            
         wbad = where(b eq -9999,nbad)
         if nbad gt 0 then b[wbad] = !values.f_nan
         vwind_pon[i,*] =b
         c = wwind_pon[i,*]            
         wbad = where(c eq -9999,nbad)
         if nbad gt 0 then c[wbad] = !values.f_nan
         wwind_pon[i,*] =c
      endfor

     ;==============================
     ;Append array of time and data:
     ;==============================
      append_array, pon_time, unix_time
      append_array, zon_wind, uwind_pon
      append_array, mer_wind, vwind_pon
      append_array, ver_wind, wwind_pon
 
      ncdf_close,cdfid  ; done

  endfor

 ;==============================
 ;Store data in TPLOT variables:
 ;==============================
 ;---Acknowlegment string (use for creating tplot vars)
  acknowledgstring = 'Note: If you would like to use following data for scientific purpose, please read and follow the DATA USE POLICY '$
                   +'(http://database.rish.kyoto-u.ac.jp/arch/iugonet/data_policy/Data_Use_Policy_e.html '$ 
                   +'The distribution of MF radar data has been partly supported by the IUGONET (Inter-university Upper '$
                   + 'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '$
                   + 'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.' 
  
   if size(zon_wind,/type) eq 4 then begin
     ;---Create tplot variables and options for zonal wind:
      dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Tsuda'))      
      store_data,'iug_mf_pon_uwnd',data={x:pon_time, y:zon_wind, v:height},dlimit=dlimit
      new_vars=tnames('iug_mf_pon_uwnd')
      if new_vars[0] ne '' then begin       
         options,'iug_mf_pon_uwnd',ytitle='MF-pon!CHeight!C[km]',ztitle='uwnd!C[m/s]'
      endif
      
     ;---Create tplot variables and options for meridional wind:
      store_data,'iug_mf_pon_vwnd',data={x:pon_time, y:mer_wind, v:height},dlimit=dlimit
      new_vars=tnames('iug_mf_pon_vwnd')
      if new_vars[0] ne '' then begin 
         options,'iug_mf_pon_vwnd',ytitle='MF-pon!CHeight!C[km]',ztitle='vwnd!C[m/s]'
      endif
     ;---Create tplot variables and options for vertical wind: 
      store_data,'iug_mf_pon_wwnd',data={x:pon_time, y:ver_wind, v:height},dlimit=dlimit
      new_vars=tnames('iug_mf_pon_wwnd')
      if new_vars[0] ne '' then begin 
         options,'iug_mf_pon_wwnd',ytitle='MF-pon!CHeight!C[km]',ztitle='wwnd!C[m/s]'
      endif
            
      new_vars=tnames('iug_mf_pon_*')
      if new_vars[0] ne '' then begin 
        ;---Add options
         options, ['iug_mf_pon_uwnd','iug_mf_pon_vwnd','iug_mf_pon_wwnd'], 'spec', 1
  
        ;---Add tdegap: 
         tdegap,'iug_mf_pon_uwnd',dt=240,/overwrite
         tdegap,'iug_mf_pon_vwnd',dt=240,/overwrite
         tdegap,'iug_mf_pon_wwnd',dt=240,/overwrite
      
        ;---Add tclip:  
         tclip,'iug_mf_pon_uwnd',-200,200,/overwrite
         tclip,'iug_mf_pon_vwnd',-200,200,/overwrite
         tclip,'iug_mf_pon_wwnd',-200,200,/overwrite
      
        ;---Add zlim:
         zlim,'iug_mf_pon_uwnd',-100,100
         zlim,'iug_mf_pon_vwnd',-100,100
         zlim,'iug_mf_pon_wwnd',-100,100
      endif
   endif 
  
  ;---Clear data and time buffer
   pon_time=0
   zon_wind=0
   mer_wind=0
   ver_wind=0
endif

new_vars=tnames('iug_mf_pon_*')
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
print, 'Note: If you would like to use following data for scientific purpose,
print, 'please read and follow the DATA USE POLICY'
print, '(http://database.rish.kyoto-u.ac.jp/arch/iugonet/data_policy/Data_Use_Policy_e.html' 
print, 'The distribution of MF radar data has been partly supported by the IUGONET'
print, '(Inter-university Upper atmosphere Global Observation NETwork) project'
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, Sports, Science'
print, 'and Technology (MEXT), Japan.' 

end
