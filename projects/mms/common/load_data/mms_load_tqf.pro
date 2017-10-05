;+
; PROCEDURE:
;         mms_load_tqf
;
; PURPOSE:
;         Loads the tetrahedron quality factor from the LASP SDC
;          (this is a simple wrapper around mms_load_tetrahedron_qf)
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-07-20 16:22:57 -0700 (Thu, 20 Jul 2017) $
;$LastChangedRevision: 23687 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_load_tqf.pro $
;-

pro mms_load_tqf, trange=trange, suffix=suffix
  mms_load_tetrahedron_qf, trange=trange, suffix=suffix
end