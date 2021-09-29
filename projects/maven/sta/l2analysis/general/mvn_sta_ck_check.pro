;+
;Routine to check whether SPICE kernels exist so that pointing information for STATIC can be converted from instrument to MSO
;frame. This is needed for, eg, the sta flow routines.
;
;Code written using help from Boris Semenov from JPL NASA.
;
;Give this routine an array of UNIX times; the routine uses SPICE to check whether there is ck and spk coverage for each timestamp.
;The calls to SPICE are all hard coded, so the only inputs are the timestamps required.
;
;The tplot variable produced will have value zero if kernels are present, or 1 if flagged as not present. For 1, SPICE cannot be used to
;get STATIC pointing in the MSO Frame.
;   mvn_sta_ck_check  :  0 = ok, 1 = flag - no SPICE coverage for this timestep.
;
;INPUTS:
;unix_in: UNIX double precision array of timetamps. The routine will check SPICE coverage at each timestep.
;
;
;   NOTES ON INPUTS: SPICE information for MAVEN is found at https://lasp.colorado.edu/maven/sdc/public/data/anc/spice/fk/maven_v05.tf.
;                    the SPICE coverage routines will only work for frames and objects that are CK based (ie can change over time).
;                    each MAVEN object is described in the above weblink, saying whether it's ck based or not. All frames etc are hard
;                    coded here, so the user doesn't need to worry about this, but it's useful if you're using SPICE for other things.
;                
;
;OUTPUTS:
;success: 0: routine failed to make the checkes - it should throw an error if this happens.
;         1: checks completed.
;
;        
;tplot variables: mvn_lpw_anc_ck_flag: flag for s/c pointing for each timestep, 1 = no data, 0 = data present
;                 mvn_lpw_anc_spk_flag: flag for s/c position for each timestep, as above.
;
;OPTIONS:
;Set /loadspice to load the SPICE kernels using mvn_spice_kernels(/load). This will assume timespan is already set.
;   
;Set /clearspice to remove SPICE kernels from IDL memory once checking is complete. If not set, routine will leave them in IDL memory.
;
;
;EGS:
;time = dindgen(86400)+time_double('2014-12-08')  ;make a UNIX time array, or use get_data to grab a time array...
;timespan, '2014-12-08', 1.
;kk = mvn_spice_kernels(/load)   ;find SPICE kernels and load into IDL.
;mvn_sta_ck_check, time  
;                                         ;check ck and spk coverage, for MAVENs position in the MSO frame.
;                                         ;As of 2019-07-31, there is ~an hour of missing ck coverage for this date, if
;                                         ;you want to check the code is working.
;
;NOTES: 
;CMF worked out by hand how many MAVEN clock ticks represent one second: 65535.964843750000. This is hard coded below.
;2020-01-14: CMF: routine will crash if only 1 timestamp input. I need to fix this.
;
;VERSIONS:
;Created: 2019-08-01: Chris Fowler (cmfowler@berkeley.edu): code copied from mvn_lpw_anc_spacecraft.pro to be stand alone.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Generic/mvn_sta_ck_check.pro
;-
;

pro mvn_sta_ck_check, unix_in, success=success, loadspice=loadspice, clearspice=clearspice

sl = path_sep()  ;/ for unix, \ for Windows
cticks = 65535.964843750000d  ;This many MAVEN clock ticks represent 1s.

;Make sure unix_in is dblarr:
if size(unix_in, /type) ne 5 then begin
  print, "#######################"
  print, "WARNING: unix_in must be a double array of UNIX times."
  print, "#######################"
  success=0
  return
endif

if keyword_set(loadspice) then kk=mvn_spice_kernels(/load)

;==============================================
;---- Convert UNIX to correct time formats ----
;==============================================
et_time = time_ephemeris(unix_in, /ut2et)  ;convert unix to et

cspice_et2utc, et_time, 'ISOC', 6, utc_time  ;convert et to utc time  ### LSK file needed here ###

;Convert ET times to encoded sclk for use with cspice_ckgp later
cspice_sce2c, -202, et_time, enc_time

;CK check:
nele_in = n_elements(unix_in)
ck_check = fltarr(nele_in)   ;0 means no coverage, 1 means coverage
;objcheck = -202000  ;object pointing is requested for
;refcheck = 'MAVEN_SPACECRAFT'  ;frame in which pointing for objcheck is required for.

;Tolerance level must be set in sc clock ticks. Convert from a time in seconds to this using the code below:
if nele_in ge 2l then begin  ;find smallest dt in STATIC data
    dt_data1 = unix_in[1:*]-unix_in[0:*]  ;dt of input times
    iKP = where(dt_data1 gt 0.)
    dt_data2 = min(dt_data1[iKP],/nan)  ;find smallest dt that is >0.
endif else dt_data2 = 8.  ;if there's only 1 data point, use a default of 8s. (within 2 STATIC measurements)
tolval = (dt_data2 * cticks)*2.d  ;tolerance for number of clock ticks for finding stuff below
tolval = 0.d

;Cycle through each time step, and check the various kernels needed (from Boris Semenov):
for aa = 0, nele_in-1 do begin
  cspice_ckgp, -202000, enc_time[aa], tolval, 'MAVEN_MME_2000', mat1, clk1, found1
  cspice_ckgp, -202503, enc_time[aa], tolval, 'MAVEN_APP_BP', mat2, clk2, found2
  cspice_ckgp, -202505, enc_time[aa], tolval, 'MAVEN_APP_IG', mat3, clk3, found3

  if found1+found2+found3 eq 3 then ck_check[aa] = 1  ;0 = no coverage, 1 = coverage
endfor


if min(ck_check) eq 1 then ck_coverage = 'all' else begin
  ck_coverage = 'some'
  tmp = where(ck_check eq 0., nTMP)
  if nTMP gt 0. then print, "### WARNING ###: Pointing information (ck) not available for ", nTMP, " data point(s)."
endelse

ck_flag = 1. - ck_check  ;switch flagging; 0 = coverage is ok, 1 means flag - no coverage (this is opposite to above, but I'm retaining
                         ;this method to be consistent with mvn_lpw_anc_spacecraft outputs).

;Store flags into tplot:
dl_ck = create_struct('Type'  ,   'ck: STATIC pointing flags for associated unix times.'   , $
                      'Info'  ,   '0: coverage is present for this unix time. 1: flag: coverage is not present for this unix time.')

store_data, 'mvn_sta_ck_check', data={x:unix_in, y:ck_flag}, dlimit=dl_ck
ylim, 'mvn_sta_ck_check', -1, 2

success=1

if keyword_set(clearspice) then mvn_lpw_anc_clear_spice_kernels

end

