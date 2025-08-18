;+
;
;NAME:
;iug_load_mu_meteor_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the horizontal wind data (uwnd, vwnd, uwndsig, vwndsig, mwnum)
;  in the text format estimated from the meteor wind special observation of the MU radar at Shigaraki
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_meteor_txt, parameter = parameter, length=length, downloadonly = downloadonly, $
;                          trange = trange, verbose=verbose
;
;KEYWOARDS:
;  LENGTH = Data length '1-day' or '1-month'. For example, iug_load_mu_meteor_nc, length = '1_day'.
;           A kind of parameters is 2 types of '1_day', and '1_month'. 
;  PARAMETER = Data parameter. For example, iug_load_mu_meteor_txt, parameter = 'h1t60min00'. 
;              A kind of parameters is 2 types of 'h1t60min00' and 'h1t30min00'.
;              The default is 'all'.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
;  
;CODE:
; A. Shinbori, 10/06/2010.
;
;MODIFICATIONS:
; A. Shinbori, 13/11/2011.
; A. Shinbori, 08/08/2012.
; A. Shinbori, 12/11/2012.
; A. Shinbori, 24/12/2012.
; A. Shinbori, 15/04/2013.
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

pro iug_load_mu_meteor_txt, parameter = parameter, $
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
parameter_all = strsplit('h1t60min00 h1t60min30 h2t60min00 h2t60min30',' ', /extract)

;--- check parameters
if(not keyword_set(parameter)) then parameter='all'
parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters

;************************************
;Data directory and last names check:
;************************************

site_data_dir=strarr(n_elements(parameters))
site_data_lastmane=strarr(n_elements(parameters))

for i=0L, n_elements(site_data_dir)-1 do begin
   site_data_dir[i]=strmid(parameters[i],0,2)+'km_'+strmid(parameters[i],2,strlen(parameters[i])-2)+'/'
   site_data_lastmane[i]=parameters[i]
endfor

;**************************
;Loop on downloading files:
;**************************
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
jj=0L
for iii=0L,n_elements(parameters)-1 do begin
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
      case length of
         '1_day':file_names = file_dailynames(file_format='YYYY/W'+$
                      'YYYYMMDD',trange=trange,times=times,/unique)+'.'+site_data_lastmane[iii]+'.txt'
         '1_month':file_names = file_dailynames(file_format='YYYY/W'+$
                      'YYYYMM',trange=trange,times=times,/unique)+'.'+site_data_lastmane[iii]+'.txt'
      endcase
     
     ;===============================        
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/sgk/mu/meteor/text/'+length+'/'+site_data_dir[iii]
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/meteor/data/text/'+length+'/'+site_data_dir[iii]
    
     ;=======================================================    
     ;Get files and local paths, and concatenate local paths:
     ;=======================================================
      local_paths = spd_download(remote_file=file_names, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)
      local_paths_all = ~(~size(local_paths_all,/type)) ? $
                       [local_paths_all, local_paths] : local_paths
      if ~(~size(local_paths_all,/type)) then local_paths=local_paths_all
   endif else file_names=fns

    ;--- Load data into tplot variables
    if(not keyword_set(downloadonly)) then downloadonly=0

    if(downloadonly eq 0) then begin
     ;===============
     ;Read the files:
     ;===============   
     ;---Definition of string variable:
      s=''
     
     ;---Determination of array number, height and time invervals:   
      if (site_data_lastmane[iii] eq 'h1t60min00') or (site_data_lastmane[iii] eq 'h1t60min30') then begin
         arr_num=41
         dh=1
      endif
      if (site_data_lastmane[iii] eq 'h2t60min00') or (site_data_lastmane[iii] eq 'h2t60min30') then begin
         arr_num=21
         dh=2
      endif     
         
     ;---Definition of array and its number:
      height = fltarr(arr_num)
      zon_wind_data = fltarr(1,arr_num)
      mer_wind_data = fltarr(1,arr_num)
      zon_thermal_data = fltarr(1,arr_num)
      mer_thermal_data = fltarr(1,arr_num)
      meteor_num_data = fltarr(1,arr_num)
      ktb_time = 0
      time = 0
      time_val = 0
      
      ;==============
      ;Loop on files: 
      ;==============
      for j=jj,n_elements(local_paths)-1 do begin
         file= local_paths[j] 
         if file_test(/regular,file) then  dprint,'Loading MU meteor data file: ',file $
         else begin
            dprint,'MU meteor data file',file,' not found. Skipping'
            continue
         endelse
        
        ;---Open read file:
         openr,lun,file,/get_lun    
        
        ;==================
        ;Loop on read data:
        ;==================
         n=0
         while(not eof(lun)) do begin
            readf,lun,s
            ok=1
            if strmid(s,0,1) eq '[' then ok=0
            if ok && keyword_set(s) then begin
               dprint,s ,dlevel=5
             
              ;---Get date and time information:
               if fix(strmid(s,0,2)) gt 70 then year = fix(strmid(s,0,2))+1900
               if fix(strmid(s,0,2)) lt 70 then year = fix(strmid(s,0,2))+2000
               day_of_year = fix(strmid(s,2,3))
               doy_to_month_date, year, day_of_year, month, day
               hour = strmid(s,5,2)
               minute = strmid(s,7,2)
              
              ;==================
              ;Get altitude data:
              ;==================
               alt = fix(strmid(s,9,3))
               idx = (alt-70)/dh
              
              ;======================================================= 
              ;Get data of U, V, sigma-u, sigma-v, N-of-m, int1, int2:
              ;=======================================================
               data =  float(strsplit(strmid(s,12,55), ' ', /extract))

              ;---Convert time from universal time to unix time   
               time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+string(hour)+':'+string(minute))  $                              
                      -time_double(string(1970)+'-'+string(1)+'-'+string(1)+'/'+string(09)+':'+string(00)+':'+string(00))
              
              ;---Insert data of zonal and meridional winds etc.
               if n eq 0 then begin
                  time_val3 = time
                  zon_wind_data[0,idx]= data[0]
                  mer_wind_data[0,idx]= data[1]
                  zon_thermal_data[0,idx]= data[2]
                  mer_thermal_data[0,idx]= data[3]
                  meteor_num_data[0,idx]= data[4]
               endif
               time_diff=time-time_val
               if n eq 0 then time_diff=3600
              
              ;===============================================================
              ;Appned array of time and data if time_val is not equal to time:
              ;===============================================================
               if time_val ne time then begin
                  time_val=time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+string(hour)+':'+string(minute)) $
                           -time_double(string(1970)+'-'+string(1)+'-'+string(1)+'/'+string(09)+':'+string(00)+':'+string(00))          
                  time_val2=time_val-time_diff
                  if time_val2 eq 0 then time_val2=time_val+3600
                
                 ;==============================
                 ;Append array of time and data:
                 ;==============================
                  if n ne 0 then begin
                     append_array, site_time, time_val2
                     append_array, zon_wind, zon_wind_data
                     append_array, mer_wind, mer_wind_data
                     append_array, zon_thermal, zon_thermal_data
                     append_array, mer_thermal, mer_thermal_data
                     append_array, meteor_num, meteor_num_data
                  endif
                  n=n+1
                  for i=0L, arr_num-1 do begin
                     zon_wind_data[0,i]=!values.f_nan
                     mer_wind_data[0,i]=!values.f_nan
                     zon_thermal_data[0,i]=!values.f_nan
                     mer_thermal_data[0,i]=!values.f_nan
                     meteor_num_data[0,i]=!values.f_nan 
                  endfor 
               endif                
               zon_wind_data[0,idx]= data[0]
               mer_wind_data[0,idx]= data[1]
               zon_thermal_data[0,idx]= data[2]
               mer_thermal_data[0,idx]= data[3]
               meteor_num_data[0,idx]= data[4]            
            endif           
         endwhile 
         free_lun,lun
        
        ;==============================
        ;Append array of time and data:
        ;==============================
         append_array, mu_time, time_val2+3600
         append_array, zon_wind, zon_wind_data
         append_array, mer_wind, mer_wind_data
         append_array, zon_thermal, zon_thermal_data
         append_array, mer_thermal, mer_thermal_data
         append_array, meteor_num, meteor_num_data

        ;==============================
        ;Append array of time and data:
        ;==============================
         append_array, site_time, mu_time
         append_array, zon_wind2, zon_wind
         append_array, mer_wind2, mer_wind
         append_array, zon_thermal2, zon_thermal
         append_array, mer_thermal2, mer_thermal
         append_array, meteor_num2, meteor_num

        ;================================================
        ;Initiarizatin of old parameters (time and data):
        ;================================================                            
         mu_time=0
         zon_wind=0
         mer_wind=0
         zon_thermal=0
         mer_thermal=0
         meteor_num=0             
      endfor       
      
      for g=0L,arr_num-1 do begin         
         height[g]=float(70+g*dh) 
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
                       + 'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded ' $
                       + 'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'

      if size(zon_wind2,/type) eq 4 then begin
        ;---Create tplot variable and add options for zonal wind:
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Nakamura'))
         store_data,'iug_mu_meteor_uwnd_'+parameters[iii],data={x:site_time, y:zon_wind2, v:height},dlimit=dlimit

        ;----Edge data cut:
         time_clip,'iug_mu_meteor_uwnd_'+parameters[iii], init_time2[0], init_time2[1], newname = 'iug_mu_meteor_uwnd_'+parameters[iii]
         options,'iug_mu_meteor_uwnd_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='uwnd!C[m/s]'
         
        ;---Create tplot variable and add options for meridional wind:
         store_data,'iug_mu_meteor_vwnd_'+parameters[iii],data={x:site_time, y:mer_wind2, v:height},dlimit=dlimit

        ;----Edge data cut:
         time_clip,'iug_mu_meteor_vwnd_'+parameters[iii], init_time2[0], init_time2[1], newname = 'iug_mu_meteor_vwnd_'+parameters[iii]
         options,'iug_mu_meteor_vwnd_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='vwnd!C[m/s]'
         
        ;---Create tplot variable and add options for standard deviation of zonal wind:
         store_data,'iug_mu_meteor_uwndsig_'+parameters[iii],data={x:site_time, y:zon_thermal2, v:height},dlimit=dlimit

        ;----Edge data cut:
         time_clip,'iug_mu_meteor_uwndsig_'+parameters[iii], init_time2[0], init_time2[1], newname = 'iug_mu_meteor_uwndsig_'+parameters[iii]
         options,'iug_mu_meteor_uwndsig_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='uwndsig!C[m/s]'
        
        ;---Create tplot variable and add options for standard deviation of meridional wind:
         store_data,'iug_mu_meteor_vwndsig_'+parameters[iii],data={x:site_time, y:mer_thermal2, v:height},dlimit=dlimit
  
        ;----Edge data cut:
         time_clip,'iug_mu_meteor_vwndsig_'+parameters[iii], init_time2[0], init_time2[1], newname = 'iug_mu_meteor_vwndsig_'+parameters[iii]
         options,'iug_mu_meteor_vwndsig_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='vwndsig!C[m/s]'
         
        ;---Create tplot variable and add options for meteor echoes:
         store_data,'iug_mu_meteor_mwnum_'+parameters[iii],data={x:site_time, y:meteor_num2, v:height},dlimit=dlimit
         
        ;----Edge data cut:
         time_clip,'iug_mu_meteor_mwnum_'+parameters[iii], init_time2[0], init_time2[1], newname = 'iug_mu_meteor_mwnum_'+parameters[iii] 
         options,'iug_mu_meteor_mwnum_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='mwnum'

        ;---Add options
         new_vars=tnames('iug_mu_meteor_*')
         if new_vars[0] ne '' then begin
            options, ['iug_mu_meteor_uwnd_'+parameters[iii],'iug_mu_meteor_vwnd_'+parameters[iii],$
                      'iug_mu_meteor_uwndsig_'+parameters[iii],'iug_mu_meteor_vwndsig_'+parameters[iii],$
                      'iug_mu_meteor_mwnum_'+parameters[iii]], 'spec', 1
         endif
      endif
  
     ;---Clear time and data buffer:
      site_time=0
      zon_wind=0
      mer_wind=0
      zon_thermal=0
      mer_thermal=0
      meteor_num=0

      new_vars=tnames('iug_mu_meteor_*')
      if new_vars[0] ne '' then begin    
        ;---Add tdegap
         tdegap, 'iug_mu_meteor_uwnd_'+parameters[iii],dt=3600,/overwrite
         tdegap, 'iug_mu_meteor_vwnd_'+parameters[iii],dt=3600,/overwrite
         tdegap, 'iug_mu_meteor_uwndsig_'+parameters[iii],dt=3600,/overwrite
         tdegap, 'iug_mu_meteor_vwndsig_'+parameters[iii],dt=3600,/overwrite
         tdegap, 'iug_mu_meteor_mwnum_'+parameters[iii],dt=3600,/overwrite
   
        ;---Add tclip
         tclip, 'iug_mu_meteor_uwnd_'+parameters[iii],-400,400,/overwrite
         tclip, 'iug_mu_meteor_vwnd_'+parameters[iii],-400,400,/overwrite
         tclip, 'iug_mu_meteor_uwndsig_'+parameters[iii],0,800,/overwrite
         tclip, 'iug_mu_meteor_vwndsig_'+parameters[iii],0,800,/overwrite
         tclip, 'iug_mu_meteor_mwnum_'+parameters[iii],0,1200,/overwrite  
      endif
   endif
   jj=n_elements(local_paths)
  ;---Initialization of timespan for parameters:
   timespan, time_org
endfor

new_vars=tnames('iug_mu_meteor_*')
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
