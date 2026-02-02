;+
;FUNCTION:  SWFO_STIS_SCI_LEVEL_1B
;PURPOSE: Creates an array of structures,
; where each structure has fields corresponding
; to the Level 1b data product for SWFO STIS, using
; the array of Level 1a structures produced
; by SWFO_STIS_SCI_LEVEL_1A.pro.
;
; Unlike the Level 1a, this data product contains
; fluxes determined by numerically merging the
; smaller pixel with the larger pixel for both species.
;
; Also assigns quality flag bits for potentially
; supicious pixel merging and electron contamination.
;
; Note that currently, all fields from Level 1a are
; included in the Level 1b.
;
; Example call:
;  > l1b =   swfo_stis_sci_level_1b(l1a, cal=cal)
;
; Cribsheets that demonstrate Level 1b loading:
; - swfo_stis_sci_l1b_crib.pro
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2026-01-27 16:45:03 -0800 (Tue, 27 Jan 2026) $
; $LastChangedRevision: 34074 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_1b.pro $

; Function that merges counts/fluxes/rates/efluxes from the small pixel
; and large pixel given the coefficients of each.

function swfo_stis_hdr, F_largepixel, F_smallpixel, eta_smallpixel=eta_smallpixel,$
    eta_largepixel=eta_largepixel
    ;, l1a_str$

    ; F_small eta_1 + F_big eta_2 / (eta2 + eta1)
    ; works for rates, fluxes, etc:

    A = (eta_smallpixel + eta_largepixel)
    hdr = (eta_smallpixel * F_smallpixel + eta_largepixel * F_largepixel)/A

    return,hdr

end

; Function to take the difference between recorded count rates
; and a line between the flux at the endpoints

function swfo_stis_deviation_from_linfit, energy, count_rate, finite=finite

    ; Take the logarithm of the energy and count rates:
    log_energy = alog10(energy)
    log_rate = alog10(count_rate)

    ; subset to finite only
    if keyword_set(finite) then begin
      finite_index = where(finite(log_rate))
      log_energy = log_energy[finite_index]
      log_rate = log_rate[finite_index]
    endif

    ; get the slope and y-intercept of the line between the endpoints:
    m = (log_rate[-1] - log_rate[0])/(log_energy[-1] - log_energy[0])
    b = log_rate[0] - m*log_energy[0]
    ; print, m
    ; print, b
    ; stop

    ; calculate the expected line at each log(energy) point:
    fit = m * log_energy + b

    ; take the difference between the log rate and the fit:
    deviation = (log_rate - fit)
    return, deviation

end


function swfo_stis_sci_level_1b,L1a_strcts,format=format,reset=reset,cal=cal

  ; if isa(param,'dictionary') then def_param = param
  ; if ~isa(def_param,'dictionary') then def_param=dictionary()
  ; if ~keyword_set(param) then param=dictionary()
  ; if ~param.haskey('range') then param.range = 30   ; interval in seconds

  output = !null
  nd = n_elements(L1a_strcts)

  ; ; pull map for first str
  ; str_0 = L1a_strcts[0]
  ; cal = swfo_stis_cal_params(str_0,reset=reset)
  ; if ~isa(cal) then return,!null
  ; bins = cal.prot_resp
  ; elec_resp = cal.elec_resp
  ; geom = bins.geom  ; this is the same for elecs and protons
  ; Get the cal values if not defined:
  if ~isa(cal,'dictionary') then cal = swfo_stis_inst_response_calval()


  ; Get deadtime correction criteria:
  dtc = cal.deadtime_correction_criteria
  dtc_lower = dtc[0]
  dtc_upper = dtc[1]
  dtc_scaling = 1/(dtc_upper-dtc_lower)

  poisson = cal.poisson_statistics_criteria
  N_low = poisson[0]
  N_high = poisson[1]
  a = cal.poisson_statistics_power_coefficient

  ; Get the calvals out for common access:
  pixel_ratio_low = cal.expected_pixel_ratio[0]
  pixel_ratio_high = cal.expected_pixel_ratio[1]
  ion_pixel_qflag = cal.bad_ion_pixel_merge_qflag_index
  elec_pixel_qflag = cal.bad_elec_pixel_merge_qflag_index

  contam_min_ion_energy = cal.contam_min_ion_energy
  contam_min_electron_energy = cal.contam_min_electron_energy

  ; Get the deadlayer / spline info for access in forloop:
  if cal.energy_response_function then begin
    O_proton_dl_keV = spline_fit3(!null,$
      cal.modeled_proton_energy_measured_in_O,$
      cal.modeled_proton_energy_loss_in_O,/xlog,/ylog)
    F_proton_dl_keV = spline_fit3(!null,$
      cal.modeled_proton_energy_measured_in_F,$
      cal.modeled_proton_energy_loss_in_F,/xlog,/ylog)
    F_electron_dl_keV = spline_fit3(!null,$
      cal.modeled_electron_energy_measured_in_F,$
      cal.modeled_electron_energy_loss_in_F,/xlog,/ylog)

  endif else begin
    O_proton_dl_keV = cal.proton_O_dead_layer
    F_proton_dl_keV = cal.proton_F_dead_layer
    F_electron_dl_keV = cal.electron_F_dead_layer
  endelse

  for i=0l,nd-1 do begin
    str = L1a_strcts[i]
    ; stop

    ; approximate period (in seconds) of Version 64 FPGA
    integration_time = str.sci_duration ; * cal.period

    ; Get the measured energies in the O and F detectors:
    O_energy  = str.spec_O1_nrg
    F_energy = str.spec_F1_nrg
    O_denergy  = str.spec_O1_dnrg
    F_denergy = str.spec_F1_dnrg

    ; To get the initial particle energy from measured energy,
    ; need a response function to determine how much energy was
    ; lost in the dead layer. The energy loss will differ depending
    ; on the assumed particle. Can either use a fixed energy loss
    ; or a Cubic spline fit to the response function

    ; This isn't easily determined for the detector at the back
    ; of the stack (O2 and F2, sensitive to Xrays + GCRs). For coincidences,
    ; assume the energy loss from the first coincidence (e.g. F12, use F1,
    ; F23, use F3.)
    ; but we only need the front-facing detectors (O1 and O2).
    ; For the coincidences 13/23, can use the same offset.

    if cal.energy_response_function then begin
      F_elec_energy = spline_fit3(param=F_electron_dl_keV, F_energy) + F_energy
      O_ion_energy = spline_fit3(param=O_proton_dl_keV, O_energy) + O_energy

      ; plot, F_energy, F_elec_energy, /xlog, /ylog, xtit='Measured Energy, keV', ytit='Actual particle energy, keV', psym=-4
      ; oplot, cal.modeled_electron_energy_measured_in_F, cal.modeled_electron_energy_loss_in_F + cal.modeled_electron_energy_measured_in_F
      ; stop
    endif else begin

      F_elec_energy = F_electron_dl_keV + F_energy
      O_ion_energy = O_proton_dl_keV + O_energy

    endelse

    ion_denergy = O_denergy
    elec_denergy = F_denergy
    ion_energy = O_ion_energy
    elec_energy = F_elec_energy

    ; f = nrglost_vs_nrgmeas['Electron-F-3']
    ; mnrg, nrg
    ; nrg = spl(mnrg) + mnrg for F1, F3
    ; nrg_n[] = spline_fit3(param=f, (adc_n * conv_n)) + (adc_n * conv_n)


    ; Determine deadtime correctons here
    ; srate is the total count rate in each detector for deadtime
    ; (summed over coincidences):
    ; O1/F1 first (tiny pixel)
    srate_O1 = total(str.rate_O1 + str.rate_O12 + str.rate_O13 + str.rate_O123)
    srate_F1 = total(str.rate_F1 + str.rate_F12 + str.rate_F13 + str.rate_F123)
    ; O3/F3 next (big pixel)
    srate_O3 = total(str.rate_O3 + str.rate_O13 + str.rate_O23 + str.rate_O123)
    srate_F3 = total(str.rate_F3 + str.rate_F13 + str.rate_F23 + str.rate_F123)

    ; Nonparalyzable deadtime in O1/F1 (tiny pixel AKA AR1)
    deadtime_correction_O1 = 1 / (1- srate_O1*cal.deadtime_s)
    deadtime_correction_F1 = 1 / (1- srate_F1*cal.deadtime_s)
    ; Nonparalyzable deadtime in O3/F3 (big pixel AKA AR2)
    deadtime_correction_O3 = 1 / (1- srate_O3*cal.deadtime_s)
    deadtime_correction_F3 = 1 / (1- srate_F3*cal.deadtime_s)

    ; formulation from gpa doc:
    ; get the deadtime prefactor:
    ; This accepts the big pixel if the deadtime correction below 1.2
    ; and de-emphasizes it as deadtime correction exceeds 1.8.
    ; eta2 = 0. > (1.8- deadtime_correction)*.4 < 1.
    eta2_O = 0. > (dtc_upper - deadtime_correction_O3)*dtc_scaling < 1.
    eta2_F = 0. > (dtc_upper - deadtime_correction_F3)*dtc_scaling < 1.

    ; rate14 = str.total14/ integration_time    ; this needs to be checked
    ; Exrate = reform(replicate(1,cal.n_energy) # rate14,cal.n_energy * 14)
    ; deadtime_correction = 1 / (1- exrate*cal.deadtime)
    ; w = where(deadtime_correction gt 10. or deadtime_correction lt .5,/null)
    ; deadtime_correction[w] = !values.f_nan
    ; Alternate: Taylor expand to avoid singularity:
    ; deadtime_correction = 1 + exrate * cal.deadtime
    ; if total(rate14) gt 1000 then stop

    ; Apply deadtime correction to flux & rate:
    ; rate is the count rate corrected for deadtime
    ion_rate_small = str.rate_O1 * deadtime_correction_O1
    ion_rate_big = str.rate_O3 * deadtime_correction_O3
    ion_flux_small = str.spec_O1 * deadtime_correction_O1
    ion_flux_big = str.spec_O3 * deadtime_correction_O3

    elec_rate_small = str.rate_F1 * deadtime_correction_F1
    elec_rate_big = str.rate_F3 * deadtime_correction_F3
    elec_flux_small = str.spec_F1 * deadtime_correction_F1
    elec_flux_big = str.spec_F3 * deadtime_correction_F3

    ; total counts in entire energy channel:
    ; 1/8/25: since reaction wheel noise affects
    ; O1, O2, F2, and F3 in decreasing magnitudes,
    ; want to switch the N_ion criterion for merging
    ; pixels to use O3 instead
    N_ion_big   = ion_rate_big * integration_time
    N_ion_small = ion_rate_small * integration_time
    N_ion_tot   = total(N_ion_big)/100

    N_elec = elec_rate_small * integration_time
    N_elec_tot = total(elec_rate_small) * integration_time

    ; Make ratio
    norm_ion_rate_O3 = ion_rate_big/100

    ; Mask out zero counts in big pixel +
    ; bad statistics in small pixel:
    norm_ion_index = where(N_ion_big eq 0 and N_ion_small le sqrt(N_ion_small))

    ion_ratio = ion_rate_small/(ion_rate_big/100)
    ion_delta = ion_rate_small - ion_rate_big/100

    ion_ratio[norm_ion_index] = !values.d_nan
    ion_delta[norm_ion_index] = !values.d_nan

    ; These are currently constant over energy
    ; original:
    ; eta1_ion =  0. > sqrt( total(ion_rate_small) * param.range  ) < 1.
    ; eta1_elec =  0. > sqrt( total(elec_rate_small) * param.range ) < 1.

    ; from GPA doc:
    ; sqrt(N) / 100 for total counts for param.range seconds.
    eta1_ion =  0d > sqrt( N_ion_tot  )/100 < 1d
    eta1_elec =  0d > sqrt( N_elec_tot  )/100 < 1d

    ; New approach:
    ; maximum control by calvals table:
    f_elec = (N_elec_tot^a - N_low^a)/(N_high^a - N_low^a)
    eta1_elec = (N_elec_tot gt N_high) + (N_elec_tot lt N_high and N_elec_tot gt N_low) * f_elec
    f_ion = (N_ion_tot^a - N_low^a)/(N_high^a - N_low^a)
    eta1_ion = (N_ion_tot gt N_high) + (N_ion_tot lt N_high and N_ion_tot gt N_low) * f_ion

    ; ; scaled poisson
    ; if tot_N_ion eq 0 then eta1_ion = 0. else  eta1_ion =  0. > sqrt( tot_N_ion  ) / tot_N_ion < 1.
    ; eta1_elec =  0. > sqrt( tot_N_elec ) / tot_N_elec < 1.

    ; stop

    hdr_ion_flux = swfo_stis_hdr(ion_flux_big, ion_flux_small, $
      eta_smallpixel=eta1_ion, eta_largepixel=eta2_O)
    hdr_elec_flux = swfo_stis_hdr(elec_flux_big, elec_flux_small, $
      eta_smallpixel=eta1_elec, eta_largepixel=eta2_F)

    hdr_ion_rate = hdr_ion_flux * str.geom_O3 * str.spec_O3_dnrg
    hdr_elec_rate = hdr_elec_flux * str.geom_F3 * str.spec_F3_dnrg

    ; Quality flag determination:
    ; First, retrieve the quality flag from level 1a
    ; We will augment this:
    q = str.quality_bits

    ; Q flag: bits at positional index 26-29 set if the pixel merging
    ; is suspect/anomalous for:
    ; - ion channel:
    ;    - 26: small pixel counting too few or big pixel counting too many
    ;    - 27: small pixel counting too many or big pixel counting too few
    ; - elec channel:
    ;    - 28: small pixel counting too few or big pixel counting too many
    ;    - 29: small pixel counting too many or big pixel counting too few

    ; Calculate the ratio of count rate in small pixel to count rate
    ; in big pixel:
    ; - sum over all energy channels to improve signal response
    ;   - this will allow detection energy-dependent differential
    ;     behavior from small-to-big pixel, which shouldn't happen
    ; - divide by the big pixel count rate, since that should have the
    ;   most counts. should give a number of ~0.01
    ;    - if have zero counts in big pixel, can't determine, so NaN
    ;      it and move on. (will not set the qf in that case,
    ;      since can't be determined).
    if total(ion_rate_big) gt 1 then ion_pixel_ratio = total(ion_rate_small) / total(ion_rate_big) else $
      ion_pixel_ratio = !values.d_nan
    if total(elec_rate_big) gt 1 then elec_pixel_ratio = total(elec_rate_small) / total(elec_rate_big) else $
      elec_pixel_ratio = !values.d_nan

    ; ; Error determination (couldn't make this work):
    ; ion_pixel_ratio_error = !values.f_nan
    ; if total(ion_rate_big) gt 1 then ion_pixel_ratio_error = sqrt(1/total(ion_rate_small) + 1/total(ion_rate_big))
    ; elec_pixel_ratio_error = !values.f_nan
    ; if total(elec_rate_big) gt 1 then elec_pixel_ratio_error = sqrt(1/total(elec_rate_small) + 1/total(elec_rate_big))


    ; set quality flag if ratio is outside of expected range:

    q = q or ishft((ion_pixel_ratio lt pixel_ratio_low)*1ull, ion_pixel_qflag[0])
    q = q or ishft((ion_pixel_ratio gt pixel_ratio_high)*1ull, ion_pixel_qflag[1])
    q = q or ishft((elec_pixel_ratio lt pixel_ratio_low)*1ull, elec_pixel_qflag[0])
    q = q or ishft((elec_pixel_ratio gt pixel_ratio_high)*1ull, elec_pixel_qflag[1])

    ; Q flag: bits at positional index 30 set if suspicious for electron contamination.
    ;  Based on SEP, anticipate STIS will have contamination by electrons
    ;  in the ion channel in the ion bins of ~50 keV to 1 MeV. This only
    ;  occurs during electron-rich events with a sizable high energy component.
    ;  It is easiest to recognize as a blurry horizontal "line" at around 200 keV,
    ;  especially in data that has been time-averaged over several samples (e.g. 5 min).
    ;
    ; This is the hardest flag to assess, so it requires multiple
    ; criterion.
    ; - Enough ion counts in the sample: >1 at the selected sensitive energy (~100 keV)
    ; - High electron count rate: >10 counts/sec in the highest elec energy
    ;   bin that is least affected by ion bleedthrough from high enerrges (~100 keV)
    ; - Low ion-electron count rate ratio (O/O+F): <0.25 for 100 keV
    ;   (NOTE: this is better than O/F since more numerically constrained)
    ; - High deviation of affected O count rates from a power law fit to
    ;   affected bin  energy range: >0.1 for 50-1000 keV

    ; Don't eval if data not available in these areas
    ions_in_range = (contam_min_electron_energy ge ion_energy[0] and $
                     contam_min_electron_energy le ion_energy[-1])
    elecs_in_range = (contam_min_electron_energy ge elec_energy[0] and $
                      contam_min_electron_energy le elec_energy[-1])

    qflag_econtam = 0

    ratio = !values.d_nan
    avg_deviation = !values.d_nan
    ion_rate_at_en = !values.d_nan
    elec_rate_at_en = !values.d_nan
    ion_contam_inrange = (elecs_in_range and ions_in_range)

    if elecs_in_range and ions_in_range then begin
      ; get closest energy to ion, to see if enough
      ; ions

      min_ion_index = (where(ion_energy ge contam_min_ion_energy))[0]
      ion_rate_at_en = hdr_ion_rate[min_ion_index]

      ; and electrons:
      min_elec_index = (where(elec_energy ge contam_min_electron_energy))[0]
      elec_rate_at_en = hdr_elec_rate[min_elec_index]

      ; enough ions and electrons?
      enough = ((ion_rate_at_en gt cal.contam_min_ion_count_rate) and $
        (elec_rate_at_en gt cal.contam_min_electron_count_rate))

      ; if so, then eval the flux ratio
      ; elec contam only a risk for electron-rich ion-poor events:
      if enough then begin
        ; print, 'enough ions + elecs'
        ; print, 'elec rate', elec_rate_at_en, ' at ', elec_energy[min_elec_index]
        ; print, 'ion rate', ion_rate_at_en, ' at ', ion_energy[min_ion_index]
        O_index = (where(O_energy ge cal.contam_min_ion_ratio_energy))[0]
        ion_rate_for_ratio = hdr_ion_rate[O_index]
        elec_rate_for_ratio = hdr_elec_rate[O_index]
        ratio = ion_rate_for_ratio/(elec_rate_for_ratio + ion_rate_for_ratio)
        ; stop

        ; and if THIS criterion is met, determine
        ; if there is a bump in the spectra in the contamination
        ; energy range. do this by calculating the linear fit
        ; to the count rate at the ends of the energy range,
        ; and then taking the sum of the difference between
        ; the measurement and linear fit.

        ; if this is above the max deviation, THEN
        ; set the qflag for elec contamination:
        if ratio lt cal.contam_min_ion_ratio then begin
          elec_contam_index =$
            where(O_energy gt cal.contam_ion_energy_range[0] and $
                  O_energy lt cal.contam_ion_energy_range[1], n_elec_contam)

          if n_elec_contam gt 2 then begin
            ; need at least two observations to run the below code,
            ; and need at least three to calculate a nonzero deviation
            ; - finite keyword: only activate for testing with Xray dataset
            ; dev = swfo_stis_deviation_from_linfit(ion_energy[elec_contam_index],$
            ;                                       hdr_ion_rate[elec_contam_index], /finite)
            dev = swfo_stis_deviation_from_linfit(ion_energy[elec_contam_index],$
                                                  hdr_ion_rate[elec_contam_index])
            avg_deviation = mean(dev, /nan)
            ; stop
            if avg_deviation gt cal.contam_ion_max_deviation_power_law then qflag_econtam = 1
          endif

        endif
      endif
    endif
    q = q or ishft(qflag_econtam*1ull, cal.elec_contam_qflag_index)
    ; str.quality_bits = q


    ; ion_energy = bins.energy
    ; w = where(bins.species eq 1,/null)
    ; ion_energy= ion_energy[w]
    ; bins = cal.elec_resp
    ; elec_flux = crate / bins.geom
    ; elec_energy = bins.energy
    ; w = where(bins.species eq 0,/null,nw)
    ; elec_energy= elec_energy[w]

    sci = {  $
      time:str.time, $
      time_unix: str.time_unix, $
      time_MET:  str.time_MET, $
      time_GR:  str.time_GR, $
      integration_time : integration_time, $
      ; srate : srate , $
      ; crate : crate , $
      ; TID:  bins.tid,  $
      ; FTO:  bins.fto,  $
      ; geom:  bins.geom,  $
      ewidth: ion_denergy,  $
      ion_energy: ion_energy,   $   ; midpoint energy
      Ch1_ion_flux :   ion_flux_small,  $
      Ch3_ion_flux :   ion_flux_big,  $
      hdr_ion_flux :   hdr_ion_flux,  $
      ion_ratio: ion_ratio, $
      ion_delta: ion_delta, $
      eta2_ion: eta2_O, $
      eta2_elec: eta2_F, $
      eta1_ion: eta1_ion, $
      eta1_elec: eta1_elec, $
      elec_energy:  elec_energy, $
      Ch1_elec_flux :   elec_flux_small,  $
      Ch3_elec_flux :   elec_flux_big,  $
      hdr_elec_flux:  hdr_elec_flux, $
      ion_pixel_ratio: ion_pixel_ratio, $
      elec_pixel_ratio: elec_pixel_ratio, $
      ; contam_inrange: ion_contam_inrange, $
      ; contam_elec_rate: elec_rate_at_en, $
      ; contam_ion_rate: ion_rate_at_en, $
      ; contam_elec_ion_ratio: ratio, $
      ; contam_elec_ion_dev: avg_deviation, $
      lut_id: 0, $
      quality_bits: q}


    ; sci = create_struct(str,sci)

    if nd eq 1 then   return, sci
    if i  eq 0 then   output = replicate(sci,nd) else output[i] = sci

  endfor

  return,output

end

