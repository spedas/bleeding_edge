;+
; MMS orbit crib sheet
;
;
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;     
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
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
