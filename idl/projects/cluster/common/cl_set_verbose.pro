;+
;NAME:
; cl_set_verbose
;PURPOSE:
; Sets verbose level in !cluster.verbose and in tplot_options
;CALLING SEQUENCE:
; cl_set_verbose, vlevel
;INPUT:
; vlevel = a verbosity level, if not set then !cluster.verbose is used
;          (this is how you would propagate the !cluster.verbose value
;          into tplot options)
;HISTORY:
; 21-aug-2012, jmm, jimm@ssl.berkeley.edu
; 12-oct-2012, jmm, Added this comment to test SVN
; 12-oct-2012, jmm, Added this comment to test SVN, again
; 18-oct-2012, jmm, Another SVN test
; 10-apr-2015, moka, adapted for MMS from 'thm_set_verbose'
; 23-dec-2019, egrimes, forked for Cluster
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-12-23 16:57:38 -0800 (Mon, 23 Dec 2019) $
; $LastChangedRevision: 28136 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/common/cl_set_verbose.pro $
;-
Pro cl_set_verbose, vlevel

  ;Need to check for !cluster
  defsysv,'!cluster',exists=exists
  if not keyword_set(exists) then begin
    cl_init
  endif

  If(n_elements(vlevel) Eq 0) Then vlev = !cluster.verbose Else vlev = vlevel[0]

  !cluster.verbose = vlev

  tplot_options, 'verbose', vlev

  Return
End
