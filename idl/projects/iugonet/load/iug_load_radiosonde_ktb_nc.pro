;+
;
;NAME:
;iug_load_radiosonde_ktb_nc
;
;PURPOSE:
;  Queries the Kyoto RISH server for the netCDF data (press, temp, rh, uwnd, vwnd) 
;  of the troposphere taken by the radiosonde at Koto Tabang 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_radiosonde_ktb_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS: 
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE, Get more detailed (higher number) command line output.
;  
;CODE:
;  A. Shinbori, 12/02/2014.
;  
;MODIFICATIONS:
;  A. Shinbori, 28/10/2014.
;   
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_radiosonde_ktb_nc, downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2


;======================
;Calculation of height:
;======================
max_height = 40000
dh=30.0
num_h= fix(40000/dh)
ht = fltarr(num_h)
for i=0, n_elements(ht)-2 do begin
   if ht[i] le 40000 then ht[i+1] = ht[i]+dh
endfor

;==================================================================
;Download files, read data, and create tplot vars at each component
;==================================================================
;******************************************************************
;Loop on downloading files
;******************************************************************
;Define FILE_NAMES, and load data:
;=================================

;---Definition of parameter and array:

if ~size(fns,/type) then begin
  ;---Definition of DAWEX radiosonde site names:
     
        
  ;****************************
  ;Get files for ith component:
  ;****************************     
   hour_res = 1  
   file_names = file_dailynames( $
                file_format='YYYY/'+$
                'YYYYMMDDhh',trange=trange,hour_res=hour_res,times=times,/unique)+'*.nc'
     
  ;===============================        
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/ktb/radiosonde/nc/'
   source.remote_data_dir = 'http://database.rish.kyoto-u.ac.jp/arch/iugonet/sonde/data/kototabang/nc/'
    
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

  ;=========================
  ;Definition of parameters:
  ;=========================
   sonde_time = 0

  ;==============
  ;Loop on files: 
  ;==============
   for j=0L,n_elements(local_paths)-1 do begin
      file= local_paths[j] 
      if file_test(/regular,file) then  dprint,'Loading Koto Tabang radiosonde file: ',file $
      else begin
         dprint,'Koto Tabang radiosonde data file',file,'not found. Skipping'
         continue
      endelse

      cdfid = ncdf_open(file,/NOWRITE)  ; Open the file
      glob = ncdf_inquire( cdfid )    ; Find out general info

     ;---Show user the size of each dimension
      print,'Dimensions', glob.ndims
      for i=0,glob.ndims-1 do begin
         ncdf_diminq, cdfid, i, name,size
         if i EQ glob.recdim then  $
            print,'    ', name, size, '(Unlimited dim)' $
         else      $
            print,'    ', name, size  
      endfor

     ;---Now tell user about the variables
      print
      print, 'Variables'
      for m=0,glob.nvars-1 do begin

        ;---Get information about the variable
         info = ncdf_varinq(cdfid, m)
         FmtStr = '(A," (",A," ) Dimension Ids = [ ", 10(I0," "),$)'
         print, FORMAT=FmtStr, info.name,info.datatype, info.dim[*]
         print, ']'

        ;---Get attributes associated with the variable
         for l=0,info.natts-1 do begin
            attname = ncdf_attname(cdfid,m,l)
            ncdf_attget,cdfid,m,attname,attvalue
            print,' Attribute ', attname, '=', string(attvalue)
            if (info.name eq 'Launching_time') and (attname eq 'units') then time_data=string(attvalue)
         endfor
      endfor

     ;---Calculation the start time infomation from the attribute data:
      time_info=strsplit(time_data,' ',/extract)
      time_units = time_info[0]
      syymmdd=time_info[2]
      shhmmss=time_info[3]
      stime = time_double(syymmdd+'/'+shhmmss)
      time_diff=strsplit(time_info[3],':',/extract)
      time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60 
     
      if time_units eq 'seconds' then dt = 1.0
      if time_units eq 'minutes' then dt = 60.0
      if time_units eq 'hours' then dt = 3600.0
         
     ;---Get the variable
      ncdf_varget, cdfid, 'lat', lat
      ncdf_varget, cdfid, 'lon', lon
      ncdf_varget, cdfid, 'height', height
      ncdf_varget, cdfid, 'Launching_time', time
      ncdf_varget, cdfid, 'press', press
      ncdf_varget, cdfid, 'temperature', temperature
      ncdf_varget, cdfid, 'relative_humidity', relative_humidity
      ncdf_varget, cdfid, 'uwind', uwind
      ncdf_varget, cdfid, 'vwind', vwind
      
      ncdf_close,cdfid  ; done

     ;---Definition of parameters and arraies:
      h_num= 0
      press2 = fltarr(1,n_elements(ht))+!values.f_nan
      temp2 = fltarr(1,n_elements(ht))+!values.f_nan
      rh2 = fltarr(1,n_elements(ht))+!values.f_nan
      uwind2 = fltarr(1,n_elements(ht))+!values.f_nan
      vwind2 = fltarr(1,n_elements(ht))+!values.f_nan
               
     ;---Replace missing number by NaN
      for i=0, n_elements(height)-1 do begin
         a = press[i]            
         wbad = where(a eq -999.00,nbad)
         if nbad gt 0 then a[wbad] = !values.f_nan
         press[i] =a 
         b = temperature[i]            
         wbad = where(b eq -999.00,nbad)
         if nbad gt 0 then b[wbad] = !values.f_nan
         temperature[i] =b 
         c = relative_humidity[i]            
         wbad = where(c eq -999.00,nbad)
         if nbad gt 0 then c[wbad] = !values.f_nan
         relative_humidity[i] =c 
         d = uwind[i]            
         wbad = where(d eq -999.00,nbad)
         if nbad gt 0 then d[wbad] = !values.f_nan
         uwind[i] =d 
         e = vwind[i]            
         wbad = where(e eq -999.00,nbad)
         if nbad gt 0 then e[wbad] = !values.f_nan
         vwind[i] =e 
      endfor


      for i=0, n_elements(ht)-1 do begin
         idx = where((height ge ht[i]-dh/2.0) and (height lt ht[i]+dh/2.0),cnt)
         if idx[0] ne -1 then begin
            press2[0,i]=mean(press[idx],/NAN)
            temp2[0,i]=mean(temperature[idx],/NAN)
            rh2[0,i]=mean(relative_humidity[idx],/NAN)
            uwind2[0,i]=mean(uwind[idx],/NAN)
            vwind2[0,i]=mean(vwind[idx],/NAN)
         endif
      endfor
      
     ;=====================
     ;Append time and data:
     ;=====================
      append_array, sonde_time, time+stime
      append_array, sonde_press, press2
      append_array, sonde_temp, temp2
      append_array, sonde_rh, rh2
      append_array, sonde_uwind, uwind2
      append_array, sonde_vwind, vwind2

     ;---Clear Buffer:
      time=0
      time_data=0
      height_data=0
      press=0
      temp=0
      rh=0
      uwind=0
      vwind=0
      lat_data=0
      lon_data=0 
      
   endfor
      
  ;==============================
  ;Store data in TPLOT variables:
  ;==============================
  ;---Acknowlegment string (use for creating tplot vars)
   acknowledgstring = 'If you acquire the radiosonde data, we ask that you' $
                    + 'acknowledge us in your use of the data. This may be done by' $
                    + 'including text such as the radiosonde data provided by Research Institute' $
                    + 'for Sustainable Humanosphere of Kyoto University. We would also' $
                    + 'appreciate receiving a copy of the relevant publications. The distribution of radiosonde data' $
                    + 'has been partly supported by the IUGONET (Inter-university Upper atmosphere Global' $
                    + 'Observation NETwork) project (http://www.iugonet.org/) funded by the' $
                    + 'Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'
                       
   if size(sonde_press,/type) eq 4 then begin 
     ;---Create tplot variables and options
      dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'H. Hashiguchi'))
      store_data,'iug_radiosonde_ktb_press',data={x:sonde_time, y:sonde_press, v:ht/1000.0},dlimit=dlimit
      options,'iug_radiosonde_ktb_press',ytitle='RSND-ktb!CHeight!C[km]',ztitle='Press.!C[hPa]'
      store_data,'iug_radiosonde_ktb_temp',data={x:sonde_time, y:sonde_temp, v:ht/1000.0},dlimit=dlimit
      options,'iug_radiosonde_ktb_temp',ytitle='RSND-ktb!CHeight!C[km]',ztitle='Temp.!C[deg.]'
      store_data,'iug_radiosonde_ktb_rh',data={x:sonde_time, y:sonde_rh, v:ht/1000.0},dlimit=dlimit
      options,'iug_radiosonde_ktb_rh',ytitle='RSND-ktb!CHeight!C[km]',ztitle='RH!C[%]'
      store_data,'iug_radiosonde_ktb_uwnd',data={x:sonde_time, y:sonde_uwind, v:ht/1000.0},dlimit=dlimit
      options,'iug_radiosonde_ktb_uwnd',ytitle='RSND-ktb!CHeight!C[km]',ztitle='uwnd!C[m/s]'
      store_data,'iug_radiosonde_ktb_vwnd',data={x:sonde_time, y:sonde_vwind, v:ht/1000.0},dlimit=dlimit
      options,'iug_radiosonde_ktb_vwnd',ytitle='RSND-ktb!CHeight!C[km]',ztitle='vwnd!C[m/s]'
      options, ['iug_radiosonde_ktb_press','iug_radiosonde_ktb_temp',$
                'iug_radiosonde_ktb_rh','iug_radiosonde_ktb_dewp',$
                'iug_radiosonde_ktb_uwnd','iug_radiosonde_ktb_vwnd'], 'spec', 1
   endif

  ;---Clear time and data buffer:
   sonde_time = 0
   sonde_press = 0
   sonde_temp = 0
   sonde_rh = 0
   sonde_dewp = 0
   sonde_uwind = 0
   sonde_vwind = 0
       
  ;---Add tdegap and zlim
   new_vars=tnames('iug_radiosonde_*')
   if new_vars[0] ne '' then begin  
      dt = 10800
      tdegap, 'iug_radiosonde_ktb_press',dt=10800*2,/overwrite
      tdegap, 'iug_radiosonde_ktb_temp',dt=10800*2,/overwrite
      tdegap, 'iug_radiosonde_ktb_rh',dt=10800*2,/overwrite
      tdegap, 'iug_radiosonde_ktb_uwnd',dt=10800*2,/overwrite
      tdegap, 'iug_radiosonde_ktb_vwnd',dt=10800*2,/overwrite
      zlim,'iug_radiosonde_ktb_uwnd',-40,40
      zlim,'iug_radiosonde_ktb_vwnd',-20,20
   endif
endif


new_vars=tnames('iug_radiosonde_*')
if new_vars[0] ne '' then begin    
   print,'*****************************
   print,'Data loading is successful!!'
   print,'*****************************
endif

;**************************
;Print of acknowledgement:
;**************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire the radiosonde data, we ask that you acknowledge'
print, 'us in your use of the data. This may be done by including text such as' 
print, 'radiosonde data provided by Research Institute for Sustainable Humanosphere' 
print, 'of Kyoto University. We would also appreciate receiving a copy of the' 
print, 'relevant publications. The distribution of radiosonde data has been partly'
print, 'supported by the IUGONET (Inter-university Upper atmosphere Global'
print, 'Observation NETwork) project (http://www.iugonet.org/) funded by the'
print, 'Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'

end
