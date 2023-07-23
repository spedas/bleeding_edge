;+
;
;NAME:
; tabsint_nobg
;
;PURPOSE:
; Calculates the absolute intensity [R] with raw and calibration data,
; and store tplot variable:
;
;SYNTAX:
; tabsint_nobg, site = site, wavelength = wavelength
;
;PARAMETERS:
;  vname1 = tplot variable of raw data.
;
;  Example
;   tabsint_nobg, site = 'ath', wavelength = 6300
;
;KEYWOARDS:
;
;CODE:
;  A. Shinbori, 05/08/2022.
;
;MODIFICATIONS:
;
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:
; $LastChangedDate:
; $LastChangedRevision:
; $URL $
;-
pro tabsint_nobg, site = site, wavelength = wavelength

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
   get_data, 'omti_asi_'+site+'_'+wavelengthc[0]+'_exposure_time', data = exp_ag_data, alimits = alim3 ;---for airglow exposure time data

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

  ;---No binning for airglow and background filters:
   if wid_cdf eq wid0 then begin
      cal_ag = cal_ag0 ;--512 moved to wid0
   endif 
  ;---2x2 binning 
   if wid0/wid_cdf eq 2 then begin
      for i = 0,wid_cdf - 1 do begin
         for j = 0, wid_cdf - 1 do begin
            cal_ag[j,i] = (cal_ag0[j*2,i*2] + cal_ag0[j*2,i*2+1] + cal_ag0[j*2+1,i*2] + cal_ag0[j*2+1,i*2+1])/4.0
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
       endfor
     endfor
   endif

  ;---Reverse of calibration data in the upside and downside directions:
   cal_ag = rotate(cal_ag, 7)

  ;============================================
  ;---Conversion from count rate to intensity:
  ;============================================
  ;---256 moved to wid0/2:
   if wid_cdf eq wid0/2 then debin = 4. else debin = 1.

  ;---Get time information of tplot variables:
   time_ag = ag_data.x  ;---Airgrow time data:

  ;---Loop of Airglow data:
   for i = 0, n_elements(time_ag) - 1 do begin

     ;---Atar remover:
      img_ag0 = reform(ag_data.y[i,*,*])
      rm_star_absint, img_ag0, img_ag, wid_cdf

     ;---2x2 binning:
      img_ag = img_ag/debin

     ;---Dark count (airglow image):
      dc_ag = median(img_ag[5:10,5:10])

     ;=======================================================================
     ;---Airglow calculation (absolute intensity [R])
     ;=======================================================================
     ;---Exposure time of airglow and background image data:
      exp_ag = exp_ag_data.y[i]

     ;---Definition of parameters to use the background/airglow calculation:
      tla = head_ag[2]    ; transmission at wl(airglow)
      dfa = head_ag[1]    ; bandwidth of airglow filter

     ;---Create airglow image (absolute intensity [R])
      ag_int = (img_ag - dc_ag)/(cal_ag * exp_ag)
      idx = where(cal_ag le 0.0, cnt)
      if cnt ge 1 then ag_int[idx] =0

     ;--- cal_ag < 0 and bg_in <=0.1 ---> ag_int = 0.0
      idx = where(ag_int lt 0.0, cnt)
      if cnt ge 1 then ag_int[idx] = 0.

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