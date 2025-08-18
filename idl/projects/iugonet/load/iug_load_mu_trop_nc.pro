;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the standard observation data of the 
;  troposphere and lower stratsphere in the netCDF format taken by the Middle
;  and Upper atmosphere (MU) radar at Shigaraki and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_trop_nc, downloadonly=downloadonly, trange=trange, verbose=verbose
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
; A. Shinbori, 19/09/2010.
;
;MODIFICATIONS:
; A. Shinbori, 24/03/2011.
; A. Shinbori, 13/11/2011.
; A. Shinbori, 26/12/2011.
; A. Shinbori, 31/01/2012.
; A. Shinbori, 19/12/2012.
; A. Shinbori, 27/07/2013.
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

pro iug_load_mu_trop_nc, downloadonly=downloadonly, $
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

;*******************
;Defition of height:
;*******************
height_zm=strsplit('1.998,2.145,2.293,2.441,2.589,2.736,2.884,3.032,3.179,3.327,3.475,3.623,3.770,3.918,4.066,4.213,4.361,4.509,4.657,4.804,'+$
                   '4.952,5.100,5.248,5.395,5.543,5.691,5.838,5.986,6.134,6.282,6.429,6.577,6.725,6.872,7.020,7.168,7.316,7.463,7.611,7.759,'+$
                   '7.907,8.054,8.202,8.350,8.497,8.645,8.793,8.941,9.088,9.236,9.384,9.531,9.679,9.827,9.975,10.122,10.270,10.418,10.565,'+$
                   '10.713,10.861,11.009,11.156,11.304,11.452,11.600,11.747,11.895,12.043,12.190,12.338,12.486,12.634,12.781,12.929,13.077,'+$
                   '13.224,13.372,13.520,13.668,13.815,13.963,14.111,14.259,14.406,14.554,14.702,14.849,14.997,15.145,15.293,15.440,15.588,'+$
                   '15.736,15.883,16.031,16.179,16.327,16.474,16.622,16.770,16.917,17.065,17.213,17.361,17.508,17.656,17.804,17.952,18.099,'+$
                   '18.247,18.395,18.542,18.690,18.838,18.986,19.133,19.281,19.429,19.576',',',/extract)
                   
 height_v=strsplit('2.025,2.175,2.325,2.475,2.625,2.775,2.925,3.075,3.225,3.375,3.525,3.675,3.825,3.975,4.125,4.275,4.425,4.575,4.725,4.875,'+$
                   '5.025,5.175,5.325,5.475,5.625,5.775,5.925,6.075,6.225,6.375,6.525,6.675,6.825,6.975,7.125,7.275,7.425,7.575,7.725,7.875,'+$
                   '8.025,8.175,8.325,8.475,8.625,8.775,8.925,9.075,9.225,9.375,9.525,9.675,9.825,9.975,10.125,10.275,10.425,10.575,10.725,'+$
                   '10.875,11.025,11.175,11.325,11.475,11.625,11.775,11.925,12.075,12.225,12.375,12.525,12.675,12.825,12.975,13.125,13.275,'+$
                   '13.425,13.575,13.725,13.875,14.025,14.175,14.325,14.475,14.625,14.775,14.925,15.075,15.225,15.375,15.525,15.675,15.825,'+$
                   '15.975,16.125,16.275,16.425,16.575,16.725,16.875,17.025,17.175,17.325,17.475,17.625,17.775,17.925,18.075,18.225,18.375,'+$
                   '18.525,18.675,18.825,18.975,19.125,19.275,19.425,19.575,19.725,19.875',',',/extract)

;---Data list which applies the above height data:
f_list=['19860317','19860318','19860319','19860320','19860321','19910209']

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
   source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/sgk/mu/troposphere/nc/'
   source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/data/data/ver01.0807_1.02/'
   
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

  ;==============
  ;Loop on files: 
  ;==============
   for j=0L,n_elements(local_paths)-1 do begin
      file= local_paths[j]
      if file_test(/regular,file) then  dprint,'Loading the troposphere and lower statrosphere observation data taken by the MU radar: ',file $
      else begin
         dprint,'The troposphere and lower statrosphere observation data taken by the MU radar ',file,' not found. Skipping'
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

     ;---Get time infomation:
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

     ;---Get dat information:
      year = fix(strmid(strtrim(string(date),1),0,4))
      month = fix(strmid(strtrim(string(date),1),4,2))
      day = fix(strmid(strtrim(string(date),1),6,2))
                           
     ;---Definition of arrary names
      data_point=120
      unix_time = dblarr(n_elements(time))
      height2 = fltarr(n_elements(data_point))
      uwind_mu=fltarr(n_elements(time),data_point)+!values.f_nan
      vwind_mu=fltarr(n_elements(time),data_point)+!values.f_nan
      wwind_mu=fltarr(n_elements(time),data_point)+!values.f_nan
      pwr1_mu=fltarr(n_elements(time),data_point,n_elements(beam))+!values.f_nan
      wdt1_mu=fltarr(n_elements(time),data_point,n_elements(beam))+!values.f_nan
      dpl1_mu=fltarr(n_elements(time),data_point,n_elements(beam))+!values.f_nan
      pnoise1_mu=fltarr(n_elements(time),n_elements(beam))+!values.f_nan

     ;---File search:
      fname=strsplit(strmid(file,10,13,/REVERSE_OFFSET),'.',/extract)
      idx=where(fname[0] eq f_list)
     
     ;---Definition of altitude and data arraies:     
      altitude = fltarr(120)
    
     ;---Enter the altitude information:
      if idx eq -1 then begin
         height_vw = float(height_v)
         height_mwzw = float(height_zm)
         height2 = float(height_vw)
      endif else begin
         height_vw = float(height_vw)
         height_mwzw = float(height_mwzw)
         height2 = float(height_vw)
      endelse
         
      for i=0L, n_elements(time)-1 do begin
        ;---Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)    
         unix_time[i] = double(time[i]) +time_double(syymmdd+'/'+shhmmss)-time_diff2 
        
        ;---Replace missing value by NaN:
         d_num=n_elements(range)
         st_num=120-d_num                       
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
            uwind_mu[i,st_num+k]=uwind[k,i]
            vwind_mu[i,st_num+k]=vwind[k,i]
            wwind_mu[i,st_num+k]=wwind[k,i]           
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
               pwr1_mu[i,st_num+k,l]=pwr[k,i,l]
               wdt1_mu[i,st_num+k,l]=width[k,i,l]
               dpl1_mu[i,st_num+k,l]=dpl[k,i,l]
               pnoise1_mu[i,l]=pnoise[i,l]
            endfor 
         endfor
      endfor


     ;==============================
     ;Append array of time and data:
     ;==============================
      append_array, mu_time, unix_time
      append_array, zon_wind, uwind_mu
      append_array, mer_wind, vwind_mu
      append_array, ver_wind, wwind_mu
      append_array, pwr1, pwr1_mu
      append_array, wdt1, wdt1_mu
      append_array, dpl1, dpl1_mu
      append_array, pn1, pnoise1_mu

      ncdf_close,cdfid  ; done   
   endfor

  ;==============================================================
  ;Change time window associated with a time shift from UT to LT:
  ;==============================================================
   timespan, time_org
   get_timespan, init_time2
   if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) - 9.0d * 3600.0d); for GUI
   
   if n_elements(mu_time) gt 1 then begin
     ;---Definition of arrary names
      bname2=strarr(n_elements(beam))
      bname=strarr(n_elements(beam))
      pwr2_mu=fltarr(n_elements(mu_time),120)
      wdt2_mu=fltarr(n_elements(mu_time),120)
      dpl2_mu=fltarr(n_elements(mu_time),120)
      pnoise2_mu=fltarr(n_elements(mu_time)) 
   
     ;==============================
     ;Store data in TPLOT variables:
     ;==============================
     ;---Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'If you acquire the middle and upper atmospher (MU) radar data, ' $
                       + 'we ask that you acknowledge us in your use of the data. This may be done by ' $
                       + 'including text such as the MU data provided by Research Institute ' $
                       + 'for Sustainable Humanosphere of Kyoto University. We would also ' $
                       + 'appreciate receiving a copy of the relevant publications. '$
                       + 'The distribution of MU radar data has been partly supported by the IUGONET '$
                       + '(Inter-university Upper atmosphere Global Observation NETwork) project '$
                       + '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, '$
                       + 'Sports, Science and Technology (MEXT), Japan.'
                    
      if size(pwr1,/type) eq 4 then begin
        ;---Create tplot variable for zonal wind:
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'H. Hashiguchi'))        
         store_data,'iug_mu_trop_uwnd',data={x:mu_time, y:zon_wind, v:height_mwzw},dlimit=dlimit

        ;----Edge data cut:
         time_clip,'iug_mu_trop_uwnd', init_time2[0], init_time2[1], newname = 'iug_mu_trop_uwnd'
         
        ;---Add options and tdegap:
         new_vars=tnames('iug_mu_trop_uwnd')
         if new_vars[0] ne '' then begin         
            options,'iug_mu_trop_uwnd',ytitle='MUR-trop!CHeight!C[km]',ztitle='uwnd!C[m/s]'
            options, 'iug_mu_trop_uwnd','spec',1
            tdegap, 'iug_mu_trop_uwnd',/overwrite
         endif 
          
        ;---Create tplot variable for meridional wind:
         store_data,'iug_mu_trop_vwnd',data={x:mu_time, y:mer_wind, v:height_mwzw},dlimit=dlimit

        ;----Edge data cut:
         time_clip,'iug_mu_trop_vwnd', init_time2[0], init_time2[1], newname = 'iug_mu_trop_vwnd'
        
        ;---Add options and tdegap:
         new_vars=tnames('iug_mu_trop_vwnd')
         if new_vars[0] ne '' then begin           
            options,'iug_mu_trop_vwnd',ytitle='MUR-trop!CHeight!C[km]',ztitle='vwnd!C[m/s]'
            options, 'iug_mu_trop_vwnd','spec',1
            tdegap, 'iug_mu_trop_vwnd',/overwrite
         endif       
         
        ;---Create tplot variable for vertical wind:
         store_data,'iug_mu_trop_wwnd',data={x:mu_time, y:ver_wind, v:height_vw},dlimit=dlimit

        ;----Edge data cut:
         time_clip,'iug_mu_trop_wwnd', init_time2[0], init_time2[1], newname = 'iug_mu_trop_wwnd'
        
        ;---Add options and tdegap:
         new_vars=tnames('iug_mu_trop_wwnd')
         if new_vars[0] ne '' then begin         
            options,'iug_mu_trop_wwnd',ytitle='MUR-trop!CHeight!C[km]',ztitle='wwnd!C[m/s]'
            options, 'iug_mu_trop_wwnd','spec',1
            tdegap, 'iug_mu_trop_wwnd',/overwrite
         endif           
        
        ;Create tplot variables for echo intensity, spectral width, Doppler velocity and niose level:
         for l=0L, n_elements(beam)-1 do begin
            bname2[l]=string(beam[l]+1)
            bname[l]=strsplit(bname2[l],' ', /extract)
            for i=0L, n_elements(mu_time)-1 do begin
               for k=0L, 119 do begin
                  pwr2_mu[i,k]=pwr1[i,k,l]
               endfor
            endfor
          
           ;---Create tplot variable for echo power:
            store_data,'iug_mu_trop_pwr'+bname[l],data={x:mu_time, y:pwr2_mu, v:height2},dlimit=dlimit

           ;----Edge data cut:
            time_clip,'iug_mu_trop_pwr'+bname[l], init_time2[0], init_time2[1], newname = 'iug_mu_trop_pwr'+bname[l]
          
           ;---Add options and tdegap:
            new_vars=tnames('iug_mu_trop_pwr*')
            if new_vars[0] ne '' then begin
               options,'iug_mu_trop_pwr'+bname[l],ytitle='MUR-trop!CHeight!C[km]',ztitle='pwr'+bname[l]+'!C[dB]'
               options, 'iug_mu_trop_pwr'+bname[l],'spec',1
               tdegap, 'iug_mu_trop_pwr'+bname[l],/overwrite
            endif  
            for i=0L, n_elements(mu_time)-1 do begin
               for k=0L, 119 do begin
                  wdt2_mu[i,k]=wdt1[i,k,l]
               endfor
            endfor
            
           ;---Create tplot variable for spectral width: 
            store_data,'iug_mu_trop_wdt'+bname[l],data={x:mu_time, y:wdt2_mu, v:height2},dlimit=dlimit

           ;----Edge data cut:
            time_clip,'iug_mu_trop_wdt'+bname[l], init_time2[0], init_time2[1], newname = 'iug_mu_trop_wdt'+bname[l]
           
           ;---Add options and tdegap:
            new_vars=tnames('iug_mu_trop_wdt*')
            if new_vars[0] ne '' then begin
               options,'iug_mu_trop_wdt'+bname[l],ytitle='MUR-trop!CHeight!C[km]',ztitle='wdt'+bname[l]+'!C[m/s]'
               options, 'iug_mu_trop_wdt'+bname[l],'spec',1
               tdegap, 'iug_mu_trop_wdt'+bname[l],/overwrite 
            endif
            for i=0L, n_elements(mu_time)-1 do begin
               for k=0L, 119 do begin
                  dpl2_mu[i,k]=dpl1[i,k,l]
               endfor
            endfor   
            
           ;---Create tplot variable for Doppler velocity:          
            store_data,'iug_mu_trop_dpl'+bname[l],data={x:mu_time, y:dpl2_mu, v:height2},dlimit=dlimit

           ;----Edge data cut:
            time_clip,'iug_mu_trop_dpl'+bname[l], init_time2[0], init_time2[1], newname = 'iug_mu_trop_dpl'+bname[l]
            
           ;---Add options and tdegap: 
            new_vars=tnames('iug_mu_trop_dpl*')
            if new_vars[0] ne '' then begin
               options,'iug_mu_trop_dpl'+bname[l],ytitle='MUR-trop!CHeight!C[km]',ztitle='dpl'+bname[l]+'!C[m/s]'
               options, 'iug_mu_trop_dpl'+bname[l],'spec',1
               tdegap, 'iug_mu_trop_dpl'+bname[l],/overwrite 
            endif
            for i=0L, n_elements(mu_time)-1 do begin
               pnoise2_mu[i]=pn1[i,l]
            endfor
           
           ;---Create tplot variable for noise level:
            store_data,'iug_mu_trop_pn'+bname[l],data={x:mu_time, y:pnoise2_mu},dlimit=dlimit

           ;----Edge data cut:
            time_clip,'iug_mu_trop_pn'+bname[l], init_time2[0], init_time2[1], newname = 'iug_mu_trop_pn'+bname[l]
            
           ;---Add options and tdegap:
            new_vars=tnames('iug_mu_trop_pn*')
            if new_vars[0] ne '' then begin
               options,'iug_mu_trop_pn'+bname[l],ytitle='MUR-trop!Cpn'+bname[l]+'!C[dB]'
               tdegap, 'iug_mu_trop_pn'+bname[l],/overwrite   
            endif                 
         endfor    
      endif
      new_vars=tnames('iug_mu_trop_*')
      if new_vars[0] ne '' then begin    
         print,'**********************************************************************************
         print,'Data loading is successful!!'
         print,'**********************************************************************************
      endif
   endif
endif

;---Clear time and data buffer:
mu_time=0
zon_wind=0
mer_wind=0
ver_wind=0
pwr1 = 0
wdt1 = 0
dpl1 = 0
pn1 = 0

;---Initialization of timespan for parameters:
timespan, time_org
      
;*************************
;Print of acknowledgement:
;*************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire the middle and upper atmosphere (MU) radar data,'
print, 'we ask that you acknowledge us in your use of the data.' 
print, 'This may be done by including text such as MU data provided' 
print, 'by Research Institute for Sustainable Humanosphere of Kyoto University.' 
print, 'We would also appreciate receiving a copy of the relevant publications.'
print, 'The distribution of MU radar data has been partly supported by the IUGONET'
print, '(Inter-university Upper atmosphere Global Observation NETwork) project'
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture,'
print, 'Sports, Science and Technology (MEXT), Japan.'  
    
end
