;+
;
;
;
; SPP_SWP_SWEEPV_NEW_TSLUT_V2
;
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2022-03-14 16:12:49 -0700 (Mon, 14 Mar 2022) $
; $LastChangedRevision: 30678 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/tables/spp_swp_sweepv_new_tslut_v2.pro $
;
;-

PRO spp_swp_sweepv_new_tslut_v2,sweepv,defv1,defv2,spv,fsindex,tsindex,nen=nen,e0=e0,emax=emax,edpeak=edpeak,plot=plot,version=version,spfac=spfac,new_defl=new_defl,defl_lim=defl_lim


   ;; Number of energies in fine sweep table 
   ;; (full table has 4x as many)
   if not keyword_set(nen)    then nen = 32 
   if not keyword_set(edpeak) then edpeak = 0


   nen = 32

   ;; Default version is 2
   if ~keyword_set(version) then version = 2
   
   ;; Get the full sweep table and index
   spp_swp_sweepv_new_fslut_v2,sweepv,defv1,defv2,spv,fsindex,nen=nen,e0=e0,emax=emax,plot=plot,version=version,spfac=spfac,new_defl=new_defl


   ;; Version 3
   ;;
   ;; Select a single energy and 8 deflections from the full index table and
   ;; repeat 2Ex8A 16 times within single "Targeted" sweep.
   ;;
   if  version eq 3 then begin

      ;; Find all 32 energies from full sweep
      enrgs = reform((reform((sweepv*16.7)[fsindex[indgen(256)*4+2]],8,32))[0,*])
      
      ;; The first energy bin should align with the proton core
      e1 = 5218.

      ;; The second energy bin should align with the proton beam core
      ;;e2 = 5218.

      ;; Find the sweep energy bins closest to both e1 and e2
      tmp1 = min(ABS(enrgs - e1),loc1)
      ;;tmp2 = min(ABS(enrgs - e2),loc2)

      ;; Select these two energy bins from downsampled full sweep
      fsindex1 = (reform(fsindex[indgen(256)*4+2],8,32))[*,loc1]
      fsindex2 = reverse((reform(fsindex[indgen(256)*4+2],8,32))[*,loc1])
      ;;fsindex2 = reverse((reform(fsindex[indgen(256)*4+2],8,32))[*,loc2])
      
      ;; Combine into single repetitive targeted sweep
      tsindex = rebin(reform(rebin([[fsindex1],[fsindex2]],8,2,16),256),256,256)

   ENDIF




   ;; Version 2
   ;;
   ;; Evenly Spaced Targeted LUT
   ;; Targeted Table using evenly (as opposed to oddly) spaced full scans.
   if  version eq 2 then begin
      ;; Get start index of each sub-stepping
      ;;edindex = fsindex[indgen(256)*4]   
      ;; Interval for each E-D step in full sweep

      ;; This is the peak index into the
      ;; master 4096-element S-LUT.
      if nen ne 32 then message,'error'
      pindexs = fsindex[edpeak * 4 +indgen(4)]
      pindex = min(pindexs)    ;; Lowest index of substeps of peak
      nang = 256/nen           ;; Number of angles in fine sweep table
                               ;; Typially 8
      ;; Lots of '*4' to take into account
      ;; size of full table.
      eindex = (0 >  ((pindex/32)-nen/2-2)  )  <  (128-nen)      ;; should be less than 128-32
      dindex = (0 > ((pindex mod 32)-nang/2+2)  )   <  (32 - nang) ; should be less than 32-8
      
      tsindex = []
      for e=0,nen-1 do begin
         ind = indgen(nang) + (e+eindex)*32 + dindex
         if (e and 1) then ind = reverse(ind) ;; reverse every odd energy step
         tsindex = [tsindex,ind]
      endfor

   ENDIF
   
   ;; Version 1
   ;;
   ;; Oddly Spaced Targeted LUT
   ;; Original Targeted table that is used togetjer with oddly spaced full sweeps.
   IF version EQ 1 THEN BEGIN 
   ;;endif else begin ;; old method (version 1)
      
      ;; Get center index of each sub-stepping
      edindex = fsindex[indgen(256)*4+2]
      ;; Interval for each E-D step in full sweep

      ;; This is the peak index into the 
      ;; master 4096-element S-LUT.
      pindex = edindex[edpeak]
      
      if keyword_set(plot) then begin
         ;;print,pindex
         plots,sweepv[pindex],defv1[pindex]-defv2[pindex],psym=7,color=250,thick=2
      endif
      
      ;; Number of angles in fine sweep table 
      ;; (full table has 4x as many).
      nang = 256/nen 
      
      ;; Lots of '*4' to take into account 
      ;; size of full table.
      eindex = floor(pindex/(nang*4)) 
      dindex = pindex mod (nang*4)
      
      ;;if keyword_set(plot) or 1 then print,eindex,dindex
      
      eindmin = eindex-nen/2
      
      ;; All of this complication is to make sure 
      ;; that we don't go off the edge of the table 
      ;; if the peak is near the edge.
      if eindmin lt 0 then begin 
         eindmin = 0    
         eindmax = nen-1
      endif else begin
         eindmax = eindmin+nen-1
         if eindmax gt (4*nen-1) then begin
            eindmax = 4*nen-1
            eindmin = 3*nen
         endif
      endelse
      
      dindmin = dindex-nang/2
      if dindmin lt 0 then begin
         dindmin = 0
         dindmax = nang-1
      endif else begin
         dindmax = dindmin+nang-1
         if dindmax gt (4*nang-1) then begin
            dindmax = 4*nang-1
            dindmin = 3*nang
         endif
      endelse
      
      if keyword_set(plot) then print,eindmin, eindmax, dindmin, dindmax 
      
      if (eindex mod 2) then odd = 1 else odd = 0
      tsindex = []
      for i = 0,nen-1 do begin
         sodd = (eindmin+i) mod 2
         ;; Does the necessary flipping of 
         ;; every other step to take.
         if odd eq sodd then begin 
            ;; Into account the up/down 
            ;; even/odd deflector sweeps
            di1 = dindmin      
         endif else begin
            di1 = 4*nang-1-dindmax	
         endelse
         
         tsindex = [tsindex,(eindmin+i)*nang*4+di1+indgen(nang)]
      endfor
   ENDIF
   

   ;; PLOT
   ;;plot = 1
   IF keyword_set(plot) THEN BEGIN
      ;;GOTO, skip
      wi,6
      !p.multi = [0,1,3]
      plot,sweepv[tsindex],psym=10,xtitle = 'Time Step',ytitle = 'Sweep Voltage',yrange = [0,4000],charsize = 2
      oplot,defv1[tsindex]*sweepv[tsindex],color = 50,psym = 10
      oplot,defv2[tsindex]*sweepv[tsindex],color = 250,psym = 10
      plot,sweepv[tsindex],psym=10,xtitle = 'Time Step',ytitle = 'Sweep Voltage (Log)',yrange = [0.1,4000],/ylog,charsize = 2,/ystyle
      oplot,defv1[tsindex]*sweepv[tsindex],color = 50,psym = 10
      oplot,defv2[tsindex]*sweepv[tsindex],color = 250,psym = 10
      oplot,spv[tsindex]*sweepv[tsindex],color = 150,psym = 10
      plot,defv1[tsindex],psym=10,xtitle = 'Time Step',ytitle = 'Sweep Voltage Ratio',charsize = 2,yrange = [0,12]
      oplot,defv1[tsindex],psym=10,color = 50
      oplot,defv2[tsindex],color = 250,psym = 10
      oplot,spv[tsindex],color = 150,psym = 10
      !p.multi = 0

      skip:

      wi,5
      symsize=0.6
      plot,sweepv,defv1-defv2,$
           psym = 7,$
           /xlog, $
           xtitle = 'V_SWEEP (Volts)',$
           ytitle = 'V_DEF/V_SWEEP (D1+, D2-)',$
           charsize = 2,$
           symsize = symsize, $
           /xstyle,$
           /ystyle, $
           yrange = [-12, 12]

      ;;nn = n_elements(tsindex[*,0])
      ;;FOR ii=0., nn-1 DO BEGIN
      ;;   clr = (ii MOD 32) / 32. * 250.
      ;;   plots,sweepv[tsindex[ii,0]],defv1[tsindex[ii,0]]-defv2[tsindex[ii,0]], psym = 1,color = clr,symsize = 2, thick=4
      ;;   wait, 0.25
      ;;ENDFOR
      
      plots,sweepv[tsindex],defv1[tsindex]-defv2[tsindex], psym = 1,color = 150,symsize = 2, thick=4
      oplot,sweepv[tsindex],defv1[tsindex]-defv2[tsindex], psym=-7,color=2,symsize = symsize
      ;;plots,sweepv[pindexs],defv1[pindexs]-defv2[pindexs],    psym = 7,color = 6,thick=2 ;,symsize = symsize

      
      ;;findexs = fsindex[indgen(256)*4]
      ;;plots,sweepv[fsindex],defv1[fsindex]-defv2[fsindex],    psym = -3,color = 6,thick=2 ;,symsize = symsize
      ;;plots,sweepv[findexs],defv1[findexs]-defv2[findexs],    psym =7,color = 6,thick=2 ;,symsize = symsize
      ;;stop
   endif

   
end
