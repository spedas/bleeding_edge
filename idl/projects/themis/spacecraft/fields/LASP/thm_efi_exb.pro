;+
; PRO: THM_EFI_ExB, Ename, Bname, Sname=Sname, Vname=Vname, $
;                   EdotB=EdotB, Btot=Btot
;
; PURPOSE: Calculate Poynting Flux and Flow Velocity
;
; INPUT: 
;       Eanme -       REQUIRED. STRING Efield data name (tplot).
;       Bname -       REQUIRED. STRING Bfield data (tplot)
;       Sname -       OPTIONAL. Poynting Flux name (tplot)
;       Vname -       OPTIONAL. Velocity Flow name (tplot)
;
; CALLING: thm_efi_exb, Ename, Bname, Sname 
;
; OUTPUT: Poynting Flux is Calculated 
;
;
; INITIAL VERSION: REE 08-10-31
; LASP, CU
; MODIFICATION HISTORY: 
;       2010-02-21: Added a check of the coordinate systems of Ename and Bname.
;                   -JBT, CU/LASP.
; 
;-

pro thm_efi_exb, Ename, Bname, Sname=Sname, Vname=Vname, EdotB=EdotB, $
  Btot = Btot

; GET DATA
get_data, Ename, data=E, dlim = elim
IF not keyword_set(E) then BEGIN
  print, 'Ename NOT VALID'
  return
ENDIF

get_data, Bname, data=B, dlim = blim
IF not keyword_set(B) then BEGIN
  print, 'Bname NOT VALID'
  return
ENDIF

; check the coordinates of Ename and Bname
ecoord = cotrans_get_coord(Ename)
ecoord = strmid(ecoord, 0, 3)
bcoord = cotrans_get_coord(Bname)
bcoord = strmid(bcoord, 0, 3)
if not strcmp(ecoord, bcoord, /fold) then begin
   print, 'THM_EFI_EXB: ' + $
      '(WARNING) The input E and B fields are not in the same coordinates.'
   print, 'The output velocity and Poynting flux will be in the same ' + $
      'coordinates as the input E field.'
   Bname2 = Bname+'_' + ecoord
   thm_cotrans, Bname, Bname2, out_c = ecoord
   get_data, Bname2, data=B, dlim = blim
endif

; ISOLATE INDIVIDUAL COMPONENTS
Ex = E.y[*,0]
Ey = E.y[*,1]
Ez = E.y[*,2]

; ISOLATE INDIVIDUAL COMPONENTS
Bx = B.y[*,0]
By = B.y[*,1]
Bz = B.y[*,2]

; INTERPOLATE B
Bx = Interpol(Bx, b.x, e.x)
By = Interpol(By, b.x, e.x)
Bz = Interpol(Bz, b.x, e.x)

; CALCULATE POYNTING FLUX
Sx = Ey*Bz - Ez*By
Sy = Ez*Bx - Ex*Bz
Sz = Ex*By - Ey*Bx

IF keyword_set(Sname) THEN BEGIN
  ; RECONSTRUCT
  u0 = 4.0*!pi*1.0e-7
  S = E
  S.y[*,0] = u0*Sx*1e3 
  S.y[*,1] = u0*Sy*1e3
  S.y[*,2] = u0*Sz*1e3
  ; STORE
  data_att = {DATA_TYPE: 'calibrated', COORD_SYS: ecoord, UNITS: 'W/m^2 x 10^-15'}
  dlim = {SPEC: 0b, LOG: 0b, COLORS: elim.colors, $
    YSUBTITLE: '(mW/m!U2!N x 10!U-15!N)', YTITLE: 'Poynting FLux', $
    LABELS: elim.labels, LABFLAG: 1L, DATA_ATT: data_att}
  dlim.labels = ['Sx', 'Sy', 'Sz']
  store_data, Sname(0), data=S, dlim=dlim
ENDIF

; DO VELOCITY
IF keyword_set(Vname) THEN BEGIN
  B2 = Bx*Bx + By*By + Bz*Bz
  V = E
  V.y[*,0] = Sx/B2 * 1.e3 ; km/s
  V.y[*,1] = Sy/B2 * 1.e3 ; km/s
  V.y[*,2] = Sz/B2 * 1.e3 ; km/s
  data_att = {DATA_TYPE: 'calibrated', COORD_SYS: ecoord, UNITS: 'km/s'}
  dlim = {SPEC: 0b, LOG: 0b, COLORS: elim.colors, $
    YSUBTITLE: '(km/s, '+ecoord+')', YTITLE: 'ExB Velocity', $
    LABELS: elim.labels, LABFLAG: 1L, DATA_ATT: data_att}
  dlim.labels = ['Vx', 'Vy', 'Vz']
  store_data, vname(0), data=V, dlim=dlim
ENDIF

; DO EdotB
IF keyword_set(EdotB) THEN BEGIN  
  BT = sqrt(Bx*Bx + By*By + Bz*Bz)
  EB = (Ex*Bx+Ey*By+Ez*Bz)/BT
  Etemp = dblarr(n_elements(E.x),4)
  Etemp(*,0) = E.y(*,0)
  Etemp(*,1) = E.y(*,1)
  Etemp(*,2) = E.y(*,2)
  Etemp(*,3) = EB
  ; STORE
  dlim = {CDF: elim.cdf, SPEC: 0b, LOG: 0b, YSUBTITLE: '(mV/m)', $
    DATA_ATT: elim.data_att, COLORS: [elim.colors, 0], $
    LABELS: ['Ex', 'Ey', 'Ez', 'E!D||!N'], LABFLAG: elim.labflag, $
    YTITLE: 'E - ' + elim.data_att.coord_sys}
  store_data, EdotB(0), data={X:e.x, Y: Etemp, V: [1,2,3,4]}, dlim=dlim
ENDIF

; DO BTOT
IF keyword_set(Btot) THEN BEGIN
  Babs = sqrt(B.y[*,0]*B.y[*,0] + B.y[*,1]*B.y[*,1] + B.y[*,2]*B.y[*,2])
  ; RECONSTRUCT
  Btemp = dblarr(n_elements(B.x),4)
  Btemp(*,0) = B.y(*,0)
  Btemp(*,1) = B.y(*,1)
  Btemp(*,2) = B.y(*,2)
  Btemp(*,3) = Babs
  ; STORE
  dlim = {CDF: blim.cdf, SPEC: 0b, LOG: 0b, YSUBTITLE: blim.ysubtitle, $
    DATA_ATT: blim.data_att, COLORS: [blim.colors, 0], $
    LABELS: ['Bx', 'By', 'Bz', 'Btot'], LABFLAG: blim.labflag, $
    YTITLE: blim.ytitle}
  store_data, Btot(0), data={X:b.x, Y: Btemp, V: [1,2,3,4]}, dlim=dlim
ENDIF

return
end
