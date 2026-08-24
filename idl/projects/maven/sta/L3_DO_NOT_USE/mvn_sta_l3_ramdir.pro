;+
;Calculate angle that ram direction makes to APP i direction. In normal operations, this should be ~zero. When this deviates
;by too much, STATIC moments are not calibrated, as attenuator can no longer be RAM pointing.
;
;
;INPUTS:
;SPICE must be loaded.
;
;OUTPUTS:
;tplot variable containing the angle (in degrees) between RAM direction and i direction in APP frame: 'mvn_sta_ramdir_angle'. Note,
;this variable is produced at the default 10 second cadence, so will need to be interpolated to the STATIC timestamps outside of this 
;routine.
;
;-
;

pro mvn_sta_l3_ramdir

mvn_ramdir, frame='MAVEN_APP'  ;this requires maven_orbit_tplot to have been run first

get_data, 'V_sc_MAVEN_APP', data=ddapp

;Calculate angle to i direction:
;cos(theta) = a-dot-b/|A||B|
vec1 = [1., 0., 0.]  ;i in APP frame

adotb = (vec1[0]*ddapp.y[*,0]) + (vec1[1]*ddapp.y[*,1]) + (vec1[2]*ddapp.y[*,2])

mag_a = sqrt(vec1[0]^2 + vec1[1]^2 + vec1[2]^2)
mag_b = sqrt(ddapp.y[*,0]^2 + ddapp.y[*,1]^2 + ddapp.y[*,2]^2)

theta = acos(adotb/(mag_a*mag_b)) * (180./!pi)  ;units of degrees

;Store:
tname = 'mvn_sta_ramdir_angle'
store_data, tname, data={x: ddapp.x, y: theta}
  options, tname, ytitle='RAM angle!C!CAPP [!U0!N]'

end


