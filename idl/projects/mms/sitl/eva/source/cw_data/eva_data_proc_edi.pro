PRO eva_data_proc_edi, sc_id
  if n_elements(sc_id) gt 1 then message, 'Please specify one spacecraft.'
  
  ;-----------------------------------------------------
  ; EDI \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  ;-----------------------------------------------------
  ;Instead of plotting counts from GDU1 and GDU2, plot
  ;0 & 180 degree pitch angle counts.
  get_data, sc_id + '_edi_pitch_gdu1',           DATA=pitch_gdu1
  get_data, sc_id + '_edi_pitch_gdu2',           DATA=pitch_gdu2
  get_data, sc_id + '_edi_amb_gdu1_raw_counts1', DATA=counts_gdu1
  get_data, sc_id + '_edi_amb_gdu2_raw_counts1', DATA=counts_gdu2


  ;-----------------------------------------------------
  ; EDI: Sort By Pitch Angle 0 \\\\\\\\\\\\\\\\\\\\\\\\\
  ;-----------------------------------------------------
  ;Find 0 and 180 pitch angles
  igdu1_0   = where(pitch_gdu1.y eq   0, ngdu1_0)
  igdu2_0   = where(pitch_gdu2.y eq   0, ngdu2_0)
  igdu1_180 = where(pitch_gdu1.y eq 180, ngdu1_180)
  igdu2_180 = where(pitch_gdu2.y eq 180, ngdu2_180)

  ;Select 0 pitch angle
  if ngdu1_0 gt 0 && ngdu2_0 gt 0 then begin
    t_0      = [ counts_gdu1.x[igdu1_0], counts_gdu2.x[igdu2_0] ]
    counts_0 = [ counts_gdu1.y[igdu1_0], counts_gdu2.y[igdu2_0] ]

    ;Sort times
    isort    = sort(t_0)
    t_0      = t_0[isort]
    counts_0 = counts_0[isort]

    ;Mark GDU
    gdu_0          = bytarr(ngdu1_0 + ngdu2_0)
    gdu_0[igdu1_0] = 1B
    gdu_0[igdu2_0] = 2B

    ;Only GDU1 data
  endif else if ngdu1_0 gt 0 then begin
    t_0      = counts_gdu1.x[igdu1_0]
    counts_0 = counts_gdu1.y[igdu1_0]
    gdu_0    = replicate(1B, ngdu1_0)

    ;Only GDU2 data
  endif else if ngdu2_0 gt 0 then begin
    t_0      = counts_gdu2.x[igdu2_0]
    counts_0 = counts_gdu2.y[igdu2_0]
    gdu_0    = replicate(2B, ngdu2_0)
  endif

  ;Store data
  if n_elements(counts_0) gt 0 $
    then store_data, sc_id + '_edi_amb_pa0_raw_counts', DATA={x: t_0, y: counts_0}

  ;Set options
  options, sc_id + '_edi_amb_pa0_raw_counts', 'ylog', 1

  ;-----------------------------------------------------
  ; EDI: Sort By Pitch Angle 180 \\\\\\\\\\\\\\\\\\\\\\\
  ;-----------------------------------------------------

  ;Select 180 pitch angle
  if ngdu1_180 gt 0 && ngdu2_180 gt 0 then begin
    t_180      = [ counts_gdu1.x[igdu1_180], counts_gdu2.x[igdu2_180] ]
    counts_180 = [ counts_gdu1.y[igdu1_180], counts_gdu2.y[igdu2_180] ]

    ;Sort times
    isort    = sort(t_180)
    t_180      = t_180[isort]
    counts_180 = counts_180[isort]

    ;Mark GDU
    gdu_180            = bytarr(ngdu1_180 + ngdu2_180)
    gdu_180[igdu1_180] = 1B
    gdu_180[igdu2_180] = 2B

    ;Only GDU1 data
  endif else if ngdu1_180 gt 0 then begin
    t_180      = counts_gdu1.x[igdu1_180]
    counts_180 = counts_gdu1.y[igdu1_180]
    gdu_180    = replicate(1B, ngdu1_180)

    ;Only GDU2 data
  endif else if ngdu2_180 gt 0 then begin
    t_180      = counts_gdu2.x[igdu2_180]
    counts_180 = counts_gdu2.y[igdu2_180]
    gdu_180    = replicate(2B, ngdu2_180)
  endif

  ;Store data
  if n_elements(counts_180) gt 0 $
    then store_data, sc_id + '_edi_amb_pa180_raw_counts', DATA={x: t_180, y: counts_180}

  ;Set options
  options, sc_id + '_edi_amb_pa180_raw_counts', 'ylog', 1

END