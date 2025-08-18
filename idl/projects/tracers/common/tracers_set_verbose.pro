;+
;NAME:
; tracers_set_verbose
;
;PURPOSE:
; Sets verbose level in !tracers.verbose and in tplot_options
;
;CALLING SEQUENCE:
; tracers_set_verbose, vlevel
;
;INPUT:
; vlevel = a verbosity level, if not set then !tracers.verbose is used
;          (this is how you would propagate the !tracers.verbose value
;          into tplot options)
;
;HISTORY:
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-07-31 17:36:13 -0700 (Thu, 31 Jul 2025) $
; $LastChangedRevision: 33518 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/tracers/common/tracers_set_verbose.pro $
;-
Pro tracers_set_verbose, vlevel

  ;Need to check for !elf
  defsysv,'!tracers',exists=exists
  if not keyword_set(exists) then begin
    tracers_init
  endif

  If(n_elements(vlevel) Eq 0) Then vlev = !tracers.verbose Else vlev = vlevel[0]

  !tracers.verbose = vlev

  tplot_options, 'verbose', vlev

  Return
End
