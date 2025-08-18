;+
;NAME:
; spd_default_local_data_dir
;
;PURPOSE:
; Returns the default data directory for file downloads for varius projects.
; It is used for the GUI configuration settings.
; Simplified replacement for root_data_dir
;
;CALLING SEQUENCE:
; spd_default_local_data_dir
;
;INPUT:
; none
;
;OUTPUT:
; (string) Directory in user's home path
;
;HISTORY:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-11-16 08:19:37 -0800 (Wed, 16 Nov 2016) $
;$LastChangedRevision: 22362 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/spd_default_local_data_dir.pro $
;-----------------------------------------------------------------------------------

function spd_default_local_data_dir
  data_dir = file_search('~',/expand_tilde) + path_sep() + 'data' + path_sep()
  return, data_dir
end