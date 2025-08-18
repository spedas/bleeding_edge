;+
;PROCEDURE: IUG_CRIB_AVON_VLFB
;    A crib sheet to demonstrate how to deal with data from
;    AVON(Asia VLF Observation Network) VLF-B data using udas.
;    You can run this crib sheet by copying&pasting each command
;    below into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_avon_vlfb
;
; Written by: M. Yagi, May 14, 2014 
; Last Update: M. Yagi, Jun 26, 2014
;-

;Initialize
thm_init 

;Specify the time span.
timespan,'2011-02-20/11:00:00',2,/min

;
cdf_leap_second_init

;Load AVON/VLF-B data
iug_load_avon_vlfb,site='tnn srb'

;View the loaded data names
tplot_names

;Plot the loaded data
tplot,['avon_vlfb_tnn_ch1','avon_vlfb_tnn_ch2','avon_vlfb_srb_ch1','avon_vlfb_srb_ch2']

;Stop
print,'Enter ".c" to continue.'
stop

;Make power spectrum data
tdpwrspc,'avon_vlfb_srb_ch2',nboxpoints=1024,nshiftpoints=64
ylim,'avon_vlfb_srb_ch2_dpwrspc',1000,10000

;Plot power spectrum data
tplot,['avon_vlfb_srb_ch2','avon_vlfb_srb_ch2_dpwrspc']

end
