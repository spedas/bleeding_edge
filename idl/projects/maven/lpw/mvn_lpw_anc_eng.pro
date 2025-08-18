;+
;pro mvn_lpw_anc_eng, unix_in
;
;PROCEDURE:   mvn_lpw_anc_eng
;PURPOSE:
; Produce tplot variables of reaction wheel and thruster firing information when available.
; 
;USAGE:
; mvn_lpw_anc_eng, unix_in
; 
;INPUTS:
;              
;- unix_in: a dblarr of unix times. This array is used to search for the correct engineering files. Returned engineering information has it's own
;           timesteps, IT WILL NOT match unix_in. Engineering files do not stop/start at midnight like L0 files; they also cover varying lengths in time.
;           Because of this a time span of +- 5 days is added to unix_in when searching for engineering files. Any "extra" timesteps within the found
;           engineering files are then removed, so that returned tplot variables match unix_in as closely as possible in terms of coverage start:stop times.
;
;This code also requires access to the SSL svn library as it uses various IDL routines from there to fetch data and convert between UNIX and UTC times.
;
;OUTPUTS:
;Tplot variables:
;
;mvn_lpw_anc_rw: reaction wheel spin rates, in units of Hz. There are four wheels, and can spin +-
;
;mvn_lpw_spec_lf_pas-rw: absolute reaction wheel spin rates, converted to Hz, overplotted on the passive lf spectra. mvn_lpw_spec_lf_pas 
;                        must be in tplot memory to produce this variable
;                        
;mvn_lpw_spec_lf_act-rw: absolute reaction wheel spin rates, converted to Hz, overplotted on the active lf spectra. mvn_lpw_spec_lf_act 
;                        must be in tplot memory to produce this variable               
;
;mvn_lpw_anc_acs: # of ACS thruster firings per timestep. There are 8 ACS thrusters - these are the main attitude control thrusters and fire
;                 the most
;
;mvn_lpw_anc_tcm: # of TCM thruster firings per timestep. There are 6 TCM thrusters - these fire less often and are for major trajectory corrections
;        
;mvn_lpw_anc_sc-rot: rotation rate of s/c about s/c x,y,z axes. Units given are "rotation rate" - not sure on actual units. 
;
;mvn_lpw_anc_rel_rw: Speed of RWs in Hz, relative to RW1. NOTE currently disabled as not sure this works correctly. 
;  
;NOTES:
;Correspondence with Boris Semenov: mvn_rec_*.sff (thruster) files are produced in ET time, with clock drift taken into account.
;Correspondence with Mike Haggard: mvn_rec_*.drf (RW) files are produced in UTC time, with clock drift "should be" taken into account.                                        
;
;Davin's routines take string UTC dates and convert to UNIX, so there should be no need to include SPICE when using these, assuming your UNIX times have been SPICE corrected.
;                          
;                                                      
;KEYWORDS:
; NONE
;
;CREATED BY:   Chris Fowler May 27th 2014
;FILE: 
;VERSION:   2.0
;LAST MODIFICATION:
;2024-05-02: CF: added new tplot variables mvn-lpw-anc-sc-rot, mvn-lpw-anc-rel-rw. Added use of mvn-lpw-plus-sym to produce scalable plotting symbols.
; ;140718 clean up for check out L. Andersson
; 14-10-31: CF: removed ISTP dlimit information via keyword as this isn't needed and needs to be more complicated to work properly.
; 15-08-12: CMF: cleaned up comments, disabled automatic production of mvn_lpw_anc_rel_r.
; 
;-


pro mvn_lpw_anc_eng, unix_in

;Run Lailas sym routine to generate a scalable (by size) plotting symbol:
mvn_lpw_plus_sym, /fill  ;set psym=8 to use

t_routine=systime(0)

;Checks:
;Make sure unix_in is dblarr:
if size(unix_in, /type) ne 5 then begin
    print, "#######################"
    print, "WARNING: unix_in must be a double array of UNIX times."
    print, "#######################"
    return
endif
today_date = systime(0)
nele = n_elements(unix_in)
sl = path_sep()


;We now have to add ~5 days either side of unix_in to ensure we get coverage for the day we want:
t1 = unix_in[0] - (3.*86400.D)   ;+- three days
t2 = unix_in[nele-1] + (3.*86400.D)


;For now, don't need all the ISTP information, as we're not documenting the engineering files:

if keyword_set(noskip) then begin   ;Leave this keyword line in, otherwise code will try to get information not present and crash.
    ;Get dlimit info from an available tplot variable (this assumes the first two variables are L0 file info and kernel info):
    tplotnames = tnames()
    if tplotnames[0] ne '' and n_elements(tplotnames) gt 2 then begin  ;if we have tplot variables 
        get_data, tplotnames[2], dlimit=dl, limit=ll  ;doesn't matter which variable for now, we just want the CDF fields from this which are identical
                                                      ;for all variables. But, kernel and orbit info are in first two tplot variables
        cdf_istp = strarr(15)  ;copy across the fields from dlimit:
        cdf_istp[0] = dl.Source_name
        cdf_istp[1] = dl.Discipline
        cdf_istp[2] = dl.Instrument_type
        cdf_istp[3] = 'Support_data'  ;dl.Data_type
        cdf_istp[4] = dl.Data_version
        cdf_istp[5] = dl.Descriptor
        cdf_istp[6] = dl.PI_name
        cdf_istp[7] = dl.PI_affiliation
        cdf_istp[8] = dl.TEXT
        cdf_istp[9] = dl.Mission_group
        cdf_istp[10] = dl.Generated_by
        cdf_istp[11] = dl.Generation_date
        cdf_istp[12] = dl.Rules_of_use
        cdf_istp[13] = dl.Acknowledgement
        t_epoch = dl.t_epoch  
        L0_datafile = dl.L0_datafile 
        
        time_check = ll.xtitle                                           
    endif else begin
        print, "################"
        print, "WARNING: Some tplot dlimit fields may be missing. Check at least one LPW tplot variable"
        print, "is in IDL memory before running mvn_lpw_anc_eng."
        print, "################"
        ;Create a dummy array containing blank strings so routine won't crash later:
        cdf_istp = strarr(15) + 'dlimit info unavailable'
        t_epoch = 'dlimit info unavailable'
        L0_datafile = 'dlimit info unavailable'
        time_check = 'Time (predicted / reconstructed info unavailable)'
    endelse
endif else begin
      cdf_istp = strarr(15) + 'dlimit info unavailable'
      t_epoch = 'dlimit info unavailable'
      L0_datafile = 'dlimit info unavailable'
      time_check = 'Time (predicted / reconstructed info unavailable)'
endelse

;============
;Get standard information for other dlimit fields:
et_time = time_ephemeris(unix_in, /ut2et)  ;et_time
utc_time = time_string(unix_in)   ;format: 2014-03-20/00:00:11
;Break up UTC time in a dbl number, just first and last times:
   aa= strsplit(utc_time[0],'/',/extract)  ;first time
   bb= strsplit(aa[0],'-',/extract)
   cc= strsplit(aa[1],':',/extract)
   utc_time1 =10000000000.0 * double( bb[0]) + 100000000.0 * double(bb[1]) + 1000000.0 * double(bb[2]) + 10000.0 *double(cc[0]) + 100.0 * double(cc[1]) +double(cc[2]) 
   aa= strsplit(utc_time[nele-1],'/',/extract)  ;last time
   bb= strsplit(aa[0],'-',/extract)
   cc= strsplit(aa[1],':',/extract)
   utc_time2 =10000000000.0 * double( bb[0]) + 100000000.0 * double(bb[1]) + 1000000.0 * double(bb[2]) + 10000.0 *double(cc[0]) + 100.0 * double(cc[1]) +double(cc[2]) 

;Check these times are predicted or reconstructed, from a present tplot variable:
;time_check = mvn_lpw_anc_spice_time_check(et_time[nele-1])  ;we check the last time. If this is predicted, we must run entire orbit later. ## fix this routine
;time_check = '(Eng data)'  ;these files have their own timestamps, the user doesn't need SPICE.

time_start = [unix_in[0], utc_time1, et_time[0]]
time_end = [unix_in[nele-1], utc_time2, et_time[nele-1]]
time_field = ['UNIX time', 'UTC time', 'ET time']
spice_used = 'Engineering files do not require SPICE from user'
;kernel_version = filenames_rw/th, defined below
loaded_kernels = 'None: engineering files do not require SPICE from user'
str_xtitle = time_check   ;predicted or reconstructed, use a loaded tplot variable (above)
;===========
 
t1c1 = t1
t2c1 = t2
t1c2 = t1
t2c2 = t2
 
;Get thruster info:
thruster = mvn_spc_anc_thruster(trange=[t1c1,t2c1])

;Reaction wheel info:
reac = mvn_spc_anc_reactionwheels(trange=[t1c2,t2c2])

;Check we found files:
if (size(thruster, /type) eq 0) or (size(thruster, /type) eq 7) then print, "### WARNING ###: mvn_lpw_anc_eng: No thruster files found. Your date may be too recent."
if size(reac, /type) eq 0 then print, "### WARNING ###: mvn_lpw_anc_eng: No reaction wheel informtion found. Your date may be too recent."
if (size(thruster, /type) eq 0 or size(thruster, /type) eq 7) and size(reac, /type) eq 0 then begin
    print, "No engineering information found. Returning."
    return
endif

   ;Find engineering files, for dlimit:
   pformat = 'maven/data/anc/eng/gnc/sci_anc_gncyy_DOY_???.drf'
   daily_names=1
   last_version=1
   filenames_rw = mvn_pfp_file_retrieve(pformat,trange=[t1,t2],daily_names=daily_names,last_version=last_version,/valid_only)  ;RW
    if size(filenames_rw, /type) eq 0 then filenames_rw = 'No reaction wheel files found."
   pformat='maven/data/anc/eng/sff/mvn_rec_yyMMDD_*.sff'
   filenames_th = mvn_pfp_file_retrieve(pformat,trange=[t1,t2],daily_names=daily_names,last_version=last_version,/valid_only)  ;thrusters
    if size(filenames_th, /type) eq 0 then filenames_th = 'No thruster files found."
   
   kernel_version = 'Engineering files used:'
   for ii = 0, n_elements(filenames_rw)-1 do begin
      ;Extract just kernel name and remove directory:
      nind = strpos(filenames_rw[ii], sl, /reverse_search)  ;nind is the indice of the last '/' in the directory before the kernel name
      lenstr = strlen(filenames_rw[ii])  ;length of the string directory
      kname = strmid(filenames_rw[ii], nind+1, lenstr-nind)  ;extract just the kernel name  
      kernel_version = kernel_version+' # '+kname
   endfor
   for ii = 0, n_elements(filenames_th)-1 do begin
      ;Extract just kernel name and remove directory:
      nind = strpos(filenames_th[ii], sl, /reverse_search)  ;nind is the indice of the last '/' in the directory before the kernel name
      lenstr = strlen(filenames_th[ii])  ;length of the string directory
      kname = strmid(filenames_th[ii], nind+1, lenstr-nind)  ;extract just the kernel name  
      kernel_version = kernel_version+' # '+kname
   endfor
   
;============
;Find time that corresponds to loaded tplot variable, as eng data covers several days:               
if size(reac, /type) ne 0 then begin
    rtime = reac[*].time
    rtime = rtime * (rtime gt unix_in[0]) * (rtime lt unix_in[nele-1])  ;rtime outside of unix_in will be 0's
    rtimes = where(rtime ne 0, nr)
    
    if nr gt 0 then begin
        reac_rw = reac[rtimes]  ;extract just the times within unix_in
        nele_r = n_elements(reac_rw)
    endif else begin 
        print, "### WARNING ###: mvn_lpw_anc_eng: no reaction wheel information for times within input UNIX times."
        reac_rw = fltarr(1) -999  ;one element array which is easy to pick out
        nele_r = 0.
    endelse

    rottime = reac[*].time
    rottime = rottime * (rottime gt unix_in[0]) * (rottime lt unix_in[nele-1])
    rottimes = where(rottime ne 0, nrot)
    
    if nrot gt 0 then begin
        reac_rot = reac[rottimes]
        nele_rot = n_elements(reac_rot)
    endif else begin
        print, "### WARNING ###: mvn_lpw_anc_eng: no s/c rotation information for times within input UNIX times."
        reac_rot = fltarr(1)-999  ;make this a one element array as we can pick this out later
        nele_rot = 0.
    endelse    
    
endif else begin
      nele_r = 0
      nele_rot = 0.
endelse
;----
if size(thruster, /type) ne 0 and size(thruster, /type) ne 7 then begin
    ttime = thruster[*].time  ;old time was the start time of each gap
    ttime = ttime * (ttime gt unix_in[0]) * (ttime lt unix_in[nele-1])  ;get rid of points outside of input UNIX time range
    ttimes = where(ttime ne 0, nt)  ;find points inside time range
    
    if nt gt 0 then begin
        thruster_th = thruster[ttimes]  ;get points inside time range
        
        ttime1 = thruster_th[*].trange[0]  ;start times
        ttime2 = thruster_th[*].trange[1]  ;end times
        ttimeMID = ttime1 + ((ttime2-ttime1)/2.d)  ;pick time in middle of time gap
        
        nele_t = n_elements(thruster_th)
    endif else begin
        print, "### WARNING ###: mvn_lpw_anc_eng: no thruster information for times within input UNIX times."
        thruster_th = fltarr(1)-999  ;make this a one element array as we can pick this out later
        nele_t = 0.
    endelse
endif else nele_t = 0.
;----

;=============
;Convert reaction wheel dgtl # [rad/s] to Hz [/s]:

if nele_r gt 1 then begin  ;reaction wheels
      yyr = fltarr(nele_r,4)
      yyr[*,0] = reac_rw[*].RW1_SPD_DGTL  ;add speeds to array
      yyr[*,1] = reac_rw[*].RW2_SPD_DGTL
      yyr[*,2] = reac_rw[*].RW3_SPD_DGTL
      yyr[*,3] = reac_rw[*].RW4_SPD_DGTL
      yyr = yyr * (1/(2.D*!pi))   ;convert to Hz
      time_r = reac_rw[*].time  ;time stamps              
                      
                      
            ;-------------------------------------------
            data =  create_struct('x', time_r, 'y', yyr)
            ;-------------------------------------------
            ;--------------- dlimit   ------------------
            dlimit=create_struct(   $                           
                'Product_name',                  'mvn_lpw_anc_rw', $
                'Project',                       cdf_istp[12], $
                'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
                'Discipline',                    cdf_istp[1], $
                'Instrument_type',               cdf_istp[2], $
                'Data_type',                     'Support_data' ,  $
                'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                'Descriptor',                    cdf_istp[5], $
                'PI_name',                       cdf_istp[6], $
                'PI_affiliation',                cdf_istp[7], $     
                'TEXT',                          cdf_istp[8], $
                'Mission_group',                 cdf_istp[9], $     
                'Generated_by',                  cdf_istp[10],  $
                'Generation_date',                today_date+' # '+t_routine, $
                'Rules of use',                  cdf_istp[11], $
                'Acknowledgement',               cdf_istp[13],   $ 
                'Title',                         '', $   ;####            
                'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                'y_catdesc',                     'Reaction wheel spin frequency in Hz.', $    
                ;'v_catdesc',                     'test dlimit file, v', $    ;###
                'dy_catdesc',                    'Error on the data.', $     ;###
                ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                'y_Var_notes',                   'Units of Hz.', $
                ;'v_Var_notes',                   'Frequency bins', $
                'dy_Var_notes',                  'Not used.', $
                ;'dv_Var_notes',                   'Error on frequency', $
                'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
                'xFieldnam',                     'x: More information', $      ;###
                'yFieldnam',                     'y: More information', $
               ; 'vFieldnam',                     'v: More information', $
                'dyFieldnam',                    'dy: Not used.', $
              ;  'dvFieldnam',                    'dv: More information', $
                'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $ 
               'MONOTON', 'INCREASE', $
               'SCALEMIN', min(data.y,/nan), $
               'SCALEMAX', max(data.y,/nan), $        ;..end of required for cdf production.
               't_epoch'         ,     t_epoch, $
               'Time_start'      ,     time_start, $
               'Time_end'        ,     time_end, $
               'Time_field'      ,     time_field, $
               'SPICE_kernel_version', kernel_version, $
               'SPICE_kernel_flag'      ,     spice_used, $                       
               'L0_datafile'     ,     L0_datafile , $ 
               'cal_vers'        ,     kernel_version ,$     
               'cal_y_const1'    ,     'Engineering files' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'cal_datafile'    ,     'No calibration file used' , $
               'cal_source'      ,     'Reaction wheel engineering files', $     
               'xsubtitle'       ,     '[sec]', $   
               'ysubtitle'       ,     '[Hz]');, $                     
               ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'zsubtitle'       ,     '[Attitude]')          
            ;-------------  limit ---------------- 
            limit=create_struct(   $               
              'char_size' ,     1.2                      ,$    
              'xtitle' ,        str_xtitle                   ,$   
              'ytitle' ,        'RW-Speed'                 ,$   
              'yrange' ,        [1.1*min(data.y,/nan),1.1*max(data.y, /nan)] ,$   
              'ystyle'  ,       1.                       ,$  
              'labflag',        1, $
              'labels',         ['RW1', 'RW2', 'RW3', 'RW4']   , $
              'colors',         [0,2,6,4]       , $
              'psym'  ,         0              , $
              'symsize',        0.5         ,$
              ;'ztitle' ,        'Z-title'                ,$   
              ;'zrange' ,        [min(data.y),max(data.y)],$                        
              ;'spec'            ,     1, $           
              ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
              ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
              ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
              'noerrorbars', 1)   
           ;---------------------------------
           store_data, 'mvn_lpw_anc_rw', data=data, dlimit=dlimit, limit=limit
      
      ;Combine with spec plot:
      tplotnames=tnames()
      if total(strmatch(tplotnames, 'mvn_lpw_spec_lf_pas')) eq 1 then begin
          store_data, 'mvn_lpw_spec_lf_pas-rw', data=['mvn_lpw_spec_lf_pas', 'mvn_lpw_anc_rw']
          ylim, 'mvn_lpw_spec_lf_pas-rw', [1.e-1, 1.e2]
      endif
      if total(strmatch(tplotnames, 'mvn_lpw_spec_lf_act')) eq 1 then begin
          store_data, 'mvn_lpw_spec_lf_act-rw', data=['mvn_lpw_spec_lf_act', 'mvn_lpw_anc_rw']
          ylim, 'mvn_lpw_spec_lf_act-rw', [1.e-1, 1.e2]
      endif
      
      
      ;Construct tplot variable which shows the relative absolute spin freqs of the 4 wheels. When the 4 wheels spin close to the same freq,
      ;I think they appear in the spectra. They don't appear when spinning at different Hz (I think).
      rel_rw = fltarr(nele_r,4)
      for aa = 0L, nele_r-1L do begin
          for bb = 0, 3 do rel_rw[aa,bb] = abs((abs(yyr[aa,0]) - abs(yyr[aa,bb]))) * (1/(2.D*!pi))  ;use RW 1 as the baseline, convert to Hz
      endfor  ;over aa
            ;-------------------------------------------
            data =  create_struct('x', time_r, 'y', rel_rw)
            ;-------------------------------------------
            ;--------------- dlimit   ------------------
            dlimit=create_struct(   $                           
              'Product_name',                  'mvn_lpw_anc_rel_rw', $
              'Project',                       cdf_istp[12], $
              'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
              'Discipline',                    cdf_istp[1], $
              'Instrument_type',               cdf_istp[2], $
              'Data_type',                     'Support_data' ,  $
              'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
              'Descriptor',                    cdf_istp[5], $
              'PI_name',                       cdf_istp[6], $
              'PI_affiliation',                cdf_istp[7], $     
              'TEXT',                          cdf_istp[8], $
              'Mission_group',                 cdf_istp[9], $     
              'Generated_by',                  cdf_istp[10],  $
              'Generation_date',                today_date+' # '+t_routine, $
              'Rules of use',                  cdf_istp[11], $
              'Acknowledgement',               cdf_istp[13],   $ 
              'Title',                         '', $   ;####            
              'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
              'y_catdesc',                     'Difference in RW frequency, relative to RW 1.', $    
              ;'v_catdesc',                     'test dlimit file, v', $    ;###
              'dy_catdesc',                    'Error on the data.', $     ;###
              ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
              'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
              'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
              'y_Var_notes',                   'Frequency of RW#, subtracted from RW 1 frequency.', $
              ;'v_Var_notes',                   'Frequency bins', $
              'dy_Var_notes',                  'Not used.', $
              ;'dv_Var_notes',                   'Error on frequency', $
              'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
              'xFieldnam',                     'x: More information', $      ;###
              'yFieldnam',                     'y: More information', $
             ; 'vFieldnam',                     'v: More information', $
              'dyFieldnam',                    'dy: Not used.', $
            ;  'dvFieldnam',                    'dv: More information', $
              'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $  
               'MONOTON', 'INCREASE', $
               'SCALEMIN', min(data.y,/nan), $
               'SCALEMAX', max(data.y,/nan), $        ;..end of required for cdf production.
               't_epoch'         ,     t_epoch, $
               'Time_start'      ,     time_start, $
               'Time_end'        ,     time_end, $
               'Time_field'      ,     time_field, $
               'SPICE_kernel_version', kernel_version, $
               'SPICE_kernel_flag'      ,     spice_used, $                       
               'L0_datafile'     ,     L0_datafile , $ 
               'cal_vers'        ,     kernel_version ,$     
               'cal_y_const1'    ,     'Engineering files' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'cal_datafile'    ,     'No calibration file used' , $
               'cal_source'      ,     'Reaction wheel engineering files', $     
               'xsubtitle'       ,     '[sec]', $   
               'ysubtitle'       ,     '[Hz]');, $                     
               ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'zsubtitle'       ,     '[Attitude]')          
            ;-------------  limit ---------------- 
            limit=create_struct(   $               
              'char_size' ,     1.2                      ,$    
              'xtitle' ,        str_xtitle                   ,$   
              'ytitle' ,        'RW rel frequency'                 ,$   
              'yrange' ,        [min(data.y,/nan) , 1.1*max(data.y, /nan)] ,$    ;differences are absolute so shouldn't go below 0.
              'ystyle'  ,       1.                       ,$  
              'labflag',        1, $
              'labels',         ['RW1', 'RW2', 'RW3', 'RW4']   , $
              'colors',         [0,2,6,4]       , $
              'psym'  ,         0              , $
              'symsize',        0.25         ,$
              ;'ztitle' ,        'Z-title'                ,$   
              ;'zrange' ,        [min(data.y),max(data.y)],$                        
              ;'spec'            ,     1, $           
              ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
              ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
              ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
              'noerrorbars', 1)   
           ;---------------------------------
           ;store_data, 'mvn_lpw_anc_rel_rw', data=data, dlimit=dlimit, limit=limit             ;### NOT sure this works correctly.
      
endif  ;nele_r gt 1

if nele_t gt 1 then begin
    ;time_t = thruster_th[*].time  ;timestamps  ;OLD
    time_t = ttimeMID  ;start and stop times added below
    yy1 = fltarr(nele_t,8)
    yy2 = fltarr(nele_t,6)
    for ii = 0, 7 do yy1[*,ii] = thruster_th[*].L28[ii]  ;get ACS thruster firings
    for ii = 0, 5 do yy2[*,ii] = thruster_th[*].L28[ii+8]  ;get TCM thruster firings
    
            ;-------------------------------------------
            data =  create_struct('x', time_t, 'y', yy1, 'dy', ttime1, 'dv', ttime2)  ;add in start and stop times
            ;-------------------------------------------
            ;--------------- dlimit   ------------------
            dlimit=create_struct(   $                           
              'Product_name',                  'mvn_lpw_anc_acs', $
              'Project',                       cdf_istp[12], $
              'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
              'Discipline',                    cdf_istp[1], $
              'Instrument_type',               cdf_istp[2], $
              'Data_type',                     'Support_data' ,  $
              'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
              'Descriptor',                    cdf_istp[5], $
              'PI_name',                       cdf_istp[6], $
              'PI_affiliation',                cdf_istp[7], $     
              'TEXT',                          cdf_istp[8], $
              'Mission_group',                 cdf_istp[9], $     
              'Generated_by',                  cdf_istp[10],  $
              'Generation_date',                today_date+' # '+t_routine, $
              'Rules of use',                  cdf_istp[11], $
              'Acknowledgement',               cdf_istp[13],   $ 
              'Title',                         '', $   ;####            
              'x_catdesc',                     'Timestamps for each data point, in UNIX time. Engineering files give time blocks; these are the mid points of each time block. The start and stop times of each time block are given in dy and dv.', $
              'y_catdesc',                     'The number of ACS thruster firings per time block.', $    
              ;'v_catdesc',                     'test dlimit file, v', $    ;###
              'dy_catdesc',                    'Start time of each time block, in UNIX time.', $     ;###
              'dv_catdesc',                    'Finish time of each time block, in UNIX time.', $   ;###
              'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
              'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
              'y_Var_notes',                   'ACS thrusters fire mainly during reaction wheel desat manoeuvres.', $
              ;'v_Var_notes',                   'Frequency bins', $
              'dy_Var_notes',                  'Size of time blocks varys.', $
              'dv_Var_notes',                  'Size of time blocks varys', $
              'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
              'xFieldnam',                     'x: More information', $      ;###
              'yFieldnam',                     'y: More information', $
             ; 'vFieldnam',                     'v: More information', $
              'dyFieldnam',                    'NA.', $
              'dvFieldnam',                    'NA.', $
              'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
               'MONOTON', 'INCREASE', $
               'SCALEMIN', min(data.y,/nan), $
               'SCALEMAX', max(data.y,/nan), $        ;..end of required for cdf production.
               't_epoch'         ,     t_epoch, $
               'Time_start'      ,     time_start, $
               'Time_end'        ,     time_end, $
               'Time_field'      ,     time_field, $
               'SPICE_kernel_version', kernel_version, $
               'SPICE_kernel_flag'      ,     spice_used, $                       
               'L0_datafile'     ,     L0_datafile , $ 
               'cal_vers'        ,     kernel_version ,$     
               'cal_y_const1'    ,     'Engineering files' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'cal_datafile'    ,     'No calibration file used' , $
               'cal_source'      ,     'ACS thruster engineering files', $     
               'xsubtitle'       ,     '[sec]', $   
               'ysubtitle'       ,     '[#]');, $                     
               ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'zsubtitle'       ,     '[Attitude]')          
            ;-------------  limit ---------------- 
            limit=create_struct(   $               
              'char_size' ,     1.2                      ,$    
              'xtitle' ,        str_xtitle                   ,$   
              'ytitle' ,        'ACS Thruster firings'                 ,$   
              'yrange' ,        [1.1*min(data.y,/nan),1.1*max(data.y, /nan)] ,$   
              'ystyle'  ,       1.                       ,$  
              'labflag',        1, $
              'labels',         ['ACS1', 'ACS2', 'ACS3', 'ACS4', 'ACS5', 'ACS6', 'ACS7', 'ACS8']   , $
              'colors',         [0,1,2,3,4,5,6,7]       , $
              'psym',           1                         , $
              'symsize',         3     ,$
              ;'ztitle' ,        'Z-title'                ,$   
              ;'zrange' ,        [min(data.y),max(data.y)],$                        
              ;'spec'            ,     1, $           
              ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
              ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
              ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
              'noerrorbars', 1)   
           ;---------------------------------
           store_data, 'mvn_lpw_anc_acs', data=data, dlimit=dlimit, limit=limit   

            ;-------------------------------------------
            data =  create_struct('x', time_t, 'y', yy2, 'dy', ttime1, 'dv', ttime2)
            ;-------------------------------------------
            ;--------------- dlimit   ------------------
            dlimit=create_struct(   $                           
              'Product_name',                  'mvn_lpw_anc_tcm', $
              'Project',                       cdf_istp[12], $
              'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
              'Discipline',                    cdf_istp[1], $
              'Instrument_type',               cdf_istp[2], $
              'Data_type',                     'Support_data' ,  $
              'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
              'Descriptor',                    cdf_istp[5], $
              'PI_name',                       cdf_istp[6], $
              'PI_affiliation',                cdf_istp[7], $     
              'TEXT',                          cdf_istp[8], $
              'Mission_group',                 cdf_istp[9], $     
              'Generated_by',                  cdf_istp[10],  $
              'Generation_date',                today_date+' # '+t_routine, $
              'Rules of use',                  cdf_istp[11], $
              'Acknowledgement',               cdf_istp[13],   $ 
              'Title',                         '', $   ;####            
              'x_catdesc',                     'Timestamps for each data point, in UNIX time. Engineering files give time blocks; these are the mid points of each time block. The start and stop times of each time block are given in dy and dv.', $
              'y_catdesc',                     'Number of TCM thruster firings per time block.', $    
              ;'v_catdesc',                     'test dlimit file, v', $    ;###
              'dy_catdesc',                    'Start time of each time block, in UNIX time.', $     ;###
              'dv_catdesc',                    'Finish time of each time block, in UNIX time.', $   ;###
              'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
              'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
              'y_Var_notes',                   'TCM thrusters are for large manoeuvres and are seen less often than the ACS thrusters.', $
              ;'v_Var_notes',                   'Frequency bins', $
              'dy_Var_notes',                  'Size of time blocks varys.', $
              'dv_Var_notes',                  'Size of time blocks varys.', $
              'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
              'xFieldnam',                     'x: More information', $      ;###
              'yFieldnam',                     'y: More information', $
             ; 'vFieldnam',                     'v: More information', $
              'dyFieldnam',                    'NA.', $
              'dvFieldnam',                    'NA.', $
              'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $ 
               'MONOTON', 'INCREASE', $
               'SCALEMIN', min(data.y,/nan), $
               'SCALEMAX', max(data.y,/nan), $        ;..end of required for cdf production.
               't_epoch'         ,     t_epoch, $
               'Time_start'      ,     time_start, $
               'Time_end'        ,     time_end, $
               'Time_field'      ,     time_field, $
               'SPICE_kernel_version', kernel_version, $
               'SPICE_kernel_flag'      ,     spice_used, $                       
               'L0_datafile'     ,     L0_datafile , $ 
               'cal_vers'        ,     kernel_version ,$     
               'cal_y_const1'    ,     'Engineering files' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'cal_datafile'    ,     'No calibration file used' , $
               'cal_source'      ,     'TCM thruster engineering files', $     
               'xsubtitle'       ,     '[sec]', $   
               'ysubtitle'       ,     '[#]');, $                     
               ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'zsubtitle'       ,     '[Attitude]')          
            ;-------------  limit ---------------- 
            limit=create_struct(   $               
              'char_size' ,     1.2                      ,$    
              'xtitle' ,        str_xtitle                   ,$   
              'ytitle' ,        'TCM Thruster firings'                 ,$   
              'yrange' ,        [1.1*min(data.y,/nan),1.1*max(data.y, /nan)] ,$   
              'ystyle'  ,       1.                       ,$  
              'labflag',        1, $
              'labels',         ['TCM1', 'TCM2', 'TCM3', 'TCM4', 'TCM5', 'TCM6']   , $
              'colors',         [0,1,2,3,4,6]       , $
              'psym',           3                   ,$
              'symsize',        3                   ,$
              ;'ztitle' ,        'Z-title'                ,$   
              ;'zrange' ,        [min(data.y),max(data.y)],$                        
              ;'spec'            ,     1, $           
              ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
              ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
              ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
              'noerrorbars', 1)   
           ;---------------------------------
           store_data, 'mvn_lpw_anc_tcm', data=data, dlimit=dlimit, limit=limit

endif  ;nele_t gt 1

if nele_rot gt 1 then begin
    ;Tplot s/c rotation about s/c axes:
      yrot = fltarr(nele_rot,3)
      yrot[*,0] = reac_rot[*].ATT_RAT_BF_X  ;add rotation to array. Not sure on units, they are "spacecraft angular rates"
      yrot[*,1] = reac_rot[*].ATT_RAT_BF_Y
      yrot[*,2] = reac_rot[*].ATT_RAT_BF_Z
      time_rot = reac_rot[*].time  ;time stamps    

            ;-------------------------------------------
            data =  create_struct('x', time_rot, 'y', yrot)
            ;-------------------------------------------
            ;--------------- dlimit   ------------------
            dlimit=create_struct(   $                           
              'Product_name',                  'mvn_lpw_anc_s/c_rot', $
              'Project',                       cdf_istp[12], $
              'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
              'Discipline',                    cdf_istp[1], $
              'Instrument_type',               cdf_istp[2], $
              'Data_type',                     'Support_data' ,  $
              'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
              'Descriptor',                    cdf_istp[5], $
              'PI_name',                       cdf_istp[6], $
              'PI_affiliation',                cdf_istp[7], $     
              'TEXT',                          cdf_istp[8], $
              'Mission_group',                 cdf_istp[9], $     
              'Generated_by',                  cdf_istp[10],  $
              'Generation_date',                today_date+' # '+t_routine, $
              'Rules of use',                  cdf_istp[11], $
              'Acknowledgement',               cdf_istp[13],   $ 
              'Title',                         '', $   ;####            
              'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
              'y_catdesc',                     'Spacecraft rotation rate (angular rate).', $    
              ;'v_catdesc',                     'test dlimit file, v', $    ;###
              'dy_catdesc',                    'Error on the data.', $     ;###
              ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
              'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
              'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
              'y_Var_notes',                   'Rate of spacecraft rotation.', $
              ;'v_Var_notes',                   'Frequency bins', $
              'dy_Var_notes',                  'Not used.', $
              ;'dv_Var_notes',                   'Error on frequency', $
              'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
              'xFieldnam',                     'x: More information', $      ;###
              'yFieldnam',                     'y: More information', $
             ; 'vFieldnam',                     'v: More information', $
              'dyFieldnam',                    'dy: Not used.', $
            ;  'dvFieldnam',                    'dv: More information', $
              'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $ 
               'MONOTON', 'INCREASE', $
               'SCALEMIN', min(data.y,/nan), $
               'SCALEMAX', max(data.y,/nan), $        ;..end of required for cdf production.
               't_epoch'         ,     t_epoch, $
               'Time_start'      ,     time_start, $
               'Time_end'        ,     time_end, $
               'Time_field'      ,     time_field, $
               'SPICE_kernel_version', kernel_version, $
               'SPICE_kernel_flag'      ,     spice_used, $                       
               'L0_datafile'     ,     L0_datafile , $ 
               'cal_vers'        ,     kernel_version ,$     
               'cal_y_const1'    ,     'Engineering files' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'cal_datafile'    ,     'No calibration file used' , $
               'cal_source'      ,     'S/C rotation from reaction wheel engineering files', $     
               'xsubtitle'       ,     '[sec]', $   
               'ysubtitle'       ,     '[Angular rate]');, $                     
               ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
               ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
               ;'zsubtitle'       ,     '[Attitude]')          
            ;-------------  limit ---------------- 
            limit=create_struct(   $               
              'char_size' ,     1.2                      ,$    
              'xtitle' ,        str_xtitle                   ,$   
              'ytitle' ,        'S/C rotation'                 ,$   
              'yrange' ,        [1.1*min(data.y,/nan),1.1*max(data.y, /nan)] ,$   
              'ystyle'  ,       1.                       ,$  
              'labflag',        1, $
              'labels',         ['s/c X', 's/c Y', 's/c Z']   , $
              'colors',         [0,2,6]       , $
              'psym',            0                        ,$
              ;'ztitle' ,        'Z-title'                ,$   
              ;'zrange' ,        [min(data.y),max(data.y)],$                        
              ;'spec'            ,     1, $           
              ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
              ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
              ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
              'noerrorbars', 1)   
           ;---------------------------------
           store_data, 'mvn_lpw_anc_sc_rot', data=data, dlimit=dlimit, limit=limit 


endif  ;over nele_rot gt 1



;stop

end


