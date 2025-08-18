;+
;NAME:
; mms_set_verbose
;PURPOSE:
; Sets verbose level in !mms.verbose and in tplot_options
;CALLING SEQUENCE:
; mms_set_verbose, vlevel
;INPUT:
; vlevel = a verbosity level, if not set then !mms.verbose is used
;          (this is how you would propagate the !mms.verbose value
;          into tplot options)
;HISTORY:
; 21-aug-2012, jmm, jimm@ssl.berkeley.edu
; 12-oct-2012, jmm, Added this comment to test SVN
; 12-oct-2012, jmm, Added this comment to test SVN, again
; 18-oct-2012, jmm, Another SVN test
; 10-apr-2015, moka, adapted for MMS from 'thm_set_verbose'
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-07-13 07:39:47 -0700 (Thu, 13 Jul 2017) $
; $LastChangedRevision: 23597 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_set_verbose.pro $
;-
Pro mms_set_verbose, vlevel

  ;Need to check for !mms
  defsysv,'!mms',exists=exists
  if not keyword_set(exists) then begin
    mms_init
  endif

  If(n_elements(vlevel) Eq 0) Then vlev = !mms.verbose Else vlev = vlevel[0]

  !mms.verbose = vlev

  tplot_options, 'verbose', vlev

  Return
End
