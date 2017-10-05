;+
;	Procedure:
;		thm_get_fbk_cal_pars
;
;	Purpose:
;		Given the signal source, and begin and end of the time interval,
;	return the filter bank RAW->PHYS transformation parameters.
;
;	Calling Sequence:
;	thm_get_fbk_cal_pars, tbeg, tend, fb_sel, cal_pars=cal_pars

;	Arguements:
;		tbeg, tend	DOUBLE, time in seconds since THEMIS epoch.
;		fb_sel	INT, FilterBank source selection indicator.
;		cal_pars	STRUCT, see Notes below for elements.
;
;
;	Notes:
;	-- use of TBEG and TEND for time-dependent calibration parameters is not currently implemented!
;	-- E-field gains and units are for voltages, not fields, since we have not deployed yet!
;	-- Elements of cal_pars are as follows:
;		gain,	FLOAT, gain of source channel at 0 dB response in (phys unit)/ADC.
;		freq_resp FLOAT[ 6], effective attenuation factor for source channel for each
;			of the six FilterBank channels.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2007-11-16 12:28:13 -0800 (Fri, 16 Nov 2007) $
; $LastChangedRevision: 2043 $
; $URL $
;-
pro thm_get_fbk_cal_pars, tbeg, tend, fb_sel, cal_pars=cal_pars

	; attenuation factors from Flight model measurements plus modeling;
	;	JWB, UCBSSL, 1 Feb 2007.
	cal_par_time = '2002-01-01/00:00:00'

	units_scm = '|nT|'
	units_edc = '|mV/m|'
	units_eac = '|mV/m|'
	units_v = '|V|'

	scm_resp = [ 3.6, 1.4, 1.0, 1.8, 5.6, 25.0]    ; highest frequency first
	spb_resp = [ 1.7, 1.6, 1.2, 1.0, 1.0, 1.0]
	axb_resp = [ 2.5, 2.0, 1.2, 1.0, 1.0, 1.0]
	eac_resp = [ 1.0, 1.0, 1.0, 1.0, 1.8, 3.2]*2
	fbk_dc_resp = [ 0.5, 1.0, 1.0, 1.0, 1.0, 1.0]*2

	adc_factor = 1.0/float( 2L^16 - 1L)/16.0
	gain_v = 2.0*105.2*adc_factor
	gain_edc = 2.0*15.0*adc_factor*1000
	gain_eac = 2.0*2.54*adc_factor*1000
	gain_scm = 2.0*5.0*adc_factor

    len_12=49.6
    len_34=40.4
    len_56=5.63

	case 1 of
		(fb_sel ge 0) and (fb_sel le 3):	begin	; SPB V channels.
			gain = gain_v
			freq_resp = spb_resp*fbk_dc_resp
			units = units_v
		end
		(fb_sel ge 4) and (fb_sel le 5):	begin	; AXB V channels.
			gain = gain_v
			freq_resp = axb_resp*fbk_dc_resp
			units = units_v
		end
		(fb_sel eq 6):	begin	; SPB EDC12
			gain = gain_edc/len_12
			freq_resp = spb_resp*fbk_dc_resp
			units = units_edc
		end
		(fb_sel eq 7):	begin	; SPB EDC34
			gain = gain_edc/len_34
			freq_resp = spb_resp*fbk_dc_resp
			units = units_edc
		end
		(fb_sel eq 8):	begin	; AXB EDC channels.
			gain = gain_edc/len_56
			freq_resp = axb_resp*fbk_dc_resp
			units = units_edc
		end
		(fb_sel ge 9) and (fb_sel le 11):	begin	; SCM channels.
			gain = gain_scm
			freq_resp = scm_resp*fbk_dc_resp
			units = units_scm
		end
		(fb_sel eq 12):	begin	; SPB EAC12
			gain = gain_eac/len_12
			freq_resp = spb_resp*eac_resp
			units = units_eac
		end
		(fb_sel eq 13):	begin	; SPB EAC34
			gain = gain_eac/len_34
			freq_resp = spb_resp*eac_resp
			units = units_eac
		end
		(fb_sel eq 14):	begin	; AXB EAC channels.
			gain = gain_eac/len_56
			freq_resp = axb_resp*eac_resp
			units = units_eac
		end
		else:	begin	; invalid source selection.
			gain = !values.f_nan
			freq_resp = !values.f_nan*fltarr( 6)
			units = 'undef'
		end
	endcase

	cal_pars = { $
		cal_par_time:cal_par_time, $
		gain:gain, freq_resp:freq_resp, units:units $
	}

return
end
