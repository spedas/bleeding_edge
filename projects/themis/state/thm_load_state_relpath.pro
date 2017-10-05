;+
;NAME:
;thm_load_state_relpath
;PURPOSE:
;Alternate relpathname routine for L1 state data, allows for different
;relpath from SPDF directory with v0? in the final relpathname
;CALLING SEQUENCE:
;relpathnames = thm_load_state_relpath(sname = sname, filetype =
;                                      filetype, level = level, $
;                                      version = version, $
;                                      trange = trange, $
;                                      addmaster = addmaster)
;INPUT:
; sname = probe, one of ['a','b','c','d','e']
; filetype = 'state' -> this keyword is only defined here due to the
;            interface to thm_load_xxx
; level = 'l1'  -> this keyword is only defined here due to the
;            interface to thm_load_xxx
; version = '0','1','2','3' or '?' The default is to not have a
;           version number, and this keyword is not used
; trange = the timerange
; relpathnames_local = the fullpath of the file as it will be saved
;                      locally, this is an output keyword
;OUTPUT:
; relpathnames = the full path of the files relative to the local
;                and remote data directories.
;HISTORY:
; April 1, 2010, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: pcruce $
; $LastChangedDate: 2014-02-20 12:48:24 -0800 (Thu, 20 Feb 2014) $
; $LastChangedRevision: 14398 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/thm_load_state_relpath.pro $
;-
Function thm_load_state_relpath, sname = sname, filetype = filetype, $
                                 level = level, version = version, $
                                 trange = trange, addmaster = addmaster, $
                                 relpathnames_local = relpathnames_local, $
                                 _extra = _extra

If(keyword_set(sname)) Then snamei = sname[0] Else snamei = 'a'
ftj = 'state'
lvlk = 'l1'
relpath = 'th'+snamei+'/'+lvlk+'/'+ ftj+'/'
prefix = 'th'+snamei+'_'+lvlk+'_'+ftj+'_'
dir = 'YYYY/'

If(keyword_set(version)) Then Begin
  vversions = 'v00 v01 v02 v03'
  vers = thm_valid_input(version, 'Version', vinputs = vversions, $
                         definput = 'v03', format = "('v', I02)", $
                         verbose = verbose, no_download = no_download)
  ending = '_'+vers+'.cdf'
Endif Else ending = '.cdf'

;local relpathnames may be the same
relpathnames_local = file_dailynames(relpath, prefix, ending, dir = dir, $
                                     trange = trange, addmaster = addmaster)

;tweak for different relpath if loading state data from SPDF
If(!themis.remote_data_dir Eq 'http://cdaweb.gsfc.nasa.gov/istp_public/data/themis/') || $
  (!themis.remote_data_dir eq 'http://spdf.gsfc.nasa.gov/pub/data/themis/') then Begin
;    relpath = 'th'+snamei+'/or/'
    ending = '_v0?.cdf'
    relpathnames = file_dailynames(relpath, prefix, ending, dir = dir, $
                                   trange = trange, addmaster = addmaster)
Endif Else relpathnames = relpathnames_local

Return, relpathnames
End


