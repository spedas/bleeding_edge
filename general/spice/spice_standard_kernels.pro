;+
;NAME: SPICE_STANDARD_KERNELs
;USAGE:  files = spice_standard_kernels(/load)
;PURPOSE:
; Provides fully resolved standard spice kernel filenames. files are downloaded if needed.
; NOTE: this routine is in development still.
;
; NAIF specifies a few "standard" files that must typically be loaded in before for any calculations can be performed. These are:
;    Leap second kernel:   (naif????.tls)  Contains times of leap seconds.   ???? contains the version number and increments by 1 with every new leap second.
;    PCK kernel:           (pck?????.tpc)  Contains spin axis and size of most solar system bodies.
;    SPK kernel:           (de???.bsp)     Contains ephemeris data for the planets. Mars (499) is NOT included in most recent version!
;
; The file names and locations (and even contents) of these kernels is not standard and will change with each new release.
;
;CALLING SEQUENCE:
;  files=spice_standard_kernels(/load)
;KEYWORDS:
; LOAD:   Set keyword to retrieve and load file
;OUTPUT:
; fully qualified kernel filename(s)
;
; $LastChangedBy: ali $
; $LastChangedDate: 2021-03-04 22:17:43 -0800 (Thu, 04 Mar 2021) $
; $LastChangedRevision: 29738 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_standard_kernels.pro $
;-
function spice_standard_kernels,load=load,source=src,reset=reset,verbose=verbose,mars=mars,jupiter=jupiter,saturn=saturn,no_update=no_update
  common spice_standard_kernels_com, kernels,retrievetime,tranges
  if ~spice_test() then return,''
  if keyword_set(reset) then kernels=0
  ct = systime(1)
  waittime = -300.           ; always check      ; search no more often than this number of seconds
  if ~keyword_set(kernels) || (ct - retrievetime) gt waittime then begin     ;
    source = spice_file_source(src,verbose=verbose,no_update=no_update)   ; with no_update set to 1 the files are assumed correct if they exist.
    kernels=0
    rpath=source.remote_data_dir+'generic_kernels/'
    lpath=source.local_data_dir+'generic_kernels/'
    ;WARNING!!!!!  ALL FILE NAMES LISTED BELOW ARE SUBJECT TO CHANGE AND DO CHANGE REGULARLY
    ;https://naif.jpl.nasa.gov/pub/naif/generic_kernels/
    ;jmm, 2017-01-30, swapped out file_retrieve calls for spd_download
    append_array, kernels, spd_download_plus(remote_file=rpath+'lsk/naif00??.tls',local_path=lpath+'lsk/',/last_version, $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
    append_array, kernels, spd_download_plus(remote_file=rpath+'pck/pck000??.tpc',local_path=lpath+'pck/',/last_version, $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
    append_array, kernels, spd_download_plus(remote_file=rpath+'spk/planets/de440s.bsp',local_path=lpath+'spk/planets/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;de440s.bsp includes years 1849 to 2150, updated on 2020-12-20, most recent as of 2021-03-04
    if keyword_set(mars) then append_array, kernels, spd_download_plus(remote_file=rpath+'spk/satellites/mar097.bsp',local_path =lpath+'spk/satellites/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;mar097.bsp, updated on 2012-09-28, most recent as of 2021-03-04
    if keyword_set(jupiter) then append_array, kernels, spd_download_plus(remote_file=rpath+'spk/satellites/jup343.bsp',local_path =lpath+'spk/satellites/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;jup343.bsp, updated on 2020-03-06, most recent as of 2021-03-04
    if keyword_set(saturn) then append_array, kernels, spd_download_plus(remote_file=rpath+'spk/satellites/sat428.bsp',local_path =lpath+'spk/satellites/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;sat428.bsp, updated on 2019-10-30, most recent as of 2021-03-04
    retrievetime = ct
  endif
  if keyword_set(load) then spice_kernel_load, kernels, verbose=verbose
  return, kernels
end
