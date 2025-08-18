;+
;
;NAME:
; tabsint
;
;PURPOSE:
; Calculates the absolute intensity [R] with raw, background, and calibration data,
; and store tplot variable:
;
;SYNTAX:
; tabsint, site = site, wavelength = wavelength
;
;PARAMETERS:
;  site = ABB code of observation site.
;  wavelength = wavelength of airglow and background image data.
;  
;  Example:
;   tabsint, site = 'ath', wavelength = [6300,5725]
;
;CODE:
;  A. Shinbori, 15/07/2022.
;
;MODIFICATIONS:
;  A. Shinbori, 05/08/2022.
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:
; $LastChangedDate:
; $LastChangedRevision:
; $URL $
;-
pro tabsint, site = site, wavelength = wavelength

  ;---Site check:
   if~keyword_set(site) then begin
      print, 'Please input site code.'
      return
   endif   
   print, site
   
  ;---Wavelength:
   if n_elements(wavelength) le 1 then begin
      print, 'Please input airglow and background wavelengths.'
      return    
   endif

   if(size(wavelength,/type) ne 7) then wavelengthc=string(wavelength, format='(i4.4)') $
   else wavelengthc=wavelength

   wavelengthc=strjoin(wavelengthc, ' ')
   wavelengthc=strsplit(strlowcase(wavelengthc), ' ', /extract)

  ;=====================================
  ;---Get data from two tplot variables:
  ;=====================================  
   if strlen(tnames('omti_asi_'+site+'_'+wavelengthc[0]+'_image_raw')) eq 0 then begin   
      print, 'Not found tplot variable!'
      return
   endif
   get_data, 'omti_asi_'+site+'_'+wavelengthc[0]+'_image_raw', data = ag_data, alimits = alim1 ;---for airglow image data
   get_data, 'omti_asi_'+site+'_'+wavelengthc[1]+'_image_raw', data = bg_data, alimits = alim2 ;---for background image data
   get_data, 'omti_asi_'+site+'_'+wavelengthc[0]+'_exposure_time', data = exp_ag_data, alimits = alim3 ;---for airglow exposure time data
   get_data, 'omti_asi_'+site+'_'+wavelengthc[1]+'_exposure_time', data = exp_bg_data, alimits = alim4 ;---for background exposure time data

   vname1 = 'omti_asi_'+site+'_'+wavelengthc[0]+'_image_raw'

  ;---Get the image size from tplot variables:
   wid_cdf = n_elements(ag_data.y[0,*,0])
   
  ;---Definition of maximum intensity value:
   max_int = 65535.0

  ;=================================================================
  ;---Download calibration data if they do not exist or are updated:
  ;=================================================================
  ;--- Create (and initialize) a data file structure
   source = file_retrieve(/struct)

  ;--- Set parameters for the data file class
   source.local_data_dir  = root_data_dir() + 'ergsc/ground/camera/omti/asi/calibrated_files/'
   source.remote_data_dir = 'https://stdb2.isee.nagoya-u.ac.jp/omti/data/'
   file_format = 'calibrated_files.zip'
   relpathnames = file_dailynames(file_format = file_format, trange = trange)
   file_ctime0 = file_info(source.remote_data_dir + file_format)
   dprint,relpathnames
   files = spd_download(remote_file = relpathnames, remote_path = source.remote_data_dir, local_path = source.local_data_dir, _extra = source, /last_version)
   file_ctime1 = file_info(source.local_data_dir + file_format)

  ;---Unzip zipfile:
   if file_ctime0.ctime ne file_ctime1.ctime then file_unzip,  files

  ;=======================================================================
  ;--Read OUT file (recreate calibration image [count/R/s])
  ;=======================================================================
  ;---Set the used calibration files:
   strtnames = strsplit(vname1,'_',/extract)
  ;---Time in UT: 
   date = ag_data.x[0]
  ;---Observation site (ABB code): 
   site = strtnames[2]
  ;---Wavelength: 
   wavelength = strtnames[3]
  ;----Obtain the search result of OMTI calibration file: 
   calibration_file_name = search_omti_calibration_file(date = date, site = site, wavelength = wavelength, wid_cdf = wid_cdf, wid0 = wid0)

  ;---Calibration image width:
   wid0 = wid0
  
  ;---Definition of absolute image data array from time and cdf image size: 
   abs_img_ag_int = fltarr(n_elements(ag_data.x), wid_cdf, wid_cdf) + 0.0

  ;---Calibration image (A [cnt/R/s]) airglow filter
   cal_ag0 = fltarr(wid0, wid0) + 0.0
   cal_ag = fltarr(wid_cdf, wid_cdf) + 0.0

  ;---Calibration image (Ab [cnt/R/s]) background filter
   cal_bg0 = fltarr(wid0, wid0) + 0.0
   cal_bg = fltarr(wid_cdf, wid_cdf) + 0.0

  ;--Airglow filter:
  ;---Definition of array:
   head0 = strarr(1)
   head_ag = fltarr(3)
   temp = fltarr(4)

  ;---Get the line of OUT file: 
   lines = long(file_lines(source.local_data_dir + calibration_file_name[0])) - 2L
   
  ;---line < (wid0/2)* (wid0/2)
   if lines lt long(wid0)/4L * long(wid0) then wid0 = wid0/2
  
  ;---Open the calibration file for airgrow data: 
   openr, 1, source.local_data_dir + calibration_file_name[0]
  ;---Read the header: 
   readf, 1, head0, head_ag
  ;---Read the calibration data: 
   for i = 0, wid0 - 1 do begin
      for j = 0, wid0 - 4, 4 do begin
         readf, 1, temp, format = '(4(x,E10.3))'
         cal_ag0[j:j+3,i] = temp
      endfor
   endfor
   close, 1

  ;---Background filter
  ;---Definition of array:
   head_bg = fltarr(3)
   temp = fltarr(4)
   
  ;---Get the line of OUT file: 
   lines = long(file_lines(source.local_data_dir + calibration_file_name[1])) - 2L

  ;---line < (wid0/2)* (wid0/2) 
   if lines lt long(wid0)/4L * long(wid0) then wid0 = wid0/2
  
  ;---Open the calibration file for filter data:  
   openr, 1, source.local_data_dir +  calibration_file_name[1]
  ;---Read the header:  
   readf, 1, head0, head_bg
  ;---Read the calibration data:  
   for i = 0, wid0 - 1 do begin
      for j = 0, wid0 - 4, 4 do begin
         readf, 1, temp, format = '(4(x,E10.3))'
         cal_bg0[j:j+3,i] = temp
      endfor
   endfor
   close, 1

  ;---No binning for airglow and background filters:
   if wid_cdf eq wid0 then begin
      cal_ag = cal_ag0 ;--512 moved to wid0
      cal_bg = cal_bg0
   endif 
  ;---2x2 binning 
   if wid0/wid_cdf eq 2 then begin
      for i = 0,wid_cdf - 1 do begin
         for j = 0, wid_cdf - 1 do begin
            cal_ag[j,i] = (cal_ag0[j*2,i*2] + cal_ag0[j*2,i*2+1] + cal_ag0[j*2+1,i*2] + cal_ag0[j*2+1,i*2+1])/4.0
            cal_bg[j,i] = (cal_bg0[j*2,i*2] + cal_bg0[j*2,i*2+1] + cal_bg0[j*2+1,i*2] + cal_bg0[j*2+1,i*2+1])/4.0
         endfor
      endfor
   endif

  ;---4x4 binning
   if wid0/wid_cdf eq 4 then begin
     for i = 0,wid_cdf - 1 do begin
       for j = 0, wid_cdf - 1 do begin
         cal_ag[j,i] = (cal_ag0[j*4,i*4] + cal_ag0[j*4,i*4+1] + cal_ag0[j*4,i*4+2]+ cal_ag0[j*4,i*4+3] $
                      + cal_ag0[j*4+1,i*4] + cal_ag0[j*4+1,i*4+1]+ cal_ag0[j*4+1,i*4+2] + cal_ag0[j*4+1,i*4+3] $
                      + cal_ag0[j*4+2,i*4] + cal_ag0[j*4+2,i*4+1]+ cal_ag0[j*4+2,i*4+2] + cal_ag0[j*4+2,i*4+3] $
                      + cal_ag0[j*4+3,i*4] + cal_ag0[j*4+3,i*4+1]+ cal_ag0[j*4+3,i*4+2] + cal_ag0[j*4+3,i*4+3])/16.0
         cal_bg[j,i] = (cal_bg0[j*4,i*4] + cal_bg0[j*4,i*4+1] + cal_bg0[j*4,i*4+2]+ cal_bg0[j*4,i*4+3] $
                      + cal_bg0[j*4+1,i*4] + cal_bg0[j*4+1,i*4+1]+ cal_bg0[j*4+1,i*4+2] + cal_bg0[j*4+1,i*4+3] $
                      + cal_bg0[j*4+2,i*4] + cal_bg0[j*4+2,i*4+1]+ cal_bg0[j*4+2,i*4+2] + cal_bg0[j*4+2,i*4+3] $
                      + cal_bg0[j*4+3,i*4] + cal_bg0[j*4+3,i*4+1]+ cal_bg0[j*4+3,i*4+2] + cal_bg0[j*4+3,i*4+3])/16.0
       endfor
     endfor
   endif

  ;---Reverse of calibration data in the upside and downside directions:
   cal_ag = rotate(cal_ag, 7)
   cal_bg = rotate(cal_bg, 7)
   
  ;============================================
  ;---Conversion from count rate to intensity:
  ;============================================
  ;---256 moved to wid0/2:
   if wid_cdf eq wid0/2 then debin = 4. else debin = 1.

  ;---Get time information of tplot variables:
   time_ag = ag_data.x  ;---Airgrow time data:
   time_bg = bg_data.x  ;---Background time data:

  ;---Loop of Airglow data:
   for i = 0, n_elements(time_ag) - 1 do begin

     ;---Atar remover:
      img_ag0 = reform(ag_data.y[i,*,*])
      rm_star_absint, img_ag0, img_ag, wid_cdf

     ;---2x2 binning:
      img_ag = img_ag/debin

     ;---Dark count (airglow image):
      dc_ag = median(img_ag[5:10,5:10])

     ;---Initialize the value:
      ref_bg1 = -1
      ref_bg2 = -1

     ;---time of airglow data <= first time of background data:
      if time_ag[i] le time_bg[0] then begin
         ref_bg1 = 0
         ref_bg2 = 0
         goto, bgimg_open
      endif

     ;---time of airglow data >= ith time of background data:
      if time_ag[i] ge time_bg[n_elements(time_bg) - 1] then begin
         ref_bg1 = n_elements(time_bg) - 1
         ref_bg2 = n_elements(time_bg) - 1
         goto, bgimg_open
      endif
     
     ;---time of background data >= time of airgrow data: 
      for ib = 0, n_elements(time_bg) - 1 do begin
         if time_bg[ib] ge time_ag[i] then begin
            ref_bg1 = ib - 1
            ref_bg2 = ib
            goto, bgimg_open
         endif
      endfor

      bgimg_open:

     ;---Exposure time of airglow and background image data:
      exp_ag = exp_ag_data.y[i]
      exp_bg = exp_bg_data.y[ref_bg1]

     ;---Read reference background image
      img_bg_ref = fltarr(wid_cdf, wid_cdf, 2) + 0.0
      img_bg_int = fltarr(wid_cdf, wid_cdf) + 0.0

     ;---Background image 1
      img_bg0 = reform(bg_data.y[ref_bg1,*,*])

     ;---2x2 binning
      img_bg0 = img_bg0/debin

     ;---Star remover
      rm_star_absint, img_bg0, img_bgs, wid_cdf
      if site eq 'syo' and wavelength ne 5893 then begin
         img_bg_ref[*,*,0] = img_bgs[0:wid_cdf-1,0:wid_cdf-1]
      endif else begin
        img_bg_ref[*,*,0] = img_bgs
      endelse

     ;---Background image 2
      img_bg0 = reform(bg_data.y[ref_bg2,*,*])

     ;---2x2 binning
      img_bg0 = img_bg0/debin

     ;---Star remover
      rm_star_absint, img_bg0, img_bgs, wid_cdf
      if site eq 'syo' and wavelength ne 5893 then begin
         img_bg_ref[*,*,1] = img_bgs[0:wid_cdf-1,0:wid_cdf-1]
      endif else begin
        img_bg_ref[*,*,1] = img_bgs
      endelse

     ;---Dark count (background image)
      dc_bg = median(img_bg_ref[5:10,5:10,*])

     ;=======================================================================
     ;---Background/airglow calculation (absolute intensity [R])
     ;=======================================================================
     ;---Definition of parameters to use the background/airglow calculation:
      tlb = head_bg[2]    ; transmission at wl(background)
      dfb = head_bg[1]    ; bandwidth of background filter
      tla = head_ag[2]    ; transmission at wl(airglow)
      dfa = head_ag[1]    ; bandwidth of airglow filter

     ;---Background count correction (linear interpolation)
      ktm = 0
      if time_bg[ref_bg2] ne time_bg[ref_bg1] then begin
         ktm = (img_bg_ref[*,*,1] - img_bg_ref[*,*,0]) / (time_bg[ref_bg2] - time_bg[ref_bg1])
      endif
      mod_bg = img_bg_ref[*,*,0] + (time_ag[i] - time_bg[ref_bg1]) * ktm

     ;---Ibg [R/nm] = ( Nb - DKb ) * T(lb) / ( Ab * tb * dFb )
      bg_int = (mod_bg - dc_bg) * tlb/(cal_bg * exp_bg * dfb)
      idx = where(cal_bg le 0.0, cnt)
      if cnt ge 1 then bg_int[idx] =0.0
      
     ;---cal_bg < 0 ---> bg_int = 0.0
      idx = where(cal_bg lt 0.0, cnt)
      if cnt ge 1 then bg_int[idx] = 0.0

     ;---bg_int < 0 ---> bg_int = 0.0 
      idx = where(bg_int lt 0.0, cnt)
      if cnt ge 1 then bg_int[idx] = 0.0

     ;---bg_int >  max_int ---> bg_int = max_int
      idx = where(bg_int gt max_int*1.0, cnt)
      if cnt ge 1 then bg_int[idx] = max_int*1.0

     ;---Create airglow image (absolute intensity [R])   
      ag_int = (img_ag - cal_ag * exp_ag * bg_int * dfa/tla - dc_ag)/(cal_ag * exp_ag)
      idx = where(cal_ag le 0.0 or bg_int le 0.0, cnt)
      if cnt ge 1 then ag_int[idx] =0.0
          
     ;--- cal_ag < 0 and bg_in <= 0.1 ---> ag_int = 0.0
      idx = where(cal_ag le 0. and bg_int le 0.0, cnt)   
      if cnt ge 1 then ag_int[idx] = 0.0
     
     ;--- cal_ag < 0 and bg_in <=0.1 ---> ag_int = 0.0
      idx = where(ag_int lt 0.0, cnt)
      if cnt ge 1 then ag_int[idx] = 0.0
      
     ;--- cal_ag > 0 max_int ---> ag_int = max_int 
      idx = where(ag_int gt max_int * 1.0, cnt)
      if cnt ge 1 then ag_int[idx] = max_int

     ;---Head and tail pixel intensities are set to maximum (32767 or 65535)
      ag_int[0,0] = max_int
      ag_int[wid_cdf - 1,wid_cdf - 1] = max_int
     
     ;----Input the image data into new array to store tplot variable:
      abs_img_ag_int[i,*,*] = ag_int
      print, 'now converting... : ',time_string(time_ag[i])

   endfor

  ;========================
  ;---Store tplot variable:
  ;========================
   store_data, strmid(vname1,0,24)+'abs', data = {x:time_ag, y:abs_img_ag_int}

end