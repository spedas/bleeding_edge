; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-05-23 10:33:06 -0700 (Fri, 23 May 2025) $
; $LastChangedRevision: 33323 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_cal_params.pro $

;This routine should return a structure that contains calibration parameters.
; Currently only valid for the non LUT mode  ; this is a place holder for final cal routines

function swfo_stis_cal_params,strct,reset=reset

  common swfo_stis_cal_params_com, stis_master

  if keyword_set(reset) then stis_master = !null
  reset=0

  if ~isa(stis_master,'dictionary') then stis_master = dictionary()

  if strct.sci_nbins ne 672 then begin
    dprint, 'Not working with LUT mode yet',strct.sci_nbins,dwait=60
    ;return,!null
  endif

  if ~stis_master.haskey('cal') then begin
    dprint,'Creating calibration structure for non LUT. FPGA version: ' +strtrim(fix(strct.fpga_rev))  ;+ string(strct.fpga_rev,format='(X)')
    nan= !values.f_nan
    if 1 then begin
      bin_resp= {geom:nan,energy:nan,ewidth:nan,tid:0,fto:0,adc_min:0, adc_max:0, species:-1}
      bin_resp= replicate(bin_resp,672)
    endif else     cal = dictionary()
    kev_per_adc = 1.   ; kev  approx
    KEV_dead_layer = 10.  ; kev  approx
    A1 = .2* .01
    A2 = .2* .99
    A3 = .2
    steradian = 1.
    gf_area = [a1,a2,a1,a3,a1,a2,a3]       ; This order is subject to change
    gf_area = transpose([[gf_area],[gf_area]])
    gf_area = replicate(1,48) # gf_area[*]
    gf_area = gf_area[*] * steradian
    bin = indgen(672)
    FTO_ID = bin / 48
    TID = FTO_ID and 1
    FTO = (FTO_ID /2 ) + 1
    LOG_ADC = bin mod 48
    ADC_min = swfo_stis_log_decomp(log_adc,17)
    ADC_max = swfo_stis_log_decomp(log_adc+1,17)
    DEL_ADC = ADC_max - ADC_min
    ewidth = DEL_ADC * kev_per_adc
    energy = (ADC_max + Adc_min)/2. * kev_per_adc + kev_dead_layer
    geom = gf_area  * ewidth
    bad = where(energy lt 20.,/null)   ; commented out
    geom[bad] = !values.f_nan
    bin_resp.geom = geom
    bin_resp.energy = energy
    bin_resp.ewidth = ewidth
    bin_resp.tid = tid
    bin_resp.fto = fto
    cal = { $
      nbins:672, $
      n_energy:48, $
      period: 1., $      ;   baseline period (1 second for SWFO;  .87 seconds for HERMES)
      kev_per_adc: kev_per_adc, $
      kev_dead_layer: kev_dead_layer, $
      deadtime: 1e-5,   $     ; Deadtime of 10 usec  (needs TBR)
      elec_resp:bin_resp , $
      prot_resp:bin_resp, $
      alpha_resp:bin_resp, $
      gamma_resp:bin_resp $
    }
    w = where(bin_resp.tid eq 1 and bin_resp.fto eq 1)   ; large area electron channel
    cal.elec_resp[w].species = 0
    w = where(bin_resp.tid eq 0 and bin_resp.fto eq 1)   ; large area ion channel
    cal.prot_resp[w].species = 1
    stis_master.cal  = cal

  endif

  return,stis_master.cal

end

