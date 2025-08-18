;+
;
;NAME:
;iug_load_meteor_ktb_txt
;
;PURPOSE:
;  Queries the RISH servers for the meteor observation data (text format) taken by 
;  the meteor wind radar (MWR) at Kototabang and loads data into tplot format.
;
;SYNTAX:
; iug_load_meteor_ktb_txt, parameter = parameter, length = length, downloadonly = downloadonly, $
;                           trange = trange, verbose=verbose
;
;KEYWOARDS:
;  LENGTH = Data length '1-day' or '1-month'. For example, iug_load_meteor_ktb_txt, length = '1_day'.
;           A kind of parameters is 2 types of '1_day', and '1_month'. 
;  PARAMETER = Data parameter. For example, iug_load_meteor_ktb_txt, parameter = 'h2t60min00'. 
;              A kind of parameters is 4 types of 'h2t60min00', 'h2t60min00', 'h4t60min00', 'h4t60min00'.
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
; A. Shinbori, 19/09/2010.
;
;MODIFICATIONS:
; A. Shinbori, 24/03/2011.
; A. Shinbori, 11/07/2011.
; A. Shinbori, 06/10/2011.
; A. Shinbori, 27/12/2011.
; A. Shinbori, 31/01/2012.
; A. Shinbori, 07/02/2012.
; A. Shinbori, 28/05/2012.
; A. Shinbori, 12/06/2012.
; A. Shinbori, 18/12/2012.
; A. Shinbori, 24/01/2014.
;   
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_meteor_ktb_txt, length = length, $
  parameter = parameter, $
  downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

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

for i=0L, n_elements(site_data_dir)-1 do begin
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
h=0L
jj=0L
for iii=0L,n_elements(parameters)-1 do begin
   if ~size(fns,/type) then begin
     ;****************************
     ;Get files for ith component:
     ;**************************** 
      case length of
         '1_day':file_names = file_dailynames(file_format='YYYY/Wk'+$
                     'YYYYMMDD',trange=trange,times=times,/unique)+'.'+site_data_lastmane[iii]+'.txt'
         '1_month':file_names = file_dailynames(file_format='YYYY/Wk'+$
                     'YYYYMM',trange=trange,times=times,/unique)+'.'+site_data_lastmane[iii]+'.txt'
      endcase
      
     ;===============================        
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/ktb/meteor/text/ver1_1_1/'+length+'/'+site_data_dir[iii]
      source.remote_data_dir = 'http://database.rish.kyoto-u.ac.jp/arch/iugonet/data/mwr/kototabang/text/ver1_1_1/'+site_data_dir[iii]
    
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
     ;===============
     ;Read the files:
     ;===============       
     ;---Definition of string variable:
      s=''
     
     ;---Determination of array number, height and time invervals:   
      if (site_data_lastmane[iii] eq 'h2t60min00') or (site_data_lastmane[iii] eq 'h2t60min30') then begin
         arr_num=21
         dh=2
      endif
      if (site_data_lastmane[iii] eq 'h4t60min00') or (site_data_lastmane[iii] eq 'h4t60min30') $
         or (site_data_lastmane[iii] eq 'h4t240min00')then begin
         arr_num=11
         dh=4
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
         if file_test(/regular,file) then  dprint,'Loading meteor radar data file: ',file $
         else begin
            dprint,'Meteor radar data file',file,' not found. Skipping'
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
               time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+string(hour)+':'+string(minute))                                
                
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
              ;============================================================= 
              ;Appned time and meteor data if time_val is not equal to time:
              ;=============================================================
               if time_val ne time then begin
                  time_val=time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+string(hour)+':'+string(minute)) $
                           -time_double(string(1970)+'-'+string(1)+'-'+string(1)+'/'+string(0)+':'+string(0)+':'+string(0))          
                  time_val2=time_val-time_diff
                  if time_val2 eq 0 then time_val2=time_val+3600
                 ;============================================================
                 ;Append array of time and meteor data at determined altitude:
                 ;============================================================
                  if n ne 0 then begin
                     append_array, site_time, time_val2
                     append_array, zon_wind, zon_wind_data
                     append_array, mer_wind, mer_wind_data
                     append_array, zon_thermal, zon_thermal_data
                     append_array, mer_thermal, mer_thermal_data
                     append_array, meteor_num, meteor_num_data
                  endif
                  n=n+1
                  for i=0, arr_num-1 do begin
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
        
        ;==================================================================
        ;Append data of time and meteor data at the last time in each file:
        ;==================================================================
         append_array, site_time, time_val2+3600
         append_array, zon_wind, zon_wind_data
         append_array, mer_wind, mer_wind_data
         append_array, zon_thermal, zon_thermal_data
         append_array, mer_thermal, mer_thermal_data
         append_array, meteor_num, meteor_num_data

        ;=================================================
        ;Append data of time and meteor data of each file:
        ;=================================================
         append_array, ktb_time, site_time
         append_array, zon_wind2, zon_wind
         append_array, mer_wind2, mer_wind
         append_array, zon_thermal2, zon_thermal
         append_array, mer_thermal2, mer_thermal
         append_array, meteor_num2, meteor_num

        ;=====================================================
        ;Initiarizatin of old parameters (time and wind data):
        ;=====================================================                            
         site_time=0
         zon_wind=0
         mer_wind=0
         zon_thermal=0
         mer_thermal=0
         meteor_num=0             
      endfor       
      for g=0L,arr_num-1 do begin         
         height[g]=float(70+g*dh) 
      endfor
   
     ;==============================
     ;Store data in TPLOT variables:
     ;==============================
     ;---Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'Note: If you would like to use following data for scientific purpose, please read and keep the DATA USE POLICY '+ $
                         '(http://database.rish.kyoto-u.ac.jp/arch/iugonet/data_policy/Data_Use_Policy_e.html '+ $ 
                         'The distribution of meteor wind radar data has been partly supported by the IUGONET (Inter-university Upper '+ $
                         'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '+ $
                         'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'

      if size(zon_wind2,/type) eq 4 then begin
        ;---Create the tplot variable and options for zonal wind:
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Tsuda'))
         store_data,'iug_meteor_ktb_uwnd_'+site_data_lastmane[iii],data={x:ktb_time, y:zon_wind2, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_uwnd_'+site_data_lastmane[iii])
         if new_vars[0] ne '' then begin  
            options,'iug_meteor_ktb_uwnd_'+site_data_lastmane[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='uwnd!C[m/s]'
         endif
         
        ;---Create the tplot variable and options for meridional wind:
         store_data,'iug_meteor_ktb_vwnd_'+site_data_lastmane[iii],data={x:ktb_time, y:mer_wind2, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_vwnd_'+site_data_lastmane[iii])
         if new_vars[0] ne '' then begin           
            options,'iug_meteor_ktb_vwnd_'+site_data_lastmane[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='vwnd!C[m/s]'
         endif
         
        ;---Create the tplot variable and options for standard deviation of zonal wind: 
         store_data,'iug_meteor_ktb_uwndsig_'+site_data_lastmane[iii],data={x:ktb_time, y:zon_thermal2, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_uwndsig_'+site_data_lastmane[iii])
         if new_vars[0] ne '' then begin
            options,'iug_meteor_ktb_uwndsig_'+site_data_lastmane[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='uwndsig!C[m/s]'
         endif
         
        ;---Create the tplot variable and options for standard deviation of meridional wind:    
         store_data,'iug_meteor_ktb_vwndsig_'+site_data_lastmane[iii],data={x:ktb_time, y:mer_thermal2, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_vwndsig_'+site_data_lastmane[iii])
         if new_vars[0] ne '' then begin          
            options,'iug_meteor_ktb_vwndsig_'+site_data_lastmane[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='vwndsig!C[m/s]'
         endif
         
        ;---Create the tplot variable and options for meteor echoes:       
         store_data,'iug_meteor_ktb_mwnum_'+site_data_lastmane[iii],data={x:ktb_time, y:meteor_num2, v:height},dlimit=dlimit
         new_vars=tnames('iug_meteor_ktb_mwnum_'+site_data_lastmane[iii])
         if new_vars[0] ne '' then begin
            options,'iug_meteor_ktb_mwnum_'+site_data_lastmane[iii],ytitle='MW-ktb!CHeight!C[km]',ztitle='mwnum'
         endif
      endif     
     
     ;---Add options  
      new_vars=tnames('iug_meteor_ktb_*')
      if new_vars[0] ne '' then begin
         options, ['iug_meteor_ktb_uwnd_'+site_data_lastmane[iii],'iug_meteor_ktb_vwnd_'+site_data_lastmane[iii],$
                   'iug_meteor_ktb_uwndsig_'+site_data_lastmane[iii],'iug_meteor_ktb_vwndsig_'+site_data_lastmane[iii],$
                   'iug_meteor_ktb_mwnum_'+site_data_lastmane[iii]], 'spec', 1
      endif

     ;---Clear time and data buffer:
      ktb_time=0
      zon_wind2=0
      mer_wind2=0
      zon_thermal2=0
      mer_thermal2=0
      meteor_num2=0

      new_vars=tnames('iug_meteor_ktb_*')
      if new_vars[0] ne '' then begin       
       ;---Add tdegap
        tdegap, 'iug_meteor_ktb_uwnd_'+site_data_lastmane[iii],/overwrite
        tdegap, 'iug_meteor_ktb_vwnd_'+site_data_lastmane[iii],/overwrite
        tdegap, 'iug_meteor_ktb_uwndsig_'+site_data_lastmane[iii],/overwrite
        tdegap, 'iug_meteor_ktb_vwndsig_'+site_data_lastmane[iii],/overwrite
        tdegap, 'iug_meteor_ktb_mwnum_'+site_data_lastmane[iii],/overwrite 
              
       ;---Add tclip
        tclip, 'iug_meteor_ktb_uwnd_'+site_data_lastmane[iii],-200,200,/overwrite
        tclip, 'iug_meteor_ktb_vwnd_'+site_data_lastmane[iii],-200,200,/overwrite
        tclip, 'iug_meteor_ktb_uwndsig_'+site_data_lastmane[iii],0,400,/overwrite
        tclip, 'iug_meteor_ktb_vwndsig_'+site_data_lastmane[iii],0,400,/overwrite
       ;tclip, 'iug_meteor_ktb_mwnum_'+site_data_lastmane[kkk],,0,800,/overwrite

       ;---Add zlim
        zlim, 'iug_meteor_ktb_uwnd_*',-100,100
        zlim, 'iug_meteor_ktb_vwnd_*',-100,100
      endif
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
print, 'please read and keep the DATA USE POLICY'
print, '(http://database.rish.kyoto-u.ac.jp/arch/iugonet/data_policy/Data_Use_Policy_e.html' 
print, 'The distribution of meteor wind radar data has been partly supported by the IUGONET'
print, '(Inter-university Upper atmosphere Global Observation NETwork) project'
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, Sports, Science'
print, 'and Technology (MEXT), Japan.'  
end
