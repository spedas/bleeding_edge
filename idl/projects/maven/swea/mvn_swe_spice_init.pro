;+
;PROCEDURE:   mvn_swe_spice_init
;PURPOSE:
;  Initializes SPICE.
;
;USAGE:
;  mvn_swe_spice_init
;
;INPUTS:
;
;KEYWORDS:
;
;    TRANGE:        Time range for MAVEN spacecraft spk and ck kernels.  If not set,
;                   then the current timespan is used.
;
;    LIST:          After loading, list the kernels in use.
;
;    FORCE:         If set, then clear all kernels and reload them based on TRANGE
;                   or the current value of trange_full.  Otherwise, ask the user
;                   for permission to clear and reload.
;
;    SCLK_VER:      Force the SCLK kernel version to be this.  Sometimes needed for
;                   accurate relative timing between MAG and SWEA.  If set, then
;                   FORCE is also set.
;
;    NOCK:          Do not load any CK kernels.  This allows ephemeris calculations
;                   where the spacecraft orientation does not matter.  Useful for
;                   calculations spanning long time intervals.
;
;    BASEONLY:      Do not load any SPK or CK kernels.  The standard and frames 
;                   kernels are loaded to allow geometry calculations spanning long
;                   time intervals.
;
;    CSS:           Include the Comet Siding Spring SPK in the loadlist.
;
;    STATUS:        Don't load anything; just give status.
;
;    INFO:          Returns an array of structures providing detailed information
;                   about each kernel, including coverage in time.
;
;    VERBOSE:       Control level of messages.  (0 = suppress most messages)
;                   Default is current value of swe_verbose.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-05-11 10:05:18 -0700 (Thu, 11 May 2023) $
; $LastChangedRevision: 31851 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_spice_init.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_swe_spice_init, trange=trange, list=list, force=force, sclk_ver=sclk_ver, $
                        nock=nock, baseonly=baseonly, css=css, status=status, info=info, $
                        verbose=verbose

  @mvn_swe_com

  common mvn_spc_met_to_unixtime_com, cor_clkdrift, icy_installed, kernel_verified, $
         time_verified, sclk, tls

  noguff = keyword_set(force)
  list = keyword_set(list)
  ck = ~keyword_set(nock)
  baseonly = keyword_set(baseonly)
  if (baseonly) then begin
    spk = 0B
    ck = 0B
  endif else spk = 1B
  css = keyword_set(css)
  if (size(verbose,/type) eq 0) then mvn_swe_verbose, get=verbose

  swap_sclk = 0
  if (size(sclk_ver,/type) gt 0) then begin
    vclk = sclk_ver[0]
    if (vclk ge 0) then begin
      path = root_data_dir() + 'misc/spice/naif/MAVEN/kernels/sclk/'
      fname = path + 'MVN_SCLKSCET.' + string(vclk,format='(i5.5)') + '.tsc'
      finfo = file_info(fname)
      if (finfo.exists) then begin
        swap_sclk = 1
        noguff = 1
      endif else print,"SCLK kernel not found: ",file_basename(fname)
    endif else print,"Invalid SCLK kernel version: ",strtrim(string(vclk),2)
  endif

  if keyword_set(status) then begin
    mvn_spice_stat, list=list
    return
  endif

  if (~noguff) then begin
    mk = spice_test('*')
    indx = where(mk ne '', n_ker)
    if (n_ker gt 0) then begin
      print,"SPICE kernels are already loaded."
      yn = 'N'
      read,"Reinitialize (y|n) ? ", yn
      if (~strmatch(yn,'y*',/fold)) then return
    endif
  endif

  oneday = 86400D

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    
    if ((size(trange,/type) eq 0) and ~baseonly) then begin
      print,"You must supply a time range."
      return
    endif
  endif
  
  if (~baseonly) then srange = minmax(time_double(trange)) + [-oneday, oneday]

; Shush dprint

  dprint,' ', getdebug=bug, dlevel=4
  if (verbose lt 1) then dprint,' ', setdebug=0, dlevel=4

; Get latest SPICE kernels

  print, "Initializing SPICE ... ", format='(a,$)'
  if (verbose gt 0) then print,' '

  cspice_kclear ; remove any previously loaded kernels

  if (css) then names = ['STD','CSS','SCK','FRM','IK'] else names = ['STD','SCK','FRM','IK']
  if (spk) then names = [names,'SPK']
  if (ck)  then names = [names,'CK','CK_APP','CK_SWE']
  swe_kernels = mvn_spice_kernels(names,verbose=(verbose-1))

  if (swap_sclk) then begin
    i = where(strmatch(swe_kernels,'*SCLK*',/fold_case) eq 1)
    if (i ge 0) then swe_kernels[i] = fname else swap_sclk = 0
  endif

  spice_kernel_load, swe_kernels ; load the kernels
  swe_kernels = spice_test('*')  ; only loaded kernels, no wildcards
  n_ker = n_elements(swe_kernels)

; Use common block settings to inform later routines that kernels have
; already been loaded, and they don't need to check again and print out
; a bunch of unnecessary diagnostics that can't be turned off.

  i = where(strpos(swe_kernels,'SCLK') ne -1, scnt)  ; spacecraft clock kernel
  j = where(strpos(swe_kernels,'tls') ne -1, tcnt)   ; leap seconds kernel
  
  if (scnt and tcnt) then begin
    kernel_verified = 1
    sclk = swe_kernels[i]
    tls = swe_kernels[j]
    time_verified = systime(1)
    msg = "Success"

    ker_info = spice_kernel_info(verbose=0)
  endif else begin
    kernel_verified = 0
    ker_info = 0
    msg = "WARNING: no SPICE kernels!"
  endelse
  info = ker_info

  print, msg

  if (swap_sclk) then begin
    print,""
    print,"  Using SCLK kernel: ", file_basename(fname)
  endif

; Print out time coverage of loaded kernels

  if (kernel_verified) then mvn_spice_stat, list=list

; Restore debug state

  dprint,' ', setdebug=bug, dlevel=4

  return

end
