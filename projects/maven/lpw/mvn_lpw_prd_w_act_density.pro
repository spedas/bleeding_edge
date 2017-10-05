;+
; NAME:
; 	mvn_lpw_prd_w_act_density
; PURPOSE:
; 	Operates on loaded tplot_variable named "mvn_lpw_spec_hf_act"
; 	Creates new variables
;		'mvn_lpw_spec2_hf_act_bgdsub': Background-supressed spectra (dB above background)
;		'mvn_lpw_spec2_hf_act_density': Determined plasma density (cc) from the location of the peak signal.
; 			The errors dy and dv give the lower and upper errors, determined from the width of the peak.
;               'mvn_lpw_spec2_hf_act_conf': A rough confidence estimate.  100 being OK, 0 being bad.  Trust anything _above_ 50, for now.
;		'mvn_lpw_spec2_hf_act_flag': Bitfield flag for plasma density
; 			Any flag = 0 indicates good data with no noted issues.
; 			Otherwise, "(flag AND flag_ID) NE 0" indicates that flag_ID is True, where flag_ID
; 			is one of
;				HF_ACT_DENSITY__ERR__SNR_TOO_LOW = 1; Peak SNR too low (<HF_ACT_MIN_SNR)
;				HF_ACT_DENSITY__ERR__HWHM_UNDEF  = 2 ; HWHM could not be determined
;				HF_ACT_DENSITY__ERR__PK_NONUNIQ  = 4 ; Peak is non-unique
;				HF_ACT_DENSITY__ERR__PKWIDTH_UNDEF = 8; Peak width could not be determined
;				HF_ACT_DENSITY__ERR__OFFSCALE_HIGH = 16 ; Frequency located is too high;
;		'mvn_lpw_spec2_hf_act_snr':  SNR for the located peak (dB above background)
;		'mvn_lpw_spec2_hf_act_density_adj': Tweaked density, based on weighted average of the nearest values to the peak.
; CATEGORY:
; 	MVN_LPW
; KEYWORD PARAMETERS:
; 	print_out and plot_out: For debugging purposes
; MODIFICATION HISTORY:
; 2015-01-20: Created by david.andrews@irfu.se
; 2015-01-28: DA: added condfidence penalty to data with MIN_SNR > SNR > LOW_SNR.  V2.
; 2015-02-03: DA: added a mode flag, default to 'act', but allows running same routine for passive sounding.  Doesn't work well though.
; 2015-02-03: DA: rejigged errors, now providing independent upper and lower values, at which the peak falls to background levels.
; 2015-02-05: DA: tplot variable storing the located frequency is now created by default. V3
; 2015-02-06: DA: applied a small 3% shift to the peak locator, to favour lower frequencies over heigher ones.  
;                 Also now uses spec2 rather than spec, so that we are now in physical units (?).
;                 This has had a knock-on effect of changing the SNR thresholds upwards.
; 2015-03-24: DA: V6. Version delivered today, for use in L2 generation. No shifts are now applied.  
; 		  An attempt is made to flag off-scale-high measurements, and add a confidence penalty here.
; 2015-04-28: DA: Fixed for the L2 generation.  Off-scale high test uses SPICE altitudes and SZA to derive an expected density
;                 If we're off significnatly from this value, then flagged as bad data.  This can maybe be improved in the future. 
;2015-11-10   Remove the line to get the spice kernels, this is done in load
;-

FUNCTION _fp_to_ne, x, err=err
	IF N_ELEMENTS(err) NE 0 THEN err = (2. / 8980.^2.) * x * err
	return, (x / 8980.0)^2.
END

FUNCTION _ne_to_fp, x, err=err
	IF N_ELEMENTS(err) NE 0 THEN err = 8980. / 2. / SQRT(x) * err
	return, SQRT(x) * 8980.
END

FUNCTION _find_peaks, x
	dx0 = x - SHIFT(x, 1)
	dx1 = x - SHIFT(x, -1)
	inx = WHERE( (dx0 GT 0.) AND (dx1 GT 0.), count)
	RETURN, inx[REVERSE(SORT(x[inx]))]
END


pro mvn_lpw_prd_w_act_density, print_out=print_out, plot_out=plot_out, mode=mode, bgdinx=bgdinx
	COMPILE_OPT IDL2
	start_time = SYSTIME(/SECONDS)

	IF ~KEYWORD_SET(mode) THEN mode = 'act'
	IF ~KEYWORD_SET(print_out) THEN print_out = 0
	IF ~KEYWORD_SET(plot_out) THEN plot_out = 0

	; Flag constants - to go into the constant file, maybe?
	HF_ACT_DENSITY__ERR__SNR_TOO_LOW = 1; Peak SNR too low (<HF_ACT_MIN_SNR)
	HF_ACT_DENSITY__ERR__ERROR_UNDEF  = 2 ; HWHM could not be determined
	HF_ACT_DENSITY__ERR__PK_NONUNIQ  = 4 ; Peak is non-unique
	HF_ACT_DENSITY__ERR__PKWIDTH_UNDEF = 8; Peak width could not be determined
	HF_ACT_DENSITY__ERR__OFFSCALE_HIGH = 16 ; Frequency located is too high

	HF_ACT_MIN_SNR = 20 ; dB
	HF_ACT_LOW_SNR = 30 ; dB
        
	MAX_FREQUENCY_BEFORE_OFFSCALE = 1734656.0; A few bins from maximum

	; HF_ACT_MIN_SNR = -!values.F_infinity
	; HF_ACT_LOW_SNR = -!values.f_infinity
        
	F_RANGE = [1e3, 3e6]
	; F_RANGE = [5e5, 2e6]

	IF mode EQ 'pas' THEN BEGIN
		MESSAGE, 'mode=pas is not supported (as of 2015-02-03)'
		; HF_ACT_MIN_SNR = 7
		; HF_ACT_LOW_SNR = 14
	ENDIF
	prefix = 'mvn_lpw_spec_hf_' + mode
	
	GET_DATA, prefix, data_str=data, limit=limit, dlimit=dlimit
	
	prefix = 'mvn_lpw_spec2_hf_' + mode

	npts = (SIZE(data.x,/DIMENSION))[0]
	nfreqs = (size(data.y,/dim))[1]
	
	; These will get used to store the located frequencies first, before 
	; conversion to density at the end of the routine
	density = FLTARR(npts) + !Values.F_NAN
	density_error = FLTARR(npts) + !Values.F_INFINITY
	density_flag = INTARR(npts) 
	density_confidence = FLTARR(npts) + 100.

	density_adj = FLTARR(npts) + !Values.F_NAN
	peak_snr    = FLTARR(npts) + !Values.F_NAN
	
	density_error_2 = FLTARR(npts, 2) + !VALUES.F_INFINITY	
	bgd_sub = data.y * 1.; need a copy
	
	secondary_peak = FLTARR(npts) + !Values.F_NAN
	secondary_snr = FLTARR(npts) + !Values.F_NAN

	primary_secondary_ratios = FLTARR(npts) + !VALUES.F_NAN

	; Background subtraction
	mv = MEDIAN(bgd_sub)
	FOR i=0L, nfreqs - 1 DO BEGIN
		bgd = MEDIAN(bgd_sub[*,i]) ;* mv
		bgd_sub[*,i] = 20. * ALOG10(bgd_sub[*,i] / bgd)
	ENDFOR

	bad_value = 1.; MIN(bgd_sub)
	bgd_sub[WHERE(bgd_sub LT 3.)] = bad_value	

	; Zero-out problem frequency bins
	bad_bins = [0,1,2,3,4,5, 6, 127]
	FOR i=0, N_ELEMENTS(bad_bins) - 1 DO BEGIN
		bgd_sub[*,bad_bins[i]] = bad_value
	ENDFOR

	; Error idenfitication
	ERROR_SEARCH = 10 ; Only search the nearest +/-FWHM_SEARCH points ...
	ERROR_SEARCH_INX = INDGEN(2 * ERROR_SEARCH) - ERROR_SEARCH

	; We need to have SZA and ALT info available, in order to flag likely off-scale-high data
	;MVN_LPW_ANC_GET_SPICE_KERNELS, [TIME_STRING(data.x[0]), TIME_STRING(data.x[-1])]
	MVN_LPW_ANC_SPACECRAFT,data.x
	GET_DATA, 'mvn_lpw_anc_mvn_pos_mso', data=d
	sza = !RADEG * ATAN(SQRT(d.y[*,1]^2 + d.y[*,2]^2), d.y[*,0])
	; altitude = (SQRT(d.y[*,0]^2 + d.y[*,1]^2 + d.y[*,2]^2) - 1.) * 3390.
	inx = WHERE(sza LT 0, count)
	IF count GT 0 THEN sza[inx] = 180. + sza[inx]
	STORE_DATA, 'mvn_lpw_anc_mvn_sza', data={x:data.x, y:sza}, $
		dlimit={yrange:[0.,180.], ylabel:'SZA/deg'}
	
	GET_DATA, 'mvn_lpw_anc_mvn_alt_iau', data=d
	altitude = d.y

	; Create a vector to multiply the peak heights by, that favours lower frequencies  	
	; scale = 0. ; A % shift in the peak height between frequency f[i] and f[i+1]
	; scale_arr = FINDGEN(nfreqs) / (nfreqs - 1.) * scale + 1.
	; PRINT, 'Scaling from ', scale_arr[0], ' to ', scale_arr[-1]
	
	; The 98th percentile of the whole orbit data
	n = ULONG64(n_elements(bgd_sub) * 0.98)
	GLOBAL_ERROR_VALUE = (bgd_sub[SORT(bgd_sub)])[n]
        
	; Signals are quantised, which causes problems with the peak finding
	; (Adjacent numerically identical points are likely)
	; An unbiased solution is to multiply each by a unique small random factor
	seed = SYSTIME(/SECONDS)
	s = (DINDGEN(nfreqs) / (nfreqs-1.) - 0.5) * 1e-5 + 1.
	shuffle = s[SORT(RANDOMU(seed,nfreqs))]
	
	FOR j=0, npts -1 DO BEGIN
		; Locate all peaks, sorted by size
		peak_inxes = _find_peaks(bgd_sub[j,*] * shuffle)

		sig = bgd_sub[j, peak_inxes[0]] ; First is the biggest
		inx = peak_inxes[0]
		
		; Our primary results
		peak_snr[j] = sig
		density[j] = data.v[j,inx]
		
		; Secondary peak
		secondary_snr[j] = bgd_sub[j, peak_inxes[1]]
		secondary_peak[j] = data.v[j, peak_inxes[1]]

		IF secondary_snr[j] LT HF_ACT_MIN_SNR THEN BEGIN ; Do we trust the secondary?
			secondary_peak[j] = !VALUES.F_NAN	
		ENDIF ELSE BEGIN ; If we do, we note it in the flag & confidences
			density_flag[j] += HF_ACT_DENSITY__ERR__PK_NONUNIQ
			density_confidence[j] -= 30.
		ENDELSE
		
		; Do we trust the primary?
		IF sig LT HF_ACT_MIN_SNR THEN BEGIN
			density_flag[j] += HF_ACT_DENSITY__ERR__SNR_TOO_LOW
			density_confidence[j] = 0.0 ; Alternatively, we could set to !Values.F_NAN?
			density[j] = !VALUES.F_NAN
			CONTINUE ; If not, next point
		ENDIF
		
		primary_secondary_ratios[j] = secondary_peak[j] / density[j]

		IF sig LT HF_ACT_LOW_SNR THEN BEGIN
			density_confidence[j] -= 10. ;
		ENDIF
		
		; This tried to do a sub-bin estimate of the peak frequency, by comparing the height of the adjacent
		; bins to the peak.  The tiny shift it introduces is way smaller than the HWHM
		; so it's probably not worth persuing.
		; density_adj[j] = $
		; 	(bgd_sub[j,inx] * data.v[j,inx] + bgd_sub[j,inx-1] * data.v[j,inx-1] + bgd_sub[j,inx+1] * data.v[j,inx+1]) $
		; 	/ (bgd_sub[j,inx] + bgd_sub[j,inx-1] + bgd_sub[j,inx+1])


		;-------------
		; Error estimate based on the spectral width
		; Locate the first point above/below the peak with signal below $error_value to determine upper/lower bound
		upper = !Values.F_Infinity
		lower = !Values.F_Infinity
		uinx = -1 & linx = -1
	
		values = bgd_sub[j,*]
		error_value = sig - 6.02 ; 6.02 = 20. ALOG10(2) ; FWHM (narrowest errors)
		; error_value = (values[SORT(values)])[96] ; 75th percentile of each 128-element column
		; error_value = GLOBAL_ERROR_VALUE         ; Or of the whole orbits worth of data
		error_value = HF_ACT_MIN_SNR - 6.02         ; Half of the minimum acceptable signal (broad errors)
		; error_value = sig - 20.                    ; 10% of the peak (narrower errors)
		
		; upper
		error_inx = WHERE(values[inx:nfreqs-1] LT error_value, count)
		IF count GT 0 THEN BEGIN
			uinx = MIN(error_inx) + inx
			upper = data.v[j, uinx]
		ENDIF

		; lower
		error_inx = WHERE(values[0:inx-1] LT error_value, count)
		IF count GT 0 THEN BEGIN
			linx = MAX(error_inx) 
			lower = data.v[j, linx]
		ENDIF

		IF (~FINITE(upper * lower)) THEN BEGIN ; Bad if either were undefined
			density_flag[j] += HF_ACT_DENSITY__ERR__ERROR_UNDEF
			density_confidence[j] -= 50.
		ENDIF

		density_error[j] = (upper - lower) / 2.0 
		density_error_2[j,0] = density[j] - lower
		density_error_2[j,1] = upper - density[j]
		
		; Check for off-scale-high - two different methods used.
		; Approximate SZA and altitude where we expect f > 2.2 MHz
		IF (sza[j] LT 80.) AND (altitude[j] LT 190.) THEN BEGIN
			IF density[j] LT 1.E6 THEN BEGIN
				PRINT, TIME_STRING(data.x[j]), sza[j], altitude[j], density[j]
				density[j] = !VALUES.F_NAN
				density_flag[j] += HF_ACT_DENSITY__ERR__OFFSCALE_HIGH

			ENDIF
		ENDIF
		
		IF (density_flag[j] AND HF_ACT_DENSITY__ERR__OFFSCALE_HIGH) EQ 0 THEN BEGIN
			; Off-scale high test, to try to locate any saturation that may be present
			IF density[j] GT MAX_FREQUENCY_BEFORE_OFFSCALE THEN BEGIN
				density_flag[j] += HF_ACT_DENSITY__ERR__OFFSCALE_HIGH
				density_confidence[j] -= 30.
			; A weaker test, which doesn't set the flag but adds a small penalty to confidence
			ENDIF ELSE IF upper GT MAX_FREQUENCY_BEFORE_OFFSCALE THEN BEGIN
				density_confidence[j] -= 5.
			ENDIF
		ENDIF

		; Make a distinction between absolutely zero (see line ~186) and passing through this far
		IF density_confidence[j] LT 0. THEN density_confidence[j] = 10. 

		IF print_out THEN $
			print, j, upper, lower, density_error_2[j,0], density_error_2[j,1], density_flag[j], $
				(density_flag[j] AND HF_ACT_DENSITY__ERR__OFFSCALE_HIGH) NE 0

	ENDFOR
	
	; Store located frequencies & errors
	STORE_DATA, prefix + '_frequency', data={x:data.x, y:density, dy:density_error_2[*,0], dv:density_error_2[*,1]}, $
		limit={ylog:1, ytitle:"ACT_PK_F / Hz"}

	; Conversions frequencies to densities, accounting for errors
	tmp = density ; store as frequency briefly
	density = _fp_to_ne(density, err=density_error)
	density_adj = _fp_to_ne(density_adj)
	
	e = density_error_2[*,0]
	junk = _fp_to_ne(tmp, err=e)
	density_error_2[*,0] = e
	
	e = density_error_2[*,1]
	junk = _fp_to_ne(tmp, err=e)
	density_error_2[*,1] = e

	; Construct new TPLOT variables
	limit.ztitle = "dB"
	limit.zrange = [1.,100.]
	data.y[*] = bgd_sub[*] ; Replace for storage in new variable
	STORE_DATA, prefix + '_bgdsub', data=data, limit=limit, dlimit=dlimit
	OPTIONS, prefix + '_bgdsub', ytitle="HF_ACT BGD_SUB"

	; STORE_DATA, prefix + '_density', data={x:data.x, y:density, dy:density_error}, limit={ylog:1, ytitle:'Ne/cm!u-3!d'}
	STORE_DATA, prefix + '_density', data={x:data.x, y:density, dy:density_error_2[*,0], dv:density_error_2[*,1]}, $
								limit={ylog:1, ytitle:'Ne/cm!u-3!n'}

	STORE_DATA, prefix + '_flag', data={x:data.x, y:density_flag}, limit={yrange:[0,32], ytitle:'HF_ACT!cFlag'}
	STORE_DATA, prefix + '_conf', data={x:data.x, y:density_confidence}, limit={yrange:[-5,105], ytitle:'HF_ACT!cConfidence'}
	STORE_DATA, prefix + '_snr', data={x:data.x, y:peak_snr}, limit={ylog:1, ytitle:'HF_ACT!nSNR / dB', yrange:[1,300]}
	
	; DA doesn't think this is particularly useful:
	; STORE_DATA, prefix + '_density_adj', data={x:data.x, y:density_adj, dy:density_error}, $
	; 		limit={ylog:1, color:64, ytitle:'Ne*/cm!u-3!n'}

	STORE_DATA, prefix + '_secondary_peak_f', data={x:data.x, y:secondary_peak}, limit={ylog:1, color:2}
	STORE_DATA, prefix + '_secondary_peak', data={x:data.x, y:_fp_to_ne(secondary_peak)}, $
				limit={ylog:1, ytitle:'SecondaryPeak/cm!u-3!n', color:2}

	STORE_DATA, prefix + '_secondary_snr', data={x:data.x, y:secondary_snr}, limit={ylog:1, color:2}
	
	finish_time = SYSTIME(/SECONDS)
	MESSAGE, 'Completed after ' + STRING(finish_time - start_time) + ' seconds',/INFO

	IF plot_out THEN BEGIN
		STORE_DATA, prefix + '_density_low', data={x:data.x, y:density - density_error_2[*,0]}, $
				limit={ylog:1, ytitle:'Ne_low/cm!u-3!n', color:1}
		STORE_DATA, prefix + '_density_high', data={x:data.x, y:density + density_error_2[*,1]}, $
				limit={ylog:1, ytitle:'Ne_high/cm!u-3!n', color:1}

		STORE_DATA, 'tmp2', data=[prefix + '_density', prefix + '_density_low', prefix + '_density_high', $
			prefix + '_secondary_peak']

		OPTIONS, 'tmp2', yrange=[1e0, 1e5]

		GET_DATA, prefix + '_frequency', data_str=d
		STORE_DATA, 'flow', data={x:d.x, y:d.y - d.dy}, limit={ylog:1, color:1, thick:1.2, yrange:[1e3, 3e6]}
		STORE_DATA, 'fhigh', data={x:d.x, y:d.y + d.dv}, limit={ylog:1, color:1, thick:1.2, yrange:[1e3, 3e6]}
		STORE_DATA, 'fmid', data={x:d.x, y:d.y, dy:density_error}, limit={ylog:1, color:7, thick:1.2, yrange:[1e3, 3e6]}

		STORE_DATA, 'tmp', data=[prefix + '', 'flow', 'fhigh', 'fmid', prefix + '_secondary_peak_f']
		OPTIONS, 'tmp', yrange=F_RANGE

		STORE_DATA, 'tmp3', data=[prefix + '_snr', prefix + '_secondary_snr']

		STORE_DATA, 'tmp4', data=[prefix + '_bgdsub', 'flow', 'fhigh']
		OPTIONS, 'tmp4', yrange=F_RANGE
		
		ZLIM, 'mvn_lpw_spec2_hf_pas', 1e-15,1e-10
		STORE_DATA, 'tmp5', data=['mvn_lpw_spec2_hf_pas', 'flow', 'fhigh', 'fmid', prefix + '_secondary_peak_f']
		OPTIONS, 'tmp5', yrange=F_RANGE

		ZLIM, 'tmp',1e-15, 1e-10

		OPTIONS,'mvn_lpw_anc_mvn_alt_iau', ylog=1
		; TPLOT, ['tmp2', 'tmp', 'tmp4', 'mvn_lpw_spec2_hf_pas', 'tmp3', prefix + '_conf', prefix + '_flag']
		TPLOT, ['tmp2', 'tmp', 'tmp4','tmp3', prefix + '_flag', 'mvn_lpw_anc_mvn_alt_iau', 'mvn_lpw_anc_mvn_sza']
		
		; TPLOT, 'tmp'
		; STORE_DATA, 'junk', data={x:data.x, y:other_peak}
	ENDIF
END

FUNCTION MSO_TO_SZA, x
	sza = !RADEG * ATAN(SQRT(x[*,1]^2 + x[*,2]^2), x[*,0])
	inx = WHERE(sza LT 0, count)
	IF count THEN sza[inx] = 180 + sza[inx]
	RETURN, sza
END

PRO TEST_HF_ACT_DETERMINATION

	; MVN_LPW_LOAD, '2014-11-12', packet=['NoHSBM']
	; DJA_HF_ACT_DENSITY_V1

	mk = MVN_SPICE_KERNELS(/all,/load,verbose=1)
	PRINT, mk
	
	GET_DATA, 'mvn_lpw_spec_hf_act_density', data_str=data_str
	time = data_str.x
	density = data_str.y
	density_error = data_str.dy

	GET_DATA, 'mvn_lpw_spec_hf_act_density_adj', data_str=data_str
	density_adj = data_str.y

	GET_DATA, 'mvn_lpw_spec_hf_act_flag', data_str=d
	flag = d.y
	inx = WHERE(flag EQ 0)

	WINDOW, 0 & ERASE
	PLOT, density, density_error, psym=4, ytitle='DN / cc', xtitle='N / cc', /ylog, /xlog
	OPLOT, density[inx], density_error[inx], psym=2, color=1

	WINDOW, 1 & ERASE
	PLOT, density, ABS(density - density_adj), psym=4, ytitle='|N - N*| / cc', xtitle='N / cc', /ylog, /xlog
	OPLOT, density[inx], ABS(density[inx] - density_adj[inx]), psym=2, color=120

	SPICE_POSITION_TO_TPLOT, 'MAVEN','MARS',frame='MSO', ut=time, scale=3396., name=n
	GET_DATA, n, data_str=data_str
	HELP, data_str,/struct

	sza = MSO_TO_SZA(data_str.y)

	WINDOW, 2 & ERASE
	PLOT, sza, density, psym=4, xtitle='SZA / deg', ytitle='N / cc', /YLOG
	OPLOT, sza[inx], density[inx], psym=2, color=120


	WINDOW, 3 & ERASE
	PLOT, time, sza, psym=4

	WINDOW, 4 & ERASE
	PLOT, time, data_str.y[*,0], psym=0, color=94
	OPLOT, time, data_str.y[*,1], psym=0, color=29
	OPLOT, time, data_str.y[*,2], psym=0, color=156
		
END

PRO PLOT_ALL_PINGS
	; 4hr 	
	; ping_orbits = [239, 240, 529]
	ping_orbits = [529]
	mvn_orbs = MVN_ORBIT_NUM()
	end_time = TIME_DOUBLE('2015-01-20')

	inx = WHERE(mvn_orbs.peri_time GT TIME_DOUBLE('2015-01-07'))
	PRINT, '>', mvn_orbs[inx[0]].num

	i = 0L
	orbit = -99

	loaded_day = 'XXX'

	; WHILE 1 DO BEGIN
	; 	IF i LE N_ELEMENTS(ping_orbits) - 1 THEN BEGIN
	; 		orbit = ping_orbits[i]
	; 	ENDIF ELSE BEGIN
	; 		orbit += 1
	; 	ENDELSE
	; 	PRINT, '================'
	; 	PRINT, i, orbit, loaded_day
	; 	inx = WHERE(mvn_orbs.num EQ orbit)
	; 	start = mvn_orbs[inx].peri_time - 60. * 30
	; 	finish = mvn_orbs[inx].peri_time + 60. * 30
	; 	
	; 	day = STRMID(TIME_STRING(start), 0, 10)
	; 	IF ~STRCMP(day, loaded_day) THEN BEGIN
	; 		MVN_LPW_LOAD, day, packet=['SPEC', 'HSK']
	; 		loaded_day = day
	; 	ENDIF
	; 	TLIMIT, start, finish
	; 	POPEN, 'DJA_HF_ACT_' + STRING(mvn_orbs[inx].num) + '.ps'
	; 	DJA_HF_ACT_DENSITY_V1
	; 	PCLOSE
	; 	i += 1
        ;
	; ENDWHILE
	
	start = TIME_DOUBLE('2015-01-07')
	loaded_day = 'XXX'
	i = 0
	WHILE 1 DO BEGIN
		IF start GT end_time THEN BREAK

		day = STRMID(TIME_STRING(start), 0, 10)
		IF ~STRCMP(day, loaded_day) THEN BEGIN
			MVN_LPW_LOAD, day, packet=['SPEC', 'HSK']
			loaded_day = day
			i = 0
		ENDIF
		finish = start + 3600. * 4
		TLIMIT, start, finish
		POPEN, 'DJA_HF_ACT_' + loaded_day + '_' +  STRING(i) + '.ps'
		DJA_HF_ACT_DENSITY_V1,/plot_out
		PCLOSE
		start += 3600 * 4
		i += 1
	ENDWHILE
END

PRO TEST_PEAKS, x
	ERASE
	; x = [0,0,0,0,1,1,1,0,0,0]

	p0 = _find_peaks(x)
	PLOT, x
	OPLOT, p0, x[p0], psym=4
END


