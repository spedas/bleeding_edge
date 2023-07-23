;+
;Procedure: ta15n_ta16_crib
;
;Purpose:  Compare TA15n model to TA16 model
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2022-10-06 09:42:40 -0700 (Thu, 06 Oct 2022) $
; $LastChangedRevision: 31156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta16/ta15n_ta16_crib.pro $
;-

pro ta15n_ta16_crib

  ; Set time range

  if ta16_supported() eq 0 then begin
    dprint, "You need to install GEOPACK 10.9 or higher for the crib."
    return
  endif

  timespan,'2007-03-23',1,/day

  ; Load THEMIS positions
  thm_load_state,probe='a',datatype='pos',coord='GSM'
  get_data,'tha_state_pos',data=d
  times=d.x

  ; Load OMNI data

  ; The N-index parameter must be seeded with 30 minutes of solar wind data prior to the first time of interest.
  timespan,'2007-03-22/23:30',24.5,/hours
  omni_load_data,varformat='*BY_GSM *BZ_GSM *flow_speed *proton_density *Pressure *SYM_H',/res5min

  ;  If no trange parameter is passed, tomni2nindex uses the timerange() command to get start/stop times for the
  ;  grid of 5-minute timestamps used internally and for the n_index output.  It doesn't look at the timestamps of
  ;  the solar wind variables, so beware of any intervening timespan calls between loading the OMNI data and
  ;  calling tomni2nindex.

  tomni2nindex,yimf_tvar='OMNI_HRO_5min_BY_GSM',zimf_tvar='OMNI_HRO_5min_BZ_GSM',V_p_tvar='OMNI_HRO_5min_flow_speed', $
    newname='n_index'

  ; Calculate the sliding average of Sym-H
  symh2symc, symh='OMNI_HRO_5min_SYM_H', pdyn='OMNI_HRO_5min_Pressure', trange=trange, newname='OMNI_HRO_5min_SYM_C'

  ; Plot
  tplot,'OMNI_HRO_5min_BY_GSM OMNI_HRO_5min_BZ_GSM OMNI_HRO_5min_flow_speed n_index OMNI_HRO_5min_Pressure OMNI_HRO_5min_SYM_H OMNI_HRO_5min_SYM_C'

  stop

  ; Calculate the field at the S/C positions, using the OMNI pressure data using the TA15N model.
  tta15n,'tha_state_pos',pdyn='OMNI_HRO_5min_Pressure',yimf='OMNI_HRO_5min_BY_GSM',zimf='OMNI_HRO_5min_BZ_GSM',xind='n_index'

  ; Calculate the field using the TA16 model.
  tta16,'tha_state_pos',pdyn='OMNI_HRO_5min_Pressure',yimf='OMNI_HRO_5min_BY_GSM',xind='n_index',symc='OMNI_HRO_5min_SYM_C'

  ; Find the difference
  dif_data, 'tha_state_pos_bta15n', 'tha_state_pos_bta16', newname='diff_TA15N_TA16'

  ; Plot
  tplot, ['tha_state_pos_bta15n', 'tha_state_pos_bta16', 'diff_TA15N_TA16']

end