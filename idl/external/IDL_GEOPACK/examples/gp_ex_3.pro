pro gp_ex_3

; Show geopack version installed

help,'geopack',/dlm


; Set time 2022-11-23 01:00:30

year = 2007
doy = 82
hour = 0
minute = 0
sec = 0

; Start position (GSW in RE) (ERG s/c position at start time)

startpos_gsm_x = 1.0773251061938103D
startpos_gsm_y = 4.5740390469308823D
startpos_gsm_z = 2.9926138096815640D

; Convert to GSE using the non-08 recalc and coordinate conversion
geopack_recalc, year, doy, hour, minute, sec, tilt = tilt
geopack_conv_coord,/from_gsm, /to_gse, startpos_gsm_x, startpos_gsm_y, startpos_gsm_z, xgse, ygse, zgse

;Now convert to GSW without specifying a solar wind velocity
geopack_recalc_08, year, doy, hour, minute, sec, tilt = tilt

geopack_conv_coord_08, /from_gse, /to_gsw, xgse, ygse, zgse, xgsw, ygsw, zgsw

; Now use a solar wind velocity with a Y component to see the effect of the aberration
geopack_recalc_08, year, doy, hour, minute, sec, tilt = tilt, vgse=[-400, 28.71, 0]

geopack_conv_coord_08, /from_gse, /to_gsw, xgse, ygse, zgse, xgsw_ab, ygsw_ab, zgsw_ab

print, 'gsm:', startpos_gsm_x, startpos_gsm_y, startpos_gsm_z
print, 'gse:', xgse, ygse, zgse
print, 'gsw:', xgsw, ygsw, zgsw
print, 'gsw_ab:', xgsw_ab, ygsw_ab, zgsw_ab

; calculate angle between gsw and gsw_ab

dp = xgsw*xgsw_ab + ygsw*ygsw_ab + zgsw*zgsw_ab
r1 = sqrt(total(xgsw*xgsw + ygsw*ygsw + zgsw*zgsw))
r2 = sqrt(total(xgsw_ab*xgsw_ab + ygsw_ab*ygsw_ab + zgsw_ab*zgsw_ab))
costheta = dp/(r1*r2)
theta=acos(costheta)
print, 'angular difference (deg): ', theta*180.0/!pi
end