;
;  $LastChangedBy: pulupa $
;  $LastChangedDate: 2017-07-11 16:45:28 -0700 (Tue, 11 Jul 2017) $
;  $LastChangedRevision: 23582 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_survey/spp_fld_magi_survey_load_l1.pro $
;

pro spp_fld_magi_survey_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_magi_survey_'

  spp_fld_mag_survey_load_l1, file, prefix = prefix

  magi_survey_names = tnames(prefix + '*')

  if magi_survey_names[0] NE '' then begin

    for i = 0, n_elements(magi_survey_names) - 1 do begin

      options, magi_survey_names[i], 'colors', [6]
      options, magi_survey_names[i], 'symsize', 0.5

    endfor

  endif

end