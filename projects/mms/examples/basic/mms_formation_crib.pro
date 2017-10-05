;+
; MMS spacecraft formation crib sheet
;
;  This script shows how to create 3D plots of the S/C formation
;    at a given time
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-05-26 08:08:50 -0700 (Thu, 26 May 2016) $
; $LastChangedRevision: 21217 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_formation_crib.pro $
;-

; https://lasp.colorado.edu/mms/sdc/public/data/sdc/mms_formation_plots/mms_formation_plot_20160108023624.png
time = '2015-10-16/13:07'

; without XY-plane projections
mms_mec_formation_plot, time

stop

; with the XY projections
mms_mec_formation_plot, time, /xy_projection

stop

; with XY projections and the tetrahedron quality factor
mms_mec_formation_plot, time, /xy_projection, /quality

stop

; use a different coordinate system
mms_mec_formation_plot, time, coord='gsm'

end


