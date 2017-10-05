; rbsp efw summary crib
;
; Kris Kersten, UMN, June 2012
;			email: kris.kersten@gmail.com

; note:  all SPEC, XSPEC data is assumed to have 64 bins

; initialize RBSP environment
rbsp_efw_init


; set desired probe
; note: probe can be string 'a' or 'b' for a single probe, or string
;		array ['a', 'b'] or space-delimited list 'a b' for both probes.
probe = 'a b'


; set time of interest to a single day
date = '2013-02-16'	; UTC.
duration = 1	; days.
timespan, date, duration

integration=0 ; for looking at integration data

; include support data?
get_support_data = 0 ; 0=no, 1=yes

; use raw ADC numbers or physical units?
type='raw' ; use raw for now. for physical units use type='calibrated'


; load data
rbsp_load_efw_waveform, probe=probe,  type=type, $
		get_support_data=get_support_data

;--find burst times and create tplot vars for B1, B2 on,off flag
test_rbsp_efw_burst_times

rbsp_load_efw_spec, probe=probe, type=type, $
		get_support_data=get_support_data, integration=integration

rbsp_load_efw_xspec, probe=probe,type=type, $
		get_support_data=get_support_data, integration=integration

get_support_data=1 ; turn on support data to get fbk select variable
rbsp_load_efw_fbk, probe=probe, type=type, $
		get_support_data=get_support_data, integration=integration



; WAVEFORM  --------------------------------------------------------------------
; split waveform vectors
split_vec, 'rbsp?_efw_esvy', suffix='_'+['E12', 'E34', 'E56']
split_vec, 'rbsp?_efw_vsvy', suffix='_V'+['1','2','3','4','5','6']
split_vec, 'rbsp?_efw_magsvy', suffix='_'+['U', 'V', 'W']
split_vec, 'rbsp?_efw_eb1', suffix='_'+['E12', 'E34', 'E56']
split_vec, 'rbsp?_efw_vb1', suffix='_V'+['1','2','3','4','5','6']
split_vec, 'rbsp?_efw_mscb1', suffix='_'+['U', 'V', 'W']
split_vec, 'rbsp?_efw_eb2', suffix='_'+['E12DC', 'E34DC', 'E56DC', 'E12AC', $
				'E34AC', 'E56AC', 'EDCpar', 'EDCprp', 'EACpar', 'EACprp']
split_vec, 'rbsp?_efw_vb2', suffix='_V'+['1','2','3','4','5','6']
split_vec, 'rbsp?_efw_mscb2', suffix='_'+['U', 'V', 'W', 'par', 'perp']



; SPEC / XSPEC  ----------------------------------------------------------------
; label SPEC
spec_sources=['E12AC', 'E56AC', 'SCMpar', 'SCMperp', 'SCMW', 'V1AC', 'V2AC']
units=' raw counts' ; for now, assume raw counts.  this will change.

; dump everything into the z-axis labels until we sort out proper labeling 
options, '*spec0', 'ztitle', spec_sources[0]+units
options, '*spec1', 'ztitle', spec_sources[1]+units
options, '*spec2', 'ztitle', spec_sources[2]+units
options, '*spec3', 'ztitle', spec_sources[3]+units
options, '*spec4', 'ztitle', spec_sources[4]+units
options, '*spec5', 'ztitle', spec_sources[5]+units
options, '*spec6', 'ztitle', spec_sources[6]+units

; for now the y-axis scaling covers [1,64], so set limits accordingly
ylim, 'rbsp?_efw_64_spec*', 1, 64, 1
options,'rbsp?_efw_64_spec*','yticks',3

; calculate phase,coherence from XSPEC
; CAVEAT: This call assumes we have 64-bin XSPECs.  This will have to be fixed.
;			For now, it *should* just quietly skip the phase and coherence
;			calculation when we have other than 64-bin specs.
test_rbsp_efw_xspec_phase

; for now the y-axis scaling covers [1,64], so set limits accordingly
ylim, 'rbsp?_efw_xspec*', 1, 64, 1
options,'rbsp?_efw_xspec*','yticks',3



; FBK  -------------------------------------------------------------------------
; set up FBK labels based on fbk select variable
fbk_sources=['E12DC', 'E34DC', 'E56DC', 'E12AC', 'E34AC', 'E56AC', $
			'SCMU', 'SCMV', 'SCMW']

get_data,'rbspa_efw_fbk_7_fbk_7_select',data=a7select
get_data,'rbspa_efw_fbk_13_fbk_13_select',data=a13select
get_data,'rbspb_efw_fbk_7_fbk_7_select',data=b7select
get_data,'rbspb_efw_fbk_13_fbk_13_select',data=b13select

; note: the fbk select variables come bach as nX2 arrays, where [*,0] array is
;		the fb1 source as a function of time, and [*,1] is the fb2 source
if is_struct(a7select) then $
	a7_sources=[fbk_sources[median(a7select.y[*,0])], fbk_sources[median(a7select.y[*,1])] ] $
	else a7_sources=['','']
if is_struct(a13select) then $
	a13_sources=[fbk_sources[median(a13select.y[*,0])], fbk_sources[median(a13select.y[*,1])] ] $
	else a13_sources=['','']
if is_struct(b7select) then $
	b7_sources=[fbk_sources[median(b7select.y[*,0])], fbk_sources[median(b7select.y[*,1])] ] $
	else b7_sources=['','']
if is_struct(b13select) then $
	b13_sources=[fbk_sources[median(b13select.y[*,0])], fbk_sources[median(b13select.y[*,1])] ] $
	else b13_sources=['','']
; note: for simplicity we've taken the median value for each channel over the
;		selected time range.  source changes will likely be rare and can be
;		handled on a case-by-case basis

; now turn the sources into labels
units='raw counts'
options,'rbspa_efw_fbk_7_fb1_av','ztitle',a7_sources[0]+'_avg '+units 
options,'rbspa_efw_fbk_7_fb1_pk','ztitle',a7_sources[0]+'_peak '+units 
options,'rbspa_efw_fbk_7_fb2_av','ztitle',a7_sources[1]+'_avg '+units 
options,'rbspa_efw_fbk_7_fb2_pk','ztitle',a7_sources[1]+'_peak '+units 
options,'rbspa_efw_fbk_13_fb1_av','ztitle',a13_sources[0]+'_avg '+units 
options,'rbspa_efw_fbk_13_fb1_pk','ztitle',a13_sources[0]+'_peak '+units 
options,'rbspa_efw_fbk_13_fb2_av','ztitle',a13_sources[1]+'_avg '+units 
options,'rbspa_efw_fbk_13_fb2_pk','ztitle',a13_sources[1]+'_peak '+units 

options,'rbspb_efw_fbk_7_fb1_av','ztitle',b7_sources[0]+'_avg '+units 
options,'rbspb_efw_fbk_7_fb1_pk','ztitle',b7_sources[0]+'_peak '+units 
options,'rbspb_efw_fbk_7_fb2_av','ztitle',b7_sources[1]+'_avg '+units 
options,'rbspb_efw_fbk_7_fb2_pk','ztitle',b7_sources[1]+'_peak '+units 
options,'rbspb_efw_fbk_13_fb1_av','ztitle',b13_sources[0]+'_avg '+units 
options,'rbspb_efw_fbk_13_fb1_pk','ztitle',b13_sources[0]+'_peak '+units 
options,'rbspb_efw_fbk_13_fb2_av','ztitle',b13_sources[1]+'_avg '+units 
options,'rbspb_efw_fbk_13_fb2_pk','ztitle',b13_sources[1]+'_peak '+units 

; for now the y-axis covers [1,13] (FBK13) and [1,7] (FBK7), so set limits
; accordingly
ylim, '*fbk_7*', 1, 7, 1
ylim, '*fbk_13*', 1, 13, 1


; PLOT  ------------------------------------------------------------------------
; global tplot options
tplot_options, 'xmargin', [ 20., 15.]
;options, '*', 'ticklen', 1.0
;options, '*', 'xgridstyle', 1
;options, '*', 'ygridstyle', 1
;options,'*','psym',0
;options,'*','symsize',.5

; spread out the labels
options,'*','labflag',-1

; set up tags for generating various summary plots
svy_summary=['_efw_esvy_E12',$
	'_efw_esvy_E34',$
	'_efw_esvy_E56',$
	'_efw_vsvy_V'+string(lindgen(6)+1, format='(I0)'),$
	'_efw_magsvy_'+['U','V','W'] ]
	
spec_summary=['_efw_64_spec'+string(lindgen(7), format='(I0)')]

xspec_summary=['_efw_xspec_64_xspec0_src1',$
	'_efw_xspec_64_xspec0_src2', $
	'_efw_xspec_64_xspec0_phase', $
	'_efw_xspec_64_xspec0_coh', $
	'_efw_xspec_64_xspec1_src1',$
	'_efw_xspec_64_xspec1_src2', $
	'_efw_xspec_64_xspec1_phase', $
	'_efw_xspec_64_xspec1_coh', $
	'_efw_xspec_64_xspec2_src1',$
	'_efw_xspec_64_xspec2_src2', $
	'_efw_xspec_64_xspec2_phase', $
	'_efw_xspec_64_xspec2_coh', $
	'_efw_xspec_64_xspec2_src1',$
	'_efw_xspec_64_xspec2_src2', $
	'_efw_xspec_64_xspec3_phase', $
	'_efw_xspec_64_xspec3_coh']
	
fbk_summary=['_efw_fbk_7_fb1_av',$
	'_efw_fbk_7_fb1_pk',$
	'_efw_fbk_7_fb2_av',$
	'_efw_fbk_7_fb2_pk',$
	'_efw_fbk_13_fb1_av',$
	'_efw_fbk_13_fb1_pk',$
	'_efw_fbk_13_fb2_av',$
	'_efw_fbk_13_fb2_pk']

combo_summary=['_efw_esvy',$
	'_efw_vsvy',$
	'_efw_magsvy',$
	'_efw_vb1_available',$
	'_efw_vb2_available',$
;	'_efw_fbk_7_fb1_av',$   ; skip avg fbks to cut down on panels
	'_efw_fbk_7_fb1_pk',$
;	'_efw_fbk_13_fb1_av',$
	'_efw_fbk_13_fb1_pk',$
	'_efw_64_spec0',$
	'_efw_64_spec1',$
	'_efw_xspec_64_xspec1_phase',$
	'_efw_xspec_64_xspec1_coh']


; this plotting could go into a for loop over 'rbspa','rbspb', but that's a
; little tricky in a crib.  for now we'll make each plot explicitly.

probeid='rbspa'
; now generate summary plots by combining probeid with summary tag, e.g.:
;tplot, probeid + svy_summary
;tplot, probeid + spec_summary
;tplot, probeid + fbk_summary

tplot_options,'title',strupcase(probeid)+' DAILY SUMMARY, '+date
tplot, probeid + combo_summary

probeid='rbspb'
;tplot, probeid + svy_summary
;tplot, probeid + spec_summary
;tplot, probeid + fbk_summary

tplot_options,'title',strupcase(probeid)+' DAILY SUMMARY, '+date
tplot, probeid + combo_summary



; make PostScript summary plots
; PostScript needs a different !p.charsize setting
old_pcharsize=!p.charsize
!p.charsize=0.7

; RBSPA
probeid='rbspa'
popen,strupcase(probeid)+'_DAILY_SUMMARY_'+strcompress(date,/remove_all),/port
tplot_options,'title',strupcase(probeid)+' DIALY SUMMARY, '+date
tplot, probeid + combo_summary
pclose

; RBSPB
probeid='rbspb'
popen,strupcase(probeid)+'_DAILY_SUMMARY_'+strcompress(date,/remove_all),/port
tplot_options,'title',strupcase(probeid)+' DIALY SUMMARY, '+date
tplot, probeid + combo_summary
pclose

; now reset the charsize
!p.charsize=old_pcharsize


end ; rbsp_efw_summary_crib