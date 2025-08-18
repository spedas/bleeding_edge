;+
;
;NAME:
;iug_load_mf_rish_pam_bin
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the observation data (uwind, vwind, wwind)
;  in the binary format (SSWMA) taken by the MF radar at Pameungpeuk and loads data into
;  tplot format.
;
;SYNTAX:
; iug_load_mf_rish_pam_bin, downloadonly=downloadonly, trange=trange, verbose=verbose
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
; A. Shinbori, 09/19/2010.
;
;MODIFICATIONS:
; A. Shinbori, 03/24/2011.
; A. Shinbori, 27/12/2011.
; A. Shinbori, 24/12/2011.
; A. Shinbori, 24/01/2014.
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_mf_rish_pam_bin, downloadonly=downloadonly, $
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
   file_format='YYYY/pameungpeuk.YYYYMMDD',trange=trange,times=times,/unique)+'.sswma'
   
  ;===============================            
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/pam/mf/binary/'
   source.remote_data_dir = 'http://database.rish.kyoto-u.ac.jp/arch/iugonet/data/mf/pameungpeuk/binary/'
  
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
  ;---Definition of arrays and variables:
   height = fltarr(36)
   analysis_status_data = fltarr(1,36)
   zon_wind_data = fltarr(1,36)
   mer_wind_data = fltarr(1,36)
   ver_wind_data = fltarr(1,36)
   uncorrected_zon_wind_data = fltarr(1,36)
   uncorrected_mer_wind_data = fltarr(1,36)
   corrected_fading_time_data = fltarr(1,36)
   uncorrected_fading_time_data = fltarr(1,36)  
   normalized_time_discrepacy_data= fltarr(1,36) 
   ellipse_major_axis_length_data= fltarr(1,36) 
   ellipse_axial_ratio_data= fltarr(1,36)
   ellipse_orientation_data= fltarr(1,36)
   receiver_snr1_data= fltarr(1,36)
   receiver_snr2_data= fltarr(1,36)
   receiver_snr3_data= fltarr(1,36)
   cross_channel_nsr1_data= fltarr(1,36)
   cross_channel_nsr2_data= fltarr(1,36)
   cross_channel_nsr3_data= fltarr(1,36)
   sea_scatter_relative_power1_data= fltarr(1,36)
   sea_scatter_relative_power2_data= fltarr(1,36)
   sea_scatter_relative_power3_data= fltarr(1,36)
             
   pam_time=0
   analysis_status=0
   zon_wind=0
   mer_wind=0
   ver_wind=0
   uncorrected_zon_wind=0
   uncorrected_mer_wind=0
   corrected_fading_time=0
   uncorrected_fading_time=0
   normalized_time_discrepacy=0
   ellipse_major_axis_length=0
   ellipse_axial_ratio=0
   ellipse_orientation=0
   receiver_snr1=0
   receiver_snr2=0
   receiver_snr3=0
   cross_channel_nsr1=0
   cross_channel_nsr2=0
   cross_channel_nsr3=0
   sea_scatter_relative_power1=0
   sea_scatter_relative_power2=0
   sea_scatter_relative_power3=0
  
  ;==============       
  ;Loop on files: 
  ;==============
   for j=0L,n_elements(local_paths)-1 do begin
      file= local_paths[j]
      if file_test(/regular,file) then  dprint,'Loading pameungpeuk sswma file: ',file $
      else begin
         dprint,'pameungpeuk sswma file ',file,' not found. Skipping'
         continue
      endelse
      
     ;---Open the read file:
      openr,lun,file,/get_lun 
   
     ;---Information of year, month and day:
      year = strmid(file,42,4)
      month = strmid(file,46,2)
      day = strmid(file,48,2)
     
     ;==========
     ;Read data:
     ;==========
      readf,lun
     
     ;=================
     ;Read file header:
     ;=================
      file_header_bytes = assoc(lun, lonarr(1))
      file_header_names = ["File magic number (0x23110001)", $
                           "No.of SSWMA records in this file (0 or more)", $
                           "Offset to start of first record from start of file", $
                           "Unit ID or serial number"]
      sswma_records = file_header_bytes[1]
      for i = 0, 3 do begin
         print, file_header_names[i]
         print, file_header_bytes[i]
      endfor
      offset = 48L

     ;===================
     ;Read record header:
     ;=================== 
      m=0 
      for k = 1L, sswma_records[0] do begin
        ;===============
        ;Read UNIX time:
        ;===============
         epoch_time_stamp = assoc(lun, lonarr(1), offset+16)
         millisecond_time_stamp = assoc(lun, lonarr(1), offset+20)
        ;print, epoch_time_stamp[0], millisecond_time_stamp[0]
        ;
        ;===============
        ;Read UNIX time:
        ;=============== 
         epoch_time = float(epoch_time_stamp[0]) + float(millisecond_time_stamp[0])/1000  
             
        ;===============================
        ;Read the number of range gates:
        ;=============================== 
         offset += 116
         record_header_bytes3 = assoc(lun, lonarr(1), offset)
         number_of_range_gates_sampled = record_header_bytes3[0]
         offset += 132
         
        ;========================
        ;Enter the missing value:
        ;========================
         for mm=0, 35 do begin   
            analysis_status_data[*,mm]= !values.f_nan        
            zon_wind_data[*,mm]= !values.f_nan
            mer_wind_data[*,mm]= !values.f_nan
            ver_wind_data[*,mm]= !values.f_nan
            uncorrected_zon_wind_data[*,mm]= !values.f_nan
            uncorrected_mer_wind_data[*,mm]= !values.f_nan
            corrected_fading_time_data[*,mm] = !values.f_nan
            uncorrected_fading_time_data[*,mm] = !values.f_nan
            normalized_time_discrepacy_data[*,mm]=!values.f_nan
            ellipse_major_axis_length_data[*,mm]=!values.f_nan
            ellipse_axial_ratio_data[*,mm]=!values.f_nan
            ellipse_orientation_data[*,mm]=!values.f_nan
            receiver_snr1_data[*,mm]=!values.f_nan
            receiver_snr2_data[*,mm]=!values.f_nan
            receiver_snr3_data[*,mm]=!values.f_nan
            cross_channel_nsr1_data[*,mm]=!values.f_nan
            cross_channel_nsr2_data[*,mm]=!values.f_nan
            cross_channel_nsr3_data[*,mm]=!values.f_nan
            sea_scatter_relative_power1_data[*,mm]=!values.f_nan
            sea_scatter_relative_power2_data[*,mm]=!values.f_nan
            sea_scatter_relative_power3_data[*,mm]=!values.f_nan
         endfor
        
        ;=============== 
        ;Results Header:
        ;===============
         n=0
         fill_value=-9999
         for l = 1L, number_of_range_gates_sampled[0] do begin
            record_header_bytes10 = assoc(lun, lonarr(1), offset+0)
            height[n] =float(record_header_bytes10[0])/1000;Range [km]
            record_header_bytes11 = assoc(lun, intarr(1), offset+4)
            ba=record_header_bytes11[0]
           ; wbad = where(ba lt 0,nbad)
           ; if nbad gt 0 then ba[wbad] = !values.f_nan              
            analysis_status_data[m,n] =ba
            if analysis_status_data[m,n] eq 0 then begin
               record_header_bytes12 = assoc(lun, fltarr(1), offset+8)
               a = record_header_bytes12[0];zonal_wind
               wbad = where(a eq fill_value,nbad)
               if nbad gt 0 then a[wbad] = !values.f_nan
               zon_wind_data[m,n]=a
               record_header_bytes13 = assoc(lun, fltarr(1), offset+12)
               b= record_header_bytes13[0];meridional_wind
               wbad = where(b eq fill_value,nbad)
               if nbad gt 0 then b[wbad] = !values.f_nan
               mer_wind_data[m,n] = b
               record_header_bytes14 = assoc(lun, fltarr(1), offset+16)
               c= record_header_bytes14[0];vertical_wind
               wbad = where(c eq fill_value,nbad)
               if nbad gt 0 then c[wbad] = !values.f_nan
               ver_wind_data[m,n] = c
               
               record_header_bytes15 = assoc(lun, fltarr(1), offset+20)
               d= record_header_bytes15[0];uncorrected zonal wind velocity
               wbad = where(d eq fill_value,nbad)
               if nbad gt 0 then d[wbad] = !values.f_nan
               uncorrected_zon_wind_data[m,n] = d
               record_header_bytes16 = assoc(lun, fltarr(1), offset+24)
               e= record_header_bytes16[0];uncorrected meridional wind velocity
               wbad = where(e eq fill_value,nbad)
               if nbad gt 0 then e[wbad] = !values.f_nan
               uncorrected_mer_wind_data[m,n] = e 
               
               record_header_bytes17 = assoc(lun, fltarr(1), offset+28)
               f = record_header_bytes17[0];uncorrected fading time
               wbad = where(f eq fill_value,nbad)
               if nbad gt 0 then f[wbad] = !values.f_nan
               corrected_fading_time_data[m,n] = f                
               record_header_bytes18 = assoc(lun, fltarr(1), offset+32)
               g = record_header_bytes18[0];uncorrected fading time
               wbad = where(g eq fill_value,nbad)
               if nbad gt 0 then g[wbad] = !values.f_nan
               uncorrected_fading_time_data[m,n] = g  
                             
               record_header_bytes19 = assoc(lun, fltarr(1), offset+36)
               h = record_header_bytes19[0];normalized time discrepacy
               wbad = where(h eq fill_value,nbad)
               if nbad gt 0 then h[wbad] = !values.f_nan
               normalized_time_discrepacy_data[m,n] = h   
                              
               record_header_bytes20 = assoc(lun, fltarr(1), offset+40)
               aa = record_header_bytes20[0];ellipse major axis length 
               wbad = where(aa eq fill_value,nbad)
               if nbad gt 0 then aa[wbad] = !values.f_nan
               ellipse_major_axis_length_data[m,n] = aa                 
               record_header_bytes21 = assoc(lun, fltarr(1), offset+44)
               ab = record_header_bytes21[0];ellipse axial ratio
               wbad = where(ab eq fill_value,nbad)
               if nbad gt 0 then ab[wbad] = !values.f_nan
               ellipse_axial_ratio_data[m,n] = ab  
               record_header_bytes22 = assoc(lun, fltarr(1), offset+48)
               ac = record_header_bytes22[0];ellipse orientation 
               wbad = where(ac eq fill_value,nbad)
               if nbad gt 0 then ac[wbad] = !values.f_nan    
               ellipse_orientation_data[m,n]=ac 
               
                record_header_bytes23 = assoc(lun, fltarr(1), offset+60+36)
                ad = record_header_bytes23[0];Receiver SNR-1 
                wbad = where(ad eq fill_value,nbad)
                if nbad gt 0 then ad[wbad] = !values.f_nan    
                receiver_snr1_data[m,n]=ad 
                record_header_bytes24 = assoc(lun, fltarr(1), offset+60+36+4)
                ae = record_header_bytes24[0];Receiver SNR-2 
                wbad = where(ae eq fill_value,nbad)
                if nbad gt 0 then ae[wbad] = !values.f_nan    
                receiver_snr2_data[m,n]=ae 
                record_header_bytes25 = assoc(lun, fltarr(1), offset+60+36+8)
                af = record_header_bytes25[0];Receiver SNR-3 
                wbad = where(af eq fill_value,nbad)
                if nbad gt 0 then af[wbad] = !values.f_nan    
                receiver_snr3_data[m,n]=af 
                 
                record_header_bytes26 = assoc(lun, fltarr(1), offset+60+60)
                ag = record_header_bytes26[0];Cross channel NSR-1
                wbad = where(ag eq fill_value,nbad)
                if nbad gt 0 then ag[wbad] = !values.f_nan    
                cross_channel_nsr1_data[m,n]=ag 
                record_header_bytes27 = assoc(lun, fltarr(1), offset+60+60+4)
                ah = record_header_bytes27[0];Cross channel NSR-2 
                wbad = where(ah eq fill_value,nbad)
                if nbad gt 0 then ah[wbad] = !values.f_nan    
                cross_channel_nsr2_data[m,n]=ah 
                record_header_bytes28 = assoc(lun, fltarr(1), offset+60+60+8)
                ai = record_header_bytes28[0];Cross channel NSR-3 
                wbad = where(ai eq fill_value,nbad)
                if nbad gt 0 then ai[wbad] = !values.f_nan    
                cross_channel_nsr3_data[m,n]=ai 
               
                record_header_bytes26 = assoc(lun, fltarr(1), offset+60+60)
                ag = record_header_bytes26[0];Cross channel NSR-1
                wbad = where(ag eq fill_value,nbad)
                if nbad gt 0 then ag[wbad] = !values.f_nan    
                cross_channel_nsr1_data[m,n]=ag 
                record_header_bytes27 = assoc(lun, fltarr(1), offset+60+60+4)
                ah = record_header_bytes27[0];Cross channel NSR-2 
                wbad = where(ah eq fill_value,nbad)
                if nbad gt 0 then ah[wbad] = !values.f_nan    
                cross_channel_nsr2_data[m,n]=ah 
                record_header_bytes28 = assoc(lun, fltarr(1), offset+60+60+8)
                ai = record_header_bytes28[0];Cross channel NSR-3 
                wbad = where(ai eq fill_value,nbad)
                if nbad gt 0 then ai[wbad] = !values.f_nan    
                cross_channel_nsr3_data[m,n]=ai 
                  
                record_header_bytes29 = assoc(lun, fltarr(1), offset+60+60+12)
                aj = record_header_bytes29[0];Sea scatter relative power-1
                wbad = where(aj eq fill_value,nbad)
                if nbad gt 0 then aj[wbad] = !values.f_nan    
                sea_scatter_relative_power1_data[m,n]=aj
                record_header_bytes30 = assoc(lun, fltarr(1), offset+60+60+12+4)
                ak = record_header_bytes30[0];Sea scatter relative power-2
                wbad = where(ak eq fill_value,nbad)
                if nbad gt 0 then ak[wbad] = !values.f_nan    
                sea_scatter_relative_power2_data[m,n]=ak 
                record_header_bytes31 = assoc(lun, fltarr(1), offset+60+60+12+8)
                al = record_header_bytes31[0];Sea scatter relative power-3
                wbad = where(al eq fill_value,nbad)
                if nbad gt 0 then al[wbad] = !values.f_nan    
                sea_scatter_relative_power3_data[m,n]=al 
             endif                                                             
             offset += 144
             n=n+1
          endfor
           
          for i=0L,n_elements(height)-1 do begin
             f=height[i]
             wbad = where(f eq 0,nbad)
             if nbad gt 0 then f[wbad] = !values.f_nan
             height[i] = f
          endfor

         ;=============================
         ;Append data of time and data:
         ;=============================
          append_array, pam_time, epoch_time
          append_array, zon_wind, zon_wind_data
          append_array, mer_wind, mer_wind_data
          append_array, ver_wind, ver_wind_data
          append_array, uncorrected_zon_wind, uncorrected_zon_wind_data
          append_array, uncorrected_mer_wind, uncorrected_mer_wind_data
          append_array, corrected_fading_time, corrected_fading_time_data
          append_array, uncorrected_fading_time, uncorrected_fading_time_data
          append_array, normalized_time_discrepacy, normalized_time_discrepacy_data
          append_array, ellipse_major_axis_length, ellipse_major_axis_length_data           
          append_array, ellipse_axial_ratio, ellipse_axial_ratio_data
          append_array, ellipse_orientation, ellipse_orientation_data
          append_array, receiver_snr1, receiver_snr1_data
          append_array, receiver_snr2, receiver_snr2_data
          append_array, receiver_snr3, receiver_snr3_data
          append_array, cross_channel_nsr1, cross_channel_nsr1_data
          append_array, cross_channel_nsr2, cross_channel_nsr2_data
          append_array, cross_channel_nsr3, cross_channel_nsr3_data
          append_array, sea_scatter_relative_power1, sea_scatter_relative_power1_data
          append_array, sea_scatter_relative_power2, sea_scatter_relative_power2_data
          append_array, sea_scatter_relative_power3, sea_scatter_relative_power3_data
       endfor
       free_lun,lun
    endfor
   
   ;==============================
   ;Store data in TPLOT variables:
   ;==============================
   ;---Acknowlegment string (use for creating tplot vars)
    acknowledgstring = 'Note: If you would like to use following data for scientific purpose, please read and keep the DATA USE POLICY '$
                     +'(http://database.rish.kyoto-u.ac.jp/arch/iugonet/data_policy/Data_Use_Policy_e.html '$ 
                     +'The distribution of MF radar data has been partly supported by the IUGONET (Inter-university Upper '$
                     + 'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '$
                     + 'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'  
    
    if size(zon_wind,/type) eq 4 then begin
      ;---Create tplot variables and options
       dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Tsuda'))     
       store_data,'iug_mf_pam_uwnd',data={x:pam_time, y:zon_wind, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_uwnd')
       if new_vars[0] ne '' then begin 
          options,'iug_mf_pam_uwnd',ytitle='MF-pam!Cheight!C[km]',ztitle='uwnd!C[m/s]'
       endif
       store_data,'iug_mf_pam_vwnd',data={x:pam_time, y:mer_wind, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_uwnd')
       if new_vars[0] ne '' then begin      
          options,'iug_mf_pam_vwnd',ytitle='MF-pam!Cheight!C[km]',ztitle='vwnd!C[m/s]'
       endif
       store_data,'iug_mf_pam_wwnd',data={x:pam_time, y:ver_wind, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_wwnd')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_wwnd',ytitle='MF-pam!Cheight!C[km]',ztitle='wwnd!C[m/s]'
       endif
       store_data,'iug_mf_pam_uncorrected_uwnd',data={x:pam_time, y:uncorrected_zon_wind, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_uncorrected_uwnd')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_uncorrected_uwnd',ytitle='MF-pam!Cheight!C[km]',ztitle='uncorrected uwnd!C[m/s]'
       endif
       store_data,'iug_mf_pam_uncorrected_vwnd',data={x:pam_time, y:uncorrected_mer_wind, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_uncorrected_vwnd')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_uncorrected_vwnd',ytitle='MF-pam!Cheight!C[km]',ztitle='uncorrected vwnd!C[m/s]'
       endif
       store_data,'iug_mf_pam_fading_time',data={x:pam_time, y:corrected_fading_time, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_fading_time')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_fading_time',ytitle='MF-pam!Cheight!C[km]',ztitle='fading time!C[sec]' 
       endif
       store_data,'iug_mf_pam_uncorrected_fading_time',data={x:pam_time, y:uncorrected_fading_time, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_uncorrected_fading_time')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_uncorrected_fading_time',ytitle='MF-pam!Cheight!C[km]',ztitle='uncorrected fading time!C[sec]' 
       endif
       store_data,'iug_mf_pam_normalized_time_discrepacy',data={x:pam_time, y:normalized_time_discrepacy, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_normalized_time_discrepacy')
       if new_vars[0] ne '' then begin      
          options,'iug_mf_pam_normalized_time_discrepacy',ytitle='MF-pam!Cheight!C[km]',ztitle='normalized time discrepacy!C[%]'
       endif
       store_data,'iug_mf_pam_ellipse_major_axis_length',data={x:pam_time, y:ellipse_major_axis_length, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_ellipse_major_axis_length')
       if new_vars[0] ne '' then begin 
          options,'iug_mf_pam_ellipse_major_axis_length',ytitle='MF-pam!Cheight!C[km]',ztitle='ellipse major axis length'
       endif
       store_data,'iug_mf_pam_ellipse_axial_ratio',data={x:pam_time, y:ellipse_axial_ratio, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_ellipse_axial_ratio')
       if new_vars[0] ne '' then begin 
          options,'iug_mf_pam_ellipse_axial_ratio',ytitle='MF-pam!Cheight!C[km]',ztitle='ellipse axial ratio'
       endif
       store_data,'iug_mf_pam_ellipse_orientation',data={x:pam_time, y:ellipse_orientation, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_ellipse_orientation')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_ellipse_orientation',ytitle='MF-pam!Cheight!C[km]',ztitle='ellipse orientation!C[deg]'
       endif
       store_data,'iug_mf_pam_receiver_snr1',data={x:pam_time, y:receiver_snr1, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_receiver_snr1')
       if new_vars[0] ne '' then begin 
          options,'iug_mf_pam_receiver_snr1',ytitle='MF-pam!Cheight!C[km]',ztitle='receiver snr1!C[dB]'
       endif
       store_data,'iug_mf_pam_receiver_snr2',data={x:pam_time, y:receiver_snr2, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_receiver_snr2')
       if new_vars[0] ne '' then begin 
          options,'iug_mf_pam_receiver_snr2',ytitle='MF-pam!Cheight!C[km]',ztitle='receiver snr2!C[dB]'
       endif
       store_data,'iug_mf_pam_receiver_snr3',data={x:pam_time, y:receiver_snr3, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_receiver_snr3')
       if new_vars[0] ne '' then begin 
          options,'iug_mf_pam_receiver_snr3',ytitle='MF-pam!Cheight!C[km]',ztitle='receiver snr3!C[dB]'
       endif
       store_data,'iug_mf_pam_cross_channel_nsr1',data={x:pam_time, y:cross_channel_nsr1, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_cross_channel_nsr1')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_cross_channel_nsr1',ytitle='MF-pam!Cheight!C[km]',ztitle='cross channel nsr1!C[dB]'
       endif
       store_data,'iug_mf_pam_cross_channel_nsr2',data={x:pam_time, y:cross_channel_nsr2, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_cross_channel_nsr2')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_cross_channel_nsr2',ytitle='MF-pam!Cheight!C[km]',ztitle='cross channel nsr2!C[dB]'
       endif
       store_data,'iug_mf_pam_cross_channel_nsr3',data={x:pam_time, y:cross_channel_nsr3, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_cross_channel_nsr3')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_cross_channel_nsr3',ytitle='MF-pam!Cheight!C[km]',ztitle='cross channel nsr3!C[dB]' 
       endif
       store_data,'iug_mf_pam_sea_scatter_relative_power1',data={x:pam_time, y:sea_scatter_relative_power1, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_sea_scatter_relative_power1')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_sea_scatter_relative_power1',ytitle='MF-pam!Cheight!C[km]',ztitle='sea scatter relative power1!C[dB]'
       endif
       store_data,'iug_mf_pam_sea_scatter_relative_power2',data={x:pam_time, y:sea_scatter_relative_power2, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_sea_scatter_relative_power2')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_sea_scatter_relative_power2',ytitle='MF-pam!Cheight!C[km]',ztitle='sea scatter relative power2!C[dB]'
       endif
       store_data,'iug_mf_pam_sea_scatter_relative_power3',data={x:pam_time, y:sea_scatter_relative_power3, v:height},dlimit=dlimit
       new_vars=tnames('iug_mf_pam_sea_scatter_relative_power3')
       if new_vars[0] ne '' then begin
          options,'iug_mf_pam_sea_scatter_relative_power3',ytitle='MF-pam!Cheight!C[km]',ztitle='sea scatter relative power3!C[dB]'  
       endif     
            
      ;---Add options
       new_vars=tnames('iug_mf_pam_*')
       if new_vars[0] ne '' then begin
          options, ['iug_mf_pam_uwnd','iug_mf_pam_vwnd','iug_mf_pam_wwnd',$
                    'iug_mf_pam_uncorrected_uwnd','iug_mf_pam_uncorrected_vwnd', $
                    'iug_mf_pam_fading_time','iug_mf_pam_uncorrected_fading_time', $
                    'iug_mf_pam_normalized_time_discrepacy','iug_mf_pam_ellipse_major_axis_length',$
                    'iug_mf_pam_ellipse_axial_ratio','iug_mf_pam_ellipse_orientation',$
                    'iug_mf_pam_receiver_snr1','iug_mf_pam_receiver_snr2',$
                    'iug_mf_pam_receiver_snr3','iug_mf_pam_cross_channel_nsr1',$
                    'iug_mf_pam_cross_channel_nsr2','iug_mf_pam_cross_channel_nsr3',$
                    'iug_mf_pam_sea_scatter_relative_power1','iug_mf_pam_sea_scatter_relative_power2',$
                    'iug_mf_pam_sea_scatter_relative_power3'], 'spec', 1
       endif
    endif

   ;---Clear data and time buffer
    pam_time=0
    zon_wind=0
    mer_wind=0
    ver_wind=0
    uncorrected_zon_wind=0
    uncorrected_mer_wind=0
    corrected_fading_time=0
    uncorrected_fading_time=0
    normalized_time_discrepacy=0
    ellipse_major_axis_length=0
    ellipse_axial_ratio=0
    ellipse_orientation=0
    receiver_snr1=0
    receiver_snr2=0
    receiver_snr3=0
    cross_channel_nsr1=0
    cross_channel_nsr2=0
    cross_channel_nsr3=0
    sea_scatter_relative_power1=0
    sea_scatter_relative_power2=0
    sea_scatter_relative_power3=0
    
   ;---Add tclip  
   ;---Definition of the upper and lower limit of wind data:
    low_en=-100000
    high_en=100000
    low_v=-20000
    high_v=20000
    
    new_vars=tnames('iug_mf_pam_*')
    if new_vars[0] ne '' then begin
       tclip, 'iug_mf_pam_uwnd',low_en,high_en,/overwrite
       tclip, 'iug_mf_pam_vwnd',low_en,high_en,/overwrite
       tclip, 'iug_mf_pam_wwnd',low_v,high_v,/overwrite  
       tclip, 'iug_mf_pam_uncorrected_uwnd',low_en,high_en,/overwrite
       tclip, 'iug_mf_pam_uncorrected_vwnd',low_en,high_en,/overwrite
    endif
              
   ;---Add tdegap
   ;---Definition of time interval to enter NaN:
    DT=1800
    if new_vars[0] ne '' then begin   
       tdegap, 'iug_mf_pam_uwnd',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_vwnd',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_wwnd',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_uncorrected_uwnd',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_uncorrected_vwnd',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_fading_time',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_uncorrected_fading_time',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_normalized_time_discrepacy',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_ellipse_major_axis_length',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_ellipse_axial_ratio',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_ellipse_orientation',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_receiver_snr1',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_receiver_snr2',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_receiver_snr3',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_cross_channel_nsr1',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_cross_channel_nsr2',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_cross_channel_nsr3',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_sea_scatter_relative_power1',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_sea_scatter_relative_power2',dt=DT,/overwrite
       tdegap, 'iug_mf_pam_sea_scatter_relative_power3',dt=DT,/overwrite
    endif
 endif

 new_vars=tnames('iug_mf_pam_*')
 if new_vars[0] ne '' then begin 
    print,'**********************************************************************************
    print,'Data loading is successful!!'
    print,'**********************************************************************************
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
print, 'The distribution of MF radar data has been partly supported by the IUGONET'
print, '(Inter-university Upper atmosphere Global Observation NETwork) project'
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, Sports, Science'
print, 'and Technology (MEXT), Japan.'  

end
