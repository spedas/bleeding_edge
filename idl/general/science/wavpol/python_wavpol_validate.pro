;+
;Name:
;  python_wavpol_validate
;
;Purpose:
;
;  Adapted from thm_crib_wavpol.  This script sets up a call to twavpol, and saves the input and output variables to
;  a tplot sav file so they can be loaded in python to compare to the python results.
;
;; =============================
;; Select date and time interval
;; =============================

timespan, '2007-05-08/03:30:00',1,/hours
trange=['2007-05-08/03:30:00','2007-05-08/04:30:00']

;; =============================
;; Select probe and mode
;; =============================

;; Select satellites

sc = ['c']

;;　Select mode (scf, scp, scw, fgs, fsl, fgh, fge)

mode = 'scf'

;; =============================
;; Get auxiliary data from STATE
;; =============================

thm_load_state, probe=sc, /get_support_data

;; ==============================================================
;; Get SCM/FGM data and SCM/FGM header file with easy calibration method
;; ==============================================================

;; If you want to set up a limited timespan for calibration,
;; For best cleanup, it is best to specify a relatively short time range,
;; over which the noise signal is relatively uniform.


;; Get SCM/FGM data

thm_load_scm, probe=sc, datatype=mode, level=2, trange=trange, coord='gse'
thm_load_fgm, probe=sc, datatype='fgl', level=2, trange=trange, coord='gse'
;
tsmooth2,'thc_fgl_gse',12,newname='thc_fgl_gse_lp' ; low pass filtered FGL data at 3sec resolution for fac
thm_fac_matrix_make, 'thc_fgl_gse_lp', other_dim='xgse', newname = 'thc_fgl_gse_lp_fac_mat' ; get fac rot mat
tvector_rotate, 'thc_fgl_gse_lp_fac_mat', 'thc_fgl_gse', newname = 'thc_fgl_fac' ; full fgl data in fac coords
tvector_rotate, 'thc_fgl_gse_lp_fac_mat', 'thc_scf_gse', newname = 'thc_scf_fac' ; full scf data in fac coords
;



;fill data gaps with regularly spaced(in time) NaNs, wavpol *only* works on regularly gridded data
;using data with irregular grids will produce incorrect results
tdegap,'th'+sc+'_scf_fac',/overwrite
tclip,'th'+sc+'_scf_fac',-10.,10.,/overwrite
tdeflag,'th'+sc+'_scf_fac','linear',/overwrite
;
;; =======================
;; Calculate polarisation
;; =======================


twavpol,'thc_scf_fac' ; can't work with string variable for now (could be fixed later)

;; =====================
;; Plot calculated data
;; =====================

zlim,'*_powspec',0.0,0.0,1
tplot, 'thc_scf_fac'+['','_powspec','_degpol', '_waveangle', '_elliptict', '_helict']

varlist = ['thc_scf_fac', 'thc_scf_fac_powspec', 'thc_scf_fac_degpol', 'thc_scf_fac_waveangle', 'thc_scf_fac_elliptict', 'thc_scf_fac_helict', 'thc_scf_fac_pspec3']
tplot_save, varlist, filename='thc_twavpol_validate'

;; ********************************************
;; end of thm_crib_twavpol.pro
;; ********************************************

end
