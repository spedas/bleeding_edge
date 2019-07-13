;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2019-07-11 16:06:40 -0700 (Thu, 11 Jul 2019) $
;  $LastChangedRevision: 27437 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_survey/spp_fld_mago_survey_load_l1.pro $
;

pro spp_fld_mago_survey_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_mago_survey_'

  spp_fld_mag_survey_load_l1, file, prefix = prefix, varformat = varformat

  mago_survey_names = tnames(prefix + '*')

  if mago_survey_names[0] NE '' then begin

    for i = 0, n_elements(mago_survey_names) - 1 do begin

      options, mago_survey_names[i], 'colors', [2]
      options, mago_survey_names[i], 'symsize', 0.5

    endfor

  endif
  
  options, prefix + 'nT', 'colors', 'rgb'
  options, prefix + 'nT_mag', 'colors'
  

end