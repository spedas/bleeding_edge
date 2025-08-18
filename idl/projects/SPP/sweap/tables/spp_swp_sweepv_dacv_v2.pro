;+
;
; SPP_SWP_SWEEPV_DACV_V2
;
;
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2022-09-16 17:09:39 -0700 (Fri, 16 Sep 2022) $
; $LastChangedRevision: 31101 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/tables/spp_swp_sweepv_dacv_v2.pro $
;
;-

PRO spp_swp_sweepv_dacv_v2,sweepv_dac,defv1_dac,defv2_dac,spv_dac,k=k,rmax=rmax,vmax=vmax,nen=nen,e0=e0,emax=emax,spfac=spfac,maxspen=maxspen,plot=plot,$
                           hvgain=hvgain,spgain=spgain,version=version,fixgain=fixgain,new_defl=new_defl,spe=spe,defl_lim=defl_lim

   max = 65536.
   
   ;; Set Defaults
   IF NOT keyword_set(k)       THEN k       = 16.7
   IF NOT keyword_set(rmax)    THEN rmax    = 11.0
   IF NOT keyword_set(vmax)    THEN vmax    = 4000
   IF NOT keyword_set(nen)     THEN nen     = 128 
   IF NOT keyword_set(e0)      THEN e0      = 5.0
   IF NOT keyword_set(emax)    THEN emax    = 20000.
   IF NOT keyword_set(spfac)   THEN spfac   = 0.
   IF NOT keyword_set(maxspen) THEN maxspen = 5000.
   IF NOT keyword_set(hvgain)  THEN hvgain  = 1000.
   IF NOT keyword_set(spgain)  THEN spgain  = 20.12
   IF NOT keyword_set(fixgain) THEN fixgain = 13.

   ;; Generate Sweep Voltages
   spp_swp_sweepv_new_v2, sweepv,defv1,defv2,spv,k=k,rmax=rmax,vmax=vmax,nen=nen,e0=e0,emax=emax,spfac=spfac,maxspen=maxspen,plot=plot,vsweep=vsweep

   ;; Change Voltages to DAC
   sweepv_dac = max*sweepv/(4*hvgain)
   defv1_dac  = max*defv1/fixgain
   defv2_dac  = max*defv2/fixgain
   spv_dac    = max*spv*sweepv/(4*spgain)

   sweepv_dac = round(sweepv_dac)
   defv1_dac  = round(defv1_dac)
   defv2_dac  = round(defv2_dac)
   spv_dac    = round(spv_dac)

   ;; New Deflector DAC values based on flight calibration
   IF keyword_set(new_defl) THEN BEGIN
      
      ;; From python code
      defMax = 60.
      defMin = -60.
      defl_range=[defMin,defMax]
      nang = 32
      angleWidth = (defMax - defMin)/nang
      angleCenter = angleWidth / 2
      angles = (defMax-defMin)-findgen(32)*angleWidth-anglewidth/2-defMax
      defv1_dac = lonarr(4096)
      defv2_dac = lonarr(4096)
      FOR i=0, 4095 DO BEGIN
         angleIndex = i MOD 32
         angleDac = spp_swp_sweepv_defl_func(spe=spe, angles[angleIndex])
         IF angleDac GT 0 THEN BEGIN 
            defv1_dac[i] = round(abs(angleDac))
            defv2_dac[i] = 0
         ENDIF 
         IF angleDac LE 0 THEN BEGIN
            defv1_dac[i] = 0        
            defv2_dac[i] = round(abs(angleDac))
         ENDIF
      ENDFOR 

   ENDIF


   ;; New Deflector DAC values based on flight calibration and
   ;; with corrected maximum V limits for the deflections.
   IF keyword_set(defl_lim) THEN BEGIN
      
      ;; From python code
      defMax = 60.
      defMin = -60.
      defl_range=[defMin,defMax]
      nang = 32
      angleWidth = (defMax - defMin)/nang
      angleCenter = angleWidth / 2
      angles = (defMax-defMin)-findgen(32)*angleWidth-anglewidth/2-defMax
      defv1_dac = lonarr(4096)
      defv2_dac = lonarr(4096)
      FOR i=0, 4095 DO BEGIN
         angleIndex = i MOD 32
         angleDac = spp_swp_sweepv_defl_func(spe=spe, angles[angleIndex])
         IF angleDac GT 0 THEN BEGIN 
            defv1_dac[i] = round(abs(angleDac))
            defv2_dac[i] = 0
         ENDIF 
         IF angleDac LE 0 THEN BEGIN
            defv1_dac[i] = 0        
            defv2_dac[i] = round(abs(angleDac))
         ENDIF
      ENDFOR 

      ;; Correction for overdeflections

      ;; Cycle through all 128 energy steps
      FOR i=0, 127 DO BEGIN

         flip = 0
         
         ;; If deflector voltage at each energy exceeds 4000 then adjust accordingly
         IF vmax/vsweep[i] LT rmax THEN BEGIN
            
            ;; Use maximum deflector multiplier value at this energy step
            vdm = vmax/vsweep[i]
            
            ;; Deflector multiplier (including fixed gain)
            stepnum = findgen(nang/2)
            vd = vdm * (0.5+stepnum)/(nang/2-0.5)

            ;; Two halves of deflector sweep
            defv1 = [reverse(vd),replicate(0,nang/2)] 
            defv2 = [replicate(0,nang/2),vd]
            
            ;; Sweep one way on evens, other way on odds
            if (0 and flip) then begin           
               defv1 = reverse(defv1) 
               defv2 = reverse(defv2)
            endif

            ;; Insert inot original deflector dac array
            defv1_dac[32*i:32*i+31]  = max*defv1/fixgain
            defv2_dac[32*i:32*i+31]  = max*defv2/fixgain

            ;; An unnecessarily complicated way to do the flipping
            flip = (flip + 1) mod 2 
            
         ENDIF
         
         
      ENDFOR
      
   ENDIF

   
   
   nang = 4096/nen
   
   num = fltarr(50)
   for i = 0,49 do begin
      ;; Big fix for low resolution at low end of sweep
      w = where(sweepv_dac le i,nw) 
      num[i] = nw/nang
   endfor
   
   cut = where(indgen(50)-num gt 4)
   thresh = cut[0]
   
   w = where(sweepv_dac le thresh,nw)
   steps = nw/nang
   
   for i = 0,steps-1 do begin
      sweepv_dac[w[i*nang]:w[i*nang+nang-1]] = replicate(thresh-i,nang)
   endfor

   
   ;; Fix spoiler at low end to match slut
   spv_dac[w] = round(spv[w]*sweepv_dac[w]*hvgain/spgain)    ; THIS LOOKS very sloppy  W = -1 here.

   if keyword_set(plot) then begin
      wi,1
      !p.multi = [0,1,3]
      plot,sweepv_dac,psym=10,$
           xtitle = 'Time Step',$
           ytitle = 'Sweep DAC',$
           yrange = [0,max],$
           charsize = 2,/xstyle ,$
           /ystyle
      oplot,defv1_dac,color = 50,psym = 10
      oplot,defv2_dac,color = 250,psym = 10
      oplot,spv_dac,color = 150,psym = 10
      stop
      plot,sweepv_dac,psym=10,$
           xtitle = 'Time Step',$
           ytitle = 'Sweep DAC (Log)',$
           yrange = [1,max],$
           /ylog,$
           charsize = 2,$
           /ystyle,/xstyle
      oplot,defv1_dac,color = 50,psym = 10
      oplot,defv2_dac,color = 250,psym = 10
      oplot,spv_dac,color = 150,psym = 10
      
      plot,sweepv_dac/max*4*hvgain,psym=10,$
           xtitle = 'Time Step',$
           ytitle = 'Sweep (Log)',$
           yrange = [0.1,vmax],$
           /ylog,$
           charsize = 2,$
           /ystyle,/xstyle
      oplot,defv1_dac/max*fixgain*sweepv_dac/max*4*hvgain,color = 50,psym = 10
      oplot,defv2_dac/max*fixgain*sweepv_dac/max*4*hvgain,color = 250,psym = 10
      oplot,spv_dac/max*4*spgain,color = 150,psym = 10
      !p.multi = 0

   endif
   
end
