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
;   $LastChangedBy: hara $
;   $LastChangedDate: 2015-07-16 13:57:22 -0700 (Thu, 16 Jul 2015) $
;   $LastChangedRevision: 18157 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/anc/mvn_spc_fov_blockage.pro $
;-
pro mvn_spc_fov_blockage, trange=trange,$
                          clr=clr,$  
                          polyfill=polyfill,$
                          invert_phi=invert_phi,$
                          invert_theta=invert_theta,$
                          swea=swea,$
                          swia=swia,$
                          sep1=sep1,$
                          sep2=sep2,$
                          static=static, phi=phi, theta=theta, noplot=noplot

  common mvn_sta_fov_block, mvn_sta_fov_block_time, mvn_sta_fov_block_qrot1, mvn_sta_fov_block_qrot2, mvn_sta_fov_block_matrix

  ;;------------------------------
  ;;Get MAVEN Vertices
  inst=maven_spacecraft_vertices()
  rot_matrix_name=inst.rot_matrix_name
  rot_matrix=inst.rot_matrix
  vertex=inst.vertex
  index=inst.index
  xsc=inst.x_sc
  ysc=inst.y_sc
  zsc=inst.z_sc
  coord=transpose([[[xsc]],[[ysc]],[[zsc]]])



  ;;--------------------------
  ;;Check vertex array size
  n1=3
  n2=8
  n3=n_elements(vertex)/n1/n2

  ;;--------------------------
  ;;Check XYZ components
  ss=size(coord)
  nn1=ss[1]
  nn2=ss[2]
  nn3=ss[3]




  ;;------------------------------
  ;;Instrument and Gimbal location
  ;;------------------------------
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


  ;;------------------------------
  ;;User selected instrument
  if keyword_set(static) then inst_loc=sta_loc
  if keyword_set(swea)   then inst_loc=swe_loc
  if keyword_set(swia)   then inst_loc=swi_loc
  if keyword_set(sep1)   then inst_loc=sep1_loc
  if keyword_set(sep2)   then inst_loc=sep2_loc

  ;;-------------------------------------------
  ;;Define instrument coordinates
  if keyword_set(static)   then inst_rot_name='STATIC'
  if keyword_set(swea)   then inst_rot_name='SWEA'
  if keyword_set(swia)   then inst_rot_name='SWIA'
  if keyword_set(sep1)    then inst_rot_name='SEP1'
  if keyword_set(sep2)    then inst_rot_name='SEP2'

  ;;---------------------------------------------
  ;;Select Rotation matrix
  pname=where(rot_matrix_name eq inst_rot_name,cc)
  if cc ne 0 then $
     inst_rot=reform(rot_matrix[*,*,pname]) else $
        if inst_rot_name ne 'STATIC' then stop, 'ERROR'

  ;;---------------------------------------------
  ;;Get STATIC location and rotation matrix
  if keyword_set(static) then begin
        
     if ~keyword_set(trange) then begin
        timespan,['2015-01-10','2015-01-11']
        trange=timerange()
     endif
     mk = spice_test('*')
     indx = where(mk ne '', count)
     if (count eq 0) then begin
        mk = mvn_spice_kernels(/all,/load,trange=trange,verbose=verbose)
     endif
     utc=time_string(trange)
     cspice_str2et,utc,et
     time_valid = spice_valid_times(et[0],object=check_objects,tol=tol)     
     recompute = 0
     IF SIZE(mvn_sta_fov_block_time, /type) EQ 0 THEN BEGIN
        recompute:
        status = EXECUTE("mvn_sta_fov_block_time = (SCOPE_VARFETCH('mvn_c0_dat', common='mvn_c0')).time")
        IF status EQ 0 THEN GOTO, previous
        undefine, status
        mvn_sta_fov_block_qrot1 = spice_body_att('MAVEN_APP_OG', 'MAVEN_APP_IG', mvn_sta_fov_block_time, $
                                                 /quaternion, check_objects='MAVEN_SPACECRAFT')
        mvn_sta_fov_block_qrot2 = spice_body_att('MAVEN_APP_IG', 'MAVEN_APP_BP', mvn_sta_fov_block_time, $
                                                 /quaternion, check_objects='MAVEN_SPACECRAFT')
        mvn_sta_fov_block_matrix = spice_body_att('MAVEN_SPACECRAFT', 'MAVEN_STATIC', mvn_sta_fov_block_time, $
                                                 check_objects='MAVEN_SPACECRAFT')
        recompute = 1
     ENDIF
     IF SIZE(mvn_sta_fov_block_time, /type) NE 0 THEN BEGIN
        IF (time_double(utc) LT mvn_sta_fov_block_time[0]) OR (time_double(utc) GT mvn_sta_fov_block_time[N_ELEMENTS(mvn_sta_fov_block_time)-1]) THEN $
           IF recompute EQ 0 THEN GOTO, recompute ELSE GOTO, previous
        idx = NN(mvn_sta_fov_block_time, utc)
        qrot1 = REFORM(mvn_sta_fov_block_qrot1[*, idx])
        qrot2 = REFORM(mvn_sta_fov_block_qrot2[*, idx])
        inst_loc = quaternion_rotation(((quaternion_rotation((inst_loc-g2_gim_loc), qrot1, /last_ind) + g2_gim_loc) - g1_gim_loc), qrot2, /last_ind) + g1_gim_loc
        inst_rot = TRANSPOSE(REFORM(mvn_sta_fov_block_matrix[*, *, idx]))
        undefine, idx
        GOTO, draw
     ENDIF
     ;;---------------------------------------------------
     ;;Change STATIC location depending on the rotation of
     ;;the inner and outer gimbal.
     ;;NOTE: In this case inst_loc = sta_loc

     ;;######################################
     ;;1.: Rotate inst_loc about outer Gimbal
     ;;a. Use location of 2nd gimbal as rotation axis
     ;;b. Perform rotation.
     ;;c. Shift back to original Spacecraft origin
     ;;---
     ;;2.: Rotate inst_loc about inner Gimbal
     ;;a. Use location of 1st gimbal as rotation axis
     ;;b. Perform rotation.
     ;;c. Shift back to original Spacecraft origin
     previous:
     inst_loc_new=inst_loc-g2_gim_loc
     inst_loc_new2=$
        spice_vector_rotate(inst_loc_new,$
                            utc[0],$
                            'MAVEN_APP_OG',$
                            'MAVEN_APP_IG',$
                            check_objects='MAVEN_SPACECRAFT')
     inst_loc=inst_loc_new2+g2_gim_loc
     ;;------------------------------------------------------
     inst_loc_new=inst_loc-g1_gim_loc
     inst_loc_new2=$
        spice_vector_rotate(inst_loc_new,$
                            utc[0],$
                            'MAVEN_APP_IG',$
                            'MAVEN_APP_BP',$
                            check_objects='MAVEN_SPACECRAFT')
     inst_loc=inst_loc_new2+g1_gim_loc

     ;;------------------------------------------------------
     ;;Get rotation matrix
     cspice_pxform,'MAVEN_SPACECRAFT','MAVEN_STATIC',et[0],static_rot
     inst_rot=transpose(static_rot)
     cspice_kclear

  endif
  draw:
  ;;---------------------------------
  ;;Shift to Instrument location
  coord[0,*,*]=coord[0,*,*]-inst_loc[0]
  coord[1,*,*]=coord[1,*,*]-inst_loc[1]
  coord[2,*,*]=coord[2,*,*]-inst_loc[2]



  ;;------------------------------------------------------------
  ;;Rotate Vertices into instrument coordiantes
  ;;NOTE: Vertices are originally in spacecraft coordinates.
  old_ver=reform(coord,nn1,nn2*nn3)
  new_ver=old_ver*0.
  for i=0L, nn2*nn3-1L do $
     new_ver[*,i]= inst_rot # old_ver[*,i]
  coord=reform(new_ver,nn1,nn2,nn3)
  new_shift=inst_rot # inst_loc
  inst_loc=new_shift




  ;;----------------------------------------------
  ;;Change coordinates from cartesian to spherical
  ;;theta - angle from positive z-axis (-90-90)
  ;;phi - angle around x-y (-180 - 180)
  ;dat=transpose(reform(vertex,n1,n2*n3))
  dat=transpose(reform(coord,nn1,nn2*nn3))
  xyz_to_polar, dat, $
                theta=theta1, $
                phi=phi1
  ;;theta=reform(theta1, n2, n3)
  ;;phi=reform(phi1, n2, n3)  
  theta=reform(theta1, nn2, nn3)
  phi=reform(phi1, nn2, nn3)


  ;;--------------
  ;;Invert Phi
  if keyword_set(invert_phi) then $
     phi=(((phi+180.)+180.) mod 360.)-180.

  ;;---------------
  ;;Invert Theta
  if keyword_set(invert_theta) then $
        theta=-1.*theta

  IF keyword_set(noplot) THEN RETURN
  ;;-------------------------------
  ;;Select Color
  if keyword_set(clr) then clr1=clr else clr1=250
  
  for iobj=0L, nn3-1L do begin
     phi_temp=phi[*,iobj]
     theta_temp=theta[*,iobj]
     if keyword_set(polyfill) then $
        polyfill, phi_temp,$
                  theta_temp,$
                  color=clr1 
     oplot, phi_temp,theta_temp,$
            color=clr1
  endfor  


end










;;;###################################################################
;;;OLD CODE (may be useful later)
;;;###################################################################



  ;;Inner Gimbal
  ;g1_gim_loc=[2585.00,203.50, 2044.00]
  ;;;Outer Gimbal
  ;g2_gim_loc=[2775.00,203.50, 2044.00]
  ;;;STATIC
  ;sta_loc=[ 3127.00, 1847.00, 1847.50]
  ;;;SWEA
  ;swe_loc=[-2359.00,   0.00,-1115.00]
  ;;;SWIA
  ;swi_loc=[ 3126.00, 1847.00, -450.00]
  ;;;SEP 
  ;sep_loc=[ 3126.00, 1847.00, -450.00]



     ;;############################################
     ;;1st: Rotate STATIC FOV center location about 
     ;;Xs/c by theta degrees.
     ;;This is the equivalent of rotating the outer gimble
     ;;(relative to the inner gimbal).
     ;;1. Shift from Spacecraft origin to location of 2nd gimbal
     ;sta_loc_new=sta_loc-g2_gim_loc
     ;;2. Find rotation matrix between outer and inner gimbal
     ;cspice_pxform, 'MAVEN_APP_OG', 'MAVEN_APP_IG', et, rot_g1
     ;;3. Get Euler angle defining rotation about Xs/c axis
     ;theta=atan(rot_g1[1,2],rot_g1[2,2])
     ;;4. Create rotation matrix and rotate
     ;rot1=[[1.,         0.,             0.],$
     ;      [0., cos(theta), -1.*sin(theta)],$
     ;      [0., sin(theta), -1.*cos(theta)]]
     ;sta_loc_new2=transpose(rot1) # sta_loc_new
     ;;5. Shift back to original Spacecraft origin
     ;sta_loc=sta_loc_new2+g2_gim_loc





     ;;######################################
     ;;2.: Rotate sta_loc about inner Gimbal
     ;;a. Shift to location of 2nd gimbal
     ;sta_loc_new=sta_loc-g1_gim_loc
     ;;b. Find rotation matrix between outer and inner gimbal
     ;cspice_pxform, 'MAVEN_APP_IG', 'MAVEN_APP_BP', et, rot_g2
     ;;c. Get Euler angle defining rotation about Ys/c axis
     ;phi=atan(-1.*rot_g2[0,2],sqrt(rot_g2[1,2]^2+rot_g2[2,2]))
     ;;d. Create rotation matrix and rotate
     ;rot2=[[cos(phi),   0.,       sin(phi)],$
     ;      [0.,         1.,             0.],$
     ;      [0.,   sin(phi),   -1.*cos(phi)]]
     ;sta_loc_new2=transpose(rot2) # sta_loc_new
     ;;5. Shift back to original Spacecraft origin
     ;sta_loc=sta_loc_new2+g1_gim_loc
     

  ;;######## USING DAVIN'S ROUTINE #############
  ;;new_ver2=spice_vector_rotate($
  ;;      old_ver,$
  ;;      replicate(utc[0],n2*n3),$
  ;;      'MAVEN_SPACECRAFT',$
  ;;      inst_rot,$
  ;;      check_objects='MAVEN_SPACECRAFT')
  ;;vertex2=reform(new_ver2,n1,n2,n3)
  ;;###########################################



  ;;------------------------------------------------------------
  ;;Rotate Vertices into instrument coordiantes
  ;;NOTE: Vertices are originally in spacecraft coordinates.
  ;;old_ver=reform(vertex,n1,n2*n3)
  ;;new_ver=old_ver*0.
  ;;for i=0, n2*n3-1 do $
  ;;   new_ver[*,i]= inst_rot # old_ver[*,i]
  ;;vertex=reform(new_ver,n1,n2,n3)
  ;;new_shift=inst_rot # inst_loc
  ;;inst_loc=new_shift

  ;;---------------------------------
  ;;Shift to Instrument location
  ;vertex[0,*,*]=vertex[0,*,*]-inst_loc[0]
  ;vertex[1,*,*]=vertex[1,*,*]-inst_loc[1]
  ;vertex[2,*,*]=vertex[2,*,*]-inst_loc[2]




  ;;-------------------------------
  ;;Draw Vertices
  ;for iobj=0, n3-1 do begin
  ;   for i=0, 5 do begin
  ;      phi_temp=phi[*,iobj]
  ;      theta_temp=theta[*,iobj]
  ;      ind=index[*,*,iobj]           
  ;      indd=[ind[*,i],ind[0,i]]
  ;      if keyword_set(polyfill) then $
  ;         polyfill, phi_temp[indd],$
  ;                   theta_temp[indd],$
  ;                   color=clr1 
  ;      oplot, phi_temp[indd],$
  ;             theta_temp[indd],$
  ;             color=clr1
  ;   endfor
  ;endfor  

