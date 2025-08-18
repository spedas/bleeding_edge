;+
;NAME:
; get_rt_path
;PURPOSE:
;  gets the directory of the calling routine.  Used for reliably looking
;  up resource paths across platform
;CALLING SEQUENCE:
;  get_rt_path,path
;OUTPUT:
;  path: the path of the routine that called get_rt_path
;
;NOTES:
;  This is a general version of specific routines like getctpath.
;  Eventually those routines should be replaced with this one.
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2009-07-16 16:38:39 -0700 (Thu, 16 Jul 2009) $
;$LastChangedRevision: 6439 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/get_rt_path.pro $
;-
pro get_rt_path,path

  compile_opt idl2

  tr = scope_traceback(/structure)
  rt_path = (tr[n_elements(tr)-2]).filename
  path = file_dirname(rt_path)

end