
pro mvn_lpw_anc_boom, unix_in, flow=flow


;+
;
;PURPOSE: determine % of booms and sensors in shadow; sun angle on booms, distance sensors are from wake.
;
;INPUTS:
; - sun_x, sun_y, sun_z are the solar co-ordinates of the Sun (x,y,z) in the MAVEN s/c frame, in km.
;                     They can be single numbers or arrays, at double precision for best results.
;
; - vx, vy, vz are MAVEN velocity vectors in km/s. Can be arrays (double precision required).
;
; - dlimit and limit are the dlimit and limit structures needed to create the tplot variables.
;
;OUTPUTS:
;  Tplot variables:
;  mvn_lpw_anc_boom_shadow_orient: 2 lines: the phi and theta angles (in degrees) of the Sun in the MAVEN s/c frame.
;  mvn_lpw_anc_boom_shadow: 4 lines: boom1, sensor1, boom2, sensor2, % that is in shadow.
;  mvn_lpw_anc_boom_shadow_desc: 2 lines: a number corresponding to the shadow 'form', as described below.
;  mvn_lpw_anc_boom_angles: 2 lines: sun angle on the boom1/sensor1, boom2,sensor2, in degrees.
;
;  mvn_lpw_anc_boom_wake_orient :2 lines: the phi and theta angles (in degrees) of the s/c velocity in the MAVEN s/c frame.
;  mvn_lpw_anc_boom_wake_d_sc: distance in meters between sensor and geometric wake. (2 lines)
;  mvn_lpw_anc_boom_wake: boom is in shadow or not, 1: in wake, 0: out of wake
;  mvn_lpw_anc_boom_wake_d_perp: perp distance in meters from sensors to ram vector passing through s/c center.
;  mvn_lpw_anc_boom_wake_d_para: para distance in meters from sensors, to ram vector passing through s/c center. +ve value
;                                means sensor is in front of s/c wrt motion; -ve values means sensor is behind.
;  mvn_lpw_anc_boom_wake_ram_angles: angles between RAM velocity and sensors, in degrees. 2 lines, for per boom.
;  
;  
; KEYWORDS:
; - flow: optional keyword. This is a 3 element vector containing flow directions of any external flows to MAVEN (for example plasma flow).
;                           Speeds are in km/s. If set, this flow is added to the MAVEN s/c vel to  give the overall ram vector. If omitted
;                           just MAVEN velocity in MSO is used to determine the RAM velocity.
;
;KEY TO DESCRIPTION FOR SHADOW_DESC:
;This is output in the tplot variable mvn_lpw_anc_boom_shadow_desc:
;
;0 : whole boom and sensor in shadow
;1 : boom all in shadow, sensor all in sun
;2 : boom all in sun, sensor all in shadow
;3 : boom partly in shadow from base out, sensor all in sun
;4 : boom all in shadow, sensor partly in shadow from base out
;5 : boom partly in shadow, not from base out, sensor all in shadow
;6 : boom all in sun, sensor partly in shadow, not from base out
;7 : boom and sensor all both in sun
;
;For two or more blocks of shadow, there are many different arrangements, so group them all into one number (there aren't many).
;For this to happen, there have to be at least two up / down changes for the boom and sensor combined (note that the boom and sensor are
;separate so the shadow can change at the boom - to detect this we need to check the value of shadow at last boom point and first sensor point).
;
;8 : two or more blocks of shadow or sun on the boom, sensor in sun
;9 : two or more blocks of sun on the sensor, boom in sun
;10 : some other combination of multiple shadow spots on the boom and sensor, both neither fully in sun or shadow
;
;
;Written August 26th 2014 by CF: calculates shadow and wake properties of the two lpw booms.
;2014-09-08: CF: fixed bugs: Nans when position info not available now carry through and produce nans for all tplot variables.
;-
;

proname = 'mvn_lpw_anc_boom'

;Checks for correct tplot variables, get data needed:
tplotnames = tnames()  ;variables stored as tplot variables

;Variables needed: mvn_lpw_anc_mvn_vel_sc, mvn_lpw_anc_sun_pos_mvn
if total(strmatch(tplotnames, 'mvn_lpw_anc_mvn_vel_sc_iau')) eq 1 then begin
      get_data, 'mvn_lpw_anc_mvn_vel_sc_iau', data=dd1, dlimit=dl1, limit=ll1
      yes1 = 1
      shad_flag = dd1.flag  ;flag info concerning velocity info
endif else begin
      print, proname, ": ### WARNING ### : tplot variable **mvn_lpw_anc_mvn_vel_sc_iau** not found. Wake information not generated. "
      print, "Run mvn_lpw_anc_spacecraft first to create required tplot variables."
      yes1 = 0
endelse

if total(strmatch(tplotnames, 'mvn_lpw_anc_sun_pos_mvn')) eq 1 then begin
  get_data, 'mvn_lpw_anc_sun_pos_mvn', data=dd2, dlimit=dl2, limit=ll2
  yes2 = 1
  wake_flag = dd2.flag  ;flag info for wake
endif else begin
  print, proname, ": ### WARNING ### : tplot variable **mvn_lpw_anc_sun_pos_mvn** not found. Shadow information not generated. "
  print, "Run mvn_lpw_anc_spacecraft first to create required tplot variables."
  yes2 = 0
endelse



if yes1 eq 1 then begin   
      ;Change variables otherwise IDL will change them:
      dlimit2 = dl2
      limit2 = ll2 
  

      sun_x = dd2.y[*,0]  ;get Sun position as fn(t)
      sun_y = dd2.y[*,1]
      sun_z = dd2.y[*,2]

      nele_time = n_elements(sun_x)  ;number of time stamps
      
      ;Work out spherical co-ordinates from input solar cartesian co-ords:
      r = sqrt(sun_x^2 + sun_y^2 + sun_z^2)
    
       ;Old code, that used atan2, that people may not have"  
   ;   theta = atan2(sun_y, sun_x, /deg)
   ;   ;Range of theta is -180 => 180. Must convert this to 0 => 360. A result 0=>180 is fine. -175==185; -90==270, -5==355, etc.
   ;   rind = where(theta lt 0., nrind)  ;find elements lt 0
   ;   if nrind gt 0 then theta[rind] = 180 + (180 - abs(theta[rind]))  ;convert them to +ve degrees from +x axis
      
      ;New code, using atan, from IDL database:
      theta = atan(sun_y,sun_x)*(180./!pi)  ;convert to degrees
      inds = where(sun_y lt 0., ninds)
      if ninds gt 0 then theta[inds] = 360. - abs(theta[inds])  ;take into account sectors from atan.

      phi = (acos(sun_z / r)) * (180.D/!pi)
      
      ;==============
      ;--- Shadow ---
      ;==============
      
      ;Read in LUT:
      ;Use an ASCII file:
      mvn_lpw_anc_boom_get_luts, lut, /shadow  ;get shadow LUT
      
      if n_elements(lut) eq 1 then print, "SHADOW LUT ERROR" else begin ;#### permanent fix here
      
        ;Use these to find the correct entry in the LUT table:
        ;### Still need to re-run the LUT with correct values. This is from the array final_data:
        ;Column 1: phi (degrees)
        ;Column 2: theta (degrees)
        ;Column 3: boom1 %
        ;Column 4: sensor1 %
        ;Column 5: boom2 %
        ;Column 6: sensor2 %
        ;Column 7: description 1
        ;Column 8: description 2
      
        ;Locate position in LUT:
        ;The resolution of the grid is known, 5 degrees currently:
        ;There are 72 theta bins for each of the 36 phi bins.
        res_th = 72.
        res_ph = 36.
        
        p_ind = (floor((phi/180.)*res_ph))*res_th
        t_ind = (floor((theta/360.)*res_th))
        
        ;Check for nans here as floor will produce weird large numbers and has no /nan option:
        nan_ind1 = finite(phi, /nan)
        nan_shad = total(nan_ind1)
        if nan_shad gt 0 then begin
                nan_ind2 = where(nan_ind1 eq 1)
                p_ind[nan_ind2] = !values.f_nan
                t_ind[nan_ind2] = !values.f_nan
        endif
      
        ind = p_ind + t_ind
      
        ;Get information from lut:
        phi2 = lut[0,ind]
        theta2 = lut[1,ind]
        boom1_p = lut[2,ind]
        sen1_p = lut[3,ind]
        boom2_p = lut[4,ind]
        sen2_p = lut[5,ind]
        d1 = lut[6,ind]
        d2 = lut[7,ind]
      
        angles = dblarr(nele_time,2)
        angles[*,0] = lut[8,ind]
        angles[*,1] = lut[9,ind]
      
        ;Create tplot variables:
        ;Store as tplot variable, some fields may need editing:
        orient = dblarr(nele_time,2)
        orient[*,0] = transpose(phi)  ;phi values, use actual values, not those from LUT which are in steps of 5 degrees
        orient[*,1] = transpose(theta)  ;theta values
      
        shadow_data = dblarr(nele_time,4)
        shadow_data[*,0] = boom1_p
        shadow_data[*,1] = sen1_p
        shadow_data[*,2] = boom2_p
        shadow_data[*,3] = sen2_p
      
        desc = dblarr(nele_time,2)  ;add descriptions of shadow. These will probably be a number, which refer to a certain case which the user can then look up
        desc[*,0] = d1
        desc[*,1] = d2
      
        ;Correct for NaNs in data:
        if nan_shad gt 0 then begin
              orient[nan_ind2,0] = !values.f_nan
              orient[nan_ind2,1] = !values.f_nan
              shadow_data[nan_ind2,0] = !values.f_nan
              shadow_data[nan_ind2,1] = !values.f_nan
              shadow_data[nan_ind2,2] = !values.f_nan
              shadow_data[nan_ind2,3] = !values.f_nan
              desc[nan_ind2,0] = !values.f_nan
              desc[nan_ind2,1] = !values.f_nan
              angles[nan_ind2,0] = !values.f_nan
              angles[nan_ind2,1] = !values.f_nan
        endif
      
        ;Orientation variables:
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_shadow_orient'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Position of Sun in the MAVEN s/c frame, in spherical co-ordinates.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
        dlimit2.y_Var_notes = 'Spherical co-ordinates in units of degrees; first row is angle from MAVEN Z axis [0-180 range]; second row is clock angle from MAVEN +Y axis [0-360 range]. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.'
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: More information'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'
                     
        dlimit2.scalemin = 0.
        dlimit2.scalemax = 360.
        dlimit2.ysubtitle='[Degrees]'
        limit2.ytitle='Sun direction wrt s/c'
        limit2.yrange=[-10., 370.]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_shadow_orient', data={x:unix_in, y:orient, flag:shad_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_shadow_orient', labels=['Phi', 'Theta']
        ;------------------------------------
      
        ;Shadow variables:
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_shadow'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Percentage that each boom and sensor is in shadow.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
        dlimit2.y_Var_notes = 'First row is +Y boom; second row is +Y sensor; third row is -Y boom; fourth row is -Y sensor. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.'
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: More information'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'
                
        dlimit2.scalemax = 100.
        dlimit2.ysubtitle='[%]'
        limit2.ytitle='Shadow percentage'
        limit2.yrange=[-10., 110.]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_shadow', data={x: unix_in, y:shadow_data, flag:shad_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_shadow', labels=['boom 1 (+Y)', 'sen 1 (+Y)', 'boom 2 (-Y)', 'sen 2 (-Y)']
        options, 'mvn_lpw_anc_boom_shadow', colors=[0, 2, 4, 6]
        ;------------------------------------
      
      
        ;Description variables:
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_shadow_desc'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Description of shadow profile.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
                    s1 = '0: whole boom and whole sensor in shadow. 1: whole boom in shadow, whole sensor in sun. 2: whole boom in sun, whole sensor in shadow. '
                    s2 = '3: boom partly in shadow from base out, sensor all in sun. 4: boom all in shadow, sensor partly in shadow from base out. '
                    s3 = '5: boom partly in shadow, not from base out, sensor all in shadow. 6: boom all in sun, sensor partly in sun, not from base out. '
                    s4 = '7: boom and sensor both fully sunlit.'
        dlimit2.y_Var_notes = s1+s2+s3+s4
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: More information'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'
                
        dlimit2.scalemax = max(desc, /nan)
        dlimit2.ysubtitle = '[Case #]'
        limit2.ytitle = 'Description'
        limit2.yrange=[-1, 11]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_shadow_desc', data={x: unix_in, y:desc, flag:shad_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_shadow_desc', labels=['Boom+sen 1 (+Y)', 'Boom+sen 2 (-Y)']
        ;------------------------------------
      
        ;Sun-boom angles:
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_shadow_angles'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Absolute angle between Sun vector and boom vector, in the MAVEN s/c frame, in degrees.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
        dlimit2.y_Var_notes = 'First row is +Y boom; second row is -Y boom. Sensor and boom vectors are aligned so that this also doubles as the absolute Sun-sensor angle. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.'
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: More information'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'
        
        dlimit2.scalemax = 180.
        dlimit2.ysubtitle='[Degrees]'
        limit2.ytitle = 'Sun-boom/sensor angle'
        limit2.yrange=[-0., 180.]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_shadow_angles', data={x: unix_in, y: angles, flag:shad_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_shadow_angles', labels=['Boom/sen 1 (+Y)', 'Boom/sen 2 (-Y)']
        ;------------------------------------
      endelse  ;lut present

endif  ;over shadow, yes1 eq 1



if yes2 eq 1 then begin
      ;============
      ;--- Wake ---
      ;============
      ;Read in LUT:
      ;Use an ASCII file:
      mvn_lpw_anc_boom_get_luts, lut, /wake  ;get shadow LUT
      
      if n_elements(lut) eq 1 then print, "### mvn_lpw_anc_boom_shadow_wake ###: WAKE LUT ERROR: no wake LUT loaded. No tplot variables produced for wake info." else begin ;#### permanent fix here
      
        ;Columns in the LUT for wake: phi, theta, distance 1, distance 2, wake 1 (1 = inside, 0 = outisde wake), wake 2, hh1, hh2, ll1, ll2.
        ;hh1 is perp distance from sensor to wake vector passing through center of s/c.
        ;ll1 is parallel distance from sensor to center of s/c, based on wake vector passing through center. +ve value means in front of s/c,
        ;-ve means behind s/c. If values is +ve, the ray trace may never see the s/c as sensor is in front of s/c. If this happens, default is
        ;to put max distance from wake, 9.5 meters I think.
      
        dlimit2 = dl1  ;make copies to edit here
        limit2 = ll1
      
        ;S/c velocity. Note, during cruise, using MSO co-ords will probably give weird results, and vice versa. Maybe put in a keyword to detect
        ;if we're in cruise or not based on position?
        vx = dd1.y[*,0]
        vy = dd1.y[*,1]
        vz = dd1.y[*,2]
        magvsc = sqrt(vx^2 + vy^2 + vz^2)  ;magnitude
        vx = vx/magvsc   ;make unit vectors
        vy = vy/magvsc
        vz = vz/magvsc
        
        ;Normalize these co-ordinates to the MAVEN MSO vel in km/s:
        get_data, 'mvn_lpw_anc_mvn_vel_mso', data=ddmso
        if n_elements(dd1.x) ne n_elements(ddmso.x) or n_elements(dd1.x) ne n_elements(unix_in) then begin  ;assume that dd1.x and mso.x are the same length, I'm not sure how they couldn't be.
          print, proname, " #### WARNING #### : number of data elements in mvn_lpw_anc_mvn_vel_sc, mvn_lpw_anc_mvn_pos_mso or unix_in are not"
          print, "equal. Make sure these are all the same length - obtain these using mvn_lpw_anc_spacecraft.pro. Exiting."
          retall
        endif
        
        magv = sqrt(ddmso.y[*,0]^2 + ddmso.y[*,1]^2 + ddmso.y[*,2]^2)  ;magnitude of the maven MSO velocity in km/s
        vx = vx*magv  ;convert MAVEN frame velocities into MSO magnitudes in km/s
        vy = vy*magv
        vz = vz*magv
        
        ;------------
        if keyword_set(flow) then begin
            ;Add external flow to this vector: use 'flow'
            if n_elements(flow[0,*]) eq 1. then begin  ;assume one flow speed for all times
                vx = vx + flow[0]  ;flow is in km/s
                vy = vy + flow[1]
                vz = vz + flow[2]
            endif
            if n_elements(flow[0,*]) gt 1 then begin  ;different flow speed at each time
                for qq = 0, n_elements(flow[0,*]) -1 do begin
                    vx[qq] = vx[qq] + flow[0,qq]
                    vy[qq] = vy[qq] + flow[1,qq]
                    vz[qq] = vz[qq] + flow[2,qq]                  
                endfor             
            endif
        endif  ;keyword flow
        
        ;---------------------------------
        ;First take mvn velocity and convert it into a phi / theta direction
        r = sqrt(vx^2 + vy^2 + vz^2)
        
        ;Old code used atan2, not in IDL library:
      ;  theta = atan2(vy, vx, /deg)
      ;  ;Range of theta is -180 => 180. Must convert this to 0 => 360. A result 0=>180 is fine. -175==185; -90==270, -5==355, etc.
      ;  rind = where(theta lt 0., nrind)  ;find elements lt 0
      ;  if nrind gt 0 then theta[rind] = 180 + (180 - abs(theta[rind]))  ;convert them to +ve degrees from +x axis
      
        ;New code, using atan, from IDL database:
        theta = atan(vy,vx)*(180./!pi)  ;convert to degrees
        inds = where(vy lt 0., ninds)
        if ninds gt 0 then theta[inds] = 360. - abs(theta[inds])  ;take into account sectors from atan.      
      
        phi = (acos(vz / r)) * (180.D/!pi)
        ;---------------------------------
      
        ;---------------------------------
        ;Locate position in LUT and read:
        ;The resolution of the grid is known, 5 degrees currently:
        ;There are 72 theta bins for each of the 36 phi bins.
        res_th = 72.
        res_ph = 36.
        p_ind = (floor((phi/180.)*res_ph))*res_th
        t_ind = (floor((theta/360.)*res_th))

        ;Check for nans here as floor will produce weird large numbers and has no /nan option:
        nan_ind1 = finite(phi, /nan)
        if total(nan_ind1) gt 0 then begin
          nan_ind2 = where(nan_ind1 eq 1)
          p_ind[nan_ind2] = !values.f_nan
          t_ind[nan_ind2] = !values.f_nan
        endif
      
        ind = p_ind + t_ind
      
        phi2 = lut[0,ind]
        theta2 = lut[1,ind]
      
        orient = dblarr(nele_time,2)
        orient[*,0] = transpose(phi) ;use actual values, not LUT ones
        orient[*,1] = transpose( theta)
      
        d = dblarr(nele_time,2)
        d[*,0] = lut[2,ind]
        d[*,1] = lut[3,ind]
      
        wake = dblarr(nele_time,2)
        wake[*,0] = lut[4,ind]
        wake[*,1] = lut[5,ind]
      
        hh = dblarr(nele_time,2)
        hh[*,0] = lut[6,ind]
        hh[*,1] = lut[7,ind]
      
        ll = dblarr(nele_time,2)
        ll[*,0] = lut[8,ind]
        ll[*,1] = lut[9,ind]
        
        ram_angle = fltarr(nele_time,2)
        ram_angle[*,0] = lut[10,ind]
        ram_angle[*,1] = lut[11,ind]
        
        ;Correct for NaNs in data:
        if nan_shad gt 0 then begin
          orient[nan_ind2,0] = !values.f_nan
          orient[nan_ind2,1] = !values.f_nan
          d[nan_ind2,0] = !values.f_nan
          d[nan_ind2,1] = !values.f_nan
          wake[nan_ind2,0] = !values.f_nan
          wake[nan_ind2,1] = !values.f_nan
          hh[nan_ind2,0] = !values.f_nan
          hh[nan_ind2,1] = !values.f_nan
          ll[nan_ind2,0] = !values.f_nan
          ll[nan_ind2,1] = !values.f_nan
          ram_angle[nan_ind2,0] = !values.f_nan
          ram_angle[nan_ind2,1] = !values.f_nan
        endif
        
        ;------------------------------------      
        ;Create tplot variables:
      
        ;Phi, theta values (for checking)
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_wake_orient'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Velocity vector of MAVEN, in the MAVEN s/c frame, in spherical co-ordinates.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
        dlimit2.y_Var_notes = 'Spherical co-ordinates in units of degrees; first row is angle from MAVEN Z axis [0-180 range]; second row is clock angle from MAVEN +Y axis [0-360 range]. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.'
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: More information'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'
        
        dlimit2.scalemax = max(orient)
        dlimit2.ysubtitle = '[degrees]'
        limit2.ytitle = 'Wake direction wrt s/c'
        limit2.yrange=[0, 1.2*max(orient, /nan)]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_wake_orient', data={x: unix_in, y:orient, flag:wake_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_wake_orient', labels=['Phi', 'Theta']
        ;------------------------------------
      
        ;Distances:
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_wake_d_sc'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Approximate geometric distances (in meters) between booms and wake, based on s/c velocity and geometry only.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
        dlimit2.y_Var_notes = 'First row is +Y boom; second row is -Y boom. Only s/c velocity and geometry has been considered. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.'
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: More information'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'
        
        dlimit2.scalemax = max(d)
        dlimit2.ysubtitle = '[m]'
        limit2.ytitle = 'Distance-from_wake'
        limit2.yrange=[0, 1.2*max(d, /nan)]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_wake_d_sc', data={x: unix_in, y:d, flag:wake_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_wake_d_sc', labels=['Sensor 1 (+Y)', 'Sensor 2 (-Y)']
        ;------------------------------------
      
        ;Wake or not:
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_wake'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Shows whether each boom is within the s/c geometric wake or not. 0: outside wake. 1: inside wake.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
        dlimit2.y_Var_notes = 'First row is +Y boom; second row is -Y boom. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.'
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: 0: outside, 1: inside.'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'
        dlimit2.scalemax = max(d)
        dlimit2.ysubtitle = '[1=Y, 0=N]'
        limit2.ytitle = 'Wake'
        limit2.yrange=[-1, 2]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_wake', data={x: unix_in, y:wake, flag:wake_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_wake', labels=['Sensor 1 (+Y)', 'Sensor 2 (-Y)']
        ;------------------------------------
      
        ;hh:
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_wake_d_perp'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Perpendicular distance (in meters) between wake vector passing through center of s/c, and each sensor tip, based on s/c velocity and geometry only.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
        dlimit2.y_Var_notes = 'First row is +Y boom; second row is -Y boom. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.'
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: More information'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'
       
        dlimit2.scalemax = max(hh)
        dlimit2.ysubtitle = '[m]'
        limit2.ytitle = 'Perp distance'
        limit2.yrange=[min(hh, /nan), 1.2*max(hh, /nan)]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_wake_d_perp', data={x: unix_in, y:hh, flag:wake_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_wake_d_perp', labels=['Sensor 1 (+Y)', 'Sensor 2 (-Y)']
        ;------------------------------------
      
        ;ll:
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_wake_d_para'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Parallel distance (in meters) between wake vector passing through center of s/c, and the tip of each boom, based on s/c velocity and geometry only.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
        dlimit2.y_Var_notes = 'First row is +Y boom; second row is -Y boom. A positive value means sensor is in front of s/c wrt motion, a negative value means sensor is behind s/c wrt motion. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.'
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: More information'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'
        
        dlimit2.scalemax = max(ll)
        dlimit2.ysubtitle = '[m]'
        limit2.ytitle = 'Para distance'
        limit2.yrange=[min(ll, /nan), 1.2*max(ll, /nan)]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_wake_d_para', data={x: unix_in, y:ll, flag:wake_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_wake_d_para', labels=['Sensor 1 (+Y)', 'Sensor 2 (-Y)']
        ;------------------------------------
      
        ;RAM-boom angles:
        ;------------------------------------
        dlimit2.Product_name = 'mvn_lpw_anc_boom_shadow_ram_angles'
        dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
        dlimit2.y_catdesc = 'Absolute angle between RAM vector and boom/sensor vector, in the MAVEN s/c frame, in degrees.'
        ;dlimit2.v_catdesc = 'test dlimit file, v'
        dlimit2.dy_catdesc = 'Error on the data.'
        ;dlimit2.dv_catdesc = 'test dlimit file, dv'
        dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
        dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
        dlimit2.y_Var_notes = 'First row is +Y boom; second row is -Y boom. Sensor and boom vectors are aligned so that this also doubles as the absolute RAM-sensor angle. MAVEN s/c frame: +Z is aligned with the main antenna. Y runs along the solar panels. X completes the system.'
        ;dlimit2.v_Var_notes = 'Frequency bins'
        dlimit2.dy_Var_notes = 'Not used.'
        ;dlimit2.dv_Var_notes = 'Error on frequency'
        dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
        dlimit2.xFieldnam = 'x: More information'
        dlimit2.yFieldnam = 'y: More information'
        ;dlimit2.vFieldnam = 'v: More information'
        dlimit2.dyFieldnam = 'dy: Not used.'
        ;dlimit2.dvFieldnam = 'dv: More information'
        dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'

        dlimit2.scalemax = 180.
        dlimit2.ysubtitle='[Degrees]'
        limit2.ytitle = 'RAM-boom/sensor angle'
        limit2.yrange=[-0., 180.]
        ;------------------------------------
        store_data, 'mvn_lpw_anc_boom_wake_ram_angles', data={x: unix_in, y: ram_angle, flag:wake_flag}, dlimit=dlimit2, limit=limit2
        options, 'mvn_lpw_anc_boom_wake_ram_angles', labels=['Boom/sen 1 (+Y)', 'Boom/sen 2 (-Y)']
              
      endelse  ;lut present
endif  ;over wake, yes2 eq 1

end