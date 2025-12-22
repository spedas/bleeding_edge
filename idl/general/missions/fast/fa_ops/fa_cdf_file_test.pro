;+
;NAME:
;fa_cdf_file_test
;PURPOSE:
;Checks the current working directory for CDF files related to
;orbit_process for a given orbit, and an SDT variable.
;Returns the file size if available, or -1 for no file.
;COMMAND SEQUENCE:
;fsize = fa_cdf_file_test(orbit, dqd)
;INPUT:
;orbit = orbit number
;dqd = SDT DQD for a given data quantity, eg: 'V1-V4_16k' for 16k data
;      for booms 1 and 4. These are available in the process programs
;      such as fa_fields_despin3.pro
;OUTPUT:
;fsize = file size in bytes, generally a file size less than 1600
;        bytes has no data; a missing file returns a file size of -1
;HISTORY:
;2025-12-09, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Function fa_cdf_file_test, orbit, dqd

  otp = -1
  orb0 = strcompress(string(orbit), /remove_all)
  fname0 = 'orbit_process_'+orb0+'.'+dqd+'.cdf'
  fname = file_search(fname0)
  If(is_string(fname)) Then Begin
     finfo = file_info(fname)
     otp = finfo.size
  Endif
  Return, otp
End
