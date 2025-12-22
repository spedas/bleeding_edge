;+
; PROCEDURE:
;
; plot_fa_att.pro
;
; PURPOSE:
;
;   Displays the orientation of the FAST spacecraft.  Shows model
;   magnetic field, spacecraft velocity, and Sun direction in the s/c
;   spin plane.  Also tells the angles of these vectors out of the
;   spin plane as well as other orbit quantities.
;
; INPUTS:
;
;   time    String or double float.
;
; KEYWORDS:
;
;   NOTEXT  Set this to suppress printing of textual info so the output image
;           may be used as an icon.
;   PS      If set, the name of the output postscript file.
;           Preset width of plot is 5 cm, but can be scaled with SCALE.
;   SCALE   Scale factor for PS plot width. Default is 1.
;   BW      Output is in black and white.
;   VECTOR  Use vector-drawn font instead of hardware font.
;
; NOTES:
;
;   Created: 6-9-97
;   Creator: J.Rauchleiba
;-
pro plot_fa_att, time, $
        NOTEXT=notext, $
        PS=psfile, $
        SCALE=scale, $
        BW=bw, $
        VECTOR=vdf

; Color definitions

blue = fix(.33*float(!d.n_colors))
brown = fix(.81*float(!d.n_colors))
red = 6
green = 4
purple = 1
yellow = 5
black = 0
white = !d.n_colors - 1

; Font Setup (reset at finish)

oldfont = !p.font
!p.font = keyword_set(vdf) * (-1)

; Window, scene setup

if keyword_set(psfile) then begin
    tvlct, /get, r, g, b
    if NOT keyword_set(scale) then scale=1
    pswidth = 5.0 * float(scale)
    popen, psfile, /port, /color, xsize=pswidth, ysize=pswidth*(325./328.)
    tvlct, r, g, b
endif else begin
    window, /free, xsize=328, ysize=325, title='FAST Attitude'
endelse

; Color Scheme
; (Using !p.background and !p.color won't work because they always
; index first and last point in color table.  PS always has 256 while
; X may have less.  Loading the X palette into the PS device results
; in leftover colors.)

if keyword_set(bw) then begin
    if keyword_set(psfile) then begin
        diagram = black
        field = black
        sunlight = black
        go = black
        background = white
    endif else begin
        diagram = white
        field = white
        sunlight = white
        go = white
        background = black
    endelse
endif else if keyword_set(psfile) then begin
    diagram = black
    field = blue
    sunlight = brown
    go = purple
    background = white
endif else begin
    diagram = brown
    field = blue
    sunlight = yellow
    go = green
    background = black
endelse

; Read diagram from GIF file and edit colors

read_gif, getenv('GIFDIR') + '/craft_axis.gif', craft
craft_fg_ind = where(craft EQ 0)
craft_bg_ind = where(craft NE 0)
craft(craft_fg_ind) = diagram
craft(craft_bg_ind) = background
tv, craft

; Label the diagram

xyouts, .03, .51, /norm, '6.5' + string("260B), color=diagram ;;"
xyouts, .512, .603, /norm, '38' + string("260B), color=diagram ;;"
xyouts, .588, .880, /norm, '5m', color=diagram
xyouts, .35, .880, /norm, '29m', color=diagram
xyouts, .503, .951, /norm, '1', color=diagram
xyouts, .503, .858, /norm, '2', color=diagram
xyouts, .0457, .422, /norm, '5', color=diagram
xyouts, .134, .431, /norm, '6', color=diagram
xyouts, .845, .430, /norm, '7', color=diagram
xyouts, .939, .422, /norm, '8', color=diagram

; Create rotation matrix from NORMAL to FASTSPIN coordinates
; The x-axis of the craft is the Fluxgate Magnetometer (38 deg
; clockwise from stubby boom 4 when looking from +z to origin)

theta = 2.23402
R = [ [cos(theta), cos(theta - !pi/2.) ], $
      [cos(theta + !pi/2.), cos(theta) ] ]

; Convert time to double float

if data_type(time) EQ 7 then t=str_to_time(time) else t=time

; Store orbit data for the specified input time

get_fa_orbit, [t], /time_array, /all, /definitive, status=st
if st NE 0 then message, 'Error in get_fa_orbit.pro'

; Get the instantaneous rotation matrices which perform the conversions 
; FASTSPIN -> GEI, FASTSPIN -> GEO

get_fa_attitude, [t, t], /time_array, coord='GEI'
get_fa_attitude, [t, t], /time_array, coord='GEO'
get_data, 'fa_rotmat_gei', data=fa_rotmat_gei
get_data, 'fa_rotmat_geo', data=fa_rotmat_geo
spin2gei = fa_rotmat_gei.y(0,*,*)
spin2geo = fa_rotmat_geo.y(0,*,*)

; Fix the matrices for the conversions
; GEI -> FASTSPIN, GEO -> FASTSPIN

gei2spin = transpose(transpose(spin2gei))
geo2spin = transpose(transpose(spin2geo))

; Get the instantaneous magnetic field vector in GEI (nT)

get_data, 'B_model', data=B_model
Bgei = B_model.y

; Transform magnetic field vector from GEI to FASTSPIN system, display

Bspin = gei2spin ## Bgei

; B-angle out of page

Borth = atan(Bspin(2)/sqrt(Bspin(0)^2 + Bspin(1)^2))*!radeg

; Rotate B planar components to match drawing orientation

Bmagnitude = sqrt( Bspin(0)^2 + Bspin(1)^2 + Bspin(2)^2 )
B_norm = Bspin/Bmagnitude/3.
B_plane = R ## [[B_norm(0)], [B_norm(1)]]

; Draw the B-vector

arrow, .5, .5, B_plane(0) + .5, B_plane(1) + .5, $
  /norm, thick=2, hthi=3, /sol, color=field
xyouts, B_plane(0) + .5 + .03*B_plane(0)/abs(B_plane(0)), $
  B_plane(1) + .5 + .03*B_plane(1)/abs(B_plane(1)), /norm,  'B', color=field
;print, 'Magnetic Field: ', Bmagnitude, ' nT'
;print, 'B-angle (+) out of page: ', Borth, ' degrees'

; Get the velocity vector in GEI (km/s)

get_data, 'fa_vel', data=fa_vel
Vgei = fa_vel.y

; Transform velocity from GEI to FASTSPIN

Vspin = gei2spin ## Vgei

; V-angle out of page

Vorth = atan(Vspin(2)/sqrt(Vspin(0)^2 + Vspin(1)^2))*!radeg

; Rotate V planar components to match drawing orientation

Vmagnitude = sqrt( Vspin(0)^2 + Vspin(1)^2 + Vspin(2)^2 ) 
V_norm = Vspin/Vmagnitude/3
V_plane = R ## [[V_norm(0)], [V_norm(1)]]

; Draw the Velocity vector

arrow, .5, .5, V_plane(0) + .5, V_plane(1) + .5, $
  /norm, thick=2, hthi=3, /sol, col=go
xyouts, V_plane(0) + .5 + .03*V_plane(0)/abs(V_plane(0)), $
  V_plane(1) + .5 + .03*V_plane(1)/abs(V_plane(1)), /norm, 'V', color=go
;print, 'Velocity: ', Vmagnitude, ' km/s'
;print, 'V-angle (+) out of page: ', Vorth, ' degrees'

; Get other orbit quantities FLAT, ILAT, MLT, ALT

get_data, 'FLAT', data=flat
get_data, 'ILAT', data=ilat
get_data, 'MLT', data=mlt
get_data, 'ALT', data=alt

; Get the Sun pointer in GEI

solar_pos, t, gst, slong, srasn, sdec, Sgei

; Transform Sun pointer unit vector from GEI to FASTSPIN

Sspin = gei2spin ## Sgei

; Sun angle out of page

Sorth = atan(Sspin(2)/sqrt(Sspin(0)^2 + Sspin(1)^2))*!radeg

; Rotate Sun pointer components to match drawing orientation

S_norm = Sspin/3
S_plane = R ## [[S_norm(0)], [S_norm(1)]]

; Draw the Sun pointer

arrow, .5, .5, S_plane(0) + .5, S_plane(1) + .5, $
  /norm, thick=1, hthi=2, /sol, col=sunlight
xyouts, S_plane(0) + .5 + .03*S_plane(0)/abs(S_plane(0)), $
  S_plane(1) + .5 +.03*S_plane(1)/abs(S_plane(1)), /nor, 'S',col=sunlight
;print, 'S-angle (+) out of page: ', Sorth, ' degrees'

;; Get LAT, LNG (GEO) of Sun indicator (diagnostic)
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
    ds=string("260B)            ;" degree symbol
    if !d.name EQ 'PS' then linewidth=500 else linewidth=12
    
    ;; Angles out of page
    
    strings = ['Angles (+ out):', $
               'Bmod ' + string(format='(F5.1)',Borth)+ds, $
               'Vel  ' + string(format='(F5.1)',Vorth)+ds, $
               'Sun  ' + string(format='(F5.1)',Sorth)+ds   ]
    leg_loc = convert_coord(.030, .123, /norm, /to_device)
    line_xpos = make_array(4, /int, value=leg_loc(0))
    line_xpos(1:3) = line_xpos(1:3) + 10
    line_ypos = intarr(4)
    for p=0,3 do line_ypos(p) = leg_loc(1) - p*linewidth
    colors = [diagram, field, go, sunlight]
    xyouts, line_xpos, line_ypos, /device, strings, color=colors
    
    ;; Magnitudes
    
    strings = ['Magnitudes: ', $
               'B = ' + string(format='(I8)', Bmagnitude) + ' nT', $
               'V = ' + string(format='(F8.2)', Vmagnitude) + ' km/s']
    leg_loc = convert_coord(.655, .123, /norm, /to_device)
    line_xpos = make_array(3, /int, value=leg_loc(0))
    line_xpos(1:2) = line_xpos(1:2) + 10
    line_ypos = intarr(3)
    for p=0,2 do line_ypos(p) = leg_loc(1) - p*linewidth
    colors = [diagram, field, go]
    xyouts, line_xpos, line_ypos, /device, strings, color=colors
    
    ;; Time stamp
    
    date_time=str_sep(time_to_str(t, /msec), '/')
    strings = ['EPOCH: ', date_time(0), date_time(1)]
    leg_loc = convert_coord(.030, .954, /norm, /to_device)
    line_xpos = make_array(3, /int, value=leg_loc(0))
    line_xpos(1:2) = line_xpos(1:2) + 10
    line_ypos = intarr(3)
    for p=0,2 do line_ypos(p) = leg_loc(1) - p*linewidth
    xyouts, line_xpos, line_ypos, /device, strings, color=diagram
    
    ;; Orbit quantities
    
    strings = ['Orbit data:', $
               'FLAT ' + string(format='(F5.1)',flat.y(0))+ds, $
               'ILAT ' + string(format='(F5.1)',ilat.y(0))+ds, $
               'MLT  ' + string(format='(F5.1)',mlt.y(0))+' hr', $
               'ALT  ' + string(format='(I5)',alt.y(0))+' km' ]
    leg_loc = convert_coord(.655, .954, /norm, /to_device)
    line_xpos = make_array(5, /int, value=leg_loc(0))
    line_xpos(1:4) = line_xpos(1:4) + 10
    line_ypos = intarr(5)
    for p=0,4 do line_ypos(p) = leg_loc(1) - p*linewidth
    xyouts, line_xpos, line_ypos, /device, strings, color=diagram
endif 

if keyword_set(psfile) then pclose
!p.font = oldfont

end
