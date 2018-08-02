;+
;
;NAME:
;iug_load_aws_sgk
;
;PURPOSE:
;  Queries the RISH server for the surface meterology data taken by the automatic weather 
;  station (AWS) at Shigaraki and loads data into tplot format.
;
;SYNTAX:
; iug_load_aws_sgk, site=site, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS: 
;  SITE = AWS observation site.  
;         For example, iug_load_aws_sgk, site = 'sgk'.
;         The default is 'all', i.e., load all available observation points.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
; 
;CODE:
;  A. Shinbori, 28/02/2013.
;  
;MODIFICATIONS:
;  A. Shinbori, 24/01/2014.
;  A. Shinbori, 08/08/2017. 
;  A. Shinbori, 30/11/2017.
;  
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_aws_sgk, site=site, $
  downloadonly=downloadonly, $
  trange=trange, verbose=verbose

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

;****************
;Site code check:
;****************
;--- all sites (default)
site_code_all = strsplit('sgk',' ', /extract)

;--- check site codes
if (not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

if n_elements(site_code) eq 1 then begin
   if site_code eq '' then begin
      print, 'This station code is not valid. Please input the allowed keywords, all, and sgk.'
      return
   endif
endif

print, site_code

;**************************
;Loop on downloading files:
;**************************
;==============================================================
;Change time window associated with a time shift from UT to LT:
;==============================================================
day_org = (time_org[1] - time_org[0])/86400.d
day_mod = day_org + 1
timespan, time_org[0] - 3600.0d * 9.0d, day_mod
if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) +9.0d * 3600.0d); for GUI

;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
if ~size(fns,/type) then begin   
  ;****************************
  ;Get files for ith component:
  ;****************************
   file_names = file_dailynames( $
   file_format='YYYY/YYYYMM/'+$
               'YYYYMMDD',trange=trange,times=times,/unique)+'.csv'
                     
  ;===============================
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/sgk/aws/csv/'
   source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/radar-group/surface/shigaraki/aws/csv/'
  
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
    
   ;==============      
   ;Loop on files: 
   ;==============
    for j=0L,n_elements(local_paths)-1 do begin
       file= local_paths[j]
       if file_test(/regular,file) then  dprint,'Loading the surface meteorological data taken by the AWS-sgk :',file $
       else begin
          dprint,'The surface meteorological data taken by the AWS-sgk', file,' not found. Skipping'
          continue
       endelse
       
      ;---Check file line:   
       lines = file_lines(file)
      
      ;---Open the read file:      
       openr,lun,file,/get_lun    
       
      ;=============================
      ;Read information of altitude:
      ;=============================
       readf, lun, s
       header_data = strsplit(s,',',/extract)
             
      ;---Definition of altitude and data arraies:
       date = header_data[0]
       time_zone = header_data[1]
       data_arr = strarr(7,lines-1)
            
      ;---Read the data:
       readf,lun, data_arr, format='(a8,a1,1x,a7,1x,a7,1x,a7,1x,a7,1x,a7)'
       data_arr = transpose(data_arr)       
        
      ;---Convert time from LT to UT
       yymmdd = strsplit(date,'/',/extract)     
       aws_data_time = time_double(string(yymmdd[0])+'-'+string(yymmdd[1])+'-'+string(yymmdd[2])+'/'+string(data_arr[*,0])) - double(time_zone) * 3600.0d

      ;---Substitute each parameter:            
       press = data_arr[*,2]
       temp = data_arr[*,3]
       rh = data_arr[*,4]
       uwnd = data_arr[*,5]
       vwnd = data_arr[*,6]

      ;---Enter the missing value:
       a = float(press)
       wbad = where(a eq -999,nbad)
       if nbad gt 0 then a[wbad] = !values.f_nan
       press=a
       b = float(temp)
       wbad = where(b eq -999,nbad)
       if nbad gt 0 then b[wbad] = !values.f_nan
       temp = b
       c = float(rh)
       wbad = where(c eq -999,nbad)
       if nbad gt 0 then c[wbad] = !values.f_nan
       rh = c
       d = float(uwnd)
       wbad = where(d eq -999,nbad)
       if nbad gt 0 then d[wbad] = !values.f_nan
       uwnd=d
       e = float(vwnd)
       wbad = where(e eq -999,nbad)
       if nbad gt 0 then e[wbad] = !values.f_nan
       vwnd=e            

      ;=====================================
      ;Append data of time and observations:
      ;=====================================
       append_array, aws_data_time_app, aws_data_time
       append_array, aws_press_app,press
       append_array, aws_temp_app, temp
       append_array, aws_rh_app,   rh
       append_array, aws_uwnd_app, uwnd
       append_array, aws_vwnd_app, vwnd  
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
    acknowledgstring = 'If you acquire the surface meteorological data, '+ $
                       'we ask that you acknowledge us in your use of the data. This may be done by'+ $
                       'including text such as the surface meteorological data provided by Research Institute'+ $
                       'for Sustainable Humanosphere of Kyoto University. We would also'+ $
                       'appreciate receiving a copy of the relevant publications. The distribution of '+ $
                       'surface meteorological data has been partly supported by the IUGONET (Inter-university Upper '+ $
                       'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '+ $
                       'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.' 
 
   if size(aws_press_app,/type) eq 4 then begin 
     ;---Create tplot variables
      dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'H. Hashiguchi'))            
      store_data,'iug_aws_sgk_press',data={x:aws_data_time_app, y:aws_press_app},dlimit=dlimit
      store_data,'iug_aws_sgk_temp',data={x:aws_data_time_app, y:aws_temp_app},dlimit=dlimit
      store_data,'iug_aws_sgk_rh',data={x:aws_data_time_app, y:aws_rh_app},dlimit=dlimit
      store_data,'iug_aws_sgk_uwnd',data={x:aws_data_time_app, y:aws_uwnd_app},dlimit=dlimit
      store_data,'iug_aws_sgk_vwnd',data={x:aws_data_time_app, y:aws_vwnd_app},dlimit=dlimit

     ;----Edge data cut:
      time_clip, 'iug_aws_sgk_press', init_time2[0], init_time2[1], newname = 'iug_aws_sgk_press'
      time_clip, 'iug_aws_sgk_rh', init_time2[0], init_time2[1], newname = 'iug_aws_sgk_rh'
      time_clip, 'iug_aws_sgk_temp', init_time2[0], init_time2[1], newname = 'iug_aws_sgk_temp'
      time_clip, 'iug_aws_sgk_uwnd', init_time2[0], init_time2[1], newname = 'iug_aws_sgk_uwnd'
      time_clip, 'iug_aws_sgk_vwnd', init_time2[0], init_time2[1], newname = 'iug_aws_sgk_vwnd'
      
     ;---Options of each tplot variable 
      new_vars=tnames('iug_aws_sgk_press')
      if new_vars[0] ne '' then begin 
         options,'iug_aws_sgk_press',ytitle='AWS-sgk!CPress.!C[hPa]'
         options,'iug_aws_sgk_temp',ytitle='AWS-sgk!CTemp.!C[degree C]'
         options,'iug_aws_sgk_rh',ytitle='AWS-sgk!CRH!C[%]'
         options,'iug_aws_sgk_uwnd',ytitle='AWS-sgk!Cuwnd!C[m/s]'
         options,'iug_aws_sgk_vwnd',ytitle='AWS-sgk!Cvwnd!C[m/s]'
      endif 
   endif
   
  ;---Clear time and data buffer:
   aws_time = 0
   aws_press = 0
   aws_temp = 0
   aws_rh = 0
   aws_uwnd = 0
   aws_vwnd = 0

  ;---Add tdegap      
   new_vars=tnames('iug_aws_sgk_press')
   if new_vars[0] ne '' then begin          
      tdegap, 'iug_aws_sgk_press',/overwrite
      tdegap, 'iug_aws_sgk_temp',/overwrite
      tdegap, 'iug_aws_sgk_rh',/overwrite
      tdegap, 'iug_aws_sgk_uwnd',/overwrite
      tdegap, 'iug_aws_sgk_vwnd',/overwrite
   endif
   
   ;---Initialization of timespan for sites:
   timespan, time_org

endif
 
new_vars=tnames('iug_aws_*')
if new_vars[0] ne '' then begin    
   print,'*****************************
   print,'Data loading is successful!!'
   print,'*****************************
endif

;*************************
;Print of acknowledgement:
;*************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire surface meteorological data, we ask that you acknowledge us'
print, 'in your use of the data. This may be done by including text such as surface' 
print, 'meteorological data provided by Research Institute for Sustainable Humanosphere' 
print, 'of Kyoto University. We would also appreciate receiving a copy of the relevant' 
print, 'publications. The distribution of surface meteorological data has been partly '
print, 'supported by the IUGONET (Inter-university Upper atmosphere Global Observation '
print, 'NETwork) project (http://www.iugonet.org/) funded by the Ministry of Education, '
print, 'Culture, Sports, Science and Technology (MEXT), Japan.'

end

