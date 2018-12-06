;+
; NAME:
;   rbsp_load_state (procedure)
;
; PURPOSE:
;   Load spacecraft state.
;
;   As of 10/29/12, valid data types are:
;     'pos'
;     'vel'
;     'spinper'
;     'spinphase'
;     'mat_dsc'
;     'umbra'
;   where:
;     'pos'('vel'): Spacecraft position(velocity). By default, the routine only
;           loads GSE coordinates. Set /get_support_data to load GSM coordinates
;           as well.
;     'spinper': Spacecraft spin period.
;     'spinphase': Spacecraft spin phase. Spin phase is defined as the angle of
;           the sun sensor with respect to the sun-pulse location (i.e., DSC x).
;     'mat_dsc': Rotation matrix in the form [N, 3, 3] between DSC and GSE. This
;           matrix should be near constant over an orbit.
;     'umbra': Loads eclipse umbra times and inward and outward penumbra
;           lengths.
;
;   MATRIX USE EXAMPLES IN IDL
;       Suppose mat_dsc is stored in 'rbsp_mat_dsc', and 'rbsp_vector_dsc' is a
;       vector in vector in DSC with array form [N,3]. Then the following code
;       will rotate 'rbsp_vector_dsc' into a vector in GSE, say,
;       'rbsp_vector_gse':
;           tvector_rotate, 'rbsp_mat_dsc', 'rbsp_vector_dsc', $
;             newname = 'rbsp_vector_gse'
;
;   If keyword get_support_data is set, GSM positon and velocity of the
;   spacecraft are obtained via cotrans, and the Xgse, Ygse, and Zgse unit
;   vectors in DSC are extracted from mat_dsc.

;   Tips:
;       1. Set /no_update if no need to look for new files in the remote server
;           to increase speed.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_load_state, probe = probe, datatype = datatype, dt = dt, $
;     no_update = no_update, klist = klist, unload = unload, $
;     spice_only = spice_only, get_support_data = get_support_data, $
;     verbose = verbose, downloadonly = downloadonly, $
;     no_eclipse = no_eclipse, $
;     use_eph_predict = use_eph_predict, $
;     no_spice_load = no_spice_load
;
; ARGUMENTS:
;
; KEYWORDS:
;   probe: (In, optional) RBSP spacecraft names, either 'a', or 'b', or
;         ['a', 'b']. The default is ['a', 'b']
;   datatype: (In, optional) See above.
;   dt: (In, optional) Cadence in seconds of the loaded state data.
;         Default = 5.
;   /no_update: If set, will not check if the remote server has newer SPICE
;         kernels, and will use the local SPICE kernels.
;   klist: A named variable to return the loaded local spice kernels.
;   /unload: If set, will not unload the loaded SPICE kernels.
;         !!!Use this with caution.!!!
;   /spice_only: If set, will only load SPICE kernels, and will not load regular
;         tplot state data.
;   /get_support_data: See above.
;   verbose: IN, OPTIONAL
;         Verbose level for dprint. Default equals !rbsp_efw.verbose
;   /downloadonly:
;         If set, only download data, no processing.
;         Default equals !rbsp_efw.downloadonly
;   no_eclipse: OUT, OPTIONAL
;         A named variable to receive 1 or 0 for no/with eclipse.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;   sc = 'a'
;   timespan, '2012-10-16'
;   rbsp_load_state, probe = sc
;
; SEE ALSO:
;
; HISTORY:
;   2012-10-29: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-02: Initial release to TDAS. JBT, SSL/UCB.
;   2012-11-03: JBT, SSL/UCB.
;         1. Changed the behavior of keyword get_support_data. Eclipse times are
;             loaded by default now. The new behavior of get_support_data is to
;             get spacecraft GSM position and velocity, and extract Xgse, Ygse,
;             and Zgse in DSC from mat_dsc and save them into tplot.
;         2. Added keyword verbose.
;         3. Some minor improvements.
;   2012-11-03: JBT, SSL/UCB.
;         1. Changed *interpol* to *interp*
;   2012-11-23: JBT, SSL/UCB.
;         1. Added downloadonly keyword.
;   2013-01-27: JBT, SSL/UCB.
;         1. Restricted attitude files to be downloaded to be within +/- 3 days
;            of current time span.
;   2013-01-27: JBT, SSL/UCB.
;         1. Added no_eclipse keyword.
;   2013-04-04: JBT, SSL/UCB.
;         1. Added keyword *use_eph_predict*.
;         2. Added keyword *no_spice_load*.
;	2015-08-29:  JWB, UCB SSL.
;		1.  Changed behavior in loop over time calls to
;		CSPICE_CKGPAV() from returning without completion
;		to setting returned CMAT and AV to !VALUES.D_NAN (3x3
;		matrix and 3-array) and warning user.
;		This is a bit of a kludge to keep missing attitude
;		data from bombing STATE calls that
;		are only interested in POS and VEL, for example.
;		2.  Adjusted 'Lvec' TPLOT variable LABELS and COLOR
;		options to be consistent with other 3-vectors.
;   2015-09-22: jmm, Fixed bug for when only 1 attitude file is
;   available, added catch statement so that spice kernels can unload
;   if the program crashes in a CSPICE routine, changed predict
;   directory, and added logic to avoid full-mission downloads.
;   2015-09-29: jmm, More error checking, for attitude history files
;   which fails for pre IDL 8.
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2018-12-05 12:31:41 -0800 (Wed, 05 Dec 2018) $
; $LastChangedRevision: 26251 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/spacecraft/rbsp_load_state.pro $
;
;-

;-------------------------------------------------------------------------------
function rbsp_load_state_get_attitude_filelist, remote_dir, localdir = localdir
compile_opt idl2, HIDDEN

urls =  remote_dir + '*.ath.bc'
spd_download_expand,urls

;urls = jbt_fileurls(remote_dir, verbose = 0, localdir = localdir)
fnames = file_basename(urls)




years = long(strmid(fnames, 6, 4))
doys  = long(strmid(fnames, 11, 3))
versions = long(strmid(fnames, 15, 2))

jdays = julday(1, 1, years) + doys - 1L
order = sort(jdays)
jdays = jdays[order]
; flist = flist[order]
fnames = fnames[order]
versions = versions[order]

; Restrict to data +/- 3 days of current time span.
tspan = timerange()
jday_sta = jbt_date2jday(strmid(time_string(tspan[0]+10),0,10)) - 3L
jday_end = jbt_date2jday(strmid(time_string(tspan[1]-10),0,10)) + 3L

; Trim file list.
ind = where(jdays ge jday_sta and jdays le jday_end, nind)

If(nind Eq 0) Then Begin ;jmm, 2015-09-29 ind = -1 fails for IDL 7.1
   dprint, verbose = verbose, 'No attitude files found within plus or minus 3 days, using last file'
   print, time_string(tspan)
   ind = n_elements(jdays)-1
   nind = 1
Endif

jdays = jdays[ind]
; flist = flist[ind]
fnames = fnames[ind]
versions = versions[ind]

ind_uniq = uniq(jdays)
; nfile = n_elements(flist)
nfile = n_elements(fnames)

If(n_elements(ind_uniq) Gt 1) Then Begin
   nversions = ind_uniq[1:*] - ind_uniq ; number of versions of each day
   nversions = [ind_uniq[0], nversions]
Endif Else nversions = ind_uniq[0]

n = n_elements(nversions)
klist = ['']
for i = 0L, n-1 do begin
  iend = ind_uniq[i]
  if i eq 0 then ista = 0 else ista = ind_uniq[i-1]+1
  v = versions[ista:iend]
  f = fnames[ista:iend]
  dum = max(v, imax)
  klist = [klist, f[imax]]
endfor

ind = where(strlen(klist) gt 0, nind)
If(nind Eq 0) Then Return, '' Else return, klist[ind]

end

;-------------------------------------------------------------------------------
pro rbsp_load_state_download_spice_probe_attitude, probe = probe

compile_opt idl2, HIDDEN
if ~keyword_set(probe) then probe = ['a', 'b']

; Determine remote and local data root dir.
datadir = !rbsp_efw.local_data_dir
datadir = expand_tilde(datadir)
serverdir = !rbsp_efw.remote_data_dir
localdir = datadir

; Determine individual spacecraft root dir
nsc = n_elements(probe)
scdirs = ['']
moc = 'MOC_data_products/'
for ip = 0, nsc - 1 do begin
  sc = probe[ip]
  scdirs = [scdirs, moc + strupcase('rbsp' + sc) + '/']
endfor
ind = where(strlen(scdirs) gt 0)
scdirs = scdirs[ind]

; Loop over spacecraft.
for ip = 0, nsc-1 do begin
  mocdir = scdirs[ip]
  remote_dir = serverdir + mocdir + 'attitude_history/'
  tmpdir = datadir + mocdir
  ; Retrieve file names for downloading
  fnames = rbsp_load_state_get_attitude_filelist(remote_dir, localdir = tmpdir)
  ; Loop over files to load.
;  nfile = n_elements(fnames)


;  fnames = remote_dir + '*.tf'
  spd_download_expand, fnames
  nfile = n_elements(fnames)


  for i = 0L, nfile-1 do begin
    fname = fnames[i]
    pathname = mocdir + 'attitude_history/' + fname

    undefine,lf,tns
    file_loaded = spd_download(remote_file=serverdir + pathname,$
      local_path=!rbsp_efw.local_data_dir+mocdir + 'attitude_history/',$
      local_file=lf,/last_version)

  endfor
endfor

end


;-------------------------------------------------------------------------------
pro rbsp_load_state_download_spice_probe, probe = probe

compile_opt idl2, HIDDEN
if ~keyword_set(probe) then probe = ['a', 'b']

datadir = !rbsp_efw.local_data_dir
datadir = expand_tilde(datadir)
serverdir = !rbsp_efw.remote_data_dir
localdir = datadir

nsc = n_elements(probe)
scdirs = ['']
moc = 'MOC_data_products/'
for ip = 0, nsc - 1 do begin
  sc = probe[ip]
  scdirs = [scdirs, moc + strupcase('rbsp' + sc) + '/']
endfor
ind = where(strlen(scdirs) gt 0)
scdirs = scdirs[ind]

; subdirs = ['attitude_history' $
;   , 'ephemerides' $
;   , 'eclipse_predict' $
;   , 'frame_kernel' $
;   , 'leap_second_kernel' $
;   , 'operations_sclk_kernel' $
;   , 'planetary_ephemeris' $
;   ] + '/'

rbsp_load_state_download_spice_probe_attitude, probe = probe

subdirs = ['ephemerides' $
  , 'ephemeris_predict_longterm' $
  , 'eclipse_predict' $
  , 'frame_kernel' $
  , 'leap_second_kernel' $
  , 'operations_sclk_kernel' $
  , 'planetary_ephemeris' $
  ] + '/'
nsub = n_elements(subdirs)
for ip = 0, nsc-1 do begin
  sc = probe[ip]
  mocdir = scdirs[ip]


  filetags = ['*deph.bsp','*peph_longterm.bsp','*pecl','*tf','*tls','*tsc','*bsp']

  for k = 0, nsub - 1 do begin
    subdir = subdirs[k]
    remote_dir = serverdir + mocdir + subdir
    tmpdir = datadir + mocdir


    urls =  remote_dir + filetags[k]
    spd_download_expand,urls
    fnamesk = file_basename(urls)

    nfile = n_elements(fnamesk)


;Here add some logic so that you don't need to download the
;full mission. For each kernel, this just mirrors the
;load_state_*_kernel logic
    case subdir of
       'leap_second_kernel/': fnames = rbsp_load_state_lsk_kernel(sc, files_in=fnamesk)
       'operations_sclk_kernel/': fnames = rbsp_load_state_sclk_kernel(sc, files_in=fnamesk)
       'ephemerides/':fnames = rbsp_load_state_eph_kernel(sc, files_in=fnamesk)
       'ephemeris_predict_longterm/':fnames = rbsp_load_state_eph_predict_kernel(sc, files_in=fnamesk)
       'eclipse_predict/':Begin
          ;this will return the full file path,
          ;this is needed so that the eventual call
          ;to rbsp_load_state_eclipse_time does
          ;not fail , jmm 2017-03-31
          ;so use file_basename to strip the path out here
          fnames = rbsp_load_state_eclipse_time_files(sc, files_in=fnamesk)
          fnames = file_basename(fnames)
       End
       Else:fnames = fnamesk
    Endcase
    If(~is_string(fnames)) Then continue
      spd_download_expand, fnames

    nfile = n_elements(fnames)
    for i = 0L, nfile-1 do begin
      fname = fnames[i]
      pathname = mocdir + subdir + fname


      undefine,lf,tns
      file_loaded = spd_download(remote_file=serverdir+pathname,$
        local_path=localdir+mocdir + subdir,$
        local_file=lf,/last_version)


    endfor
  endfor
endfor

end

;-------------------------------------------------------------------------------
pro rbsp_load_state_download_spice_general

compile_opt idl2, HIDDEN

datadir = !rbsp_efw.local_data_dir
datadir = expand_tilde(datadir)
serverdir = !rbsp_efw.remote_data_dir
localdir = datadir

spicedir = 'teams/spice/'

subdirs = ['fk/', 'ik/', 'pck/']
filetags = ['*.tf','*.ti','*.tpc']

nsub = n_elements(subdirs)
for k = 0, nsub - 1 do begin
  subdir = subdirs[k]
  remote_dir = serverdir + spicedir + subdir
  tmpdir = datadir + spicedir
;  urls = jbt_fileurls(remote_dir, verbose = 0, localdir = tmpdir)
;  fnames = file_basename(urls)
;  nfile = n_elements(fnames)
  fnames = remote_dir + filetags[k]


  spd_download_expand, fnames
  nfile = n_elements(fnames)

  for i = 0L, nfile-1 do begin
    fname = fnames[i]
    ;pathname = spicedir + subdir + fname

    undefine,lf,tns
    file_loaded = spd_download(remote_file=fname,$
      local_path=!rbsp_efw.local_data_dir+spicedir+subdir,$
      local_file=lf,/last_version)

  endfor
endfor

end

;-------------------------------------------------------------------------------
;jmm, 2015-09-22 Added files_in so that URLS can be passed
function rbsp_load_state_lsk_kernel, sc, files_in = files_in

compile_opt idl2, HIDDEN

If(keyword_set(files_in)) Then flist = files_in Else Begin
   datadir = !rbsp_efw.local_data_dir
   datadir = expand_tilde(datadir)
   sep = path_sep()

   moc = 'MOC_data_products' + sep

   LSK = 'leap_second_kernel' + sep
   dir = datadir + moc + strupcase('rbsp' + sc) + sep + LSK
   flist = file_search(dir, 'naif*')
Endelse

fnames = file_basename(flist)
day_number = long(strmid(fnames, 4, 4))
dum = max(day_number, imax)

return, flist[imax]

end

;-------------------------------------------------------------------------------
function rbsp_load_state_general_kernels, sc

compile_opt idl2, HIDDEN

datadir = !rbsp_efw.local_data_dir
datadir = expand_tilde(datadir)
sep = path_sep()

moc = datadir + 'MOC_data_products' + sep
spice = datadir + 'teams' + sep + 'spice' + sep
fk_dir = spice + 'fk' + sep
ik_dir = spice + 'ik' + sep
pck_dir = spice + 'pck' + sep
frame = moc + strupcase('rbsp' + sc) + sep + 'frame_kernel' + sep
planet = moc + strupcase('rbsp' + sc) + sep + 'planetary_ephemeris' + sep

klist = ['']

; fk
dir = fk_dir
flist = file_search(dir, 'rbsp*')
fnames = file_basename(flist)
versions = long(strmid(fnames, 12, 3))
dum = max(versions, imax)
klist = [klist, flist[imax]]

; ik
klist = [klist, ik_dir + 'rbsp' + strlowcase(sc) + '_rps_v000.ti']

; pck
klist = [klist, jbt_file_latest(pck_dir)]

; frame_kernel
klist = [klist, jbt_file_latest(frame)]

; planetary_ephemeris
klist = [klist, jbt_file_latest(planet)]

ind = where(strlen(klist) gt 0)
return, klist[ind]

end

;-------------------------------------------------------------------------------
;jmm, 2015-09-22 Added files_in so that URLS can be passed
;New version, since files no longer contain the full mission, then
function rbsp_load_state_eph_kernel, sc, files_in = files_in

compile_opt idl2, HIDDEN

If(keyword_set(files_in)) Then flist = files_in Else Begin
   datadir = !rbsp_efw.local_data_dir
   datadir = expand_tilde(datadir)
   sep = path_sep()

   moc = datadir + 'MOC_data_products' + sep
   eph_dir = moc + strupcase('rbsp' + sc) + sep + 'ephemerides' + sep
   flist = file_search(eph_dir, 'rbsp*')
Endelse
fnames = file_basename(flist)

years0 = long(strmid(fnames, 6, 4))
doys0 = long(strmid(fnames, 11, 3))
jdays0 = julday(1, 1, years0) + doys0 - 1L

years = long(strmid(fnames, 15, 4))
doys  = long(strmid(fnames, 20, 3))
jdays = julday(1, 1, years) + doys - 1L

versions = long(strmid(fnames, 24, 2))

tspan = timerange()
jday_sta = jbt_date2jday(strmid(time_string(tspan[0]+10),0,10))
jday_end = jbt_date2jday(strmid(time_string(tspan[1]-10),0,10))

ssjd = where(jday_sta Ge jdays0 And jday_end Le jdays, nind)

If(nind Eq 0) Then Begin
   dprint, 'No good ephemeris file for input time range: Using last file'
   dprint, time_string(tspan)
   jday_max = max(jdays)
   ind = where(jdays eq jday_max, nind)
   v = versions[ind]
   f = flist[ind]
   dum = max(v, imax)
   return, f[imax]
Endif Else Begin
;use the last file for a given time range, jmm, 2016-04-29
   ind = max(ssjd)
   f = flist[ind]
   return, f
Endelse
end

;-------------------------------------------------------------------------------
;jmm, 2015-09-22 Added files_in so that URLS can be passed
function rbsp_load_state_eph_predict_kernel, sc, files_in = files_in

compile_opt idl2, HIDDEN

If(keyword_set(files_in)) Then flist = files_in Else Begin
   datadir = !rbsp_efw.local_data_dir
   datadir = expand_tilde(datadir)
   sep = path_sep()

   moc = datadir + 'MOC_data_products' + sep
   eph_dir = moc + strupcase('rbsp' + sc) + sep + 'ephemeris_predict_longterm' + sep

   flist = file_search(eph_dir, 'rbsp*')
Endelse
fnames = file_basename(flist)
years = long(strmid(fnames, 6, 4))
doys  = long(strmid(fnames, 11, 3))
versions = long(strmid(fnames, 15, 2))

jdays = julday(1, 1, years) + doys - 1L
jday_max = max(jdays)
ind = where(jdays eq jday_max, nind)
v = versions[ind]
f = flist[ind]
dum = max(v, imax)

return, f[imax]

end

;-------------------------------------------------------------------------------
function rbsp_load_state_att_kernels, sc

compile_opt idl2, HIDDEN

datadir = !rbsp_efw.local_data_dir
datadir = expand_tilde(datadir)
sep = path_sep()

moc = datadir + 'MOC_data_products' + sep
att_dir = moc + strupcase('rbsp' + sc) + sep + 'attitude_history' + sep

flist = file_search(att_dir, 'rbsp*')
fnames = file_basename(flist)
years = long(strmid(fnames, 6, 4))
doys  = long(strmid(fnames, 11, 3))
versions = long(strmid(fnames, 15, 2))

jdays = julday(1, 1, years) + doys - 1L
order = sort(jdays)
jdays = jdays[order]
flist = flist[order]
versions = versions[order]

; Restrict to data +/- 3 days of current time span.
tspan = timerange()
jday_sta = jbt_date2jday(strmid(time_string(tspan[0]+10),0,10)) - 3L
jday_end = jbt_date2jday(strmid(time_string(tspan[1]-10),0,10)) + 3L

ind = where(jdays ge jday_sta and jdays le jday_end, nind)
If(nind Eq 0) Then Begin ;jmm, 2015-09-29 ind = -1 fails for IDL 7.1
   dprint, verbose = verbose, 'No attitude files found within plus or minus 3 days, using last file'
   print, time_string(tspan)
   ind = n_elements(jdays)-1
   nind = 1
Endif

jdays = jdays[ind]
flist = flist[ind]
versions = versions[ind]

ind_uniq = uniq(jdays)
nfile = n_elements(flist)

If(n_elements(ind_uniq) Gt 1) Then Begin
   nversions = ind_uniq[1:*] - ind_uniq ; number of versions of each day
   nversions = [ind_uniq[0], nversions]
Endif Else nversions = ind_uniq[0]

n = n_elements(nversions)
klist = ['']
for i = 0L, n-1 do begin
  iend = ind_uniq[i]
  if i eq 0 then ista = 0 else ista = ind_uniq[i-1]+1
  v = versions[ista:iend]
  f = flist[ista:iend]
  dum = max(v, imax)
  klist = [klist, f[imax]]
endfor

ind = where(strlen(klist) gt 0, nind)
If(nind Gt 0) Then return, klist[ind] $
Else return, ''

end

;-------------------------------------------------------------------------------
;2015-09-22, jmm, Added files_in keyword so that URLS can be passed in
function rbsp_load_state_sclk_kernel, sc, files_in = files_In

compile_opt idl2, HIDDEN

If(keyword_set(files_in)) Then flist = files_in Else Begin
   datadir = !rbsp_efw.local_data_dir
   datadir = expand_tilde(datadir)
   sep = path_sep()
   moc = 'MOC_data_products' + sep

   SCLK = 'operations_sclk_kernel' + sep
   dir = datadir + moc + strupcase('rbsp' + sc) + sep + SCLK

; print, dir
   flist = file_search(dir, 'rbsp*')
Endelse
fnames = file_basename(flist)
day_number = long(strmid(fnames, 11, 4))
dum = max(day_number, imax)

return, flist[imax]

end

;-------------------------------------------------------------------------------
function rbsp_load_state_spice_kernel_list, probe = probe, $
  use_eph_predict = use_eph_predict

compile_opt idl2, HIDDEN

if ~keyword_set(probe) then probe = ['a', 'b']

datadir = !rbsp_efw.local_data_dir
datadir = expand_tilde(datadir)
sep = path_sep()
moc = 'MOC_data_products' + sep
spice = 'teams' + sep + 'spice' + sep

nsc = n_elements(probe)
klist = ['']
for ip = 0, nsc - 1 do begin
  sc = probe[ip]
  if ~keyword_set(use_eph_predict) then begin
    klist = [klist $
      , rbsp_load_state_lsk_kernel(sc) $
      , rbsp_load_state_sclk_kernel(sc) $
      , rbsp_load_state_general_kernels(sc) $
      , rbsp_load_state_att_kernels(sc) $
      , rbsp_load_state_eph_kernel(sc) $
      ]
  endif else begin
    klist = [klist $
      , rbsp_load_state_lsk_kernel(sc) $
      , rbsp_load_state_sclk_kernel(sc) $
      , rbsp_load_state_general_kernels(sc) $
      , rbsp_load_state_att_kernels(sc) $
      , rbsp_load_state_eph_predict_kernel(sc) $
      ]
  endelse
endfor

ind = where(strlen(klist) gt 0, nind)
klist = klist[ind]

; Expand klist.
nk = n_elements(klist)
for i = 0L, nk - 1 do klist[i] = file_expand_path(klist[i])

return, klist

end

;-------------------------------------------------------------------------------
pro rbsp_load_state_load_spice, probe = probe, no_update = no_update, $
  klist = klist, downloadonly = downloadonly, $
  use_eph_predict = use_eph_predict

compile_opt idl2, HIDDEN

if ~keyword_set(probe) then probe = ['a','b']

if ~keyword_set(no_update) then begin
  rbsp_load_state_download_spice_general
  rbsp_load_state_download_spice_probe, probe = probe
endif

if keyword_set(downloadonly) then return
klist = rbsp_load_state_spice_kernel_list(probe = probe, $
  use_eph_predict = use_eph_predict)

dprint, 'Loading the following SPICE kernels:'
pm, klist

cspice_furnsh, klist
end

;-------------------------------------------------------------------------------
;2015-09-22, jmm, Added files_in keyword so that URLS can be passed in
function rbsp_load_state_eclipse_time_files, sc, files_in=files_in
compile_opt idl2, HIDDEN
; dprint, 'Hello world.'
datadir = !rbsp_efw.local_data_dir
datadir = expand_tilde(datadir)
sep = path_sep()
moc = datadir + 'MOC_data_products' + sep
ecl_dir = moc + strupcase('rbsp' + sc) + sep + 'eclipse_predict' + sep

If(keyword_set(files_in)) Then Begin
   all_ecl_files = file_basename(files_in)
Endif Else Begin
; Get all names of eclipse time files.
   all_ecl_files = file_basename(file_search(ecl_dir, 'rbsp*'))
; print, 'All eclipse time files (before stregex):'
; pm, all_ecl_files
Endelse
reg = '^rbsp' + strlowcase(sc) + '_201[0-9]{1}_[0-9]{3}_[0-9]{2}'
ind = where(stregex(all_ecl_files, reg, /bool))
all_ecl_files = all_ecl_files[ind]
; print, 'All eclipse time files:'
; pm, all_ecl_files

; Extract day-of-year numbers
tmp = stregex(all_ecl_files, '201[0-9]{1}_[0-9]{3}_[0-9]{2}', /extract)
years = long(strmid(tmp, 0, 4))
doys = long(strmid(tmp, 5, 3))
versions = long(strmid(tmp, 9, 2))
jdays = julday(1, 1, years) + doys - 1
; help, jdays

; Determine the days of tplot time span.
tspan = timerange() + [10, -10.]
days = (tspan[1] - tspan[0])/(24d * 3600d) + 1

; Get files
files = ['']
for i = 0L, days - 1 do begin
  time = tspan[0] + i * 24d * 3600d
  date = strmid(time_string(time), 0, 10)
  jday = jbt_date2jday(date)
  ind = where(jdays lt jday, nind)
  if nind eq 0 then begin
    dprint, 'No eclipse file available. Something is off.'
    Return, ''
  endif
  ; Find doy
  itmp = ind[nind-1]
  doy = doys[itmp]
  ind = where(doys eq doy, nind)
  if nind gt 1 then begin
    ; Compare versions
    v = versions[ind]
    dum = max(v, imax)
    file = all_ecl_files[ind[imax]]
  endif else file = all_ecl_files[ind[0]]
  files = [files, file]
endfor

ind = where(strlen(files) gt 0)
files = files[ind]
ind = uniq(files)
files = files[ind]

return, ecl_dir+files

end

;-------------------------------------------------------------------------------
function rbsp_load_state_eclipse_str2time, subitems
compile_opt idl2, HIDDEN
  day = subitems[0]
  month = subitems[1]
  year = subitems[2]
  time_str = subitems[3]
  if strcmp(strmid(month, 0, 3), 'Jan', /fold) then mm = '01'
  if strcmp(strmid(month, 0, 3), 'Feb', /fold) then mm = '02'
  if strcmp(strmid(month, 0, 3), 'Mar', /fold) then mm = '03'
  if strcmp(strmid(month, 0, 3), 'Apr', /fold) then mm = '04'
  if strcmp(strmid(month, 0, 3), 'May', /fold) then mm = '05'
  if strcmp(strmid(month, 0, 3), 'Jun', /fold) then mm = '06'
  if strcmp(strmid(month, 0, 3), 'Jul', /fold) then mm = '07'
  if strcmp(strmid(month, 0, 3), 'Aug', /fold) then mm = '08'
  if strcmp(strmid(month, 0, 3), 'Sep', /fold) then mm = '09'
  if strcmp(strmid(month, 0, 3), 'Oct', /fold) then mm = '10'
  if strcmp(strmid(month, 0, 3), 'Nov', /fold) then mm = '11'
  if strcmp(strmid(month, 0, 3), 'Dec', /fold) then mm = '12'
  str = year + '-' + mm + '-' + day + '/' + time_str
  return, time_double(str)
end


;-------------------------------------------------------------------------------
pro rbsp_load_state_parse_eclipse_time_file, file, sc, $
  umbra_sta, umbra_end, in_penumbra_len, out_penumbra_len, $
  no_eclipse = no_eclipse
compile_opt idl2, HIDDEN
; dprint, 'Hello world.'
; umbra_time: arrays of umbra starting and ending times
; penumbra_length: arrays of penumbra length associated umbra_time
; umbra_inout: indicators of in and out of umbra times. 1 for in, 2 for out

no_eclipse = 0

; print, file
lines = jbt_get_lines(file)
nline = n_elements(lines)

; Find starting line index
ind = where(strmatch(lines, '*------------------------*'))
ista = ind[0] + 1

iline = ista
nitem = 13
while iline lt nline do begin
  line = lines[iline]
;   print, line
  items = strsplit(line, /extract)
;   print, 'Item list:'
;   pm, string(indgen(13)) + '; ' + items
;   stop
  if n_elements(items) ne 13 then begin
    iline++
    continue
  endif
  if n_elements(orbit_ids) eq 0 then begin
    orbit_ids = long(items[0])
    start_times = rbsp_load_state_eclipse_str2time(items[1:4])
    end_times = rbsp_load_state_eclipse_str2time(items[5:8])
    tlens = double(items[9])
    types = items[11]
  endif else begin
    orbit_ids = [orbit_ids, long(items[0])]
    start_times = [start_times, rbsp_load_state_eclipse_str2time(items[1:4])]
    end_times = [end_times, rbsp_load_state_eclipse_str2time(items[5:8])]
    tlens = [tlens, double(items[9])]
    types = [types, items[11]]
  endelse

  iline++

endwhile

if n_elements(types) eq 0 then begin
  no_eclipse = 1
  dprint, 'No eclipse in the current time span.'
  return
endif

ind_umbra = where(strcmp(types, 'Umbra', /fold), nind)
if nind eq 0 then begin
;   dprint, 'No umbra in the file. Something is off.'
;   stop
  no_eclipse = 1
  dprint, 'No umbra in the current time span.'
  return
endif

n_type = n_elements(types)
umbra_sta = start_times[ind_umbra]
umbra_end = end_times[ind_umbra]
in_penumbra_len = umbra_sta
out_penumbra_len = umbra_sta
ind = ind_umbra
for i = 0, nind -1 do begin
  if ind[i] eq 0 then in_penumbra_len[i] = !values.f_nan $
    else in_penumbra_len[i] = tlens[ind[i]-1]
  if ind[i] eq n_type-1 then out_penumbra_len[i] = !values.f_nan $
    else out_penumbra_len[i] = tlens[ind[i]+1]
;   if out_penumbra_len[i] gt 100 then stop
endfor

; in_penumbra_len = interpol(in_penumbra_len, dindgen(nind), $
;   dindgen(nind), /nan)
; out_penumbra_len = interpol(out_penumbra_len, dindgen(nind), $
;   dindgen(nind), /nan)
in_penumbra_len = interp(in_penumbra_len, dindgen(nind), $
  dindgen(nind), /ignore_nan)
out_penumbra_len = interp(out_penumbra_len, dindgen(nind), $
  dindgen(nind), /ignore_nan)

; Remove moon penumbras
in_penumbra_len = thm_lsp_median_smooth(in_penumbra_len, 7)
out_penumbra_len = thm_lsp_median_smooth(out_penumbra_len, 7)
umbra_len = umbra_end - umbra_sta

; stop
;
; help, in_penumbra_len
; help, out_penumbra_len
; help, umbra_sta
; help, umbra_end
;
; plot, in_penumbra_len
; plot, out_penumbra_len
; plot, umbra_len
;
end



;-------------------------------------------------------------------------------
pro rbsp_load_state_load_eclipse_time, probe = probe, $
  no_eclipse = no_eclipse
compile_opt idl2, HIDDEN

; dprint, 'Hello world.'

tspan = timerange()
nsc = n_elements(probe)

; Loop over spacecraft.
for ip = 0, nsc-1 do begin
  sc = strlowcase(probe[ip])
  rbx = 'rbsp' + sc + '_'

; Locate the eclipse time file. This assumes that the correct file is availabe
; on the local disk if there is one.
  files = rbsp_load_state_eclipse_time_files(sc)
;   dprint, 'Eclipse time files:'
;   help, files
;   pm, files
;   stop


  ; Loop over files
  nfile = n_elements(files)
  for i = 0, nfile-1 do begin
    file = files[i]
  ; Parse the eclipse time file, and return umbra times as tplot x, and penumbra
  ; times as tplot y.
    rbsp_load_state_parse_eclipse_time_file, file, sc, $
            umbra_sta, umbra_end, in_penumbra_len, out_penumbra_len, $
            no_eclipse = no_eclipse
    if no_eclipse gt 0 then continue
  ; Assemble umbra times and penumbra lengths for each spacecraft.
    if n_elements(umbra_sta_all) eq 0 then begin
      umbra_sta_all = umbra_sta
      umbra_end_all = umbra_end
      in_penumbra_len_all = in_penumbra_len
      out_penumbra_len_all = out_penumbra_len
    endif else begin
      umbra_sta_all        = [umbra_sta_all        , umbra_sta]
      umbra_end_all        = [umbra_end_all        , umbra_end]
      in_penumbra_len_all  = [in_penumbra_len_all  , in_penumbra_len]
      out_penumbra_len_all = [out_penumbra_len_all , out_penumbra_len]
    endelse
  endfor


  ; Save umbra times and penumbra lengths into tplot variable
  if n_elements(umbra_end_all) eq 0 or n_elements(umbra_sta_all) eq 0 then $
    continue
  ind = where(umbra_end_all gt tspan[0] and umbra_sta_all lt tspan[1], nind)
  if nind eq 0 then continue
  umbra_sta = umbra_sta_all[ind]
  umbra_end = umbra_end_all[ind]
  in_penumbra_len = in_penumbra_len_all[ind]
  out_penumbra_len = out_penumbra_len_all[ind]

  att = {units:'s'}
  dl = {data_att:att, ysubtitle:'[s]', psym:1}

  store_data, rbx + 'umbra_sta', data = {x:umbra_sta, y:in_penumbra_len}, $
    dlim = dl
  options, rbx + 'umbra_sta', colors = [2], labels=['sta']

  store_data, rbx + 'umbra_end', data = {x:umbra_end, y:out_penumbra_len}, $
    dlim = dl
  options, rbx + 'umbra_end', colors = [6], labels=['end']

  store_data, rbx + 'umbra', data = rbx + 'umbra_' + ['end', 'sta']
  options, rbx + 'umbra', labflag = 1

endfor
end

;-------------------------------------------------------------------------------
function rbsp_load_state_smooth_mat_dsc, mat_dsc
compile_opt idl2, hidden
  nsm = 1000
  for i = 0, 2 do $
    for j = 0, 2 do $
      mat_dsc[*,i,j] = smooth(mat_dsc[*,i,j], nsm, /edge_truncate)
  return, mat_dsc
end

;-------------------------------------------------------------------------------
pro rbsp_load_state, probe = probe, datatype = datatype, dt = dt, $
  no_update = no_update, klist = klist, unload = unload, $
  spice_only = spice_only, get_support_data = get_support_data, $
  verbose = verbose, downloadonly = downloadonly, $
  no_eclipse = no_eclipse, $
  use_eph_predict = use_eph_predict, $
  no_spice_load = no_spice_load

compile_opt idl2

;Catch errors here so that spice kernels can be unloaded
err = 0
catch, err
If(err Ne 0) Then Begin
   catch, /cancel
   dprint, 'Error'
   help, /last_message, output = err_msg
   For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
;Unload any open spice kernels
   If(is_string(klist)) Then Begin
      dprint, 'Unloading SPICE kernels...'
      cspice_unload, klist
   Endif
   Return
Endif

; if ~keyword_set(datatype) then datatype = ['pos', 'vel', 'spinper', $
;   'spinphase', 'mat_dsc', 'mat_xyz']
if ~keyword_set(datatype) then datatype = ['pos', 'vel', 'spinper', $
  'spinphase', 'mat_dsc', 'umbra', 'Lvec']
if ~keyword_set(probe) then probe = ['a', 'b']
if n_elements(dt) ne 1 then dt = 5.
if n_elements(unload) eq 0 then unload = 1

rbsp_efw_init
if n_elements(no_update) eq 0 then no_update = !rbsp_efw.no_download
if n_elements(downloadonly) eq 0 then downloadonly = !rbsp_efw.downloadonly

if dt lt 0.1 then begin
  dprint, 'dt is small. You can now have a long cup of coffee, take a walk, '
  print, " and don't be surprised if the loading is not over yet " + $
    'when you come back.'
endif

tspan = timerange()
; dsta = strmid(time_string(tspan[0]+10.), 0, 10)
; dend = strmid(time_string(tspan[1]-10.), 0, 10)
; days = (time_double(dend) - time_double(dsta) )/(24d * 3600d) + 1
; tsta = time_double(dsta)
tlen = tspan[1] - tspan[0]
ntimes = ceil(tlen / dt)
time = tspan[0] + dindgen(ntimes) * dt

; Load SPICE
if ~keyword_set(no_spice_load) then begin
  dprint, verbose = verbose, 'Loading SPICE...'
  rbsp_load_state_load_spice, probe = probe, no_update = no_update, $
    klist = klist, downloadonly = downloadonly, $
    use_eph_predict = use_eph_predict
  if keyword_set(downloadonly) then return
endif

; Load eclipse time
; dprint, verbose = verbose, 'Loading eclipse times...'
; rbsp_load_state_load_eclipse_time, probe = probe
; return

; Only load spice kernels
if keyword_set(spice_only) then return

; Set up time array for SPICE
time_str=time_string(time, prec=3) ; turn it back into a string for
                                   ; ISO conversion
strput,time_str,'T',10 ; convert TPLOT time string 'yyyy-mm-dd/hh:mm:ss.msec'
                       ; to ISO 'yyyy-mm-ddThh:mm:ss.msec'
cspice_str2et,time_str,et ; convert ISO time string to SPICE ET

ntype = n_elements(datatype)
nsc = n_elements(probe)

; Loop over spacecraft.
for ip = 0, nsc-1 do begin
  sc = probe[ip]
  rbx = 'rbsp' + sc + '_'
  spice_str_id = 'RBSP_' + strupcase(sc)
  spice_str_id =spice_str_id[0]  ; convert to scalar
  spice_num_id = -long(byte(strlowcase(sc))) - 265 ; -362 for 'a', -363 for 'b'
  spice_num_id = spice_num_id[0] ; convert to scalar
  inst = spice_num_id * 1000L
;   id_a= -362
;   id_b=-363
;   print, spice_str_id
;   print, spice_num_id

  ; Get positions and velocities in GSE
  cspice_spkezr, spice_str_id, et,'GSE', 'NONE','EARTH', posvel, ltime
  pgse=transpose(posvel[0:2,*])
  vgse=transpose(posvel[3:5,*])

  ; Get attitude, spin period, and spin phase.
  ;-- Convert et to encoded sclk
  cspice_sce2c, spice_num_id[0], et, sclkdp

  ;-- Get sun positions
;   thm_load_slp, verbose = 0
;   cotrans, 'slp_sun_pos', 'slp_sun_pos_gse', /gei2gse
;   get_data, 'slp_sun_pos_gse', data = d
;   xs = interp(d.y[*,0], d.x, time, /ignore_nan)
;   ys = interp(d.y[*,1], d.x, time, /ignore_nan)
;   zs = interp(d.y[*,2], d.x, time, /ignore_nan)
  xs = 149598261d + time * 0d
  ys = time * 0d
  zs = time * 0d


;   stop
  store_data, 'slp_*', /del, verbose = 0

  ;-- Get spacecraft-to-sun unit vector
  x2 = pgse[*,0]
  y2 = pgse[*,1]
  z2 = pgse[*,2]
  us = [[xs-x2], [ys-y2], [zs-z2]]
  absus = sqrt(total(us^2,2))
  us[*,0] = us[*,0]  / absus
  us[*,1] = us[*,1]  / absus
  us[*,2] = us[*,2]  / absus

  ;-- SPICE guts
  mat_dsc = fltarr(ntimes, 3, 3) ; DSC to GSE matrix
  mat_xyz = fltarr(ntimes, 3, 3) ; XYZ to GSE matrix
  xdsc = fltarr(ntimes, 3) ; DSC x in the spacecraft XYZ coordinates
  per = dblarr(ntimes)  ; Spin period
  Lvec = dblarr(ntimes, 3)  ; Spin angular momentum direction
  some_not_found = 0
  for i = 0L, ntimes - 1 do begin
;     toltics = 100d
;     toltics = 0d
;     cspice_ckgpav, inst, sclkdp[i], toltics, 'GSE', cmat, av, clkout, found

    cspice_ckgpav, inst, sclkdp[i], 0d, 'GSE', cmat, av, clkout, found

    ;stop
    if found le 0 then begin
       some_not_found++
       cmat = !values.d_nan*[ [ 1., 1., 1.], [ 1., 1., 1.], [ 1., 1., 1.]]
       av = !values.d_nan*[ 1., 1., 1.]
      ;return
    endif
;     dprint, 'found = ', found
;     stop
    mat_xyz[i,*,*] = cmat
    per[i] = 2d * !dpi / sqrt(total(av^2))
    Lvec[i, *] = av / sqrt(total(av^2))

    u_sun = reform(us[i, *])  ; sun-pointing unit vector in GSE
    u_axb = reform(cmat[*,2]) ; spin angular momentum unit vector in GSE
    tmp = crossp(u_axb, u_sun)
    tmp = tmp / sqrt(total(tmp^2))  ; normalization
    u_ss = crossp(tmp, u_axb)  ; sun-sensor pulse view unit vector in GSE
    xdsc[i,*] = cmat ## transpose(u_ss)
    ydsc_gse = crossp(u_axb, u_ss)  ; DSC y in GSE
    mat_dsc[i,*,*] = [[u_ss], [ydsc_gse], [u_axb]]

;     print, 'x: ', reform(mat_dsc[i,*,*]) ## transpose(u_ss)
;     print, 'y: ', reform(mat_dsc[i,*,*]) ## transpose(ydsc_gse)
;     print, 'z: ', reform(mat_dsc[i,*,*]) ## transpose(u_axb)

;     stop
  endfor
  If(some_not_found Gt 0) Then Begin
    dprint, string(some_not_found, $
                   format='("WARNING:  Spacecraft pointing matrix not found for ", I," times.  Attitude products will be NaN (CMAT and AV set to NaN).")')
  Endif

  x = xdsc[*,0]
  y = xdsc[*,1]
  phase = -atan(y, x) * !radeg + 360. - 45.
  phase = phase mod 360

;   stop

  ; Store data into tplot
  ; pos
  if total(strcmp(datatype, 'pos', /fold)) gt 0 then begin
    tvar = rbx + 'pos_gse'
    data = {x:time, y:pgse}
    att = {units:'[km]', coord_sys:'gse'}
    dl ={data_att:att, ysubtitle:'[km]'}
    store_data, tvar, data = data, dlim = dl, verbose = verbose
    options, tvar, colors = [2, 4, 6], $
      labels = ['x GSE', 'y GSE', 'z GSE'], $
      labflag = 1
    if keyword_set(get_support_data) then begin
      newtvar = rbx + 'pos_gsm'
      cotrans, tvar, newtvar, /gse2gsm
      options, newtvar, colors = [2, 4, 6], $
        labels = ['x GSM', 'y GSM', 'z GSM'], $
        labflag = 1
    endif
  endif
  ; vel
  if total(strcmp(datatype, 'vel', /fold)) gt 0 then begin
    tvar = rbx + 'vel_gse'
    data = {x:time, y:vgse}
    att = {units:'[km/s]', coord_sys:'gse'}
    dl ={data_att:att, ysubtitle:'[km/s]'}
    store_data, tvar, data = data, dlim = dl, verbose = verbose
    options, tvar, colors = [2, 4, 6], $
      labels = ['Vx GSE', 'Vy GSE', 'Vz GSE'], $
      labflag = 1
    if keyword_set(get_support_data) then begin
      newtvar = rbx + 'vel_gsm'
      cotrans, tvar, newtvar, /gse2gsm
      options, newtvar, colors = [2, 4, 6], $
        labels = ['Vx GSM', 'Vy GSM', 'Vz GSM'], $
        labflag = 1
    endif
  endif
  ; spin angular momentum vector
  if total(strcmp(datatype, 'Lvec', /fold)) gt 0 then begin
    tvar = rbx + 'Lvec'
    data = {x:time, y:Lvec}
    att = {units:'', coord_sys:'gse'}
    dl ={data_att:att}
    store_data, tvar, data = data, dlim = dl, verbose = verbose
    options, tvar, colors = [2, 4, 6], $
      labels = ['Lx GSE', 'Ly GSE', 'Lz GSE'], $
      labflag = 1
  endif
  ; spin period
  if total(strcmp(datatype, 'spinper', /fold)) gt 0 then begin
    tvar = rbx + 'spinper'
    data = {x:time, y:per}
    att = {units:'[s]', coord_sys:''}
    dl ={data_att:att, ysubtitle:'[s]', yrange:minmax(per)+[-0.001,0.001], $
       ystyle:1}
    store_data, tvar, data = data, dlim = dl, verbose = verbose
    options, tvar, colors = [0], $
      labels = ['spin!C period'], $
      labflag = 1
  endif
  ; spin phase
  if total(strcmp(datatype, 'spinphase', /fold)) gt 0 then begin
    tvar = rbx + 'spinphase'
    data = {x:time, y:phase}
    att = {units:'[degree]', coord_sys:''}
    dl ={data_att:att, ysubtitle:'[degree]'}
    store_data, tvar, data = data, dlim = dl, verbose = verbose
    options, tvar, colors = [0], $
      labels = ['spin!C phase'], $
      labflag = 1
  endif
;   ; mat_xyz
;   'mat_xyz': rotation matrix in the form [N, 3, 3] between XYZ and GSE
;   if total(strcmp(datatype, 'mat_xyz', /fold)) gt 0 then begin
;     tvar = rbx + 'mat_xyz'
;     data = {x:time, y:mat_xyz}
;     att = {units:'', coord_sys:''}
;     dl ={data_att:att, ysubtitle:''}
;     store_data, tvar, data = data, dlim = dl
;   endif
  ; mat_dsc
  if total(strcmp(datatype, 'mat_dsc', /fold)) gt 0 then begin
    tvar = rbx + 'mat_dsc'
    mat_dsc = rbsp_load_state_smooth_mat_dsc(temporary(mat_dsc))

    data = {x:time, y:mat_dsc}
    att = {units:'', coord_sys:''}
    dl ={data_att:att, ysubtitle:''}
    store_data, tvar, data = data, dlim = dl
    if keyword_set(get_support_data) then begin
      get_data, tvar, data = d
      xgse_in_dsc = reform(d.y[*,0,*])
      ygse_in_dsc = reform(d.y[*,1,*])
      zgse_in_dsc = reform(d.y[*,2,*])
      att = {units:'', coord_sys:'dsc'}
      dl ={data_att:att, ysubtitle:''}
      store_data, rbx + 'xgse_dsc', data = {x:d.x, y:xgse_in_dsc}, dlim=dl, $
        verbose = verbose
      options, rbx + 'xgse_dsc', colors = [2, 4, 6], $
        labels = ['X', 'Y', 'Z'], $
        labflag = 1
      store_data, rbx + 'ygse_dsc', data = {x:d.x, y:ygse_in_dsc}, dlim=dl, $
        verbose = verbose
      options, rbx + 'ygse_dsc', colors = [2, 4, 6], $
        labels = ['X', 'Y', 'Z'], $
        labflag = 1
      store_data, rbx + 'zgse_dsc', data = {x:d.x, y:zgse_in_dsc}, dlim=dl, $
        verbose = verbose
      options, rbx + 'zgse_dsc', colors = [2, 4, 6], $
        labels = ['X', 'Y', 'Z'], $
        labflag = 1
    endif
  if total(strcmp(datatype, 'umbra', /fold)) gt 0 then begin
    rbsp_load_state_load_eclipse_time, probe = sc, no_eclipse = no_eclipse
  endif

  endif

endfor  ; sc loop

if keyword_set(no_spice_load) then return

; Unload spice kernels
if keyword_set(unload) then begin
  dprint, 'Unloading SPICE kernels...'
  cspice_unload, klist
endif else $
  dprint, verbose = verbose, 'SPICE not unloaded. !!!Keep this in mind!!!'

end
