;+
;PROCEDURE:      MVN_SPC_FOV_BLOCKAGE
;
;PURPOSE:        Plot MAVEN spacecraft/instrument vertices in spherical
;                coordiantes (phi-> -180-180, theta-> -90-90). The
;                location and orientation can be changed by selecting
;                the instrument of choice as a keyword. 
;
;OUTPUT:         Oplot of MAVEN spacecraft and isntruments.
;
;KEYWORDS:
;
;  POLYFILL:     FOR FUTURE VERSION
;
;  TRANGE:       Time selection.
;
;  CLR:          Color of vertices and fill.
;
;  INVERT_PHI:   Invert the phi coordiantes.
;
;  INVERT_THETA: Invert the theta coordiantes.
;
;  SWEA:         Change coordinates/FOV to match SWEA.
;
;  SWIA:         Change coordinates/FOV to match SWIA.
;
;  STATIC:       Change coordinates/FOV to match STATIC.
;
;  SEP1:         Change coordinates/FOV to match SEP1.
;
;  SEP2:         Change coordinates/FOV to match SEP2.
;
;  PHI:          Return the computed phi information.
;
;  THETA:        Return the computed theta information.
;
;CREATED BY:     Roberto Livi on 2015-02-23.
;
;EXAMPLES:       1. SWEA
;                mvn_spc_fov_blockage,clr=200,/swea,/invert_phi,/invert_theta
;
; VERSION:
;   $LastChangedBy: rlivi2 $
;   $LastChangedDate: 2018-06-11 13:31:44 -0700 (Mon, 11 Jun 2018) $
;   $LastChangedRevision: 25347 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/anc/mvn_spc_fov_blockage.pro $
;-
pro mvn_spc_fov_blockage, trange=trange,$
                          clr=clr,$  
                          polyfill=polyfill,$
                          negate=negate,$
                          invert_phi=invert_phi,$
                          invert_theta=invert_theta,$
                          swea=swea,$
                          swia=swia,$
                          sep1=sep1,$
                          sep2=sep2,$
                          static=static, $
                          phi=phi, $
                          theta=theta, $
                          noplot=noplot

   ;; MAVEN Field-of-View Common Blocks
   COMMON mvn_spc_vertices, inst
   COMMON mvn_sta_fov_block, $
    mvn_sta_fov_block_time,  $
    mvn_sta_fov_block_qrot1, $
    mvn_sta_fov_block_qrot2, $
    mvn_sta_fov_block_qrot3, $
    mvn_sta_fov_block_qrot4, $
    mvn_sta_fov_block_qrot5, $
    mvn_sta_fov_block_matrix

   ;; Initiate MAVEN vertices
   maven_spacecraft_vertices
   rot_matrix_name=inst.rot_matrix_name
   rot_matrix=inst.rot_matrix

   ;; User selected instrument
   IF keyword_set(static) THEN inst_loc=inst.sta_loc
   IF keyword_set(swea)   THEN inst_loc=inst.swe_loc
   IF keyword_set(swia)   THEN inst_loc=inst.swi_loc
   IF keyword_set(sep1)   THEN inst_loc=inst.sep1_loc
   IF keyword_set(sep2)   THEN inst_loc=inst.sep2_loc

   ;; Define instrument coordinates
   IF keyword_set(static)  THEN inst_rot_name='STATIC'
   IF keyword_set(swea)    THEN inst_rot_name='SWEA'
   IF keyword_set(swia)    THEN inst_rot_name='SWIA'
   IF keyword_set(sep1)    THEN inst_rot_name='SEP1'
   IF keyword_set(sep2)    THEN inst_rot_name='SEP2'

   ;; Select Rotation matrix
   pname=where(rot_matrix_name eq inst_rot_name,cc)

   ;; Error Check
   if cc ne 0 then $
    inst_rot=reform(rot_matrix[*,*,pname]) else $
     if inst_rot_name ne 'STATIC' then stop, 'ERROR'

   ;; STATIC location and rotation matrix
   if keyword_set(static) then begin

      ;; Keyword Check 
      if ~keyword_set(trange) then begin
         timespan,['2015-01-10','2015-01-11']
         trange=timerange()
      ENDIF

      ;; Spice Check
      mk = spice_test('*')
      indx = where(mk ne '', count)
      if (count eq 0) then begin
         mk = mvn_spice_kernels($
              /all,/load,trange=trange,$
              verbose=verbose)
      ENDIF

      ;; Get valid times
      utc=time_string(trange)
      cspice_str2et,utc,et
      time_valid = spice_valid_times($
                   et[0],object=check_objects,tol=tol)

      recompute = 0

      ;; If time block is empty generate rotation matrices
      ;; with Spice.
      IF SIZE(mvn_sta_fov_block_time, /type) EQ 0 THEN BEGIN
         recompute:

         ;; Get time intervals from APID C0
         status = EXECUTE("mvn_sta_fov_block_time = "+$
                          "(SCOPE_VARFETCH('mvn_c0_dat', "+$
                          "common='mvn_c0')).time")

         ;; Check if time exists
         IF status EQ 0 THEN stop, $
          'Took this section out. See comments. ;;GOTO, previous'
         undefine, status

         ;; MAVEN APP OG to MAVEN APP IG
         mvn_sta_fov_block_qrot3 = spice_body_att($
                 'MAVEN_APP_OG','MAVEN_APP_IG',$
                 mvn_sta_fov_block_time, $
                 /quaternion, $
                 check_objects='MAVEN_SPACECRAFT')

         ;; MAVEN APP IG to MAVEN APP BP
         mvn_sta_fov_block_qrot4  = spice_body_att($
                 'MAVEN_APP_IG','MAVEN_APP_BP',$
                 mvn_sta_fov_block_time, $
                 /quaternion, $
                 check_objects='MAVEN_SPACECRAFT')

         ;; MAVEN SPACECRAFT to MAVEN STATIC
         mvn_sta_fov_block_matrix = spice_body_att($
                 'MAVEN_SPACECRAFT', 'MAVEN_STATIC',$
                 mvn_sta_fov_block_time, $
                 check_objects='MAVEN_SPACECRAFT')
         recompute = 1
      ENDIF

      ;; If block time exists:
      IF SIZE(mvn_sta_fov_block_time, /type) NE 0 THEN BEGIN
         IF (time_double(utc) LT mvn_sta_fov_block_time[0]) OR $
          (time_double(utc) GT max(mvn_sta_fov_block_time)) THEN $
           IF recompute EQ 0 THEN GOTO, recompute $
           ELSE stop, 'Took this section out. See comments. ;;GOTO, previous'
         idx = NN(mvn_sta_fov_block_time, utc)

         ;; 1. Outer Gimbal closest to APP base plate.
         qrot2 =  REFORM(mvn_sta_fov_block_qrot3[*, idx])
         tmp2 = quaternion_rotation([1.0,0.0,1.0], qrot2, /last_ind)
         th2 = atan(tmp2[1],tmp2[2])

         ;; 2. Rotate about Inner Gimbal closest to spacecraft.
         qrot1 =  REFORM(mvn_sta_fov_block_qrot4[*, idx])
         tmp1 = quaternion_rotation([0.0,1.0,1.0], qrot1, /last_ind)
         th1 = -1.*atan(tmp1[0],tmp1[2])

         mvn_spc_vertices_rotate_app, th1, th2

         ;; 3. Rotation matrix -> Spacecraft to STATIC
         inst_rot = TRANSPOSE(REFORM(mvn_sta_fov_block_matrix[*, *, idx]))
         undefine, idx
         GOTO, draw
      ENDIF      
   ENDIF 
   draw:

   ;; Vertices and Matrices
   vertex=inst.vertex
   index=inst.index
   original_inst_loc = inst.inst_loc

   ;; Temporary kludge
   inst.inst_loc = inst_loc
   
   ;; Create XYZ coordinates for plotting
   nn = 5.*inst.n2 ;; 5 points to draw each side.
   xx = fltarr(inst.n3,nn);5.*inst.n2)
   yy = fltarr(inst.n3,nn);5.*inst.n2)
   zz = fltarr(inst.n3,nn);5.*inst.n2)

   ;; Cycle through all n3 objects
   for iobj=0, inst.n3-1 do begin

      ;; Cycle through all 8 vertices.
      ll = indgen(5)
      for i=0, inst.n2-1 do begin           
         box  = vertex[*,*,iobj]
         ind  = index[*,*,iobj]           
         indd = [ind[*,i],ind[0,i]]
         ;; Generate PREC number of points between two vertices.
         ;; Repeat for all indices.
         xx[iobj,ll] = reform(box[0,indd])
         yy[iobj,ll] = reform(box[1,indd])
         zz[iobj,ll] = reform(box[2,indd])
         ll = ll+5
      endfor
   endfor
   
   ;; Expand using prec
   prec = inst.prec
   xx_new = fltarr(inst.n3,(nn-1)*prec+1)
   yy_new = fltarr(inst.n3,(nn-1)*prec+1)
   zz_new = fltarr(inst.n3,(nn-1)*prec+1)

   for iobj=0, inst.n3-1 do begin    
      xx_new[iobj,*] = interpol(xx[iobj,*],findgen(nn),$
                                findgen((nn-1)*prec+1)/prec)
      yy_new[iobj,*] = interpol(yy[iobj,*],findgen(nn),$
                                findgen((nn-1)*prec+1)/prec)
      zz_new[iobj,*] = interpol(zz[iobj,*],findgen(nn),$
                                findgen((nn-1)*prec+1)/prec)
   endfor

   ;; Coordinate Transformation
   coord=transpose([[[xx_new]],[[yy_new]],[[zz_new]]])

   ;; Check vertex array size
   n1=3
   n2=8
   n3=n_elements(vertex)/n1/n2

   ;; Check XYZ components
   ss=size(coord)
   nn1=ss[1]
   nn2=ss[2]
   nn3=ss[3]

   ;; Shift to Instrument location
   coord[0,*,*]=coord[0,*,*]-inst.inst_loc[0]
   coord[1,*,*]=coord[1,*,*]-inst.inst_loc[1]
   coord[2,*,*]=coord[2,*,*]-inst.inst_loc[2]

   ;; Rotate Vertices into instrument coordinates
   ;; NOTE: Vertices are originally in
   ;;       spacecraft coordinates.
   old_ver=reform(coord,nn1,nn2*nn3)
   new_ver=old_ver*0.
   FOR i=0L, nn2*nn3-1L DO $
    new_ver[*,i]= inst_rot # old_ver[*,i]
   coord=reform(new_ver,nn1,nn2,nn3)
   new_shift=inst_rot # inst_loc
   inst_loc=new_shift

   
   ;; Change coordinates from cartesian to spherical
   ;; theta - angle from positive z-axis (-90-90)
   ;; phi   - angle around x-y (-180 - 180)
   ;; dat=transpose(reform(vertex,n1,n2*n3))
   IF 1 THEN BEGIN 
      dat=transpose(reform(coord,nn1,nn2*nn3))
      cart_to_sphere, dat[*,0], dat[*,1], dat[*,2],$
                      r,theta,phi
      theta = reform(temporary(theta), nn2, nn3)
      phi   = reform(temporary(phi),   nn2, nn3)
   ENDIF

   ;;Invert Phi
   IF keyword_set(invert_phi) THEN BEGIN 
      phi = (phi+180.) MOD 360
      pp = where(phi GT 180,cc)
      IF cc NE 0 THEN phi[pp] = phi[pp]-360.
   ENDIF 
   
   ;;Invert Theta
   if keyword_set(invert_theta) then $
    theta=-1.*theta

   ;; Exit with noplot
   IF keyword_set(noplot) THEN RETURN

   ;; Select Color
   if keyword_set(clr) then clr1=clr else clr1=250

   ;; Draw Objects
   FOR iobj=0L, nn3-1L DO BEGIN

      ;; Exclude APP from drawing
      IF iobj NE 11 AND $
       iobj NE 12 AND $
       iobj NE 13 AND $
       iobj NE 14 THEN BEGIN 

         ;; Setup phi and theta components
         phi_temp=phi[*,iobj]
         theta_temp=theta[*,iobj]
         if keyword_set(polyfill) then $
          polyfill, phi_temp,$
                    theta_temp,$
                    color=clr1 
         oplot, phi_temp,theta_temp,$
                color=clr1
      ENDIF
   ENDFOR
   
END
