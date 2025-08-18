;+
;Load in MAVEN acceleromater (ACC) L3 derived products to IDL tplot. 
;
;Routine uses timespan command - set start date and number of days with timespan first, and then run this command, similar to the other PFP 
;instruments.
;
;This routine requires SPICE software. ACC times are given as # seconds from periapsis; SPICE is required to find the UTC periapsis time. The user is
;not required to do anything extra (other than install SPICE) - everything is done by the routine.
;
;This routine is still under testing and may break. Please let CMF know if this happens!
;
;
;EGS:
;timespan, '2019-01-01', 2.
;mvn_acc_load
;
;KEYWORDS:
;loadspice: Set as a string, SPICE software is needed to convert orbit number to UNIX time. Set this variable to a string, '0' or '1':
;         '0': don't load SPICE. Use this if you have already loaded in SPICE kernels for the set timespan period.
;         '1': load SPICE. Use this to load SPICE kernels for the set timespan period.
;         The default if not set is to load SPICE.
;         Note: I haven't made this routine clever enough yet to know whether SPICE kernels are already loaded in for the set time range, so
;         it will probably crash if you don't set this keyword correctly.
;
;clearspice: same as loadspice: set as string:
;         '0' : don't clear (leave in IDL memory).
;         '1' : clear from IDL memory.
;         Default is '0'.
;
;OUTPUTS / NOTES:
;The ACC files contain the following quantities for each data point, which are stored in the output tplot variables 'ACC_density' and 'ACC_density_sm'. 
;The full resolution (1s) densities are stored within 'ACC_density', under the '.y' field in the tplot data structure. The smoothed (99s) densities
;are stored within 'ACC_density_sm', under the .y field in the tplot data structure. 
;
;The remaining variables are stored under the tags specified below.
;
;(.x) time from periapsis [s]
;(.y) density - either full (1s) resolution or smoothed (99s), in units of [kg km^-3]
;(.alt) altitude in the IAU (planetary) frame [km]
;(.lon) planetary longitude [degrees]
;(.lat) planetary latitude [degrees]
;(.sza) solar zenith angle [degrees]
;(.lst) local solar time [hours]
;(.sig) sigma of .y field [kg km^-3]
;
;They don't however contain the UNIX time for each point (just the offset in time from periapsis). Using the orbit number in the filename, this 
;routine converts orbit number to a UNIX time at periapsis, which is then used to calculate the UNIX time at each point, based on the offset time. 
;To check the accuracy of this, I have compared the altitudes provided in the ACC files, to the altitudes dervied from SPICE based on these derived 
;UNIX time steps. At periapsis (~150 km), the SPICE derived altitudes are about 0.2 km larger than those provided in the ACC files. At 200 km 
;(roughly where ACC data span up to), SPICE derived altitudes are roughly 0.5 km larger than those provided. Thus, I believe these errors are 
;small enough for most uses that they are insignificant. All altitudes, longitudes and latitudes here are in planetary, ie IAU, coordinates.
;
;I haven't checked the accuracy of the other parameters provided in the ACC file. I assume they are of similar accuracy to altitude.
;
;
;success: set to a variable; on output, it will be: 0 : load unsuccessful - no ACC files found
;                                                   1 : load successful - ACC files found and loaded (note, routine is not clever enough to say whether files were
;                                                       found for each day in the requested time range)
;
;
;OTHER:
;Created by Chris Fowler (cmfowler@berkeley.edu) on 2018-07-31.
;
;.r /Users/cmfowler/IDL/Projects/2018/CME_sep12/mvn_acc_load_l3.pro
;-
;

pro mvn_acc_load_l3, loadspice=loadspice, clearspice=clearspice, success=success

success = 0

get_timespan, datesSET

d1 = time_string(datesSET[0])  ;start date
d2 = time_string(datesSET[1])  ;end date (note, this is the last time +1 requested, eg if requesting 2016-06-08. ndays=3, dates=[2016-06-08/00:00:00, 2016-06-12/00:00:00].

if not keyword_set(loadspice) then loadspice = '1'  ;default
if size(loadspice, /type) ne 7 then loadspice = '1'  ;loadspice must be a string for catches to work
if loadspice eq '1' then kk = mvn_spice_kernels(/load)  ;load kernels for entire time range set.

if not keyword_set(clearspice) then clearspice='0' ;default
if size(clearspice, /type) ne 7 then clearspice='0'

;FIND FILES:
path = 'maven/data/sci/acc/l3/YYYY/MM/'
tmin = min(time_double(datesSET), max=tmax)
fname = 'mvn_acc_l3_pro-*pORBIT_YYYYMMDD_v??_r??.tab'   ;in file retrieve below, the string ORBIT here is replaced by the orbit number, to find the files.
accFILES = mvn_pfp_file_retrieve(path+fname,trange=[tmin,tmax], /orbit_names, /valid)

neleF = n_elements(accFILES)  ;number of files to load

if neleF gt 0 then begin
    
    for ff = 0l, neleF-1l do begin      
        ;Orbit number is in the file name, which is tagged at periapsis. This can be used to get the timestamp of periapsis:
        fbn = file_basename(accFILES[ff])
        orbnum = float(strmid(fbn, 20, 5))  ;orbit number. This method assumes the number of characters in the filename is constant.
        periTIME = mvn_orbit_num(orbnum=orbnum)  ;returns UNIX timestamp

        ;===================
        ;OPEN AND READ FILE: 
        openr, lun, accFILES[ff], /get_lun 
        
        nlines = long(file_lines(accFILES[ff]))  ;work out number of lines in the file
        row = 0l
        
        ;ARRAYS:
        time = dblarr(nlines)  ;store UNIX times here (dervied using SPICE and offset time from periapsis from data file)
        dtime = dblarr(nlines)  ;offset in time from periapsis (from data file)
        lat = fltarr(nlines)
        lon = fltarr(nlines)
        lst = fltarr(nlines)
        sza = fltarr(nlines)
        alt = fltarr(nlines)
        den_sm = fltarr(nlines)  ;smoothed (over 99s) density
        sig_sm = fltarr(nlines)  ;sigma smoothed density
        den = fltarr(nlines)   ;full res density
        sig = fltarr(nlines)   ;sigma full res density
        
        while (not EOF(lun)) do begin
          line = " "
          readf, lun, line
  
          split = strsplit(line, ' ', /regex, /extract)  ;extract elements split up by ','. See text file 812506AALBL.txt for descroption of each column.
            
          ;Append data:
          time[row] = periTIME + split[0]  ;UNIX timestamp
          dtime[row] = split[0]
          lat[row] = split[1]
          lon[row] = split[2]
          lst[row] = split[3]
          sza[row] = split[4]
          alt[row] = split[5]
          den_sm[row] = split[6]
          sig_sm[row] = split[7]
          den[row] = split[8]
          sig[row] = split[9]

          row += 1L
  
        endwhile
       
        close,lun
        free_lun, lun
        
        ;Store into large arrays:
        if size(time_all, /type) eq 0 then begin
          time_all = time
          lat_all = lat
          lon_all = lon
          lst_all = lst
          sza_all = sza
          alt_all = alt
          den_sm_all = den_sm
          sig_sm_all = sig_sm
          den_all = den
          sig_all = sig
          
        endif else begin
          time_all = [time_all, time]
          lat_all = [lat_all, lat]
          lon_all = [lon_all, lon]
          lst_all = [lst_all, lst]
          sza_all = [sza_all, sza]
          alt_all = [alt_all, alt]
          den_sm_all = [den_sm_all, den_sm]
          sig_sm_all = [sig_sm_all, sig_sm]
          den_all = [den_all, den]
          sig_all = [sig_all, sig]
          
        endelse

    endfor ;ff

endif  ;nfileTMP>0


if clearspice eq '1' then mvn_lpw_anc_clear_spice_kernels  ;clear SPICE from IDL if requested

if size(time_all, /type) ne 0 then begin
    ;STORE INTO TPLOT:
    ;Full res data:
    data = create_struct('x'   ,   time_all    , $
                         'y'   ,   den_all     , $
                         'sig' ,   sig_all     , $
                         'lat' ,   lat_all     , $
                         'lon' ,   lon_all     , $
                         'sza' ,   sza_all     , $
                         'alt' ,   alt_all     )
    
    store_data, 'ACC_density', data=data
    options, 'ACC_density', ytitle='ACC neutral density'
    options, 'ACC_density', ysubtitle='[kg km!U-3!N]'
    options, 'ACC_density', 'datagap', 300.
    
    ;Smoothed data:
    data = create_struct('x'   ,   time_all    , $
                         'y'   ,   den_sm_all     , $
                         'sig' ,   sig_sm_all     , $
                         'lat' ,   lat_all     , $
                         'lon' ,   lon_all     , $
                         'sza' ,   sza_all     , $
                         'alt' ,   alt_all     )
    
    store_data, 'ACC_density_sm', data=data
    options, 'ACC_density_sm', ytitle='ACC neutral density (sm)'
    options, 'ACC_density_sm', ysubtitle='[kg km!U-3!N]'
    options, 'ACC_density_sm', 'datagap', 300.
    
    success=1
endif else begin
    print, ""
    print, "No ACC data files found for the requested date range."
endelse


end






