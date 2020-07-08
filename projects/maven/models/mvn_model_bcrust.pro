;+
;
;PROCEDURE:       MVN_MODEL_BCRUST
;
;PURPOSE:         Computes magnetic field predictions from the Martian
;                 crustal field model at the MAVEN location, an returns
;                 the predicutions in a named data structure.
;
;INPUTS:
;
;   TRANGE:       An array in any format accepted by time_double().
;                 The minimum and maximum values in this array specify
;                 the time range to calculate. If the elements of 1d
;                 time range array are more than 2, the crustal field
;                 model is calculated at the precise time steps.   
;
;KEYWORDS:
;
;   RESOLUTION:   Defines the time resolution. Default is 1sec. 
;
;         DATA:   Returns the calculated results as structure.
;    
;       ARKANI:   Uses Arkani-Hamed's spherical harmonic model. 
;                 (default nmax=62, but goes out to n=90)
;
;    CAIN_2003:   Uses Cain's 2003 spherical harmonic model.
;                 (default nmax=90)
;
;    CAIN_2011:   Uses Cain's 2011 spherical harmonic model.
;                 (default nmax=90)
;
;     PURUCKER:   Uses Purucker's spherical harmonic model.
;
; MORSCHHAUSER:   Uses Morschhauser's 2014 spherical harmonic model.
;                 (It is the default model to calculate).
;
;     LANGLAIS:   Uses Langlais's 2019 spherical harmonic model.
;
;         NMAX:   Specifies nmax for spherical harmonic model in the event
;                 the user does not want to use the full model
;                 (e.g. invoking /Cain defaults to nmax=90, but you
;                  could change to nmax=60 by adding nmax=60 when calling)
;
;      VERSION:   Specifies the version of the Cain 2011 model to be used.
;                 Default = 0. 
;                  
;        TPLOT:   Generates the tplot variables of crustal field model.
;
;         PATH:   Defines the file path which the IDL save file is stored. 
;                 In default, it is stored to the same place for this routine.
;
;          POS:   If user wants to use a pseudo location, or to explicitly  
;                 define the MAVEN location, you can use this keyword.
;                 The coordinate system must be IAU_MARS (planetocentric coordinates).
;                 The format must be two-dimensional 3 x N or N x 3 elements array.
;
;MODEL REFERENCES: 
;
;    CAIN_2003:   Cain, J. C., B. B. Ferguson, and D. Mozzoni (2003), 
;                 An n = 90 internal potential function of the Martian crustal magnetic field,
;                 J. Geophys. Res., 108(E2), 5008, doi:10.1029/2000JE001487.
;
;    CAIN_2011:   There is a no official paper published any journals.
;  
;       ARKANI:   Arkani-Hamed, J. (2004),
;                 A coherent model of the crustal magnetic field of Mars,
;                 J. Geophys. Res., 109, E09005, doi:10.1029/2004JE002265.
;
;     PURUCKER:  Lillis, R. J., M. E. Purucker, J. S. Halekas, K. L. Louzada,
;                S. T. Stewart-Mukhopadhyay, M. Manga, and H. V. Frey (2010), 
;                Study of impact demagnetization at Mars using Monte Carlo modeling
;                and multipile altitude data, 
;                J. Geophys. Res., 115, E07007, doi:10.1029/2009JE003556.
; 
;                Purucker, M. E. (2008), 
;                A global model of the internal magnetic field of the
;                Moon based on Lunar Prospector magnetometer observations,
;                Icarus, 197, 19-23, doi:10.1016/j.icarus.2008.03.016.  
;
; MORSCHHAUSER:  Morschhauser, A., V. Lesur, and M. Grott (2014), 
;                A spherical harmonic model of the lithospheric magnetic field of Mars,
;                J. Geophys. Res. Planets, 119, 1162-1188, doi:10.1002/2013JE004555.
;
;     LANGLAIS:  Langlais, B., Thebault, E., Houliez, A., Purucker, M. E., & Lillis, R. J. (2019), 
;                A new model of the crustal magnetic field of Mars using MGS and MAVEN, 
;                Journal of Geophysical Research: Planets, 124, 1542– 1569. https://doi.org/10.1029/2018JE005854.
;
;NOTES:
;   1. This routine is based on information from an IDL save file. The name
;      of the save file is set as 'martiancrustmodels.sav' in the main procedure. 
;
;      1'. The latest IDL save file is generated by Robert Lillis.
;          (This comment is noted by Takuya Hara.)
;
;   2. Several supporting subroutines are included in this file, and appear
;      BEFORE the main 'mvn_model_bcrust' routine.
;
;   3. Use of the models using this routine DOES NOT imply that the modelers 
;      have given you permission to use their models. Do not be afraid to 
;      contact them - they are generally very happy to share the models.  
;      But they would like to know who is using their model - especially 
;      before any talks or publications.
;      (This comment was noted by Dave Brain.)
;
;HISTORY:
;(YYYY-MM-DD)
; 2004-07-27: Original version was written by Dave Brain.
;             It was optimized to use the Mars Global Surveyor (MGS) data. 
; 2004-08-24: Last modification date by Dave.
; 2014-10-07: T. Hara revised to optimize for the MAVEN data.
;
;CREATED BY:	  Takuya Hara on 2015-02-12.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2020-07-07 11:33:30 -0700 (Tue, 07 Jul 2020) $
; $LastChangedRevision: 28857 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/models/mvn_model_bcrust.pro $
;
;-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;   SUPPORT ROUTINES   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function legendre_schmidt_all, nmax, x
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; legendre_schmidt_all.pro                              ;
;                                                       ;
; Function returns the Schmidt-normalized associated    ;
; legendre polynomials:                                 ;
;  P(n,m,x) = Cnm * (1-x^2)^(m/2) * d^m/dx^m P(n,x)     ;
; Where:                                                ;
;  Cnm = 1 if m=0                                       ;
;  Cnm = sqrt( 2 * (n-m)! / (n+m)! )                    ;
; for all n,m combinations where n=0-nmax and m=0-n     ;
;                                                       ;
; Inputs:                                               ;
;  nmax -   The maximum degree of the Assoc. Leg. Poly. ;
;  x    -   A number (should be between -1 and 1)       ;
;                                                       ;
; Output:                                               ;
;  P    -   A matrix with dimension [nmax+1,nmax+1]     ;
;           that contains P(n,m,x), stored in element   ;
;           [n,m], and 0 everywhere else                ;
;           Double precision is used                    ;
;                                                       ;
; Keywords:                                             ;
;                                                       ;
; Uses the recursion relation:                          ;
;  sqrt( n^2 - m^2) * P(n,m,x) =                        ;
;     x * (2*n-1) * P(n-1,m,x) -                        ;
;     sqrt( (n+m-1)*(n-m-1) ) * P(n-2,m,x)              ;
; Where:                                                ;
;  P(m,m) = Cnm * (1-x^2)^(m/2) * (2*m-1)!!             ;
;           !! = product of all odd integers <= 2m-1    ;
;  P(m-1,m) = 0                                         ;
;                                                       ;
; Assumes the user doesn't feed the routine nonsense    ;
;                                                       ;
; Dave Brain                                            ;
; October 5, 2001                                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   P = dblarr(nmax+1,nmax+1)
   
   P[0,0] = 1d
   
   IF nmax GT 0 THEN BEGIN
      twoago = 0d0
      FOR i = 1, nmax DO BEGIN
         P[i,0] = ( x * (2d0*i - 1d0) * P[i-1,0] - $
                   (i - 1d0) * twoago ) / (i)
         twoago = P[i-1,0]
      ENDFOR
   ENDIF
   
   Cm = sqrt(2D0)
   FOR m = 1d0, nmax DO BEGIN
   
      Cm = Cm / sqrt(2d0*m*(2d0*m-1d0))
   
      P[m,m] = (1d0 - x^2)^(0.5d0 * m) * Cm
   
      FOR i = 1d0, m-1 DO P[m,m] = (2d0*i + 1d0) * P[m,m]
   
      IF nmax GT m THEN BEGIN
         twoago = 0d0
         FOR i = m+1d0, nmax DO BEGIN
            P[i,m] = ( x * (2d0*i - 1d0) * P[i-1,m] - $
                       sqrt( (i+m-1d0) * (i-m-1d0) ) * twoago ) / $
                     sqrt( ( i*i - m*m ) )
            twoago = P[i-1,m]
         ENDFOR
      ENDIF
   
   ENDFOR; m = 1D, nmax
   
   return, P
   
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function sph_b, g, h, a_over_r, sct, scp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sph_b.pro                                     ;
;                                               ;
; Routine to calculate vector magnetic field    ;
;  at a given location (a_over_r,sct,scp) in    ;
;  spherical coordinates from a spherical       ;
;  harmonic model                               ;
;                                               ;
; Inputs:                                       ;
;  g, h are the coefficients, in square arrays  ;
;   with dimensions [nmax+1,nmax+1].  Coeffs    ;
;   are stored according to [n,m].              ;
;  a_over_r is the vaue of a/r in the spherical ;
;   harmonic expansion, or the mean planetary   ;
;   radius divided by the radius at which you   ;
;   are calculating the field                   ;
;  sct, scp are the colatitude and east         ;
;   longitude at which you are calculating      ;
;   the field, IN RADIANS                       ;
;                                               ;
; Output:                                       ;
;  [Br, Bt, Bp] at scr, sct, scp                ;
;                                               ;
; Dave Brain                                    ;
; October 8, 2001 - sct, scp to radians         ;
;                   a,r to a_over_r             ;
; October 4, 2001                               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ; Determine nmax
      nmax = n_elements(g[0,*]) - 1
      cntarr = dindgen(nmax+1)
   
   ; Compute R(r) and dR(r) at each n
   ;  Only compute parts inside the summation over n
   ;  R(r) = [a/r]^(n+1)
   ;  dR(r) = (n+1)*[a/r]^(n+1)  ( Factors omitted that can move 
   ;                               outside of summation - see
   ;                               pg 34 in Thesis Book 2 )
      R = (a_over_r)^(cntarr+1)
      dR = R*(cntarr+1)
   
   
   ; Compute Phi(phi) and dPhi(phi) at each m,n combo
   ;  Phi(phi) = gnm * cos(m*phi) + hnm * sin(m*phi)
   ;  dPhi(phi) = m * [-gnm * sin(m*phi) + hnm * cos(m*phi)]
      cos_m_phi = cos( cntarr * scp )
      sin_m_phi = sin( cntarr * scp )
   
      Phi  = g*0d
      dPhi = Phi
   
      FOR n = 1, nmax DO BEGIN
         Phi[n,*]  = cos_m_phi * g[n,*] + sin_m_phi * h[n,*]
         dPhi[n,*] = ( cos_m_phi * h[n,*] - sin_m_phi * g[n,*] ) * cntarr
      ENDFOR; n = 1, nmax
   
   
   ; Compute Theta and dTheta at each m,n combo
   ;  Theta(theta) = P(n,m,x)  the Schmidt normalized associated legendre poly.
   ;  dTheta(theta) = m * cos(theta) / sin(theta) * P(n,m,x) - 
   ;                  C(n,m) / C(n,m+1) * P(n,m+1,x)
   ;                  Where C(n,m) = 1 if m=0
   ;                               = ( 2 * (n-m)! / (n+m)! ) ^ (1/2)
   ;                  Cool math tricks are involved
      cos_theta = cos(sct)
      sin_theta = sin(sct)
   
      Theta = legendre_schmidt_all(nmax,cos_theta)
      reftime1 = systime(1)
      dTheta = g*0d
   
      dTheta[1,*] = cntarr * cos_theta / sin_theta * Theta[1,*]
      dTheta[1,0] = dTheta[1,0] - Theta[1,1]
   
      FOR n = 2, nmax DO BEGIN
         dTheta[n,*] = cntarr * cos_theta / sin_theta * Theta[n,*]
         dTheta[n,0] = dTheta[n,0] - $
                       sqrt( (n * (n+1)) * 0.5d ) * Theta[n,1]
         dTheta[n,1:n] = dTheta[n,1:n] - $
                         sqrt( (n-cntarr[1:n]) * (n+cntarr[1:n]+1) ) * $
                          [ [ Theta[n,2:n] ], [ 0d ] ]
      ENDFOR; n = 1, nmax
   
   
   ; Put it all together
   
   ; Br = a/r Sum(n=1,nmax) { (n+1) * R(r) * 
   ;      Sum(m=0,n) { Theta(theta) * Phi(phi) } }
      br = total( Theta*Phi, 2 )      ; Sum over m for each n
      br = total( br * dR ) * a_over_r ; (0th element contributes 0)
   
   ; Btheta = B_SN
   ; Btheta = a*sin(theta)/r Sum(n=1,nmax) { R(r) * 
   ;          Sum(m=0,n) { dTheta(theta) * Phi(phi) } }
      bt = total( dTheta*Phi, 2 )      ; Sum over m for each n
      bt = -1.d * total( bt * R ) * a_over_r ; (0th element contributes 0)
   
   ; Bphi = B_EW
   ; Bphi = -a/r/sin(theta) Sum(n=1,nmax) { R(r) * 
   ;        Sum(m=0,n) { Theta(theta) * DPhi(phi) } }
      bp = total( Theta*dPhi, 2 )      ; Sum over m for each n
      bp = -1.d * total( bp * R ) * a_over_r / sin_theta ; ( 0th element 
                                                         ;   contributes 0 )
   
   
   ; Return the vector field
      return, [br, bt, bp]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function datas2c, rdat, tdat, pdat, tposn, pposn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; datas2c   	    	    	    	    	    	;
;   	    	    	    	    	    	    	;
; Routine to convert spherical data to cartesian    	;
;   	    	    	    	    	    	    	;
; rdat, tdat, pdat are spherical data vector components ;
; tposn, pposn are theta and phi components of position ;
;   	    	    	    	    	    	    	;
; angles are in radians     	    	    	    	;
;   	    	    	    	    	    	    	;
; Dave Brain	    	    	    	    	    	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ; Calcute angles
      cp = cos(pposn)
      sp = sin(pposn)
      ct = cos(tposn)
      st = sin(tposn)

   ;; Transformation Matrix ;;
   ;                         ;
   ;  st*cp    ct*cp    -sp  ;
   ;                         ;
   ;  st*sp    ct*sp     cp  ;
   ;                         ;
   ;    ct       -st      0  ;
   ;                         ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ; Calcute x, y, z
      RETURN, [ $
         [ st * cp * rdat  +  ct * cp * tdat  -  sp * pdat ], $
         [ st * sp * rdat  +  ct * sp * tdat  +  cp * pdat ], $
         [      ct * rdat  -       st * tdat               ]    ]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function datac2s, xdat, ydat, zdat, tposn, pposn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; datas2c   	    	    	    	    	    	;
;   	    	    	    	    	    	    	;
; Routine to convert cartesian data to spherical    	;
;   	    	    	    	    	    	    	;
; xdat, ydat, zdat are cartesian data vector components ;
; tposn, pposn are theta and phi components of position ;
;   	    	    	    	    	    	    	;
; angles are in radians     	    	    	    	;
;   	    	    	    	    	    	    	;
; Dave Brain	    	    	    	    	    	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ; Calcute angles
      cp = cos(pposn)
      sp = sin(pposn)
      ct = cos(tposn)
      st = sin(tposn)

   ;; Transformation Matrix ;;
   ;                         ;
   ;  st*cp    st*sp    ct   ;
   ;                         ;
   ;  ct*cp    ct*sp    -st  ;
   ;                         ;
   ;    -sp       cp      0  ;
   ;                         ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;


   ; Calcute r, theta, phi  (note I switched 2 column rows b/c of '-' signs
      RETURN, [ $
         [ st * sp * ydat  +  st * cp * xdat  +  ct * zdat ], $
         [ ct * sp * ydat  +  ct * cp * xdat  -  st * zdat ], $
         [      cp * ydat  -       sp * xdat               ]    ]


end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;   START OF MAIN ROUTINE   ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro mvn_model_bcrust, var, resolution=resolution, data=modelmag, $
                      silent=sl, verbose=vb, nmax=nmax, $
                      arkani=arkani, purucker=purucker, $
                      cain_2003=cain_2003, cain_2011=cain_2011, $
                      version=version, tplot=tplot, path=path, spice_list=spice_list, $
                      morschhauser=morschhauser, pos=pos, no_download=no_download, langlais=langlais, $
                      fast=fast, ndat=ndat

  IF keyword_set(sl) THEN silent = sl ELSE silent = 0
  IF keyword_set(vb) THEN verbose = vb ELSE verbose = 0
  verbose -= silent

  IF ~keyword_set(pos) THEN BEGIN
     trange = var
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
     tmin = MIN(trange, max=tmax)
     IF N_ELEMENTS(trange) EQ 2 THEN BEGIN
        IF keyword_set(resolution) THEN res = resolution ELSE res = 1.d
        trange = dgen(range=trange, resolution=res) 
     ENDIF 
     
     num = N_ELEMENTS(trange)
     IF TOTAL(mvn_spice_valid_times([tmin, tmax], verbose=verbose)) LT 2 THEN $
        mk = mvn_spice_kernels(/all, /load, /clear, trange=[tmin, tmax], verbose=verbose, no_download=no_download)
     pgeo = FLOAT(spice_body_pos('MAVEN', 'MARS', utc=trange, frame='IAU_MARS'))
     eph = {x_pc: REFORM(pgeo[0, *]), y_pc: REFORM(pgeo[1, *]), z_pc: REFORM(pgeo[2, *])}
     ;get_mvn_eph, trange, eph, silent=silent, no_download=no_download
  ENDIF ELSE BEGIN
     IF SIZE(pos, /n_dimension) EQ 2 THEN BEGIN
        sz = SIZE(pos, /dimension)
        IF (sz[0] EQ 3) OR (sz[1] EQ 3) THEN BEGIN
           pos2 = pos
           IF sz[1] EQ 3 THEN pos2 = TRANSPOSE(pos2) ; Fixed 3 x N array
           eph = {x_pc: REFORM(pos2[0, *]), $
                  y_pc: REFORM(pos2[1, *]), $
                  z_pc: REFORM(pos2[2, *])  }
           num = N_ELEMENTS(eph.x_pc)
           undefine, pos2
        ENDIF ELSE BEGIN
           dprint, 'Inproper position data array. You must input 3 x N or N x 3 elements array.' 
           RETURN
        ENDELSE 
        undefine, sz
     ENDIF ELSE BEGIN
        dprint, 'Inproper position data array. You must input 3 x N or N x 3 elements array.' 
        RETURN
     ENDELSE 
     
     IF SIZE(var, /type) NE 0 THEN BEGIN
        trange = time_double(var)
        IF N_ELEMENTS(trange) EQ num THEN BEGIN
           str_element, eph, 'time', trange, /add 
           tmin = MIN(trange, max=tmax)
        ENDIF ELSE undefine, trange
     ENDIF 
  ENDELSE 

  ; Set name of file containing crustal models
  ; Assuming that the IDL save file is stored on the same place to this routine.
  IF ~keyword_set(path) THEN path = FILE_DIRNAME(ROUTINE_FILEPATH('mvn_model_bcrust'), /mark)
  modelfile = path + 'martiancrustmodels.sav'

  IF keyword_set(morschhauser) THEN mflg = 1 ELSE mflg = 0
  IF keyword_set(cain_2003) THEN cflg03 = 1 ELSE cflg03 = 0
  IF keyword_set(cain_2011) THEN cflg11 = 1 ELSE cflg11 = 0
  IF keyword_set(arkani) THEN aflg = 1 ELSE aflg = 0
  IF keyword_set(purucker) THEN pflg = 1 ELSE pflg = 0
  IF keyword_set(langlais) THEN lflg = 1 ELSE lflg = 0
  
  IF (mflg + cflg03 + cflg11 + aflg + pflg + lflg EQ 0) THEN BEGIN
     IF verbose GE 0 THEN BEGIN
        print, ptrace()
        print, '  The Morschhauser model is used in default.'
     ENDIF 
     mflg = 1
  ENDIF 
  IF (mflg + cflg03 + cflg11 + aflg + pflg + lflg GT 1) THEN BEGIN
     dprint, "'mvn_model_bcrust' must be called with only one crustal model selected."
     RETURN
  ENDIF 

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Restore model information ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  restore, modelfile

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Model MAG data in pc cartesian coords ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  rplanet = 3390.D  
  ; Determine the model coeff.
  IF (cflg03) THEN BEGIN
     modeler = 'cain_2003'
     mname = 'Cain (2003)'
     g = gc_2003
     h = hc_2003
     IF N_ELEMENTS(nmax) EQ 1 THEN BEGIN
        g = g[0:nmax+1, 0:nmax+1]
        h = h[0:nmax+1, 0:nmax+1]
     ENDIF ELSE nmax = 90
  ENDIF 
  IF (cflg11) THEN BEGIN
     modeler = 'cain_2011'
     IF ~keyword_set(version) THEN BEGIN
        mname = 'Cain (2011)'
        g = gc_2011
        h = hc_2011
     ENDIF ELSE BEGIN
        mname = 'Cain (2011B)'
        g = gc_2011b
        h = hc_2011b
     ENDELSE
     IF N_ELEMENTS(nmax) EQ 1 THEN BEGIN
        g = g[0:nmax+1, 0:nmax+1]
        h = h[0:nmax+1, 0:nmax+1]
     ENDIF ELSE nmax = 90
  ENDIF 
  IF (aflg) THEN BEGIN
     modeler = 'arkani'
     mname = 'Arkani'
     g = ga
     h = ha
     IF N_ELEMENTS(nmax) EQ 1 THEN BEGIN
        g = g[0:nmax+1, 0:nmax+1]
        h = h[0:nmax+1, 0:nmax+1]
     ENDIF ELSE nmax = 90
  ENDIF 
  IF (pflg) THEN BEGIN
     modeler = 'purucker'
     mname = 'Purucker'
     g = gp
     h = hp
     IF N_ELEMENTS(nmax) EQ 1 THEN BEGIN
        g = g[0:nmax+1, 0:nmax+1]
        h = h[0:nmax+1, 0:nmax+1]
     ENDIF ELSE nmax = 51
  ENDIF 
  IF (mflg) THEN BEGIN
     modeler = 'morschhauser'
     mname = 'Morschhauser'
     g = gm
     h = hm
     IF N_ELEMENTS(nmax) EQ 1 THEN BEGIN
        g = g[0:nmax+1, 0:nmax+1]
        h = h[0:nmax+1, 0:nmax+1]
     ENDIF ELSE nmax = 110
     rplanet = 0.339350d4
  ENDIF 
  IF (lflg) THEN BEGIN
     modeler = 'langlais'
     mname = 'Langlais'
     g = gl
     h = hl
     IF N_ELEMENTS(nmax) EQ 1 THEN BEGIN
        g = g[0:nmax+1, 0:nmax+1]
        h = h[0:nmax+1, 0:nmax+1]
     ENDIF ELSE nmax = 134
     rplanet = 3393.5D
  ENDIF 

  ; Convert pc cartesian coords to pc lon/lat/r
  pcsph = cv_coord( from_rect=TRANSPOSE( [ [eph.x_pc],    $
                                           [eph.y_pc],    $
                                           [eph.z_pc] ]), $
                    /to_sphere, /double )
  pcr = REFORM(pcsph[2, *])
  pct = !DPI/2d0 - REFORM(pcsph[1, *])
  pcp = REFORM(pcsph[0, *])
  pcsph = 0

  ; Allocate array space
  bpcsph = DBLARR(3, num)

  ; Apply crustal B field model
  t0 = SYSTIME(/sec) 
  IF KEYWORD_SET(fast) THEN BEGIN
     bpcsph = mvn_model_bcrust_calc(g, h, rplanet/pcr, pct,  pcp) 
     dprint, 'Calculation is completed: ', time_string(SYSTIME(/sec)-t0, tformat='mm:ss.fff'), dlevel=2, verbose=verbose
  ENDIF ELSE BEGIN
     fifb = string("15B) ;"
     IF (verbose GE 0) THEN print, ptrace() 
     FOR i=0L, num-1 DO BEGIN
        IF KEYWORD_SET(ndat) THEN BEGIN
           imin = i * LONG(ndat)
           imax = (imin + LONG(ndat)) < (num - 1)
           IF (num - 1) - imax LT 0.25 * ndat THEN imax = num - 1
           ans = mvn_model_bcrust_calc(g, h, rplanet/pcr[imin:imax], pct[imin:imax],  pcp[imin:imax])
           bpcsph[*, imin:imax] = ans
        ENDIF ELSE BEGIN
           imax = i
           ans = sph_b( g, h, rplanet/pcr[i], pct[i], pcp[i] )
           bpcsph[*, i] = ans
        ENDELSE 
        IF (verbose GE 0) THEN $
           print, format='(a, a, a, I0, a, I0, a, f6.2, a, f0.1, a, $)', $
                  '      ', fifb, '  Modeling ', num, $
                  ' observations with ' + mname + ' nmax = ', nmax, ': ', $
                  (imax+1)/float(num)*100., '% complete (Elapsed time: ', SYSTIME(/sec)-t0, ' sec).'
        IF (imax EQ num-1) THEN BREAK
     ENDFOR                     ; i
     IF (verbose GE 0) THEN print, ''
  ENDELSE 
  ; Convert spherical data to cartesian
  bpc = datas2c(bpcsph[0, *], bpcsph[1, *], bpcsph[2, *], pct, pcp) 
                 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Calculate model prediction in SS coords ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  IF SIZE(trange, /type) NE 0 THEN BEGIN
     IF TOTAL(mvn_spice_valid_times([tmin, tmax], verbose=verbose)) LT 2 THEN $
        mk = mvn_spice_kernels(/all, /load, /clear, trange=[tmin, tmax], verbose=verbose, no_download=no_download)
     bss = spice_vector_rotate(TRANSPOSE(bpc), trange, 'IAU_MARS', 'MAVEN_MSO',   $
                               check_objects='MAVEN_SPACECRAFT', verbose=verbose)
     bss = TRANSPOSE(bss)
  ENDIF 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Create Output structure for model predictions ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      
  ; Make basic mag structure for now
  model = { time: 0.d,       $
            amp:  0.0,       $
            ss:   FLTARR(3), $
            pc:   FLTARR(3), $
            lg:   FLTARR(3)  }
  ; Turn it into an array
  modelmag = REPLICATE(model, num)
      
  ; Set time
  IF SIZE(trange, /type) NE 0 THEN modelmag.time = trange
      
  ; Set pc = (IAU_MARS)
  modelmag.pc = TRANSPOSE(FLOAT(bpc))
      
  ; Set ss
  IF SIZE(trange, /type) NE 0 THEN modelmag.ss = TRANSPOSE(FLOAT(bss))

  ; Set lg = (Local geographic coordinates) 
  modelmag.lg = FLOAT(bpcsph)

  ; Set amp
  modelmag.amp = SQRT( TOTAL(modelmag.pc*modelmag.pc, 1) )     
      
  IF keyword_set(tplot) AND SIZE(trange, /type) NE 0 THEN BEGIN
     IF SIZE(mk, /type) EQ 0 THEN mk = spice_test('*')
     store_data, 'mvn_model_bcrust_amp_' + modeler, data={x: modelmag.time, y:modelmag.amp}, $
                 dlimits={ytitle: mname, ysubtitle: '|B| [nT]'}
     store_data, 'mvn_model_bcrust_geo_' + modeler, data={x: modelmag.time, y:transpose(modelmag.pc)}, $
                 dlimits={colors: 'bgr', labels: ['Bx', 'By', 'Bz'], labflag: 1, ytitle: mname, ysubtitle:'B IAU_MARS [nT]', $
                          constant: 0, spice_master_frame: 'MAVEN_SPACECRAFT', spice_frame: 'IAU_MARS'}
     store_data, 'mvn_model_bcrust_mso_' + modeler, data={x: modelmag.time, y:transpose(modelmag.ss)}, $
                 dlimits={colors: 'bgr', labels: ['Bx', 'By', 'Bz'], labflag: 1, ytitle: mname, ysubtitle:'Bmso [nT]', $
                          constant: 0, spice_master_frame: 'MAVEN_SPACECRAFT', spice_frame: 'MAVEN_MSO'}
     IF KEYWORD_SET(spice_list) THEN $
        store_data, 'mvn_model_bcrust_mso_spice_kernels', data={x: [MEAN([tmin, tmax])], y: [STRJOIN(FILE_BASENAME(mk), ' ')]}
  ENDIF 
  dprint, dlevel=2, 'Don''t forget to contact the modeler if you use these results!', verbose=verbose
  RETURN
END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;   END OF MAIN ROUTINE   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
