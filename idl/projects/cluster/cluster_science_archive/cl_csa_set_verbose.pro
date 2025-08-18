;+
;NAME:
; cl_csa_set_verbose
;PURPOSE:
; Sets verbose level in !cluster_csa.verbose and in tplot_options
;CALLING SEQUENCE:
; cl_csa_set_verbose, vlevel
;INPUT:
; vlevel = a verbosity level, if not set then !cluster_csa.verbose is used
;          (this is how you would propagate the !cluster_csa.verbose value
;          into tplot options)
;HISTORY:
; 21-aug-2012, jmm, jimm@ssl.berkeley.edu
; 12-oct-2012, jmm, Added this comment to test SVN
; 12-oct-2012, jmm, Added this comment to test SVN, again
; 18-oct-2012, jmm, Another SVN test
; 10-apr-2015, moka, adapted for MMS from 'thm_set_verbose'
; 23-dec-2019, egrimes, forked for Cluster
; 
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-05-20 17:50:46 -0700 (Thu, 20 May 2021) $
; $LastChangedRevision: 29980 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/cluster_science_archive/cl_csa_set_verbose.pro $
;-
Pro cl_csa_set_verbose, vlevel

  ;Need to check for !cluster_csa
  defsysv,'!cluster_csa',exists=exists
  if not keyword_set(exists) then begin
    cl_csa_init
  endif

  If(n_elements(vlevel) Eq 0) Then vlev = !cluster_csa.verbose Else vlev = vlevel[0]

  !cluster_csa.verbose = vlev

  tplot_options, 'verbose', vlev

  Return
End
