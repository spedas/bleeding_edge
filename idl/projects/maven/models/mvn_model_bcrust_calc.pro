;+
;
;FUNCTION:        MVN_MODEL_BCRUST_CALC
;
;PURPOSE:         Calculates vector magnetic field at a given location (a_over_r, sct, scp)
;                 in spherical coordinates from a spherical harmonic crustal model.
;
;INPUTS: 
;         
;      G, H:      The coefficients, in square arrays with dimensions [nmax+1, nmax+1].
;                 Coeffs are stored according to [n, m].
;
;  A_OVER_R:      The value of a/r in the spherical harmonic expansion,
;                 or the mean Martian radius by the radius at which
;                 you are calculating the field.
;
;  SCT, SCP:      The colatitude and east longitude at which you are calculating
;                 the field, IN RADIANS.
;
;OUTPUTS:         [Br, Bt, Bp] at scr, sct, scp.
;
;KEYWORDS:        None.
;
;NOTE:            It originally comes from sph_b.pro, which is a subroutine included in mvn_model_bcrust.pro.
;                 The original sph_b.pro was written by Dave Brain on 2001-10-08.
;                 It is vectorized to perform the fast calculation.
;
;CREATED BY:      Takuya Hara on 2020-07-07.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2020-07-07 11:27:32 -0700 (Tue, 07 Jul 2020) $
; $LastChangedRevision: 28856 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/models/mvn_model_bcrust_calc.pro $
;
;-

FUNCTION mvn_model_bcrust_calc_legendre, nmax, x

;NOTE:   It originally comes from legendre_schmidt_all.pro, which is a subroutine included in mvn_model_bcrust.pro.
;        The original sph_b.pro was written by Dave Brain on 2001-10-05.
;        It is vectorized to perform the fast calculation.

  ndat = N_ELEMENTS(x)

  P = DBLARR(nmax+1, nmax+1, ndat)
  P[0, 0, *] = 1d

  IF nmax GT 0 THEN BEGIN
     twoago = 0d0
     FOR i=1, nmax DO BEGIN
        P[i, 0, *] = ( x * (2d0*i - 1d0) * P[i-1, 0, *] - $
                       (i - 1d0) * twoago ) / (i)
        twoago = P[i-1, 0, *]
     ENDFOR
  ENDIF

  Cm = SQRT(2D0)
  FOR m=1d0, nmax DO BEGIN
     Cm = Cm / SQRT(2d0*m*(2d0*m-1d0))

     P[m, m, *] = (1d0 - x^2)^(0.5d0 * m) * Cm

     FOR i=1d0, m-1 DO P[m, m, *] = (2d0*i + 1d0) * P[m, m, *]
     
     IF nmax GT m THEN BEGIN
        twoago = 0d0
        FOR i = m+1d0, nmax DO BEGIN
           P[i, m, *] = ( x * (2d0*i - 1d0) * P[i-1, m, *] - $
                          SQRT( (i+m-1d0) * (i-m-1d0) ) * twoago ) / $
                        SQRT( ( i*i - m*m ) )
           twoago = P[i-1, m, *]
        ENDFOR
     ENDIF
  ENDFOR ; m = 1D, nmax

  RETURN, TEMPORARY(P)
END

 
FUNCTION mvn_model_bcrust_calc, g, h, a_over_r, sct, scp, test=test
  IF KEYWORD_SET(test) THEN t0 = SYSTIME(/sec)
  ndat = N_ELEMENTS(a_over_r)

  ; Determine nmax
  nmax = N_ELEMENTS(g[0, *]) - 1
  cntarr = DINDGEN(nmax+1)

  ; Compute R(r) and dR(r) at each n
  ;  Only compute parts inside the summation over n
  ;  R(r) = [a/r]^(n+1)
  ;  dR(r) = (n+1)*[a/r]^(n+1)  ( Factors omitted that can move
  ;                               outside of summation - see
  ;                               pg 34 in Thesis Book 2 )

  IF ndat GT 1 THEN BEGIN
     R = TRANSPOSE(REBIN(a_over_r, ndat, nmax+1, /sample))
     dR = R
     FOR n=1, nmax DO BEGIN
        R[n, *]  = R[n, *] ^ (cntarr[n] + 1)
        dR[n, *] = R[n, *] * (cntarr[n] + 1)
     ENDFOR
  ENDIF ELSE BEGIN
     R = (a_over_r)^(cntarr+1)
     dR = R*(cntarr+1)
  ENDELSE
  IF KEYWORD_SET(test) THEN $
     dprint, 'R, dR are completed: ' + time_string(systime(/sec)-t0, tformat='mm:ss.fff, ') + $
             string(double(memory(/current))/1.d9, '(F0.2)') + ' GB required.'

  ; Compute Phi(phi) and dPhi(phi) at each m,n combo
  ;  Phi(phi) = gnm * cos(m*phi) + hnm * sin(m*phi)
  ;  dPhi(phi) = m * [-gnm * sin(m*phi) + hnm * cos(m*phi)]
  cos_m_phi = COS( cntarr # scp )
  sin_m_phi = SIN( cntarr # scp )

  Phi  = g*0d
  dPhi = Phi
  IF ndat GT 1 THEN BEGIN
     Phi = REBIN(Phi, nmax+1, nmax+1, ndat, /sample)
     dPhi = REBIN(dPhi, nmax+1, nmax+1, ndat, /sample)
  ENDIF

  FOR n=1, nmax DO BEGIN
     if keyword_set(test) then print, n
     IF ndat GT 1 THEN BEGIN
        Phi[n, *, *]  = REFORM(cos_m_phi * REBIN(REFORM(g[n, *]), nmax+1, ndat, /sample) + $
                               sin_m_phi * REBIN(REFORM(h[n, *]), nmax+1, ndat, /sample), 1, nmax+1, ndat)
        dPhi[n, *, *] = REFORM((cos_m_phi * REBIN(REFORM(h[n, *]), nmax+1, ndat, /sample) - $
                                sin_m_phi * REBIN(REFORM(g[n, *]), nmax+1, ndat, /sample)) * REBIN(cntarr, nmax+1, ndat, /sample), $
                               1, nmax+1, ndat)
     ENDIF ELSE BEGIN
        Phi[n, *]  = cos_m_phi * g[n, *] + sin_m_phi * h[n, *]
        dPhi[n, *] = ( cos_m_phi * h[n, *] - sin_m_phi * g[n, *] ) * cntarr
     ENDELSE
  ENDFOR ; n = 1, nmax
  IF KEYWORD_SET(test) THEN $
     dprint, 'Phi, dPhi are completed: ' + time_string(systime(/sec)-t0, tformat='mm:ss.fff, ') + $
             string(double(memory(/current))/1.d9, '(F0.2)') + ' GB required.'

  ;  Compute Theta and dTheta at each m, n combo
  ;  Theta(theta) = P(n,m,x) the Schmidt normalized associated legendre poly.
  ;  dTheta(theta) = m * cos(theta) / sin(theta) * P(n,m,x) -
  ;                  C(n,m) / C(n,m+1) * P(n,m+1,x)
  ;                  Where C(n,m) = 1 if m=0
  ;                               = ( 2 * (n-m)! / (n+m)! ) ^ (1/2)
  ;                  Cool math tricks are involved

  cos_theta = cos(sct)
  sin_theta = sin(sct)

  Theta = mvn_model_bcrust_calc_legendre(nmax, cos_theta)
  IF KEYWORD_SET(test) THEN $
     dprint, 'Legendre poly expansion is completed: ' + time_string(systime(/sec)-t0, tformat='mm:ss.fff, ') + $
             string(double(memory(/current))/1.d9, '(F0.2)') + ' GB required.'

  dTheta = Theta*0d

  IF ndat GT 1 THEN BEGIN
     dTheta[1, *, *] = REFORM(REBIN(cntarr, nmax+1, ndat, /sample), 1, nmax+1, ndat) * Theta[1, *, *]
     dTheta[1, *, *] = REFORM(dTheta[1, *, *]) * REFORM(TRANSPOSE(REBIN((cos_theta / sin_theta), ndat, nmax+1, /sample)), 1, nmax+1, ndat)
  ENDIF ELSE dTheta[1, *] = cntarr * cos_theta / sin_theta * Theta[1, *]

  dTheta[1, 0, *] = dTheta[1, 0, *] - Theta[1, 1, *]

  FOR n = 2, nmax DO BEGIN
     if keyword_set(test) then print, n
     IF ndat GT 1 THEN BEGIN
        dTheta[n, *, *] = REFORM(REBIN(cntarr, nmax+1, ndat, /sample), 1, nmax+1, ndat) * Theta[n, *, *]
        dTheta[n, *, *] = REFORM(dTheta[n, *, *]) * REFORM(TRANSPOSE(REBIN((cos_theta / sin_theta), ndat, nmax+1, /sample)), 1, nmax+1, ndat)

        dTheta[n, 0, *] = dTheta[n, 0, *] - $
                          SQRT( (n * (n+1)) * 0.5d ) * Theta[n, 1, *]

        dTheta[n, 1:n, *] = dTheta[n, 1:n, *] - $
                            REFORM(REBIN(SQRT( (n-cntarr[1:n]) * (n+cntarr[1:n]+1) ), n, ndat, /sample), 1, n, ndat) * $
                            [ [ Theta[n, 2:n, *] ], [ REPLICATE(0d, 1, 1, ndat) ] ]
     ENDIF ELSE BEGIN
        dTheta[n, *] = cntarr * cos_theta / sin_theta * Theta[n, *]
        dTheta[n, 0] = dTheta[n, 0] - $
                       SQRT( (n * (n+1)) * 0.5d ) * Theta[n, 1]
        dTheta[n, 1:n] = dTheta[n, 1:n] - $
                         SQRT( (n-cntarr[1:n]) * (n+cntarr[1:n]+1) ) * $
                         [ [ Theta[n, 2:n] ], [ 0d ] ]
     ENDELSE
  ENDFOR ; n = 1, nmax
  IF KEYWORD_SET(test) THEN $
     dprint, 'Theta, dTheta are completed: ' + time_string(systime(/sec)-t0, tformat='mm:ss.fff, ') + $
             string(double(memory(/current))/1.d9, '(F0.2)') + ' GB required.'

  ; Put it all together

  ; Br = a/r Sum(n=1,nmax) { (n+1) * R(r) *
  ;      Sum(m=0,n) { Theta(theta) * Phi(phi) } }
  br = TOTAL( Theta*Phi, 2 )                                                   ; Sum over m for each n
  br = TOTAL( br * TEMPORARY(dR), 1) * a_over_r                                ; (0th element contributes 0)

  ; Btheta = B_SN
  ; Btheta = a*sin(theta)/r Sum(n=1,nmax) { R(r) *
  ;          Sum(m=0,n) { dTheta(theta) * Phi(phi) } }
  bt = TOTAL( TEMPORARY(dTheta)*TEMPORARY(Phi), 2 )                            ; Sum over m for each n
  bt = -1.d * total( bt * R, 1) * a_over_r                                     ; (0th element contributes 0)

  ; Bphi = B_EW
  ; Bphi = -a/r/sin(theta) Sum(n=1,nmax) { R(r) *
  ;        Sum(m=0,n) { Theta(theta) * DPhi(phi) } }
  bp = TOTAL( TEMPORARY(Theta)*TEMPORARY(dPhi), 2 )                            ; Sum over m for each n
  bp = -1.d * total( bp * TEMPORARY(R), 1) * a_over_r / TEMPORARY(sin_theta)   ; (0th element contributes 0)

  ; Return the vector field
  IF ndat EQ 1 THEN RETURN, [br, bt, bp] ELSE RETURN, TRANSPOSE([ [br], [bt], [bp] ])
END
