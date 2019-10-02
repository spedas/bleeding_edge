;+
;
;
; SPP_SWP_SWEEPV_NEW_V2
;
; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2019-09-30 22:43:11 -0700 (Mon, 30 Sep 2019) $
; $LastChangedRevision: 27805 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/tables/spp_swp_sweepv_new_v2.pro $
;
;-

PRO spp_swp_sweepv_new_v2,sweepv,defv1,defv2,spv,k=k,rmax=rmax,vmax=vmax,nen=nen,e0=e0,emax=emax,spfac=spfac,version=version,maxspen=maxspen,plot=plot,new_defl=new_defl

   ;; Keyword Check
   IF NOT keyword_set(k)       THEN k       = 16.7
   IF NOT keyword_set(rmax)    THEN rmax    = 11.0
   IF NOT keyword_set(vmax)    THEN vmax    = 4000
   IF NOT keyword_set(nen)     THEN nen     = 128 
   IF NOT keyword_set(e0)      THEN e0      = 5.0
   IF NOT keyword_set(emax)    THEN emax    = 20000.
   IF NOT keyword_set(spfac)   THEN spfac   = 0.
   IF NOT keyword_set(maxspen) THEN maxspen = 5000.

   nang = 4096/nen
   
   exp = (emax/e0)^(1.0/(nen-1)) -1 

   ;; Hemisphere voltage sweep
   vsweep = reverse(e0/k * (1+exp)^findgen(nen)) 
   stepnum = findgen(nang/2)
   
   sweepv = 0.
   defv1  = 0.
   defv2  = 0.
   spv    = 0.
   flip   = 0

   
   for i = 0,nen-1 do begin

      vdm = (rmax < vmax/vsweep[i])

      ;; Deflector multiplier (including fixed gain)
      vd = vdm * (0.5+stepnum)/(nang/2-0.5) 

      sweepv = [sweepv,replicate(vsweep[i],nang)]

      ;; Spoiler cuts off above some energy
      if vsweep[i] lt maxspen/k then spr = spfac else spr = 0.0	
      
      ;; Spoiler multiplier
      spv = [spv,replicate(spr,nang)]				
      
      ;; Two halves of deflector sweep
      add1 = [reverse(vd),replicate(0,nang/2)] 
      add2 = [replicate(0,nang/2),vd]
      
      ;; Sweep one way on evens, other way on odds
      if (0 and flip) then begin           
         add1 = reverse(add1) 
         add2 = reverse(add2)
      endif
      
      defv1 = [defv1,add1]
      defv2 = [defv2,add2]
      
      ;; An unnecessarily complicated way to do the flipping
      flip = (flip + 1) mod 2 
      
   endfor
   
   spv = spv < 80/sweepv
   
   sweepv = sweepv[1:4096]
   defv1  = defv1[1:4096]
   defv2  = defv2[1:4096]
   spv    = spv[1:4096]
   
   if keyword_set(plot) then begin
                                ;print,nen,nang
      wi,3
      !p.multi = [0,1,3]
      plot,sweepv,psym=10,$
           xtitle = 'Index Step',$
           ytitle = 'Sweep Voltage',$
           yrange = [0,vmax],$
           charsize = 2
      oplot,defv1*sweepv,color = 50,psym = 10
      oplot,defv2*sweepv,color = 250,psym = 10     
      plot,sweepv,psym=10,$
           xtitle = 'Index Step',$
           ytitle = 'Sweep Voltage (Log)',$
           yrange = [0.1,vmax],$
           /ylog,$
           charsize = 2,$
           /ystyle
      oplot,defv1*sweepv,color = 50,psym = 10
      oplot,defv2*sweepv,color = 250,psym = 10
      oplot,spv*sweepv,color = 150,psym = 10     
      plot,defv1,psym = 10,$
           xtitle = 'Index Step',$
           ytitle = 'Sweep Voltage Ratio',$
           charsize = 2, $
           yrange = [0,rmax]
      oplot,defv1,psym=10,color = 50
      oplot,defv2,color = 250,psym = 10
      oplot,spv,color = 150,psym = 10
      
      !p.multi = 0
   endif
   
end
