;+
;NAME: SPICE_STANDARD_KERNELS
;USAGE:  files = spice_standard_kernels(/load)
;PURPOSE:
; Provides fully resolved standard spice kernel filenames.  Files are downloaded as needed.
;
; WARNING: NAIF does not follow a strict file naming convention, so this routine cannot predict changes that
; might occur in the future.  Some kernel names are hard wired because there is no reliable alternative.
;
; NAIF specifies a few "standard" files that must typically be loaded before for any calculations can be performed.
; These are:
;    Leap second kernel   : naif????.tls  (times of leap seconds)
;    PCK kernel           : pck?????.tpc  (spin axes, sizes and shapes of many solar system bodies)
;    Planetary SPK kernel : de???.bsp     (ephemeris data for the planets)
;
; The planetary SPK kernel (de???.bsp) includes both the positions of the planetary centers of mass and the 
; positions of the planetary system barycenters (planet + satellites).  This can be an important difference for
; systems where the moon mass is a significant fraction of the primary mass, like the Pluto-Charon, Earth-Moon
; and Sun-Jupiter systems.  For Mars, the difference is negligible (~1 cm).  When using integer codes, the smallest
; positive integers are reserved for barycenters: 0 (SOLAR_SYSTEM_BARYCENTER), 1 (MERCURY_BARYCENTER), ...,
; while the planetary centers of mass are: 199 (MERCURY), 299 (VENUS), 399 (EARTH), 499 (MARS), ....  It's
; up to the user to determine which center is appropriate.
;
; As of July 2025, the latest planetary ephemeris is de442 (released 2025-02-06).  It spans from 1550 to 2650 and
; includes improvements for Mars, Jupiter and Uranus.  Sometimes (but not always!), short versions are provided,
; for example the de442s spans from 1850 to 2150.  Sometimes there are even long versions that span tens of
; thousands of years.  New versions are typically released every few years, but there's no regular cadence.  On
; the NAIF website (https://naif.jpl.nasa.gov/pub/naif/), look at the comment file ('tech-comments', '.cmt' or 
; '.mrg' file) to see the time span covered.  The hard-wired default here is de442.
;
; In addition, there are several optional planetary satellite ephemeris kernels:
;    Mars satellite SPK kernel    : mar???.bsp
;    Jupiter satellite SPK kernel : jup???.bsp
;    Saturn satellite SPK kernel  : sat???.bsp
;    Uranus satellite SPK kernel  : ura???.bsp
;    Neptune satellite SPK kernel : nep???.bsp
;    Pluto satellite SPK kernel   : plu???.bsp
;
; The Mars satellite kernel has long and short versions: mar099 (1600-2600) and mar099s (1995-2050).  The other
; satellite kernels have only one version.  The hard-wired default here is mar099.
;
; Jupiter, Saturn, Uranus and Neptune have many moons.  There are multiple satellite kernel files for each
; of these planets.  The hard-wired defaults here (jup365, sat441, ura182 and nep095) contain the largest moons.
; All of these files and their contents are subject to change without notice.  Caution!  Higher numbered versions
; of these satellite files are not necessarily updates but instead include a bunch of minor moons.
;
;CALLING SEQUENCE:
;  files = spice_standard_kernels(/load)
;
;KEYWORDS:
;  LOAD:       Set keyword to retrieve and load file
;  MARS:       Include satellites of Mars (Phobos and Deimos)
;  JUPITER:    Include largest satellites of Jupiter
;  SATURN:     Include largest satellites of Saturn
;  URANUS:     Include largest satellites of Uranus
;  NEPTUNE:    Include largest satellites of Neptune
;  PLUTO:      Include satellites of Pluto
;  SOURCE:     Passed to spice_file_source: overrides default file source
;  RESET:      Forces a reload of all standard kernels
;  VERBOSE:    Passed to spice_file_source and spice_kernel_load
;  NO_UPDATE:  Passed to spice_file_source: files are assumed to be correct if they exist
;
;MORE WORDS OF CAUTION:
;  It can matter what order you load kernels in.  The reason is that natural and artificial satellite
;  kernels as well as minor body kernels often attempt to be self contained by including kernels for one
;  or more planets.  This introduces overlap with the planetary spk (de442).  Which planet kernel
;  prevails?  The one that is loaded last.  For example, if you load the kernel for Comet Siding Spring, 
;  it will contain a snippet of the Mars kernel, superceding the much longer Mars kernel contained in the
;  de442.  To solve this, load the comet kernel first, then load the de442.  A similar situation occurs
;  with the Mars satellite kernel.  Currently, the mar099 and de442 kernels cover about the same time 
;  range, so the order doesn't matter much.  But someday it could.  This routine loads the de442 after
;  the satellite kernel(s).
;
;OUTPUT:
; fully qualified kernel filename(s)
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-07-14 11:23:09 -0700 (Mon, 14 Jul 2025) $
; $LastChangedRevision: 33460 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_standard_kernels.pro $
;-
function spice_standard_kernels,load=load,source=src,reset=reset,verbose=verbose,mars=mars,jupiter=jupiter,$
           saturn=saturn,uranus=uranus,neptune=neptune,pluto=pluto,no_update=no_update
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
    if keyword_set(mars) then append_array, kernels, spd_download_plus(remote_file=rpath+'spk/satellites/mar099.bsp',local_path =lpath+'spk/satellites/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;mar099.bsp includes years 1600 to 2600, updated on 2025-06-02
    if keyword_set(jupiter) then append_array, kernels, spd_download_plus(remote_file=rpath+'spk/satellites/jup365.bsp',local_path =lpath+'spk/satellites/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;jup365.bsp includes years 1600 to 2200, updated on 2021-03-14
    if keyword_set(saturn) then append_array, kernels, spd_download_plus(remote_file=rpath+'spk/satellites/sat441.bsp',local_path =lpath+'spk/satellites/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;sat441.bsp includes years 1750 to 2250, updated on 2022-01-29
    if keyword_set(uranus) then append_array, kernels, spd_download_plus(remote_file=rpath+'spk/satellites/ura182.bsp',local_path =lpath+'spk/satellites/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;ura182.bsp includes years 1550 to 2650, updated on 2025-02-06
    if keyword_set(neptune) then append_array, kernels, spd_download_plus(remote_file=rpath+'spk/satellites/nep095.bsp',local_path =lpath+'spk/satellites/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;nep095.bsp includes years 1900 to 2050, updated on 2020-08-05
    if keyword_set(pluto) then append_array, kernels, spd_download_plus(remote_file=rpath+'spk/satellites/plu060.bsp',local_path =lpath+'spk/satellites/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;plu060.bsp includes years 1800 to 2200, updated on 2024-04-03
    append_array, kernels, spd_download_plus(remote_file=rpath+'spk/planets/de442.bsp',local_path=lpath+'spk/planets/', $
      no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o) ;de442.bsp includes years 1550 to 2650, updated on 2025-02-06
    retrievetime = ct
  endif
  if keyword_set(load) then spice_kernel_load, kernels, verbose=verbose
  return, kernels
end
