;+
;Routine inspired by Takuya Hara's mvn_sta_updown_dir.pro, to calculate which STATIC bins look within a specified cone angle, look direction
;and coordinate system.
;
;This routine will determine if SPICE kernels are loaded or not. If not, it will load them automatically, based on the timespan set.
;
;INPUTS / KEYWORDS:
;   dat: STATIC data structure, use eg dat=mvn_sta_get_d1(index=100)
;   sta_apid: string, the STATIC APID to use. This routine requires one that has anode and defeltor dimensions: 'ce', 'cf', 'd0', 'd1'. The default
;             is 'd0' if not set.
;
;   searchvector: 3D float vector array in the specified coordinate system, [x,y,z]. The routine will find which STATIC bins look in this direction, 
;                 within a cone angle of "coneangle". Default if not set is [-1,0,0], which is tailward in the MSO coordinate system. A note on
;                 +- convention: you must define the direction of flow you want to capture. For eg, to find which STATIC bins are facing the
;                 Sun (and will observe the solar wind), searchvector=[-1., 0., 0.], fromframe='MAVEN_MSO'.
;                 
;   coneangle: the cone angle in degrees around searchvector; the routine identifies which STATIC bins fall within this cone angle. Default if not set
;              is coneangle=30 degrees.  
;              A value of zero degrees means only bins exactly parallel to searchvector are included. A value of 45 means bins within 45 degrees of
;              searchvector are included. A value of 180 means all bins are included.
;   
;   fromframe: string: the frame in which searchvector is specified. Available frames are defined in the MAVEN SPICE documentation. The default if
;              this keyword is not set is 'MAVEN_MSO', which is the MSO coordinate system.
;   
;OUTPUT: data structure the same dimensions as dat.data (for a single timestamp). 0 = that bin lies outside the desired look direction, 1 = that
;         bin lies within the desired look direction.
;              
;EXAMPLE:
;timespan, '2020-01-01', 1.
;mvn_sta_l2_load, sta_apid='d0'
;mvn_sta_l2_tplot
;kk=mvn_spice_kernels(/load)
;i=100 ;define which indice/timestamp to grab
;dat=mvn_sta_get_d0(index=i)
;result = mvn_sta_find_bin_directions(dat, sta_apid='d0', searchvector=[-1.,0.,0.], coneangle=15.)  
;
;This result can then be fed into multiple STATIC analysis routines using the bins keyword. For eg, j_4d(bins=result). j_4d will then calculate
;ion flux for only the bins flagged in "result", enabling users to calculate fluxes in the specified searchvector direction.
;
;
;.r /Users/cmfowler/IDL/STATIC_routines/FOV_routines/mvn_sta_find_bin_directions.pro
;-
;

function mvn_sta_find_bin_directions, dat, sta_apid=sta_apid, success=success, searchvector=searchvector, coneangle=coneangle, fromframe=fromframe

proname = "mvn_sta_find_bin_directions"

if size(dat,/type) ne 8 then begin
  print, proname, ": dat must be a STATIC data strucutre, obtained using eg mvn_sta_get_d0()."
  success=0
  return, 1
endif

if size(coneangle,/type) eq 0 then coneangle=35.  ;default 35 degrees.
if size(searchvector,/type) eq 0 then searchvector = [-1., 0., 0.]
if n_elements(searchvector) ne 3 then searchvector = [-1., 0., 0.]
if not keyword_set(fromframe) then fromframe='MAVEN_MSO'

;Are SPICE kernels loaded?
kernels = mvn_sta_anc_determine_spice_kernels()  ;are SPICE kernels loaded?
if kernels.nTOT eq 0 then kk=mvn_spice_kernels(/load)

r=1.
thetaTMP = dat.theta
phiTMP = dat.phi
sphere_to_cart,r,thetaTMP,phiTMP, xsta, ysta, zsta  ;xsta, ysta, zsta are the same size as dat.theta and dat.phi, but are the x,y,z components.

;==========================
;ROTATE FROM STATIC TO MSO:
;Check when we have SPICE coverage for STATIC rotations:
time0 = (dat.time+dat.end_time)/2d  ;midtime
mvn_sta_ck_check, time0, success=checksuccess  ;SPICE already loaded

;SPICE requires input vectors in [3,N] format, so forloop through STATIC dimensions and use a loop to achieve this:
;xmso = fltarr(dat.nenergy, dat.nbins, dat.nmass)+!values.f_nan  ;these arrays contain the X, Y and Z components of each a-d bin, in MSO coordinates.
;ymso = xmso
;zmso = xmso

;Array to store flag in :
sta_flag_arr = fltarr(dat.nenergy, dat.nbins, dat.nmass)  ;0 means bin lies outside searchvector+coneangle. 1 means bin lies within this.                                           

if checksuccess eq 1 then begin
  get_data, 'mvn_sta_ck_check', data=ddch
  
  if ddch.y[0] eq 0 then begin
      vector_sta = spice_vector_rotate(searchvector,time0,fromframe, 'MAVEN_STATIC')
                  
  endif else begin  ;check=0
      print, proname, ": There wasn't SPICE coverage for this time stamp. I'm skipping it."
      success=0
      return, 1
  endelse 
  
  ;Find which bins fall within coneangle of searchvector:
  adotb = (xsta * vector_sta[0]) + (ysta * vector_sta[1]) + (zsta * vector_sta[2])
  mag_a = sqrt(xsta^2 + ysta^2 + zsta^2)
  mag_b = sqrt(vector_sta[0]^2 + vector_sta[1]^2 + vector_sta[2]^2)
  
  angle = acos(adotb/(mag_a*mag_b)) * 180./!pi  ;in degrees.
  
  ;Only take angles that are < coneangle
  iKP = where(angle le coneangle, niKP)
  if niKP gt 0 then sta_flag_arr[iKP] = 1.
  
  success = 1.

endif else begin
  print, proname, ": There wasn't SPICE coverage for this time stamp. I'm skipping it."
  success=0
  return, 1
endelse

return, sta_flag_arr

end



