;+
;Give this routine an array of UNIX times; the routine uses SPICE to check whether there is ck and spk coverage for each timestamp.
;This function occurs in mvn-lpw-anc-spacecraft, but also occurs with several SPICE calculations. Only the ck/spk checking process
;is carried out here (which runs quicker), producing the same tplot variables as those in mvn-lpw-anc-spacecraft. 
;
;The variables produced will have value zero if kernels are present, or 1 if flagged as not present. For 1, SPICE cannot be used to
;get spacecraft position / pointing, depending on which kernel is missing (ck = pointing, spk = position).
;
;
;INPUTS:
;unix_in: UNIX double precision array of timetamps. The routine will check SPICE coverage at each timestep.
;
;
;objcheck: the NAIF object code to be checked for spk (position kernels). -202 is MAVEN, for eg. See 
;           https://lasp.colorado.edu/maven/sdc/public/data/anc/spice/fk/maven_v05.tf
;           for the full list of MAVEN codes.
; 
;ckcheck: the NAIF object code to be checked for ck (pointing) kernels. These have three additional integers added to the end
;         compared to objcheck. Eg, MAVEN is -202000.           
;           
;refcheck: the reference frame that objcheck should be checked in. Eg 'MAVEN_MSO'.
;
;   NOTES ON INPUTS: the SPICE coverage routines will only work for frames and objects that are CK based (ie can change over time).
;                    each MAVEN object is described in the above weblink, saying whether it's ck based or not. This routine may or may 
;                    not work for certain combinations of instruments and frames. CMF hasn't figured out whether this routine can be made 
;                    generic or not, however, it should work for MAVEN_SPACECRAFT and MAVEN_MSO.
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
;Set /loadspice to load the SPICE kernels found in 'mvn_lpw_load_kernel_files' to tplot memory. If not set, routine assumes they are already
;   loaded.
;   
;Set /unloadspice to remove SPICE kernels from IDL memory once checking is complete. If not set, routine will leave them in IDL memory.
;
;
;EGS:
;time = dindgen(86400)+time_double('2014-12-08')  ;make a UNIX time array, or use get_data to grab a time array...
;
;mvn_lpw_anc_get_spice_kernels, time, /notatlasp   ;find SPICE kernels and save into tplot variable 'mvn_lpw_load_kernel_files'
;mvn_lpw_anc_spacecraft, /only_load_spice    ;load SPICE kernels to IDL
;
;mvn_lpw_anc_ck_spk_check, time, ckcheck=-202000, objcheck=-202, refcheck='MAVEN_MSO'   
;                                                         ;check ck and spk coverage, for MAVENs position in the MSO frame.
;                                                         ;As of 2019-07-31, there is ~an hour of missing ck coverage for this date, if
;                                                         ;you want to check the code is working.
;
;NOTES: 
;CMF worked out by hand how many MAVEN clock ticks represent one second: 65535.964843750000. This is hard coded below.
;
;VERSIONS:
;Created: 2019-07-31: Chris Fowler (cmfowler@berkeley.edu): code copied from mvn_lpw_anc_spacecraft.pro to be stand alone.
;
;-
;

pro mvn_lpw_anc_ck_spk_check, unix_in, ckcheck=ckcheck, objcheck=objcheck, refcheck=refcheck, success=success, loadspice=loadspice, unloadspice=unloadspice

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

;Check we have objects and frames:
if size(objcheck,/type) eq 0 then begin
  print, ""
  print, "objcheck must be a NAIF ID code for the object you want to check."
  success=0
  return
endif

if size(refcheck,/type) eq 0 then begin
  print, ""
  print, "refcheck must be a string NAIF ID for the reference frame you want to check object in."
  success=0
  return
endif

;GET KERNEL NAMES:
get_data, 'mvn_lpw_load_kernel_files', data=data_kernels, dlimit=dl_kernels 

if size(dl_kernels,/type) ne 8 then begin
    print, ""
    print, "I couldn't find the tplot variable 'mvn_lpw_load_kernel_files'; run timespan and mvn_lpw_anc_get_spice_kernels to do this."
    success=0
    return
endif

nele_kernels = n_elements(dl_kernels.KERNEL_FILES)

;==================
;Check that we have spk and ck kernels loaded:
spk_p = 0  ;planets (MAVEN below)
ck = 0 ;pointing
fk = 0  ;frame info
lsk = 0  ;leapsecs
sclk = 0 ;MAVEN clock
for hh = 0, nele_kernels-1 do begin
  if stregex(dl_kernels.Kernel_files[hh], sl+'de[^bsp]*bsp', /boolean) eq 1 then spk_p += 1  ;add one to counter
  if stregex(dl_kernels.Kernel_files[hh], sl+'ck', /boolean) eq 1 then ck += 1
  if stregex(dl_kernels.Kernel_files[hh], 'maven_v[^tf]*tf', /boolean) eq 1 then fk += 1
  if stregex(dl_kernels.Kernel_files[hh], sl+'lsk', /boolean) eq 1 then lsk += 1
  if stregex(dl_kernels.Kernel_files[hh], sl+'sclk', /boolean) eq 1 then sclk += 1
endfor

;Do I need all of these checks, or just ck and spk kernels?
if (spk_p eq 0) then begin
  print, "#### WARNING ####: No planetary ephemeris kernel loaded: check for "+sl+"spk"+sl+"de???.bsp file."
  success=0
  return
endif
if (ck eq 0) then begin
  print, "#### WARNING ####: No pointing kernels loaded: check for "+sl+"ck"+sl+"... files."
  success=0
  return
endif
if (fk eq 0) then begin
  print, "#### WARNING ####: No frame kernels loaded: check for "+sl+"fk"+sl+"... files."
  success=0
  return
endif
if (lsk eq 0) then begin
  print, "#### WARNING ####: No leapsecond kernel loaded: check for "+sl+"lsk"+sl+"... files."
  success=0
  return
endif
if (sclk eq 0) then begin
  print, "#### WARNING ####: No spacecraft clock kernel loaded: check for "+sl+"sclk"+sl+"... files."
  success=0
  return
endif

;LOAD SPICE KERNELS:
if keyword_set(loadspice) then begin
    for aa = 0, nele_kernels-1 do cspice_furnsh, dl_kernels.Kernel_files[aa]  ;load all kernels
endif


;Get spk kernel names to feed into routine:
;Search for the spk kernel files, and feed them into here, as we need the names so the routine knows which ones to check:
;Look for 'MAVEN/kernels/spk/ in the names, as these are the MAVEN position kernels (be careful not to include planets for example)
kernels_to_check = ['']  ;empty array to fill in

for bb = 0, nele_kernels-1 do begin
  if stregex(dl_kernels.Kernel_files[bb], sl+'spk', /boolean) eq 1 then kernels_to_check = [kernels_to_check, dl_kernels.Kernel_files[bb]] ;add to list if an spk kernel
endfor  ;over bb
if n_elements(kernels_to_check) gt 1 then kernels_to_check = kernels_to_check[1:n_elements(kernels_to_check)-1] else begin  ;remove first '' from array
  print, "#### WARNING ####: No spk kernels loaded. Check these are loaded. Exiting."
  retall
endelse

;object=-202  ;-202 = MAVEN
spkcov = mvn_lpw_anc_covtest(unix_in, kernels_to_check, objcheck)  ;for now use unix times, may change to ET.   ### give spk kernel names here!
if min(spkcov) eq 1 then spk_coverage = 'all' else begin
  spk_coverage = 'some'
  tmp = where(spkcov eq 0, nTMP)
  if nTMP gt 0. then print, "### WARNING ###: Position (spk) information not available for ", nTMP, " data point(s)."
endelse
;spkcov is an array nele long. 1 means timestep is covered, 0 means timestep is outside of coverage.


;=============================
;---- Convert UNIX to UTC ----
;=============================
;Davin's routines all require UTC as input, use Berkeley routines here to convert from UNIX to UTC:

et_time = time_ephemeris(unix_in, /ut2et)  ;convert unix to et

cspice_et2utc, et_time, 'ISOC', 6, utc_time  ;convert et to utc time  ### LSK file needed here ###

;Convert ET times to encoded sclk for use with cspice_ckgp later
cspice_sce2c, -202, et_time, enc_time

;CK check:
nele_in = n_elements(unix_in)
ck_check = fltarr(nele_in)
;objcheck = -202000  ;object pointing is requested for
;refcheck = 'MAVEN_SPACECRAFT'  ;frame in which pointing for objcheck is required for.

;Tolerance level must be set in sc clock ticks. Convert from a time in seconds to this using the code below:
dt_data1 = unix_in[1:*]-unix_in[0:*]  ;dt of input times
iKP = where(dt_data1 gt 0.)
dt_data2 = min(dt_data1[iKP],/nan)  ;find smallest dt that is >0.
tolval = (dt_data2 * cticks)*2.d  ;tolerance for number of clock ticks for finding stuff below

for aa = 0, nele_in-1 do begin
  cspice_ckgp, ckcheck, enc_time[aa], tolval, refcheck, mat1, clk, found
  ck_check[aa] = found  ;0 if coverage exists, 1 if not
endfor
if min(ck_check) eq 1 then ck_coverage = 'all' else begin
  ck_coverage = 'some'
  tmp = where(ck_check eq 0., nTMP)
  if nTMP gt 0. then print, "### WARNING ###: Pointing information (ck) not available for ", nTMP, " data point(s)."
endelse

;Make a flag array for spk and ck coverage, where a zero means a time stamp is covered, and a 1 means it isn't. These will apply for all position and velocity
;variables. Attitude variables depend on encoded s/c clock, which is dealt with under sections 8 and 9 below.
;ck_check and spkcov are fltarrs, where a 1 means coverage, 0 means no coverage. The flag array produced next will be reversed; 0 means coverage (no flag), 1 means
;no coverage (flag).
ck_spk_flag = (ck_check ne 1) + (spkcov ne 1)  ;gives a zero when there is coverage, and a 1 with no coverage
ck_flag = ck_check ne 1
spk_flag  = spkcov ne 1

;Store flags into tplot:
dl_ck = create_struct('Type'  ,   'ck: MAVEN pointing flags for associated unix times.'   , $
  'Info'  ,   '0: coverage is present for this unix time. 1: flag: coverage is not present for this unix time.')
dl_spk = create_struct('Type'  ,   'spk: MAVEN position flags for associated unix times.'   , $
  'Info'  ,   '0: coverage is present for this unix time. 1: flag: coverage is not present for this unix time.')

store_data, 'mvn_lpw_anc_ck_flag', data={x:unix_in, y:ck_flag}, dlimit=dl_ck
ylim, 'mvn_lpw_anc_ck_flag', -1, 2
store_data, 'mvn_lpw_anc_spk_flag', data={x:unix_in, y:spk_flag}, dlimit=dl_spk
ylim, 'mvn_lpw_anc_spk_flag', -1 , 2

success=1

if keyword_set(unloadspice) then mvn_lpw_anc_clear_spice_kernels

end

