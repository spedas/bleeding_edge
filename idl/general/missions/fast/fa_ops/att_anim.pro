;+
; PROCEDURE:
;
; att_anim.pro
;
; PURPOSE:
;
;   Animates the orientation of the FAST spacecraft.  Shows model
;   magnetic field, spacecraft velocity, and Sun direction in the s/c
;   spin plane.  Also tells the angles of these vectors out of the
;   spin plane as well as other orbit quantities.
;
; INPUTS:
;
;   TIME     Array or scalar.  Scalar may be string or double float.
;            If scalar, then time array is constructed from 30 points
;            over ten seconds centered on the time argument.
;
; KEYWORDS:
;
;   NOTEXT   Set this to suppress printing of textual info so the output
;            image may be used as an icon.
;
;   N_FRAMES The number of frames in the animation.  Default is 30.
;            Has no effect if TIME is an array.
;
; NOTES:
;
;   Created: 98-4-8
;   Creator: J.Rauchleiba
;-
pro att_anim, time, NOTEXT=notext, N_FRAMES=nf

;; Convert time to double float and create array

if n_elements(time) EQ 1 then begin
    if data_type(time) EQ 7 then t=str_to_time(time) else t=time
    if NOT keyword_set(nf) then nf = 30
    t_array = dindgen(nf)*(10d/double(nf)) - 5d + t
endif else t_array = time

; Colors

n_colors = !d.n_colors
black = 0
white = !d.n_colors - 1
blue = fix(.33*float(!d.n_colors))
brown = fix(.81*float(!d.n_colors))
red = 6
green = 4
yellow = 5

; Scene setup

xsize = 328
ysize = 325
window, /free, xsize=xsize, ysize=ysize, /PIXMAP
wintitle='FAST Attitude'
read_gif, getenv('GIFDIR') + '/craft_axis.gif', craft
craft_fg_ind = where(craft EQ 0)
craft_bg_ind = where(craft NE 0)
craft(craft_fg_ind) = brown
craft(craft_bg_ind) = !p.background
tv, craft

;; Label the diagram

xyouts, .03, .51, /norm, '6.5' + string("260B), color=brown
xyouts, .512, .603, /norm, '38' + string("260B), color=brown
xyouts, .588, .880, /norm, '5m', color=brown
xyouts, .35, .880, /norm, '29m', color=brown
xyouts, .503, .951, /norm, '1', color=brown
xyouts, .503, .858, /norm, '2', color=brown
xyouts, .0457, .422, /norm, '5', color=brown
xyouts, .134, .431, /norm, '6', color=brown
xyouts, .845, .430, /norm, '7', color=brown
xyouts, .939, .422, /norm, '8', color=brown

;; Retrieve labeled image back into craft variable.
;; Open a window.
;; Setup Animation.

craft = tvrd()
nframes = n_elements(t_array)
xinteranimate, set=[xsize, ysize, nframes]

;; Create the (static) rotation matrix from NORMAL to FASTSPIN
;; coordinates. The x-axis of the craft is the Fluxgate Magnetometer
;; (38 deg clockwise from stubby boom 4 when looking from +z to origin)

theta = 2.23402
R = [ [cos(theta), cos(theta - !pi/2.) ], $
      [cos(theta + !pi/2.), cos(theta) ] ]

; Store orbit data for the specified input time

get_fa_orbit, t_array, /time_array, /all, /definitive, status=st
if st NE 0 then message, 'Error in get_fa_orbit.pro'

;; Get the instantaneous rotation matrices which perform the conversions 
;; FASTSPIN -> GEI, FASTSPIN -> GEO

get_fa_attitude, t_array, /time_array, coord='GEI'
get_fa_attitude, t_array, /time_array, coord='GEO'
get_data, 'fa_rotmat_gei', data=fa_rotmat_gei
get_data, 'fa_rotmat_geo', data=fa_rotmat_geo

;; Get data needed in loop

get_data, 'B_model', data=B_model
get_data, 'fa_vel', data=fa_vel

get_data, 'FLAT', data=flat
get_data, 'ILAT', data=ilat
get_data, 'MLT', data=mlt
get_data, 'ALT', data=alt

;; Frame-creation LOOP

for f = 0, nframes - 1 do begin
    
tv, craft    
    
spin2gei = fa_rotmat_gei.y(f,*,*)
spin2geo = fa_rotmat_geo.y(f,*,*)

;; Fix the matrices for the conversions
;; GEI -> FASTSPIN, GEO -> FASTSPIN

gei2spin = transpose(transpose(spin2gei))
geo2spin = transpose(transpose(spin2geo))

;; Get the instantaneous magnetic field vector in GEI (nT)

Bgei = B_model.y(f,*)

;; Transform magnetic field vector from GEI to FASTSPIN system, display

Bspin = gei2spin ## Bgei

;; B-angle out of page

Borth = atan(Bspin(2)/sqrt(Bspin(0)^2 + Bspin(1)^2))*!radeg

;; Rotate B planar components to match drawing orientation

Bmagnitude = sqrt( Bspin(0)^2 + Bspin(1)^2 + Bspin(2)^2 )
B_norm = Bspin/Bmagnitude/3.
B_plane = R ## [[B_norm(0)], [B_norm(1)]]

;; Draw the B-vector

arrow, .5, .5, B_plane(0)+.5, B_plane(1)+.5, /norm,thick=2,hthi=3,/sol,col=blue
xyouts, B_plane(0) + .5 + .03*B_plane(0)/abs(B_plane(0)), $
  B_plane(1) + .5 + .03*B_plane(1)/abs(B_plane(1)), /norm,  'B', color=blue
;;;print, 'Magnetic Field: ', Bmagnitude, ' nT'
;;;print, 'B-angle (+) out of page: ', Borth, ' degrees'

;; Get the velocity vector in GEI (km/s)

Vgei = fa_vel.y(f,*)

;; Transform velocity from GEI to FASTSPIN

Vspin = gei2spin ## Vgei

;; V-angle out of page

Vorth = atan(Vspin(2)/sqrt(Vspin(0)^2 + Vspin(1)^2))*!radeg

;; Rotate V planar components to match drawing orientation

Vmagnitude = sqrt( Vspin(0)^2 + Vspin(1)^2 + Vspin(2)^2 ) 
V_norm = Vspin/Vmagnitude/3
V_plane = R ## [[V_norm(0)], [V_norm(1)]]

;; Draw the Velocity vector

arrow, .5, .5, V_plane(0)+.5, V_plane(1)+.5,/norm,thick=2,hthi=3,/sol,col=green
xyouts, V_plane(0) + .5 + .03*V_plane(0)/abs(V_plane(0)), $
  V_plane(1) + .5 + .03*V_plane(1)/abs(V_plane(1)), /norm, 'V', color=green
;;;print, 'Velocity: ', Vmagnitude, ' km/s'
;;;print, 'V-angle (+) out of page: ', Vorth, ' degrees'

;; Get the Sun pointer in GEI

raven_sun_pos, t_array(f), slong, srasn, sdec, Sgei

;; Transform Sun pointer unit vector from GEI to FASTSPIN

Sspin = gei2spin ## Sgei

;; Sun angle out of page

Sorth = atan(Sspin(2)/sqrt(Sspin(0)^2 + Sspin(1)^2))*!radeg

;; Rotate Sun pointer components to match drawing orientation

S_norm = Sspin/3
S_plane = R ## [[S_norm(0)], [S_norm(1)]]

;; Draw the Sun pointer

arrow, .5,.5, S_plane(0)+.5, S_plane(1)+.5,/norm,thick=1,hthi=2,/sol,col=yellow
xyouts, S_plane(0) + .5 + .03*S_plane(0)/abs(S_plane(0)), $
  S_plane(1) + .5 +.03*S_plane(1)/abs(S_plane(1)), /nor, 'S',col=yellow
;print, 'S-angle (+) out of page: ', Sorth, ' degrees'

;; Get LAT, LNG (GEO) of Sun indicator
;
;store_data, 'spos_gei', data={x:[t], y:[[Sgei(0)],[Sgei(1)],[Sgei(2)]]}
;coord_trans, 'spos_gei', 'spos_geo', 'GEIGEO'
;get_data, 'spos_geo', data=spos_geo
;Sgeo = spos_geo.y
;slat = atan(Sgeo(0,2), sqrt(Sgeo(0,0)^2 + Sgeo(0,1)^2))
;slng = atan(Sgeo(0,1), Sgeo(0,0))
;;if Sgeo(0,0) LT 0 then slng = slng + !pi
;print, 'Sun lat: ', slat*!radeg
;print, 'Sun lng: ', slng*!radeg

if NOT keyword_set(notext) then begin
    colors = [black, white, blue, brown, red, green, yellow]
    fonts = '*helvetic-bold*--12|10!5 vector|20!3*helvetica-bold*--24*'
    ds=string("260B)            ;" degree symbol
    yspace = 12
    
    ;; Angles out of page
    
    strings = ['`C3`Angles (+ out):', $
               '`H7,C2`Bmod ' + string(format='(F5.1)',Borth)+ds, $
               '`C5`Vel  ' + string(format='(F5.1)',Vorth)+ds, $
               '`C6`Sun  ' + string(format='(F5.1)',Sorth)+ds]
    disp_txt, xstart=10, ystart=40, strings, fonts, yspace, colors=colors
    
    ;; Magnitudes
    
    strings = ['`C3`Magnitudes: ', $
               '`H7,C2`B = ' + string(format='(I8)', Bmagnitude) + ' nT', $
               '`C5`V = ' + string(format='(F8.2)', Vmagnitude) + ' km/s']
    disp_txt, xstart=215, ystart=40, strings, fonts, yspace, colors=colors
    
    ;; Time stamp
    
    date_time=str_sep(time_to_str(t_array(f), /msec), '/')
    strings = ['`C3`'+date_time(0), date_time(1)]
    disp_txt, xstart=10, ystart=310, strings, fonts, yspace, colors=colors
    
    ;; Orbit quantities
    
    strings = ['`C3`Orbit data:', $
               '`H7`FLAT ' + string(format='(F5.1)',flat.y(f))+ds, $
               'ILAT ' + string(format='(F5.1)',ilat.y(f))+ds, $
               'MLT  ' + string(format='(F5.1)',mlt.y(f))+' hr', $
               'ALT  ' + string(format='(I5)',alt.y(f))+' km' ]
    disp_txt, xstart=215, ystart=310, strings, fonts, yspace, colors=colors
endif 

;; Render the frame

print, string(bytarr(25 + strlen(strtrim(nframes, 2)))+8b), $
  'Rendering ' + strtrim(nframes, 2) + ' Frames... ', $
  100*float(f)/float(nframes-1.), '%', format='(a,a,i3,a,$)'
xinteranimate, frame=f, window=!d.window

endfor

;; View the animation

print
xinteranimate, 20

end
