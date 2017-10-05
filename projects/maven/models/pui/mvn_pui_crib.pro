;20160518 Ali
;crib sheet for MAVEN Pickup Ion Modeler

mvn_pui_model ;models pickup oxygen and hydrogen for SEP and 1D SWIA/STATIC spectra
mvn_pui_model,/do3d ;models 3D spectra for SWIA and STATIC. A bit slower than 1D and requires about 7 GB of memory for 1 full day (mostly due to STATIC)
mvn_pui_model,binsize=60. ;sets the model time bin size to 60 seconds and runs the modeler (default is 32 sec)
mvn_pui_model,/nodataload ;does not load any data. set if you want to re-run the simulation with all the required data already loaded

common mvn_pui_com ;data-model results are stored in this common block

mvn_pui_tplot,/store,/tplot ;stores and plots SEP and 1D SWIA/STATIC spectra
mvn_pui_tplot,/store,/swia3d ;stores and plots 3D SWIA spectra in tplot variables: 16 azimuth x 4 elevation bins
mvn_pui_tplot,/store,/static3d_o ;stores and plots STATIC 3D spectra for O: 16 azimuth x 4 elevation bins
mvn_pui_tplot,/store,/static3d_h ;stores and plots STATIC 3D spectra for H: 16 azimuth x 4 elevation bins

mvn_pui_plot_tsample,/all ;line plots of data at a time specified by cursor (use keyword /avrg for averaged values over a time period)
mvn_pui_plot_exoden,/hoto,/thermalh ;plots exospheric density profiles used in mvn_pui_exoden
mvn_pui_sep_angular_response(/plot) ;plots the SEP effective area vs angle of incidence (angular response)
mvn_pui_sep_energy_response,/plot ;plots the SEP energy response matrix
mvn_pui_reduced_fov(/plot) ;plots the dependence of SWIA and STATIC elevation coverage on energy
mvn_pui_flux_drivers ;models pickup ion fluxes using given constant upstream driver parameters