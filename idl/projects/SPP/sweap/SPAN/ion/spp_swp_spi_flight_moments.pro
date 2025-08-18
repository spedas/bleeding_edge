

; The following section generates SPAN-Ai proton count arrays - data.
; "data" includes statistical fluctuations.


FUNCTION spp_swp_spi_moments_get_dave_vel, att

   FE  = lonarr(128,4)
   FES = lonarr(128,4)
   SFE = [740000000.,$
          130000000.,$
            1100000.,$
               8800.]

   FE_eff     = 1.0
   FE_eff_att = 0.1
   start_v = 2000.
   step_v  = 0.06 
   n_v     = 128 
   voltage = fltarr(n_v)
   voltage[0] = start_v
   FOR i=1, n_v-1 DO voltage[i] = voltage[i-1]*(1-step_v)
   kfactor = 16.7
   energy  = voltage*kfactor
   kfactor_spl = 15.
   energy_spl  = voltage*kfactor_spl

   ;; 1/V(E) -> 1/sqrt(E)
   FE[*,0]  = SFE[0] * FE_eff     * (1./sqrt(energy))
   FES[*,0] = SFE[0] * FE_eff_att * (1./sqrt(energy_spl))
   
   ;; 1 -> 1
   FE[*,1]  = SFE[1] * FE_eff     * (1.)
   FES[*,1] = SFE[1] * FE_eff_att * (1.)

   ;; V(E) -> sqrt(E)
   FE[*,2]  = SFE[2] * FE_eff     * sqrt(energy)
   FES[*,2] = SFE[2] * FE_eff_att * sqrt(energy_spl)

   ;; V(E)^2 -> E
   FE[*,3]  = SFE[3] * FE_eff     * energy
   FES[*,3] = SFE[3] * FE_eff_att * energy_spl

   IF keyword_set(att) THEN RETURN, FES

   RETURN, FE
   
END



FUNCTION spp_swp_spi_moments_get_theta, $
 th0, th1, SFD,  att=att


   ;; SFD 32768 max, plus sum over anodes does not
   ;; saturate 31 bit +sign accumulator
   IF ~keyword_set(SFD) THEN SFD = 32768.0
   IF ~keyword_set(th0) OR ~keyword_set(th1) THEN BEGIN

      def_range = 120.
      ndefl = 32.
      th0 = -60. + def_range/ndefl*indgen(ndefl)
      th1 = -60. + def_range/ndefl*(indgen(ndefl)+1.)

   ENDIF

   IF ~keyword_set(ndefl) THEN ndefl = n_elements(th0)
   
   FD  = intarr(ndefl,6)      ;; short
   FDA = intarr(ndefl,6)      ;; short

   def_eff     = replicate(1,ndefl)
   def_eff_att = replicate(1,ndefl)

   ;; <cos(th)>
   FD[*,0]  = SFD * def_eff     * $
              (sin(th1*!DTOR)-sin(th0*!DTOR)) / $
              (((th1-th0) MOD 360)*!DTOR) + 0.5
   FDA[*,0] = SFD * def_eff_att * $
              (sin(th1*!DTOR)-sin(th0*!DTOR)) / $
              (((th1-th0) MOD 360)*!DTOR) + 0.5
   ;; <cos(th)^2>
   FD[*,1]  = SFD * def_eff     * $
                 (0.5 + 0.25*(sin(2.*th1*!DTOR)-sin(2.*th0*!DTOR)) / $
                  (((th1-th0) MOD 360.)*!DTOR)) + 0.5
   FDA[*,1] = SFD * def_eff_att * $
              (0.5 + 0.25*(sin(2.*th1*!DTOR)-sin(2.*th0*!DTOR)) / $
               (((th1-th0) MOD 360.)*!DTOR)) + 0.5
   ;; <sin(th)cos(th)>
   FD[*,2]  = SFD * def_eff     * $
              (0.5 * (sin(th1*!DTOR)^2-sin(th0*!DTOR)^2) / $
               (((th1-th0) MOD 360.)*!DTOR)) + 0.5
   FDA[*,2] = SFD * def_eff_att * $
              (0.5 * (sin(th1*!DTOR)^2-sin(th0*!DTOR)^2) / $
               (((th1-th0) MOD 360.)*!DTOR)) + 0.5
   ;; <cos(th)^3>
   FD[*,3]  = SFD * def_eff     * $
              ((sin(th1*!DTOR)*(cos(th1*!DTOR)^2+2)-$
                sin(th0*!DTOR)*(cos(th0*!DTOR)^2+2)) / $
               (3.*(((th1-th0) MOD 360.)*!DTOR))) + 0.5
   FDA[*,3] = SFD * def_eff_att * $
              ((sin(th1*!DTOR)*(cos(th1*!DTOR)^2+2)-$
                sin(th0*!DTOR)*(cos(th0*!DTOR)^2+2)) / $
               (3.*(((th1-th0) MOD 360.)*!DTOR))) + 0.5   
   ;; <cos(th)sin(th)^2>
   FD[*,4]  = SFD * def_eff     * $
              ((sin(th1*!DTOR)^3-sin(th0*!DTOR)^3)/$
               (3.*(((th1-th0) MOD 360.)*!DTOR))) + 0.5
   FDA[*,4] = SFD * def_eff_att * $
              ((sin(th1*!DTOR)^3-sin(th0*!DTOR)^3)/$
               (3.*(((th1-th0) MOD 360.)*!DTOR))) + 0.5
   ;; <cos(th)^2sin(th)>
   FD[*,5]  = SFD * def_eff     * $
              ((cos(th0*!DTOR)^3-cos(th1*!DTOR)^3)/$
               (3.*(((th1-th0) MOD 360.)*!DTOR))) + 0.5
   FDA[*,5] = SFD * def_eff_att * $
              ((cos(th0*!DTOR)^3-cos(th1*!DTOR)^3)/$
               (3.*(((th1-th0) MOD 360.)*!DTOR))) + 0.5
   
   IF keyword_set(att) THEN RETURN, FD ELSE RETURN, FDA
      
END




FUNCTION spp_swp_spi_moments_get_phi,  $
 phi0, phi1, SFA, att=att

   ;; SFA 32767 max, plus sum over anodes does not
   ;; saturate 31 bit +sign accumulator
   IF ~keyword_set(SFA) THEN SFA = 32767.0

   ;; Anode Sizes
   IF ~keyword_set(phi0) OR ~keyword_set(phi1) THEN BEGIN 
      print, " - 8 Anodes each 11.25 degrees - "
      anode_size = 11.25
      phi0 = indgen(8)*11.25
      phi1 = indgen(8)*11.25+11.15
   ENDIF

   ;; Number of angles
   n_phi = n_elements(phi0)

   ;; Variable Decleration
   FS  = intarr(6,n_phi)      ;; short
   FSA = intarr(6,n_phi)      ;; short

   ;; Anode Efficiencies (unit for now)
   anode_eff     = replicate(1,n_phi)
   anode_eff_att = replicate(1,n_phi)


   ;; -------------- VALUES FROM DAVE ------------------
   print, 'Dave phi values'
      ;; 1 - (WHY +0.5???)
   FS[0,*]  = anode_eff     * SFA + 0.5
   FSA[0,*] = anode_eff_att * SFA + 0.5
   ;; <cos(phi)>
   FS[1,*]  = SFA * anode_eff     * $
              (sin(phi1*!DTOR)-sin(phi0*!DTOR)) / $
              (((phi1-phi0) MOD 360)*!DTOR) + 0.5
   FSA[1,*] = SFA * anode_eff_att * $
              (sin(phi1*!DTOR)-sin(phi0*!DTOR)) / $
              (((phi1-phi0) MOD 360)*!DTOR) + 0.5
   ;; <sin(phi)>
   FS[2,*]  = SFA * anode_eff     * $
              (cos(phi0*!DTOR)-cos(phi1*!DTOR)) / $
              (((phi1-phi0) MOD 360)*!DTOR) + 0.5
   FSA[2,*] = SFA * anode_eff_att * $
              (cos(phi0*!DTOR)-cos(phi1*!DTOR)) / $
              (((phi1-phi0) MOD 360)*!DTOR) + 0.5
   ;; <cos(phi)^2>
   FS[3,*]  = SFA * anode_eff     * $
              (0.5 + 0.25*(sin(2.*phi1*!DTOR)-sin(2.*phi0*!DTOR)) / $
               (((phi1-phi0) MOD 360.)*!DTOR)) + 0.5
   FSA[3,*] = SFA * anode_eff_att * $
              (0.5 + 0.25*(sin(2.*phi1*!DTOR)-sin(2.*phi0*!DTOR)) / $
               (((phi1-phi0) MOD 360.)*!DTOR)) + 0.5
   ;; <sin(phi)^2>
   FS[4,*]  = SFA * anode_eff     * $
              (0.5 + 0.25*(sin(2.*phi0*!DTOR)-sin(2.*phi1*!DTOR)) / $
               (((phi1-phi0) MOD 360.)*!DTOR)) + 0.5
   FSA[4,*] = SFA * anode_eff_att * $
              (0.5 + 0.25*(sin(2.*phi0*!DTOR)-sin(2.*phi1*!DTOR)) / $
               (((phi1-phi0) MOD 360.)*!DTOR)) + 0.5
   ;; <sin(phi)cos(phi)>
   FS[5,*]  = SFA * anode_eff     * $
              (0.5 * (sin(phi1*!DTOR)^2-sin(phi0*!DTOR)^2) / $
               (((phi1-phi0) MOD 360.)*!DTOR)) + 0.5
   FSA[5,*] = SFA * anode_eff_att * $
              (0.5 * (sin(phi1*!DTOR)^2-sin(phi0*!DTOR)^2) / $
               (((phi1-phi0) MOD 360.)*!DTOR)) + 0.5

   RETURN, FS

END




;;#############################################################################
;;#############################################################################
;;##############################            ###################################
;;##############################   C Code   ###################################
;;##############################            ###################################
;;#############################################################################
;;#############################################################################

PRO spp_swp_spi_moments_sumproduct64, A, B, Sum

   ;; long A
   ;; Long B
   ;; short Sum

   P    = uintarr(4)
   i    = 0
   LL   = 0L
   LH   = 0L
   HL   = 0
   HH   = 0L
   Acc  = 0L
   AbsA = 0L
   AbsB = 0L

   ;; AbsA and AbsB have 7FFFFFFF max
   AbsA = abs(A)
   AbsB = abs(B)

   ;; LL has FFFF * FFFF = FFFE0001 max
   LL = spp_swp_spi_moments_LSW(AbsA)*LSW(AbsB) 
   ;; LH has FFFF * 7FFF = 7FFE8001 max 
   LH = spp_swp_spi_moments_LSW(AbsA)*MSW(AbsB) 
   ;; HL has 7FFF * FFFF = 7FFE8001 max
   HL = spp_swp_spi_moments_MSW(AbsA)*LSW(AbsB) 
   ;; HH has 7FFF * 7FFF = 3FFF0001 max 
   HH = spp_swp_spi_moments_MSW(AbsA)*MSW(AbsB) 

   P[3] = LSW(LL) ;; turn into short?
   Acc  = MSW(LL) + LSW(LH) + LSW(HL)
   P[2] = LSW(Acc) ;; turn into short?
   Acc  = MSW(Acc) + MSW(LH) + MSW(HL) + LSW(HH)
   P[1] = LSW(Acc) ;; turn into short?
   Acc  = MSW(Acc) + MSW(HH)
   P[0] = LSW(Acc) ;; turn into short?

   ;; If we have a negative product
   IF A^B LT 0 THEN BEGIN
      ;; Invert all bits
      FOR i=0, 3 DO P[i] = ~P[i]
      ;; Increment
      ;IF
   ENDIF

   ;; Add product to sum
   Acc = 0
   FOR i=3, 0, -1 DO BEGIN
      Acc = Acc + Sum[i]   ;; unsigned short
      Acc = Acc + P[i]     ;; unsigned short
      Sum[i] = LSW(Acc)    ;; short
      Acc = ishft(Acc,-16)
   ENDFOR
   
   
END



;; 32bit * 16bit product divided by 65536 (both values signed)
;; Fractional multiply where 16bit value is scaled to 32768=+1.0
;; Result is scaled product divided by 2

FUNCTION spp_swp_spi_moments_product, x32, y16

   x32_1 = ishft(x32,-16)
   x32_2 = x32 AND 'FFFF'x
   IF y16 LT 0 THEN x32_3 = x32 $
   ELSE x32_3 = 0

   y16_1 = y16
   y16_2 = ishft(y16,-16)
   IF x32 LT 0 THEN y16_3 = ishft(y16,16) $
   ELSE y16_3 = 0
   
   return, x32_1*y16_1 + $
           x32_2*y16_2 - $
           x32_3-y16_3
   
    ;; (((unsigned long)(x32))>>16)*((unsigned short)(y16)) + $
    ;; (((((unsigned long)(x32))&0xFFFF)*((unsigned short)(y16)))>>16) - $
    ;; ((y16)<0?(x32):0) - ((x32)<0?(y16)<<16:0)

END

PRO spp_swp_spi_moments_code, CR=CR, att

   ;; Global Variables
   IF ~keyword_set(CR) THEN BEGIN 
      CR  = uintarr(32,8,8)  ;; short
      FS  = intarr(6,8)      ;; short
      FSA = intarr(6,8)      ;; short
      FD  = intarr(32,6)     ;; short
      FDS = intarr(32,6)     ;; short
      FE  = lonarr(128,4)    ;; long
      FES = lonarr(128,4)    ;; long
   ENDIF   

   ;; 13 64-bit moments
   ;; M[i,0] = MSW
   ;; M[i,3] = LSW
   M   = intarr(13,4)     ;; short

   ;; Energy/Deflection/Anodes indices
   E0 = 0                ;; int
   D0 = 0                ;; int
   A0 = 0                ;; int
   
   ;; Intermediate Accumulators
   S  = lonarr(6)
   DM = lonarr(13)
   CRP = long(0)
   FSP = long(0)
   FDP = 0
   FEP = long(0)
   I = 0
   E = 0
   D = 0
   A = 0

   ;; Attenuator status
   IF keyword_set(att) THEN $
    AttenuatorIsOut = 0 $
   ELSE AttenuatorIsOut = 1

   
   ;; Initialize Moments
   FOR i=0, 12 DO BEGIN
      M[i,0] = 0
      M[i,1] = 0
      M[i,2] = 0
      M[i,3] = 0
   ENDFOR
   
   ;; Calculate moments
   FOR e=0, 31 DO BEGIN
      ;; Initialize partial moment sums
      DM = DM*0
      FOR d=0, 7 DO BEGIN

         ;; Compute the sums of products across A for this D,E
         IF AttenuatorIsOut THEN FSP = FS[0,0] $
         ELSE FSP = FSA[0,0]
         FOR i=0, 5 DO BEGIN
            S[i] = 0
            CRP = CR[e,d,0]
            FOR a=0, 7 DO BEGIN
               s[i] = s[i] + (CRP++)*(FSP++)
            ENDFOR
         ENDFOR

         ;; Increment Partial moments across deflectors
         FDP = FD[d0+d,0]

         DM[0]  = DM[0]  + spp_swp_spi_moments_product(S[0],FDP[0])     ;; N
         DM[1]  = DM[1]  + spp_swp_spi_moments_product(S[1],FDP[1])     ;; NVx
         DM[2]  = DM[2]  + spp_swp_spi_moments_product(S[2],FDP[1])     ;; NVy
         DM[3]  = DM[3]  + spp_swp_spi_moments_product(S[0],FDP[2])     ;; NVz
         DM[4]  = DM[4]  + spp_swp_spi_moments_product(S[3],FDP[3])     ;; NPxx
         DM[5]  = DM[5]  + spp_swp_spi_moments_product(S[4],FDP[3])     ;; NPyy
         DM[6]  = DM[6]  + spp_swp_spi_moments_product(S[0],FDP[4])     ;; NPzz
         DM[7]  = DM[7]  + spp_swp_spi_moments_product(S[5],FDP[3])     ;; NPxy
         DM[8]  = DM[8]  + spp_swp_spi_moments_product(S[1],FDP[5])     ;; NPxz
         DM[9]  = DM[9]  + spp_swp_spi_moments_product(S[2],FDP[5])     ;; NPyz
         DM[10] = DM[10] + spp_swp_spi_moments_product(S[1],FDP[1])     ;; NHx
         DM[11] = DM[11] + spp_swp_spi_moments_product(S[2],FDP[1])     ;; NHy
         DM[12] = DM[12] + spp_swp_spi_moments_product(S[0],FDP[2])     ;; NHz

      ENDFOR
      stop
      
      ;; Now increment moments across energy
      IF SpoilerIsOff(e0+e) THEN FEP = FE[e0+e,0] $
      ELSE FEP = FES[e0+e,0]

      spp_swp_spi_moments_sumproduct64,DM[0], FEP++,M[0,0]
      spp_swp_spi_moments_sumproduct64,DM[1], FEP,  M[1,0]
      spp_swp_spi_moments_sumproduct64,DM[2], FEP,  M[2,0]
      spp_swp_spi_moments_sumproduct64,DM[3], FEP++,M[3,0]
      spp_swp_spi_moments_sumproduct64,DM[4], FEP  ,M[4,0]
      spp_swp_spi_moments_sumproduct64,DM[5], FEP  ,M[5,0]
      spp_swp_spi_moments_sumproduct64,DM[6], FEP  ,M[6,0]
      spp_swp_spi_moments_sumproduct64,DM[7], FEP  ,M[7,0]
      spp_swp_spi_moments_sumproduct64,DM[8], FEP  ,M[8,0]
      spp_swp_spi_moments_sumproduct64,DM[9], FEP++,M[9,0]
      spp_swp_spi_moments_sumproduct64,DM[10],FEP  ,M[10,0]
      spp_swp_spi_moments_sumproduct64,DM[11],FEP  ,M[11,0]
      spp_swp_spi_moments_sumproduct64,DM[12],FEP  ,M[12,0]

   ENDFOR
         
END




;;#############################################################################
;;#############################################################################
;;#############################             ###################################
;;#############################  End C Code ###################################
;;#############################             ###################################
;;#############################################################################
;;#############################################################################

FUNCTION spp_swp_spi_moments_get_guess, ms=ms

   ;; plasmasheet ms=0,1  magnetosheath ms=2,3  FAC ms=5
   ;; note: for narrow beams, ndth should be large 
   ;; note: for narrow beams, density modulation depends on phi0
   ;; note: for colder beams, value of pot relative to nearest
   ;;       energy modulates the density

   IF ~keyword_set(ms) THEN ms=2

   if ms eq 0 then begin 
      pot=20.
      temp=100.*[1.,1.,1.]
      n_e=1.
      vd=[0.d,0.d,0.d]
      beam=0
   endif
   if ms eq 1 then begin 
      pot=40.
      temp=1000.*[1.,1.,1.]
      n_e=.1
      vd=[500.d,0.d,0.d]
      beam=0
   endif
   if ms eq 2 then begin 
      pot=4. 
      temp=100.*[1.,1.,1.] 
      n_e=300. 
      vd=[100.d,0.d,0.d] 
      beam=0 
   endif
   if ms eq 3 then begin 
      pot=8. 
      temp=50.*[1.,1.,1.] 
      n_e=5. 
      vd=[600.d,0.d,0.d] 
      beam=0 
   endif
   if ms eq 4 then begin 
      pot=18.0 
      temp=200.*[1.,.1,.1] 
      ;;temp=200.*[1.,1.,1.] 
      n_e=1. 
      vd=[6000.d,0.d,0.d]
      beam=1 
   endif

   return, {pot:pot,$
            temp:temp,$
            n_e:n_e,$
            vd:vd,$
            beam:beam}

END



PRO spp_swp_spi_moments_test

   ;stop, '-------CHECK----------'

   ;; Test Pattern
   n_energy     = 32
   n_deflectors = 8
   n_anodes     = 8
   CR = intarr(n_energy, n_deflectors, n_anodes)
   
   FOR e0=0, n_energy-1 DO $
    FOR d0=0, n_deflectors-1 DO $
     FOR a0=0, n_anodes-1 DO $
      CR[e0,d0,a0] = e0*d0*a0

   att = 0

   ;; PHI Components
   ;; SFA 32767 max, plus sum over anodes does not
   ;; saturate 31 bit +sign accumulator
   phi_SFA = 32767.0
   ;phi_mxc = 1185
   FS  = intarr(6,8)      ;; short
   FSA = intarr(6,8)      ;; short
   ;; Anode Characteristics
   anode_size = 11.25
   phi0 = indgen(8)*11.25
   phi1 = indgen(8)*11.25+11.15
   anode_eff     = replicate(1,8)
   anode_eff_att = replicate(1,8)

   ;; SFA 32767 max, plus sum over anodes does not
   ;; saturate 31 bit +sign accumulator
   th_SFD = 32767.0

   ;; Deflection Range
   def_range = 120.

   ;; Number of Deflection
   ndefl = 32.

   ;; Theta Values
   th0 = -60. + def_range/ndefl*indgen(ndefl)
   th1 = -60. + def_range/ndefl*(indgen(ndefl)+1.)

   FS    = spp_swp_spi_moments_get_phi(/att,phi0=phi0,phi1=phi1,/dave)
   FS_rl = spp_swp_spi_moments_get_phi(/att,phi0=phi0,phi1=phi1)
   
   FD    = spp_swp_spi_moments_get_theta(/att,th0=th0,th1=th1,/dave)
   FD_rl = spp_swp_spi_moments_get_theta(/att,th0=th0,th1=th1)

   FE = spp_swp_spi_moments_get_dave_vel(att)

   stop
   
   spp_swp_spi_moments_code, CR

END



PRO spp_swp_spi_flight_moments, ms=ms, test=test

   ;; SPAN-Ai Instrument Common Block
   spp_swp_spi_param, spi_param
   
   ;; Run a test
   IF keyword_set(test) THEN spp_swp_spi_moments_test

   ;; Get Guess
   vars = spp_swp_spi_moments_get_guess(ms=3)
   
   ;; Below arrays have dimensions (32 energies, 256 solid angle)
   ;; some dimension are redundant.
   ;; energy sweep
   emax = 41600.
   de   = .3
   engy = emax/((1.+de)^findgen(33))
   en   = emax/(1+de)^(findgen(32)+.5)

   energy  = fltarr(32,256)
   denergy = fltarr(32,256)

   for i=0,255 do energy(*,i)=en
   for i=0,255 do denergy(*,i)=(engy(0:31)-engy(1:32))
   dengy=max(denergy/energy) & print,dengy
   
   th=fltarr(256) 
   th0=-78.75+22.5*findgen(8)
   for i=0,31 do th(i*8:i*8+7)=th0
   theta=fltarr(32,256) 
   for i=0,31 do theta(i,*)=th
   
   ph=fltarr(256)
   ;phi0=5.625
   phi0=0.
   for i=0,31 do ph(i*8:i*8+7)=i*11.25+phi0
   phi=fltarr(32,256)
   for i=0,31 do phi(i,*)=ph

   geom    = fltarr(32,256)
   geom(*) = 1.
   dtheta  = fltarr(32,256) & dtheta=22.5
   dphi    = fltarr(32,256) & dphi(*)=11.25 
   domega  = 2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)
   eff     = fltarr(32) & eff(*)=1.

   ;; Geometric Factor
   gf      = 0.0001           ;; [cm2*sr]   SPAN-Ai GF
   ;; Integration Time
   integ_t = 0.874            ;; [s]         1 NYS 
   ;; Electron Mass (to get grams multiply by 1.6e-22.)
   mass    = 5.68566e-06      ;; [ev/c2] where c = 299792 [km/s]  
   ;; Proton Mass   (to get grams multiply by 1.6e-22.)
   ;mass = 0.0104389          ;; [ev/c2] where c = 299792 [km/s]  
   ;; C
   cc = 299792458d            ;; [m s-1]
   ;; 1 Electronvolt to Joule
   evtoj = 1.602176565e-19    ;; [J] = [kg m2 s-2]
   ;; Boltzmann Constant
   kk = 1.38064852e-23        ;; [m2 kg s-2 K-1]
   ;; Temp constant
   v_e=1876.d*(vars.temp/10.)^.5

   data=fltarr(32,256)
   ndth=20

   f0=1.d*vars.n_e*((mass)/(2.*!pi))^1.5/$              ;; [cm-3]*[ev/c2]*
      (vars.temp(0)*vars.temp(1)*vars.temp(2))^.5

   
   ;; the following is needed for narrow beams
   FOR i=0,ndth-1 DO BEGIN
      dth=dtheta/2.-dtheta/ndth*(.5+i)
      velx=1876.d*((energy-vars.pot > 0.)/10.)^.5*$
           cos((theta+dth)/!radeg)*cos(phi/!radeg)
      vely=1876.d*((energy-vars.pot > 0.)/10.)^.5*$
           cos((theta+dth)/!radeg)*sin(phi/!radeg)
      velz=1876.d*((energy-vars.pot > 0.)/10.)^.5*$
           sin((theta+dth)/!radeg)
      data= data + f0 * $
            exp(-(velx-vars.vd(0))^2./v_e(0)^2.) * $
            exp(-(vely-vars.vd(1))^2./v_e(1)^2.) * $
            exp(-(velz-vars.vd(2))^2./v_e(2)^2.) * $
            (integ_t*gf*geom*energy^2.*1.e5*2./mass^2.)
   ENDFOR

   data=data/ndth
   data(0,*)=0.                            ;; Eliminate retrace
   ind=where(energy-vars.pot le 0.,count)
   if count gt 0 then data(ind)=0.         ;; Eliminate counts below sc_pot
   ;; data(*,16:239)=0.                    ;; One sided x
   ;; data(*,80:255)=0. & data(*,0:47)=0.  ;; One sided y
   plot,energy(*,0),data(0:31),$
        ylog=1,xlog=1,xtitle='Energy eV',ytitle='Counts',$
        psym=-2;yrange=[.1,1.e4],psym=-2
   
   ;; Add statistical errors
   for i=0,32*256-1 do data(i) = $
    round(randomn(seed,1,poisson=float(data(i)>1.e-35)))
   oplot,energy(*,0),data(0:31),color=250,psym=-1


   ;;**************************************************************
   ;; The following mimics creation of the onboard tables with real
   ;; numbers rather than integers

   ;; Energy tables

   V =11.705314 
   emax=41600.
   dei=.38
   dee=.30
   eni = 41600./(1+dei)^(findgen(32)+.5)
   ene = 41600./(1+dee)^(findgen(32)+.5)

   ;; For density
   ;; 1<w0<.011573
   we0=ene^(-.5) & w0max=max(we0) & we0=we0/w0max
   wi0=eni^(-.5) & w0max=max(wi0) & wi0=wi0/w0max 

   ;; For flux
   ;; 1<w1<1
   we1=we0 & we1(*)=1. & w1max=1.
   wi1=wi0 & wi1(*)=1. & w1max=1.                 

   ;; For pressure
   ;; 1<w2<.011573
   we2=ene^.5 & w2max=max(we2) & we2=we2/w2max
   wi2=eni^.5 & w2max=max(wi2) & wi2=wi2/w2max    

   ;; For heat flux
   ;; 1<w3<.0001339
   we3=ene & w3max=max(we3) & we3=we3/w3max
   wi3=eni & w3max=max(wi3) & wi3=wi3/w3max       

   ;; Potential correction
   ;; Set negative numbers to zero
   tmp=0.>(1-V/ene)<4.          
   pe0=(tmp)^.5  & pmax=3.998^.5  & pe0n=pe0/pmax
   pe1=(tmp)     & pmax=3.998     & pe1n=pe1/pmax
   pe2=(tmp)^1.5 & pmax=3.998^1.5 & pe2n=pe2/pmax
   pe3=(tmp)^2.  & pmax=3.998^2   & pe3n=pe3/pmax
   ;; Set negative numbers to zero
   tmp=0.>(1+V/eni)<4.          
   pi0=(tmp)^.5  & pmax=3.998^.5  & pi0n=pi0/pmax
   pi1=(tmp)     & pmax=3.998     & pi1n=pi1/pmax
   pi2=(tmp)^1.5 & pmax=3.998^1.5 & pi2n=pi2/pmax
   pi3=(tmp)^2.  & pmax=3.998^2   & pi3n=pi3/pmax

   ;; Energy-potential correction
   wpe0=we0*pe0
   wpe1=we1*pe1
   wpe2=we2*pe2
   wpe3=we3*pe3
   wpi0=wi0*pi0
   wpi1=wi1*pi1
   wpi2=wi2*pi2
   wpi3=wi3*pi3

   ;; *32767 scales the weight to an integer size
   ;; We don't scale the potential correction because
   ;; when we are done with the calculation, we need
   ;; to divide by 2^15 which cancels the scaling out.
   wpe0s=we0*32767*pe0n     
   wpe1s=we1*32767*pe1n     
   wpe2s=we2*32767*pe2n     
   wpe3s=we3*32767*pe3n     
   wpi0s=wi0*32767*pi0n
   wpi1s=wi1*32767*pi1n
   wpi2s=wi2*32767*pi2n
   wpi3s=wi3*32767*pi3n
   print,transpose([[wpe1s],[we1*32767],[pe1n*32767]])

   ;; Solid angle, -90<th<90, 0<ph<360
   ;; Assume electrons - 8 anodes
   th0=(90.-22.5*findgen(8))/!radeg
   th1=th0-22.5/!radeg
   ph0=(11.25*findgen(32))/!radeg
   ph1=ph0+11.25/!radeg



   ;; Integral of dimensions
   ;;
   ;; phi -> 0 to 2pI
   ;; th  -> -pi to pi
   ;;
   ;; x = r*cos(th)*cos(phi)
   ;; y = r*cos(th)*sin(phi)
   ;; z = r*sin(th)
   ;;
   ;; Integral from phi0 to phi1 and th0 to th1

   
   ;; DENSITY
   ;;
   ;; n-> cos(th) dphi dth
   ang_nn = (sin(th0)-sin(th1)) * (phi1-phi0)

   
   ;; VELOCITY
   ;;
   ;; v  -> cos(th) *dot* (x,y,z)
   ;;
   ;; vx -> cos(th) * cos(th) * cos(phi) dphi dth
   ;; vy -> cos(th) * cos(th) * sin(phi) dphi dth
   ;; vz -> cos(th) * sin(th)            dphi dth
   ang_vx = 0.5*(th1-th0 + sin(th1)*cos(th1) - sin(th0)*cos(th0)) * $
            (sin(phi1)-sin(phi0))
   ang_vx = 0.5*(th1-th0 + sin(th1)*cos(th1) - sin(th0)*cos(th0)) * $
            (cos(phi0)-cos(phi1))
   ang_vx = 0.25*(cos(2*th0)-cos(2*th1))


   ;; PRESSURE (COLUMN-MAJOR ORDER)
   ;;
   ;; p ->  cos(th) *dot* (x,y,z) *dot* (x,y,z)
   ;;
   ;;                                                       -                -
   ;;                                                       |cos(th)*cos(phi)|
   ;; cos(th) * [cos(th)cos(phi),cos(th)sin(phi),sin(th)] * |cos(th)*sin(phi)|
   ;;                                                       |    sin(th)     |
   ;;                                                       -                -
   ;;
   ;;       =
   ;;
   ;; |    cos(th)^3*cos(phi)^2        cos(th)^3*sin(phi)*cos(phi)     cos(th)^2*sin(th)*cos(phi) |
   ;; | cos(th)^3*cos(phi)*sin(phi)          cos(th)^3*sin(phi)^2      cos(th)^2*sin(th)*sin(phi) |
   ;; | cos(th)^2*sin(th)*cos(phi)      cos(th)^2*sin(th)*sin(phi)          cos(th)*sin(th)^2     |
   ;;
   ;;


   ;; Phi Components
   ;; 0: 1                   - whatever
   ;; 1: cos(phi)            - within vx
   ;; 2: sin(phi)            - within vy
   ;; 3: cos(phi)^2          - c2
   ;; 4: sin(phi)^2          - c6
   ;; 5: sin(phi) cos(phi)   - c3
   ;;
   ;; Theta Components
   ;; 0: cos(th)             - n 
   ;; 1: cos(th)^2           - within vx
   ;; 2: sin(th) cos(th)     - within vz
   ;; 3: cos(th)^3           - c1
   ;; 4: cos(th) sin(th)^2   - c8
   ;; 5: cos(th)^2 sin(th)   - c4

   
   
   ;; Integral of cos(th)^3 dth
   c1 = (1./12.)*(-9*sin(th0)-sin(3*th0)+9.*sin(th1)+sin(3*th1))
   ;; Integral of cos(phi)^2 dphi
   c2 = (1./2.)*(-1.*phi0-sin(phi0)*cos(phi0)+phi1+sin(phi1)*cos(phi1))
   ;; Integral of cos(phi)sin(phi) dphi
   c3 = (1./4.)*(cos(2.*phi0)-cos(2.*phi1))
   ;; Integral of cos(th)^2*sin(th) dphi
   c4 = (1./3.)*(cos(th0)^3-cos(th1)^3)
   ;; Integral of cos(phi) dphi
   c5 = sin(phi1)-sin(phi0)
   ;; Integral of sin(phi)^2 dphi
   c6 = (1./2.)*(-1.*phi0+sin(phi0)*cos(phi0)+phi1-sin(phi1)*cos(phi1))
   ;; Integral of sin(phi) dphi
   c7 = sin(phi0)-sin(phi1)
   ;; Integral of cos(th)*sin(th)^2
   c8 = (1./3.)*(sin(th1)^3-sin(th0)^3)
   
   ang_pxx = c1*c2  
   ang_pxy = c1*c3
   ang_pxz = c4*c5
   ang_pyx = ang_pxy
   ang_pyy = c1*c6
   ang_pyz = c4*c7
   ang_pzx = ang_pxz
   ang_pzy = ang_pyz
   ang_pzz = c8   


   
   ;; Dimensions (theta,phi)
   ;;  .0299 <s0  <.1503
   ;; -.1455 <s1  <.1455
   ;; -.1455 <s2  <.1455
   ;; -.0712 <s3  <.0712
   ;;  .0000 <s4  <.1400	xx
   ;;  .0000 <s5  <.1400	yy
   ;;  .0057 <s6  <.0592	zz
   ;; -.0672 <s7  <.0672	xy
   ;; -.0581 <s8  <.0581	xz
   ;; -.0581 <s9  <.0581	yz
   ;; -.1455 <s10 <.1455
   ;; -.1455 <s11 <.1455
   ;; -.0712 <s12 <.0712
   s0=(sin(th0)-sin(th1))#(ph1-ph0)
   s1=(cos((th0+th1)/2)^2*(th0-th1))#(cos((ph1+ph0)/2)*(ph1-ph0))*1.d 
   s2=(cos((th0+th1)/2)^2*(th0-th1))#(sin((ph1+ph0)/2)*(ph1-ph0))*1.d 
   s3=(cos((th0+th1)/2)*sin((th0+th1)/2)*(th0-th1))#(ph1-ph0)*1.d 
   s4=(cos((th0+th1)/2)^3*(th0-th1))#(cos((ph1+ph0)/2)^2*(ph1-ph0)) 
   s5=(cos((th0+th1)/2)^3*(th0-th1))#(sin((ph1+ph0)/2)^2*(ph1-ph0)) 
   s6=(cos((th0+th1)/2)*sin((th0+th1)/2)^2*(th0-th1))#(ph1-ph0) 
   s7=(cos((th0+th1)/2)^3*(th0-th1))#$
      (cos((ph1+ph0)/2)*sin((ph1+ph0)/2)*(ph1-ph0)) 
   s8=(cos((th0+th1)/2)^2*sin((th0+th1)/2)*(th0-th1))#$
      (cos((ph1+ph0)/2)*(ph1-ph0)) 
   s9=(cos((th0+th1)/2)^2*sin((th0+th1)/2)*(th0-th1))#$
      (sin((ph1+ph0)/2)*(ph1-ph0)) 
   s10=s1                       
   s11=s2                       
   s12=s3                       

   stop
   
   ;; Normalize s0-s12 to maximum value
   s0max=max(s0) & s0=s0/s0max	
   s1max=max(s1) & s1=s1/s1max
   s2max=max(s2) & s2=s2/s1max
   s3max=max(s3) & s3=s3/s1max
   s4max=max(s4) & s4=s4/s4max
   s5max=max(s5) & s5=s5/s4max
   s6max=max(s6) & s6=s6/s4max
   s7max=max(s7) & s7=s7/s4max
   s8max=max(s8) & s8=s8/s4max
   s9max=max(s9) & s9=s9/s4max
   s10max=max(s10) & s10=s10/s10max
   s11max=max(s11) & s11=s11/s10max
   s12max=max(s12) & s12=s12/s10max



   
   ;; Change for SPAN-Ai
   ;;
   ;;#################################################################
   ;;# For Themis                                                    #
   ;;#                                                               #
   ;;# Multiply wN*pN to get wpN and truncate to 16 bits assuming    #
   ;;# positive definite and wpN<1, N(M).                            #
   ;;#                                                               #
   ;;# Multiply wpN*sMij to get wpsMij and truncate to +/- 15 bits   #
   ;;# assuming abs(wpsNMij)<1.                                      #
   ;;#                                                               #
   ;;# Multiply Cij*wpsNMij and sum over ij into 32 bit registers    #
   ;;# for each of M moments.                                        #
   ;;#                                                               #
   ;;# Let the processor do the compression to 16 or fewer           #
   ;;# bits before storage.                                          #
   ;;#################################################################

   
   ;; Density
   const        = (mass*1.e-10/2.)^(.5)/integ_t/gf
   density_norm = total(data*(wp0#reform(s0,256)))
   density      = const*(dengy*emax^(-.5))*density_norm*w0max*s0max
   print,density

   ;; Flux
   flux1_norm = total(data*(wp1#reform(s1,256)))
   flux2_norm = total(data*(wp1#reform(s2,256)))
   flux3_norm = total(data*(wp1#reform(s3,256)))
   print,flux1_norm,flux2_norm,flux3_norm

   const = 1./integ_t/gf
   print,const*dengy*w1max*s1max

   flux1 = const*dengy*flux1_norm*w1max*s1max
   flux2 = const*dengy*flux2_norm*w1max*s1max
   flux3 = const*dengy*flux3_norm*w1max*s1max
   flux  = [flux1,flux2,flux3]
   print,flux

   ;; Velocity
   vel = 1.e-5*flux/density
   print,vel

   ;; Momentum/pressure tensor
   p1_norm = total(data*(wp2#reform(s4,256)))
   p2_norm = total(data*(wp2#reform(s5,256)))
   p3_norm = total(data*(wp2#reform(s6,256)))
   p4_norm = total(data*(wp2#reform(s7,256)))
   p5_norm = total(data*(wp2#reform(s8,256)))
   p6_norm = total(data*(wp2#reform(s9,256)))

   const = (mass*1.e-10/2.)^(-.5)/integ_t/gf
   p1 = const*(dengy*emax^(.5))*p1_norm*w2max*s4max
   p2 = const*(dengy*emax^(.5))*p2_norm*w2max*s4max
   p3 = const*(dengy*emax^(.5))*p3_norm*w2max*s4max
   p4 = const*(dengy*emax^(.5))*p4_norm*w2max*s4max
   p5 = const*(dengy*emax^(.5))*p5_norm*w2max*s4max
   p6 = const*(dengy*emax^(.5))*p6_norm*w2max*s4max
   press = ([p1,p2,p3,p4,p5,p6]-$
            [vel(0)*flux(0),vel(1)*flux(1),vel(2)*flux(2),$
             vel(0)*flux(1),vel(0)*flux(2),vel(1)*flux(2)])*mass*1.e-10
   print,p1,p2,p3,p4,p5,p6
   print,press

   ;; Temperature
   print,press(0:2)/density     

   ;; Heat flux or energy flux
   q1_norm = total(data*(wp3#reform(s10,256)))
   q2_norm = total(data*(wp3#reform(s11,256)))
   q3_norm = total(data*(wp3#reform(s12,256)))
   print,q1_norm,q2_norm,q3_norm

   const = .5*mass*(mass*1.e-10/2.)^(-1.0)/integ_t/gf
   q1 = const*(dengy*emax^(1.0))*q1_norm*w3max*s10max
   q2 = const*(dengy*emax^(1.0))*q2_norm*w3max*s10max
   q3 = const*(dengy*emax^(1.0))*q3_norm*w3max*s10max
   print,q1,q2,q3
   print,const*(dengy*emax^(1.0))*w3max*s10max

   ;; Typical dynamic range of normalized electron moments   
   print,density_norm
   print,flux1_norm,flux2_norm,flux3_norm
   print,p1_norm,p2_norm,p3_norm,p4_norm,p5_norm,p6_norm
   print,q1_norm,q2_norm,q3_norm


END

;;	ps0	ps1	ms2	ms3	fac4
;; pot	20	40	4.	8.	20
;; temp	100.	1000.	100.	50.	200.*[1.,0.1,0.1]
;; n_e	1.	.1	300.	5.	1.
;; vd	[20.,0.,0.]	[500.,0.,0.]	[100.,0.,0.]
;;     [600.,0.,0.] 	[6000.d,0.d,0.d]

;; No statistical noise
;;	ps0		ps1		ms2		ms3
;;  m0	4188		423		1.24e+06	20612.	
;;  m1	44.4		111		66614.		6654.
;;  m2	0		-0.0004		-0.436		-0.005
;;  m3	0		6.8e-14		-8.69e-11	-2.67e-13	
;;  m4	353		354		106042.		918.
;;  m5	353		353		105982.		882.
;;  m6	877		877		263030.		2188.
;;  m7	2.e-5		2.11e-05	-0.014		6.70e-05	
;;  m8	-8.e-7		4.95e-06	0.00059		3.40e-05	
;;  m9	2.e-6		1.48e-06	0.00082		1.20e-06	
;; m10	.3		7.6		456		23.
;; m11	-8.e-6		-2.57e-05	-0.0024		-1.44e-05	
;; m12	-2.e-15		3.11e-15	6.07e-13	1.50e-15
		
;; With statistical noise
;;	ps0	ps1	ms2		ms3	fac4
;;  m0	4189	429	1.24e+06	20609	3929.
;;  m1	104.9	132.	68131.		6753.	11530.
;;  m2	44.7	-5.4	-1030.		36.5	-7.1
;;  m3	127.8	67.4	-661.		-58.7	125.9
;;  m4	349.4	358	106064.		911.	1154.
;;  m5	351.5	351.	106020.		877.	66.5
;;  m6	878.5	864.	262940.		2180.	199.3
;;  m7	-6.83	-1.56	-64.		-3.39	-2.0
;;  m8	-2.23	8.6	-81.		-0.71	7.6
;;  m9	-2.43	-1.8	44.1		-1.70	0.79
;; m10	0.49	6.6	464		22.8	113.
;; m11	0.26	0.45	0.31		-0.002	-0.2
;; m12	1.17	5.0	-10.9		0.449	1.2


;; Suggested dynamic range
;;	signed	max	min	compress
;;m0	no  	2^24	2^5	? bits
;;m1	yes  	2^20	2^1	? bits
;;m2	yes 	2^20	2^1	? bits
;;m3	yes 	2^20	2^1	? bits
;;m4	no 	2^20	2^1	? bits
;;m5	no 	2^20	2^1	? bits
;;m6	no 	2^20	2^1	? bits
;;m7	yes 	2^20	2^1	? bits
;;m8	yes 	2^20	2^1	? bits
;;m9	yes 	2^20	2^1	? bits
;;m10	yes	



;; Notes

;;The s/c potential correction will result in underestimating the density.
;;The error is small if an energy step is just above the s/c potential
;;and is largest for an energy step just below s/c potential.
;;The error is larger for large s/c potential and low temperature.

;;Flux is generally calculated accurately.
;;However, the resulting velocity will be in error due to inaccurate density.
;;We may want to build a correction on the ground that depends on s/c
;;potential, the actual energy sweep, and the temperature.

;;Significant errors are introduced to the moments if the
;;anisotropy is large -- ie Tpar/Tperp<.1
;;Therefore narrow beams will not be treated properly.
;;The same is true if the drift is large.



;;
;;   print, 'Roberto theta values'      
;;   ;; <cos(th)>
;;   FD[*,0]  = SFD * def_eff     * $
;;              (sin(th1*!DTOR)-sin(th0*!DTOR)) / $
;;              (((th1-th0) MOD 360)*!DTOR) + 0.5
;;   FDA[*,0] = SFD * def_eff_att * $
;;              (sin(th1*!DTOR)-sin(th0*!DTOR)) / $
;;              (((th1-th0) MOD 360)*!DTOR) + 0.5
;;   
;;   ;; <cos(th)^2>
;;   FD[*,1]  = SFD * def_eff     * $
;;              (1./2.)*(-1.*th0*!DTOR-sin(th0*!DTOR)*cos(th0*!DTOR)+$
;;                       th1*!DTOR+sin(th1*!DTOR)*cos(th1*!DTOR)) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5                 
;;   FDA[*,1] = SFD * def_eff_att * $
;;              (1./2.)*(-1.*th0*!DTOR-sin(th0*!DTOR)*cos(th0*!DTOR)+$
;;                       th1*!DTOR+sin(th1*!DTOR)*cos(th1*!DTOR)) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5
;;
;;   ;; <sin(th)cos(th)>
;;   FD[*,2]  = SFD * def_eff     * $
;;              (1./4.)*(cos(2.*th0*!DTOR)-cos(2.*th1*!DTOR)) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5
;;   FDA[*,2] = SFD * def_eff_att * $
;;              (1./4.)*(cos(2.*th0*!DTOR)-cos(2.*th1*!DTOR)) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5
;;   
;;   ;; <cos(th)^3>
;;   FD[*,3]  = SFD * def_eff     * $
;;              (1./12.) * (-9.*sin(th0*!DTOR)-sin(3*th0*!DTOR)+$
;;                          9.*sin(th1*!DTOR)+sin(3*th1*!DTOR)) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5
;;   FDA[*,3] = SFD * def_eff_att * $
;;              (1./12.) * (-9.*sin(th0*!DTOR)-sin(3*th0*!DTOR)+$
;;                          9.*sin(th1*!DTOR)+sin(3*th1*!DTOR)) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5
;;   
;;   ;; <cos(th)sin(th)^2>
;;   FD[*,4]  = SFD * def_eff     * $
;;              (1./3.)*(sin(th1*!DTOR)^3-sin(th0*!DTOR)^3) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5
;;   FDA[*,4] = SFD * def_eff_att * $
;;              (1./3.)*(sin(th1*!DTOR)^3-sin(th0*!DTOR)^3) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5
;;   
;;   ;; <cos(th)^2sin(th)>
;;   FD[*,5]  = SFD * def_eff     * $
;;              (1./3.)*(cos(th0*!DTOR)^3-cos(th1*!DTOR)^3) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5      
;;   FDA[*,5] = SFD * def_eff_att * $
;;              (1./3.)*(cos(th0*!DTOR)^3-cos(th1*!DTOR)^3) / $
;;              (((th1-th0) MOD 360.)*!DTOR) + 0.5      
;;
;;
;;
;;
;;      ;; ------------ VALUES FROM ROBERTO -----------------
;;      print, 'Roberto phi values'
;;      ;; 1
;;      FS[0,*]  = anode_eff     * SFA + 0.5
;;      FSA[0,*] = anode_eff_att * SFA + 0.5
;;      ;; <cos(phi)>
;;      FS[1,*]  = SFA * anode_eff     * $
;;                 (sin(phi1*!DTOR)-sin(phi0*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5
;;      FSA[1,*] = SFA * anode_eff_att * $
;;                 (sin(phi1*!DTOR)-sin(phi0*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5
;;      ;; <sin(phi)>
;;      FS[2,*]  = SFA * anode_eff     * $
;;                 (cos(phi0*!DTOR)-cos(phi1*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5
;;      FSA[2,*] = SFA * anode_eff_att * $
;;                 (cos(phi0*!DTOR)-cos(phi1*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5
;;      ;; <cos(phi)^2>
;;      FS[3,*]  = SFA * anode_eff     * $
;;                 (1./2.)*(-1.*phi0*!DTOR-sin(phi0*!DTOR)*cos(phi0*!DTOR)+$
;;                          phi1*!DTOR+sin(phi1*!DTOR)*cos(phi1*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5
;;      FSA[3,*] = SFA * anode_eff_att * $
;;                 (1./2.)*(-1.*phi0*!DTOR-sin(phi0*!DTOR)*cos(phi0*!DTOR)+$
;;                          phi1*!DTOR+sin(phi1*!DTOR)*cos(phi1*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5
;;      ;; <sin(phi)^2>
;;      FS[4,*]  = SFA * anode_eff     * $
;;                 (1./2.)*(-1.*phi0*!DTOR+sin(phi0*!DTOR)*cos(phi0*!DTOR)+$
;;                          phi1*!DTOR-sin(phi1*!DTOR)*cos(phi1*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5
;;      FSA[4,*] = SFA * anode_eff_att * $
;;                 (1./2.)*(-1.*phi0*!DTOR+sin(phi0*!DTOR)*cos(phi0*!DTOR)+$
;;                          phi1*!DTOR-sin(phi1*!DTOR)*cos(phi1*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5
;;      ;; <sin(phi)cos(phi)>
;;      FS[5,*]  = SFA * anode_eff     * $
;;                 (1./4.)*(cos(2.*phi0*!DTOR)-cos(2.*phi1*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5
;;      FSA[5,*] = SFA * anode_eff_att * $
;;                 (1./4.)*(cos(2.*phi0*!DTOR)-cos(2.*phi1*!DTOR)) / $
;;                 (((phi1-phi0) MOD 360.)*!DTOR) + 0.5

