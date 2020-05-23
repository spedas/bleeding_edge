;+
; NAME: rbsp_efw_xspec_crib.pro
; SYNTAX:
; PURPOSE: Create tplot variables pertaining to the EFW cross-spectral product
; INPUT:
; OUTPUT:
; KEYWORDS:
;	PROCEDURE: .run b1_status_crib
; HISTORY: Kris Kersten, UMN, June 2012 (kris.kersten@gmail.com)
; 				 Modified by Aaron Breneman, UMN, Dec 2012 (awbrenem@gmail.com)
; VERSION:
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2020-05-21 20:36:46 -0700 (Thu, 21 May 2020) $
;   $LastChangedRevision: 28720 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_xspec_crib.pro $
;-


;initialize RBSP environment
rbsp_efw_init

;set desired probe
probe = 'a'

;set time of interest to a single day
date = '2012-10-13'	; UTC.
duration = 1	; days.
timespan, date, duration

;Set other quantities
integration=0 ; for looking at integration data
get_support_data = 0 ; include support data? 0=no, 1=yes
suffix = ''
type='calibrated' ;use ADC (raw) numbers or physical (calibrated) units?



;Load the data
rbsp_load_efw_xspec,$
	probe=probe,$
	type=type,$
	get_support_data=get_support_data,$
	integration=integration


;Get burst availability
rbsp_load_efw_burst_times,probe=probe
options,'rbsp'+probe+'_efw_vb1_available','colors',0
options,'rbsp'+probe+'_efw_vb2_available','colors',0



;Optional: Add in fce lines to the spec. Need EMFISIS data for this
speclist = tnames('*_xspec*')
rbsp_add_fce2spec,speclist,probe,period=period


suffix = '_fce'


;64 bins per FFT for entire mission
bins = '64'


;Plot options
charsz_plot = 0.8  ;character size for plots
charsz_win = 1.2
!p.charsize = charsz_win
tplot_options,'xmargin',[20.,15.]
tplot_options,'ymargin',[3,6]
tplot_options,'xticklen',0.08
tplot_options,'yticklen',0.02
tplot_options,'xthick',2
tplot_options,'ythick',2
tplot_options,'labflag',-1



;Plot xspec quantities
tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_src1'+suffix,$
   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_src2'+suffix,$
   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_phase'+suffix,$
   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_coh'+suffix,$
	 'rbsp'+probe+'_efw_vb1_available','rbsp'+probe+'_efw_vb2_available']


tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec1_src1'+suffix,$
	'rbsp'+probe+'_efw_xspec_'+bins+'_xspec1_src2'+suffix,$
	'rbsp'+probe+'_efw_xspec_'+bins+'_xspec1_phase'+suffix,$
	'rbsp'+probe+'_efw_xspec_'+bins+'_xspec1_coh'+suffix,$
	'rbsp'+probe+'_efw_vb1_available','rbsp'+probe+'_efw_vb2_available']


tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec2_src1'+suffix,$
	'rbsp'+probe+'_efw_xspec_'+bins+'_xspec2_src2'+suffix,$
	'rbsp'+probe+'_efw_xspec_'+bins+'_xspec2_phase'+suffix,$
	'rbsp'+probe+'_efw_xspec_'+bins+'_xspec2_coh'+suffix,$
	'rbsp'+probe+'_efw_vb1_available','rbsp'+probe+'_efw_vb2_available']


tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec3_src1'+suffix,$
	'rbsp'+probe+'_efw_xspec_'+bins+'_xspec3_src2'+suffix,$
	'rbsp'+probe+'_efw_xspec_'+bins+'_xspec3_phase'+suffix,$
	'rbsp'+probe+'_efw_xspec_'+bins+'_xspec3_coh'+suffix,$
	'rbsp'+probe+'_efw_vb1_available','rbsp'+probe+'_efw_vb2_available']






;Example saving plot to .PS
; PostScript needs a different !p.charsize setting
old_pcharsize=!p.charsize
!p.charsize=0.6

popen,'RBSP'+strupcase(probe)+'_XSPEC_summary_'+strcompress(date,/remove_all),/port
	tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
	tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_src1',$
	       'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_src2',$
	       'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_phase',$
	       'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_coh']+suffix
pclose


; now reset the charsize
!p.charsize=old_pcharsize


; delete all loaded quantities (this can be useful if you want to look at
; an entirely different day)
;store_data, '*', /delete


;anames=''
;nna=''
;anames=tnames('rbspa_efw_xspec_*')
;if strlen(anames[0]) ne 0 then nna=strmid(anames[0],16,1)
;if nna eq '3' then abins='36' $
;	else if nna eq '6' then abins='64' $
;	else if nna eq '1' then abins='112' $
;	else abins='0'

;bnames=''
;nnb=''
;bnames=tnames('rbspb_efw_xspec_*')
;if strlen(bnames[0]) ne 0 then nnb=strmid(bnames[0],16,1)
;if nnb eq '3' then bbins='36' $
;	else if nnb eq '6' then bbins='64' $
;	else if nnb eq '1' then bbins='112' $
;	else bbins='0'


end
