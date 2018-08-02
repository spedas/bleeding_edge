;+
;
;NAME:
;iug_load_radiosonde_dawex_nc
;
;PURPOSE:
;  Queries the Kyoto RISH server for the netCDF data (press, temp, rh, uwnd, vwnd) 
;  of the troposphere taken by the radiosonde at DAW, GNP and 
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_radiosonde_dawex_nc, site=site, $
;                        downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS: 
;   SITE = DAWEX observation site.  
;          For example, iug_load_radiosonde_dawex_nc, site = 'drw'.
;          The default is 'all', i.e., load all available observation points.
;          The default is 'all', i.e., load all available parameters.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
;  
;CODE:
;  A. Shinbori, 19/12/2012.
;  
;MODIFICATIONS:
;  A. Shinbori, 26/02/2013.
;  A. Shinbori, 30/05/2013.
;  A. Shinbori, 24/01/2014.
;  
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_radiosonde_dawex_nc, site=site, $
  downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2

;****************
;Site code check:
;****************
;--- all sites (default)
site_code_all = strsplit('drw gpn ktr',' ', /extract)

;--- check site codes
if (not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

if n_elements(site_code) eq 1 then begin
   if site_code eq '' then begin
      print, 'This station code is not valid. Please input the allowed keywords, all, drw, gpn, and ktr.'
      return
   endif
endif
print, site_code

;*************
;Data premane:
;*************
site_data_premane = strsplit('nD nG nK',' ', /extract)

;======================
;Calculation of height:
;======================
height = fltarr(400)
for i=0L, 398 do begin
    height[i+1] = height[i]+0.1
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
h=0L
jj=0L
k=0L
n_site=intarr(3)

;---In the case that the parameters are except for all.'
if n_elements(site_code) le 3 then begin
   h_max=n_elements(site_code)
   for i=0L,n_elements(site_code)-1 do begin
      case site_code[i] of
         'drw':n_site[i]=0 
         'gpn':n_site[i]=1 
         'ktr':n_site[i]=2 
      endcase
   endfor
endif

for ii=0L,n_elements(site_code)-1 do begin
   k=n_site[ii]
   if ~size(fns,/type) then begin
     ;---Definition of DAWEX radiosonde site names:
      case site_code[ii] of
         'drw':site_code2='Dr'
         'gpn':site_code2='Gp'
         'ktr':site_code2='Kh'
      endcase     
        
     ;****************************
     ;Get files for ith component:
     ;****************************     
      hour_res = 1  
      file_names = file_dailynames( $
                   file_format='YYYY/'+site_data_premane[k]+$
                   'MMDDhh',trange=trange,hour_res=hour_res,times=times,/unique)+'.nc'
     
     ;===============================        
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir =  root_data_dir() + 'iugonet/rish/DAWEX/'+site_code[ii]+'/radiosonde/nc/'
      source.remote_data_dir = 'http://database.rish.kyoto-u.ac.jp/arch/iugonet/DAWEX/data/'+site_code2+'/nc/'
    
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
      sonde_press = 0
      sonde_temp = 0
      sonde_rh = 0
      sonde_dewp = 0
      sonde_uwind = 0
      sonde_vwind = 0

     ;==============
     ;Loop on files: 
     ;==============
      for j=jj,n_elements(local_paths)-1 do begin
         file= local_paths[j] 
         if file_test(/regular,file) then  dprint,'Loading DAWEX data file: ',file $
         else begin
            dprint,'DAWEX data file',file,'not found. Skipping'
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

        ;---Calculation the start time infomation from the attribute data:
         time_info=strsplit(time_data,' ',/extract)
         time_units = time_info[0]
         syymmdd=time_info[2]
         shhmmss=time_info[3]
         time_diff=strsplit(time_info[3],':',/extract)
         time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60 
         
         if time_units eq 'seconds' then dt = 1.0
         if time_units eq 'minutes' then dt = 60.0
         if time_units eq 'hours' then dt = 3600.0
         
        ;---Get the variable
         ncdf_varget, cdfid, 'lat', lat
         ncdf_varget, cdfid, 'lon', lon
         ncdf_varget, cdfid, 'height', ht
         ncdf_varget, cdfid, 'time', time
         ncdf_varget, cdfid, 'press', press
         ncdf_varget, cdfid, 'temperature', temperature
         ncdf_varget, cdfid, 'relative_humidity', relative_humidity
         ncdf_varget, cdfid, 'dew_point', dew_point
         ncdf_varget, cdfid, 'uwind', uwind
         ncdf_varget, cdfid, 'vwind', vwind

         ncdf_close,cdfid  ; done

        ;---Definition of arraies:
         p = fltarr(1,400)
         temp = fltarr(1,400)
         rh = fltarr(1,400)
         dewp = fltarr(1,400)
         uwnd = fltarr(1,400)
         vwnd = fltarr(1,400)
      
         for k=0L, n_elements(ht)-1 do begin
           ;========================
           ;Get height array number:
           ;========================
            h_num = ht[k]/100

           ;==================================================
           ;Get data of press., temp., rh, dewp, uwind, vwind:
           ;==================================================
            p[0,h_num] = press[k]
            temp[0,h_num] = temperature[k]
            rh[0,h_num] = relative_humidity[k]
            dewp[0,h_num] = dew_point[k]
            uwnd[0,h_num] = uwind[k]
            vwnd[0,h_num] = vwind[k]     
         endfor   
        ;---Replace missing number by NaN
         for i=0L, 399 do begin
            a = p[*,i]            
            wbad = where(a eq -999.0 || a eq 0.0,nbad)
            if nbad gt 0 then a[wbad] = !values.f_nan
            p[*,i] =a 
            b = temp[*,i]            
            wbad = where(b eq -999.0 || b eq 0.0,nbad)
            if nbad gt 0 then b[wbad] = !values.f_nan
            temp[*,i] =b 
            c = rh[*,i]            
            wbad = where(c eq -999.0 || c eq 0.0,nbad)
            if nbad gt 0 then c[wbad] = !values.f_nan
            rh[*,i] =c 
            d = dewp[*,i]            
            wbad = where(d eq -999 || d eq 0.0,nbad)
            if nbad gt 0 then d[wbad] = !values.f_nan
            dewp[*,i] =d 
            e = uwnd[*,i]            
            wbad = where(e eq -999.0 || e eq 0.0,nbad)          
            if nbad gt 0 then e[wbad] = !values.f_nan
            uwnd[*,i] =e 
            f = vwnd[*,i]            
            wbad = where(f eq -999.0 || f eq 0.0,nbad)
            if nbad gt 0 then f[wbad] = !values.f_nan
            vwnd[*,i] =f 
         endfor
          
        ;=====================
        ;Append time and data:
        ;=====================
         append_array, sonde_time, double(time)*dt
         append_array, sonde_press, float(p)
         append_array, sonde_temp, float(temp)
         append_array, sonde_rh, float(rh)
         append_array, sonde_dewp, float(dewp)
         append_array, sonde_uwind, float(uwnd)
         append_array, sonde_vwind, float(vwnd)
      endfor

     ;==============================
     ;Store data in TPLOT variables:
     ;==============================
     ;---Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'If you acquire the dawin sonde campaine data, we ask that you' $
                       + 'acknowledge us in your use of the data. This may be done by' $
                       + 'including text such as the dawin donde campaine data provided by Research Institute' $
                       + 'for Sustainable Humanosphere of Kyoto University. We would also' $
                       + 'appreciate receiving a copy of the relevant publications. The distribution of dawin sonde data' $
                       + 'has been partly supported by the IUGONET (Inter-university Upper atmosphere Global' $
                       + 'Observation NETwork) project (http://www.iugonet.org/) funded by the' $
                       + 'Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'
                       
      if size(sonde_press,/type) eq 4 then begin 
        ;---Create tplot variables and options
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Tsuda'))
         store_data,'iug_radiosonde_'+site_code[ii]+'_press',data={x:sonde_time, y:sonde_press, v:height},dlimit=dlimit
         options,'iug_radiosonde_'+site_code[ii]+'_press',ytitle='RSND-'+site_code[ii]+'!CHeight!C[km]',ztitle='Press.!C[hPa]'
         store_data,'iug_radiosonde_'+site_code[ii]+'_temp',data={x:sonde_time, y:sonde_temp, v:height},dlimit=dlimit
         options,'iug_radiosonde_'+site_code[ii]+'_temp',ytitle='RSND-'+site_code[ii]+'!CHeight!C[km]',ztitle='Temp.!C[deg.]'
         store_data,'iug_radiosonde_'+site_code[ii]+'_rh',data={x:sonde_time, y:sonde_rh, v:height},dlimit=dlimit
         options,'iug_radiosonde_'+site_code[ii]+'_rh',ytitle='RSND-'+site_code[ii]+'!CHeight!C[km]',ztitle='RH!C[%]'
         store_data,'iug_radiosonde_'+site_code[ii]+'_dewp',data={x:sonde_time, y:sonde_dewp, v:height},dlimit=dlimit
         options,'iug_radiosonde_'+site_code[ii]+'_dewp',ytitle='RSND-'+site_code[ii]+'!CHeight!C[km]',ztitle='Dewp.!C[deg.]'
         store_data,'iug_radiosonde_'+site_code[ii]+'_uwnd',data={x:sonde_time, y:sonde_uwind, v:height},dlimit=dlimit
         options,'iug_radiosonde_'+site_code[ii]+'_uwnd',ytitle='RSND-'+site_code[ii]+'!CHeight!C[km]',ztitle='uwnd!C[m/s]'
         store_data,'iug_radiosonde_'+site_code[ii]+'_vwnd',data={x:sonde_time, y:sonde_vwind, v:height},dlimit=dlimit
         options,'iug_radiosonde_'+site_code[ii]+'_vwnd',ytitle='RSND-'+site_code[ii]+'!CHeight!C[km]',ztitle='vwnd!C[m/s]'
         options, ['iug_radiosonde_'+site_code[ii]+'_press','iug_radiosonde_'+site_code[ii]+'_temp',$
                   'iug_radiosonde_'+site_code[ii]+'_rh','iug_radiosonde_'+site_code[ii]+'_dewp',$
                   'iug_radiosonde_'+site_code[ii]+'_uwnd','iug_radiosonde_'+site_code[ii]+'_vwnd'], 'spec', 1
      endif

     ;---Clear time and data buffer:
      sonde_time = 0
      sonde_press = 0
      sonde_temp = 0
      sonde_rh = 0
      sonde_dewp = 0
      sonde_uwind = 0
      sonde_vwind = 0
       
     ;---Add tdegap
      new_vars=tnames('iug_radiosonde_*')
      if new_vars[0] ne '' then begin  
         tdegap, 'iug_radiosonde_'+site_code[ii]+'_press',/overwrite
         tdegap, 'iug_radiosonde_'+site_code[ii]+'_temp',/overwrite
         tdegap, 'iug_radiosonde_'+site_code[ii]+'_rh',/overwrite
         tdegap, 'iug_radiosonde_'+site_code[ii]+'_dewp',/overwrite
         tdegap, 'iug_radiosonde_'+site_code[ii]+'_uwnd',/overwrite
         tdegap, 'iug_radiosonde_'+site_code[ii]+'_vwnd',/overwrite
      endif
   endif
   jj=n_elements(local_paths)
endfor 

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
print, 'If you acquire the dawin sonde campaine data, we ask that you acknowledge'
print, 'us in your use of the data. This may be done by including text such as' 
print, 'radiosonde data provided by Research Institute for Sustainable Humanosphere' 
print, 'of Kyoto University. We would also appreciate receiving a copy of the' 
print, 'relevant publications. The distribution of dawin sonde data has been partly'
print, 'supported by the IUGONET (Inter-university Upper atmosphere Global'
print, 'Observation NETwork) project (http://www.iugonet.org/) funded by the'
print, 'Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'

end
