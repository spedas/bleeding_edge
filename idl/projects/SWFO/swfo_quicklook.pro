; Function to produce start/end unix time arrays
; that end every X days and begin every Y days

pro plot_intervals, trange, durations,$
  start_time, end_time, end_cadence=end_cadence,center_start=center_start

  ; Make sure trange is in unix time
  trange = time_double(trange)

  ; Construct intervals to load and plot data over:
  durations_s = duration_str2dbl(durations)
  n_durations = n_elements(durations)

  if keyword_set(end_cadence) then begin
    cadence_s = duration_str2dbl(end_cadence)

    ; Create a list of days of days to end each plot on:
    tints = floor(time_double(trange)/cadence_s)
    ; print, tints
    ; print, time_string(tints*cadence_s)
    n_intervals = tints[1] - tints[0]

  endif else begin
    n_intervals = 1
  endelse

  ; empty arrays to fill:
  start_time = dblarr(n_intervals, n_durations)
  ; end_time = dblarr(n_intervals, n_durations)
  end_time = dblarr(n_intervals)

  for i= 0, n_intervals - 1 do begin
    if keyword_set(end_cadence) then tr = (tints[0] + i +[0,1]) *cadence_s else tr=trange
    if keyword_set(center_start) then tr = tr + 86400d

    ; Now make the plot duration times:
    for j=0, n_durations - 1 do begin
      new_tr = [tr[1] - durations_s[j], tr[1]]
      ; plot_tranges[i].add, new_tr
      start_time[i, j] = new_tr[0]
      ; end_time[i, j] = tr[1]
      ; stop
    endfor
    end_time[i] = tr[1]
    ; print, time_String(tr)
  endfor
  ; print, time_string(start_time)
  ; print, time_string(end_time)
  return
end

; +
; PROCEDURE: swfo_quicklook
; PURPOSE:
; Makes and saves plots of SWFO STIS data at given intervals.
; Can be combined with exec to continually produce plots.
; 
; Example usage:
; > swfo_quicklook, plot_types=['summ', 'noise', 'health'],$
;     data_resolution=['30s', '300s', 'fr'],$
;     plot_durations=['1d', '3d', '7d'],$
;     trange=systime(1) + [-3600d*24, 3600d*24]
; Will make summary, noise, and instrument health plots
; for resolutions of 30 seconds, 300 seconds, and the full resolution
; with plot durations of 1 day, 3 days, and 7 days.
; over a time range of 24 hours before now, and 24 hours after now.
; 
; For live plots that are centered on now rather than dailies:
; > swfo_quicklook, plot_types=['summ', 'noise', 'health'],$
;     data_resolution=['30s', '300s', 'fr'],$
;     plot_durations=['1d', '3d', '7d'], /live
;
; Note: ACE plot not working yet.
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2026-08-17 09:27:15 -0700 (Mon, 17 Aug 2026) $
; $LastChangedRevision: 34746 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_quicklook.pro $
; $ID: $

pro swfo_quicklook, trange=trange, plot_cadence=plot_cadence,$
  plot_types=plot_types, destination_dir=destination_dir,$
  data_resolution=data_resolution, plot_durations=plot_durations,$
  show=show, live=live

  ; ACE currently not working on sweapsoc:
  if ~keyword_set(plot_types) then plot_types = ['health', 'summ', 'ace', 'noise']

  ; Information on directory to write file to:
  ; destination_dir = '/Users/rjolitz/Desktop/test_dir'
  if ~keyword_set(destination_dir) then destination_dir = root_data_dir()

  ; End with / if not already:
  if ~destination_dir.endswith('/') then destination_dir = destination_dir + '/'

  ; Set the destination filename:
  destination_dir = destination_dir + 'swfo/data/plots/'

  if keyword_set(live) then destination_fname = destination_dir + '{PLOTNAME}_last_{PLOTDURATION}_{CADENCE}' else $
    destination_fname = destination_dir +$
      '{PLOTNAME}/YYYY/MM/swfo_ql_{PLOTNAME}_{PLOTDURATION}_{CADENCE}_YYYYMMDD'

  if keyword_set(live) then trange = [systime(1), systime(1)]

  ; Time range for plots to be made over:
  if ~keyword_set(trange) then trange = timerange(trange)
  trange = time_double(trange)

  if trange[0] lt time_double('2025-09-30') then begin
    dprint, 'Date too early: '+time_string(trange)
    return
  endif

  ; Output plot types:
  ; - plot_cadence: frequency of plots (e.g. 1d - every day, 3d, every 3 days)
  if ~keyword_set(plot_cadence) then plot_cadence = '1d'
  n_plot_types = n_elements(plot_types)
  ace_in_plot_types = where(plot_types eq 'ace', load_ace)

  ; STIS datasets needed for making plots:
  swfo_types = ['stis_l0b', 'stis_l1a', 'stis_l1b']

  ; Resolution of datasets used:
  if ~keyword_set(data_resolution) then data_resolution = ['fr', '30s', '300s']

  ; Make label for the data resolutions:
  data_resolution_label = strarr(n_elements(data_resolution))
  foreach dr, data_resolution, indx do begin
    case dr of
      'fr': label = ''
      '30s': label = '30-sec '
      '300s': label = '5-min '
      else: label = ''
    endcase
    data_resolution_label[indx] = label
  endforeach

  if ~keyword_set(plot_durations) then plot_durations = ['7d', '3d', '1d']

  ; Set up plot intervals that end every 1-3d 
  ; (depending on plot_cadence) and start every 1-7d before
  ; that end.
  if keyword_set(live) then plot_intervals, trange, plot_durations, start_time_unix, end_time_unix else $
    plot_intervals, trange, plot_durations, start_time_unix, end_time_unix, end_cadence=plot_cadence
  n_intervals = n_elements(end_time_unix)
  n_durations = n_elements(plot_durations)

  ; print, time_String(start_time_unix[0, *])
  ; print, time_String(end_time_unix[0])
  ; stop

  ; Variables for plots:
  ; - Health:
  hkp_var = ['FPGA_REV', 'VOLTAGE_1P5_VD',$
             'VOLTAGE_3P3_VD', 'VOLTAGE_5P0_VD', 'VOLTAGE_DFE_POS_VA',$
             'VOLTAGE_DFE_NEG_VA', 'BIAS_CURRENT_MICROAMPS', 'ADC_BIAS_VOLTAGE',$
             'TEMP_DAP', 'TEMP_SENSOR1', 'TEMP_SENSOR2']
  tplot_hkp_var = 'swfo_stis_l0b_{}_' + hkp_var
  hkp_ytit = dictionary()
  hkp_ytit["FPGA_REV"] = "FPGA!CRev."
  hkp_ytit["VOLTAGE_1P5_VD"] = "Digital!C1.5 V"
  hkp_ytit["VOLTAGE_3P3_VD"] = "Digital!C3.3 V"
  hkp_ytit["VOLTAGE_5P0_VD"] = "Digital!C5.0 V"
  hkp_ytit["VOLTAGE_DFE_POS_VA"] = "Analog!CDFE +V"
  hkp_ytit["VOLTAGE_DFE_NEG_VA"] = "Analog!CDFE -V"
  hkp_ytit["BIAS_CURRENT_MICROAMPS"] = "Bias!CCurrent uA"
  hkp_ytit["ADC_BIAS_VOLTAGE"] = "ADC Bias!CVoltage"
  hkp_ytit["TEMP_DAP"] = "DAP!CTemp."
  hkp_ytit["TEMP_SENSOR1"] = "DFE1!CTemp."
  hkp_ytit["TEMP_SENSOR2"] = "DFE2!CTemp."

  ; set nominal ranges
  hkp_nominal = dictionary()
  hkp_nominal["ADC_BIAS_VOLTAGE"] = [-40, -32]
  hkp_nominal["TEMP_DAP"] = [-40, 55]
  hkp_nominal["VOLTAGE_1P5_VD"] = [1.4, 1.6]
  hkp_nominal["VOLTAGE_3P3_VD"] = [3.1, 3.5]
  hkp_nominal["VOLTAGE_5P0_VD"] = [4.5, 5.5]
  hkp_nominal["VOLTAGE_DFE_POS_VA"] = [4.5, 6.5]
  hkp_nominal["VOLTAGE_DFE_NEG_VA"] = [-6.5, -4.5]
  hkp_nominal["BIAS_CURRENT_MICROAMPS"] = [3, 4] ; [-4, -3]
  hkp_nominal["TEMP_SENSOR1"] = [-55, 50]
  hkp_nominal["TEMP_SENSOR2"] = [-55, 50]
  hkp_nominal["FPGA_REV"] = [208, 210]

  ; - Summary:
  ; summ_var = ['swfo_stis_l0b_{}_HKP_GAP', 'swfo_stis_l0b_{}_SCI_GAP', 'swfo_stis_l0b_{}_NSE_GAP',$
  ;             'swfo_stis_l1b_{}_HDR_ION_EFLUX', 'swfo_stis_l1b_{}_HDR_ELEC_EFLUX',$
  ;             'swfo_stis_l1a_{}_NOISE_SIGMA', 'swfo_stis_l0b_{}_VALID_RATES']
  summ_var = ['swfo_stis_l0b_GAP',$
              'swfo_stis_l1b_{}_HDR_ION_EFLUX', 'swfo_stis_l1b_{}_HDR_ELEC_EFLUX',$
              'swfo_stis_l1a_{}_NOISE_SIGMA', 'swfo_stis_l0b_{}_VALID_RATES']

  ; - ACE compare:
  ace_var = ['stis_l2_{}_ION_FLUX', 'stis_l2_{}_ELEC_FLUX',$
             'ace_rtsw_epam_proton_flux', 'ace_rtsw_epam_elec_flux']

  ; - NOISE:
  noise_var = ['swfo_stis_l0b_GAP', 'swfo_stis_l1a_{}_NOISE_*',$
               'swfo_stis_l1a_{}_REACTION_WHEEL_SPEED_RPM',$
               'swfo_stis_l1a_{}_IRU_BITS']


  foreach resolution_str, data_resolution, res_index do begin

    ; Resolution of observation finagling:
    ; swfo_load keyword: lowres = 0 (full), 1 (30s), 2 (300s)
    ; Have to leave a crazy value for non-lowres bc it
    ; will keep appending '30s' to the swfo_types ad infinitum
    ; Instead, add the cadence kw to the swfo_types here
    ; and set the cadence kw to 5
    if resolution_str.endswith('s') then begin
      res_tplot_prefix = resolution_str
      res_kw = 5
      swfo_types_i = swfo_types + '_' + resolution_str
    endif else begin
      res_kw = 0
      res_tplot_prefix = 'fr'
      swfo_types_i = swfo_types
    endelse

    ; fill in the tplot variable info:
    tplot_hkp_var_i = strarr_replace(tplot_hkp_var, '{}', res_tplot_prefix)
    summ_var_i = strarr_replace(summ_var, '{}', res_tplot_prefix)
    ace_var_i = strarr_replace(ace_var, '{}', res_tplot_prefix)
    noise_var_i = strarr_replace(noise_var, '{}', res_tplot_prefix)

    for interval=0, n_intervals-1 do begin
      ; Get the end time of the interval:
      end_time_unix_i = end_time_unix[interval]

      ; Get the EARLIEST start time, so we can subset
      ; this to smaller inclusive ranges afterwards without
      ; having to reload the same data repeatedly.
      min_start_time_unix_i = min(start_time_unix[interval, *])

      ; Clear out all previously present data
      ; (tplot bogs down when it 'alters' variables, it is
      ; quicker to just delete em all).
      del_data, '*'

      ; Load the range:
      tr = [min_start_time_unix_i, end_time_unix_i]
      swfo_load, types=swfo_types_i, trange=tr, lowres=res_kw

      ; Sets the common tplot variables and appearances:
      swfo_stis_tplot, /setl

      ; if doing ace, load that as well
      if load_ace then ace_load, trange=tr

      ; Build a bitplot of useful flags:
      get_data, 'swfo_stis_l0b_' + res_tplot_prefix + '_USER_09', data=user09

      ; The HKP, nse, and sci gap is not updated when the replay
      ; data fills in, leading to residual "gaps". So those aren't as useful
      ; for identifying missing data / processing pipeline errors
      ; get_data, 'swfo_stis_l0b_' + res_tplot_prefix + '_HKP_GAP', data=hkpgap
      ; get_data, 'swfo_stis_l0b_' + res_tplot_prefix + '_NSE_GAP', data=nsegap
      ; get_data, 'swfo_stis_l0b_' + res_tplot_prefix + '_SCI_GAP', data=scigap
      ; gapbit = ishft(user09.y ne 1, 3) or ishft(scigap.y, 2) or ishft(nsegap.y, 1) or hkpgap.y
      ; store_data, 'swfo_stis_l0b_GAP', data={x: scigap.x, y: gapbit},$
      ;   dl={tplot_routine: 'bitplot', psyms:1, colors: 'grbk',$
      ;       labels: ['HKP Gap', 'NSE Gap', 'SCI Gap', 'User09!=1'],$
      ;       ytitle: 'Flags', panel_size: 0.25, yrange: [-0.5, 3.5],$
      ;       yticks: 1, yminor: 1}

      get_data, 'swfo_stis_l0b_' + res_tplot_prefix + '_HKP_REPLAY', data=replay
      get_data, 'swfo_stis_l0b_' + res_tplot_prefix + '_SCI_TIME_RES', data=time_res

      ; Try to flag the gaps indirectly
      ; Calculate the effective time between frames:
      tdiff = replay.x - shift(replay.x,1)

      ; Duration = 1 + time_res should be == tdiff
      missing_data_flag = (round(tdiff) - time_res.y) ne 1

      if res_tplot_prefix eq 'fr' then begin

        gapbit = ishft(replay.y, 2) or ishft(user09.y ne 1, 1) or missing_data_flag
        store_data, 'swfo_stis_l0b_GAP', data={x: replay.x, y: gapbit},$
          dl={tplot_routine: 'bitplot', psyms:1, colors: 'krbg',$
              labels: ['Tdiff != Tres', 'User09!=1', 'Replay'],$
              ytitle: 'Flags', panel_size: 0.25, yrange: [-0.5, 2.5],$
              yticks: 1, yminor: 1}

      endif else begin

        gapbit =user09.y ne 1
        store_data, 'swfo_stis_l0b_GAP', data={x: replay.x, y: gapbit},$
          dl={tplot_routine: 'bitplot', psyms:1, colors: 'r',$
              labels: ['User09!=1'],$
              ytitle: 'Flags', panel_size: 0.25, yrange: [-0.5, 0.5],$
              yticks: 1, yminor: 1}

      endelse

      ; Iterate through the possible plots to make:
      foreach plot_name, plot_types do begin
        ; stop

        wi, 2, wsize=[900, 1000]
        tplot_options, 'charsize', 1.2
        tplot_options,'xmargin',[10,10]
        tplot_options, 'ygap', 0.4

        ; Health plot
        if plot_name.startswith('health') then begin

          ; Apply ylimit & tlimit:
          foreach hkpname, hkp_var do begin
            hkp_tplot_name_i = 'swfo_stis_l0b_'+res_tplot_prefix+'_'+hkpname
            nom = hkp_nominal[hkpname]
            plot_yrange = [nom[0] - 0.1*(nom[1] - nom[0]), nom[1] + 0.1*(nom[1] - nom[0])]
            if hkpname.contains("FPGA") then begin
              plot_yrange = [208, 210]
              options, hkp_tplot_name_i, yticks=2, panel_size=0.5
            endif else if hkpname.contains("VOLTAGE") then begin
              options, hkp_tplot_name_i, yticks=4
            endif

            ylim, hkp_tplot_name_i, plot_yrange[0], plot_yrange[1]
            options, hkp_tplot_name_i, ytitle=hkp_ytit[hkpname]
          endforeach

          tplot, tplot_hkp_var_i, window=2

        endif else if plot_name.startswith('summ') then begin

          ; if res_tplot_prefix eq 'fr' then begin
          ;  valid_yrange = [1, 2e5]
          ;  eflux_zrange = [1, 1e5]
          ; endif else begin 
          valid_yrange=[0.2, 2e5]
          eflux_zrange = [0.2, 1e5]
          ; endelse

          options, 'swfo_stis_l1b_'+res_tplot_prefix+'_HDR_ION_EFLUX',$
            ytitle='Ion Energy [keV]', ztitle='HDR EFLUX', zrange=eflux_zrange
          options, 'swfo_stis_l1b_'+res_tplot_prefix+'_HDR_ELEC_EFLUX',$
            ytitle='Elec Energy [keV]', ztitle='HDR EFLUX', zrange=eflux_zrange

          options, 'swfo_stis_l1a_'+res_tplot_prefix+'_NOISE_SIGMA',$
            ytitle='Noise Sigma', panel_size=0.5
          options, 'swfo_stis_l0b_'+res_tplot_prefix+'_VALID_RATES',$
            ytitle='Valid Rates', ysubtitle='[counts/s]', yrange=valid_yrange

          tplot, summ_var_i, window=2

        endif else if plot_name.startswith('ace') then begin

          options, 'ace_rtsw_epam_elec_flux',$
            ytitle='5-min ACE Elec Flux', ysubtitle='[#/cm2-s-ster-keV]'
          options, 'ace_rtsw_epam_proton_flux',$
            ytitle='5-min ACE Proton Flux', ysubtitle='[#/cm2-s-ster-keV]'

          options, 'stis_l2_'+res_tplot_prefix+'_ION_FLUX',$
            ytitle=data_resolution_label[res_index] +'STIS Ion Flux', ysubtitle='[#/cm2-s-ster-keV]'
          options, 'stis_l2_'+res_tplot_prefix+'_ELEC_FLUX',$
            ytitle=data_resolution_label[res_index] +'STIS Elec Flux', ysubtitle='[#/cm2-s-ster-keV]'

          tplot, ace_var_i, window=2

        endif else if plot_name.startswith('noise') then begin

          options, 'swfo_stis_l1a_' + res_tplot_prefix + '_NOISE_HISTOGRAM',$
            zrange=[1, 2e3], ytitle='Noise!CHistogram'

          ; ylim, 'swfo_stis_l0b_' + res_tplot_prefix +'_NSE_GAP', 0, 1, 0
          ; options, 'swfo_stis_l0b_' + res_tplot_prefix +'_NSE_GAP',$
          ;   colors=6, panel_size=0.1, yticks=1, yminor=1
          ; options, 'swfo_stis_l0b_'+res_tplot_prefix+'_NSE_GAP',ytitle='Nse', ysubtitle='Gap'

          options, 'swfo_stis_l1a_' + res_tplot_prefix + '_NOISE_RES',$
            yrange=[0, 7], yminor=1, yticks=7, panel_size=0.5, ytitle='Res'
          options, 'swfo_stis_l1a_' + res_tplot_prefix + '_NOISE_PERIOD',$
            yrange=[0, 250], yminor=1, panel_size=0.5, ytitle='Period'
          options, 'swfo_stis_l1a_' + res_tplot_prefix + '_NOISE_TOTAL',$
            panel_size=0.5, ytitle='Total'
          options, 'swfo_stis_l1a_' + res_tplot_prefix + '_NOISE_SIGMA',$
            panel_size=0.5, ytitle='Sigma'


          options, 'swfo_stis_l1a_' + res_tplot_prefix + '_REACTION_WHEEL_SPEED_RPM',$
            yrange=[-2200, 2200], ytitle='Rxn Wheel Speed [RPM]'
          options, 'swfo_stis_l1a_' + res_tplot_prefix + '_NOISE_BASELINE',$
            yrange=[-10, 5], ytitle='Baseline'
          options, 'swfo_stis_l1a_' + res_tplot_prefix + '_IRU_BITS', ytitle='IRU Bits'

          tplot, noise_var_i, window=2

        endif


        for dur=0, n_durations - 1 do begin
          start_time_unix_i = start_time_unix[interval, dur]
          subset_tr = [start_time_unix_i, end_time_unix_i]

          ; if keyword_set(center_start) then reference_t = end_time_unix_i - 86400d else $
          ;   reference_t = subset_tr[1]
          reference_t = end_time_unix_i - 86400d

          ; Now create the plot png name:
          fname_i = time_string(reference_t, tformat=destination_fname)
          fname_i = fname_i.replace('{PLOTNAME}', plot_name)
          fname_i = fname_i.replace('{PLOTDURATION}', plot_durations[dur])
          fname_i = fname_i.replace("{CADENCE}", res_tplot_prefix)
          ; stop

          ; Offset by two hours the end of the trange
          ; for live view:
          if keyword_set(live) then begin
            subset_tr = subset_tr + [0, 2*3600d]
            print, time_string(subset_tr)
          endif
            
          ; Redraw the subset timerange:
          tlimit, subset_tr

          ; add a timebar marking the current time if
          ; live plot
          if keyword_set(live) then timebar, end_time_unix_i

          ; Redraw the timebars:
          if plot_name.startswith('health') then begin

            foreach hkpname, hkp_var do begin
              hkp_tplot_name_i = 'swfo_stis_l0b_'+res_tplot_prefix+'_'+hkpname
              nom = hkp_nominal[hkpname]

              ; No nominal range for the FPGA
              if hkpname.contains("FPGA") then continue

              timebar, nom[0], /databar, varname=hkp_tplot_name_i, color='g'
              timebar, nom[1], /databar, varname=hkp_tplot_name_i, color='g'
            endforeach

            timebar, 1.5, /databar, varname='swfo_stis_l0b_'+res_tplot_prefix+'_VOLTAGE_1P5_VD',$
              linestyle=5, color='m'
            timebar, 3.3, /databar, varname='swfo_stis_l0b_'+res_tplot_prefix+'_VOLTAGE_3P3_VD',$
              linestyle=5, color='m'
            timebar, 5.0, /databar, varname='swfo_stis_l0b_'+res_tplot_prefix+'_VOLTAGE_5P0_VD',$
              linestyle=5, color='m'
          endif

          ; Write the pngs:
          if keyword_set(show) then stop

          makepng, fname_i, /mkdir, window=2
          ;tlimit, 0, 0
        endfor


      endforeach
    endfor
  endforeach

  return

end