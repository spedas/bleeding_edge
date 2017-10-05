;+
;PROCEDURE:	mvn_sta_l0_load,pathname=pathname,trange=trange,files=files,mag=mag,pfdpu=pfdpu,sep=sep,lpw=lpw,RT=RT,download_only=download_only
;PURPOSE:	
;	To generate quicklook data plots and a tplot save file
;INPUT:		
;
;KEYWORDS:
;	all		0/1		if not set, housekeeping and raw variables 'mvn_STA_*' are deleted from tplot after data is loaded
;
;CREATED BY:	J. McFadden	  13-05-07
;VERSION:	1
;LAST MODIFICATION:  14-03-17		copied davin file retrieve and load routine
;MOD HISTORY:
;
;NOTES:	  
;	
;-

pro mvn_sta_l0_load,pathname=pathname,files=files,sep=sep,pfdpu=pfdpu,mag=mag,lpw=lpw,trange=trange,download_only=download_only,all=all

starttime = systime(1)

;if n_elements(pfdpu) eq 0 then pfdpu=1
;if n_elements(sep) eq 0 then sep=1

files = mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,RT=RT,files=files)

if not keyword_set(download_only) then begin
  mvn_pfp_l0_file_read,sep=sep,pfdpu=pfdpu,mag=mag,lpw=lpw,/static,pathname=pathname,file=files,trange=trange 

dprint,'Download finished in ',systime(1)-starttime,' seconds'

	mvn_sta_handler,/clear
	if keyword_set(all) then mvn_sta_hkp_cal,def_lim=1
	mvn_sta_prod_cal,all=all
	mvn_sta_dead_load		; preliminary version ready 20150122
	mvn_sta_qf_load			; fixed 20150724
	mvn_sta_qf14_load		; fixed 20150724 - 

;	mvn_sta_bkg_load		; not developed yet

; Note - the follow can be run a couple of weeks after data arrives at berkeley to complete the structures
;	these can be run on l2 data rather than reprocessing from l0 data in order to run faster

;	mvn_sta_ephemeris_load		; preliminary version ready 20150119
;	mvn_sta_mag_load		; preliminary version ready 20150119
;	mvn_sta_sc_bins_load

;	mvn_sta_scpot_load		; not developed yet

endif

end