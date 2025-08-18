;+
; FUNCTION:
;         mms_part_des_photoelectrons
;
; PURPOSE:
;         Loads and returns the FPI/DES photoelectron model based on stepper ID
;
; INPUT:
;         dist_var: DES distribution data
;         
;
; NOTES:
;         see: https://agupubs.onlinelibrary.wiley.com/doi/full/10.1002/2017JA024518
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-07-08 07:52:14 -0700 (Wed, 08 Jul 2020) $
;$LastChangedRevision: 28860 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_des_photoelectrons.pro $
;-

function mms_part_des_photoelectrons, dist_var
  mms_init ; !mms should already be loaded, but just in case
  
  get_data, dist_var, data=d, dlimits=dl

  ; need the data rate
  data_rate = (strsplit(dist_var, '_', /extract))[n_elements(strsplit(dist_var, '_', /extract))-1]
  
  if ~is_struct(dl) || data_rate eq '' then begin
    dprint, dlevel = 0, 'Error reading distribution data; this should never happen - please let me know: egrimes@igpp.ucla.edu'
    return, -1
  endif
  
  ; (1) Determine the energy table tag used for the time period of interest
  str_element, dl.cdf.gatt, 'energy_table_name', table_name
  stepper_id = strsplit(table_name, 'energies_des', /extract)
  stepper_id = STRMID(stepper_id[0], 0L, (STRPOS(stepper_id[0], '.'))[0])

  ; download the model file from the SDC
  pe_model = spd_download(remote_file='https://lasp.colorado.edu/mms/sdc/public/data/models/fpi/mms_fpi_'+data_rate+'_l2_des-bgdist_v?.?.?_p'+stepper_id+'.cdf', $
    local_path=!mms.local_data_dir + '/mms/sdc/public/data/models/fpi/', /last_version, /valid_only)

  if pe_model[0] eq '' then begin
    dprint, dlevel = 0, 'Error, DES photoelectron model file not found; the model is missing from the SDC'
    return, -1
  endif
  
  mms_cdf2tplot, pe_model[0], /all

  if data_rate eq 'fast' then begin
    get_data, 'mms_des_bgdist_fast', data=bg_dist
    get_data, 'mms_des_numberdensity_fast', data=nphoto
    return, {bg_dist: bg_dist, n: nphoto}
  endif else if data_rate eq 'brst' then begin
    get_data, 'mms_des_bgdist_p0_brst', data=bg_dist_0
    get_data, 'mms_des_bgdist_p1_brst', data=bg_dist_1
    get_data, 'mms_des_numberdensity_p0_brst', data=nphoto_0
    get_data, 'mms_des_numberdensity_p1_brst', data=nphoto_1
    return, {bgdist_p0: bg_dist_0, bgdist_p1: bg_dist_1, n_0: nphoto_0, n_1: nphoto_1}
  endif
  
  dprint, dlevel = 0, 'Error - something went wrong with the photoelectron model'
  return, -1
end

