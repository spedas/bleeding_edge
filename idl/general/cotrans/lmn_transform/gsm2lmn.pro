;+
; NAME:
;     GSM2LMN
;
; PURPOSE:
;	Routine transforms vector field from GSM to LMN (boundary-normal)
;	coordinate system for magnetopause. Shue et al., 1998 magnetopause model
;	is used.
;
; CATEGORY:
;	Coordinate Transformation
;
; CALLING SEQUENCE:
;	gsm2lmn,txyz,Bxyz,Blmn,swdat
;
; INPUTS:
;	txyz: | t | x  | y  | z | - time and GSM position of the input vector (Bxyz).
;           - 2D array (nvectors,4)
;	Bxyz: | Bx | By | Bz | - vector field to transform (in GSM).
;           - 2D array (nvectors,3)
; OPTIONAL INPUT:
;	swdat: | t | Dp | Bz | of IMF at the bow-shock nose covering time
;		interval of interest. 2D array (ntimepoints,3). The time points
;		may be different from those of the vector field. However, they
;		should use the same time units.
;		If this input is not provided, the SPDF standard static SW data
;		are generated.
;
; KEYWORDS: none
;
; PARAMETERS: none
;
; OUTPUTS:
;	Blmn: | Bl | Bm | Bn | - vector in LMN at the same space-time points.
;		- 2D array (nvectors,3)
;
; DEPENDENCIES: None - can be used alone. Lowest-level part of LMN transform package.
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2007/12/28 on the base of
;	the code xyz2lmnshue by Liu Jiang (09/21/2007)
;	Modified for error handling, changed () to [] for arrays, and now correctly
;	indexes for loop with long integers for large arrays
;	                                     by: Lynn B. Wilson III    2012/10/26
;-
;
; THE CODE BEGINS:

PRO gsm2lmn,txyz,Bxyz,Blmn,swdat

;Some input check for vector field
sizebxyz = SIZE(bxyz)
sizetxyz = SIZE(txyz)
IF (sizebxyz[0] NE 2) THEN BEGIN
   dprint, 'gsm2lmn: Bxyz must be vector (array).'
   RETURN
ENDIF
IF (sizetxyz[0] NE 2) THEN BEGIN
   dprint, 'gsm2lmn: You must provide space-time coordinates of input vectors as 2D array.'
   RETURN
ENDIF
IF (sizebxyz[1] NE sizetxyz[1]) THEN BEGIN
   dprint, 'gsm2lmn: first dimensions of coordinate and vector arrays must be equal.'
   RETURN
ENDIF

;Check SW input.
sizesw   = SIZE(swdat)
IF (sizesw[0] EQ 0) THEN BEGIN
   ;Generate static "standard" SW data.
   dprint, 'gsm2lmn: No SW input detected. Static MP considered with Bz=0 and Dp=2.088 nPa.'
   swdata = DBLARR(sizebxyz[1],3)
   swdata[*,0] = txyz[*,0]
   swdata[*,1] = 2.088
   swdata[*,2] = 0.D
ENDIF ELSE BEGIN
   swdata      = DBLARR(sizebxyz[1],3)
   ;Replace bad values with static data and INTERPOLate Bz and Dp onto the timegrid of Bxyz.
   timeb       = REFORM(txyz[*,0])
   swdata[*,0] = timeb
   timesw      = REFORM(swdat[*,0])
   dparr       = REFORM(swdat[*,1])
   ind         = WHERE(FINITE(dparr),n,COMPLEMENT=indbad,NCOMPLEMENT=nbad)
   IF (nbad GT 0) THEN dparr[indbad] = 2.088 ;; nPa - a 'standard' value
   dparra      = INTERPOL(dparr,timesw,timeb)
   swdata[*,1] = dparra
   bzarr       = REFORM(swdat[*,2])
   ind         = WHERE(FINITE(bzarr),n,COMPLEMENT=indbad,NCOMPLEMENT=nbad)
   IF (nbad GT 0) THEN bzarr[indbad] = 0. ;; nT - a 'standard' value
   bzarra      = INTERPOL(bzarr,timesw,timeb)
   swdata[*,2] = bzarra
ENDELSE

blmn     = DBLARR(sizebxyz[1],sizebxyz[2])
npoints  = sizebxyz[1]
;; Transformation starts
FOR i=0L, npoints - 1L DO BEGIN
   bz    = swdata[i,2]
   dp    = swdata[i,1] > 0.01
   x     = txyz[i,1]
   y     = txyz[i,2]
   z     = txyz[i,3]
   alpha = (0.58 - 0.007*bz)*(1 + 0.024*ALOG(dp))

   theta = ACOS(x/SQRT(x^2 + y^2 + z^2))
   rho   = SQRT(y^2 + z^2)
   IF (rho GT 0.) THEN BEGIN
      tang1 = [0.,z,-y]
      tang2 = [x,y,z]*alpha*SIN(theta)/(1 + COS(theta)) + [-rho^2, x*y, x*z]/rho
      tang1 = tang1/SQRT(TOTAL(tang1^2))
      tang2 = tang2/SQRT(TOTAL(tang2^2))
      dN = CROSSP(tang1,tang2)
      dM = CROSSP(dN, [0,0,1])
      dM = dM/SQRT(TOTAL(dM^2))
      dL = CROSSP(dM, dN)
   ENDIF ELSE BEGIN
      dN = [1.,0.,0.]
      dM = [0.,-1.,0.]
      dL = [0.,0.,1.]
   ENDELSE
   ;; Define transformation matrix
   transm    = [[dL],[dM],[dN]]
   ;; Rotate input:  GSM -> LMN
   blmn[i,*] = bxyz[i,*] # transm
ENDFOR

dprint,  'gsm2lmn finished.'

END
