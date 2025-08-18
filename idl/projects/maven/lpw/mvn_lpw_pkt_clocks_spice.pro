function mvn_lpw_pkt_clocks_spice, sclk_in1, sclk_in2, kernel_dir

;+
;Program written by Chris Fowler on Feb 19th 2014. Routine takes MAVEN s/c clock time in mvn_lpw_pkt routines and uses SPICE
;to determine correct start / end times of each dataset.
;
;INPUTS:
;  Times must be in the correct MAVEN format ie 0123456789.12345. See MAVEN sclk SPICE kernels
;  for more info (http://naif.jpl.nasa.gov/naif/data_mars.html).
;- sclk_in1: s/c clock main seconds in - the time to be SPICE corrected. Must be a long, float, double or array of these types.
;- sclk_in2: s/c clock fraction of seconds in. Must be a long, float, double or array of these types.
;
;OUTPUTS:
;  String array containing:
;  - Mission Ellapsed Time (MET) (s/c time)
;  - ET / DBT (SPICE ephemeris time / dynamic barycenter time)
;  - UTC time
;  - Julian time
;  - UNIX
;  - # of leap seconds that have occured up to the date of interest (sclk_in1.sclk_in2). If the SPICE kernels for this are 
;    unavailable a number of -999. is returned.
;  - format: ;tt=[[MET], [UTC_time], [et_time], [jd_time], [unix_time], [leapsecs]]
;            ;eg for two clock times entered, tt is a [2x6] array, where each row is different clock format, and clock times go left
;            ;to right in columns in the order they are input into sclk_in1 and 2.
;
;       kernel_dir: Tells the routine where to search for the SPICE kernels. Setting his as 'online' will search our online server.
;                   If you are working offline, use kernel_dir = "/Full/Path/to/SPICE/kernels/"
;                   REMEMBER that for now you will still need to edit the individual files in the code below based on the date range of the data you 
;                   are looking at. There should be an automated routine eventually to avoid doing this.
;Example:
; time = mvn_lpw_pkt_clocks_spice([0123456789], [12345]) ;for MET time of 0123456789.12345
; "time" will be a string array containing the outputs. 
;_

;======================
;Make sure two numbers have been entered for sclk_in1 and sclk_in2:
IF size(sclk_in1, /type) NE 3 AND size(sclk_in1, /type) NE 4 AND size(sclk_in1, /type) NE 5 THEN BEGIN
      print, "############################"
      print, "Spacecraft -seconds- clock entered is not in the correct format (float or double precision number)." 
      print, "For MAVEN, spacecraft clock is of the format 0123456789.12345."
      print, "-second- clock: 0123456789."
      print, "-subsecond- clock: .12345"
      print, "Check sclk_in1 and sclk_in2 are in correct format before being input into this routine."
      print, "############################"
      return, 1
ENDIF
IF size(sclk_in2, /type) NE 3 AND size(sclk_in2, /type) NE 4 AND size(sclk_in2, /type) NE 5 THEN BEGIN
      print, "############################"
      print, "Spacecraft -subsecond- clock entered is not in the correct format (float or double precision number)." 
      print, "For MAVEN, spacecraft clock is of the format 0123456789.12345."
      print, "-second- clock: 0123456789."
      print, "-subsecond- clock: .12345"
      print, "Check sclk_in1 and sclk_in2 are in correct format before being input into this routine."
      print, "############################"
      return, 1
ENDIF

;Combine 
ssclk_in1 = string(sclk_in1, format='(F16.5)')  ;if we have double values:
;Combine subseconds to main seconds. Subseconds can only go up to .65535, so have to be carefull BECAUSE subseconds come in as 12345, not a fraction. So
;14.0 is actually 0.00014 when joining to sclk_in1:

;     The on-board clock, the conversion for which is provided by this SCLK
;     file, consists of two fields:
;          SSSSSSSSSS.FFFFF
;     where:
;          SSSSSSSSSS -- count of on-board seconds
;          FFFFF      -- count of fractions of a second with one fraction
;                        being 1/65536 of a second; normally this field value
;                        is within 0..65535 range.

sclk = string(sclk_in1+(sclk_in2/100000.d), format='(F16.5)')  ;create time in correct string format
nele_sclk = n_elements(sclk)
;======================

scid = -202  ;MAVEN s/c ID for SPICE

;======================
;---Kernel directory---
;======================
;This is where the kernel directory is set:
if not keyword_set(kernel_dir) then begin
      print, "############################"
      print, "WARNING: kernel_dir not set."
      print, "Use kernel_dir = 'online' when connected to sever."
      print, "Use kernel_dir = '/Full/path/to/kernel_files/' when working offline."
      print, "############################"
      return,1  ;this routine is a function so has to return a value
endif
if kernel_dir eq 'online' then filedir = "/Volumes/maven/spice_kernels/"
if kernel_dir ne 'online' then filedir = kernel_dir
;======================

;Load LSK and sclk files:
file1 = filedir+'lsk/naif0010.tls'
file2 = filedir+'sclk/MVN_SCLKSCET.00001.tsc'

cspice_furnsh, file1  ;unload kernels at end of routine using file1/2
cspice_furnsh, file2

;Ephermeris time:
cspice_scs2e, scid, sclk, et_time  ;et is the converted ephermeris time. This won't work for -ve et_times, I think this is because the routine
                                   ;requires the MAVEN ID and MAVEN times should all be +ve et_times.

;Convert ET to UTC time:
cspice_et2utc, et_time, 'ISOC', 3, utc_time 

;Make arrays for different times, append to them in for loop:
jd_time = dblarr(nele_sclk)
unix_time = dblarr(nele_sclk)
added_ls = dblarr(nele_sclk)

;Load SPICE leapsecond kernels if available:
cspice_dtpool, 'DELTET/DELTA_AT', found1, n, type  ;found=1 if kernel is found, n is the total size of the 2 column array.

IF found1 EQ 1 THEN BEGIN
     cspice_gdpool, 'DELTET/DELTA_AT', 0, n, values, found2  ;extract the leapsecs kernel. One column = #, second column = leapsecond date          
     IF found2 EQ 1 THEN BEGIN
         ;Need to extract every other point from the array which are the ET times. We'll then search for where our s/c time fits into these times,
         ;to determine how many leapseconds have passed up to our specific s/c date.
         leapdates = dblarr(n/2.)  ;array to store dates leapseconds were added / subtracted
         leapsecs = fltarr(n/2.)  ;array storing how many leapseconds have been added / subtracted, up to the corresponding date in leapdates.
                                  ;(leapseconds can be added or subtracted, in multiples of 0, 1, 2, so this column is important.)
         for ii = 0, (n/2.)-1. do begin
             leapsecs[ii] = values[2.*ii]
             leapdates[ii] = values[(2*ii)+1.]
         endfor  ;over ii
     ENDIF  ;over found2 = 1
ENDIF  ;over found1 = 1

;Go through each UTC time and convert to Julian:
FOR bbb = 0, nele_sclk -1 DO BEGIN

      ;UTC time is given in the format "2013 NOV 09 19:00:46.690", so split up strings based on the characters " :"
      utc_elements = strsplit(utc_time[bbb], "-T:.", /extract)  ;utc_elements is a 6 element array in the format [year, month, day, hour, min, sec.subsec]    
      
      ;Result = JULDAY(Month, Day, Year, Hour, Minute, Second). Convert strings to floats.
      jd_time[bbb] = julday(float(utc_elements[1]), float(utc_elements[2]), float(utc_elements[0]), float(utc_elements[3]), float(utc_elements[4]), float(utc_elements[5]))
      
      ;Comute UNIX time:
      ;First convert the epoch 00:00:00 Jan 1st 1970 to JD date:
      epoch = julday(1,1,1970,0,0,0)
      
      ;Get UNIX time:
      unix_time[bbb] = (jd_time[bbb] - epoch) * 86400.D  ;convert days to secs (after 00:00:00 Jan 1st 1970)
      
      ;Get # of leapseconds passed up to date of interest:
      ;Need to pull out data from the array "DELTET/DELTA_AT" from the LSK kernel:      
 
          IF found2 EQ 1 THEN BEGIN  
              cspice_gdpool, 'DELTET/DELTA_T_A', 0, 1, delta_t_a, found3  ;get delta_t_a from kernel.
              
              IF found3 EQ 1 THEN BEGIN
                  cspice_deltet, et_time[bbb], 'ET', delta_et  ;delta_et is ET offset from UTC 
                  added_ls[bbb] = round(delta_et - delta_t_a)  ;the number of leapsecs added for the current et_time[bbb]             
              ENDIF ELSE BEGIN  ;found3 = 1
                  added_ls[bbb] = -999.  ;if we can't find the kernel values use this error number instead
              ENDELSE
          ENDIF ELSE BEGIN  ;found2 = 1    
              ;If the leapseconds kernel wasn't found:
              added_ls[bbb] = -999.  ;return a float as this will go in a float array.
          ENDELSE
ENDFOR  ;over nele_sclk2

cspice_unload, file1
cspice_unload, file2

;Append values to array:
tt = [[sclk], [utc_time], [string(et_time, format='(F16.5)')], $
     [string(jd_time, format='(F16.5)')], [string(unix_time, format='(F16.5)')], [strtrim(added_ls,2)]]

return, tt  ;NOTE: using print, format='(g)' will print just the year from UTC times, as '(g)' is for doubles. Just use print - they're all strings.

;the array tt is returned, with the format:
;tt=[[MET (s/c time)], [UTC_time], [ET_time], [jd_time], [unix_time], [leapsecs]]
;where each row is the next clock format.



end