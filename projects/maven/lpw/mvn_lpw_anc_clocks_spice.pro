;;+
;PROCEDURE:   mvn_lpw_anc_clocks_spice
;PURPOSE:
;  Routine takes MAVEN s/c clock time in mvn_lpw_pkt routines and uses SPICE
;    to determine correct start / end times of each dataset.
;  
;USAGE:
;  mvn_lpw_anc_clocks_spice, sclk_in1, sclk_in2,clock_field_str,clock_start_t,clock_end_t,spice,spice_used,str_xtitle,kernel_version,unix_time
;
;INPUTS:
;  Times must be in the correct MAVEN format ie 0123456789.12345. See MAVEN sclk SPICE kernels
;  for more info (http://naif.jpl.nasa.gov/naif/data_mars.html).
;       sclk_in1: s/c clock main seconds in - the time to be SPICE corrected. Must be a long, float, double or array of these types.
;       sclk_in2: s/c clock fraction of seconds in. Must be a long, float, double or array of these types.
;
;
;OUTPUTS:
;            clock_field_str  what clock_start_t /clock_end_t    contain in text 
;            clock_start_t     first time point of the array   < this is now a number not an string
;            clock_end_t      last  time point of the array < this is now a number not an string
;            
;            spice            newly added; either defined and then contain the directory of the kernel or undefined            
;            spice_used       text out
;            str_xtitle       text out
;            kernel_version   text out
;            unix_time       this is the full time arry in unix time
;            
;KEYWORDS:
;Set /clear_kernels to clear SPICE kernels from IDL memory once run. DO NOT set this when processing L0 data, as kernels must then be looked up from NAIF for each pkt variable.
;
;Example:
; time = mvn_lpw_pkt_clocks_spice([0123456789], [12345]) ;for MET time of 0123456789.12345
; "time" will be a string array containing the outputs. 
;
;
;CREATED BY:   Chris Fowler on Feb 19th 2014
;FILE: mvn_lpw_anc_clocks_spice.pro
;VERSION:   2.0
;LAST MODIFICATION:   
;04/25/14 L. Andersson change it from being a function to an procedure, changed the time from string to double, 
;              moved all information into this routine so that it is not spread out in other routines.
;               spice is presently used to carry the kernel_directory, later on this can be turn into a 'yes' 
;              when routines exsits to automatically find the directory.
;
;04/29/2014 CF: added automated kernel loading added. Also checks to see if times are predicted or reconstructed. 
;;140718 clean up for check out L. Andersson
;2015-10-08 CMF made clearing SPICE kernels a keyword.
;
;-




pro mvn_lpw_anc_clocks_spice, sclk_in1, sclk_in2,clock_field_str,clock_start_t,clock_end_t,spice,spice_used,str_xtitle,kernel_version,unix_time2, clear_kernels=clear_kernels

;------------------------------------------------
          spice_used = 'SPICE used'
          str_xtitle = 'Time (UNIX)'   ;we add on constructed or reconstructed at the end as well
          kernel_version = 'anc_clocks_spice_ver V2.0'
;------------------------------------------------

Input_info_correct=1
sl = path_sep()  ;/ for unix, \ for Windows
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
      Input_info_correct=0
ENDIF
IF size(sclk_in2, /type) NE 3 AND size(sclk_in2, /type) NE 4 AND size(sclk_in2, /type) NE 5 THEN BEGIN
      print, "############################"
      print, "Spacecraft -subsecond- clock entered is not in the correct format (float or double precision number)." 
      print, "For MAVEN, spacecraft clock is of the format 0123456789.12345."
      print, "-second- clock: 0123456789."
      print, "-subsecond- clock: .12345"
      print, "Check sclk_in1 and sclk_in2 are in correct format before being input into this routine."
      print, "############################"
     Input_info_correct=0
ENDIF

IF Input_info_correct EQ 1 then begin

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

sclk_time = double(sclk_in1+(sclk_in2/100000.d))  ;create time in double array
sclk      = string(sclk_time, format='(F16.5)')  ;create time in correct string format for spice

nele_sclk = n_elements(sclk)
;======================

scid = -202  ;MAVEN s/c ID for SPICE

    ;filedir =spice ; '/Users/andersson/Idl/2014_maven/spice/spice_kernels/'  ;base directory for local kernels (need to find an automated way to check for updates)


;==================
;---Load kernels---
;==================
;Code for automatically loading found kernels:
;Get kernel info from tplot variables and load:
tplotnames = tnames()  ;list of tplot variables in memory
if total(strmatch(tplotnames, 'mvn_lpw_load_kernel_files')) eq 1 then begin  ;found kernel tplot variable
    get_data, 'mvn_lpw_load_kernel_files', data=data_kernels, dlimit=dl_kernels  ;dl.kernels contains the kernel names
    nele_kernels = n_elements(dl_kernels.Kernel_files)  ;number of kernels to load
    loaded_clock_kernels = ['']  ;start array
    for aa = 0, nele_kernels-1 do begin
        if (stregex(dl_kernels.Kernel_files[aa], sl+'lsk', /boolean) eq 1) or (stregex(dl_kernels.Kernel_files[aa], sl+'sclk', /boolean) eq 1) then begin   ;#### /\ for windows
            cspice_furnsh, dl_kernels.Kernel_files[aa]  ;load lsk or sclk kernel
            loaded_clock_kernels = [loaded_clock_kernels, dl_kernels.Kernel_files[aa]]
            
            ;Extract just kernel name and remove directory:
            nind = strpos(dl_kernels.Kernel_files[aa], sl, /reverse_search)  ;nind is the indice of the last '/' in the directory before the kernel name
            lenstr = strlen(dl_kernels.Kernel_files[aa])  ;length of the string directory
            kname = strmid(dl_kernels.Kernel_files[aa], nind+1, lenstr-nind)  ;extract just the kernel name                       
            kernel_version = kernel_version + " # " + kname  ;add kernels used to dlimit field
        endif       
    endfor  ;over aa
        if n_elements(loaded_clock_kernels) le 2 then begin  ;we need at least one lsk and one sclk kernel, plus the dummy entry = 3 element array
           print, "#### WARNING ####: No lsk and / or sclk kernels found to load. Check kernels are found and loaded."
           retall
        endif   
endif else begin
      print, "####################"
      print, "WARNING: No SPICE kernels found which match this data set.
      print, "Check there are kernels available online for this data.
      print, "If they are present, check the kernel finder to see if it's finding them.
      print, "####################"
      retall
endelse

;===============================
;--- SSL convert MET to UNIX ---
;===============================
;Use the SSL routine to convert MET to UNIX time, so that we're using the same routine as the PFP team:
;This takes the time as full seconds I believe, so:
;Convert subseconds to "real fractional seconds"
whole = double(sclk_in1)  ;already as main seconds
frac = double(sclk_in2)
frac = frac / ((2.d^16))  ;convert to sub seconds

MET = whole+frac  ;double prec number, seconds into s/c mission (MET)

;Call timespan first to avoid the manual call. Get the input string from tplot:
get_data, 'mvn_lpw_load_file', dlimit=dl

timespan, dl.utc, 1.  ;use the UTC input string 
unix_time2 = mvn_spc_met_to_unixtime(MET)  ;default is now to correct for  clockdrift

;===============================


;Ephermeris time: one below using davin's routine
;cspice_scs2e, scid, sclk, et_time  ;et is the converted ephermeris time. This won't work for -ve et_times, I think this is because the routine
                                   ;requires the MAVEN ID and MAVEN times should all be +ve et_times.

;Convert ET to UTC time:
;cspice_et2utc, et_time, 'ISOC', 5, utc_time ;<== number determines how many dp to have in seconds

;For consistency, use Davin's routine to convert unix to UTC time:
utc_time = time_string(unix_time2, precision=5)   ;precision give you dp to have in seconds

;Get ET time using Davin's routine:
et_time = time_ephemeris(utc_time, /ut2et)

utc_time_time=dblarr(nele_sclk)
for i=0L,nele_sclk-1 do begin
   aa= strsplit(utc_time[i],'/',/extract)  ;this is 'T' when using utc times ouput by SPICE
   bb= strsplit(aa[0],'-',/extract)
   cc= strsplit(aa[1],':',/extract)
  utc_time_time[i] =10000000000.0 * double( bb[0]) + 100000000.0 * double(bb[1]) + 1000000.0 * double(bb[2]) + 10000.0 *double(cc[0]) + 100.0 * double(cc[1]) +double(cc[2]) 
endfor  


;Make arrays for different times, append to them in for loop:
jd_time = dblarr(nele_sclk)
;unix_time = dblarr(nele_sclk)
added_ls = dblarr(nele_sclk)

;Load SPICE leapsecond kernels if available:
cspice_dtpool, 'DELTET/DELTA_AT', found1, n, type  ;found=1 if kernel is found, n is the total size of the 2 column array.

IF found1 EQ 1 THEN cspice_gdpool, 'DELTET/DELTA_AT', 0, n, values, found2  ;extract the leapsecs kernel. One column = #, second column = leapsecond date          

;Go through each UTC time and convert to Julian:
FOR bbb = 0L, nele_sclk -1 DO BEGIN
        ;old way to get JD: identical to 3rd dp with spice routine, so good either way, but old way is probably longer
        ;  ;UTC time is given in the format "2013 NOV 09 19:00:46.690", so split up strings based on the characters " :"
        ;  utc_elements = strsplit(utc_time[bbb], "-T:.", /extract)  ;utc_elements is a 6 element array in the format [year, month, day, hour, min, sec.subsec]    
          
        ;  ;Result = JULDAY(Month, Day, Year, Hour, Minute, Second). Convert strings to floats.
        ;  jd_time[bbb] = julday(float(utc_elements[1]), float(utc_elements[2]), float(utc_elements[0]), float(utc_elements[3]), float(utc_elements[4]), float(utc_elements[5]))
          
      jd_time[bbb] = cspice_unitim(et_time[bbb], 'ET', 'JED')  ;convert to JD from ET epoch, using spice
      
      ;Comute UNIX time:
          ;Old way, use Davin's routine below outside of for loop:
          ;  ;First convert the epoch 00:00:00 Jan 1st 1970 to JD date:
          ;  epoch = julday(1,1,1970,0,0,0)
            
          ;  ;Get UNIX time:
          ;  unix_time[bbb] = (jd_time[bbb] - epoch) * 86400.D  ;convert days to secs (after 00:00:00 Jan 1st 1970)
       
      
      ;;Get # of leapseconds passed up to date of interest:
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

;Get CDF_TT2000 time using CDF routine:
;The Idl routine requires the UTC time to be in this format: 2014-10-10T01:34:05.765, this format is output by cspice_et2utc already, but not by Davin's routines

utc_time_temp = utc_time
for ttt = 0L, n_elements(utc_time)-1 do begin
  dd = strsplit(utc_time[ttt], '/', /extract)  ;break up string based on '/'
  utc_time[ttt] = dd[0]+'T'+dd[1]  ;recombine with new delimeter 'T'
endfor

tt1 = cdf_parse_tt2000(utc_time[0])  ;get first and last times and convert
tt2 = cdf_parse_tt2000(utc_time[nele_sclk-1])


;=======================
;--- Check last time ---
;=======================
;Check that the last timestamp from the data lies inside the reconstructed part of the sclk kernel. If it is outside (predicted) then we
;will need to re-run at a later date to get reconstructed time. This will be noted in the x axis title of the tplot variable.

time_check = mvn_lpw_anc_spice_time_check(et_time[nele_sclk-1])  ;give routine the last time point

;------------
str_xtitle = str_xtitle+' '+time_check  ;add to str_xtitle
;------------

if keyword_set(clear_kernels) then mvn_lpw_anc_clear_spice_kernels ;Clear kernel_verified flag, jmm, 2015-02-11   ;CMF made this a keyword 2015-10-08

;Append values to array:
tt = [[sclk], [utc_time], [string(et_time, format='(F16.5)')], $
     [string(jd_time, format='(F16.5)')], [string(unix_time2, format='(F16.5)')], [strtrim(added_ls,2)]]

;NOTE: using print, format='(g)' will print just the year from UTC times, as '(g)' is for doubles. Just use print - they're all strings.

;the array tt is returned, with the format:
;tt=[[MET (s/c time)], [UTC_time], [ET_time], [jd_time], [unix_time], [leapsecs]]
;where each row is the next clock format.

          clock_field_str = ['mission_elapsed_time (SPICE sclk format)', 'UTC_time (yyyymmddhhmmss.ms)', 'ephermeris_time (ET)', 'julian_date (JD)', 'UNIX_time', 'CDF TT2000 Time', 'leapseconds', time_check[0]]
        
   
   ; change so the clock arrays are double instead
    
          clock_start_t = [sclk_time[0],          utc_time_time[0],            et_time[0],          jd_time[0],          unix_time2[0],       tt1,        added_ls[0]] 
          clock_end_t   = [sclk_time[nele_sclk-1],utc_time_time[nele_sclk-1,0],et_time[nele_sclk-1],jd_time[nele_sclk-1],unix_time2[nele_sclk-1],      tt2,      added_ls[nele_sclk-1]] 
   
endif  ;input data OK     

end
