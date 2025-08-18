;+
;pro thm_sst_crib
; This is an example crib sheet that will load Solid State Telescope data.
; Open this file in a text editor and then use copy and paste to copy
; selected lines into an idl window. Or alternatively compile and run
; using the command:
; .RUN THM_SST_CRIB
;Author: Davin Larson
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2014-10-14 10:44:04 -0700 (Tue, 14 Oct 2014) $
; $LastChangedRevision: 15991 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_sst.pro $
;-
;

trange = ['2010-06-05','2010-06-06']

;set the date and duration (in days)
timespan,trange

;set the spacecraft
probe = 'c'

;set the datatype

datatype = 'psif' ;(psef for electrons, psib/pseb for burst mode, psir/pser for reduced mode)

;loads particle data for data type
thm_part_load,probe=probe,datatype=datatype 

;calculate derived products
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs =['energy','theta','phi','moments']

;view the loaded data names
tplot_names

;plot the energy spectrogram, and angular spectrograms(despun spacecraft coordinates (DSL))
tplot,['th'+probe+'_psif_eflux_energy','th'+probe+'_psif_eflux_theta','th'+probe+'_psif_eflux_phi','th'+probe+'_psif_density']

stop

;----------------------------------------------------------------------------------------------------------------------------
;  Manual SST sun decontamination
;----------------------------------------------------------------------------------------------------------------------------


probe='c'
datatype='psif'
trange = ['2010-06-05','2010-06-06']
timespan,trange

;loads particle data for data type
thm_part_load,probe=probe,trange=trange,datatype=datatype

;  manual sun decontamination with SST (bin numbers)
; Bin numbers specified in this example are the current default
thm_part_products,probe=probe,datatype=datatype,trange=trange,sst_sun_bins=[0,8,16,24,32,33,34,40,47,48,49,50,55,56,57],outputs='energy theta phi'

tplot,['th'+probe+'_psif_eflux_energy','th'+probe+'_psif_eflux_theta','th'+probe+'_psif_eflux_phi']

stop

;----------------------------------------------------------------------------------------------------------------------------
;  Use edit 3d bins to view data
;----------------------------------------------------------------------------------------------------------------------------

probe='c'
datatype='psif'
trange = ['2010-06-05','2010-06-06']
timespan,trange

;loads particle data for data type
thm_part_load,probe=probe,trange=trange,datatype=datatype

;select bins for removal
edit3dbins,thm_part_dist('th'+probe+'_psif',time_double('2010-06-05/12:00:00'),/sst_cal),bins
;right click to exit, left click to select bins for removal
stop

;see removed bins
edit3dbins,thm_part_dist('th'+probe+'_psif',time_double('2010-06-05/12:00:00'),/sst_cal,sun_bins=bins,method_clean='manual'),bins

stop

;use bins in data
thm_part_products,probe=probe,datatype=datatype,trange=trange,sst_sun_bins=where(~bins),outputs='energy theta phi'

tplot,['th'+probe+'_psif_eflux_energy','th'+probe+'_psif_eflux_theta','th'+probe+'_psif_eflux_phi']
end
