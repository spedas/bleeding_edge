;+
;
;Name:
;iug_load_mf_rish_pon_txt
;
;Purpose:
;  Queries the Kyoto_RISH renkei2 servers for pontianak data and loads data into
;  tplot format.
;
;Syntax:
; iug_load_mf_rish_pon_txt, downloadonly = downloadonly, trange = trange, verbose = verbose
;
;Keywords:
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
;
;Code:
;  A. Shinbori, 10/09/2010.
;
;Modifications:
;  A. Shinbori, 05/06/2011.
;  A. Shinbori, 24/01/2014.
;  
;Acknowledgment:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_mf_rish_pon_txt, downloadonly=downloadonly, $
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
      file_format='YYYY/'+$
      'YYYYMMDD',trange=trange,times=times,/unique)+'_fca.txt'
  
  ;===============================        
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/pon/mf/text/
   source.remote_data_dir = 'http://database.rish.kyoto-u.ac.jp/arch/iugonet/data/mf/pontianak/text/'
  
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

  ;---Initialize data and time buffer
   pon_time=0
   zon_wind=0
   mer_wind=0
   ver_wind=0
  
  ;==============
  ;Loop on files: 
  ;==============
   for j=0L,n_elements(local_paths)-1 do begin
      file= local_paths[j]
      if file_test(/regular,file) then  dprint,'Loading Pontianak file: ',file $
      else begin
         dprint,'Pontianak file ',file,' not found. Skipping'
         continue
      endelse
      
     ;---Open the read file:
      openr,lun,file,/get_lun    
     
     ;==================
     ;Loop on read data:
     ;==================
      while(not eof(lun)) do begin

        ;---Definition of height and wind arrays:
         height = fltarr(21)
         zon_wind_data = fltarr(1,21)
         mer_wind_data = fltarr(1,21)
         ver_wind_data = fltarr(1,21)
        
        ;==============
        ;Read data set:
        ;==============
         for k=0L,n_elements(height)-1 do begin
            readf,lun,s
            data1 = strsplit(s,' ',/EXTRACT)
           
           ;=================================
           ;Get information of date and time:
           ;=================================
            if k eq 0 then begin
               year = fix(data1[0])
               month = fix(data1[1])
               day = fix(data1[2])
               hour = fix(data1[3])
               minute = fix(data1[4])
               second=0               
            endif
           
           ;---Get information of height and winds: 
            height[k] = float(data1[5])
            zon_wind_data[0,k] = float(data1[6])
            mer_wind_data[0,k] = float(data1[7])
            ver_wind_data[0,k] = float(data1[8])
           
           ;---Replace the missing value (-9999.00) into NaN:
            a = zon_wind_data[0,k]            
            wbad = where(a eq -9999.00,nbad)
            if nbad gt 0 then a[wbad] = !values.f_nan
            zon_wind_data[0,k]=a
            b = mer_wind_data[0,k]
            wbad = where(b eq -9999.00,nbad)
            if nbad gt 0 then b[wbad] = !values.f_nan
            mer_wind_data[0,k]=b
            c = mer_wind_data[0,k]
            wbad = where(c eq -9999.00,nbad)
            if nbad gt 0 then c[wbad] = !values.f_nan
            mer_wind_data[0,k]=c                     
         endfor
           
        ;---Convert time from universal time to unix time:   
         time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+string(hour)+':'+string(minute)+':'+string(second))
           
        ;=============================
        ;Append data of time and data:
        ;=============================       
         append_array, pon_time_1, time
         append_array, zon_wind_1, zon_wind_data
         append_array, mer_wind_1, mer_wind_data 
         append_array, ver_wind_1, ver_wind_data                  
      endwhile 
      free_lun,lun
     
     ;---Clear buffer: 
      time=0
      zon_wind_data=0
      mer_wind_data=0
      ver_wind_data=0

     ;=============================
     ;Append data of time and data:
     ;=============================       
      append_array, pon_time, pon_time_1
      append_array, zon_wind, zon_wind_1
      append_array, mer_wind, mer_wind_1 
      append_array, ver_wind, ver_wind_1
     
     ;---Clear buffer: 
      pon_time_1=0
      zon_wind_1=0
      mer_wind_1=0
      ver_wind_1=0   
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
  
        ;---Add options of setting lanels
         options, 'iug_mf_pon_uwnd', labels='MFR-pon [km]'
         options, 'iug_mf_pon_vwnd', labels='MFR-pon [km]'
         options, 'iug_mf_pon_wwnd', labels='MFR-pon [km]'
     
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
    
  ;---Clear time and data buffer:
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
print, 'If you acquire MF radar data, we ask that you acknowledge us'
print, 'in your use of the data. This may be done by including text' 
print, 'such as MF radar data provided by Research Institute for Sustainable' 
print, 'Humanosphere of Kyoto University. We would also appreciate receiving' 
print, 'a copy of the relevant publications.'

end

