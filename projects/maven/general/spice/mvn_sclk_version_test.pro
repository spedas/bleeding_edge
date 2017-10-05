;+
;NAME:
;mvn_sclk_version_test
;PURPOSE:
;compares MAVEN MET to UNIX time conversions for an SCLK kernel with
;the most recent kernels. Returns the time ranges for which kernels do
;and do not match.
;CALLING SEQUENCE:
;mvn_sclk_version_test, sclk_name, trange_ok, trange_not_ok, $
;                       test_sclk_name = test_sclk_name
;INPUT:
;sckl_name = the name of the kernel file, this is typically available
;in L2 cdf files.
;OUTPUT:
;trange_ok = the time range for which the two kernels' values
;match. Note that times have resolution of 1 hour
;trange_not_ok = the time range for which the two kernels'
;values do not match
;KEYWORDS:
;test_sclk_name = a file name for the kernel to be tested against, the
;default is to use the current - most recent kernel file.
;dt_tolerance = dt values below this are treated as zero, the default
;is 0.0d0
;HISTORY:
;20-oct-2015, jmm, jimm@ssl.berkeley.edu, hacked from MVN_SCLK_TEST
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-10-20 17:08:23 -0700 (Tue, 20 Oct 2015) $
; $LastChangedRevision: 19120 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_sclk_version_test.pro $
;-
Pro mvn_sclk_version_test, sclk_name0, trange_ok, trange_not_ok, $
                           test_sclk_name = test_sclk_name, $
                           dt_tolerance = dt_tolerance, _extra = _extra

;Init output
  trange_ok = [0.0d0, 0.0d0] & trange_not_ok = trange_ok

;Check for spice
  If(~spice_test()) Then Begin
    dprint, 'SPICE is not installed.'
    Return
  Endif
;may need the path, depending on IO
  spath = root_data_dir() + 'misc/spice/naif/MAVEN/kernels/sclk/'
;Get kernel to test against
  If(keyword_set(test_sclk_name)) Then test_sclk0 = test_sclk_name[0] $
  Else Begin
     sclk = file_search(spath+'*.tsc', count = nsclk)
     If(nsclk Eq 0) Then Begin
        dprint, 'No kernels found in: '+spath
        Return
     Endif
;Get latest version
     test_sclk0 = sclk[nsclk-1]
  Endelse

;Add a path to filenames if no path is passed in
  If(test_sclk0 Eq file_basename(test_sclk0)) Then test_sclk = spath+test_sclk0 $
  Else test_sclk = test_sclk0
  If(sclk_name0 Eq file_basename(sclk_name0)) Then sclk_name = spath+sclk_name0 $
  Else sclk_name = sclk_name0

;File creation times
  finfo_sclk = file_info(sclk_name)
  If(~finfo_sclk.exists) Then Begin
     dprint, 'File not found: '+sclk_name
     Return
  Endif Else sclk_ctime = finfo_sclk.ctime
  
  finfo_test = file_info(test_sclk)
  If(~finfo_test.exists) Then Begin
     dprint, 'File not found: '+test_sclk
     Return
  Endif Else test_ctime = finfo_test.ctime
  
; Generate MET values, one per hour, spanning the time range covered by
; the sck kernels.
  ctimex = [test_ctime, sclk_ctime]
  t0 = min(ctimex) - 60D*86400D
  t1 = max(ctimex) + 60D*86400D
  nmet = ceil((t1 - t0)/3600D)

  toff = time_double('1984-11-14/12') - time_double('2014-11-15')
  met = 3600D*dindgen(nmet) + (t0 + toff)
; Convert MET to UNIX time for each SCLK kernel
  tls = spice_standard_kernels(verbose=-1)
  cspice_kclear
  spice_kernel_load, [tls, sclk_name], verbose=-1
  time_sclk = mvn_spc_met_to_unixtime(met, /correct)
  tls = spice_standard_kernels(verbose=-1)
  cspice_kclear
  spice_kernel_load, [tls, test_sclk], verbose=-1
  time_test = mvn_spc_met_to_unixtime(met, /correct)

; Calculate differences between time conversions
  dt = time_sclk - time_test
  If(keyword_set(dt_tolerance)) Then dtt = dt_tolerance Else dtt = 0.0d0

  ok = where(abs(dt) Le dtt, nok)
  If(nok Gt 0) Then trange_ok = minmax(time_test[ok])
  not_ok = where(abs(dt) Gt dtt, nnot_ok)
  If(nnot_ok Gt 0) Then trange_not_ok = minmax(time_test[not_ok])

End


