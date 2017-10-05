;+
;	Procedure:
;		thm_get_fft_cal_pars
;
;	Purpose:
;		Given the signal source, and begin and end of the time interval,
;	return the FFT RAW->PHYS transformation parameters.
;
;	Calling Sequence:
;	thm_get_fft_cal_pars, tbeg, tend, fft_sel, nbins, cal_pars=cal_pars

;	Arguements:
;		tbeg, tend	DOUBLE, time in seconds since THEMIS epoch.
;		fft_sel	INT, FilterBank source selection indicator.
;		nbins,	INT, number of frequency bins in spectrum (16, 32, 64).
;		cal_pars	STRUCT, see Notes below for elements.
;
;
;	Notes:
;	-- use of TBEG and TEND for time-dependent calibration parameters is not currently implemented!
;	-- E-field gains and units are for actual deployed boom lengths (CDE).
;	-- Elements of cal_pars are as follows:
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2007-11-16 12:28:13 -0800 (Fri, 16 Nov 2007) $
; $LastChangedRevision: 2043 $
; $URL $
;-
pro thm_get_fft_cal_pars, tbeg, tend, fft_sel, nbins, cal_pars=cal_pars
	; attenuation factors from Flight model measurements plus modeling;
	;	JWB, UCBSSL, 1 Feb 2007.
	cal_par_time = '2002-01-01/00:00:00'

; set the unit strings.
	units_scm = 'nT!U2!N/Hz'
	units_edc = '(V/m)!U2!N/Hz'	; <--- NOTE that E-field units are mV/m (deployed state).
	units_eac = '(V/m)!U2!N/Hz'	; <--- NOTE that E-field units are mV/m (deployed state).
	units_v = 'V!U2!N/Hz'

; determine the frequency binning and bin width.
; note that even though there is a variable bin width across the spectrum (df/f ~ const.),
; the on-board calculation produces a result that should be normalized with a constant bin width of 8 Hz.
	if (fft_sel ge 12) and (fft_sel le 14) then $
		rate = '16k' else $
		rate = '8k'

	thm_fft_freq_bins, rate=rate, nbins=nbins, cent_freq=cent_freq
	bin_width = 8.	; Hz.


; determine the attenuation factors for each frequency bin.
; note that these are attenuation factors for spectral density, rather than amplitude,
; and so are the square of the analogous frequency response factors in the CAL_FBK routine.

; note that there is an upper limit on the attenuation factor to keep from amplifying noise bins.
	max_atten_fac = 100.

	thm_comp_scm_response, 'dummy', cent_freq, scm_resp

	thm_comp_efi_response, 'SPB', cent_freq, spb_resp

	thm_comp_efi_response, 'AXB', cent_freq, axb_resp

	thm_comp_eac_response, 'dummy', cent_freq, eac_resp

; set up the various gain factors.
	adc_factor = 1.0/float( 2L^16 - 1L)

	gain_v = 2.0*105.2*adc_factor
	gain_edc = 2.0*15.0*adc_factor
	gain_eac = 2.0*2.54*adc_factor
	gain_scm = 2.0*5.0*adc_factor

	l12 = 49.6	; meters.
	l34 = 40.4	; meters.
	l56 = 5.63	; meters.
	lv = 1.0	; unitless.
	lscm = 1.0	; unitless.

	case 1 of
		(fft_sel ge 0) and (fft_sel le 3):	begin	; SPB V channels.
			gain = gain_v
			freq_resp = spb_resp
			units = units_v
			len = lv
		end
		(fft_sel ge 4) and (fft_sel le 5):	begin	; AXB V channels.
			gain = gain_v
			freq_resp = axb_resp
			units = units_v
			len = lv
		end
		(fft_sel ge 6) and (fft_sel le 7):	begin	; SPB EDC channels.
			gain = gain_edc
			freq_resp = spb_resp
			units = units_edc
			if fft_sel eq 6 then $
				len = l12 else $
				len = l34
		end
		(fft_sel eq 8):	begin	; AXB EDC channels.
			gain = gain_edc
			freq_resp = axb_resp
			units = units_edc
			len = l56
		end
		(fft_sel ge 9) and (fft_sel le 11):	begin	; SCM channels.
			gain = gain_scm
			freq_resp = scm_resp
			units = units_scm
			len = lscm
		end
		(fft_sel ge 12) and (fft_sel le 13):	begin	; SPB EAC channels.
			gain = gain_eac
			freq_resp = spb_resp*eac_resp
			units = units_eac
			if fft_sel eq 12 then $
				len = l12 else $
				len = l34
		end
		(fft_sel eq 14):	begin	; AXB EAC channels.
			gain = gain_eac
			freq_resp = axb_resp*eac_resp
			units = units_eac
			len = l56
		end
		(fft_sel ge 16) and (fft_sel le 17):	begin	; EFI DQ channels.
			gain = gain_edc
			freq_resp = spb_resp
			units = units_edc
			len = l12
		end
		(fft_sel ge 18) and (fft_sel le 19):	begin	; SCM DQ channels.
			gain = gain_scm
			freq_resp = scm_resp
			units = units_scm
			len = lscm
		end
		else:	begin	; invalid source selection.
			gain = !values.f_nan
			freq_resp = !values.f_nan*fltarr( nbins)
			units = 'undef'
			len = !values.f_nan
		end
	endcase

	; lump the ADC->Phys factor, boom length, and freq bin width into a single factor.
	gain = (gain/len)^2/bin_width	; (unit/ADC)^2/Hz.

    ; Correct for Hanning window and bitshift from FFT processor
    ; Bitshift is 4 bits (i.e. *16), and Hanning correction is 4
    gain/=64.

	; convert the total voltage gains into attenuation factors for spectral density,
	; and impose the MAX_ATTEN_FAC limit on the upscaling factor.
	freq_resp = 1./freq_resp^2 < max_atten_fac

	cal_pars = { $
		cal_par_time:cal_par_time, $
		gain:gain, ff:cent_freq, freq_resp:freq_resp, units:units $
	}

return
end
