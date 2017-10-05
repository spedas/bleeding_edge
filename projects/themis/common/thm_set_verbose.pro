;+
;NAME:
; thm_set_verbose
;PURPOSE:
; Sets verbose level in !themis.verbose and in tplot_options
;CALLING SEQUENCE:
; thm_set_verbose, vlevel
;INPUT:
; vlevel = a verbosity level, if not set then !themis.verbose is used
;          (this is how you would propagate the !themis.verbose value
;          into tplot options)
;HISTORY:
; 21-aug-2012, jmm, jimm@ssl.berkeley.edu
; 12-oct-2012, jmm, Added this comment to test SVN
; 12-oct-2012, jmm, Added this comment to test SVN, again
; 18-oct-2012, jmm, Another SVN test
; 31-oct-2016, jmm, Added setting to dprint too
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-10-31 13:25:10 -0700 (Mon, 31 Oct 2016) $
; $LastChangedRevision: 22240 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_set_verbose.pro $
;-
Pro thm_set_verbose, vlevel

;Need to check for !themis
defsysv,'!themis',exists=exists
if not keyword_set(exists) then begin
   thm_init
endif

If(n_elements(vlevel) Eq 0) Then vlev = !themis.verbose Else vlev = vlevel[0]

!themis.verbose = vlev

tplot_options, 'verbose', vlev

;Set dprint verbose too, jmm, 2016-10-31
dprint, setverbose=vlev

Return
End
