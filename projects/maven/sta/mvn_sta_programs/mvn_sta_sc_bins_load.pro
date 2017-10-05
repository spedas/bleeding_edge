;;##########################################################################
;; Taken from Coyote Progrmming Library

function sc_bins_load_hist_nd,V,bs,MIN=mn,MAX=mx,NBINS=nbins,REVERSE_INDICES=ri
  s=size(V,/DIMENSIONS)
  if n_elements(s) ne 2 then message,'Input must be N (dimensions) x P (points)'
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
        nbins=long(nbins)       ;No fractional bins, please
        bs=float(mx-mn)/nbins   ;a correct formulation
     endif else message,'Must pass either binsize or NBINS'
  endif else nbins=long((mx-mn)/bs+1)

  total_bins=product(nbins,/PRESERVE_TYPE) ;Total number of bins
  h=long((V[s[0]-1,*]-mn[s[0]-1])/bs[s[0]-1])
  
  ;; The scaled indices, s[n]+N[n-1]*(s[n-1]+N[n-2]*(s[n-2]+...
  for i=s[0]-2,0,-1 do h=nbins[i]*temporary(h) + long((V[i,*]-mn[i])/bs[i])

  out_of_range=[~array_equal(mn le imn,1b),~array_equal(mx ge imx,1b)]
  if ~array_equal(out_of_range,0b) then begin
     in_range=1
     if out_of_range[0] then $  ;out of range low
        in_range=total(V ge rebin(mn,s,/SAMP),1,/PRESERVE_TYPE) eq s[0]
     if out_of_range[1] then $  ;out of range high
        in_range AND= total(V le rebin(mx,s,/SAMP),1,/PRESERVE_TYPE) eq s[0]
     h=(temporary(h) + 1L)*temporary(in_range) - 1L
  endif

  ret=make_array(TYPE=3,DIMENSION=nbins,/NOZERO)
  if arg_present(ri) then $
     ret[0]=histogram(h,MIN=0L,MAX=total_bins-1L,REVERSE_INDICES=ri) $
  else $
     ret[0]=histogram(h,MIN=0L,MAX=total_bins-1L)
  return,ret
end



;;##########################################################################
;; Inside-> Take the dot and cross product of point an nearby vertices
;;          to determine whether the point is inside or outisde of box

function inside, x, y, px, py, Index=index

  on_Error, 1
  
  sx = Size(px)
  sy = Size(py)
  if (sx[0] EQ 1) then NX = sx[1] else stop,'Variable px is not a vector'
  if (sy[0] EQ 1) then NY = sy[1] else stop,'Varialbe py is not a vector'
  if (NX EQ NY)   then N = NX     else stop,'Incompatible vector dimensions'
  
  i  = indgen(n,/Long)           ;; indices 0...N-1
  ip = indgen(n,/Long) + 1       ;; indices 1...N
  
  nn = n_elements(x) 
  X1 = px(i)  # replicate(1,nn) - replicate(1,n) # reform([x],nn)
  Y1 = py(i)  # replicate(1,nn) - replicate(1,n) # reform([y],nn)
  X2 = px(ip) # replicate(1,nn) - replicate(1,n) # reform([x],nn)
  Y2 = py(ip) # replicate(1,nn) - replicate(1,n) # reform([y],nn)
  
  dp = x2*x1 + y1*y2              ;; Dot-product
  cp = x1*y2 - y1*x2              ;; Cross-product
  theta = atan(cp,dp)
  
  ret = replicate(0L, n_elements(x))
  i = where(abs(total(theta,1)) gt 0.01,count)
  if (count gt 0) then ret(i)=1
  if (n_elements(ret) eq 1) then ret=ret[0]
  
  if (keyword_set(index)) then $
     ret=(indgen(/long, n_elements(x)))(where(ret eq 1))
  
  return, ret
  
end









;;##########################################################################
;; histt

function histt, map, orig_time, dat, phi_sc, theta_sc, xx, yy, perc_block=perc_block, test_plot=test_plot


  ;;-------------------------------
  ;; Setup APID varibales
  ndef      = dat.ndef 
  nanode    = dat.nanode
  nswp      = dat.swp_ind
  nbins     = dat.nbins 
  nenergy   = dat.nenergy
  theta     = reform(dat.theta[nswp,nenergy-1,*])
  ntime     = n_elements(dat.time)
  bins_sc   = intarr(ntime,nanode+1,ndef)
  bins_sc_temp = fltarr(ntime,nanode+1,ndef)
  
  ;;-------------------------------
  ;; Interpolate map for new times
  nmap    = n_elements(map[0,*])
  new_map = intarr(ntime,nmap)
  ttime =   (dat.end_time-dat.time) / 2. + dat.time 


  for i=0, nmap-1 do new_map[*,i] = ceil(interpol(map[*,i], orig_time, ttime))



  ;;-------------------------------
  ;; Cycle through all times
  for i=0, ntime-1 do begin

     ;;-------------------------------
     ;; To speed things up:
     ;; If the map is the same as in the
     ;; previous interval then skip
     if i ne 0 then if total((new_map[i-1,*]-new_map[i,*]) > 0) eq 0 then begin
        bins_sc_temp[i,*,*] = bins_sc_temp[i-1,*,*]
        goto, skipp
     endif
     
     pp   = where(new_map[i,*] eq 1,ccc)
     if ccc eq 0 then goto, skipp
     orig_data = transpose([[xx], [yy]])
     data = transpose([[xx[pp]], [yy[pp]]])
     
     ;;-------------------------------
     ;; Setup bins
     ;;
     ;; Only deflectors
     if nanode eq 1 then begin
        theta = reform(dat.theta[nswp,nenergy-1,*])
        ntheta = abs(theta[0,1]-theta[0,0])
        minn  = [-180.0, min(theta[i,*])-ntheta/2.]
        maxx  = [ 180.0, max(theta[i,*])+ntheta/2.]
        bins  = [ 360.0, abs(theta[i,1]-theta[i,0])]
     endif
     ;; Only Anodes
     if nbins eq 1 then begin
        minn = [-180.0 - 22.5/2.,-90.0]
        maxx = [ 180.0 + 22.5/2., 90.0]
        bins = [  22.5,180.0]
     endif
     ;; Deflectors and anodes
     if nbins gt 1 and nanode gt 1 then begin
        theta = reform(dat.theta[nswp,nenergy-1,*])
        ntheta = abs(theta[0,1]-theta[0,0])
        minn = [-180.0 - 22.5/2., min(theta) - ntheta/2.]
        maxx = [ 180.0 + 22.5/2., max(theta) + ntheta/2.] 
        bins = [  22.5, ntheta]
     endif

     orig_ff = sc_bins_load_hist_nd(orig_data,bins,min=minn, max=maxx)
     ff      = sc_bins_load_hist_nd(data,     bins,min=minn, max=maxx)
     bins_sc_temp[i,*,*] = float(ff[0:nanode,0:ndef-1]) / $
                           float(orig_ff[0:nanode,0:ndef-1])

     ;;---------------------------------------
     ;; Test Plot
     if keyword_set(test_plot) then begin
        ind = nn(orig_time,ttime[i])
        plot, phi_sc[ind,*,*], theta_sc[ind,*,*], $
              xrange=[-180,180], $
              yrange=[-90,90], $
              xstyle=1, $
              ystyle=1
        oplot, xx[pp], yy[pp], psym=1, color=250
        for j=0, ndef do oplot, [-180,180], replicate(minn[1]+ntheta*j,2)
        if nanode ne 1 then for j=0, nanode do $
           oplot, replicate(minn[0]+22.5*j,2),$
                  [min(theta[i,*]-ntheta/2.),max(theta[i,*]+ntheta/2.)]

        ;;--------------
        ;; Test some more

        bb = bins_sc_temp[i,*,*]
        bb = reform(transpose(bb,[0,2,1])) 
        bb = reverse(bb,1)
        wait, 0.05
     endif
     skipp:
  endfor

  ;;--------------------------------------
  ;; Rearrange bins to match STATIC bins
  if nanode gt 1 and ndef gt 1 then begin
     ss = size(bins_sc_temp)
     ;; Reverse order of deflector
     bins_sc_temp = reverse(bins_sc_temp,3)
     ;; Shift anodes down one unit to center
     temp_arr = bins_sc_temp[*,0,*] + bins_sc_temp[*,ss[2]-2,*]
     bins_sc_temp[*,0:ss[2]-3,*] = bins_sc_temp[*,1:ss[2]-2,*] 
     bins_sc_temp[*,ss[2]-2,*] = temp_arr
  endif
  if nanode eq 1 then begin
     ss = size(bins_sc_temp)
     ;; Reverse order of deflector
     bins_sc_temp = reverse(bins_sc_temp,3)
  endif

  ;;--------------------------------------
  ;; Mark only FOV with percentage blocked
  pp  = where(bins_sc_temp gt perc_block,cc)
  ppn = where(bins_sc_temp le perc_block,ccn)
  if cc  ne 0 then bins_sc[pp]  = 0
  if ccn ne 0 then bins_sc[ppn] = 1

  bins_sc = bins_sc[*,0:nanode-1,0:ndef-1]
  bins_sc = reform(transpose(bins_sc,[0,2,1]),ntime,ndef*nanode)

  return, reform(bins_sc)
  
end












;;#####################################################################
;; Main Function

pro mvn_sta_sc_bins_load, perc_block=perc_block,test_plot=test_plot


  ;;---------------------------------------------
  ;; Mark bins that are blocked by the spacecraft
  if ~keyword_set(perc_block) then perc_block=0.5
  
  ;;-----------------------------------------------------------
  ;; Declare Common Blocks
  common mvn_c8,mvn_c8_ind,mvn_c8_dat  ;16D       4s  Ram Conic
  common mvn_ca,mvn_ca_ind,mvn_ca_dat  ;4Dx16A    4s  Ram Conic
  common mvn_cc,mvn_cc_ind,mvn_cc_dat  ;8D       32s  Ram
  common mvn_cd,mvn_cd_ind,mvn_cd_dat  ;8D        4s  Ram
  common mvn_ce,mvn_ce_ind,mvn_ce_dat  ;4Dx16A   32s  Conic
  common mvn_cf,mvn_cf_ind,mvn_cf_dat  ;4Dx16A    4s  Conic
  common mvn_d0,mvn_d0_ind,mvn_d0_dat  ;4Dx16A  128s  Pickup
  common mvn_d1,mvn_d1_ind,mvn_d1_dat  ;4Dx16A   16s  Pickup
  common mvn_d4,mvn_d4_ind,mvn_d4_dat  ;4Dx16A    4s  Pickup

  apid=['c0','c6','c8',$
        'ca','cc','cd','ce','cf',$
        'd0','d1','d4']
  nn_apid=n_elements(apid)

  ;;----------------------------------------------------------------
  ;; Check if time exists
  if n_elements(mvn_c8_dat.time) eq 0 then begin
     print, 'This program uses APID c8, which is not loaded.'
     return
  endif

  print, 'Blocked Bins - Generate block map using apid C8 (~1 minute)'

  ;;----------------------------------------------------------------
  ;; Evenly spaced points in 2D with points seperated by nnn degrees
  ;; 1 degree per point
  nnn = 5
  phi_map   = indgen(360/nnn)*nnn - 180
  theta_map = indgen(180/nnn)*nnn - 90
  xx = reform(rebin(phi_map, 360/nnn, 180/nnn),360./nnn*180./nnn)
  yy = reform(transpose(rebin(theta_map, 180/nnn, 360/nnn)),360./nnn*180./nnn)

  ;;------------------------------
  ;; Get MAVEN Vertices
  inst=maven_spacecraft_vertices(prec=1)
  rot_matrix_name = inst.rot_matrix_name
  rot_matrix = inst.rot_matrix
  vertex = inst.vertex
  index  = inst.index
  xsc    = inst.x_sc
  ysc    = inst.y_sc
  zsc    = inst.z_sc
  coord=transpose([[[xsc]],[[ysc]],[[zsc]]])
  
  ;;--------------------------
  ;; Check vertex array size
  n1=3
  n2=8
  n3=n_elements(vertex)/n1/n2
  
  ;;--------------------------
  ;; Check XYZ components
  ss=size(coord)
  nn1=ss[1]
  nn2=ss[2]
  nn3=ss[3]

  ;;--------------------------------
  ;; Instrument and Gimbal location
  ;;--------------------------------
  ;;Inner Gimbal
  g1_gim_loc=[2589.00,203.50, 2044.00]
  ;;Outer Gimbal
  g2_gim_loc=[2775.00,203.50, 2044.00]
  ;;STATIC
  sta_loc=[2589.0+538.00, 203.50+450.00, 1847.50]
  ;;SWEA
  swe_loc=[-2359.00,   0.00,-1115.00]
  ;;SWIA
  swi_loc=[-1223.00,-1313.00, 1969.00]
  ;;SEP +X/+
  sep1_loc=[ 1245.00, 1143.00,2080.00]
  ;;SEP +X/-Y
  sep2_loc=[ 1245.00,-1143.00,2080.00]

  ;;-----------------------------------------------
  ;; STATIC location in Spacecraft cooridnates [mm]
  sta_loc=[2589.0+538.00, 203.50+450.00, 1847.50]

  ;;--------------------------
  ;; Get matrices/quaternions
  time = (mvn_c8_dat.end_time-mvn_c8_dat.time) / 2 + mvn_c8_dat.time
  qrot1_all = spice_body_att('MAVEN_APP_OG',$
                             'MAVEN_APP_IG', $
                             time, $
                             /quaternion, $
                             check_objects='MAVEN_SPACECRAFT')
  qrot2_all = spice_body_att('MAVEN_APP_IG',$
                             'MAVEN_APP_BP',$
                             time, $
                             /quaternion,$
                             check_objects='MAVEN_SPACECRAFT')
  matrix_all = spice_body_att('MAVEN_SPACECRAFT',$
                              'MAVEN_STATIC', $
                              time, $
                              check_objects='MAVEN_SPACECRAFT')


  ;;#######################################################################
  ;; Shift/Rotate spacecraft for all time and find blockage percentage
  nn = n_elements(time)

  ;;----------------------------------------
  ;; Map
  final_map = intarr(nn,360./nnn*180./nnn)

  phi_sc   = fltarr(nn,nn2,nn3)
  theta_sc = fltarr(nn,nn2,nn3)

  for iddx=1, nn-1 do begin

     ;;------------
     ;; Quick cluge
     idx=iddx-1

     ;;--------------------------------------------
     ;; Check if qrot changed. If it is the same as
     ;; before we do not need to recalculate map

     qrot_test = total(abs(qrot1_all[*,iddx]-qrot1_all[*,iddx-1])) + $
                 total(abs(qrot2_all[*,iddx]-qrot2_all[*,iddx-1]))

     if qrot_test gt 1e-5 or idx eq 0 then begin

        t1 = systime(1)
  
        ;;----------------------------------------
        ;; Rotate instrument location
        inst_loc = sta_loc
        coord=transpose([[[xsc]],[[ysc]],[[zsc]]])
        
        qrot1 = reform(qrot1_all[*, idx])
        qrot2 = reform(qrot2_all[*, idx])
        tmp1 = quaternion_rotation((inst_loc-g2_gim_loc), qrot1, /last_ind)
        tmp2 = quaternion_rotation(((tmp1+g2_gim_loc)-g1_gim_loc),qrot2,/last_ind)
        inst_loc = tmp2 + g1_gim_loc
        inst_rot = transpose(reform(matrix_all[*, *, idx]))
        
        ;;-----------------------------------------
        ;; Center spacecraft on instrument location
        coord[0,*,*]=coord[0,*,*]-inst_loc[0]
        coord[1,*,*]=coord[1,*,*]-inst_loc[1]
        coord[2,*,*]=coord[2,*,*]-inst_loc[2]

        ;;------------------------------------------------------------
        ;; Rotate Vertices into instrument coordiantes
        ;; NOTE: Vertices are originally in spacecraft coordinates.
        old_ver=reform(coord,nn1,nn2*nn3)
        new_ver=old_ver*0.
        for i=0L, nn2*nn3-1L do $
           new_ver[*,i]= inst_rot # old_ver[*,i]
        coord=reform(new_ver,nn1,nn2,nn3)
        new_shift=inst_rot # inst_loc
        inst_loc=new_shift
        
        ;;----------------------------------------------
        ;; Change coordinates from cartesian to spherical
        ;; theta - angle from positive z-axis (-90-90)
        ;; phi   - angle around x-y (-180 - 180)
        dat=transpose(reform(coord,nn1,nn2*nn3))
        xyz_to_polar, dat, $
                      theta=theta1, $
                      phi=phi1
        theta=reform(theta1, nn2, nn3)
        phi=reform(phi1, nn2, nn3)
        
        
        ;;---------------
        ;; Invert Phi
        phi=(((phi+180.)+180.) mod 360.)-180.
        
        ;;---------------
        ;; Invert Theta
        theta=-1.*theta
        
        phi_sc[idx,*,*]   = phi
        theta_sc[idx,*,*] = theta
        
        ;;-------------------------
        ;; Only check within limits
        xxyy_pp = where(xx le max(phi)   and xx ge min(phi) and $
                        yy le max(theta) and yy ge min(theta))
        
        ;;---------------------------
        ;; Fill Map with Blockage
        t2 = systime(1)     
        for i=0, n3-1 do $
           for j=0, 29, 5 do begin
           res_ins = inside(xx[xxyy_pp],yy[xxyy_pp],phi[j:j+4,i],theta[j:j+4,i])
           pp   = where(res_ins eq 1,cc)           
           if cc ne 0 then final_map[idx,xxyy_pp[pp]] = 1
        endfor

        t3 = systime(1)
        ;print, idx, '   ', t2-t1, '   ', t3-t2, qrot_test
        
     endif else begin
        phi_sc[idx,*,*]   = phi
        theta_sc[idx,*,*] = theta
        final_map[idx,*] = final_map[idx-1,*]
        ;print, idx, '   ', t2-t1, '   ', t3-t2, qrot_test
     endelse

     ;;----------------------------
     ;; Plot Spacecraft and map
     if keyword_set(test_plot) then begin
        pp=where(final_map[idx,*] eq 1)
        plot, phi, theta, xrange=[-180,180], yrange=[-90,90], xstyle=1, ystyle=1
        oplot, xx, yy, psym=3
        oplot, xx[pp], yy[pp], psym=1, color=250
        wait, 0.01
     endif

  endfor




  ;;*******************************************************************************
  ;; Bin data for all APIDs
  ;save,    filename='final_map.sav', final_map, mvn_c8_dat, phi_sc, theta_sc, time, mvn_cc_dat, mvn_ca_dat, xx, yy
  ;skip:
  ;restore, filename='final_map.sav'


  map  = final_map
  time = (mvn_c8_dat.end_time-mvn_c8_dat.time) / 2 + mvn_c8_dat.time
  final_map = 0

  ;;---------------------------
  ;; C8 - 16D     4s  Ram Conic
  print, 'Blocked Bins - Interpolate for APID-C8'
  ss = size(mvn_c8_dat)
  if ss[2] eq 8 then $
     mvn_c8_dat.bins_sc = histt(map,time,mvn_c8_dat,phi_sc,theta_sc,xx,yy,perc_block=perc_block)
  ;;---------------------------
  ;; CA - 4Dx16A    4s  Ram Conic
  print, 'Blocked Bins - Interpolate for APID-CA'
  ss = size(mvn_ca_dat)
  if ss[2] eq 8 then $
     mvn_ca_dat.bins_sc = histt(map,time,mvn_ca_dat,phi_sc,theta_sc,xx,yy,perc_block=perc_block)
  ;;---------------------------
  ;; CC - 8D       32s  Ram
  print, 'Blocked Bins - Interpolate for APID-CC'
  ss = size(mvn_cc_dat)
  if ss[2] eq 8 then $
     mvn_cc_dat.bins_sc = histt(map,time,mvn_cc_dat,phi_sc,theta_sc,xx,yy,perc_block=perc_block)
  ;;---------------------------
  ;; CD - 8D        4s  Ram
  print, 'Blocked Bins - Interpolate for APID-CD'
  ss = size(mvn_cd_dat)
  if ss[2] eq 8 then $
     mvn_cd_dat.bins_sc = histt(map,time,mvn_cd_dat,phi_sc,theta_sc,xx,yy,perc_block=perc_block)
  ;;---------------------------
  ;; CE - 4Dx16A   32s  Conic
  print, 'Blocked Bins - Interpolate for APID-CE'
  ss = size(mvn_ce_dat)
  if ss[2] eq 8 then $
     mvn_ce_dat.bins_sc = histt(map,time,mvn_ce_dat,phi_sc,theta_sc,xx,yy,perc_block=perc_block)
  ;;---------------------------
  ;; CF - 4Dx16A    4s  Conic
  print, 'Blocked Bins - Interpolate for APID-CF'
  ss = size(mvn_cf_dat)
  if ss[2] eq 8 then $
     mvn_cf_dat.bins_sc = histt(map,time,mvn_cf_dat,phi_sc,theta_sc,xx,yy,perc_block=perc_block)
  ;;---------------------------
  ;; D0 - 4Dx16A  128s  Pickup
  print, 'Blocked Bins - Interpolate for APID-D0'
  ss = size(mvn_d0_dat)
  if ss[2] eq 8 then $
     mvn_d0_dat.bins_sc = histt(map,time,mvn_d0_dat,phi_sc,theta_sc,xx,yy,perc_block=perc_block)
  ;;---------------------------
  ;; D1 - 4Dx16A   16s  Pickup
  print, 'Blocked Bins - Interpolate for APID-D1'
  ss = size(mvn_d1_dat)
  if ss[2] eq 8 then $
     mvn_d1_dat.bins_sc = histt(map,time,mvn_d1_dat,phi_sc,theta_sc,xx,yy,perc_block=perc_block)
  ;;---------------------------
  ;; D4 - 4Dx16A    4s  Pickup
  print, 'Blocked Bins - Interpolate for APID-D4'
  ss = size(mvn_d4_dat)
  if ss[2] eq 8 then $
     mvn_d4_dat.bins_sc = histt(map,time,mvn_d4_dat,phi_sc,theta_sc,xx,yy,perc_block=perc_block)


end




























































;;***********************************************************
;;Old Code




           ;ii  = strtrim(string(i),2)
           ;iii0 = strtrim(string(j),2)
           ;iii4 = strtrim(string(j+4),2)
           ;;-----------------
           ;; Commands
           ;cmd1 = "roi"+ii+" = "+$
           ;       "obj_new('IDLanROI', "+$
           ;       "phi["  +iii0+":"+iii4+","+ii+"], "+$
           ;       "theta["+iii0+":"+iii4+","+ii+"])"
           ;cmd2 = "temp=roi"+ii+"->containspoints(xx,yy)"
           ;cmd3 = "obj_destroy, roi"+ii
           ;;-----------------
           ;; Execute commands
           ;res1 = execute(cmd1)
           ;res2 = execute(cmd2)
           ;res3 = execute(cmd3)
           ;pp=where(temp eq 1,cc)           
           ;if cc ne 0 then final_map[pp] = 1
           ;pp=where(final_map eq 1,cc)
           ;plot, phi, theta
           ;oplot, xx[pp], yy[pp], psym=3, color=250
           ;wait, 0.2



     ;pp=where(final_map eq 1,cc)
     ;plot, phi, theta
     ;oplot, xx[pp], yy[pp], psym=3, color=250
     ;stop














  ;minn  = [ -2, -2]
  ;maxx  = [  2, 2]
  ;binss = [0.05,0.1]
  ;
  ;ff    = hist_nd(dat,binss,min=minn, max=maxx, reverse_indices=ri)
  ;
  ;nnx  =(maxx[0]-minn[0])/binss[0]+1
  ;nny  =(maxx[1]-minn[1])/binss[1]+1
  ; 
  ;nnxx = findgen(nnx+1)
  ;nnyy = findgen(nny+1)
  ;
  ;iix  = nnxx[0:nnx-1]
  ;iiy  = nnyy[0:nny-1]
  ;
  ;iiix = nnxx[1:nnx]
  ;iiiy = nnyy[1:nny]
  ;
  ;xx  = nnxx*binss[0]+minn[0]
  ;yy  = nnyy*binss[1]+minn[1]
  ;
  ;xx2 = transpose([[xx[iix]], [xx[iix]],[xx[iiix]],[xx[iiix]],[xx[iix]]])
  ;yy2 = transpose([[yy[iiy]],[yy[iiiy]],[yy[iiiy]], [yy[iiy]],[yy[iiy]]])
  ;
  ;xx3 = reform(rebin(xx2,5,nnx,nny), (nnx)*5.*(nny))
  ;yy3 = reform(transpose(rebin(yy2,5,nny,nnx),[0,2,1]),(nnx)*5.*(nny))
  ;
  ;tot=fltarr(nnx,nny)
  ;
  ;for i=0L,(nnx)*(nny)-1 do $
  ;   if ri[i+1] gt ri[i] then $
  ;      tot[i]=n_elements(dat[ri[ri[i]:ri[i+1]-1]])
