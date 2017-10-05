; docformat = 'rst'
;
; NAME:
;    unh_edi_amb_crib
;
; PURPOSE:
;+
;   Plot EDI ambient data
;
; :Categories:
;    MMS, SITL
;
; :Examples:
;   To use::
;       IDL> .r unh_edi_amb_crib
;
; :Author:
;    Matthew Argall::
;    University of New Hampshire
;    Morse Hall Room 348
;    8 College Road
;    Durham, NH 03824
;    matthew.argall@unh.edu
;
; :History:
;    Modification History::
;       2015/08/03  -   Written by Matthew Argall
;       2015/09/06  -   Include EDP E-field. Plot 0 & 180 separately. - MRA
;       2015/10/09  -   Plot any telemetry mode. - MRA
;-
;*****************************************************************************************


;timespan,'2015-09-11/09:46:32', 1, /SECOND

;Set the time range and spacecraft ID
timespan,'2015-09-11/09:40:00', 10, /MINUTES
sc_id   = 'mms4'
mode    = 'brst'  ;'slow', 'fast', 'srvy', or 'brst'
load_fgm = 1
load_edp = 1
load_edi = 1

;Load Data into TPlot
;   - FGM takes forever to load because it reads attitude data and despins.
if load_fgm then mms_load_fgm, PROBES=strmid(sc_id,3), LEVEL='ql', DATA_RATE=mode
if load_edp then mms_load_edp, PROBES=strmid(sc_id,3), LEVEL='ql', DATA_RATE=mode, DATATYPE='dce';, SUFFIX=''
	
;No srvy files exist. Combine slow and fast.
if load_edi then begin
	if mode eq 'srvy' $
		then mms_sitl_get_edi_amb, SC_ID=sc_id, MODE=['slow', 'fast'] $
		else mms_sitl_get_edi_amb, SC_ID=sc_id, MODE=mode
endif

;-----------------------------------------------------
; MMS Colors \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------

;Load colors into color table. MMS Colors:
;   - MMS1:  BLACK (change to white if using dark background)
;   - MMS2:  RED
;   - MMS3:  GREEN
;   - MMS4:  BLUE
;   - X,Y,Z is BLUE, GREEN, RED, solid, dashed, dotted  
;
;   - Red = RGB [213, 94, 0] 
;   - Green = RGB [0, 158, 115]   
;   - Blue = RGB [86, 180, 233]
tvlct, r, g, b, /GET
red   = [[213], [ 94], [  0]]
green = [[  0], [158], [115]]
blue  = [[ 86], [180], [233]]

ired   = 1
igreen = 2
iblue  = 3
tvlct, red,   ired
tvlct, green, igreen
tvlct, blue,  iblue

;-----------------------------------------------------
; DFG \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------
;Set plot properties
options, sc_id + '_dfg_' + mode + '_gsm_dmpa', 'colors', [iblue, igreen, ired]
options, sc_id + '_dfg_' + mode + '_gsm_dmpa', 'labels', ['Bx', 'By', 'Bz']
options, sc_id + '_dfg_' + mode + '_gsm_dmpa', 'yrange', [-100, 100]
options, sc_id + '_dfg_' + mode + '_gsm_dmpa', 'labflag', -1

;-----------------------------------------------------
; EDP \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------
;Set plot properties
options, sc_id + '_edp_' + mode + '_dce_dsl', 'colors', [iblue, igreen, ired]
options, sc_id + '_edp_' + mode + '_dce_dsl', 'labels', ['Ex', 'Ey', 'Ez']
options, sc_id + '_edp_' + mode + '_dce_dsl', 'yrange', [-30, 30]
options, sc_id + '_edp_' + mode + '_dce_dsl', 'labflag', -1

;-----------------------------------------------------
; EDI \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------
;
; Instead of plotting counts from GDU1 and GDU2, plot
; 0 & 180 degree pitch angle counts.
;

;Burst has more data
;   - So far, we have been operating such that the magnetic field is
;     centered between pads 2 and 3. So, for pitch angle 0 or 180
;     +/- 11.25 degrees (angular width of each pad), we average counts
;     from pads 2 and 3 and discard the others
;   - Furthermore, in burst mode, EDI samples faster than FGM can send
;     magnetic field information. Therefore, the pitch angle data
;     is at a slower cadence than the couts data. We need to interpolate.
if mode eq 'brst' then begin
	;Pitch angle data
	get_data, sc_id + '_edi_pitch_gdu1', DATA=pitch_gdu1
	get_data, sc_id + '_edi_pitch_gdu2', DATA=pitch_gdu2
	
	;Get data from pads 2 and 3
	get_data, sc_id + '_edi_amb_gdu1_raw_counts2', DATA=gdu1_counts2
	get_data, sc_id + '_edi_amb_gdu2_raw_counts2', DATA=gdu2_counts2
	get_data, sc_id + '_edi_amb_gdu1_raw_counts3', DATA=gdu1_counts3
	get_data, sc_id + '_edi_amb_gdu2_raw_counts3', DATA=gdu2_counts3
	
	;Average their counts
	gdu1_counts1 = {x: gdu1_counts2.x, y: (gdu1_counts2.y + gdu1_counts3.y) / 2L}
	gdu2_counts1 = {x: gdu2_counts2.x, y: (gdu2_counts2.y + gdu2_counts3.y) / 2L}
	
	;Delete data
	undefine, gdu1_counts2, gdu1_counts3, gdu2_counts2, gdu2_counts3
	
	;Interpolate pitch angle data
	;   - Associate counts with the last available pitch angle data point.
;	ipitch_gdu1 = value_locate(pitch_gdu1.x, gdu1_counts1.x) > 0
;	ipitch_gdu2 = value_locate(pitch_gdu2.x, gdu2_counts1.x) > 0
;	pitch_gdu1  = {x: gdu1_counts1.x, y: pitch_gdu1.y[ipitch_gdu1]}
;	pitch_gdu2  = {x: gdu2_counts1.x, y: pitch_gdu2.y[ipitch_gdu2]}
	
	;Store new data
;	store_data, sc_id + '_edi_pitch_gdu1_interp',           DATA=pitch_gdu1
;	store_data, sc_id + '_edi_pitch_gdu2_interp',           DATA=pitch_gdu2
;	store_data, sc_id + '_edi_amb_gdu1_raw_counts1_interp', DATA=gdu1_counts1
;	store_data, sc_id + '_edi_amb_gdu2_raw_counts1_interp', DATA=gdu2_counts1
	
	
;Survey-level data
endif else begin
	get_data, sc_id + '_edi_pitch_gdu1',           DATA=pitch_gdu1
	get_data, sc_id + '_edi_pitch_gdu2',           DATA=pitch_gdu2
	get_data, sc_id + '_edi_amb_gdu1_raw_counts1', DATA=gdu1_counts1
	get_data, sc_id + '_edi_amb_gdu2_raw_counts1', DATA=gdu2_counts1
endelse

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
	t_0      = [ gdu1_counts1.x[igdu1_0], gdu2_counts1.x[igdu2_0] ]
	counts_0 = [ gdu1_counts1.y[igdu1_0], gdu2_counts1.y[igdu2_0] ]
	
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
	t_0      = gdu1_counts1.x[igdu1_0]
	counts_0 = gdu1_counts1.y[igdu1_0]
	gdu_0    = replicate(1B, ngdu1_0)

;Only GDU2 data
endif else if ngdu2_0 gt 0 then begin
	t_0      = gdu2_counts1.x[igdu2_0]
	counts_0 = gdu2_counts1.y[igdu2_0]
	gdu_0    = replicate(2B, ngdu2_0)

;No EDI data
endif else begin
	message, 'No 0 degree pitch angle data.', /INFORMATIONAL
	t_0      = 0
	counts_0 = -1
endelse

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
	t_180      = [ gdu1_counts1.x[igdu1_180], gdu2_counts1.x[igdu2_180] ]
	counts_180 = [ gdu1_counts1.y[igdu1_180], gdu2_counts1.y[igdu2_180] ]
	
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
	t_180      = gdu1_counts1.x[igdu1_180]
	counts_180 = gdu1_counts1.y[igdu1_180]
	gdu_180    = replicate(1B, ngdu1_180)

;Only GDU2 data
endif else if ngdu2_180gdu2_counts1 gt 0 then begin
	t_180      = gdu2_counts1.x[igdu2_180]
	counts_180 = gdu2_counts1.y[igdu2_180]
	gdu_180    = replicate(2B, ngdu2_180)
	
;No EDI data
endif else begin
	message, 'No 180 degree pitch angle data.', /INFORMATIONAL
	t_180 = 0
	counts_180 = -1
endelse

;Store data
if n_elements(counts_180) gt 0 $
	then store_data, sc_id + '_edi_amb_pa180_raw_counts', DATA={x: t_180, y: counts_180}

;Set options
options, sc_id + '_edi_amb_pa180_raw_counts', 'ylog', 1

;-----------------------------------------------------
; Plot \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------

;Plot the data
;   1. B GSM-DMPA
;   2. E DSL
;   3. Counts GDU1
;   4. Counts GDU2
tplot, [sc_id + '_dfg_' + mode + '_gsm_dmpa', $
        sc_id + '_edp_' + mode + '_dce_dsl', $
        sc_id + '_edi_amb_pa0_raw_counts', $
        sc_id + '_edi_amb_pa180_raw_counts']
end