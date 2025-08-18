;+
; Procedure: enp_crib.pro
;
; Purpose:  A crib showing how to transform data from ENP coordinates to GEI coordinates and vice versa
;
;   E: sat to earth (in orbtial plane)
;   N: east (in orbital plane)
;   P: north (perpendicular to orbtial plane).
;
;  Defined relative to another coordinate system:
;   P_sat = spacecraft position in geocentric inertial coordinate system
;   V_sat = deriv(P_sat)   (spacecraft velocity in the same coordinate system.)
;
;
;   P_enp = P_sat cross V_sat
;   E_enp = -P_sat
;   N_enp = P_enp cross P_sat
;
;Notes:
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-11 08:33:06 -0800 (Tue, 11 Feb 2014) $
; $LastChangedRevision: 14275 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/enp/enp_crib.pro $
;-

  ;set the time
  timespan,'2008-03-01', 5, /days

  ;load some 1-m resolution FGM data for GOES 10
  goes_load_data, trange = trange, probes='10', datatype='fgm', /avg_1m

  ;----------------
  ;ENP system
  ;----------------
  
  ;input position MUST be earth-centered and inertial
  ;velocity/orbital plane determined using derivative of position.
  ;If there are not enough points, the result will be inaccurate.  Also, may have small error at the tails.
  enp_matrix_make,'g10_pos_gei'  ;accepts newname,suffix keywords, can use globbing on inputs
  stop
  
  ;--------------------
  ;ENP->GEI
  ;-------------------- 
 
  tvector_rotate,'g10_pos_gei_enp_mat','g10_H_enp',/invert  ;invert keyword runs transformation backwards

  ; rename the new tplot variable
  copy_data, 'g10_H_enp_rot', 'g10_H_gei'
  
  ; set the default options
  options,'g10_H_gei',labels=['Bx','By','Bz'],ytitle='g10_H_gei'
  
  ; plot the field components in GEI coordinates
  tplot, 'g10_H_gei'
  stop

  ;--------------------
  ;GEI->ENP
  ;--------------------

  ;this routine interpolate rotation matrices automatically, no need to match cadence ahead of time
  tvector_rotate,'g10_pos_gei_enp_mat','g10_H_enp'   ;accepts newname,suffix keywords, can use globbing on inputs

  options,'g10_H_enp_rot',labels=['E','N','P'],ytitle='g10_H_enp'
  
  options,'g10_H_enp',yrange=[-100,150]

  tplot,['g10_H_enp']

  stop
  
  ;-----------------------
  ;User Provided Velocity, Rather than derivative of position velocity
  ;-----------------------
  
  tinterpol_mxn,'g10_pos_gei','g10_H_enp'
  
  enp_matrix_make,'g10_pos_gei',velocity_tvar='g10_vel_gei'
  
  tvector_rotate,'g10_pos_gei_enp_mat','g10_H_gei'   ;accepts newname,suffix keywords, can use globbing on inputs

  options,'g10_H_gei_rot',labels=['E','N','P'],ytitle='g10_H_enp'

  tplot,['g10_H_gei_rot','g10_H_enp'] ;should match
  
  stop
  
  ;------------------------------
  ;User provided Single Orbital Element, doesn't use velocity at all
  ;------------------------------
  
  ;GOES 10 orbital elements for 2007-12-17
  orbital_time = time_double('2007-12-17/01:37:56')
  orbital_ras =   81.7391D ;right ascension of ascending node
  orbital_inclination = 2.2461 ;orbital inclination
  
  orbital_elements = [orbital_time,orbital_ras,orbital_inclination]
  
  enp_matrix_make,'g10_pos_gei',orbital_elements=orbital_elements
   
  tvector_rotate,'g10_pos_gei_enp_mat','g10_H_gei'   ;accepts newname,suffix keywords, can use globbing on inputs
  
  options,'g10_H_gei_rot',labels=['E','N','P'],ytitle='g10_H_enp'

  tplot,['g10_H_gei_rot','g10_H_enp'] ;Should be small error due to accumultated time-series error orbital elements.
                                      ;Occurs at the GEI-POS-Z 0-crossing.
                                      ;Should be fixed by interpolated orbital elements. 

  stop
  
  ;------------------------------
  ;User provided Interpolated Orbital Element, doesn't use velocity at all
  ;-------------------------
  
  orbital_time1 = time_double('2007-12-10/06:52:04')
  orbital_ras1 = 081.8024D
  orbital_inclination1 = 2.2298D
  
  orbital_time2 = time_double('2007-12-17/01:37:56')
  orbital_ras2 =   81.7391D ;right ascension of ascending node
  orbital_inclination2 = 2.2461D ;orbital inclination
  
  ;Can have as many orbital elements as you want, not limited to providing elements at only 2 times 
  orbital_elements = [[orbital_time1,orbital_ras1,orbital_inclination1],[orbital_time2,orbital_ras2,orbital_inclination2]]
  
  enp_matrix_make,'g10_pos_gei',orbital_elements=orbital_elements
   
  tvector_rotate,'g10_pos_gei_enp_mat','g10_H_gei'   ;accepts newname,suffix keywords, can use globbing on inputs
  
  options,'g10_H_gei_rot',labels=['E','N','P'],ytitle='g10_H_enp'

  tplot,['g10_H_gei_rot','g10_H_enp']
  
end