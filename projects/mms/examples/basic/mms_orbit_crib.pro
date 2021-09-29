;+
; MMS orbit crib sheet
;
;
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-05-27 17:05:59 -0700 (Wed, 27 May 2020) $
; $LastChangedRevision: 28741 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_orbit_crib.pro $
;-

; create a simple orbit plot with all 4 spacecraft on 15Dec2015
mms_orbit_plot, probe=[1, 2, 3, 4], trange=['2015-12-15', '2015-12-16']
stop

; you can specify the plane to view using the 'plane' keyword
; and you can disable the image of Earth with the /noearth option
mms_orbit_plot, plane='yz', probe=[1, 2, 3, 4], trange=['2015-12-15', '2015-12-16'], /noearth
stop

; you can specify the coordinate system using the 'coord' keyword
mms_orbit_plot, coord='sm', probe=[1, 2, 3, 4], trange=['2015-12-15', '2015-12-16'];, yrange=[-20, 20], xrange=[-20, 20]
stop

end
