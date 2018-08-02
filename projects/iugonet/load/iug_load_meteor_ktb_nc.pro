;+
;
;NAME:
;iug_load_meteor_ktb_nc
;
;PURPOSE:
;  Queries the RISH servers for the meteor data (netCDF format) taken by 
;  the meteor wind radar (MWR) at Kototabang and loads data into tplot format.
;
;SYNTAX:
; iug_load_meteor_ktb_nc, parameter = parameter, length = length, downloadonly = downloadonly, $
;                           trange = trange, verbose=verbose
;
;KEYWOARDS:
;  LENGTH = Data length '1-day' or '1-month'. For example, iug_load_meteor_ktb_nc, length = '1_day'.
;           A kind of parameters is 2 types of '1_day', and '1_month'.  
; PARAMETER = Data parameter. For example, iug_load_meteor_ktb_nc, parameter = 'h2t60min00'. 
;             A kind of parameters is 4 types of 'h2t60min00', 'h2t60min00', 'h4t60min00', 'h4t60min00'.
;             The default is 'all'.
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
; A. Shinbori, 11/07/2011.
; A. Shinbori, 06/10/2011.
; A. Shinbori, 27/12/2011.
; A. Shinbori, 31/01/2012.
; A. Shinbori, 28/05/2012.
; A. Shinbori, 12/06/2012.
; A. Shinbori, 25/07/2012.
; A. Shinbori, 18/12/2012.
; A. Shinbori, 24/01/2014.
;   
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_meteor_ktb_nc, parameter = parameter, $
   length=length, $
   downloadonly = downloadonly, $
   trange = trange, $
   verbose = verbose

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2

;*****************************
;Load '1_day' data by default:
;*****************************
if (not keyword_set(length)) then length='1_day'

;****************
;Parameter check:
;****************

;--- all parameters (default)
parameter_all = strsplit('h2t60min00 h2t60min30 h4t60min00 h4t60min30 h4t240min00',' ', /extract)

;--- check parameters
if (not keyword_set(parameter)) then parameter='all'
parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters

;************************************
;Data directory and last names check:
;************************************

site_data_dir=strarr(n_elements(parameters))
site_data_lastmane=strarr(n_elements(parameters))

for i=0, n_elements(site_data_dir)-1 do begin
   site_data_dir[i]=strmid(parameters[i],0,2)+'km_'+strmid(parameters[i],2,strlen(parameters[i])-2)+'/'
   site_data_lastmane[i]=parameters[i]
endfor

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
for iii=0L,n_elements(parameters)-1 do begin   
   if ~size(fns,/type) then begin
     ;****************************
     ;Get files for ith component:
     ;****************************     
      case length of
         '1_day':file_names = file_dailynames(file_format='YYYY/Wk'+$
                      'YYYYMMDD',trange=trange,times=times,/unique)+'.'+site_data_lastmane[iii]+'.nc'
         '1_month':file_names = file_dailynames(file_format='YYYY/Wk'+$
                      'YYYYMM',trange=trange,times=times,/unique)+'.'+site_data_lastmane[iii]+'.nc'
      endcase
      
     ;===============================        
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/ktb/meteor/nc/ver1_1_2/'+length+'/'+site_data_dir[iii]
      source.remote_data_dir = 'http://database.rish.kyoto-u.ac.jp/arch/iugonet/data/mwr/kototabang/nc/ver1_1_2/'+site_data_dir[iii]

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

     ;---Definition time and parameters:
      site_time=0
      zon_wind=0
      mer_wind=0
      zon_thermal=0
      mer_thermal=0
      meteor_num=0    
   
     ;======================================
     ;Loop on files (read the NetCDF files): 
     ;======================================
      for j=jj,n_elements(local_paths)-1 do begin
         file= local_paths[j]
         if file_test(/regular,file) then  dprint,'Loading the wind data estimated from the MWR at Kototabang: ',file $
         else begin
            dprint,'The wind data estimated from the MWR at Kototabang',file,'not found. Skipping'
            continue
         endelse
    
         cdfid = ncdf_open(file,/NOWRITE)  ; Open the file
         glob = ncdf_inquire( cdfid )    ; Find out general info

        ;---Show user the size of each dimension
         print,'Dimensions', glob.ndims
         for i=0L,glob.ndims-1 do begin
            ncdf_diminq, cdfid, i, name,size
            if i eq glob.recdim then  $
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
          
        ;---Get the time infomation:
         time_info=strsplit(time_data,' ',/extract)
         syymmdd=time_info[2]
         shhmmss=time_info[3]
         time_diff=strsplit(time_info[4],':',/extract)
         time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60   
          
        ;---Get the variable
         ncdf_varget, cdfid, 'time', time
         ncdf_varget, cdfid, 'range', range
         ncdf_varget, cdfid, 'uwind', uwind
         ncdf_varget, cdfid, 'vwind', vwind
         ncdf_varget, cdfid, 'sig_uwind', sig_uwind
         ncdf_varget, cdfid, 'sig_vwind', sig_vwind
         ncdf_varget, cdfid, 'num', num

        ;---Definition of arrary names
         unix_time = dblarr(n_elements(time))
         height=fltarr(n_elements(range))
         uwind_data=fltarr(n_elements(time),n_elements(range))
         vwind_data=fltarr(n_elements(time),n_elements(range))
         sig_uwind_data=fltarr(n_elements(time),n_elements(range))
         sig_vwind_data=fltarr(n_elements(time),n_elements(range))
         num_data=fltarr(n_elements(time),n_elements(range))
         
         for i=0L, n_elements(time)-1 do begin
          
           ;---Change hours since midnight of the first day of every month (Universal Time) into unixtime (1970-01-01 00:00:00)
            unix_time[i] = double(time[i])*3600 +time_double(syymmdd+'/'+shhmmss)-time_diff2
           
            uwind_data[i,*]=uwind[0,*,i]
            vwind_data[i,*]=vwind[0,*,i]
            sig_uwind_data[i,*]=sig_uwind[0,*,i]
            sig_vwind_data[i,*]=sig_vwind[0,*,i]
            num_data[i,*]=num[0,*,i]
            height= range/1000 ;m -> km
                  
           ;---Replace missing value by NaN
            a = uwind_data[i,*]            
            wbad = where(a eq -9999,nbad)
            if nbad gt 0 then a[wbad] = !values.f_nan
            uwind_data[i,*] =a
            b = vwind_data[i,*]            
            wbad = where(b eq -9999,nbad)
            if nbad gt 0 then b[wbad] = !values.f_nan
            vwind_data[i,*] =b
            c = sig_uwind_data[i,*]            
            wbad = where(c eq -9999,nbad)
            if nbad gt 0 then c[wbad] = !values.f_nan
            sig_uwind_data[i,*] =c
            d = sig_vwind_data[i,*]            
            wbad = where(d eq -9999,nbad)
            if nbad gt 0 then d[wbad] = !values.f_nan
            sig_vwind_data[i,*] =d
            e = num_data[i,*]            
            wbad = where(e eq -9999,nbad)
            if nbad gt 0 then e[wbad] = !values.f_nan
            num_data[i,*] =e
         endfor
         
        ;=============================================
        ;Append array of time and meteor observations:
        ;=============================================
         append_array, site_time, unix_time
         append_array, zon_wind, uwind_data
         append_array, mer_wind, vwind_data
         append_array, zon_thermal, sig_uwind_data
         append_array, mer_thermal, sig_vwind_data
         append_array, meteor_num, num_data
         ncdf_close,cdfid  ; done
      endfor

     ;==============================
     ;Store data in TPLOT variables:
     ;==============================
     ;---Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'Note: If you would like to use following data for scientific purpose, please read and follow the DATA USE POLICY '+ $
                         '(http://database.rish.kyoto-u.ac.jp/arch/iugonet/data_policy/Data_Use_Policy_e.html '+ $ 
                         'The distribution of meteor wind radar data has been partly supported by the IUGONET (Inter-university Upper '+ $
                         'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '+ $
                         'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'
      
      if size(zon_wind,/type) eq 4 then begin
        ;---Create the tplot variable and options for zonal wind:
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Tsuda'))
         store_data,'iug_meteor_ktb_uwnd_'+parameters[iii],data={x:site_time, y:zon_wind, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_uwnd_'+parameters[iii])
         if new_vars[0] ne '' then begin      
            options,'iug_meteor_ktb_uwnd_'+parameters[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='uwnd!C[m/s]'
         endif 
         
        ;---Create the tplot variable and options for meridional wind:
         store_data,'iug_meteor_ktb_vwnd_'+parameters[iii],data={x:site_time, y:mer_wind, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_vwnd_'+parameters[iii])
         if new_vars[0] ne '' then begin     
            options,'iug_meteor_ktb_vwnd_'+parameters[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='vwnd!C[m/s]'
         endif
         
        ;---Create the tplot variable and options for standard deviation of zonal wind:
         store_data,'iug_meteor_ktb_uwndsig_'+parameters[iii],data={x:site_time, y:zon_thermal, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_uwndsig_'+parameters[iii])
         if new_vars[0] ne '' then begin
            options,'iug_meteor_ktb_uwndsig_'+parameters[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='uwndsig!C[m/s]'
         endif
         
        ;---Create the tplot variable and options for standard deviation of meridional wind:
         store_data,'iug_meteor_ktb_vwndsig_'+parameters[iii],data={x:site_time, y:mer_thermal, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_uwndsig_'+parameters[iii])
         if new_vars[0] ne '' then begin
            options,'iug_meteor_ktb_vwndsig_'+parameters[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='vwndsig!C[m/s]'        
         endif
         
        ;---Create the tplot variable and options for meteor echoes:    
         store_data,'iug_meteor_ktb_mwnum_'+parameters[iii],data={x:site_time, y:meteor_num, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_vwndsig_'+parameters[iii])
         if new_vars[0] ne '' then begin
            options,'iug_meteor_ktb_mwnum_'+parameters[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='mwnum'
         endif
      endif
      
     ;---Add options 
      new_vars=tnames('iug_meteor_ktb_*')
      if new_vars[0] ne '' then begin
         options, ['iug_meteor_ktb_uwnd_'+parameters[iii],'iug_meteor_ktb_vwnd_'+parameters[iii],$
                   'iug_meteor_ktb_uwndsig_'+parameters[iii],'iug_meteor_ktb_vwndsig_'+parameters[iii],$
                   'iug_meteor_ktb_mwnum_'+parameters[iii]], 'spec', 1
      endif
   endif
  
  ;---Clear time and data buffer:
   site_time=0
   zon_wind=0
   mer_wind=0
   zon_thermal=0
   mer_thermal=0
   meteor_num=0

   new_vars=tnames('iug_meteor_ktb_*')
   if new_vars[0] ne '' then begin   
     ;---Add tdegap
      tdegap, 'iug_meteor_ktb_uwnd_'+parameters[iii],dt=3600,/overwrite
      tdegap, 'iug_meteor_ktb_vwnd_'+parameters[iii],dt=3600,/overwrite
      tdegap, 'iug_meteor_ktb_uwndsig_'+parameters[iii],dt=3600,/overwrite
      tdegap, 'iug_meteor_ktb_vwndsig_'+parameters[iii],dt=3600,/overwrite
      tdegap, 'iug_meteor_ktb_mwnum_'+parameters[iii],dt=3600,/overwrite  
     
     ;---Add tclip
      tclip, 'iug_meteor_ktb_uwnd_'+parameters[iii],-200,200,/overwrite
      tclip, 'iug_meteor_ktb_vwnd_'+parameters[iii],-200,200,/overwrite
      tclip, 'iug_meteor_ktb_uwndsig_'+parameters[iii],0,800,/overwrite
      tclip, 'iug_meteor_ktb_vwndsig_'+parameters[iii],0,800,/overwrite
      tclip, 'iug_meteor_ktb_mwnum_'+parameters[iii],0,1200,/overwrite   
    
     ;---Add zlim
      zlim, 'iug_meteor_ktb_uwnd_*',-100,100
      zlim, 'iug_meteor_ktb_vwnd_*',-100,100
   endif
   jj=n_elements(local_paths)
endfor

new_vars=tnames('iug_meteor_ktb_*')
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
print, 'The distribution of meteor wind radar data has been partly supported by the IUGONET'
print, '(Inter-university Upper atmosphere Global Observation NETwork) project'
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, Sports, Science'
print, 'and Technology (MEXT), Japan.'
  
end

