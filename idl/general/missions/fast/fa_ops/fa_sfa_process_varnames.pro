Function fa_sfa_process_varnames
;Variable list for SFA, sdt dqd, then tplot_name
  a = ['FastFieldsMode_1036 fa_fieldsmode_1036', $
       'FastFieldsMode_1036 fa_fieldsmode_1057', $
;       'SfaAveLines fa_sfaave_words', $
;       'SfaAveWord1 fa_sfaave_word1', $
;       'SfaAveWord2 fa_sfaave_word2', $
;       'SfaAveWord3 fa_sfaave_word3', $
;       'SfaAveWord4 fa_sfaave_word4', $
       'SfaAve_Mag3AC fa_sfaave_mag3ac', $
       'SfaAve_V1-V2 fa_sfaave_e12', $
       'SfaAve_V1-V4 fa_sfaave_e14', $
       'SfaAve_V3-V4 fa_sfaave_e34', $
       'SfaAve_V5-V6 fa_sfaave_e56', $
       'SfaAve_V5-V8 fa_sfaave_e58', $
       'SfaAve_V7-V8 fa_sfaave_e78', $
       'SfaAve_V9-V10 fa_sfaave_v910', $
;       'SfaBurstLines fa_sfaburst_words', $
;       'SfaBurstWord1 fa_sfaburst_word1', $
;       'SfaBurstWord2 fa_sfaburst_word2', $
;       'SfaBurstWord3 fa_sfaburst_word3', $
;       'SfaBurstWord4 fa_sfaburst_word4', $
       'SfaBurst_Mag3AC fa_sfaburst_mag3ac', $
       'SfaBurst_V1-V2 fa_sfaburst_e12', $
       'SfaBurst_V1-V4 fa_sfaburst_e14', $
       'SfaBurst_V3-V4 fa_sfaburst_e34', $
       'SfaBurst_V5-V6 fa_sfaburst_e56', $
       'SfaBurst_V5-V8 fa_sfaburst_e58', $
       'SfaBurst_V7-V8 fa_sfaburst_e78', $
       'SfaBurst_V9-V10 fa_sfaburst_e910']

  na = n_elements(a)
  b = strarr(2, na)
  For j = 0, na-1 Do b[*, j] = strsplit(a[j], ' ', /extract)

  Return, b

End

