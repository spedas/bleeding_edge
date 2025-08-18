
PRO MVN_KP_INSITU_CHECK_FOR_NEW_L2_FILES, first_day, number_of_days, LPW = lpw, EUV=euv, SWE=swe, SWI=swi, STA=sta, SEP = sep, MAG=mag, NGI=ngi, ALL=all,$
  L2=l2, INTERP=interp


;--------------------------------------------------------------------------------------------
; 
;   Usage:    MVN_KP_INSITU_CHECK_FOR_NEW_L2_FILES, '2014-10-01', 31, /SEP, /l2
;
;  * MOI was September 21, 2014
;  * no l2 files to be saved for swea, they already exist in the /swea/kp/ subdirectory
;  * need to delete previous l2/interp files if exisSting files are old version numbers
;  
;---------------------------------------------------------------------------------------------


first_day_unix = TIME_DOUBLE(first_day)
seconds_in_day = 60L*60L*24L

files_to_update_L2 = '/disks/data/maven/data/sci/kp/insitu/files_to_update_L2.txt'
OPENW, ounit, files_to_update_L2, /GET_LUN 

RESTORE, FILENAME = '/disks/data/maven/data/sci/kp/insitu/version_numbers_l2.sav'
;instrument_version_numbers[1].version_number = '??'  ; LPW has v02 for lpnt files, v01 for others
file_type = ['cdf', 'cdf', 'sts', 'csv', 'cdf', 'cdf', 'tplot', 'cdf']


FOR i=0,N_ELEMENTS(instrument)-1 DO PRINT, instrument[i], ' v',version_number[i], ' ', file_type[i]

IF KEYWORD_SET(all) THEN m=10
IF KEYWORD_SET(euv) THEN m=0
IF KEYWORD_SET(lpw) THEN m=1
IF KEYWORD_SET(mag) THEN m=2
IF KEYWORD_SET(ngi) THEN m=3
IF KEYWORD_SET(sep) THEN m=4
IF KEYWORD_SET(sta) THEN m=5
IF KEYWORD_SET(swe) THEN m=6
IF KEYWORD_SET(swi) THEN m=7

IF (m EQ 10) THEN BEGIN
  instrument = instrument_version_numbers.name
  version_number = instrument_version_numbers.version_number
ENDIF ELSE BEGIN
  instrument = instrument_version_numbers[m].name
  version_number = instrument_version_numbers[m].version_number
  file_type = file_type[m]
ENDELSE
HELP, instrument
  



  FOR i=0, N_ELEMENTS(instrument)-1 DO BEGIN

    FOR j=0, number_of_days-1 DO BEGIN

      ;---------------------------------------------------------
      ;  Getting date and setting up strings of date segments
      ;---------------------------------------------------------  
      date = (j * seconds_in_day) + first_day_unix
      date_string = TIME_STRING(date, FORMAT=2, PRECISION=-3)
      year  = STRMID(date_string, 0, 4)
      month = STRMID(date_string, 4, 2)
      day   = STRMID(date_string, 6, 2)


      ;-------------------------------------------------
      ;  Search for kp instrument files created by me
      ;------------------------------------------------      
      path = '/disks/data/maven/data/sci/kp/insitu/instrument_data/' + instrument[i] + '/' + year + '/' + month + '/'
      IF KEYWORD_SET(L2) THEN file = instrument[i] + '_kp_L2_' + year + month + day + '*.sav'
      IF KEYWORD_SET(interp) THEN BEGIN
        IF KEYWORD_SET(euv) OR (i EQ 0)
        file = instrument[i] + '_kp_interp_' + year + month + day + '*.sav'
      result = FILE_SEARCH(path, file, count=count)
      IF (count EQ 0) THEN BEGIN
        time_of_processing = 0L 
      ENDIF ELSE BEGIN 
        stamp = FILE_INFO(result)
        time_of_processing = stamp.mtime
      ENDELSE
  
      ;------------------------------------------------------------
      ;  Search for instrument L2 files created by instrument team, if found THEN search for kp instrument files
      ;------------------------------------------------------------
      IF ( (i EQ 6) OR (KEYWORD_SET(swe)) ) THEN BEGIN
        IF (KEYWORD_SET(interp)) THEN BEGIN
          path = '/disks/data/maven/data/sci/' + instrument[i] + '/kp/' + year + '/' + month + '/'
          file = 'mvn_' + instrument[i] + '_*_' + year + month + day + '*'; + 'v'+ version_number[i] + '*' + file_type[i]    
        ENDIF
      ENDIF ELSE IF ( (i EQ 7) OR (KEYWORD_SET(swi)) ) THEN BEGIN
        path = '/disks/data/maven/data/sci/' + instrument[i] + '/l2/' + year + '/' + month + '/'
        file = 'mvn_' + instrument[i] + '_*_' + '*mom*' + year + month + day + '*' + 'v' + version_number[i] + '*' + file_type[i]
      ENDIF ELSE BEGIN 
        path = '/disks/data/maven/data/sci/' + STRMID(instrument[i],0,3) + '/l2/' + year + '/' + month + '/'
        file = 'mvn_' + instrument[i] + '_*_' + year + month + day + '*' + 'v' + version_number[i] + '*' + file_type[i]      
      ENDELSE
      result = FILE_SEARCH(path, file, count=count)

      ;-------------------------------------------------------
      ;  Get timestamp of file creation
      ;-------------------------------------------------------
      FOR k=0, count-1 DO BEGIN
        stamp = FILE_INFO(result[k])
        delta = stamp.mtime - time_of_processing
        result_split = STRSPLIT(result[k], /EXTRACT, '/')
        n = N_ELEMENTS(result_split)-1
             
        IF (delta GE 0) THEN BEGIN
          PRINTF, ounit, date_string, STRMID(instrument[i],0,3), TIME_STRING(stamp.mtime), TIME_STRING(time_of_processing), delta, ' ', result_split[n], $
            FORMAT = '(A12, A5, 2A25, I15, A5, A-80)'
        ENDIF
      ENDFOR
    
  ENDFOR       
ENDFOR

FREE_LUN, ounit


END

