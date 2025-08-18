;+
; FUNCTION: THM_EFI_DERIVE_EZ, E, B, minBz=minBz, minRat=minRat, ratio=ratio
;                   
;
; PURPOSE: DERIVES EZ ASSUMING EdotB = 0
;
; INPUT: 
;       E -       REQUIRED. Data structure in DSL
;       B -       REQUIRED. Data structure in DSL
;
; KEYWORDS: 
;       minBz -       OPTIONAL. Keeps from divide by zero. DEFAULT = 0.01 nT
;       minRat -      OPTIONAL. Minimum value of Bz/|B|.  DEFAULT = 0.1
;       ratio -       OUTPUT. = Bz/|B|
;
; CALLING: thm_efi_derive_Ez, Edsl, Bdsl 
;
; OUTPUT: Tplot 
;
;
; INITIAL VERSION: REE 08-11-04
; MODIFICATION HISTORY: 
; REE 09_05_01
; LASP, CU
; 
;-

function thm_lsp_derive_ez, E, B, minBz=minBz, minRat=minRat, ratio=ratio

; CHECK KEYWORDS
if not keyword_Set(minBz) then minBz=0.01 ; nT
if not keyword_Set(minRat) then minRat=0.1 ; Ratio

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
indp = where((Bz LT minBz) AND (Bz GE 0.0), np)
indn = where((Bz GT -minBz) AND (Bz LT 0.0), nn)
Bm = Bz
if np GT 0 then Bm(indp) = minBz
if nn GT 0 then Bm(indn) = -minBz
Eder = -(Ex*Bx+Ey*By) / Bm
ratio  = Bz/BT
indbad = where(abs(ratio) LT minRat, nbad)
if nbad GT 0 then Eder(indbad) = !values.d_nan
return, Eder
end
