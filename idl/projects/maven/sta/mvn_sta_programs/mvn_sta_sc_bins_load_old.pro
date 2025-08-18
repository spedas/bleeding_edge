;+
; :Name:
;    Roberto Livi
;
; :Program:
;    MVN_STA_SC_BINS_LOAD
;
; :Syntax:
;    IDL> mvn_sta_sc_bins_load, /test_plot1, /test_plot2
;
; :Purpose:
;    Fill MAVEN STATIC common block data with FOV
;    obstruction by the spacecraft.
;
; :Params:
;    perc_block: Set this number to the desired percentage
;                of covered area before marking a bin as
;                blocked.
;
; :Returns:
;    None.
;
; :Keywords:
;    test_plot1: Plots for debugging.
;    test_plot2: More plots for debugging.
;    ssave: Save file for intermediary debugging.
;    rrestore: Restore file for intermediary debugging.
;    verbose: Print out processing status.
;
; :Version:
;
;   $LastChangedBy: jimm $
;   $LastChangedDate: 2020-12-17 09:53:34 -0800 (Thu, 17 Dec 2020) $
;   $LastChangedRevision: 29540 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_programs/mvn_sta_sc_bins_load_old.pro $
;-



;; Taken from Coyote Progrmming Library
FUNCTION sc_bins_load_hist_nd,V,bs,MIN=mn,MAX=mx,$
                              NBINS=nbins,$
                              REVERSE_INDICES=ri

   s=size(V,/DIMENSIONS)
   if n_elements(s) ne 2 then message,$
    'Input must be N (dimensions) x P (points)'
   if s[0] gt 8 then message, 'Only up to 8 dimensions allowed'
   imx=max(V,DIMENSION=2,MIN=imn)
   if n_elements(mx) eq 0 then mx=imx
   if n_elements(mn) eq 0 then mn=imn
   if s[0] gt 1 then begin
      if n_elements(mn)    eq 1 then mn=replicate(mn,s[0])
      if n_elements(mx)    eq 1 then mx=replicate(mx,s[0])
      if n_elements(bs)    eq 1 then bs=replicate(bs,s[0])
      if n_elements(nbins) eq 1 then nbins=replicate(nbins,s[0])
   endif else begin
      mn=[mn] & mx=[mx]
   endelse

   if ~array_equal(mn le mx,1b) then $
    message,'Min must be less than or equal to max.'

   if n_elements(bs) eq 0 then begin
      if n_elements(nbins) ne 0 then begin
         nbins=long(nbins)      ;No fractional bins, please
         bs=float(mx-mn)/nbins  ;a correct formulation
      endif else message,'Must pass either binsize or NBINS'
   endif else nbins=long((mx-mn)/bs+1)
   total_bins=product(nbins,/PRESERVE_TYPE) ;Total number of bins
   h=long((V[s[0]-1,*]-mn[s[0]-1])/bs[s[0]-1])
   
   ;; The scaled indices, s[n]+N[n-1]*(s[n-1]+N[n-2]*(s[n-2]+...
   for i=s[0]-2,0,-1 do h=nbins[i]*temporary(h) + long((V[i,*]-mn[i])/bs[i])

   out_of_range=[~array_equal(mn le imn,1b),~array_equal(mx ge imx,1b)]
   if ~array_equal(out_of_range,0b) then begin
      in_range=1
      if out_of_range[0] then $ ;out of range low
       in_range=total(V ge rebin(mn,s,/SAMP),1,/PRESERVE_TYPE) eq s[0]
      if out_of_range[1] then $ ;out of range high
       in_range AND= total(V le rebin(mx,s,/SAMP),1,/PRESERVE_TYPE) eq s[0]
      h=(temporary(h) + 1L)*temporary(in_range) - 1L
   endif

   ret=make_array(TYPE=3,DIMENSION=nbins,/NOZERO)
   if arg_present(ri) then $
    ret[0]=histogram(h,MIN=0L,MAX=total_bins-1L,REVERSE_INDICES=ri) $
   else $
    ret[0]=histogram(h,MIN=0L,MAX=total_bins-1L)
   return, ret
END





FUNCTION mvn_sta_sc_bins_inside, x, y, px, py, Index=index
;+
; Inside - Take the dot and cross product of point an nearby vertices
;          to determine whether the point is inside or outisde of box
;-
   
   
   on_Error, 1
   sx = Size(px)
   sy = Size(py)
   IF (sx[0] EQ 1) THEN NX = sx[1] ELSE stop,'Variable px is not a vector'
   IF (sy[0] EQ 1) THEN NY = sy[1] ELSE stop,'Varialbe py is not a vector'
   IF (NX EQ NY)   THEN N = NX     ELSE stop,'Incompatible vector dimensions'
   i  = indgen(n,/Long)           ;; indices 0...N-1
   ip = indgen(n,/Long) + 1       ;; indices 1...N
   nn = n_elements(x) 
   X1 = px[i]  # replicate(1,nn) - replicate(1,n) # reform([x],nn)
   Y1 = py[i]  # replicate(1,nn) - replicate(1,n) # reform([y],nn)
   X2 = px[ip] # replicate(1,nn) - replicate(1,n) # reform([x],nn)
   Y2 = py[ip] # replicate(1,nn) - replicate(1,n) # reform([y],nn)
   dp = x2*x1 + y1*y2              ;; Dot-product
   cp = x1*y2 - y1*x2              ;; Cross-product
   theta = atan(cp,dp)
   ret = replicate(0L, n_elements(x))
   i = where(abs(total(theta,1)) gt 0.01,count)
   IF (count GT 0) THEN ret[i]=1
   IF (n_elements(ret) eq 1) then ret=ret[0]
   IF (keyword_set(index)) THEN $
    ret=(indgen(/long, n_elements(x)))(where(ret eq 1))
   return, ret
   
END

FUNCTION mvn_sta_sc_bins_histt, map, orig_time, dat, $
                                phi_sc, theta_sc, xx, yy, $
                                perc_block=perc_block, $
                                test_plot2=test_plot2

   ;; Setup APID varibales
   ndef      = dat.ndef 
   nanode    = dat.nanode
   nswp      = dat.swp_ind
   nnbins    = dat.nbins 
   nenergy   = dat.nenergy
   theta     = reform(dat.theta[nswp,nenergy-1,*])
   ntime     = n_elements(dat.time)
   bins_sc   = intarr(ntime,nanode,ndef)
   bins_sc_temp = fltarr(ntime,nanode,ndef)
   
   ;; Interpolate map with new time intervals
   ttime   = (dat.end_time-dat.time)/2.+dat.time 
   nmap    = n_elements(map[0,*])
   new_map = intarr(ntime,nmap)
   FOR i=0, nmap-1 DO new_map[*,i] = $
    ceil(interpol(map[*,i], orig_time, ttime))
   
   ;; Cycle through all time intervals
   FOR i=0, ntime-1 DO BEGIN
      
      ;; To speed things up:
      ;; If the map is the same as in the
      ;; previous interval then skip
      IF i NE 0 THEN $
       IF total((new_map[i-1,*]-new_map[i,*]) > 0) EQ 0 THEN BEGIN
         bins_sc_temp[i,*,*] = bins_sc_temp[i-1,*,*]
         GOTO, skipp
      ENDIF

      ;; 0 - Clear
      ;; 1 - Obstructed
      pp   = where(new_map[i,*] eq 1,ccc)
      if ccc eq 0 then goto, skipp

      ;; orig_data - all points
      ;; data      - obstructed points
      orig_data = transpose([[xx], [yy]])
      data = transpose([[xx[pp]], [yy[pp]]])
      
      ;; -------- Setup bins ----------

      ;; Only Deflectors (Summed Anode)
      if ndef GT 1 AND nanode EQ 1 THEN BEGIN
         ntheta = abs(theta[i,1]-theta[i,0])
         minn  = [-180.0, min(theta[i,*]) - ntheta/2.]
         maxx  = [ 180.0, max(theta[i,*]) + ntheta/2.]
         bins  = [ 360.0, abs(theta[i,1]-theta[i,0])]
         nbins = [nanode+1,ndef]
      endif

      ;; Only Anodes (Summed Deflectors)
      IF ndef EQ 1 AND nanode GT 1 THEN BEGIN
         minn  = [-180.0-22.5,-90.0]
         maxx  = [ 180.0, 90.0]
         bins  = [  22.5,180.0]
         nbins = [nanode+1,ndef]
      endif

      ;; Deflectors and Anodes
      IF ndef GT 1 AND nanode GT 1 THEN BEGIN
         ntheta = abs(theta[i,1]-theta[i,0])
         minn  = [-180.0-22.5, min(theta[i,*]) - ntheta/2.]
         maxx  = [ 180.0, max(theta[i,*]) + ntheta/2.]
         bins  = [  22.5, ntheta]
         nbins = [nanode+1,ndef]
      ENDIF 

      ;; orig_ff - Binned map of all points
      ;; ff      - Binned map of all obstructed points 
      offset = 22.5/2.
      minn = minn + [offset, 0.]
      maxx = maxx + [offset, 0.]
      orig_ff = sc_bins_load_hist_nd($
                orig_data, nbins=nbins,$
                min=minn, max=maxx,$
                reverse_indices=ri1)
      ff = sc_bins_load_hist_nd($
           data, nbins=nbins,$
           min=minn, max=maxx,$
           reverse_indices=ri2)

      ;; Ratio between obstructed and non-obstructed
      ;; points within a given bin.
      bins_sc_temp[i,*,*] = $
       float(ff[1:nanode,0:ndef-1]) / $
       float(orig_ff[1:nanode,0:ndef-1])

      ;; Skipped if qrot_test is small
      skipp:
      
      ;; Test Plot
      IF keyword_set(test_plot2) AND $
       ttime[i] GT 1522588800 THEN BEGIN 

         ind = nn(orig_time,ttime[i])
         objs = indgen(11)

         ;; Plot spacecraft
         plot, phi_sc[ind,*,objs], theta_sc[ind,*,objs], $
               xrange=[-180,180], $
               yrange=[-90,90], $
               xstyle=1, $
               ystyle=1, $
               /nodata,$
               title=dat.data_name+' - '+time_string(orig_time[ind])

         ;; Polyfill blocked sectors
         nano1 = ((maxx-minn)/bins)[0]-1
         ndef1 = ((maxx-minn)/bins)[1]

         ;; Blocked bins array
         bb = reform(bins_sc_temp[i,*,*])

         ;; Cycle through deflector bins
         FOR idef=0,ndef1-1 DO BEGIN

            ;; Cycle through anodes bins
            FOR iano=0,nano1-1 DO BEGIN

               bbb = bb[idef*nano1+iano]
               tmpx = minn[0]+bins[0]*iano
               tmpy = minn[1]+bins[1]*idef
               xxx  = [tmpx,tmpx,tmpx+bins[0],tmpx+bins[0],tmpx]
               yyy  = [tmpy,tmpy+bins[1],tmpy+bins[1],tmpy,tmpy]

               ;; Plot obscured blocks
               IF bbb GT perc_block THEN polyfill, xxx, yyy, color=50

            ENDFOR
         ENDFOR 

         ;; Plot spacecraft
         oplot, phi_sc[ind,*,objs], theta_sc[ind,*,objs]
               
         ;; Plot obscured points
         oplot, xx[pp], yy[pp], psym=1, color=250

         ;; Plot Anode and Deflector maps
         FOR j=0, ndef DO oplot, [-180,180], replicate(minn[1]+ntheta*j,2)
         IF nanode NE 1 THEN FOR j=0, nanode DO $
          oplot, replicate(minn[0]+22.5*j,2),$
                 [min(theta[i,*])-ntheta/2.,max(theta[i,*])+ntheta/2.]

         wait, 0.01
      ENDIF      
   ENDFOR 

   ;; Rearrange bins to match STATIC bins
   IF nanode GT 1 AND ndef GT 1 THEN BEGIN
      ss = size(bins_sc_temp)
      ;; Reverse order of deflector
      bins_sc_temp = reverse(bins_sc_temp,3)
   ENDIF
   IF nanode EQ 1 THEN BEGIN
      ss = size(bins_sc_temp)
      ;; Reverse order of deflector
      bins_sc_temp = reverse(bins_sc_temp,3)
   ENDIF
   
   ;; Fill bins_sc bitmap
   
   ;; 0 - Blocked
   pp  = where(bins_sc_temp gt perc_block,cc)
   IF cc  GT 0 THEN bins_sc[pp]  = 0

   ;; 1 - Not Blocked
   ppn = where(bins_sc_temp le perc_block,ccn)
   IF ccn GT 0 THEN bins_sc[ppn] = 1
   
   ;; Reform to match common block array
   bins_sc = reform(transpose(bins_sc,[0,2,1]),ntime,ndef*nanode)

   return, reform(bins_sc)
   
END 







PRO mvn_sta_sc_bins_load_old, perc_block = perc_block,$
                              test_plot1 = test_plot1,$
                              test_plot2 = test_plot2,$
                              ssave      = ssave,$
                              rrestore   = rrestore,$
                              verbose    = verbose

;+
;#################################################
;                Main Function
;#################################################
;-
   
   
   ;; Get time interval
   trange = timerange()
   
   ;; Default block percentage is set to 50%
   if ~keyword_set(perc_block) then perc_block=0.5

   ;; Restore intermediary file for debugging
   IF keyword_set(rrestore) THEN GOTO, skip3

   ;; Common Blocks
   COMMON mvn_spc_vertices, inst
   COMMON mvn_sta_fov_block, $
    mvn_sta_fov_block_time,  $
    mvn_sta_fov_block_qrot1, $
    mvn_sta_fov_block_qrot2, $
    mvn_sta_fov_block_qrot3, $
    mvn_sta_fov_block_qrot4, $
    mvn_sta_fov_block_qrot5, $
    mvn_sta_fov_block_matrix
   COMMON mvn_c0,mvn_c0_ind,mvn_c0_dat
   COMMON mvn_c8,mvn_c8_ind,mvn_c8_dat ;16D       4s  Ram Conic
   COMMON mvn_ca,mvn_ca_ind,mvn_ca_dat ;4Dx16A    4s  Ram Conic
   COMMON mvn_cc,mvn_cc_ind,mvn_cc_dat ;8D       32s  Ram
   COMMON mvn_cd,mvn_cd_ind,mvn_cd_dat ;8D        4s  Ram
   COMMON mvn_ce,mvn_ce_ind,mvn_ce_dat ;4Dx16A   32s  Conic
   COMMON mvn_cf,mvn_cf_ind,mvn_cf_dat ;4Dx16A    4s  Conic
   COMMON mvn_d0,mvn_d0_ind,mvn_d0_dat ;4Dx16A  128s  Pickup
   COMMON mvn_d1,mvn_d1_ind,mvn_d1_dat ;4Dx16A   16s  Pickup
   COMMON mvn_d4,mvn_d4_ind,mvn_d4_dat ;4Dx16A    4s  Pickup

   ;; Check if time exists
   IF n_elements(mvn_c0_dat.time) EQ 0 THEN BEGIN
      print, 'ERROR: STATIC data needs to be loaded first.'
      return
   ENDIF

   ;; Generate spacecraft blockage data
   mvn_spc_fov_blockage, trange=mean(mvn_c0_dat.time),$
                         /invert_phi,  $
                         /invert_theta,$
                         theta = theta, phi=phi,$
                         /static, /noplot

   ;; APID Names
   apid=['c0','c6','c8',$
         'ca','cc','cd','ce','cf',$
         'd0','d1','d4']
   nn_apid=n_elements(apid)

   ;; General Info
   print, 'Blocked Bins - Generate block map '+$
          'using APID C0 times (~1 minute)'

   ;; Use APID C0 time intervals
   time = (mvn_c0_dat.end_time-mvn_c0_dat.time) / 2 + mvn_c0_dat.time
   nn1 = n_elements(time)

   ;; Spacecraft coordinate dimensions
   nn2 = (size(inst.x_sc_res))[1]
   nn3 = (size(inst.x_sc_res))[2]

   ;; Vertex array dimensions
   n1=3
   n2=8
   n3=n_elements(inst.vertex)/n1/n2

   ;; Create 2D grid
   ;; -180 - phi   - 180
   ;;  -90 - theta -  90
   ;; nnnx - Anode bin size in degrees
   ;; nnny - Deflector bin size in degrees
   ;; xx   - Rebin phi and collapse to 1D
   ;; yy   - Rebin theta and collapse to 1D
   nnnx = 22.5/5.
   nnny = 3.
   tmpx = round(360./nnnx)
   tmpy = round(180./nnny)
   phi_map   = indgen(tmpx)*nnnx - 180
   theta_map = indgen(tmpy)*nnny -  90
   xx = reform(          rebin(phi_map,  tmpx,tmpy) ,tmpx*tmpy)
   yy = reform(transpose(rebin(theta_map,tmpy,tmpx)),tmpx*tmpy)

   ;; Map that marks obstructed
   ;; coordinates
   final_map = intarr(nn1,tmpx*tmpy)

   ;; Spacecraft coordinate array
   phi_sc   = fltarr(nn1,nn3,nn2)
   theta_sc = fltarr(nn1,nn3,nn2)

   ;; Cycle through all times and fill in map
   FOR iddx=1, nn1-1 DO BEGIN

      ;; Quick kluge
      idx=iddx-1

      ;; Check if qrot changed. If it is the same as
      ;; before we do not need to recalculate map
      qrot_test = total(abs(mvn_sta_fov_block_qrot3[*,iddx]-$
                            mvn_sta_fov_block_qrot3[*,iddx-1])) + $
                  total(abs(mvn_sta_fov_block_qrot4[*,iddx]-$
                            mvn_sta_fov_block_qrot4[*,iddx-1]))

      IF qrot_test GT 1e-4 OR idx EQ 0 THEN BEGIN

         ;; Record time
         t1 = systime(1)

         ;; Generate blockage data
         mvn_spc_fov_blockage, trange=mvn_sta_fov_block_time[iddx],$
                               /invert_phi,  $
                               /invert_theta,$
                               theta=theta, phi=phi,   $
                               /static, /noplot

         ;; Store phi/theta values
         phi_sc[idx,*,*]   = phi
         theta_sc[idx,*,*] = theta
         nnphi = n_elements(phi[*,0])
         phitmp1      = phi
         
         ;; Only check within limits
         xxyy_pp = where(xx le max(phi)   and xx ge min(phi) and $
                         yy le max(theta) and yy ge min(theta))
         xtmp1 = xx[xxyy_pp]
         ytmp1 = yy[xxyy_pp]
         
         ;; Record time
         t2 = systime(1)     

         ;; Counter
         jj = 0

         ;; Cycle through all objects ... 
         FOR i=0, n3-1 DO BEGIN

            ;; ... unless related to  APP
            IF (i NE 11) AND $
             (i NE 12) AND $
             (i NE 13) AND $
             (i NE 14) THEN BEGIN
               
               ;; Find boundary conditions/crossings between 180 and -180            
               IF max(ABS(phi[1:nnphi-1,i]-phi[0:nnphi-2-2,i])) GE 180 THEN BEGIN
                  ptmp1 = where(xtmp1 LE 0,count) 
                  IF count GT 0 THEN xtmp1[ptmp1] = xtmp1[ptmp1] + 360.
                  ptmp1 = where(phi[*,i] LE 0,count) 
                  IF count GT 0 THEN phitmp1[ptmp1,i] = phi[ptmp1,i] + 360.  
               ENDIF ELSE BEGIN
                  xtmp1 = xx[xxyy_pp]
                  phitmp1 = phi
               ENDELSE 

               ;; Loop through six sides of object
               FOR j=0, (30-1)*inst.prec, 4*inst.prec+inst.prec DO BEGIN


                  ;; Result gives points within xtmp1 and ytmp1
                  res_ins = mvn_sta_sc_bins_inside($
                            xtmp1,$
                            ytmp1,$
                            phitmp1[j:j+4*inst.prec,i],$
                            theta[j:j+4*inst.prec,i])

                  ;; 0 - Outside, i.e. clear
                  ;; 1 - Inside, i.e. blocked/obscured
                  pp   = where(res_ins EQ 1,cc)

                  ;; If points were found then add them to map
                  IF cc NE 0 THEN final_map[idx,xxyy_pp[pp]] = 1

                  ;; Plot for debugging
                  IF 0 THEN BEGIN
                     plot, xtmp1, ytmp1, psym=1 ,xs=1,ys=1,$
                           xr=[-180,360],yr=[-90,90]
                     arr = where(final_map[idx,*] EQ 1,acc)
                     IF acc GT 1 THEN $
                      oplot, xx[arr], yy[arr], psym=1, color=250
                     oplot, phi[j:j+4*inst.prec,i],$
                            theta[j:j+4*inst.prec,i],color=250
                  ENDIF

               ENDFOR

            ENDIF

         ENDFOR

         ;; Record time
         t3 = systime(1)

         ;; Print debug information
         IF keyword_set(verbose) THEN $
          print, nn1, idx, '   ', t2-t1,$
                 '   ', t3-t2, qrot_test

         ;; Plot spacecraft for debugging
         IF keyword_set(test_plot1) THEN BEGIN 
            pp=where(final_map[idx,*] eq 1,cc)
            plot, phi, theta, xr=[-180,180], yr=[-90,90], $
                  xs=1, ys=1,/nodata,$
                  title=time_string(mvn_sta_fov_block_time[iddx])
            FOR ii=0, inst.nn3-1 DO BEGIN
               IF (ii NE 11) AND (ii NE 12) AND $
                (ii NE 13) AND (ii NE 14) THEN BEGIN 
                  FOR j=0, (30-1)*inst.prec, 4*inst.prec+inst.prec DO BEGIN
                     oplot, phi[j:j+4*inst.prec,ii],$
                            theta[j:j+4*inst.prec,ii]
                     IF cc GT 1 THEN $
                      oplot, xx[pp], yy[pp], psym=1, color=250
                     oplot, xx, yy, psym=3
                  ENDFOR
               ENDIF 
            ENDFOR
         ENDIF
         
      ENDIF ELSE BEGIN

         ;; Store previous result
         phi_sc[idx,*,*]   = phi
         theta_sc[idx,*,*] = theta
         final_map[idx,*]  = final_map[idx-1,*]

      ENDELSE

   ENDFOR



   ;; ------------- Bin data for all APIDs -------------------

   ;; Save intermediary file for debugging
   IF keyword_set(ssave) THEN $
    save,filename='~/Desktop/final_map.sav', final_map, $
         mvn_c0_dat, phi_sc, theta_sc, time, xx, yy

   ;; Restore intermediary file for debugging
   IF keyword_set(rrestore) THEN BEGIN 
      skip3:
      restore, filename='~/Desktop/final_map.sav'
   ENDIF 

   map  = final_map
   time = (mvn_c0_dat.end_time-mvn_c0_dat.time)/2 + $
          mvn_c0_dat.time
   final_map = 0

   ;;---------------------------
   ;; C8 - 16D     4s  Ram Conic
   print, 'Blocked Bins - Interpolate for APID-C8'
   ss = size(mvn_c8_dat)
   if ss[2] eq 8 then $
    mvn_c8_dat.bins_sc = $
    mvn_sta_sc_bins_histt(map,time,mvn_c8_dat,phi_sc,theta_sc,$
                          xx,yy,perc_block=perc_block,$
                          test_plot2=test_plot2)
   ;;---------------------------
   ;; CA    4s  Ram Conic
   print, 'Blocked Bins - Interpolate for APID-CA'
   ss = size(mvn_ca_dat)
   if ss[2] eq 8 then $
    mvn_ca_dat.bins_sc = $
    mvn_sta_sc_bins_histt(map,time,mvn_ca_dat,phi_sc,theta_sc,$
                          xx,yy,perc_block=perc_block,$
                          test_plot2=test_plot2)
   ;;---------------------------
   ;; CC - 8D       32s  Ram
   print, 'Blocked Bins - Interpolate for APID-CC'
   ss = size(mvn_cc_dat)
   if ss[2] eq 8 then $
    mvn_cc_dat.bins_sc = $
    mvn_sta_sc_bins_histt(map,time,mvn_cc_dat,phi_sc,theta_sc,$
                          xx,yy,perc_block=perc_block,$
                          test_plot2=test_plot2)
   ;;---------------------------
   ;; CD - 8D        4s  Ram
   print, 'Blocked Bins - Interpolate for APID-CD'
   ss = size(mvn_cd_dat)
   if ss[2] eq 8 then $
    mvn_cd_dat.bins_sc = $
    mvn_sta_sc_bins_histt(map,time,mvn_cd_dat,phi_sc,theta_sc,$
                          xx,yy,perc_block=perc_block,$
                          test_plot2=test_plot2)
   ;;---------------------------
   ;; CE - 4Dx16A   32s  Conic
   print, 'Blocked Bins - Interpolate for APID-CE'
   ss = size(mvn_ce_dat)
   if ss[2] eq 8 then $
    mvn_ce_dat.bins_sc = $
    mvn_sta_sc_bins_histt(map,time,mvn_ce_dat,phi_sc,theta_sc,$
                          xx,yy,perc_block=perc_block,$
                          test_plot2=test_plot2)
   ;;---------------------------
   ;; CF - 4Dx16A    4s  Conic
   print, 'Blocked Bins - Interpolate for APID-CF'
   ss = size(mvn_cf_dat)
   if ss[2] eq 8 then $
    mvn_cf_dat.bins_sc = $
    mvn_sta_sc_bins_histt(map,time,mvn_cf_dat,phi_sc,theta_sc,$
                          xx,yy,perc_block=perc_block,$
                          test_plot2=test_plot2)

   ;;---------------------------
   ;; D0 - 4Dx16A  128s  Pickup
   print, 'Blocked Bins - Interpolate for APID-D0'
   ss = size(mvn_d0_dat)
   if ss[2] eq 8 then $
    mvn_d0_dat.bins_sc = $
    mvn_sta_sc_bins_histt(map,time,mvn_d0_dat,phi_sc,theta_sc,$
                          xx,yy,perc_block=perc_block,$
                          test_plot2=test_plot2)
   ;;---------------------------
   ;; D1 - 4Dx16A   16s  Pickup
   print, 'Blocked Bins - Interpolate for APID-D1'
   ss = size(mvn_d1_dat)
   if ss[2] eq 8 then $
    mvn_d1_dat.bins_sc = $
    mvn_sta_sc_bins_histt(map,time,mvn_d1_dat,phi_sc,theta_sc,$
                          xx,yy,perc_block=perc_block,$
                          test_plot2=test_plot2)
   ;;---------------------------
   ;; D4 - 4Dx16A    4s  Pickup
   print, 'Blocked Bins - Interpolate for APID-D4'
   ss = size(mvn_d4_dat)
   if ss[2] eq 8 then $
    mvn_d4_dat.bins_sc = $
    mvn_sta_sc_bins_histt(map,time,mvn_d4_dat,phi_sc,theta_sc,$
                          xx,yy,perc_block=perc_block,$
                          test_plot2=test_plot2)

END 
