;; -------------------------------------------- ;;
;; ---------- Sweep Voltages ------------------ ;;
;; -------------------------------------------- ;;
;;PRO spp_swp_spx_get_voltages,sweepv,defv1,$
;;                             defv2, spv,$
;;                             version=version,$
;;                             k=k,rmax=rmax,$
;;                             vmax=vmax,nen=nen,$
;;                             e0=e0,emax=emax,$
;;                             spfac=spfac,$
;;                             maxspen=maxspen,$
;;                             hvgain=hvgain,$
;;                             spgain=spgain,$
;;                             fixgain=fixgain
PRO spp_swp_spx_get_voltages, table

   sweepv = 0.
   defv1  = 0.
   defv2  = 0.
   spv    = 0.
   flip   = 0
   nang = 4096/table.nen

   ;; Was e0 same as emin???
   exp = (table.emax/table.emin)^(1.0/(table.nen-1)) -1 

   ;; Hemisphere voltage sweep
   vsweep = reverse(table.emin/table.k * (1+exp)^findgen(table.nen)) 
   stepnum = findgen(nang/2)

   ;; Cycle through Steps
   for i = 0,table.nen-1 do begin

      vdm = (table.rmax < table.vmax/vsweep[i])

      ;; Deflector multiplier (including fixed gain)
      vd = vdm * (0.5+stepnum)/(nang/2-0.5) 
      sweepv = [sweepv,replicate(vsweep[i],nang)]

      ;; Spoiler cuts off above some energy
      if vsweep[i] lt table.maxspen/table.k then spr = table.spfac else spr = 0.0	

      ;; Spoiler multiplier
      spv = [spv,replicate(spr,nang)]				

      ;; Two halves of deflector sweep
      add1 = [reverse(vd),replicate(0,nang/2)] 
      add2 = [replicate(0,nang/2),vd]

      ;; Sweep one way on evens, other way on odds

      ;; #### VERSION 2 ###########
      IF table.version EQ 2 THEN BEGIN 
         if (0 and flip) then begin           
            add1 = reverse(add1) 
            add2 = reverse(add2)
         ENDIF
      ENDIF
      ;; #### VERSION 1 ###########
      IF table.version EQ 1 THEN BEGIN 
         if (flip) then begin           
            add1 = reverse(add1) 
            add2 = reverse(add2)
         ENDIF
      ENDIF
      
      defv1 = [defv1,add1]
      defv2 = [defv2,add2]
      ;; An unnecessarily complicated way to do the flipping
      flip = (flip + 1) mod 2 
   endfor
   spv = spv < 80/sweepv

   ;;sweepv = sweepv[1:4096]
   ;;defv1  = defv1[1:4096]
   ;;defv2  = defv2[1:4096]
   ;;spv    = spv[1:4096]   

   table.hem_v  = sweepv[1:4096]
   table.def1_v = defv1[1:4096]
   table.def2_v = defv2[1:4096]
   table.spl_v  = spv[1:4096]   
   
END

;; -------------------------------------------- ;;
;; --------------- DACs ----------------------- ;;
;; -------------------------------------------- ;;
;;pro spp_swp_spx_get_dac,sweepv_dac, defv1_dac,$
;;                        defv2_dac, spv_dac, $
;;                        version=version,$
;;                        k=k,rmax=rmax,$
;;                        vmax=vmax,nen=nen,$
;;                        e0=e0,emax=emax,$
;;                        spfac=spfac,$
;;                        maxspen=maxspen,$
;;                        hvgain=hvgain,$
;;                        spgain=spgain,$
;;                        fixgain=fixgain
pro spp_swp_spx_get_dacs, table

   ;; Generate S-LUT Table
   ;;spp_swp_spx_get_voltages, sweepv, defv1, $
   ;;                          defv2, spv, $
   ;;                          version=version,$
   ;;                          k=k,rmax=rmax,$
   ;;                          vmax=vmax,nen=nen,$
   ;;                          e0=e0,emax=emax,$
   ;;                          spfac=spfac,$
   ;;                          maxspen=maxspen,$
   ;;                          hvgain=hvgain,$
   ;;                          spgain=spgain,$
   ;;                          fixgain=fixgain
   spp_swp_spx_get_voltages, table
   
   ;; Change to DAC
   ;;max = 65536.   
   ;;sweepv_dac = round(max*sweepv/(4*hvgain))
   ;;defv1_dac  = round(max*defv1/fixgain)
   ;;defv2_dac  = round(max*defv2/fixgain)
   ;;spv_dac    = round(max*spv*sweepv/(4*spgain))
   max = 65536.   
   table.hem_dac  = round(max*table.hem_v/(4.0*table.hvgain))
   table.def1_dac = round(max*table.def1_v/table.fixgain)
   table.def2_dac = round(max*table.def2_v/table.fixgain)
   table.spl_dac  = round(max*table.spl_v*table.hem_v/(4.0*table.spgain))

END

;; -------------------------------------------- ;;
;; --------------- SLUT ----------------------- ;;
;; -------------------------------------------- ;;
;;PRO spp_swp_spx_get_slut,sweepv_dac,defv1_dac,$
;;                         defv2_dac,spv_dac,$
;;                         version=version,$
;;                         k=k,rmax=rmax,$
;;                         vmax=vmax,nen=nen,$
;;                         e0=e0,emax=emax,$
;;                         spfac=spfac,$
;;                         maxspen=maxspen,$
;;                         hvgain=hvgain,$
;;                         spgain=spgain,$
;;                         fixgain=fixgain
PRO spp_swp_spx_get_slut, table
   
   ;;spp_swp_spx_get_dac,sweepv_dac,defv1_dac,$
   ;;                    defv2_dac, spv_dac, $
   ;;                    version=version,$
   ;;                    k=k,rmax=rmax,$
   ;;                    vmax=vmax,nen=nen,$
   ;;                    e0=e0,emax=emax,$
   ;;                    spfac=spfac,$
   ;;                    maxspen=maxspen,$
   ;;                    hvgain=hvgain,$
   ;;                    spgain=spgain,$
   ;;                    fixgain=fixgain
   spp_swp_spx_get_dacs, table

END

;; -------------------------------------------- ;;
;; -------------- FSLUT ----------------------- ;;
;; -------------------------------------------- ;;
;;PRO spp_swp_spx_get_fslut,index,version=version,$
;;                          k=k,rmax=rmax,$
;;                          vmax=vmax,nen=nen,$
;;                          e0=e0,emax=emax,$
;;                          spfac=spfac,$
;;                          maxspen=maxspen,$
;;                          hvgain=hvgain,$
;;                          spgain=spgain,$
;;                          fixgain=fixgain
PRO spp_swp_spx_get_fslut, table

   ;;nang = 256/nen * 4   
   ;;index = []
   nang = 256/table.nen * 4   
   index = []
   ;; Arrange deflector sweep
   CASE table.version OF
      1: BEGIN 
         FOR e=0,table.nen-1 DO BEGIN
            ind = (e*4+2) * nang + indgen(nang)
            IF e MOD 2 THEN ind = reverse(ind)
            index = [index, ind]
         ENDFOR
      END
      2: BEGIN
         FOR i = 0, table.nen-1 DO BEGIN
            flip = i MOD 2
            index = [index,(i*4+2-flip)*nang+indgen(nang)]
         ENDFOR
      END
   ENDCASE

   table.fsindex = index
   
END

;; -------------------------------------------- ;;
;; -------------- TSLUT ----------------------- ;;
;; -------------------------------------------- ;;
;;PRO spp_swp_spx_get_tslut,tsindex,$
;;                          fsindex,$
;;                          version=version,$
;;                          edpeak=edpeak,$
;;                          k=k,rmax=rmax,$
;;                          vmax=vmax,nen=nen,$
;;                          e0=e0,emax=emax,$
;;                          spfac=spfac,$
;;                          maxspen=maxspen,$
;;                          hvgain=hvgain,$
;;                          spgain=spgain,$
;;                          fixgain=fixgain
PRO spp_swp_spx_get_tslut, table, edpeak

   ;;spp_swp_spx_get_slut,fsindex,$
   ;;                     version=version,$
   ;;                     k=k,rmax=rmax,$
   ;;                     vmax=vmax,nen=nen,$
   ;;                     e0=e0,emax=emax,$
   ;;                     spfac=spfac,$
   ;;                     maxspen=maxspen,$
   ;;                     hvgain=hvgain,$
   ;;                     spgain=spgain,$
   ;;                     fixgain=fixgain

   spp_swp_spx_get_fslut, table
   
   ;;IF NOT keyword_set(nen)    THEN nen = 32 
   ;;IF NOT keyword_set(edpeak) THEN edpeak = 0
   
   ;; Error Check
   IF table.version GT 2 THEN message, 'Error'
   
   ;; --------- Version 2 ---------
   ;;IF version EQ 2 THEN BEGIN
   ;;   IF nen/4 NE 32 THEN message,'error'
   ;;   pindexs = fsindex[edpeak * 4 +indgen(4)]
   ;;   ;; Lowest index of substeps of peak
   ;;   pindex = min(pindexs)  
   ;;   nang = 256/nen  
   ;;   ;; Should be less than 128-32
   ;;   eindex = (0>((pindex/32)-nen/2-2))<(128-nen)   
   ;;   ;; Should be less than 32-8
   ;;   dindex = (0>((pindex mod 32)-nang/2+2))<(32-nang)  
   ;;   tsindex = []
   ;;   FOR e=0,nen-1 DO BEGIN
   ;;      ind = indgen(nang) + (e+eindex)*32 + dindex
   ;;      ;; Reverse every odd energy step
   ;;      IF (e AND 1) THEN ind = reverse(ind)  
   ;;      tsindex = [tsindex,ind]
   ;;   ENDFOR 
   ;;ENDIF

   IF table.version EQ 2 THEN BEGIN
      IF table.nen/4 NE 32 THEN message,'error'
      pindexs = table.fsindex[edpeak * 4 +indgen(4)]
      ;; Lowest index of substeps of peak
      pindex = min(pindexs)
      nang = 256/table.nen
      ;; Should be less than 128-32
      eindex = (0>((pindex/32)-table.nen/2-2))<(128-table.nen)   
      ;; Should be less than 32-8
      dindex = (0>((pindex mod 32)-nang/2+2))<(32-nang)
      tsindex = []
      FOR e=0,table.nen-1 DO BEGIN
         ind = indgen(nang) + (e+eindex)*32 + dindex
         ;; Reverse every odd energy step
         IF (e AND 1) THEN ind = reverse(ind)  
         tsindex = [tsindex,ind]
      ENDFOR 
   ENDIF
   table.tsindex[edpeak,*] = tsindex

   
   ;; --------- Version 1 ---------   
   ;;IF version EQ 1 THEN BEGIN 
   ;;   
   ;;   ;; Get center index of each sub-stepping
   ;;   edindex = fsindex[indgen(256)*4+2]
   ;;   ;; Interval for each E-D step in full sweep
   ;;   ;; This is the peak index into the 
   ;;   ;; master 4096-element S-LUT.
   ;;   pindex = edindex[edpeak]
   ;;   IF keyword_set(plot) THEN BEGIN
   ;;      ;;print,pindex
   ;;      plots,sweepv[pindex],$
   ;;            defv1[pindex]-defv2[pindex],$
   ;;            psym = 7, color = 250, thick=2
   ;;   ENDIF
   ;;   nang = 256/nen 
   ;;   eindex = floor(pindex/(nang*4)) 
   ;;   dindex = pindex MOD (nang*4)
   ;;   IF keyword_set(plot) THEN print,eindex,dindex
   ;;   eindmin = eindex-nen/2
   ;;   
   ;;   ;; All of this complication is to make sure 
   ;;   ;; that we don't go off the edge of the table 
   ;;   ;; if the peak is near the edge.
   ;;   IF eindmin LT 0 THEN BEGIN 
   ;;      eindmin = 0    
   ;;      eindmax = nen-1
   ;;   ENDIF ELSE BEGIN
   ;;      eindmax = eindmin+nen-1
   ;;      IF eindmax GT (4*nen-1) THEN BEGIN
   ;;         eindmax = 4*nen-1
   ;;         eindmin = 3*nen
   ;;      ENDIF
   ;;   ENDELSE  
   ;;   dindmin = dindex-nang/2
   ;;   IF dindmin LT 0 THEN BEGIN
   ;;      dindmin = 0
   ;;      dindmax = nang-1
   ;;   ENDIF ELSE BEGIN
   ;;      dindmax = dindmin+nang-1
   ;;      IF dindmax GT (4*nang-1) THEN BEGIN
   ;;         dindmax = 4*nang-1
   ;;         dindmin = 3*nang
   ;;      ENDIF
   ;;   ENDELSE
   ;;   IF keyword_set(plot) THEN $
   ;;    print,eindmin, eindmax, dindmin, dindmax 
   ;;   IF (eindex MOD 2) THEN odd = 1 ELSE odd = 0
   ;;   tsindex = []
   ;;   FOR i = 0,nen-1 DO BEGIN
   ;;      sodd = (eindmin+i) MOD 2
   ;;      ;; Does the necessary flipping of 
   ;;      ;; every other step to take.
   ;;      IF odd EQ sodd THEN BEGIN 
   ;;         ;; Into account the up/down 
   ;;         ;; even/odd deflector sweeps
   ;;         di1 = dindmin      
   ;;      ENDIF ELSE BEGIN
   ;;         di1 = 4*nang-1-dindmax	
   ;;      ENDELSE
   ;;      tsindex = [tsindex,(eindmin+i)*nang*4+di1+indgen(nang)]
   ;;   ENDFOR
   ;;ENDIF   

   IF table.version EQ 1 THEN BEGIN 
      
      ;; Get center index of each sub-stepping
      edindex = table.fsindex[indgen(256)*4+2]
      ;; Interval for each E-D step in full sweep
      ;; This is the peak index into the 
      ;; master 4096-element S-LUT.
      pindex = edindex[edpeak]
      IF keyword_set(plot) THEN BEGIN
         ;;print,pindex
         plots,table.hem_v[pindex],$
               table.def1_v[pindex]-table.def2_v[pindex],$
               psym = 7, color = 250, thick=2
      ENDIF
      nang = 256/table.nen 
      eindex = floor(pindex/(nang*4)) 
      dindex = pindex MOD (nang*4)
      IF keyword_set(plot) THEN print,eindex,dindex
      eindmin = eindex-nen/2
      
      ;; All of this complication is to make sure 
      ;; that we don't go off the edge of the table 
      ;; if the peak is near the edge.
      IF eindmin LT 0 THEN BEGIN 
         eindmin = 0    
         eindmax = nen-1
      ENDIF ELSE BEGIN
         eindmax = eindmin+nen-1
         IF eindmax GT (4*nen-1) THEN BEGIN
            eindmax = 4*nen-1
            eindmin = 3*nen
         ENDIF
      ENDELSE  
      dindmin = dindex-nang/2
      IF dindmin LT 0 THEN BEGIN
         dindmin = 0
         dindmax = nang-1
      ENDIF ELSE BEGIN
         dindmax = dindmin+nang-1
         IF dindmax GT (4*nang-1) THEN BEGIN
            dindmax = 4*nang-1
            dindmin = 3*nang
         ENDIF
      ENDELSE
      IF keyword_set(plot) THEN $
       print,eindmin, eindmax, dindmin, dindmax 
      IF (eindex MOD 2) THEN odd = 1 ELSE odd = 0
      tsindex = []
      FOR i = 0,nen-1 DO BEGIN
         sodd = (eindmin+i) MOD 2
         ;; Does the necessary flipping of 
         ;; every other step to take.
         IF odd EQ sodd THEN BEGIN 
            ;; Into account the up/down 
            ;; even/odd deflector sweeps
            di1 = dindmin      
         ENDIF ELSE BEGIN
            di1 = 4*nang-1-dindmax	
         ENDELSE
         tsindex = [tsindex,(eindmin+i)*nang*4+di1+indgen(nang)]
      ENDFOR
   ENDIF   
   table.tsindex[edpeak,*] = tsindex
   
END





;; ----------------------------------------------
;; -------------- MAIN ----------------------- ;;
;; ----------------------------------------------
PRO spp_swp_spx_tables, table, $
                        get_slut  = get_slut, $
                        get_fslut = get_fslut,$
                        get_tslut = get_tslut


   ;; DAC Tables
   ;;slut  = intarr(4096)
   ;;fslut = intarr(256)
   ;;tslut = intarr(256,256)

   ;; Default Table Parameters
   ;;max     = 65535
   ;;k       = 16.7
   ;;rmax    = 11.0
   ;;vmax    = 4000
   ;;nen     = 128
   ;;e0      = 100.
   ;;emax    = 10000.
   ;;spfac   = 0.
   ;;maxspen = 5000.
   ;;hvgain  = 1000.
   ;;spgain  = 20.12
   ;;fixgain = 13.
   ;;edmask  = []
   
   ;; Default Version
   ;;IF ~keyword_set(version) THEN version = 2
   ;;print, 'Version: '+string(version)
   ;;print, 'Version: '+string(table.version)

   ;; --------- Get SLUT ---------
   IF keyword_set(get_slut) THEN $
    ;;spp_swp_spx_get_slut,sweep,def1,def2,spl,$
    ;;                     version=version,$
    ;;                     k=k,rmax=rmax,$
    ;;                     vmax=vmax,nen=nen,$
    ;;                     e0=e0,emax=emax,$
    ;;                     spfac=spfac,$
    ;;                     maxspen=maxspen,$
    ;;                     hvgain=hvgain,$
    ;;                     spgain=spgain,$
    ;;                     fixgain=fixgain
   spp_swp_spx_get_slut, table
   

   ;; --------- Get FSLUT ---------
   IF keyword_set(get_slut) THEN $
    ;;spp_swp_spx_get_fslut,fsindex,$
    ;;                      version=version,$
    ;;                      k=k,rmax=rmax,$
    ;;                      vmax=vmax,nen=nen,$
    ;;                      e0=e0,emax=emax,$
    ;;                      spfac=spfac,$
    ;;                      maxspen=maxspen,$
    ;;                      hvgain=hvgain,$
    ;;                      spgain=spgain,$
    ;;                      fixgain=fixgain
    spp_swp_spx_get_fslut, table


   ;; --------- Get TSLUT ---------
   IF keyword_set(get_slut) THEN BEGIN
      FOR edpeak=0, 255 DO BEGIN 
         ;;spp_swp_spx_get_tslut,tsindex,$
         ;;                      fsindex,$
         ;;                      version=version,$
         ;;                      edpeak=edpeak,$
         ;;                      k=k,rmax=rmax,$
         ;;                      vmax=vmax,nen=nen,$
         ;;                      e0=e0,emax=emax,$
         ;;                      spfac=spfac,$
         ;;                      maxspen=maxspen,$
         ;;                      hvgain=hvgain,$
         ;;                      spgain=spgain,$
         ;;                      fixgain=fixgain
         spp_swp_spx_get_tslut, table, edpeak

         ;;tslut[edpeak,*] = temporary(tsindex)

      ENDFOR
   ENDIF

END 
