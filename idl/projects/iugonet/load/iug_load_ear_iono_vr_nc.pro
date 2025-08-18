;+
;
;NAME:
;iug_load_ear_iono_vr_nc
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the FAI observation data in the NetCDF format 
;  taken by the equatorial atmosphere radar (EAR) and loads data into
;  tplot format.
;
;SYNTAX:
; iug_load_ear_iono_vr_nc, parameter=parameter, $
;                          downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  PARAMETERS = first parameter name of EAR FAI obervation data.  
;          For example, iug_load_ear_iono_vr_nc, parameter = 'vb3p4a'.
;          The default is 'all', i.e., load all available parameters.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE (In): [1,...,5], Get more detailed (higher number) command line output.
;  
;DATA AVAILABILITY:
;  Please check the following homepage of the time schedule of field-aligned irregularity (FAI) observation 
;  before you analyze the FAI data using this software. 
;  http://www.rish.kyoto-u.ac.jp/ear/data-fai/index.html#data
;
;CODE:
; A. Shinbori, 19/09/2010.
;
;MODIFICATIONS:
; A. Shinbori, 24/03/2011.
; A. Shinbori, 09/07/2011.
; A. Shinbori, 31/01/2012.
; A. Shinbori, 17/12/2012.
; A. Shinbori, 24/01/2014.
; A. Shinbori, 08/08/2017.
; A. Shinbori, 29/11/2017.
;  
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-


pro iug_load_ear_iono_vr_nc, parameter=parameter, $
  downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

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

;************
;parameters:
;************
;--- all parameters (default)
parameter_all = strsplit('vb3p4a 150p8c8a 150p8c8b 150p8c8c 150p8c8d 150p8c8e 150p8c8b2a 150p8c8b2b '+$
                          '150p8c8b2c 150p8c8b2d 150p8c8b2e 150p8c8b2f',' ', /extract)

;--- check parameters
if(not keyword_set(parameter)) then parameter='all'
parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters

;*****************
;Defition of unit:
;*****************
;--- all units (default)
unit_all = strsplit('m/s dB',' ', /extract)

;**************************
;Loop on downloading files:
;**************************
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
jj=0L
for ii=0L,n_elements(parameters)-1 do begin
  ;==============================================================
  ;Change time window associated with a time shift from UT to LT:
  ;==============================================================
   day_org = (time_org[1] - time_org[0])/86400.d
   day_mod = day_org + 1
   timespan, time_org[0] - 3600.0d * 7.0d, day_mod
   if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) + 7.0d * 3600.0d); for GUI
   
   if ~size(fns,/type) then begin
     ;****************************
     ;Get files for ith component:
     ;****************************
      file_names = file_dailynames( $
      file_format='YYYY/YYYYMMDD/'+$
                  'YYYYMMDD',trange=trange,times=times,/unique)+'.fai'+parameters[ii]+'.nc'
                  
     ;===============================
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/ktb/ear/fai/v_region/nc/'
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/ear/data-fai/data/nc/'
      
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

      ;===========================================================
     ;read data, and create tplot vars at each parameter:
     ;===========================================================
     ;Read the files:
     ;===============
     ;============== 
     ;Loop on files: 
     ;==============    
      for j=jj,n_elements(local_paths)-1 do begin
         file= local_paths[j]
         if file_test(/regular,file) then  dprint,'Loading the FAI observation data taken by the EAR: ',file $
         else begin
            dprint,'The FAI observation data taken by the EAR ',file,' not found. Skipping'
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
    
        ;---Get time information:
         time_info=strsplit(time_data,' ',/extract)
         syymmdd=time_info[2]
         shhmmss=time_info[3]
         time_diff=strsplit(time_info[4],':',/extract)
         time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60 
     
        ;---Get the variable
         ncdf_varget, cdfid, 'lat', lat
         ncdf_varget, cdfid, 'lon', lon
         ncdf_varget, cdfid, 'sealvl', sealvl
         ncdf_varget, cdfid, 'bmwdh', bmwdh
         ncdf_varget, cdfid, 'freq', freq
         ncdf_varget, cdfid, 'ipp', ipp
         ncdf_varget, cdfid, 'ndata', ndata
         ncdf_varget, cdfid, 'nfft', nfft
         ncdf_varget, cdfid, 'ncoh', ncoh
         ncdf_varget, cdfid, 'nicoh', nicoh
         ncdf_varget, cdfid, 'beam', beam
         ncdf_varget, cdfid, 'range', range
         ncdf_varget, cdfid, 'az', az
         ncdf_varget, cdfid, 'ze', ze
         ncdf_varget, cdfid, 'date', date
         ncdf_varget, cdfid, 'time', time
         ncdf_varget, cdfid, 'height', height
         ncdf_varget, cdfid, 'pwr', pwr
         ncdf_varget, cdfid, 'width', width
         ncdf_varget, cdfid, 'dpl', dpl
         ncdf_varget, cdfid, 'pnoise', pnoise

        ;---Get date information:
         year = fix(strmid(strtrim(string(date),1),0,4))
         month = fix(strmid(strtrim(string(date),1),4,2))
         day = fix(strmid(strtrim(string(date),1),6,2))
                          
        ;---Definition of arrary names
         height2 = fltarr(n_elements(range))
         unix_time = dblarr(n_elements(time))
         pwr1_ear=fltarr(n_elements(time),n_elements(range),n_elements(beam))
         wdt1_ear=fltarr(n_elements(time),n_elements(range),n_elements(beam))
         dpl1_ear=fltarr(n_elements(time),n_elements(range),n_elements(beam))
         snr1_ear=fltarr(n_elements(time),n_elements(range),n_elements(beam))
         pnoise1_ear=fltarr(n_elements(time),n_elements(beam)) 
    
         for i=0L, n_elements(time)-1 do begin
           ;---Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)    
            unix_time[i] = double(time[i]) +time_double(string(syymmdd)+'/'+string(shhmmss))-double(time_diff2)
           
           ;---Replace missing value by NaN:                            
            for k=0L, n_elements(range)-1 do begin
               for l=0L, n_elements(beam)-1 do begin
                  a = pwr[k,i,l]            
                  wbad = where(a eq 10000000000,nbad)
                  if nbad gt 0 then a[wbad] = !values.f_nan
                  pwr[k,i,l] =a
                  b = width[k,i,l]            
                  wbad = where(b eq 10000000000,nbad)
                  if nbad gt 0 then b[wbad] = !values.f_nan
                  width[k,i,l]  =b
                  c = dpl[k,i,l]            
                  wbad = where(c eq 10000000000,nbad)
                  if nbad gt 0 then c[wbad] = !values.f_nan
                  dpl[k,i,l] =c
                  pwr1_ear[i,k,l]=pwr[k,i,l]  
                  wdt1_ear[i,k,l]=width[k,i,l]  
                  dpl1_ear[i,k,l]=dpl[k,i,l]
               endfor        
            endfor
            for l=0L, n_elements(beam)-1 do begin            
               d = pnoise[i,l]            
               wbad = where(d eq 10000000000,nbad)
               if nbad gt 0 then d[wbad] = !values.f_nan
               pnoise[i,l] =d
               pnoise1_ear[i,l]=pnoise[i,l]           
            endfor
         endfor
         ncdf_close,cdfid  ; done
       
        ;---Calculation of SNR
         snr=fltarr(n_elements(time),n_elements(range),n_elements(beam)) 
         for i=0L,n_elements(time)-1 do begin
            for l=0L,n_elements(beam)-1 do begin
               for k=0L,n_elements(range)-1 do begin
                  snr1_ear[i,k,l]=pwr1_ear[i,k,l]-(pnoise1_ear[i,l]+alog10(nfft))
              endfor 
            endfor
         endfor
       
        ;=============================
        ;Append data of time and data:
        ;=============================
         append_array, ear_time, unix_time
         append_array, pwr1, pwr1_ear
         append_array, wdt1, wdt1_ear
         append_array, dpl1, dpl1_ear
         append_array, pn1, pnoise1_ear
         append_array, snr1, snr1_ear
      endfor

     ;==============================================================
     ;Change time window associated with a time shift from UT to LT:
     ;==============================================================
      timespan, time_org
      get_timespan, init_time2
      if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) - 7.0d * 3600.0d); for GUI
      
     ;==============================
     ;Store data in TPLOT variables:
     ;==============================
     ;---Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'The Equatorial Atmosphere Radar belongs to Research Institute for ' $
                       + 'Sustainable Humanosphere (RISH), Kyoto University and is operated by ' $
                       + 'RISH and National Institute of Aeronautics and Space (LAPAN) Indonesia. ' $
                       + 'Distribution of the data has been partly supported by the IUGONET '$
                       + '(Inter-university Upper atmosphere Global Observation NETwork) project ' $
                       + '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, ' $
                       + 'Sports, Science and Technology (MEXT), Japan.'
                       
      if n_elements(ear_time) gt 1 then begin
         bname2=strarr(n_elements(beam))
         bname=strarr(n_elements(beam))
         pwr2_ear=fltarr(n_elements(ear_time),n_elements(range))
         wdt2_ear=fltarr(n_elements(ear_time),n_elements(range))
         dpl2_ear=fltarr(n_elements(ear_time),n_elements(range))
         snr2_ear=fltarr(n_elements(ear_time),n_elements(range))
         pnoise2_ear=fltarr(n_elements(ear_time)) 
    
         if size(pwr1,/type) eq 4 then begin
           ;---Create tplot variable for each parameter:
            dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'H. Hashiguchi'))         
            for l=0L, n_elements(beam)-1 do begin
               bname2[l]=string(beam[l]+1)
               bname[l]=strsplit(bname2[l],' ', /extract)
               for k=0L, n_elements(range)-1 do begin
                  height2[k]=height[k,l]
               endfor
               for i=0L, n_elements(ear_time)-1 do begin
                  for k=0L, n_elements(range)-1 do begin
                     pwr2_ear[i,k]=pwr1[i,k,l]
                  endfor
               endfor
              
              ;---Create tplot variable for echo power: 
               store_data,'iug_ear_fai'+parameters[ii]+'_pwr'+bname[l],data={x:ear_time, y:pwr2_ear, v:height2},dlimit=dlimit

              ;----Edge data cut:
               time_clip, 'iug_ear_fai'+parameters[ii]+'_pwr'+bname[l], init_time2[0], init_time2[1], newname = 'iug_ear_fai'+parameters[ii]+'_pwr'+bname[l]
      
              ;---Add options and tdegap:
               new_vars=tnames('iug_ear_fai'+parameters[ii]+'_pwr'+bname[l])
               if new_vars[0] ne '' then begin
                  options,'iug_ear_fai'+parameters[ii]+'_pwr'+bname[l],ytitle='EAR-iono!CHeight!C[km]',ztitle='pwr'+bname[l]+'!C[dB]'
                  options,'iug_ear_fai'+parameters[ii]+'_pwr'+bname[l],'spec',1
                  tdegap, 'iug_ear_fai'+parameters[ii]+'_pwr'+bname[l], /overwrite
               endif
               for i=0L, n_elements(ear_time)-1 do begin
                  for k=0L, n_elements(range)-1 do begin
                     wdt2_ear[i,k]=wdt1[i,k,l]
                  endfor
               endfor
               
              ;---Create tplot variable for spectral width: 
               store_data,'iug_ear_fai'+parameters[ii]+'_wdt'+bname[l],data={x:ear_time, y:wdt2_ear, v:height2},dlimit=dlimit

               ;----Edge data cut:
               time_clip, 'iug_ear_fai'+parameters[ii]+'_wdt'+bname[l], init_time2[0], init_time2[1], newname = 'iug_ear_fai'+parameters[ii]+'_wdt'+bname[l]
              
              ;---Add options and tdegap:
               new_vars=tnames('iug_ear_fai'+parameters[ii]+'_wdt'+bname[l])
               if new_vars[0] ne '' then begin
                  options,'iug_ear_fai'+parameters[ii]+'_wdt'+bname[l],ytitle='EAR-iono!CHeight!C[km]',ztitle='wdt'+bname[l]+'!C[m/s]'
                  options,'iug_ear_fai'+parameters[ii]+'_wdt'+bname[l],'spec',1
                  tdegap, 'iug_ear_fai'+parameters[ii]+'_wdt'+bname[l], /overwrite
               endif 
               for i=0L, n_elements(ear_time)-1 do begin
                  for k=0L, n_elements(range)-1 do begin
                     dpl2_ear[i,k]=dpl1[i,k,l]
                  endfor
               endfor
              
              ;---Create tplot variable for Doppler velocity:
               store_data,'iug_ear_fai'+parameters[ii]+'_dpl'+bname[l],data={x:ear_time, y:dpl2_ear, v:height2},dlimit=dlimit

               ;----Edge data cut:
               time_clip, 'iug_ear_fai'+parameters[ii]+'_dpl'+bname[l], init_time2[0], init_time2[1], newname = 'iug_ear_fai'+parameters[ii]+'_dpl'+bname[l]
              
              ;---Add options and tdegap:
               new_vars=tnames('iug_ear_fai'+parameters[ii]+'_dpl'+bname[l])
               if new_vars[0] ne '' then begin
                  options,'iug_ear_fai'+parameters[ii]+'_dpl'+bname[l],ytitle='EAR-iono!CHeight!C[km]',ztitle='dpl'+bname[l]+'!C[m/s]'
                  options,'iug_ear_fai'+parameters[ii]+'_dpl'+bname[l],'spec',1
                  tdegap, 'iug_ear_fai'+parameters[ii]+'_dpl'+bname[l], /overwrite
               endif
               for i=0L, n_elements(ear_time)-1 do begin
                  for k=0L, n_elements(range)-1 do begin
                     snr2_ear[i,k]=snr1[i,k,l]
                  endfor
               endfor
              
              ;---Create tplot variable for singal to noise ratio:
               store_data,'iug_ear_fai'+parameters[ii]+'_snr'+bname[l],data={x:ear_time, y:snr2_ear, v:height2},dlimit=dlimit

               ;----Edge data cut:
               time_clip, 'iug_ear_fai'+parameters[ii]+'_snr'+bname[l], init_time2[0], init_time2[1], newname = 'iug_ear_fai'+parameters[ii]+'_snr'+bname[l]
              
              ;---Add options and tdegap:
               new_vars=tnames('iug_ear_fai'+parameters[ii]+'_snr'+bname[l])
               if new_vars[0] ne '' then begin
                  options,'iug_ear_fai'+parameters[ii]+'_snr'+bname[l],ytitle='EAR-iono!CHeight!C[km]',ztitle='snr'+bname[l]+'!C[dB]'
                  options,'iug_ear_fai'+parameters[ii]+'_snr'+bname[l],'spec',1
                  tdegap, 'iug_ear_fai'+parameters[ii]+'_snr'+bname[l], /overwrite
               endif 
               for i=0L, n_elements(time)-1 do begin
                  pnoise2_ear[i]=pn1[i,l]
               endfor
               
              ;---Create tplot variable for noise level:
               store_data,'iug_ear_fai'+parameters[ii]+'_pn'+bname[l],data={x:ear_time, y:pnoise2_ear},dlimit=dlimit

              ;----Edge data cut:
               time_clip, 'iug_ear_fai'+parameters[ii]+'_pn'+bname[l], init_time2[0], init_time2[1], newname = 'iug_ear_fai'+parameters[ii]+'_pn'+bname[l]
              
              ;---Add options and tdegap:
               new_vars=tnames('iug_ear_fai'+parameters[ii]+'_pn'+bname[l])
               if new_vars[0] ne '' then begin
                  options,'iug_ear_fai'+parameters[ii]+'_pn'+bname[l],ytitle='pn'+bname[l]+'!C[dB]' 
                  tdegap, 'iug_ear_fai'+parameters[ii]+'_pn'+bname[l], /overwrite  
               endif        
            endfor
         endif
      
         new_vars=tnames('iug_ear_fai*')
         if new_vars[0] ne '' then begin      
            print,'**********************************************************************************
            print,'Data loading is successful!!'
            print,'**********************************************************************************
         endif
      endif
   endif
 
 
  ;---Clear time and data buffer:
   ear_time=0
   pwr1 = 0
   wdt1 = 0
   dpl1 = 0
   pn1 = 0
   snr1 = 0
   
   jj=n_elements(local_paths)
  ;---Initialization of timespan for parameters-1:
   timespan, time_org
endfor

;*************************
;Print of acknowledgement:
;*************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'The Equatorial Atmosphere Radar belongs to Research Institute for '
print, 'Sustainable Humanosphere (RISH), Kyoto University and is operated by '
print, 'RISH and National Institute of Aeronautics and Space (LAPAN) Indonesia. '
print, 'Distribution of the data has been partly supported by the IUGONET '
print, '(Inter-university Upper atmosphere Global Observation NETwork) project '
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, '
print, 'Sports, Science and Technology (MEXT), Japan.'

end

