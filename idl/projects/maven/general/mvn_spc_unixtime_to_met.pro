;+
;Function:  mvn_spc_unixtime_to_met
;Purpose:  Convert unixtime to MET (mission Elapsed Time)
; Note: This routine MUST remain reasonably efficient since it could potentially be called from within an inner FOR loop.
; Author: Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-01-21 17:00:30 -0800 (Tue, 21 Jan 2014) $
; $LastChangedRevision: 13959 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/idl_socware/trunk/projects/maven/mvn_spc_met_to_unixtime.pro $
;-

function mvn_spc_unixtime_to_met,unixtime,correct_clockdrift=correct_clockdrift    ;, reset=reset, prelaunch=prelaunch

met = mvn_spc_met_to_unixtime(unixtime,/reverse,correct_clockdrift=correct_clockdrift)
return,met

end


