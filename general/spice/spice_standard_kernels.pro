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
;KEYWORDS:
;  MARS:   
; 
;CALLING SEQUENCE:
;  files=spice_standard_kernels(/load) 
;TYPICAL USAGE:
;INPUT:
;  none 
;KEYWORDS:
; LOAD:   Set keyword to retrieve and load file
;OUTPUT:
; fully qualified kernel filename(s)
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-05-11 00:00:35 -0700 (Sat, 11 May 2019) $
; $LastChangedRevision: 27221 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_standard_kernels.pro $
;-
function spice_standard_kernels,load=load,source=src,reset=reset,verbose=verbose,mars=mars,no_update=no_update
common spice_standard_kernels_com, kernels,retrievetime,tranges
if ~spice_test()  then return,''
if keyword_set(reset) then kernels=0
ct = systime(1)
waittime = -300.           ; always check      ; search no more often than this number of seconds
if ~keyword_set(kernels) || (ct - retrievetime) gt waittime then begin     ; 
    source = spice_file_source(src,verbose=verbose,no_update=no_update)   ; with no_update set to 1 the files are assumed correct if they exist.
;    sprg = mvn_file_source()
;    if not keyword_set(source) then source=naif
;    source.no_update =1      ;  Don't check for file if it exists
;    if keyword_set(verbose) then source.verbose=verbose
    kernels=0
;        WARNING!!!!!  ALL FILE NAMES LISTED BELOW ARE SUBJECT TO
;        CHANGE AND DO CHANGE REGULARLY
;    append_array,kernels,
; jmm, 2017-01-30, swapped out file_retrieve calls for spd_download
    append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'generic_kernels/lsk/naif00??.tls', $
                                             local_path = source.local_data_dir+'generic_kernels/lsk/', /last_version, $
                                             no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
    append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'generic_kernels/pck/pck00010.tpc', $
                                        local_path = source.local_data_dir+'generic_kernels/pck/', /last_version, $
                                        no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
;    append_array,kernels,  file_retrieve('generic_kernels/spk/planets/de421.bsp',_extra=source)   ; Now obsolete ....  No longer on NAIF site!
;    append_array,kernels,  file_retrieve('generic_kernels/spk/planets/a_old_versions/de421.bsp',_extra=source)   ; archived location of de421.bsp
    append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'generic_kernels/spk/planets/de435.bsp', $
                                        local_path = source.local_data_dir+'generic_kernels/spk/planets/', $
                                        no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
    if keyword_set(mars) then append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'generic_kernels/spk/satellites/mar097.bsp', $
                                                                  local_path = source.local_data_dir+'generic_kernels/spk/satellites/', $
                                                                  no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ; mar097.bsp is most recent as of 2014/1/1 ??    
    retrievetime = ct
;    kernels = file_search(kernels)
endif
if keyword_set(load) then spice_kernel_load, kernels, verbose=verbose
return, kernels
end
