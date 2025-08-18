;+
; PRO: THM_EFI_DERIVE_EZ, Edsl, Bdsl, new_name=new_name
;                   
;
; PURPOSE: DERIVES EZ ASSUMING EdotB = 0
;
; INPUT: 
;       Edsl -       REQUIRED. STRING Efield data name (tplot).
;       Bdsl -       REQUIRED. STRING Bfield data (tplot)
;
; CALLING: thm_efi_derive_Ez, Edsl, Bdsl 
;
; OUTPUT: Tplot 
;
;
; INITIAL VERSION: REE 08-11-04
; MODIFICATION HISTORY: 
; LASP, CU
; 
;-

pro thm_efi_derive_Ez, Edsl, Bdsl, new_name=new_name

; CHECK KEYWORDS
if not keyword_set(new_name) then new_name = Edsl

; GET DATA
get_data, Edsl, data=E, dlim = elim
IF not keyword_set(E) then BEGIN
  print, 'Ename NOT VALID'
  return
ENDIF

get_data, Bdsl, data=B
IF not keyword_set(B) then BEGIN
  print, 'Bname NOT VALID'
  return
ENDIF

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

; DERVIVE EAxial
BT = sqrt(Bx*Bx + By*By + Bz*Bz)
indp = where((Bz LT 1.0) AND (Bz GE 0.0), np)
indn = where((Bz GT -1.0) AND (Bz LT 0.0), nn)
Bm = Bz
if np GT 0 then Bm(indp) = 1.0
if nn GT 0 then Bm(indn) = -1.0
Eder = -(Ex*Bx+Ey*By) / Bm
indbad = where(abs(Bz/BT) LT 0.1, nbad)
if nbad GT 0 then Eder(indbad) = !values.d_nan
Etemp = dblarr(n_elements(E.x),4)
Etemp(*,0) = E.y(*,0)
Etemp(*,1) = E.y(*,1)
Etemp(*,2) = E.y(*,2)
Etemp(*,3) = Eder

; STORE
dlim = {CDF: elim.cdf, SPEC: 0b, LOG: 0b, YSUBTITLE: '(mV/m)', $
  DATA_ATT: elim.data_att, COLORS: [elim.colors, 0], $
  LABELS: ['Ex', 'Ey', 'Ez', 'E!Dzder!N'], LABFLAG: elim.labflag, $
  YTITLE: 'E - ' + elim.data_att.coord_sys}
store_data, new_name, data={X:e.x, Y: Etemp, V: [1,2,3,4]}, dlim=dlim

return
end
