;+
;
;NAME:
;iug_load_ear_trop_nc
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the standard observation data of troposphere and stratsoohere
;  in the netCDF format taken by the equatorial atmosphere radar (EAR) and loads data into
;  tplot format.
;
;SYNTAX:
; iug_load_ear_trop_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE (In): [1,...,5], Get more detailed (higher number) command line output.
;  
;CODE:
; A. Shinbori, 19/09/2010.
;
;MODIFICATIONS:
; A. Shinbori, 24/03/2011.
; A. Shinbori, 13/11/2011.
; A. Shinbori, 31/01/2012.
; A. Shinbori, 18/12/2012.
; A. Shinbori, 24/01/2014.
; A. Shinbori, 08/08/2017.
; A. Shinbori, 30/11/2017.
;  
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_ear_trop_nc, downloadonly=downloadonly, $
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

;**************************
;Loop on downloading files:
;**************************
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
   file_format='YYYYMM/YYYYMMDD/'+$
                   'YYYYMMDD',trange=trange,times=times,/unique)+'.nc'
  
  ;===============================
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/ktb/ear/troposphere/nc/'
   source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/ear/data/data/ver02.0212/'
  
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
   for j=0L,n_elements(local_paths)-1 do begin
      file= local_paths[j]
      if file_test(/regular,file) then  dprint,'Loading the troposphere and lower statrosphere observation data taken by the EAR: ',file $
      else begin
         dprint,'The troposphere and lower statrosphere observation data taken by the EAR ',file,' not found. Skipping'
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
      ncdf_varget, cdfid, 'beam', beam
      ncdf_varget, cdfid, 'range', range
      ncdf_varget, cdfid, 'az', az
      ncdf_varget, cdfid, 'ze', ze
      ncdf_varget, cdfid, 'date', date
      ncdf_varget, cdfid, 'time', time
      ncdf_varget, cdfid, 'navet', navet
      ncdf_varget, cdfid, 'itdnum', itdnum
      ncdf_varget, cdfid, 'height_vw', height_vw
      ncdf_varget, cdfid, 'height_mwzw', height_mwzw
      ncdf_varget, cdfid, 'height', height
      ncdf_varget, cdfid, 'vwind', wwind
      ncdf_varget, cdfid, 'nvwind', nwwind
      ncdf_varget, cdfid, 'mwind', vwind
      ncdf_varget, cdfid, 'nmwind', nvwind
      ncdf_varget, cdfid, 'zwind', uwind
      ncdf_varget, cdfid, 'nzwind', nuwind
      ncdf_varget, cdfid, 'pwr', pwr
      ncdf_varget, cdfid, 'npwr', npwr
      ncdf_varget, cdfid, 'width', width
      ncdf_varget, cdfid, 'nwidth', nwidth
      ncdf_varget, cdfid, 'dpl', dpl
      ncdf_varget, cdfid, 'ndpl', ndpl
      ncdf_varget, cdfid, 'pnoise', pnoise

     ;---Get date information:
      year = fix(strmid(strtrim(string(date),1),0,4))
      month = fix(strmid(strtrim(string(date),1),4,2))
      day = fix(strmid(strtrim(string(date),1),6,2))
                           
     ;---Definition of arrary names
      unix_time = dblarr(n_elements(time))
      height2 = fltarr(n_elements(range))
      uwind_ear=fltarr(n_elements(time),n_elements(range))
      vwind_ear=fltarr(n_elements(time),n_elements(range))
      wwind_ear=fltarr(n_elements(time),n_elements(range))
      pwr1_ear=fltarr(n_elements(time),n_elements(range),n_elements(beam))
      wdt1_ear=fltarr(n_elements(time),n_elements(range),n_elements(beam))
      dpl1_ear=fltarr(n_elements(time),n_elements(range),n_elements(beam))
      pnoise1_ear=fltarr(n_elements(time),n_elements(beam)) 
    
      for i=0L, n_elements(time)-1 do begin
        ;Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)    
         unix_time[i] =  double(time[i])+time_double(syymmdd+'/'+shhmmss)-time_diff2     
        
        ;---Replace missing value by NaN:                        
         for k=0L, n_elements(range)-1 do begin
            a = uwind[k,i]            
            wbad = where(a eq 10000000000,nbad)
            if nbad gt 0 then a[wbad] = !values.f_nan
            uwind[k,i] =a
            b = vwind[k,i]            
            wbad = where(b eq 10000000000,nbad)
            if nbad gt 0 then b[wbad] = !values.f_nan
            vwind[k,i] =b
            c = wwind[k,i]            
            wbad = where(c eq 10000000000,nbad)
            if nbad gt 0 then c[wbad] = !values.f_nan
            wwind[k,i] =c                    
            uwind_ear[i,k]=uwind[k,i]
            vwind_ear[i,k]=vwind[k,i]
            wwind_ear[i,k]=wwind[k,i]                      
            for l=0L, n_elements(beam)-1 do begin           
               e = pwr[k,i,l]            
               wbad = where(e eq 10000000000,nbad)
               if nbad gt 0 then e[wbad] = !values.f_nan
               pwr[k,i,l] =e
               f = width[k,i,l]            
               wbad = where(f eq 10000000000,nbad)
               if nbad gt 0 then f[wbad] = !values.f_nan
               width[k,i,l] =f
               g = dpl[k,i,l]            
               wbad = where(g eq 10000000000,nbad)
               if nbad gt 0 then g[wbad] = !values.f_nan
               dpl[k,i,l] =g        
               d = pnoise[i,l]            
               wbad = where(d eq 10000000000,nbad)
               if nbad gt 0 then d[wbad] = !values.f_nan
               pnoise[i,l] =d     
               pwr1_ear[i,k,l]=pwr[k,i,l]
               wdt1_ear[i,k,l]=width[k,i,l]
               dpl1_ear[i,k,l]=dpl[k,i,l]
               pnoise1_ear[i,l]=pnoise[i,l]
            endfor 
         endfor
      endfor
    
   ;=============================
   ;Append data of time and data:
   ;=============================
    append_array, ear_time, unix_time
    append_array, zon_wind, uwind_ear
    append_array, mer_wind, vwind_ear
    append_array, ver_wind, wwind_ear
    append_array, pwr1, pwr1_ear
    append_array, wdt1, wdt1_ear
    append_array, dpl1, dpl1_ear
    append_array, pn1, pnoise1_ear

    ncdf_close,cdfid  ; done
    
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
                 + 'Distribution of the data has been partly supported by the IUGONET ' $
                 + '(Inter-university Upper atmosphere Global Observation NETwork) project ' $
                 + '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, ' $
                 + 'Sports, Science and Technology (MEXT), Japan.'
                 
   if n_elements(ear_time) gt 1 then begin
     ;---Definition of arrary names
      bname2=strarr(n_elements(beam))
      bname=strarr(n_elements(beam))
      pwr2_ear=fltarr(n_elements(ear_time),n_elements(range))
      wdt2_ear=fltarr(n_elements(ear_time),n_elements(range))
      dpl2_ear=fltarr(n_elements(ear_time),n_elements(range))
      pnoise2_ear=fltarr(n_elements(ear_time)) 
      
      if size(pwr1,/type) eq 4 then begin
        ;---Create tplot variable for zonal wind:
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'H. Hashiguchi'))   
         store_data,'iug_ear_trop_uwnd',data={x:ear_time, y:zon_wind, v:height_mwzw},dlimit=dlimit

        ;----Edge data cut:
         time_clip, 'iug_ear_trop_uwnd', init_time2[0], init_time2[1], newname = 'iug_ear_trop_uwnd'
        
        ;---Add options and tdegap:
         new_vars=tnames('iug_ear_trop_uwnd')
         if new_vars[0] ne '' then begin
            options,'iug_ear_trop_uwnd',ytitle='EAR-trop!CHeight!C[km]',ztitle='uwnd!C[m/s]'
            options, 'iug_ear_trop_uwnd','spec',1
            tdegap, 'iug_ear_trop_uwnd',/overwrite
         endif
         
        ;---Create tplot variable for meridional wind:
         store_data,'iug_ear_trop_vwnd',data={x:ear_time, y:mer_wind, v:height_mwzw},dlimit=dlimit

        ;----Edge data cut:
         time_clip, 'iug_ear_trop_vwnd', init_time2[0], init_time2[1], newname = 'iug_ear_trop_vwnd'
        
        ;---Add options and tdegap:
         new_vars=tnames('iug_ear_trop_vwnd')
         if new_vars[0] ne '' then begin
            options,'iug_ear_trop_vwnd',ytitle='EAR-trop!CHeight!C[km]',ztitle='vwnd!C[m/s]'
            options, 'iug_ear_trop_vwnd','spec',1
            tdegap, 'iug_ear_trop_vwnd',/overwrite
         endif
         
        ;---Create tplot variable for vertical wind:
         store_data,'iug_ear_trop_wwnd',data={x:ear_time, y:ver_wind, v:height_vw},dlimit=dlimit

        ;----Edge data cut:
         time_clip, 'iug_ear_trop_wwnd', init_time2[0], init_time2[1], newname = 'iug_ear_trop_wwnd'
         
        ;---Add options and tdegap:
         new_vars=tnames('iug_ear_trop_wwnd')
         if new_vars[0] ne '' then begin
            options,'iug_ear_trop_wwnd',ytitle='EAR-trop!CHeight!C[km]',ztitle='wwnd!C[m/s]'
            options, 'iug_ear_trop_wwnd','spec',1
            tdegap, 'iug_ear_trop_wwnd',/overwrite
         endif
                  
        ;---Create tplot variable for echo intensity, spectral width, Doppler velocity and niose level for beam 1-5:
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
             
            ;---Echo power (beam 1-5)
             store_data,'iug_ear_trop_pwr'+bname[l],data={x:ear_time, y:pwr2_ear, v:height2},dlimit=dlimit

            ;----Edge data cut:
             time_clip, 'iug_ear_trop_pwr'+bname[l], init_time2[0], init_time2[1], newname = 'iug_ear_trop_pwr'+bname[l]

             new_vars=tnames('iug_ear_trop_pwr*')
             if new_vars[0] ne '' then begin
                options,'iug_ear_trop_pwr'+bname[l],ytitle='EAR-trop!CHeight!C[km]',ztitle='pwr'+bname[l]+'!C[dB]'
                options, 'iug_ear_trop_pwr'+bname[l],'spec',1
                tdegap, 'iug_ear_trop_pwr'+bname[l],/overwrite
             endif
             for i=0L, n_elements(ear_time)-1 do begin
                 for k=0L, n_elements(range)-1 do begin
                     wdt2_ear[i,k]=wdt1[i,k,l]
                 endfor
             endfor
             
            ;---Spectral width (beam 1-5)
             store_data,'iug_ear_trop_wdt'+bname[l],data={x:ear_time, y:wdt2_ear, v:height2},dlimit=dlimit

            ;----Edge data cut:
             time_clip, 'iug_ear_trop_wdt'+bname[l], init_time2[0], init_time2[1], newname = 'iug_ear_trop_wdt'+bname[l]

             new_vars=tnames('iug_ear_trop_wdt*')
             if new_vars[0] ne '' then begin             
                options,'iug_ear_trop_wdt'+bname[l],ytitle='EAR-trop!CHeight!C[km]',ztitle='wdt'+bname[l]+'!C[m/s]'
                options, 'iug_ear_trop_wdt'+bname[l],'spec',1
                tdegap, 'iug_ear_trop_wdt'+bname[l],/overwrite 
             endif
             
             for i=0L, n_elements(ear_time)-1 do begin
                 for k=0L, n_elements(range)-1 do begin
                     dpl2_ear[i,k]=dpl1[i,k,l]
                 endfor
             endfor
             
            ;---Doppler velocity (beam 1-5)             
             store_data,'iug_ear_trop_dpl'+bname[l],data={x:ear_time, y:dpl2_ear, v:height2},dlimit=dlimit

            ;----Edge data cut:
             time_clip, 'iug_ear_trop_dpl'+bname[l], init_time2[0], init_time2[1], newname = 'iug_ear_trop_dpl'+bname[l]

             new_vars=tnames('iug_ear_trop_dpl*')
             if new_vars[0] ne '' then begin  
                options,'iug_ear_trop_dpl'+bname[l],ytitle='EAR-trop!CHeight!C[km]',ztitle='dpl'+bname[l]+'!C[dB]'
                options, 'iug_ear_trop_dpl'+bname[l],'spec',1
                tdegap, 'iug_ear_trop_dpl'+bname[l],/overwrite 
             endif
              
             for i=0L, n_elements(ear_time)-1 do begin
                 pnoise2_ear[i]=pn1[i,l]
             endfor
             
            ;---Noise level (beam 1-5)
             store_data,'iug_ear_trop_pn'+bname[l],data={x:ear_time, y:pnoise2_ear},dlimit=dlimit

            ;----Edge data cut:
             time_clip, 'iug_ear_trop_pn'+bname[l], init_time2[0], init_time2[1], newname = 'iug_ear_trop_pn'+bname[l]

             new_vars=tnames('iug_ear_trop_pn*')
             if new_vars[0] ne '' then begin 
                options,'iug_ear_trop_pn'+bname[l],ytitle='pn'+bname[l]+'!C[dB]'
                tdegap, 'iug_ear_trop_pn'+bname[l],/overwrite  
             endif                  
         endfor    
      endif
      
      new_vars=tnames('iug_ear_trop_*')
      if new_vars[0] ne '' then begin 
         print,'**********************************************************************************
         print,'Data loading is successful!!'
         print,'**********************************************************************************
      endif
   endif
endif

;---Initialization of timespan for parameters-1:
timespan, time_org

;---Clear time and data buffer:
ear_time=0
zon_wind=0
mer_wind=0
ver_wind=0
pwr1 = 0
wdt1 = 0
dpl1 = 0
pn1 = 0
      
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

