;+
; PROCEDURE:
;         mms_fpi_dist_angles
;
; PURPOSE:
;         Returns the azimuth/colatitude for FPI sky maps.
;
; NOTE:
;         Angle values describe the instrument look directions.
;         This routine might be obsolete once the angles are added to the data CDFs.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-09-02 17:52:09 -0700 (Fri, 02 Sep 2016) $
;$LastChangedRevision: 21796 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_dist_angles.pro $
;-

pro mms_fpi_dist_angles, probe=probe, level=level, data_rate=data_rate, species=species, $
                         suffix=suffix, phi=phi, theta=theta

    compile_opt idl2, hidden


  ;ensure output is correct or undefined
  undefine, phi, theta
  
  ;probe/level/rate/species should already be defined & filtered
  if undefined(suffix) then suffix = ''

  ;no supplementary variables for l1 data
  if level ne 'l2' then begin
    info = mms_get_fpi_info()
    phi = info.azimuth
    theta = info.elevation ;colatitude
    return
  endif

  ;get l2 angles
  get_data, 'mms'+probe+'_d'+species+'s_phi_'+data_rate+suffix, ptr=phi_ptr
  get_data, 'mms'+probe+'_d'+species+'s_theta_'+data_rate+suffix, ptr=theta_ptr

  if ~is_struct(phi_ptr) || ~is_struct(theta_ptr) then begin
    dprint, dlevel=0, 'Cannot find tplot variables containing azimuth/elevation data'
    return
  endif

  phi = *phi_ptr.y

  theta = *theta_ptr.y 

end