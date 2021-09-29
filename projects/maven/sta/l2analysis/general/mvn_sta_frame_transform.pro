;+
;Routine that can be used to subtract the MAVEN spacecraft velocity, and/or plasma flow velocity, from a STATIC data structure,
;to transform to a new reference frame.
;
;One can input the spacecraft velocity vector and/or plasma flow velocity, which will be subtracted from the data structure. This 
;routine can also calculate the spacecraft velocity vector using SPICE, but it will not calculate the plasma flow vector, as this 
;requires assumptions about the dominant species, whether multiple populations exist, etc, that must be made by the user.
;
;
;INPUTS:
;ddd: STATIC data structure for a single timestamp. Obtained by using e.g. dat=mvn_sta_get_c6()
;
;
;KEYWORDS:
;sc_vector: float: 3D vector containing the spacecraft velocity vectory in the MSO coordinate system (known as "MAVEN_MSO"
;           in SPICE). This is the spacecraft velocity that will be used to transform to the local frame. If not set, this routine
;           will calculate this vector using the timestamp in the input ddd STATIC data structure. One can also set sc_vector=1,
;           and this routine will calculate sc_vector for you using SPICE (you must have set timespan beforehand though). sc_vector
;           must have units of km/s.
;
;flow_vector: float: 3D vector containing the plasma flow vector in the MSO coordinate system (known as "MAVEN_MSO" in SPICE).
;             if set, this vector will be subtracted from the STATIC data, transforming the data to the plasma rest frame. 
;             flow_vector must have units of km/s.
;            
;
;scpot: float: force the spacecraft potential to this value (units of eV). If not set, use the default value in the STATIC data 
;              structures (determined from the STATIC data). IT IS STRONGLY RECOMMENDED that you use the default value.
;
;success: set this keyword to a variable. On return, 0 = routine was not successful; 1 = it was.
;
;
;CAVEATS:
;- Frame transformation can only be done on STATIC apids that contain theta and phi information. These are apids ce, cf, d0, d1.
;
;EG:
;timespan, '2018-03-03', 1. ;set timespan
;kk = mvn_spice_kernels(/load)  ;load SPICE kernels. mvn_sta_frame_transform will also do this if no kernels are loaded, but it
;                               ;doesn't check the time range of loaded kernels - it goes on the last timerange set by timespan.
;mvn_sta_l2_load, sta_apid='d0' ;load STATIC data that has 3D information (ce, cf, d0 or d1).
;mvn_sta_l2_tplot               ;put into tplot
;dat = mvn_sta_get_d0()         ;use ctime to pick a timestamp to look at. dat is now the STATIC data structure at that time.
;
;result = mvn_sta_frame_transform(dat, /sc_vector)  ;apply sc velocity correction to dat structure.
;                                                   ;result is the new STATIC data structure, with updated theta, phi and energy arrays.
;
;
;
;.r /Users/cmfowler/IDL/STATIC_routines/Generic/mvn_sta_frame_transform.pro ;for testing
;-
;

function mvn_sta_frame_transform, ddd, sc_vector=sc_vector, flow_vector=flow_vector, scpot=scpot, success=success

proname = 'mvn_sta_frame_transform'

;Check apid:
if ddd.ndef eq 1 or ddd.nanode eq 1 then begin
   print, proname, ": you must use a STATIC apid that contains theta and phi information: ce, cf, d0 or d1."
   success=0
   return, 0
endif

dat0 = ddd ;copy variable
tmid = 0.5*(dat0.time + dat0.end_time)  ;mid timestamp of STATIC data

;SPICE: will be needed for rotations:
spicekernels = mvn_sta_anc_determine_spice_kernels()  ;find which SPICe kernels are loaded

;Load SPICE if not kernels found. Note, this isn't clever enough to check the time range of any kernels already loaded - it assumes
;if SPICE is loaded, the kernels are the correct ones
if spicekernels.nTOT eq 0 then kk = mvn_spice_kernels(/load)  ;Load SPICE if not 

;Calculate spacecraft velocity vector if not input:
if keyword_set(sc_vector) then begin
    case n_elements(sc_vector) of
      1: sc_vector = spice_body_vel('MAVEN', 'MARS', utc=tmid, frame='MAVEN_MSO')  ;Calculate MAVEN velocity in Mars MSO frame
      3:   ;do nothing at this stage
      else: begin
              print, proname, ": sc_vector must be set to 1 or a 3 element float vector in the MSO coordinate system."
              success=0
              return, 0.
            endelse
    endcase
    
    ;Rotate sc vector from MSO to STATIC frame:
    v_sc_sta = spice_vector_rotate(sc_vector, tmid, 'MAVEN_MSO', 'MAVEN_STATIC')  ;rotate velocity from MSO to STATIC frame
    v_sc_sta *= -1.  ;reverse sign as flow is in opposite direction to s/c motion.
endif


;Remove bulk flow velocity if input:
if keyword_set(flow_vector) then begin
    if n_elements(flow_vector) ne 3 then begin
        print, proname, ": flow_vector must be a 3 element float vector in the MSO coordinate system."
        success=0
        return, 0.
    endif
    
    v_flow_sta = spice_vector_rotate(transpose(v_flow_mso), tmid, 'MAVEN_MSO', 'MAVEN_STATIC')  ;rotate plasma flow from MSO to STATIC frame

    v_flow_sta *= -1.  ;I think I need this - check
endif else v_flow_sta = [0., 0., 0.]

;Total vector to correct for (km/s):
v_correct = v_sc_sta + v_flow_Sta

;Spacecraft potential:
if keyword_set(sc_pot) then dat0.sc_pot = sc_pot  ;force potential to a specified value
if finite(dat0.sc_pot) eq 0 then dat0.sc_pot = 0.  ;make sure sc_pot is a real number.

;Correct f(v) for sc_pot and sc vel:
dat1 = mvn_sta_convert_vframe(dat0, v_correct)

badbin = WHERE(~FINITE(dat1.energy), nbad)  ;remove bad energy bins - this can happen via convert_vframe if energies become negative
IF nbad GT 0 THEN dat1.bins[badbin] = 0

success=1

return, dat1

end

