;+
; MMS spacecraft formation crib sheet
;
;  This script shows how to create 3D plots of the S/C formation
;    at a given time
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
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
stop

; plot the average B-field in the center of the plot (average of all 4 spacecraft)
mms_mec_formation_plot, '2016-1-08/2:36', /bfield_center
stop

; plot the average DIS and DES bulk velocities in the center of the plot (averages of all 4 spacecraft)
mms_mec_formation_plot, '2016-1-08/2:36', /dis_center, /des_center
stop

; include a user-specified vector on the plot
mms_mec_formation_plot, '2016-1-08/2:36', vector_x=[0, 1], vector_y=[0, 1], vector_z=[0, 5]
stop

; include multiple user-specified vectors on the plot
mms_mec_formation_plot, '2016-1-08/2:36', vector_x=[[0, 1], [0, 7]], vector_y=[[0, 1], [0, 1]], vector_z=[[0, 5], [0, 1]], $
  vector_colors=[[255, 0, 0], [0, 0, 255]] ; note: by default, the colors are black; to change the colors, set the vector_colors keyword (RGB)
stop

; include a user-specified vector on the plot with projections
mms_mec_formation_plot, '2016-1-08/2:36', vector_x=[0, 1], vector_y=[0, 1], vector_z=[0, 5], /projection, vector_colors=[255, 0, 0]
stop

end


