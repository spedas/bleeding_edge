mvn_pui_model: models oxygen and hydrogen pickup ions measured by MAVEN SEP, SWIA, STATIC
please send bugs/comments to rahmati@ssl.berkeley.edu

20170214: complete overhaul of the code. s/c potential corrected swea specra are now used to calculate electron impact ionization rates. model/data are stored in arrays of structures (common block mvn_pui_com). new visualization and analysis routines added. see mvn_pui_crib.

20160712: modified/added a few routines for better visualization of model results.

20160608: speed/memory improvements. fixed a data loading bug. added a couple of routines.

20160518: 3D spectra for STATIC are now modeled. Oxygen and hydrogen pickup ions are stored in separare variables for STATIC.

20160504: 3D spectra for SWIA are now modeled. SEP's energy and angular response is improved.

20160404-Ali: the first working version of the code was checked in. Run mvn_pui_model and it should simulate pickup O+ and H+ fluxes for SEP, SWIA, and STATIC and store them in tplot variables. Note that the results are only valid when MAVEN is outside the bow shock in the upstream undisturbed solar wind.