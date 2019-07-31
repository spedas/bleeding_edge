
;+
;pro mvn_lpw_anc_spacecraft, unix_in, not_quiet=not_quiet
;
;PROCEDURE:   mvn_lpw_anc_spacecraft
;PURPOSE:
; Routine to determine MAVEN pointing and position using the SPICE kernels.
; Routine determines angle between MAVEN x,y,z axes and the Sun.
; Routine gets MAVEN and Sun pointing directions in MAVEN spacecraft frame.
; SPICE is required to run this routine.
; Routine loads and unloads SPICE kernels for you.
; 
; TO RUN:
; mvn_lpw_anc_get_spice_kernels, time    ;find required SPICE kernels for the UNIX time array 'time'. Kernels are saved into a tplot variable
; mvn_lpw_anc_spacecraft, time      ;calcualte pointing etc, using kernels stored previously in tplot. 
;
;
;USAGE:
; mvn_lpw_cruciform, unix_in
;
;INPUTS:
;
;- unix_in: a dblarr of unix times for which attitude information is to be determined for. Routine will automatically check if pointing info
;           is available at each of these time steps, and skip the SPICE routines if not, to avoid crashes. Skipped points appear as nans in the
;           produced tplot variables.
;
;OUTPUTS:
;Tplot variables of the following:
;mvn_lpw_anc_ck_flag: flag for s/c position for each timestep, 1 = no data, 0 = data present
;
;mvn_lpw_anc_spk_flag: flag for s/c pointing for each timestep, as above.
;
;mvn_lpw_anc_mvn_att_mso: pointing vectors for MAVEN x,y,z axes in MSO frame. X,Y,Z vector for each MAVEN axis = 9 in total.
;
;mvn_lpw_anc_mvn_pos_mso: MAVEN position in MSO frame. X, Y, Z co-ords, in Rmars (Rmars = 3376.0d)
;
;mvn_lpw_anc_mvn_vel_mso MAVEN velocity in MSO frame. Vx, Vy, Vz co-ords, in km/s
;
;mvn_lpw_anc_mvn_pos_iau: MAVEN position in the IAU_MARS frame. X, Y, Z co-ords in Rmars.
;
;mvn_lpw_anc_mvn_att_J2000: Pointing for MAVEN x,y,z axes in J2000 frame. X, Y, Z vector for each MAVEN axis = 9 in total.
;
;mvn_lpw_anc_mvn_angles: Two entries: 1): Angular offset between MAVEN z axis and Sun look direction. 2) Clock angle between Sun and MAVEN X axis. Both in degrees.
;
;mvn_lpw_anc_mvn_abs_angle_z: Absolute angle between MAVEN z axis vector and Sun look direction vector, in degrees.
;
;mvn_lpw_anc_sun_pos_j2000: Sun position in J2000. X, Y, Z in km.
;
;mvn_lpw_anc_sun_pos_mvn: Sun position in the MAVEN s/c frame, in km. MAVEN is at the origin, with the usual s/c frame: Z is through the antenna, Y is along the Solar panels, X completes this.
;
;mvn_lpw_anc_mvn_pos_J2000: MAVEN position in J2000. X, Y, Z in km.
;
;mvn_lpw_anc_mvn_vel_J2000: MAVEN velocity in J2000, Vx, Vy, Vz in km/s.
;
;mvn_lpw_anc_mvn_vel_sc_mso: MAVEN velocity in the s/c frame, in km/s, based on the MSO frame. 3x1 vector: x,y,z in s/c frame. [0,0,1] for example means that the s/c is traveling antenna first (fly Z), in the MSO frame at Mars.
;
;mvn_lpw_anc_mvn_vel_sc_iau: MAVEN velocity in the s/c frame, in km/s, based on the IAU frame.
;
;mvn_lpw_anc_mvn_longlat_iau: array is [N,2]: top row is east longitude, bottom is latitude, both in degrees, in IAU frame. This is in the geodetic frame (Mars not a sphere).
;
;mvn_lpw_anc_mvn_alt_iau: MAVEN altitude from surface, in geodetic coords (IAU frame), in km.
;
;mvn_lpw_anc_mars_shadow: 1 if MAVEN is within the geometric shadow Mars; 0 if MAVEN is in sunlight.
;
;mvn_lpw_anc_mars_ls: Ls (solar longitude value) of Mars.
;
;With /css set:
;mvn_lpw_anc_css_pos_mso: CSS position, in MSO frame, Rmars.
;
;mvn_lpw_anc_css_pos_iau: CSS position, in IAU frame, Rmars.
;
;With /moons set:
;mvn_lpw_anc_pho_pos_mso: Phobos position in MSO frame, Rmars.
;
;mvn_lpw_anc_dei_pos_mso: Deimos positions in MSO frame, Rmars.
;
;mvn_lpw_anc_pho_pos_iau: Phobos position in IAU frame, Rmars.
;
;mvn_lpw_anc_dei_pos_iau: Deimos positions in IAU frame, Rmars.
;
;mvn_lpw_anc_phobos_pos_mvn  :Phobos position in MAVEN s/c frame, in km
;
;mvn_lpw_anc_deimos_pos_mvn  :Deimos position in MAVEN s/c frame, in km
;
;mvn_lpw_anc_mvn_pos_pho    :MAVEN position in the Phobos IAU frame, in Rmars.
;
;
;KEYWORDS:
;Setting /not_quiet will plot mvn_abs_angles_z and the offset between MAVEN z axis and the Sun (used more for checking the routine worked).
;
;Setting /moons will get the positions of the moons Phobos and Deimos in MSO, IAU and MAVEN s/c frames.
;
;Setting /css will get position information of Comet Siding Spring in MSO and IAU frames.
;
;Set /basic to only calculate MAVEN position and velocity in both the MSO and IAU frames, and altitude in the IAU frame. This helps speed up the routine.
;       Mars Ls (Solar longitude) value is also calculated.
;
;Setting /dont_load will skip loading SPICE kernels into IDL memory. Set this if they are already loaded. Default if not set is to load SPICE kernels.
;
;Setting /dont_unload will keep SPICE kernels stored in IDL memory. Default is to clear them after running through.
;
;Setting /only_load_spice will load the SPICE kernels in the tplot variable 'mvn_lpw_load_kernel_files' into IDL memory, and then quit
;       without performing any other calculations.
;
;NOTE: even though kernel_dir is a key word it must still be set. See inputs above.
;
;
;
;CREATED BY:   Chris Fowler April 16th 2014
;FILE:
;VERSION:   2.1
;LAST MODIFICATION:
;April 17th 2014 CF added kernel_dir to inputs, outputs now saved as tplot variables. TO DO: add dlimit and limit fields to tplot variables.
;April 23rd 2014 CF added a check to make sure we have ck kernel pointing before trying to get the rotation matrix, to avoid crashes. Also added
;                   et_time as an input, which is needed for use with SPICE routines.
;April 24th 2014 CF added mvn_lpw_pos_J2000, mvn_lpw_vel_J2000
;April 28/29th 2014 CF added checks to make sure there is ck and spk info before running spice. This avoids crashes. Kernels now automatically loaded
;                      from the SPICE wrapper.
;May 16th 2014 CF: Switched to Davin's routines which call upon SPICE. Mine are commented out here. Fixed bug so routine will check for spk and ck
;                  coverage before attmepting to use SPICE, which causes it to crash if no coverage is present.
;140718 clean up for check out L. Andersson
;140730 CF: added in routines to obtain shadow % on the booms based on Sun position in s/c frame. Added in new tplot variable, Sun position wrt MAVEN s/c frame.
;140826: CF: shadow and wake information removed from this routine and is now calculated in mvn_lpw_anc_boom.pro. This routine must be run first to create
;            the necessary tplot variables.
;141006: CF: update dlimits for ISTP compliance.
;141031: CF: added keyword /moons, so get position of Phobos and Deimos in MSO and IAU co-ords.
;150309: CF: added SPICE routines to get long, lat, and correct altitude based on geodetic co-ords. Also added Phobos and Deimos code as written by Brian Templeman.
;2017-03-23: CMF: longlat calculation was incorrect (wrong frame). Corrected, longlat now in the IAU_MARS frame, as described above.
;2019-07-30: CMF: tried to modify dont_load keyword so that this routine won't check for the tplot variable 'mvn_lpw_load_kernel_files', 
;                 but there's a bunch of later code that depends on this. For now, this tplot variable needs to be loaded for the routine
;                 to work.
;-
;=================

pro mvn_lpw_anc_spacecraft, unix_in, not_quiet=not_quiet, moons=moons, css=css, dont_load=dont_load, dont_unload=dont_unload, basic=basic, $
                                only_load_spice=only_load_spice

t_routine = SYSTIME(0)

;Load kernels:
scid = -202  ;MAVEN s/c ID for SPICE
kernel_version = 'anc_spacecraft V2.0'   ;needed for dlimits, add loaded kernels to it

if keyword_set(basic) then basic = '1' else basic = '0'  ;reset keyword as it's quicker to check a value than if a keyword is set.

;======================
;---Kernel directory---
;======================
;The default will be to use the directory as set up by Davin's routines. As this will probably be on the server, there will also be an option
;to work offline.
;======================
sl = path_sep()  ;/ for unix, \ for Windows
;Code for automatically loading found kernels:
;Get kernel info from tplot variables and load:
tplotnames = tnames()  ;list of tplot variables in memory
        if total(strmatch(tplotnames, 'mvn_lpw_load_kernel_files')) eq 1 then begin  ;found kernel tplot variable
            get_data, 'mvn_lpw_load_kernel_files', data=data_kernels, dlimit=dl_kernels  ;dl.kernels contains the kernel names
            nele_kernels = n_elements(dl_kernels.Kernel_files)  ;number of kernels to load
            loaded_kernels_arr=strarr(nele_kernels)  ;string array
            loaded_kernels='';dummy string
            for aa = 0, nele_kernels-1 do begin
                if not keyword_set(dont_load) then cspice_furnsh, dl_kernels.Kernel_files[aa]  ;load all kernels for now
        
                ;Extract just kernel name and remove directory:
                nind = strpos(dl_kernels.Kernel_files[aa], sl, /reverse_search)  ;nind is the indice of the last '/' in the directory before the kernel name
                lenstr = strlen(dl_kernels.Kernel_files[aa])  ;length of the string directory
                kname = strmid(dl_kernels.Kernel_files[aa], nind+1, lenstr-nind)  ;extract just the kernel name
                loaded_kernels_arr[aa] = kname  ;copy kernels as a string
                loaded_kernels = loaded_kernels + " # " + kname  ;one long string so can save into dlimit
                kernel_version = kernel_version + " # " + kname  ;add loaded kernel to dlimit field
            endfor  ;over aa
        endif else begin
                print, "####################"
                print, "WARNING: No SPICE kernels found which match this data set.
                print, "Check there are kernels available online for this data.
                print, "If they are present, check the kernel finder to see if it's finding them."
                print, "Did you ask IDL to not use SPICE?"
                print, "####################"
                retall
        endelse
  
if keyword_set(only_load_spice) then return
 
;Make sure unix_in is dblarr:
if size(unix_in, /type) ne 5 then begin
  print, "#######################"
  print, "WARNING: unix_in must be a double array of UNIX times."
  print, "#######################"
  retall
endif
 
;==================
;Check that we have spk (planet), ck, lsk, fk, sclk kernels loaded for attitude information:
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

if (spk_p eq 0) then begin
    print, "#### WARNING ####: No planetary ephemeris kernel loaded: check for "+sl+"spk"+sl+"de???.bsp file."
    retall
endif
if (ck eq 0) then begin
    print, "#### WARNING ####: No pointing kernels loaded: check for "+sl+"ck"+sl+"... files."
    retall
endif
if (fk eq 0) then begin
    print, "#### WARNING ####: No frame kernels loaded: check for "+sl+"fk"+sl+"... files."
    retall
endif
if (lsk eq 0) then begin
    print, "#### WARNING ####: No leapsecond kernel loaded: check for "+sl+"lsk"+sl+"... files."
    retall
endif
if (sclk eq 0) then begin
    print, "#### WARNING ####: No spacecraft clock kernel loaded: check for "+sl+"sclk"+sl+"... files."
    retall
endif
;MAVEN spk position kernels are checked for below.
;==================
;Check whether the times fall within kernel coverage for the SPK files:

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

spkcov = mvn_lpw_anc_covtest(unix_in, kernels_to_check, -202)  ;for now use unix times, may change to ET.   ### give spk kernel names here!
if min(spkcov) eq 1 then spk_coverage = 'all' else begin
    spk_coverage = 'some'
    tmp = where(spkcov eq 0, nTMP)
    if nTMP gt 0. then print, "### WARNING ###: Position (spk) information not available for ", nTMP, " data point(s)."   
endelse
;spkcov is an array nele long. 1 means timestep is covered, 0 means timestep is outside of coverage.

;There is a ck check later on, it requires encoded time so is below:

;=======================
;---Checking complete---
;=======================

;Get dlimit and limit info from a tplot variable:
;tnames() is a string array containing the names of all tplot variables in memory. Check this exists, then grab dlimit and limit info
;from the first variable. This means we don't need to feed in instrument constants. The attitude variable specific fields will be edited
;as that variable is stored.
tplotnames = tnames()
;If there are no tplot variables stored then tplotnames is the string ''. If there are tplot variables stored tplotnames is either 'tplotname' or
;a string array of tplot names. We may have other tplot variables loaded, find those which are lpw ones:
if tplotnames[0] ne '' and n_elements(tplotnames) gt 2 then begin  ;if we have tplot variables
    wheret = where(strmatch(tplotnames, '*mvn_lpw_*') eq 1 and (tplotnames ne 'mvn_lpw_load_kernel_files') and (tplotnames ne 'mvn_lpw_load_file'), nwheret)  ;look for where we have lpw variables

    if nwheret ge 1 then begin  ;the first two lpw variables are usually the L0 load file and SPICE kernels which don't have the ISTP info
        get_data, tplotnames[wheret[0]], dlimit=dl, limit=ll  ;doesn't matter which variable for now, we just want the CDF fields from this which are identical
                                                      ;for all variables. But, we don't want kernel information as this doesn't contain those fields.
        def = 'ISTP information not available.'
        cdf_istp = strarr(15)  ;copy across the fields from dlimit:
        if tag_exist(dl, 'Source_name') then cdf_istp[0] = dl.Source_name else cdf_istp[0] = def
        if tag_exist(dl, 'Discipline') then cdf_istp[1] = dl.Discipline else cdf_istp[1] = def
        if tag_exist(dl, 'Instrument_type') then cdf_istp[2] = dl.Instrument_type else cdf_istp[2] = def
        if tag_exist(dl, 'Support_data') then cdf_istp[3] = 'Support_data' else cdf_istp[3] = def  ;dl.Data_type
        if tag_exist(dl, 'Data_version') then cdf_istp[4] = dl.Data_version else cdf_istp[4] = def
        if tag_exist(dl, 'Descriptor') then cdf_istp[5] = dl.Descriptor else cdf_istp[5] = def
        if tag_exist(dl, 'PI_name') then cdf_istp[6] = dl.PI_name else cdf_istp[6] = def
        if tag_exist(dl, 'PI_affiliation') then cdf_istp[7] = dl.PI_affiliation else cdf_istp[7] = def
        if tag_exist(dl, 'TEXT') then cdf_istp[8] = dl.TEXT else cdf_istp[8] = def
        if tag_exist(dl, 'Mission_group') then cdf_istp[9] = dl.Mission_group else cdf_istp[9] = def
        if tag_exist(dl, 'Generated_by') then cdf_istp[10] = dl.Generated_by else cdf_istp[10] = def
        if tag_exist(dl, 'Generation_data') then cdf_istp[11] = dl.Generation_date else cdf_istp[11] = def
        if tag_exist(dl, 'Rules_of_use') then cdf_istp[12] = dl.Rules_of_use else cdf_istp[12] = def
        if tag_exist(dl, 'Acknowledgement') then cdf_istp[13] = dl.Acknowledgement else cdf_istp[13] = def
        if tag_exist(dl, 't_epoch') then t_epoch = dl.t_epoch else t_epoch=-999.
        if tag_exist(dl, 'L0_datafile') then L0_datafile = dl.L0_datafile else L0_datafile='NA'
    endif else begin
      cdf_istp = strarr(15) + 'ISTP information unavailable'
      t_epoch = 'ISTP information unavailable'
      L0_datafile = 'ISTP information unavailable'
    endelse
endif else begin
    print, "################"
    print, "WARNING: Some tplot dlimit fields may be missing. Check at least one tplot variable"
    print, "is in IDL memory before running mvn_lpw_spacecraft."
    print, "################"
    ;Create a dummy array containing blank strings so routine won't crash later:
    cdf_istp = strarr(15) + 'ISTP information unavailable'
    t_epoch = 'dlimit info unavailable'
    L0_datafile = 'dlimit info unavailable'
endelse

;==================
;Convert UNIX times in to et for use with SPICE:
nele = n_elements(unix_in)  ;number of times entered

print, "Determining MAVEN pointing for ", nele, " data points..."

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
for aa = 0, nele_in-1 do begin
    cspice_ckgp, -202000, enc_time[aa], 0.0, 'MAVEN_SPACECRAFT', mat1, clk, found
    ck_check[aa] = found  ;0 if coverage exists, 1 if not
endfor
if min(ck_check) eq 1 then ck_coverage = 'all' else begin
    ck_coverage = 'some'
    tmp = where(ck_check eq 0., nTMP)
    if nTMP gt 0. then print, "### WARNING ###: Pointing information (ck) not available for ", nTMP, " data point(s)."
endelse
    ;tick_time =strarr(nele)
    ;for aa = 0, nele-1 do begin   ;to test if we get back the sclk string, which we do
    ;    cspice_sce2s, -202, et_time[aa], tick_t
    ;    tick_time[aa] = tick_t
    ;endfor

;============
;Get standard information for other dlimit fields:
;Break up UTC time in a dbl number, just first and last times:
   aa= strsplit(utc_time[0],'T',/extract)  ;first time
   bb= strsplit(aa[0],'-',/extract)
   cc= strsplit(aa[1],':',/extract)
   utc_time1 =10000000000.0 * double( bb[0]) + 100000000.0 * double(bb[1]) + 1000000.0 * double(bb[2]) + 10000.0 *double(cc[0]) + 100.0 * double(cc[1]) +double(cc[2])
   aa= strsplit(utc_time[nele-1],'T',/extract)  ;last time
   bb= strsplit(aa[0],'-',/extract)
   cc= strsplit(aa[1],':',/extract)
   utc_time2 =10000000000.0 * double( bb[0]) + 100000000.0 * double(bb[1]) + 1000000.0 * double(bb[2]) + 10000.0 *double(cc[0]) + 100.0 * double(cc[1]) +double(cc[2])

;Check these times are predicted or reconstructed:
time_check = mvn_lpw_anc_spice_time_check(et_time[nele-1])  ;we check the last time. If this is predicted, we must run entire orbit later. ## fix this routine


time_start = [unix_in[0], utc_time1, et_time[0]]
time_end = [unix_in[nele-1], utc_time2, et_time[nele-1]]
time_field = ['UNIX time', 'UTC time', 'ET time']
spice_used = 'SPICE used'
str_xtitle = 'Time (UNIX)'+time_check   ;### predicted or reconstructed?
today_date = systime(0)
;===========

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

;########
;Now et_time and utc_time contain the time steps of input data points, which can be used with Davins SPICE routines.
;########
;Now get MAVEN attitude / orientation info here

mvn_x = [1.d, 0.d, 0.d]  ;look directions for MAVEN s/c
mvn_y = [0.d, 1.d, 0.d]
mvn_z = [0.d, 0.d, 1.d]

;=====
;==1==
;=====
if basic eq '0' then begin
;Absolute angle between Sun and MAVEN
;Get Sun position relative to MAVEN in s/c frame:
;Information needed:
target = 'Sun'
frame    = 'MAVEN_SPACECRAFT'
abcorr   = 'LT+S'  ;correct for light travel time and something
observer = 'MAVEN'

if (spk_coverage eq 'all') and (ck_coverage eq 'all') then state = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin
;if spk_coverage eq 'all' then cspice_spkpos, target, et_time, frame, abcorr, observer, state, ltime else begin ;state contains R and V [0:5], ltime = light time between observer and object
    state = dblarr(3,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
    for aa = 0, nele-1 do begin  ;do each time point individually
          if (spkcov[aa] eq 1) and (ck_check[aa] eq 1) then state_temp = spice_body_pos(target, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr) else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if spkcov[aa] eq 1 then cspice_spkpos, target, et_time[aa], frame, abcorr, observer, state_temp, ltime else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if we don't have coverage, use nans instead
          state[0,aa] = state_temp[0]  ;add time step to overall array
          state[1,aa] = state_temp[1]
          state[2,aa] = state_temp[2]
    endfor
endelse

;state = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr)  ;Suns position, from MAVEN, in S/C frame

;Extract Sun position, in s/c frame:
pos_s = dblarr(nele,3)
pos_s[*,0] = state[0,*]  ;positions in km
pos_s[*,1] = state[1,*]
pos_s[*,2] = state[2,*]

;Store as tplot variable:
;--------------- dlimit   ------------------
dlimit=create_struct(   $
  'Product_name',                  'mvn_lpw_anc_sun_pos_mvn', $
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
  'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
  'y_catdesc',                     'Sun position, in MAVEN frame.', $
  ;'v_catdesc',                     'test dlimit file, v', $    ;###
  'dy_catdesc',                    'Error on the data.', $     ;###
  ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
  'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
  'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
  'y_Var_notes',                   'Units of km', $
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
  'SCALEMIN', min(pos_s), $
  'SCALEMAX', max(pos_s), $        ;..end of required for cdf production.
  't_epoch'         ,     t_epoch, $
  'Time_start'      ,     time_start, $
  'Time_end'        ,     time_end, $
  'Time_field'      ,     time_field, $
  'SPICE_kernel_version', kernel_version, $
  'SPICE_kernel_flag'      ,     spice_used, $
  'L0_datafile'     ,     L0_datafile , $
  'cal_vers'        ,     kernel_version ,$
  'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
  ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
  ;'cal_datafile'    ,     'No calibration file used' , $
  'cal_source'      ,     'SPICE kernels', $
  'xsubtitle'       ,     '[sec]', $
  'ysubtitle'       ,     '[km]');, $
;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
;'zsubtitle'       ,     '[Attitude]')
;-------------  limit ----------------
limit=create_struct(   $
  'char_size' ,     1.2                      ,$
  'xtitle' ,        str_xtitle                   ,$
  'ytitle' ,        'Sun position (s/c frame)'                 ,$
  'yrange' ,        [min(pos_s),max(pos_s)] ,$
  'ystyle'  ,       1.                       ,$
  'labflag',        1, $
  'labels',         ['MVN X', 'MVN Y', 'MVN Z'], $
  ;'ztitle' ,        'Z-title'                ,$
  ;'zrange' ,        [min(data.y),max(data.y)],$
  ;'spec'            ,     1, $
  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
  'noerrorbars', 1)
;---------------------------------
store_data, 'mvn_lpw_anc_sun_pos_mvn', data={x:unix_in, y:pos_s, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
;---------------------------------


;Divide Sun's position by it's magnitude to get it as a look vector from MAVEN:
sun_mag = dblarr(nele)
vector_sun = dblarr(nele,3)
mvn_abs_angles_z = dblarr(nele)   ;store absolute angle between Sun and MAVEN z axis.
;Get absolute angle between pointing vectors for MAVEN z axis (EUV boresight) (although this may not be useful)
;cos(theta) = a-dot-b / mag(a) * mag(b)
mag_sun = 1.D  ;look vector therefore mag is one, as obtained above
mag_mvnz = 1.D  ;by definition this is one.
for aa = 0L, nele -1 do begin
    sun_mag[aa] = sqrt(pos_s[aa,0]^2 + pos_s[aa,1]^2 + pos_s[aa,2]^2)  ;magnitude for each time
    vector_sun[aa,*] = pos_s[aa,*] / sun_mag[aa]  ;divide position vector by magnitude to get look vector (total mag = 1)

    mvn_abs_angles_z[aa] = acos((mvn_z[0]*vector_sun[aa,0] + mvn_z[1]*vector_sun[aa,1] + mvn_z[2]*vector_sun[aa,2]) / (mag_sun * mag_mvnz)) * (180.D/!pi)   ;in degrees
endfor

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $
                   'Product_name',                  'mvn_lpw_anc_abs_angle_z', $
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
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'Absolute angle between MAVEN Z axis vector and Sun position vector, in MAVEN s/c frame.', $
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Units of degrees. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.' , $
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
                   'SCALEMIN', min(mvn_abs_angles_z), $
                   'SCALEMAX', max(mvn_abs_angles_z), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $
                   'L0_datafile'     ,     L0_datafile , $
                   'cal_vers'        ,     kernel_version ,$
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $
                   'xsubtitle'       ,     '[sec]', $
                   'ysubtitle'       ,     '[Degrees]');, $
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')
                ;-------------  limit ----------------
                limit=create_struct(   $
                  'char_size' ,     1.2                      ,$
                  'xtitle' ,        str_xtitle                   ,$
                  'ytitle' ,        'mvn-abs_angles-z'                 ,$
                  'yrange' ,        [0.9*min(mvn_abs_angles_z),1.1*max(mvn_abs_angles_z)] ,$
                  'ystyle'  ,       1.                       ,$
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$
                  ;'zrange' ,        [min(data.y),max(data.y)],$
                  ;'spec'            ,     1, $
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
               ;---------------------------------
               store_data, 'mvn_lpw_anc_mvn_abs_angle_z', data={x:unix_in, y:mvn_abs_angles_z, flag:ck_spk_flag}, dlimit=dlimit, limit=limit

;=====
;==2==
;=====
offset = dblarr(nele,2)  ;store x,y offsets
;Get offset between MAVEN z axis and Sun, and clock angle from MAVEN X axis, in degrees:
mvn_angles = dblarr(nele,2)  ;array to store angles, first row is radius, second is angle from x axis, counter clockwise

;Plot x and y distances from Sun vector to check the pointing routines are working - should get a cross for the cruciform!
;Define the sun vector as the center:
for aa = 0L, nele-1 do begin
    center = [vector_sun[aa,0], vector_sun[aa,1]]  ;make Sun vector the 'zero' position for this time step
    mvn_point_z = [mvn_z[0], mvn_z[1]]  ;x,y pointing for z axis on MAVEN
    offset[aa,*] = [[mvn_point_z[0] - center[0]], [mvn_point_z[1] - center[1]]]  ;get offset

    ;As co-ordinates are projected onto a 2D screen, we can get "radius angle" and angle from s/c x axis for the Sun vector.
    mvn_angles[aa,0] = acos(vector_sun[aa,2]) * (180.D/!pi)  ;in degrees. Use Sun z vector to get "radius displacement angle". If sun(z) = 1, this equals
                                                                 ;s/c z (also 1), so acos(1) = 0 degrees, which is correct!
    mvn_angles[aa,1] = atan(vector_sun[aa,1], vector_sun[aa,0]) * (180.D/!pi)  ;degrees, tan(y/x) to get angle from s/c x axis.
endfor  ;over aa

ydata = dblarr(nele,2)
ydata[*,0] = mvn_angles[*,0]
ydata[*,1] = mvn_angles[*,1]
                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $
                   'Product_name',                  'mvn_lpw_anc_mvn_angles', $
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
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'First row: angle between MAVEN Z axis and Sun position in MAVEN s/c frame. Second row: clock angle between Sun angle and MAVEN +X axis, in MAVEN s/c frame.', $
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Units of degrees. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.' , $
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
                   'SCALEMIN', min(mvn_angles), $
                   'SCALEMAX', max(mvn_angles), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $
                   'L0_datafile'     ,     L0_datafile , $
                   'cal_vers'        ,     kernel_version ,$
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $
                   'xsubtitle'       ,     '[sec]', $
                   'ysubtitle'       ,     '[Degrees]');, $
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')
                ;-------------  limit ----------------
                limit=create_struct(   $
                  'char_size' ,     1.2                      ,$
                  'xtitle' ,        str_xtitle                   ,$
                  'ytitle' ,        'mvn-angles'                 ,$
                  'yrange' ,        [1.1*min(mvn_angles),1.1*max(mvn_angles)] ,$
                  'ystyle'  ,       1.                       ,$
                  'labels',         ['Angular_separation', 'Clock_angle'], $
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$
                  ;'zrange' ,        [min(data.y),max(data.y)],$
                  ;'spec'            ,     1, $
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
               ;---------------------------------
               store_data, 'mvn_lpw_anc_mvn_angles', data={x:unix_in, y:ydata, flag:ck_spk_flag}, dlimit=dlimit, limit=limit

;=====
;==3==
;=====
;Get Sun position in J2000 (Earth centered):
target = 'Sun'
frame    = 'J2000'
abcorr   = 'LT+S'  ;correct for light travel time and something
observer = 'MAVEN'

;cspice_spkpos, target, et_time, frame, abcorr, observer, state_j, ltime_j  ;state contains R and V [0:5], ltime = light time between observer and object

if (spk_coverage eq 'all') then state_j = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin
;if spk_coverage eq 'all' then cspice_spkezr, target, et_time, frame, abcorr, observer, state_j, ltime else begin ;state contains R and V [0:5],
    state_j = dblarr(3,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
    for aa = 0, nele-1 do begin  ;do each time point individually
          if (spkcov[aa] eq 1) then state_temp = spice_body_pos(target, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr) else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if spkcov[aa] eq 1 then cspice_spkpos, target, et_time[aa], frame, abcorr, observer, state_temp, ltime else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if we don't have coverage, use nans instead
          state_j[0,aa] = state_temp[0]  ;add time step to overall array
          state_j[1,aa] = state_temp[1]
          state_j[2,aa] = state_temp[2]
    endfor
endelse

;Extract Sun position and velocities in J2000:
sun_pos_j2000 = dblarr(nele,3)
sun_pos_j2000[*,0] = state_j[0,*]  ;in km
sun_pos_j2000[*,1] = state_j[1,*]
sun_pos_j2000[*,2] = state_j[2,*]

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $
                   'Product_name',                  'mvn_lpw_anc_sun_pos_j2000', $
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
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'Sun position, in the Earth mean equator and equinox of J2000 frame (J2000) frame.', $
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Units of km. J2000 frame: Origin is center of Earth. X-Y plane defined as Earths mean equator on 2000-01-01. X points to vernal equinox on 2000-01-01. Z completes system (celestial north).' , $
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
                   'SCALEMIN', min(sun_pos_j2000), $
                   'SCALEMAX', max(sun_pos_j2000), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $
                   'L0_datafile'     ,     L0_datafile , $
                   'cal_vers'        ,     kernel_version ,$
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $
                   'xsubtitle'       ,     '[sec]', $
                   'ysubtitle'       ,     '[km (J2000 frame)]');, $
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')
                ;-------------  limit ----------------
                limit=create_struct(   $
                  'char_size' ,     1.2                      ,$
                  'xtitle' ,        str_xtitle                   ,$
                  'ytitle' ,        'Sun-position'                 ,$
                  'yrange' ,        [0.9*min(sun_pos_J2000),1.1*max(sun_pos_j2000)] ,$
                  'ystyle'  ,       1.                       ,$
                  'labels',         ['X', 'Y', 'Z'], $
                  'colors',         [2, 4, 6], $  ;blue, green, red
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$
                  ;'zrange' ,        [min(data.y),max(data.y)],$
                  ;'spec'            ,     1, $
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
               ;---------------------------------
               store_data, 'mvn_lpw_anc_sun_pos_j2000', data={x:unix_in, y:sun_pos_j2000, flag:spk_flag}, dlimit=dlimit, limit=limit

;========
;==4, 5==
;========
;MAVEN position J2000:
;Position:
target = 'MAVEN'
frame    = 'J2000'
abcorr   = 'LT+S'  ;correct for light travel time and something
observer = 'Sun'

;if (spk_coverage eq 'all') and (ck_coverage eq 'all') then state = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin  ;DAVINS ROUTINE
if (spk_coverage eq 'all') then cspice_spkezr, target, et_time, frame, abcorr, observer, state, ltime else begin ;state contains R and V [0:5], USE THIS UNTIL DAVIN ADDS VEL INTO HIS ABOVE
    state = dblarr(6,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
    for aa = 0, nele-1 do begin  ;do each time point individually
          if (spkcov[aa] eq 1) then cspice_spkezr, target, et_time[aa], frame, abcorr, observer, state_temp, ltime else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]
          ;if we don't have coverage, use nans instead
          state[0,aa] = state_temp[0]  ;add time step to overall array
          state[1,aa] = state_temp[1]
          state[2,aa] = state_temp[2]
          state[3,aa] = state_temp[3]   ;added to include velocity
          state[4,aa] = state_temp[4]
          state[5,aa] = state_temp[5]
    endfor
endelse

;cspice_spkezr, target, et_time, frame, abcorr, observer, state, ltime  ;state contains R and V [0:5], ltime = light time between observer and object

mvn_pos_j2000 = dblarr(nele,3)
mvn_vel_j2000 = dblarr(nele,3)
mvn_pos_j2000[*,0] = state[0,*]  ;positions in km
mvn_pos_j2000[*,1] = state[1,*]  ;positions in km
mvn_pos_j2000[*,2] = state[2,*]  ;positions in km
mvn_vel_j2000[*,0] = state[3,*]  ;velocities in km
mvn_vel_j2000[*,1] = state[4,*]  ;velocities in km
mvn_vel_j2000[*,2] = state[5,*]  ;velocities in km

;mvn_pos_au = mvn_pos_mso / (1.496D8)   ;position in AU

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $
                   'Product_name',                  'mvn_lpw_anc_mvn_pos_j2000', $
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
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'MAVEN position, in the Earth mean equator and equinox of J2000 frame (J2000) frame.', $
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Units of km. J2000 frame: Origin is center of Earth. X-Y plane defined as Earths mean equator on 2000-01-01. X points to vernal equinox on 2000-01-01. Z completes system (celestial north).' , $
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
                   'SCALEMIN', min(mvn_pos_j2000), $
                   'SCALEMAX', max(mvn_pos_j2000), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $
                   'L0_datafile'     ,     L0_datafile , $
                   'cal_vers'        ,     kernel_version ,$
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $
                   'xsubtitle'       ,     '[sec]', $
                   'ysubtitle'       ,     '[km (J2000 frame)]');, $
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')
                ;-------------  limit ----------------
                limit=create_struct(   $
                  'char_size' ,     1.2                      ,$
                  'xtitle' ,        str_xtitle                   ,$
                  'ytitle' ,        'mvn-position'                 ,$
                  'yrange' ,        [min(mvn_pos_j2000),max(mvn_pos_j2000)] ,$
                  'ystyle'  ,       1.                       ,$
                  'labels',         ['X', 'Y', 'Z'], $
                  'colors',         [2, 4, 6], $  ;blue, green, red
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$
                  ;'zrange' ,        [min(data.y),max(data.y)],$
                  ;'spec'            ,     1, $
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
               ;---------------------------------
               store_data, 'mvn_lpw_anc_mvn_pos_j2000', data={x:unix_in, y:mvn_pos_j2000, flag:spk_flag}, dlimit=dlimit, limit=limit
               ;---------------------------------

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $
                   'Product_name',                  'mvn_lpw_anc_mvn_vel_j2000', $
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
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'MAVEN velocity, in the Earth mean equator and equinox of J2000 frame (J2000) frame.', $
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Units of km/s. J2000 frame: Origin is center of Earth. X-Y plane defined as Earths mean equator on 2000-01-01. X points to vernal equinox on 2000-01-01. Z completes system (celestial north).' , $
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
                   'SCALEMIN', min(mvn_vel_j2000), $
                   'SCALEMAX', max(mvn_vel_j2000), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $
                   'L0_datafile'     ,     L0_datafile , $
                   'cal_vers'        ,     kernel_version ,$
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $
                   'xsubtitle'       ,     '[sec]', $
                   'ysubtitle'       ,     '[km/s (J2000 frame)]');, $
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')
                ;-------------  limit ----------------
                limit=create_struct(   $
                  'char_size' ,     1.2                      ,$
                  'xtitle' ,        str_xtitle                   ,$
                  'ytitle' ,        'mvn-velocity'                 ,$
                  'yrange' ,        [min(mvn_vel_j2000),max(mvn_vel_j2000)] ,$
                  'ystyle'  ,       1.                       ,$
                  'labels',         ['Vx', 'Vy', 'Vz'], $
                  'labflag',        1, $
                  'colors',         [2, 4, 6], $  ;blue, green, red
                  ;'ztitle' ,        'Z-title'                ,$
                  ;'zrange' ,        [min(data.y),max(data.y)],$
                  ;'spec'            ,     1, $
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
               ;---------------------------------
               store_data, 'mvn_lpw_anc_mvn_vel_j2000', data={x:unix_in, y:mvn_vel_j2000, flag:spk_flag}, dlimit=dlimit, limit=limit
               ;---------------------------------

endif  ;basic eq '0'

;========
;==6, 7==
;========
;MAVEN position and velocity in MSO and IAU frames:
;General info:
frame    = 'MAVEN_MSO'
frame2   = 'IAU_MARS'
abcorr   = 'LT+S'
observer = 'Mars'
target = 'MAVEN'

;if (spk_coverage eq 'all') and (ck_coverage eq 'all') then stateezr = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin  ;DAVINS ROUTINE
if (spk_coverage eq 'all') then begin  ;and (ck_coverage eq 'all') then begin
  cspice_spkezr, target, et_time, frame, abcorr, observer, stateezr, ltime ;state contains R and V [0:5], USE FOR NOW UNTIL DAVIN ADDS VEL TO HIS ABOVE
  cspice_spkezr, target, et_time, frame2, abcorr, observer, stateezr2, ltime  ;contains R and V in the IAU_MARS frame
endif else begin
    stateezr = dblarr(6,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
    stateezr2 = dblarr(6,nele)
    for aa = 0, nele-1 do begin  ;do each time point individually
          ;if (spkcov[aa] eq 1) and (ck_check[aa] eq 1) then state_temp = spice_body_pos(target, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr) else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]  ;DAVINS
          if (spkcov[aa] eq 1) then cspice_spkezr, target, et_time[aa], frame, abcorr, observer, state_temp, ltime else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]  ;USE THIS FOR NOW UNTIL DAVINS HAS VEL
          if (spkcov[aa] eq 1) then cspice_spkezr, target, et_time[aa], frame2, abcorr, observer, state_temp2, ltime else state_temp2=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]  ;USE THIS FOR NOW UNTIL DAVINS HAS VEL

          ;if we don't have coverage, use nans instead
          stateezr[0,aa] = state_temp[0]  ;add time step to overall array
          stateezr[1,aa] = state_temp[1]
          stateezr[2,aa] = state_temp[2]
          stateezr[3,aa] = state_temp[3]  ;vel
          stateezr[4,aa] = state_temp[4]
          stateezr[5,aa] = state_temp[5]
          ;if we don't have coverage, use nans instead
          stateezr2[0,aa] = state_temp2[0]  ;add time step to overall array
          stateezr2[1,aa] = state_temp2[1]
          stateezr2[2,aa] = state_temp2[2]
          stateezr2[3,aa] = state_temp2[3]  ;vel
          stateezr2[4,aa] = state_temp2[4]
          stateezr2[5,aa] = state_temp2[5]
    endfor
endelse

mvn_pos_mso = dblarr(nele,4)  ;x,y,z,total (4 rows)
mvn_vel_mso = dblarr(nele,4)
mvn_pos_iau = dblarr(nele,4)  ;x,y,z,total (4 rows)
mvn_vel_iau = dblarr(nele,4)
Rmars = 3376.0d ;Mars radius, km
mvn_pos_mso[*,0] = stateezr[0,*]/Rmars  ;positions in Rmars
mvn_pos_mso[*,1] = stateezr[1,*]/Rmars  ;positions in Rmars
mvn_pos_mso[*,2] = stateezr[2,*]/Rmars  ;positions in Rmars
mvn_pos_mso[*,3] = sqrt(mvn_pos_mso[*,0]^2 + mvn_pos_mso[*,1]^2 + mvn_pos_mso[*,2]^2)  ;total radius
mvn_vel_mso[*,0] = stateezr[3,*]  ;velocities in km/s
mvn_vel_mso[*,1] = stateezr[4,*]  ;velocities in km/s
mvn_vel_mso[*,2] = stateezr[5,*]  ;velocities in km/s
mvn_vel_mso[*,3] = sqrt(mvn_vel_mso[*,0]^2 + mvn_vel_mso[*,1]^2 + mvn_vel_mso[*,2]^2)  ;total vel, km/s

mvn_pos_iau[*,0] = stateezr2[0,*]/Rmars  ;positions in Rmars
mvn_pos_iau[*,1] = stateezr2[1,*]/Rmars  ;positions in Rmars
mvn_pos_iau[*,2] = stateezr2[2,*]/Rmars  ;positions in Rmars
mvn_pos_iau[*,3] = sqrt(mvn_pos_iau[*,0]^2 + mvn_pos_iau[*,1]^2 + mvn_pos_iau[*,2]^2)  ;total radius
mvn_vel_iau[*,0] = stateezr2[3,*]  ;velocities in km/s
mvn_vel_iau[*,1] = stateezr2[4,*]  ;velocities in km/s
mvn_vel_iau[*,2] = stateezr2[5,*]  ;velocities in km/s
mvn_vel_iau[*,3] = sqrt(mvn_vel_iau[*,0]^2 + mvn_vel_iau[*,1]^2 + mvn_vel_iau[*,2]^2)  ;total vel, km/s
mvn_pos_iau_cp = stateezr2[0:2,*]  ;copy for getting long, lat, later on

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $
                   'Product_name',                  'mvn_lpw_anc_mvn_pos_mso', $
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
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'MAVEN position, in the Mars-Sun-orbit (MSO) frame.', $
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Units of Mars radii. MSO frame (areocentric): Origin is center of Mars. X points from center of Mars to center of Sun. Y points opposite to Mars orbital angular velocity. Z completes the system.' , $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'Not used.', $
                   ;'dv_Var_notes',                   'Error on frequency', $
                   'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
                   'xFieldnam',                     'x: More information', $      ;###
                   'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
                   ; 'vFieldnam',                     'v: More information', $
                   'dyFieldnam',                    'No used.', $
                   ;  'dvFieldnam',                    'dv: More information', $
                   'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
                   'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_pos_mso), $
                   'SCALEMAX', max(mvn_pos_mso), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $
                   'L0_datafile'     ,     L0_datafile , $
                   'cal_vers'        ,     kernel_version ,$
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $
                   'xsubtitle'       ,     '[sec]', $
                   'ysubtitle'       ,     '[Mars radii (MSO frame)]');, $
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')
                ;-------------  limit ----------------
                limit=create_struct(   $
                  'char_size' ,     1.2                      ,$
                  'xtitle' ,        str_xtitle                   ,$
                  'ytitle' ,        'mvn-position'                 ,$
                  'yrange' ,        [-4.,4.] ,$     ;range of orbit at Mars
                  'ystyle'  ,       1.                       ,$
                  'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
                  'labflag',        1, $
                  'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
                  ;'ztitle' ,        'Z-title'                ,$
                  ;'zrange' ,        [min(data.y),max(data.y)],$
                  ;'spec'            ,     1, $
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
               ;---------------------------------
               store_data, 'mvn_lpw_anc_mvn_pos_mso', data={x:unix_in, y:mvn_pos_mso, flag:spk_flag}, dlimit=dlimit, limit=limit
               ;---------------------------------

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $
                   'Product_name',                  'mvn_lpw_anc_mvn_vel_mso', $
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
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'MAVEN velocity, in the Mars-Sun-orbit (MSO) frame.', $
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Units of km/s. MSO frame (areocentric): Origin is center of Mars. X points from center of Mars to center of Sun. Y points opposite to Mars orbital angular velocity. Z completes the system.' , $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'Not used.', $
                   ;'dv_Var_notes',                   'Error on frequency', $
                   'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
                   'xFieldnam',                     'x: More information.', $      ;###
                   'yFieldnam',                     'y: More information.', $
                   ; 'vFieldnam',                     'v: More information', $
                   'dyFieldnam',                    'dy: Not used.', $
                   ;  'dvFieldnam',                    'dv: More information', $
                   'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_vel_mso), $
                   'SCALEMAX', max(mvn_vel_mso), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $
                   'L0_datafile'     ,     L0_datafile , $
                   'cal_vers'        ,     kernel_version ,$
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $
                   'xsubtitle'       ,     '[sec]', $
                   'ysubtitle'       ,     '[km/s (MSO frame)]');, $
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')
                ;-------------  limit ----------------
                limit=create_struct(   $
                  'char_size' ,     1.2                      ,$
                  'xtitle' ,        str_xtitle                   ,$
                  'ytitle' ,        'mvn-velocity'                 ,$
                  'yrange' ,        [-5,5] ,$
                  'ystyle'  ,       1.                       ,$
                  'labels',         ['Vx', 'Vy', 'Vz', 'TOTAL'], $
                  'labflag',        1, $
                  'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
                  ;'ztitle' ,        'Z-title'                ,$
                  ;'zrange' ,        [min(data.y),max(data.y)],$
                  ;'spec'            ,     1, $
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
               ;---------------------------------
               store_data, 'mvn_lpw_anc_mvn_vel_mso', data={x:unix_in, y:mvn_vel_mso, flag:spk_flag}, dlimit=dlimit, limit=limit  ;#### no velocity yet
               ;---------------------------------

    ;=========
    ;IAU_MARS:
    ;=========

    ;Store as tplot variable:
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_mvn_pos_iau', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'MAVEN position, in the IAU_MARS frame.', $
      ;'v_catdesc',                     'test dlimit file, v', $    ;###
      'dy_catdesc',                    'Error on the data.', $     ;###
      ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of Mars radii. IAU_MARS frame (areodetic): X points from center of Mars to 0 degrees east longitude and 0 degrees latitude; Y points from center of Mars to +90 degrees east longitude and 0 degrees latitude; Z completes the right handed system.' , $
      ;'v_Var_notes',                   'Frequency bins', $
      'dy_Var_notes',                  'Not used.', $
      ;'dv_Var_notes',                   'Error on frequency', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
    'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
      ; 'vFieldnam',                     'v: More information', $
      'dyFieldnam',                    'dy: Not used.', $
      ;  'dvFieldnam',                    'dv: More information', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(mvn_pos_iau), $
      'SCALEMAX', max(mvn_pos_iau), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Mars radii (IAU_MARS frame)]');, $
    ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
    ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
    ;'zsubtitle'       ,     '[Attitude]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'mvn-position'                 ,$
      'yrange' ,        [-4.,4.] ,$     ;range of orbit at Mars
      'ystyle'  ,       1.                       ,$
      'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
      'labflag',        1, $
      'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
      ;'ztitle' ,        'Z-title'                ,$
      ;'zrange' ,        [min(data.y),max(data.y)],$
      ;'spec'            ,     1, $
      ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_mvn_pos_iau', data={x:unix_in, y:mvn_pos_iau, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------

    ;Store as tplot variable:
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_mvn_vel_iau', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'MAVEN velocity, in the IAU_MARS frame.', $
      ;'v_catdesc',                     'test dlimit file, v', $    ;###
      'dy_catdesc',                    'Error on the data.', $     ;###
      ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of km/s. IAU_MARS frame (areodetic): X points from center of Mars to 0 degrees east longitude and 0 degrees latitude; Y points from center of Mars to +90 degrees east longitude and 0 degrees latitude; Z completes the right handed system.' , $
      ;'v_Var_notes',                   'Frequency bins', $
      'dy_Var_notes',                  'Not used.', $
      ;'dv_Var_notes',                   'Error on frequency', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
    'xFieldnam',                     'x: More information.', $      ;###
      'yFieldnam',                     'y: More information.', $
      ; 'vFieldnam',                     'v: More information', $
      'dyFieldnam',                    'dy: Not used.', $
      ;  'dvFieldnam',                    'dv: More information', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(mvn_vel_mso), $
      'SCALEMAX', max(mvn_vel_mso), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[km/s (IAU_MARS frame)]');, $
    ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
    ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
    ;'zsubtitle'       ,     '[Attitude]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'mvn-velocity'                 ,$
      'yrange' ,        [-5,5] ,$
      'ystyle'  ,       1.                       ,$
      'labels',         ['Vx', 'Vy', 'Vz', 'TOTAL'], $
      'labflag',        1, $
      'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
      ;'ztitle' ,        'Z-title'                ,$
      ;'zrange' ,        [min(data.y),max(data.y)],$
      ;'spec'            ,     1, $
      ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_mvn_vel_iau', data={x:unix_in, y:mvn_vel_iau, flag:spk_flag}, dlimit=dlimit, limit=limit  ;#### no velocity yet
    ;---------------------------------

;========
;===7b===
;========
;Ls value for Mars:

;if (spk_coverage eq 'all') then LsMars = CSPICE_LSPCN('MARS',et_time,'NONE') else begin 
  LsMars = fltarr(nele)
  
  for aa = 0, nele-1 do begin  ;do each time point individually
      if (spkcov[aa] eq 1) then LsMars[aa] = CSPICE_LSPCN('MARS',et_time[aa],'NONE') else LsMars[aa] = !values.f_nan
  endfor
;endelse

LsMars = LsMars * 180./!pi  ;convert to degrees

;Store as tplot variable:
;--------------- dlimit   ------------------
dlimit=create_struct(   $
  'Product_name',                  'mvn_lpw_anc_mars_ls', $
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
  'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
  'y_catdesc',                     'Mars solar longitude.', $
  ;'v_catdesc',                     'test dlimit file, v', $    ;###
  'dy_catdesc',                    'Error on the data.', $     ;###
  ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
  'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
  'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
  'y_Var_notes',                   'Mars solar longitude in degrees' , $
;'v_Var_notes',                   'Frequency bins', $
'dy_Var_notes',                  'Not used.', $
  ;'dv_Var_notes',                   'Error on frequency', $
  'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
'xFieldnam',                     'x: More information.', $      ;###
  'yFieldnam',                     'y: More information.', $
  ; 'vFieldnam',                     'v: More information', $
  'dyFieldnam',                    'dy: Not used.', $
  ;  'dvFieldnam',                    'dv: More information', $
  'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
  'MONOTON', 'INCREASE', $
  'SCALEMIN', min(mvn_vel_mso), $
  'SCALEMAX', max(mvn_vel_mso), $        ;..end of required for cdf production.
  't_epoch'         ,     t_epoch, $
  'Time_start'      ,     time_start, $
  'Time_end'        ,     time_end, $
  'Time_field'      ,     time_field, $
  'SPICE_kernel_version', kernel_version, $
  'SPICE_kernel_flag'      ,     spice_used, $
  'L0_datafile'     ,     L0_datafile , $
  'cal_vers'        ,     kernel_version ,$
  'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
  ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
  ;'cal_datafile'    ,     'No calibration file used' , $
  'cal_source'      ,     'SPICE kernels', $
  'xsubtitle'       ,     '[sec]', $
  'ysubtitle'       ,     '[Degrees]');, $
;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
;'zsubtitle'       ,     '[Attitude]')
;-------------  limit ----------------
limit=create_struct(   $
  'char_size' ,     1.2                      ,$
  'xtitle' ,        str_xtitle                   ,$
  'ytitle' ,        'Mars Ls'                 ,$
  'yrange' ,        [0,360] ,$
  'ystyle'  ,       1.                       ,$
  ;'ztitle' ,        'Z-title'                ,$
  ;'zrange' ,        [min(data.y),max(data.y)],$
  ;'spec'            ,     1, $
  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
  'noerrorbars', 1)
;---------------------------------
store_data, 'mvn_lpw_anc_mars_ls', data={x:unix_in, y:LsMars, flag:spk_flag}, dlimit=dlimit, limit=limit 
;---------------------------------

;========
;==8, 9==
;========
if basic eq '0' then begin
;Get MAVEN look vectors:
;Use SPICE to get the MAVEN s/c look vectors for X, Y, and Z:
;Convert from s/c frame to J2000 and MSO frame:

mvn_pointing = dblarr(3,3,nele)  ;array to store all MAVEN pointing info, x in first column, y in second, z in third

;Here, need to check that there is always pointing info for MAVEN. Go through each timestep and check there is pointing.
;Use the encoded clock time, as determined at start of code using SPICE
matrix_j2000=dblarr(3,3,nele)  ;store the rotation matrix in
matrix_mso=dblarr(3,3,nele)  ;store MSO rotation matrix
for aa = 0l, nele-1 do begin
    cspice_ckgp, -202000, enc_time[aa], 0.0, 'MAVEN_SPACECRAFT', mat1, clk, found
    if found eq 1. then begin  ;if we have pointing info, carry on...
        mat_j = spice_body_att('MAVEN_SPACECRAFT', 'J2000', utc_time[aa])  ;one at a time to Davin's routine
        ;cspice_pxform, "MAVEN_SPACECRAFT", "J2000", et_time[aa], mat_j  ;MAVEN pointing in J2000 frame
        matrix_j2000[*,*,aa] = mat_j[*,*]

        mat_mso = spice_body_att('MAVEN_SPACECRAFT', 'MAVEN_MSO', utc_time[aa])
        ;cspice_pxform, "MAVEN_SPACECRAFT", "MAVEN_MSO", et_time[aa], mat_mso  ;MAVEN pointing in MSO frame
        matrix_mso[*,*,aa] = mat_mso[*,*]
    endif else begin
        matrix_j2000[*,*,aa] = !values.f_nan  ;nans if we don't find pointing
        matrix_mso[*,*,aa] = !values.f_nan
    endelse
endfor

;Make a flag array letting us know what timesteps we don't have pointing info for:
att_flag = fltarr(nele)
for aa = 0L, nele-1 do att_flag[aa] = finite(matrix_mso[0,0,aa], /nan)  ;if we have a nan, we need a flag for that timestep


mvn_att_j2000 = dblarr(3,3,nele)  ;store x vector (3 components in J2000) in row 1, y in row 2, z in 3. Time in nele.
mvn_att_mso = dblarr(3,3,nele)  ;store x vector (3 components in MSO) in row 1, y in row 2, z in 3. Time in nele.

for aa = 0L, nele-1 do begin
        ;Transform MAVEN xyz vectors into J2000:
        cspice_mxv, matrix_j2000[*,*,aa], mvn_x, mvn_x_j2000   ;can only take one vector at a time.
          mvn_att_j2000[*,0,aa] = mvn_x_j2000  ;store mvn x in j2000 for time nele
        cspice_mxv, matrix_j2000[*,*,aa], mvn_y, mvn_y_j2000
          mvn_att_j2000[*,1,aa] = mvn_y_j2000
        cspice_mxv, matrix_j2000[*,*,aa], mvn_z, mvn_z_j2000
          mvn_att_j2000[*,2,aa] = mvn_z_j2000

        ;Transform MAVEN xyz vectors into MSO:
        cspice_mxv, matrix_mso[*,*,aa], mvn_x, mvn_x_mso   ;can only take one vector at a time.
          mvn_att_mso[*,0,aa] = mvn_x_mso  ;store mvn x in mso for time nele
        cspice_mxv, matrix_mso[*,*,aa], mvn_y, mvn_y_mso
          mvn_att_mso[*,1,aa] = mvn_y_mso
        cspice_mxv, matrix_mso[*,*,aa], mvn_z, mvn_z_mso
          mvn_att_mso[*,2,aa] = mvn_z_mso
endfor  ;over aa

ydata = dblarr(nele,9)
for bb = 0, 2 do ydata[*,bb] = mvn_att_j2000[bb,0,*]
for bb = 0, 2 do ydata[*,3+bb] = mvn_att_j2000[bb,1,*]
for bb = 0, 2 do ydata[*,6+bb] = mvn_att_j2000[bb,2,*]
                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $
                   'Product_name',                  'mvn_lpw_anc_mvn_att_j2000', $
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
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'MAVEN attitude (pointing), in the Earth mean equator and equinox of J2000 frame (J2000) frame.', $
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Unit vectors for pointing. J2000 frame: Origin is center of Earth. X-Y plane defined as Earths mean equator on 2000-01-01. X points to vernal equinox on 2000-01-01. Z completes system (celestial north). First row is MAVEN s/c X axis vector [x,y,z components], in the J2000 frame. Second row is MAVEN s/c Y axis vector [x,y,z components], in the J2000 frame. Third row is MAVEN s/c Z axis vector px,y,z components] in J2000 frame.', $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'Not used.', $
                   ;'dv_Var_notes',                   'Error on frequency', $
                   'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
                   'xFieldnam',                     'x: More information.', $      ;###
                   'yFieldnam',                     'y: More information.', $
                   ; 'vFieldnam',                     'v: More information', $
                   'dyFieldnam',                    'dy: Not used.', $
                   ;  'dvFieldnam',                    'dv: More information', $
                   'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_att_j2000), $
                   'SCALEMAX', max(mvn_att_j2000), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $
                   'L0_datafile'     ,     L0_datafile , $
                   'cal_vers'        ,     kernel_version ,$
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $
                   'xsubtitle'       ,     '[sec]', $
                   'ysubtitle'       ,     '[Unit vector]');, $
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')
                ;-------------  limit ----------------
                limit=create_struct(   $
                  'char_size' ,     1.2                      ,$
                  'xtitle' ,        str_xtitle                   ,$
                  'ytitle' ,        'mvn-att_(Look-vector_J2000-frame)'                 ,$
                  'yrange' ,        [1.1*min(mvn_att_j2000),1.1*max(mvn_att_j2000)] ,$
                  'ystyle'  ,       1.                       ,$
                  'labels',         ['Xx', 'Xy', 'Xz', 'Yx', 'Yy', 'Yz', 'Zx', 'Zy', 'Zz'], $
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$
                  ;'zrange' ,        [min(data.y),max(data.y)],$
                  ;'spec'            ,     1, $
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
               ;---------------------------------
               store_data, 'mvn_lpw_anc_mvn_att_j2000', data={x:unix_in, y:ydata, flag:att_flag}, dlimit=dlimit, limit=limit


ydata = dblarr(nele,9)
for bb = 0, 2 do ydata[*,bb] = mvn_att_mso[bb,0,*]
for bb = 0, 2 do ydata[*,3+bb] = mvn_att_mso[bb,1,*]
for bb = 0, 2 do ydata[*,6+bb] = mvn_att_mso[bb,2,*]

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $
                   'Product_name',                  'mvn_lpw_anc_mvn_att_mso', $
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
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'MAVEN attitude (pointing), in the Mars-Sun-orbit (MSO) frame.', $
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Unit vectors. MSO frame: Origin is center of Mars. X points from center of Mars to center of Sun. Y points opposite to Mars orbital angular velocity. Z completes the system. First row is MAVEN s/c X axis vector [x,y,z components], in the MSO frame. Second row is MAVEN s/c Y axis vector [x,y,z components], in the MSO frame. Third row is MAVEN s/c Z axis vector px,y,z components] in MSO frame.', $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'Not used.', $
                   ;'dv_Var_notes',                   'Error on frequency', $
                   'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
                   'xFieldnam',                     'x: More information.', $      ;###
                   'yFieldnam',                     'y: More information.', $
                   ; 'vFieldnam',                     'v: More information', $
                   'dyFieldnam',                    'dy: Not used.', $
                   ;  'dvFieldnam',                    'dv: More information', $
                   'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_att_mso), $
                   'SCALEMAX', max(mvn_att_mso), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $
                   'L0_datafile'     ,     L0_datafile , $
                   'cal_vers'        ,     kernel_version ,$
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $
                   'xsubtitle'       ,     '[sec]', $
                   'ysubtitle'       ,     '[Unit vector (MSO frame)]');, $
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')
                ;-------------  limit ----------------
                limit=create_struct(   $
                  'char_size' ,     1.2                      ,$
                  'xtitle' ,        str_xtitle                   ,$
                  'ytitle' ,        'mvn-attitude'                 ,$
                  'yrange' ,        [1.1*min(mvn_att_mso),1.1*max(mvn_att_mso)] ,$
                  'ystyle'  ,       1.                       ,$
                  'labels',         ['Xx', 'Xy', 'Xz', 'Yx', 'Yy', 'Yz', 'Zx', 'Zy', 'Zz'], $
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$
                  ;'zrange' ,        [min(data.y),max(data.y)],$
                  ;'spec'            ,     1, $
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
               ;---------------------------------
               store_data, 'mvn_lpw_anc_mvn_att_mso', data={x:unix_in, y:ydata, flag:att_flag}, dlimit=dlimit, limit=limit
               ;---------------------------------

if keyword_set(not_quiet) then begin
    ;Plot offsets:
    ;window, 0, xsize=600, ysize=600  ;makes some machines crash using the window routine
    !p.multi=[0,1,2]
    plot, offset[*,0], offset[*,1], xtitle='Offset in X', ytitle='Offset in Y', title='Offset between MVN Z and Sun (s/c frame)' ;, xrange=[-0.5, 0.5], yrange=[-0.5,0.5] xsty=1, ysty=1
    plot, mvn_angles[*,0], title='Absolute angle between Sun and MAVEN z axis', xtitle='Timestep', ytitle='Abs angle (deg)'
    !p.multi=0
endif


;========
;== 10 ==
;========
;MAVEN velocity in s/c frame:
;General info:

;Here, need to check that there is always pointing info for MAVEN. Go through each timestep and check there is pointing.
;Use the encoded clock time, as determined at start of code using SPICE
tmatrix_iau = dblarr(3,3,nele)  ;store the rotation matrix in
tmatrix_mso = dblarr(3,3,nele)
for aa = 0l, nele-1 do begin
  cspice_ckgp, -202000, enc_time[aa], 0.0, 'MAVEN_MSO', mat1, clk, found
  cspice_ckgp, -202000, enc_time[aa], 0.0, 'IAU_MARS', mat1b, clk, foundb
  if found eq 1. then begin  ;if we have pointing info, carry on...
    mat_mso = spice_body_att('MAVEN_MSO', 'MAVEN_SPACECRAFT', utc_time[aa])  ;one at a time to Davin's routine  ;matrix to convert from MARS_MSO to MAVEN s/c frame.
    ;cspice_pxform, "MAVEN_SPACECRAFT", "J2000", et_time[aa], mat_j  ;MAVEN pointing in J2000 frame
    ;tmatrix_j2000[*,*,aa] = mat_j_2[*,*]
    tmatrix_mso[*,*,aa] = mat_mso[*,*]
  endif else tmatrix_mso[*,*,aa] = !values.f_nan

  if foundb eq 1. then begin  ;if we have pointing info, carry on...
    mat_iau = spice_body_att('IAU_MARS', 'MAVEN_SPACECRAFT', utc_time[aa])  ;one at a time to Davin's routine  ;matrix to convert from MARS_MSO to MAVEN s/c frame.

    tmatrix_iau[*,*,aa] = mat_iau[*,*]
  endif else tmatrix_iau[*,*,aa] = !values.f_nan

endfor


mvn_vel_sc_mso = dblarr(nele,3)  ;store x vector (3 components) in row 1, y in row 2, z in 3. Time in nele.
mvn_vel_sc_iau = dblarr(nele,3)

for aa = 0L, nele-1 do begin
  ;Transform MAVEN xyz vectors:
  cspice_mxv, tmatrix_mso[*,*,aa], transpose(mvn_vel_mso[aa,0:2]), mvn_ram   ;can only take one vector at a time.
  mvn_vel_sc_mso[aa,*] = mvn_ram
  cspice_mxv, tmatrix_iau[*,*,aa], transpose(mvn_vel_iau[aa,0:2]), mvn_ram   ;can only take one vector at a time.
  mvn_vel_sc_iau[aa,*] = mvn_ram
endfor  ;over aa

;Add in total vel vector here:
mvn_vel_sc_mso2 = dblarr(nele,4)
mvn_vel_sc_iau2 = dblarr(nele,4)

for aa = 0, 2 do mvn_vel_sc_mso2[*,aa] = mvn_vel_sc_mso[*,aa]  ;add in x,y,z
mvn_vel_sc_mso2[*,3] = sqrt(mvn_vel_sc_mso[*,0]^2 + mvn_vel_sc_mso[*,1]^2 + mvn_vel_sc_mso[*,2]^2)  ;total

for aa = 0, 2 do mvn_vel_sc_iau2[*,aa] = mvn_vel_sc_iau[*,aa]  ;add in x,y,z
mvn_vel_sc_iau2[*,3] = sqrt(mvn_vel_sc_iau[*,0]^2 + mvn_vel_sc_iau[*,1]^2 + mvn_vel_sc_iau[*,2]^2)  ;total


;Store as tplot variable:
;--------------- dlimit   ------------------
dlimit=create_struct(   $
  'Product_name',                  'mvn_lpw_anc_mvn_vel_sc_mso', $
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
  'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
  'y_catdesc',                     'MAVEN attitude (pointing), in the MAVEN s/c frame.', $
  ;'v_catdesc',                     'test dlimit file, v', $    ;###
  'dy_catdesc',                    'Error on the data.', $     ;###
  ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
  'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
  'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
  'y_Var_notes',                   'Look vectors. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system. Velocity determined from MARS_MSO to MAVEN s/c frame' , $
  ;'v_Var_notes',                   'Frequency bins', $
  'dy_Var_notes',                  'Not used.', $
  ;'dv_Var_notes',                   'Error on frequency', $
  'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
  'xFieldnam',                     'x: More information.', $      ;###
  'yFieldnam',                     'y: More information.', $
  ; 'vFieldnam',                     'v: More information', $
  'dyFieldnam',                    'dy: Not used.', $
  ;  'dvFieldnam',                    'dv: More information', $
  'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
  'MONOTON', 'INCREASE', $
  'SCALEMIN', min(mvn_vel_mso), $
  'SCALEMAX', max(mvn_vel_mso), $        ;..end of required for cdf production.
  't_epoch'         ,     t_epoch, $
  'Time_start'      ,     time_start, $
  'Time_end'        ,     time_end, $
  'Time_field'      ,     time_field, $
  'SPICE_kernel_version', kernel_version, $
  'SPICE_kernel_flag'      ,     spice_used, $
  'L0_datafile'     ,     L0_datafile , $
  'cal_vers'        ,     kernel_version ,$
  'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
  ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
  ;'cal_datafile'    ,     'No calibration file used' , $
  'cal_source'      ,     'SPICE kernels', $
  'xsubtitle'       ,     '[sec]', $
  'ysubtitle'       ,     '[km/s (S/C frame)]');, $
;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
;'zsubtitle'       ,     '[Attitude]')
;-------------  limit ----------------
limit=create_struct(   $
  'char_size' ,     1.2                      ,$
  'xtitle' ,        str_xtitle                   ,$
  'ytitle' ,        'mvn-velocity-mso'                 ,$
  'yrange' ,        [min(mvn_vel_sc_mso2),max(mvn_vel_sc_mso2)] ,$
  'ystyle'  ,       1.                       ,$
  'labels',         ['Vx', 'Vy', 'Vz', 'TOTAL'], $
  'labflag',        1, $
  'colors',         [2,4,6,0], $
  ;'ztitle' ,        'Z-title'                ,$
  ;'zrange' ,        [min(data.y),max(data.y)],$
  ;'spec'            ,     1, $
  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
  'noerrorbars', 1)
;---------------------------------
store_data, 'mvn_lpw_anc_mvn_vel_sc_mso', data={x:unix_in, y:mvn_vel_sc_mso2, flag:att_flag}, dlimit=dlimit, limit=limit  ;#### no velocity yet
;---------------------------------

;--------------- dlimit   ------------------
dlimit=create_struct(   $
  'Product_name',                  'mvn_lpw_anc_mvn_vel_sc_iau', $
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
  'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
  'y_catdesc',                     'MAVEN attitude (pointing), in the MAVEN s/c frame.', $
  ;'v_catdesc',                     'test dlimit file, v', $    ;###
  'dy_catdesc',                    'Error on the data.', $     ;###
  ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
  'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
  'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
  'y_Var_notes',                   'Look vectors. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system. Velocity determined from MARS_IAU to MAVEN sc frame.' , $
  ;'v_Var_notes',                   'Frequency bins', $
  'dy_Var_notes',                  'Not used.', $
  ;'dv_Var_notes',                   'Error on frequency', $
  'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
'xFieldnam',                     'x: More information.', $      ;###
  'yFieldnam',                     'y: More information.', $
  ; 'vFieldnam',                     'v: More information', $
  'dyFieldnam',                    'dy: Not used.', $
  ;  'dvFieldnam',                    'dv: More information', $
  'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
  'MONOTON', 'INCREASE', $
  'SCALEMIN', min(mvn_vel_iau), $
  'SCALEMAX', max(mvn_vel_iau), $        ;..end of required for cdf production.
  't_epoch'         ,     t_epoch, $
  'Time_start'      ,     time_start, $
  'Time_end'        ,     time_end, $
  'Time_field'      ,     time_field, $
  'SPICE_kernel_version', kernel_version, $
  'SPICE_kernel_flag'      ,     spice_used, $
  'L0_datafile'     ,     L0_datafile , $
  'cal_vers'        ,     kernel_version ,$
  'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
  ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
  ;'cal_datafile'    ,     'No calibration file used' , $
  'cal_source'      ,     'SPICE kernels', $
  'xsubtitle'       ,     '[sec]', $
  'ysubtitle'       ,     '[km/s (S/C frame)]');, $
;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
;'zsubtitle'       ,     '[Attitude]')
;-------------  limit ----------------
limit=create_struct(   $
  'char_size' ,     1.2                      ,$
  'xtitle' ,        str_xtitle                   ,$
  'ytitle' ,        'mvn-velocity-IAU'                 ,$
  'yrange' ,        [min(mvn_vel_sc_iau2),max(mvn_vel_sc_iau2)] ,$
  'ystyle'  ,       1.                       ,$
  'labels',         ['Vx', 'Vy', 'Vz', 'TOTAL'], $
  'labflag',        1, $
  'colors',         [2,4,6,0], $
  ;'ztitle' ,        'Z-title'                ,$
  ;'zrange' ,        [min(data.y),max(data.y)],$
  ;'spec'            ,     1, $
  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
  'noerrorbars', 1)
;---------------------------------
store_data, 'mvn_lpw_anc_mvn_vel_sc_iau', data={x:unix_in, y:mvn_vel_sc_iau2, flag:att_flag}, dlimit=dlimit, limit=limit  ;#### no velocity yet
;---------------------------------

endif  ;basic eq 0.

if keyword_set(moons) then begin
    ;Get the positions of the moons Phobos and Deimos in MSO and IAU frames:
    ;MAVEN position and velocity in MSO frame:
    ;General info:
    frame1    = 'MAVEN_MSO'
    frame2   = 'IAU_MARS'
    frame3   = 'IAU_PHOBOS'
    abcorr   = 'LT+S'
    observer = 'Mars'
    observer2 = 'PHOBOS'
    target1 = 'PHOBOS'
    target2 = 'DEIMOS'
    target3 = 'MAVEN_SPACECRAFT'

    ;if (spk_coverage eq 'all') and (ck_coverage eq 'all') then stateezr = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin  ;DAVINS ROUTINE
    if (spk_coverage eq 'all') then begin
      cspice_spkezr, target1, et_time, frame1, abcorr, observer, stateezr1, ltime ;state contains R and V [0:5], USE FOR NOW UNTIL DAVIN ADDS VEL TO HIS ABOVE
      cspice_spkezr, target1, et_time, frame2, abcorr, observer, stateezr2, ltime  ;contains R and V in the IAU_MARS frame
      cspice_spkezr, target2, et_time, frame1, abcorr, observer, stateezr3, ltime ;state contains R and V [0:5], USE FOR NOW UNTIL DAVIN ADDS VEL TO HIS ABOVE
      cspice_spkezr, target2, et_time, frame2, abcorr, observer, stateezr4, ltime  ;contains R and V in the IAU_MARS frame
      ;cspice_spkezr, target3, et_time, frame3, abcorr, observer2, stateezr5, ltime ;MAVEN position wrt Phobos IAU frame
    endif else begin
      stateezr1 = dblarr(6,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
      stateezr2 = dblarr(6,nele)
      stateezr3 = dblarr(6,nele)
      stateezr4 = dblarr(6,nele)
      ;stateezr5 = dblarr(6,nele)
      for aa = 0, nele-1 do begin  ;do each time point individually
        ;if (spkcov[aa] eq 1) and (ck_check[aa] eq 1) then state_temp = spice_body_pos(target, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr) else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]  ;DAVINS
        if (spkcov[aa] eq 1) then begin
          cspice_spkezr, target1, et_time[aa], frame1, abcorr, observer, state_temp1, ltime   ;USE THIS FOR NOW UNTIL DAVINS HAS VEL
          cspice_spkezr, target1, et_time[aa], frame2, abcorr, observer, state_temp2, ltime   ;USE THIS FOR NOW UNTIL DAVINS HAS VEL
          cspice_spkezr, target2, et_time[aa], frame1, abcorr, observer, state_temp3, ltime   ;USE THIS FOR NOW UNTIL DAVINS HAS VEL
          cspice_spkezr, target2, et_time[aa], frame2, abcorr, observer, state_temp4, ltime   ;USE THIS FOR NOW UNTIL DAVINS HAS VEL
          ;cspice_spkezr, target3, et_time, frame3, abcorr, observer2, stateezr5, ltime
        endif else begin
            state_temp1=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]
            state_temp2=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]
            state_temp3=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]
            state_temp4=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]
            ;state_temp5=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]
        endelse

        ;if we don't have coverage, use nans instead
        stateezr1[0,aa] = state_temp1[0]  ;add time step to overall array
        stateezr1[1,aa] = state_temp1[1]
        stateezr1[2,aa] = state_temp1[2]
        stateezr1[3,aa] = state_temp1[3]  ;vel
        stateezr1[4,aa] = state_temp1[4]
        stateezr1[5,aa] = state_temp1[5]
        ;if we don't have coverage, use nans instead
        stateezr2[0,aa] = state_temp2[0]  ;add time step to overall array
        stateezr2[1,aa] = state_temp2[1]
        stateezr2[2,aa] = state_temp2[2]
        stateezr2[3,aa] = state_temp2[3]  ;vel
        stateezr2[4,aa] = state_temp2[4]
        stateezr2[5,aa] = state_temp2[5]

        stateezr3[0,aa] = state_temp3[0]  ;add time step to overall array
        stateezr3[1,aa] = state_temp3[1]
        stateezr3[2,aa] = state_temp3[2]
        stateezr3[3,aa] = state_temp3[3]  ;vel
        stateezr3[4,aa] = state_temp3[4]
        stateezr3[5,aa] = state_temp3[5]
        ;if we don't have coverage, use nans instead
        stateezr4[0,aa] = state_temp4[0]  ;add time step to overall array
        stateezr4[1,aa] = state_temp4[1]
        stateezr4[2,aa] = state_temp4[2]
        stateezr4[3,aa] = state_temp4[3]  ;vel
        stateezr4[4,aa] = state_temp4[4]
        stateezr4[5,aa] = state_temp4[5]

        ;stateezr5[0,aa] = state_temp5[0]  ;add time step to overall array
        ;stateezr5[1,aa] = state_temp5[1]
        ;stateezr5[2,aa] = state_temp5[2]
        ;stateezr5[3,aa] = state_temp5[3]  ;vel
        ;stateezr5[4,aa] = state_temp5[4]
        ;stateezr5[5,aa] = state_temp5[5]
      endfor
    endelse

    pho_pos_mso = dblarr(nele,4)  ;x,y,z,total (4 rows)
    pho_pos_iau = dblarr(nele,4)
    dei_pos_mso = dblarr(nele,4)  ;x,y,z,total (4 rows)
    dei_pos_iau = dblarr(nele,4)
    ;mvn_pos_pho = dblarr(nele,4)

    Rmars = 3376.0d ;Mars radius, km

    pho_pos_mso[*,0] = stateezr1[0,*]/Rmars  ;positions in Rmars
    pho_pos_mso[*,1] = stateezr1[1,*]/Rmars  ;positions in Rmars
    pho_pos_mso[*,2] = stateezr1[2,*]/Rmars  ;positions in Rmars
    pho_pos_mso[*,3] = sqrt(pho_pos_mso[*,0]^2 + pho_pos_mso[*,1]^2 + pho_pos_mso[*,2]^2)  ;total radius

    pho_pos_iau[*,0] = stateezr2[0,*]/Rmars  ;positions in Rmars
    pho_pos_iau[*,1] = stateezr2[1,*]/Rmars  ;positions in Rmars
    pho_pos_iau[*,2] = stateezr2[2,*]/Rmars  ;positions in Rmars
    pho_pos_iau[*,3] = sqrt(pho_pos_iau[*,0]^2 + pho_pos_iau[*,1]^2 + pho_pos_iau[*,2]^2)  ;total radius

    dei_pos_mso[*,0] = stateezr3[0,*]/Rmars  ;positions in Rmars
    dei_pos_mso[*,1] = stateezr3[1,*]/Rmars  ;positions in Rmars
    dei_pos_mso[*,2] = stateezr3[2,*]/Rmars  ;positions in Rmars
    dei_pos_mso[*,3] = sqrt(dei_pos_mso[*,0]^2 + dei_pos_mso[*,1]^2 + dei_pos_mso[*,2]^2)  ;total radius

    dei_pos_iau[*,0] = stateezr4[0,*]/Rmars  ;positions in Rmars
    dei_pos_iau[*,1] = stateezr4[1,*]/Rmars  ;positions in Rmars
    dei_pos_iau[*,2] = stateezr4[2,*]/Rmars  ;positions in Rmars
    dei_pos_iau[*,3] = sqrt(dei_pos_iau[*,0]^2 + dei_pos_iau[*,1]^2 + dei_pos_iau[*,2]^2)  ;total radius
    
    ;mvn_pos_pho[*,0] = stateezr5[0,*]/Rmars  ;positions in Rmars
    ;mvn_pos_pho[*,1] = stateezr5[1,*]/Rmars  ;positions in Rmars
    ;mvn_pos_pho[*,2] = stateezr5[2,*]/Rmars  ;positions in Rmars
    ;mvn_pos_pho[*,3] = sqrt(mvn_pos_pho[*,0]^2 + mvn_pos_pho[*,1]^2 + mvn_pos_pho[*,2]^2)  ;total radius
    
    ;SPICE didn't like doing MAVEN in Phobos frame, so use rotate instead:
    get_data, 'mvn_lpw_anc_mvn_pos_mso', data=ddTMP
    mavPTMP = transpose(ddTMP.y[*,0:2])  ;get x,y,z
    phoTMP = spice_vector_rotate(mavPTMP*Rmars, ddTMP.x, 'MAVEN_MSO', 'IAU_PHOBOS', check_objects='IAU_PHOBOS')   ;!@#$!@#% Doesn't work yet
    phoTMP = transpose(phoTMP)  ;back to tplot format
    phoR = sqrt(phoTMP[*,0]^2 + phoTMP[*,1]^2 + phoTMP[*,2]^2)
    phoTMP = [[phoTMP], [phoR]]  ;add in magnitude

    ;Store as tplot variable:
    ;-------
    ;PHOBOS:
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_pho_pos_mso', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'Phobos position, in the Mars-Sun-orbit (MSO) frame.', $
      ;'v_catdesc',                     'test dlimit file, v', $    ;###
      'dy_catdesc',                    'Error on the data.', $     ;###
      ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of Mars radii. MSO frame (areocentric): Origin is center of Mars. X points from center of Mars to center of Sun. Y points opposite to Mars orbital angular velocity. Z completes the system.' , $
      ;'v_Var_notes',                   'Frequency bins', $
      'dy_Var_notes',                  'Not used.', $
      ;'dv_Var_notes',                   'Error on frequency', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
      'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
      ; 'vFieldnam',                     'v: More information', $
      'dyFieldnam',                    'No used.', $
      ;  'dvFieldnam',                    'dv: More information', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(pho_pos_mso), $
      'SCALEMAX', max(pho_pos_mso), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Mars radii (MSO frame)]');, $
    ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
    ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
    ;'zsubtitle'       ,     '[Attitude]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'Phobos-position'                 ,$
      'yrange' ,        [-5.,5.] ,$     ;range of orbit at Mars
      'ystyle'  ,       1.                       ,$
      'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
      'labflag',        1, $
      'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
      ;'ztitle' ,        'Z-title'                ,$
      ;'zrange' ,        [min(data.y),max(data.y)],$
      ;'spec'            ,     1, $
      ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_pho_pos_mso', data={x:unix_in, y:pho_pos_mso, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------

    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_pho_pos_iau', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'Phobos position, in the IAU_MARS frame.', $
      ;'v_catdesc',                     'test dlimit file, v', $    ;###
      'dy_catdesc',                    'Error on the data.', $     ;###
      ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of Mars radii. IAU_MARS frame (areodetic): X points from center of Mars to 0 degrees east longitude and 0 degrees latitude; Y points from center of Mars to +90 degrees east longitude and 0 degrees latitude; Z completes the right handed system.' , $
      ;'v_Var_notes',                   'Frequency bins', $
      'dy_Var_notes',                  'Not used.', $
      ;'dv_Var_notes',                   'Error on frequency', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
      'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
      ; 'vFieldnam',                     'v: More information', $
      'dyFieldnam',                    'No used.', $
      ;  'dvFieldnam',                    'dv: More information', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(pho_pos_iau), $
      'SCALEMAX', max(pho_pos_iau), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Mars radii (IAU frame)]');, $
    ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
    ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
    ;'zsubtitle'       ,     '[Attitude]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'Phobos-position'                 ,$
      'yrange' ,        [-5.,5.] ,$     ;range of orbit at Mars
      'ystyle'  ,       1.                       ,$
      'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
      'labflag',        1, $
      'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
      ;'ztitle' ,        'Z-title'                ,$
      ;'zrange' ,        [min(data.y),max(data.y)],$
      ;'spec'            ,     1, $
      ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_pho_pos_iau', data={x:unix_in, y:pho_pos_iau, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------

    ;-------
    ;DEIMOS:
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_dei_pos_mso', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'Deimos position, in the Mars-Sun-orbit (MSO) frame.', $
      ;'v_catdesc',                     'test dlimit file, v', $    ;###
      'dy_catdesc',                    'Error on the data.', $     ;###
      ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of Mars radii. MSO frame (areocentric): Origin is center of Mars. X points from center of Mars to center of Sun. Y points opposite to Mars orbital angular velocity. Z completes the system.' , $
      ;'v_Var_notes',                   'Frequency bins', $
      'dy_Var_notes',                  'Not used.', $
      ;'dv_Var_notes',                   'Error on frequency', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
      'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
      ; 'vFieldnam',                     'v: More information', $
      'dyFieldnam',                    'No used.', $
      ;  'dvFieldnam',                    'dv: More information', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(dei_pos_mso), $
      'SCALEMAX', max(dei_pos_mso), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Mars radii (MSO frame)]');, $
    ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
    ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
    ;'zsubtitle'       ,     '[Attitude]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'Deimos-position'                 ,$
      'yrange' ,        [-10.,10.] ,$     ;range of orbit at Mars
      'ystyle'  ,       1.                       ,$
      'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
      'labflag',        1, $
      'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
      ;'ztitle' ,        'Z-title'                ,$
      ;'zrange' ,        [min(data.y),max(data.y)],$
      ;'spec'            ,     1, $
      ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_dei_pos_mso', data={x:unix_in, y:dei_pos_mso, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------

    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_dei_pos_iau', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'Deimos position, in the IAU_MARS frame.', $
      ;'v_catdesc',                     'test dlimit file, v', $    ;###
      'dy_catdesc',                    'Error on the data.', $     ;###
      ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of Mars radii. IAU_MARS frame (areodetic): X points from center of Mars to 0 degrees east longitude and 0 degrees latitude; Y points from center of Mars to +90 degrees east longitude and 0 degrees latitude; Z completes the right handed system.' , $
      ;'v_Var_notes',                   'Frequency bins', $
      'dy_Var_notes',                  'Not used.', $
      ;'dv_Var_notes',                   'Error on frequency', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
      'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
      ; 'vFieldnam',                     'v: More information', $
      'dyFieldnam',                    'No used.', $
      ;  'dvFieldnam',                    'dv: More information', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(pho_pos_iau), $
      'SCALEMAX', max(pho_pos_iau), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Mars radii (IAU frame)]');, $
    ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
    ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
    ;'zsubtitle'       ,     '[Attitude]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'Deimos-position'                 ,$
      'yrange' ,        [-10.,10.] ,$     ;range of orbit at Mars
      'ystyle'  ,       1.                       ,$
      'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
      'labflag',        1, $
      'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
      ;'ztitle' ,        'Z-title'                ,$
      ;'zrange' ,        [min(data.y),max(data.y)],$
      ;'spec'            ,     1, $
      ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_dei_pos_iau', data={x:unix_in, y:dei_pos_iau, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------

    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_mvn_pos_pho', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'MAVEN position, in the IAU_PHOBOS frame.', $
      ;'v_catdesc',                     'test dlimit file, v', $    ;###
      'dy_catdesc',                    'Error on the data.', $     ;###
      ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of Mars radii. IAU_PHOBOS frame (areodetic): I *think* this is correct, but you should check: X points from center of Phobos to 0 degrees east longitude and 0 degrees latitude; Y points from center of Phobos to +90 degrees east longitude and 0 degrees latitude; Z completes the right handed system.' , $
    ;'v_Var_notes',                   'Frequency bins', $
    'dy_Var_notes',                  'Not used.', $
      ;'dv_Var_notes',                   'Error on frequency', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
    'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
      ; 'vFieldnam',                     'v: More information', $
      'dyFieldnam',                    'No used.', $
      ;  'dvFieldnam',                    'dv: More information', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(phoTMP), $
      'SCALEMAX', max(phoTMP), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Mars radii (IAU frame)]');, $
    ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
    ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
    ;'zsubtitle'       ,     '[Attitude]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'MAVEN-position'                 ,$
      'yrange' ,        [-10.,10.] ,$     ;range of orbit at Mars
      'ystyle'  ,       1.                       ,$
      'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
      'labflag',        1, $
      'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
      ;'ztitle' ,        'Z-title'                ,$
      ;'zrange' ,        [min(data.y),max(data.y)],$
      ;'spec'            ,     1, $
      ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_mvn_pos_pho', data={x:unix_in, y:phoTMP, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------



    ;===================================================================================================================================
    ;Get the positions of the moons Phobos and Deimos in MAVEN frames:
    ;MOON positions and velocity in MAVEN frame:
    ;General info:
    frame    = 'MAVEN_SPACECRAFT'
    abcorr   = 'LT+S'  ;correct for light travel time and something
    observer = 'MAVEN'
    targetPHOBOS = 'PHOBOS'
    targetDEIMOS = 'DEIMOS'
    ;=====
    ;==1==
    ;=====
    ;Absolute angle between Moons and MAVEN
    ;Get Moon position relative to MAVEN in s/c frame:
    ;Information needed:

    IF (spk_coverage EQ 'all') AND (ck_coverage EQ 'all') THEN BEGIN
      statePHOBOS = spice_body_pos(targetPHOBOS, observer, utc=utc_time, frame=frame, abcorr=abcorr)
      stateDEIMOS = spice_body_pos(targetDEIMOS, observer, utc=utc_time, frame=frame, abcorr=abcorr)
    ENDIF ELSE BEGIN
      statePHOBOS = DBLARR(3,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
      stateDEIMOS = DBLARR(3,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
      FOR aa = 0, nele-1 DO BEGIN  ;do each time point individually
        IF (spkcov[aa] EQ 1) AND (ck_check[aa] EQ 1) THEN BEGIN
          state_tempPHOBOS = spice_body_pos(targetPHOBOS, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr)
          state_tempDEIMOS = spice_body_pos(targetDEIMOS, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr)
        ENDIF ELSE BEGIN
          state_tempPHOBOS = [!values.f_nan, !values.f_nan, !values.f_nan]
          state_tempDEIMOS = [!values.f_nan, !values.f_nan, !values.f_nan]
        ENDELSE
        ;if we don't have coverage, use nans instead
        statePHOBOS[0,aa] = state_tempPHOBOS[0]  ;add time step to overall array
        statePHOBOS[1,aa] = state_tempPHOBOS[1]
        statePHOBOS[2,aa] = state_tempPHOBOS[2]
        stateDEIMOS[0,aa] = state_tempDEIMOS[0]  ;add time step to overall array
        stateDEIMOS[1,aa] = state_tempDEIMOS[1]
        stateDEIMOS[2,aa] = state_tempDEIMOS[2]
      ENDFOR
    ENDELSE

    ;Extract PHOBOS position, in s/c frame:
    pos_PHOBOS = DBLARR(nele,3)
    pos_PHOBOS[*,0] = statePHOBOS[0,*]  ;positions in km
    pos_PHOBOS[*,1] = statePHOBOS[1,*]
    pos_PHOBOS[*,2] = statePHOBOS[2,*]
    ;Extract Sun position, in s/c frame:
    pos_DEIMOS = DBLARR(nele,3)
    pos_DEIMOS[*,0] = stateDEIMOS[0,*]  ;positions in km
    pos_DEIMOS[*,1] = stateDEIMOS[1,*]
    pos_DEIMOS[*,2] = stateDEIMOS[2,*]


    ;Store as tplot variable:
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_PHOBOS_pos_mvn', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'PHOBOS position, in MAVEN frame.', $
      'dy_catdesc',                    'Error on the data.', $     ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of km', $
      'dy_Var_notes',                  'Not used.', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
      'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: More information', $
      'dyFieldnam',                    'dy: Not used.', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', MIN(pos_PHOBOS), $
      'SCALEMAX', MAX(pos_PHOBOS), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[km]');, $
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'Phobos position (s/c frame)'                 ,$
      'yrange' ,        [MIN(pos_PHOBOS),MAX(pos_PHOBOS)] ,$
      'ystyle'  ,       1.                       ,$
      'labflag',        1, $
      'labels',         ['MVN X', 'MVN Y', 'MVN Z'], $
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_phobos_pos_mvn', data={x:unix_in, y:pos_PHOBOS, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------

    ;Store as tplot variable:
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_DEIMOS_pos_mvn', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'DEIMOS position, in MAVEN frame.', $
      'dy_catdesc',                    'Error on the data.', $     ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of km', $
      'dy_Var_notes',                  'Not used.', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
      'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: More information', $
      'dyFieldnam',                    'dy: Not used.', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', MIN(pos_DEIMOS), $
      'SCALEMAX', MAX(pos_DEIMOS), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[km]');, $
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'Deimos position (s/c frame)'                 ,$
      'yrange' ,        [MIN(pos_DEIMOS),MAX(pos_DEIMOS)] ,$
      'ystyle'  ,       1.                       ,$
      'labflag',        1, $
      'labels',         ['MVN X', 'MVN Y', 'MVN Z'], $
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_deimos_pos_mvn', data={x:unix_in, y:pos_DEIMOS, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------

endif  ;moons


if keyword_set(css) then begin
      ;Load CSS kernel, de file (planet ephemeris) and lsk file. Get them from tplot variable.


      cssfile = '/Volumes/spg/maven/data/misc/spice/naif/generic_kernels/spk/comets/siding_spring_s46.bsp'  ;hard coded, only one spk produced.
      css_kernels_to_check = cssfile
      css_loaded_kernels = cssfile
      cspice_furnsh, cssfile

      ;Get the positions of the moons Phobos and Deimos in MSO and IAU frames:
      ;MAVEN position and velocity in MSO frame:
      ;General info:
      frame1    = 'MAVEN_MSO'
      frame2   = 'IAU_MARS'
      abcorr   = 'LT+S'
      observer = 'Mars'
      target1 = '1003228'  ;CSS NAIF code

      css_cov = mvn_lpw_anc_covtest(unix_in, css_kernels_to_check, 1003228)  ;for now use unix times, may change to ET.
      if min(css_cov) eq 1 then css_coverage = 'all' else begin
        css_coverage = 'some'
        print, "### WARNING ###: CSS position (spk) information not available for ", n_elements(where(css_cov) eq 0), " data point(s)."
      endelse

      css_flag = (css_cov ne 1)

      if (css_coverage eq 'all') then begin
        cspice_spkezr, target1, et_time, frame1, abcorr, observer, stateezr1, ltime ;state contains R and V [0:5], USE FOR NOW UNTIL DAVIN ADDS VEL TO HIS ABOVE
        cspice_spkezr, target1, et_time, frame2, abcorr, observer, stateezr2, ltime  ;contains R and V in the IAU_MARS frame
      endif else begin
        stateezr1 = dblarr(6,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
        stateezr2 = dblarr(6,nele)
        for aa = 0, nele-1 do begin  ;do each time point individually
          ;if (spkcov[aa] eq 1) and (ck_check[aa] eq 1) then state_temp = spice_body_pos(target, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr) else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]  ;DAVINS
          if (css_cov[aa] eq 1) then begin
            cspice_spkezr, target1, et_time[aa], frame1, abcorr, observer, state_temp1, ltime   ;USE THIS FOR NOW UNTIL DAVINS HAS VEL
            cspice_spkezr, target1, et_time[aa], frame2, abcorr, observer, state_temp2, ltime   ;USE THIS FOR NOW UNTIL DAVINS HAS VEL
          endif else begin
            state_temp1=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]
            state_temp2=[!values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan, !values.f_nan]
          endelse

          ;if we don't have coverage, use nans instead
          stateezr1[0,aa] = state_temp1[0]  ;add time step to overall array
          stateezr1[1,aa] = state_temp1[1]
          stateezr1[2,aa] = state_temp1[2]
          stateezr1[3,aa] = state_temp1[3]  ;vel
          stateezr1[4,aa] = state_temp1[4]
          stateezr1[5,aa] = state_temp1[5]
          ;if we don't have coverage, use nans instead
          stateezr2[0,aa] = state_temp2[0]  ;add time step to overall array
          stateezr2[1,aa] = state_temp2[1]
          stateezr2[2,aa] = state_temp2[2]
          stateezr2[3,aa] = state_temp2[3]  ;vel
          stateezr2[4,aa] = state_temp2[4]
          stateezr2[5,aa] = state_temp2[5]

        endfor
      endelse

      css_pos_mso = dblarr(nele,4)  ;x,y,z,total (4 rows)
      css_pos_iau = dblarr(nele,4)
      css_pos_mso = dblarr(nele,4)  ;x,y,z,total (4 rows)
      css_pos_iau = dblarr(nele,4)

      Rmars = 3376.0d ;Mars radius, km

      css_pos_mso[*,0] = stateezr1[0,*]/Rmars  ;positions in Rmars
      css_pos_mso[*,1] = stateezr1[1,*]/Rmars  ;positions in Rmars
      css_pos_mso[*,2] = stateezr1[2,*]/Rmars  ;positions in Rmars
      css_pos_mso[*,3] = sqrt(css_pos_mso[*,0]^2 + css_pos_mso[*,1]^2 + css_pos_mso[*,2]^2)  ;total radius

      css_pos_iau[*,0] = stateezr2[0,*]/Rmars  ;positions in Rmars
      css_pos_iau[*,1] = stateezr2[1,*]/Rmars  ;positions in Rmars
      css_pos_iau[*,2] = stateezr2[2,*]/Rmars  ;positions in Rmars
      css_pos_iau[*,3] = sqrt(css_pos_iau[*,0]^2 + css_pos_iau[*,1]^2 + css_pos_iau[*,2]^2)  ;total radius

      ;Store as tplot variable:
      ;-------
      ;CSS:
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'mvn_lpw_anc_css_pos_mso', $
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
        'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
        'y_catdesc',                     'Comet Siding spring position, in the Mars-Sun-orbit (MSO) frame.', $
        ;'v_catdesc',                     'test dlimit file, v', $    ;###
        'dy_catdesc',                    'Error on the data.', $     ;###
        ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
        'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
        'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
        'y_Var_notes',                   'Units of Mars radii. MSO frame (areocentric): Origin is center of Mars. X points from center of Mars to center of Sun. Y points opposite to Mars orbital angular velocity. Z completes the system.' , $
        ;'v_Var_notes',                   'Frequency bins', $
        'dy_Var_notes',                  'Not used.', $
        ;'dv_Var_notes',                   'Error on frequency', $
        'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
      'xFieldnam',                     'x: More information', $      ;###
        'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
        ; 'vFieldnam',                     'v: More information', $
        'dyFieldnam',                    'No used.', $
        ;  'dvFieldnam',                    'dv: More information', $
        'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
        'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', min(css_pos_mso), $
        'SCALEMAX', max(css_pos_mso), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     time_start, $
        'Time_end'        ,     time_end, $
        'Time_field'      ,     time_field, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     L0_datafile , $
        'cal_vers'        ,     kernel_version ,$
        'cal_y_const1'    ,     css_loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'SPICE kernels', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[Mars radii (MSO frame)]');, $
      ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'zsubtitle'       ,     '[Attitude]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'CSS-position'                 ,$
        'yrange' ,        [min(css_pos_mso, /nan),max(css_pos_mso, /nan)] ,$     ;range of orbit at Mars
        'ystyle'  ,       1.                       ,$
        'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
        'labflag',        1, $
        'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
        ;'ztitle' ,        'Z-title'                ,$
        ;'zrange' ,        [min(data.y),max(data.y)],$
        ;'spec'            ,     1, $
        ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
        'noerrorbars', 1)
      ;---------------------------------
      store_data, 'mvn_lpw_anc_css_pos_mso', data={x:unix_in, y:css_pos_mso, flag:css_flag}, dlimit=dlimit, limit=limit
      ;---------------------------------

      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'mvn_lpw_anc_css_pos_iau', $
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
        'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
        'y_catdesc',                     'Comet Siding Spring position, in the IAU_MARS frame.', $
        ;'v_catdesc',                     'test dlimit file, v', $    ;###
        'dy_catdesc',                    'Error on the data.', $     ;###
        ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
        'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
        'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
        'y_Var_notes',                   'Units of Mars radii. IAU_MARS frame (areodetic): X points from center of Mars to 0 degrees east longitude and 0 degrees latitude; Y points from center of Mars to +90 degrees east longitude and 0 degrees latitude; Z completes the right handed system.' , $
      ;'v_Var_notes',                   'Frequency bins', $
      'dy_Var_notes',                  'Not used.', $
        ;'dv_Var_notes',                   'Error on frequency', $
        'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
      'xFieldnam',                     'x: More information', $      ;###
        'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
        ; 'vFieldnam',                     'v: More information', $
        'dyFieldnam',                    'No used.', $
        ;  'dvFieldnam',                    'dv: More information', $
        'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
        'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', min(css_pos_iau), $
        'SCALEMAX', max(css_pos_iau), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     time_start, $
        'Time_end'        ,     time_end, $
        'Time_field'      ,     time_field, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     L0_datafile , $
        'cal_vers'        ,     kernel_version ,$
        'cal_y_const1'    ,     css_loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'SPICE kernels', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[Mars radii (IAU frame)]');, $
      ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'zsubtitle'       ,     '[Attitude]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'CSS-position'                 ,$
        'yrange' ,        [min(css_pos_iau, /nan), max(css_pos_iau, /nan)] ,$     ;range of orbit at Mars
        'ystyle'  ,       1.                       ,$
        'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
        'labflag',        1, $
        'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
        ;'ztitle' ,        'Z-title'                ,$
        ;'zrange' ,        [min(data.y),max(data.y)],$
        ;'spec'            ,     1, $
        ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
        'noerrorbars', 1)
      ;---------------------------------
      store_data, 'mvn_lpw_anc_css_pos_iau', data={x:unix_in, y:css_pos_iau, flag:css_flag}, dlimit=dlimit, limit=limit
      ;---------------------------------

endif


;========================================================
;Longitude, Latitude, Altitude, based on geodetic coords:
;========================================================
;Mars is not a sphere therefore the altitudes calculated above are off by upto ~20 km.
;Check we have radius information about Mars:
found = cspice_bodfnd( 499, "RADII" )

if (found) then begin
      cspice_bodvrd, 'MARS', "RADII", 499, radii
      flat = (RADII[0] - RADII[2])/RADII[0]  ;flattening coefficient between polar and equatorial radii.

      cspice_recgeo, mvn_pos_iau_cp, radii[0], flat, lon, lat, alt   ;mvn_pos_iau is 3XN matrix of position. THIS GIVES CORRECT ALTITUDE BUT NOT EAST LON-LAT!!

      alt_iau = alt
      
        ;Calculate east lon-lat correctly! Convert MSO cartesian to IAU_Mars frame using cspice_pxform, then get long lat (from spherical).
        cspice_pxform, 'MAVEN_MSO', 'IAU_MARS', et_time, rotate  ;rotate contains the rotation matrix to go from MAVEN_MSO to IAU_MARS.
                                  ;rotate is 3x3xN, where N is number of time steps
               
        pos_IAU = fltarr(3, nele)  ;store position in IAUmars frame
        get_data, 'mvn_lpw_anc_mvn_pos_mso', data=ddMSO
        
        for tp = 0., nele-1. do begin                       
            cspice_mxv, rotate[*,*,tp], transpose(ddMSO.y[tp,0:2]), iauTMP   ;rotate into new frame
            pos_IAU[*,tp] = iauTMP  ;store rotated position         
        endfor
        
        ;Convert cartesian to spherical (lon-lat):
        rIAU = sqrt(pos_IAU[0,*]^2 + pos_IAU[1,*]^2 + pos_IAU[2,*]^2)
        phi = acos(pos_IAU[2,*]/rIAU) * (180./!pi)  ;0 is in +Z direction, adjust:
            phi2=90.-phi   ;this is now latitude +90 => -90
            
        theta = atan(pos_IAU[1,*], pos_IAU[0,*]) * (180./!pi)  ;this should also be east longitude, NOTE: whenr you give atan() two arguments it does the sectors correctly.
            iTMP = where(theta lt 0., niTMP)  ;range is -180=>180, negative values go to 180-360
            if niTMP gt 0. then theta[iTMP] = 360. + theta[iTMP]  ;negative means values subtract
        
        longlat = [[transpose(theta)], [transpose(phi2)]]

        ;Store data:
        store_data, 'mvn_lpw_anc_mvn_longlat_iau', data={x:unix_in, y:longlat}
        store_data, 'mvn_lpw_anc_mvn_alt_iau', data={x:unix_in, y:alt_iau}

    if keyword_set(notready) then begin
      ;COROTATION:
      mvn_lpw_anc_corotation, CoRoV_iau=CoRoV_iau

      ;Transform IAU to MSO and SC frames:
      CoRoV_MSO = dblarr(nele,3)  ;store CoRo information in MSO, x in first column, y in second, z in third
      CoRoV_SC = CoRoV_MSO

    ;Here, need to check that there is always pointing info for MAVEN. Go through each timestep and check there is pointing.
    ;Use the encoded clock time, as determined at start of code using SPICE
    tmatrix_sc = dblarr(3,3,nele)  ;store the rotation matrix in
    tmatrix_mso = dblarr(3,3,nele)
    for aa = 0l, nele-1 do begin
      cspice_ckgp, -202000, enc_time[aa], 0.0, 'MAVEN_MSO', mat1, clk, found
      cspice_ckgp, -202000, enc_time[aa], 0.0, 'IAU_MARS', mat1b, clk, foundb
      if found eq 1. then begin  ;if we have pointing info, carry on...
        mat_mso = spice_body_att('IAU_MARS', 'MAVEN_MSO', utc_time[aa])  ;one at a time to Davin's routine  ;matrix to convert from MARS_MSO to MAVEN s/c frame.
        tmatrix_mso[*,*,aa] = mat_mso[*,*]
      endif else tmatrix_mso[*,*,aa] = !values.f_nan

      if foundb eq 1. then begin  ;if we have pointing info, carry on...
        mat_sc = spice_body_att('IAU_MARS', 'MAVEN_SPACECRAFT', utc_time[aa])  ;one at a time to Davin's routine  ;matrix to convert from MARS_MSO to MAVEN s/c frame.
        tmatrix_sc[*,*,aa] = mat_sc[*,*]
      endif else tmatrix_sc[*,*,aa] = !values.f_nan

    endfor


    for aa = 0L, nele-1 do begin
      ;Transform MAVEN xyz vectors:
      cspice_mxv, tmatrix_mso[*,*,aa], transpose(CoRoV_iau[aa,0:2]), CoRoV_MSO_TMP   ;can only take one vector at a time.
      CoRoV_MSO[aa,*] = CoRoV_MSO_TMP
      cspice_mxv, tmatrix_sc[*,*,aa], transpose(CoRoV_iau[aa,0:2]), CoRoV_SC_TMP   ;can only take one vector at a time.
      CoRoV_SC[aa,*] = CoRoV_SC_TMP
    endfor  ;over aa

    ;Add in total vel vector here:
    CoRoV_MSO2 = dblarr(nele,4)
    CoRoV_SC2 = dblarr(nele,4)

    for aa = 0, 2 do CoRoV_MSO2[*,aa] = CoRoV_MSO[*,aa]  ;add in x,y,z
    CoRoV_MSO2[*,3] = sqrt(CoRoV_MSO2[*,0]^2 + CoRoV_MSO2[*,1]^2 + CoRoV_MSO2[*,2]^2)  ;total

    for aa = 0, 2 do CoRoV_SC2[*,aa] = CoRoV_SC[*,aa]  ;add in x,y,z
    CoRoV_SC2[*,3] = sqrt(CoRoV_SC2[*,0]^2 + CoRoV_SC2[*,1]^2 + CoRoV_SC2[*,2]^2)  ;total


      ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_mvn_CoRoV_SC', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'Mars co-rotation velocity in km/s in s/c frame, as computed from the IAU frame.', $
      ;'v_catdesc',                     'test dlimit file, v', $    ;###
      'dy_catdesc',                    'Error on the data.', $     ;###
      ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of km/s. IAU_MARS frame (areodetic): X points from center of Mars to 0 degrees east longitude and 0 degrees latitude; Y points from center of Mars to +90 degrees east longitude and 0 degrees latitude; Z completes the right handed system.' , $
    ;'v_Var_notes',                   'Frequency bins', $
    'dy_Var_notes',                  'Not used.', $
      ;'dv_Var_notes',                   'Error on frequency', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
    'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
      ; 'vFieldnam',                     'v: More information', $
      'dyFieldnam',                    'No used.', $
      ;  'dvFieldnam',                    'dv: More information', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(CoRoV_SC2), $
      'SCALEMAX', max(CoRoV_SC2), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Velocity [km/s, S/C frame]]');, $
    ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
    ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
    ;'zsubtitle'       ,     '[Attitude]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'CoRoV_SC'                 ,$
      'yrange' ,        [min(CoRoV_SC2, /nan), max(CoRoV_SC2, /nan)] ,$     ;range of orbit at Mars
      'ystyle'  ,       1.                       ,$
      'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
      'labflag',        1, $
      'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
      ;'ztitle' ,        'Z-title'                ,$
      ;'zrange' ,        [min(data.y),max(data.y)],$
      ;'spec'            ,     1, $
      ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_mvn_CoRoV_SC', data={x:unix_in, y:CoRoV_SC2, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------

    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'mvn_lpw_anc_mvn_CoRoV_IAU', $
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
      'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
      'y_catdesc',                     'Mars co-rotation velocity in km/s, in IAU frame.', $
      ;'v_catdesc',                     'test dlimit file, v', $    ;###
      'dy_catdesc',                    'Error on the data.', $     ;###
      ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
      'flag_catdesc',                  'Flag equals 1 when no SPICE times available.', $   ; ###
      'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
      'y_Var_notes',                   'Units of km/s. IAU_MARS frame (areodetic): X points from center of Mars to 0 degrees east longitude and 0 degrees latitude; Y points from center of Mars to +90 degrees east longitude and 0 degrees latitude; Z completes the right handed system.' , $
    ;'v_Var_notes',                   'Frequency bins', $
    'dy_Var_notes',                  'Not used.', $
      ;'dv_Var_notes',                   'Error on frequency', $
      'flag_Var_notes',                '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.', $
    'xFieldnam',                     'x: More information', $      ;###
      'yFieldnam',                     'y: 1 Mars radius = 3376.0 km.', $
      ; 'vFieldnam',                     'v: More information', $
      'dyFieldnam',                    'No used.', $
      ;  'dvFieldnam',                    'dv: More information', $
      'flagFieldnam',                  'flag: based off of SPICE ck and spk kernel coverage.', $
      'SI_conversion',                 '1 Mars radius = 3376.0 km',  $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(CoRoV_IAU), $
      'SCALEMAX', max(CoRoV_IAU), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     time_start, $
      'Time_end'        ,     time_end, $
      'Time_field'      ,     time_field, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     L0_datafile , $
      'cal_vers'        ,     kernel_version ,$
      'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'SPICE kernels', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Velocity [km/s, IAU frame]]');, $
    ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
    ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
    ;'zsubtitle'       ,     '[Attitude]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'CoRoV_IAU'                 ,$
      'yrange' ,        [min(CoRoV_IAU, /nan), max(CoRoV_IAU, /nan)] ,$     ;range of orbit at Mars
      'ystyle'  ,       1.                       ,$
      'labels',         ['X', 'Y', 'Z', 'TOTAL'], $
      'labflag',        1, $
      'colors',         [2, 4, 6, 0], $  ;blue, green, red, black
      ;'ztitle' ,        'Z-title'                ,$
      ;'zrange' ,        [min(data.y),max(data.y)],$
      ;'spec'            ,     1, $
      ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;---------------------------------
    store_data, 'mvn_lpw_anc_mvn_CoRoV_IAU', data={x:unix_in, y:CoRoV_IAU, flag:ck_spk_flag}, dlimit=dlimit, limit=limit
    ;---------------------------------

stop
  endif
endif

;========================================================

mvn_lpw_anc_boom_mars_shadow, unix_in   ;is MAVEN in Mars' shadow or not


;==============

if ~KEYWORD_SET(dont_unload) THEN mvn_lpw_anc_clear_spice_kernels ;Clear kernel_verified flag, jmm, 2015-02-11

;print, "==========================="
;print, "Routine finished"
;print, "==========================="
;stop
end
