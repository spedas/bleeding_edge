
;+
;Written 2014-10-20: CF: routine to get SPICE kernels for a certain time range using Davin's SPICE software. Routine places
;names of kernels into the tplot variable mvn_lpw_load_kernel_files, which is used by mvn_lpw_anc_spacecraft to get position etc.
;Added notatlasp keyword to disable server check, jmm, 2015-01-29
;
;INPUTS:
;utc_range: an array containing the times for which to search for SPICE kernels. Times can be double UNIX times, or string UTC times. The min and max values are fed into the SSL software
;           to search for SPICE kernels covering this time range.
;
;OUTPUTS:
;tplot variable containing the kernels, used by mvn_lpw_anc_spacecraft.pro, mvn_lpw_load_kernel_files
;
;KEYWORDS
;Set /notatlasp if you are not using the LASP /spg/maven server to store kernels. This means the IDL environment variable ROOT_DATA_DIR is NOT set to /spg/maven at LASP.
;
;Set /load to load SPICE kernels into IDL memory.
;
;
;
;NOTE: 
;
;
;EXAMPLE
;mvn_lpw_anc_get_spice_kernels, ['2014-10-10', '2014-10-11']  ;get SPICE kernels for the date '2014-10-10/00:00:00 up to 2014:10:10/23:59:59, ie 24 hours worth.
;mvn_lpw_anc_get_spice_kernels, [time_double('2014-10-10'), time_double('2014-10-11')]
;
;EDITS:
;2015-10-08: CMF added /load keyword.
;2015-11-09: CMF: modified routine to take an array of double or string times, and use the max/min values to send into the Berkeley routines.
;
;-
;

pro mvn_lpw_anc_get_spice_kernels, utc_range, notatlasp=notatlasp, load=load

proname = 'mvn_lpw_anc_get_spice_kernels'
sl = path_sep()

rd = getenv('ROOT_DATA_DIR')  ;root dir
;Check we're connecting to SPG, otherwise copies are saved on your machine:
IF ~keyword_set(notatlasp) && file_test(rd+'server_check'+sl+'lpw_server_check.rtf') EQ 0. THEN BEGIN
  print, "### WARNING ###: MAVEN data not detected. Are you connected to the right server?"
  print, "At LASP, this is the lds/spg/ server, assumed to be located at /Volumes/spg/ on a Mac."
  print, "If you are not at LASP, use the keyword '/notatlasp' to skip this check. See mvn_lpw_load.pro"
  print, "for more information. Returning."
  return
ENDIF

;Take min and max values from utc_range:
stype = size(utc_range,/type)

if stype eq 7 then begin   ;STRINGS entered
    unix_range = time_double(utc_range)
    minT = min(unix_range,/nan)
    maxT = max(unix_range,/nan)
endif
if stype eq 5 then begin  ;DOUBLE entered
    unix_range = utc_range
    minT = min(unix_range,/nan)
    maxT = max(unix_range,/nan)
endif
if stype ne 5 and stype ne 7 then begin
      print, proname, " : ### WARNING ### : utc_in must be a double precision array of UNIX times, or a string array of UTC times in the format yyyy-mm-dd/hh:mm:ss. Exiting."
      retall
endif

tt = mvn_spice_kernels(trange = [minT, maxT])
if keyword_set(load) then spice_kernel_load, tt   ;send in found SPICE kernels.

;tt contains the names of all SPICE kernels regardless of the type (ck, pck, lsk, etc). For now, we need ck, tls, spk, sclk. Remove files which
;don't contain any of these letters. Then, need to laod kernels in the correct order, which is tt[0] => tt[last].
nele_tt = n_elements(tt)  ;number of kernels found
kernels = ['remove_first_string_entry_later']     ;#####
for aa = 0, nele_tt - 1 do begin
  if (strpos(tt[aa], sl+'ck') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]]  ;look for the kernel type, and make sure there's no
  if (strpos(tt[aa], sl+'pck') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]] ;'_*_' in the name as this means not found. If present,
  if (strpos(tt[aa], sl+'lsk') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]] ;append to kernels.
  if (strpos(tt[aa], sl+'spk') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]]
  if (strpos(tt[aa], sl+'sclk') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]]
  if (strpos(tt[aa], sl+'fk') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]]
  if (strpos(tt[aa], 'maven_v04.tf') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]]  ;Davin has latest frame file at SSL
  ;### As .tf file is added manually by Davin, sl is for unix. Windows can use this for directories, but IDL can't match it when string searching
  ;so don't include here.
endfor

;Remove first entry of array kernels, as this was just a dummy to set up the array:
IF n_elements(kernels) GT 1 THEN BEGIN
  nele_k = n_elements(kernels)
  kernels = kernels[1:nele_k-1]  ;get all but first entry
ENDIF ELSE BEGIN
  print, "#### WARNING ####: No kernels found. Is date outside of MAVEN mission timeline?"
  return
ENDELSE


store_data, 'mvn_lpw_load_kernel_files', data={x:1., y:1.}, dlimit={Kernel_files: kernels, $
  Purpose: "Directories to kernel files needed for UTC date "+time_string(minT)+" - "+time_string(maxT), $
  Notes: "Load in order first entry to last entry to ensure correct coverage"}


end
