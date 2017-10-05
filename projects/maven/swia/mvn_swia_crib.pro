;+
;PROCEDURE:	
;	MVN_SWIA_CRIB
;PURPOSE:	
;	Crib file to demonstrate SWIA software 
;
;INPUT:		
;
;KEYWORDS:
;
;AUTHOR:	J. Halekas	
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-10-16 08:41:12 -0700 (Thu, 16 Oct 2014) $
; $LastChangedRevision: 16003 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_crib.pro $
;
;-


; Preamble: Note that by default this software uses Davin's file_retrieve software and will download files over the web if they are not cached locally. This can take awhile, so beware. If you want to suppress this behavior you can set the '/no_server' keyword, and it will only look locally. You can also hardwire in the file names and path if you are assuming a different data structure than the PF standard.  However, you *must* have your files organized in subdirectories by YYYY/MM or the load routine will choke. By default this code will return the most recent version/revision of the data file that exists, but you can also override that to load old files (why would you want to?).   


; load moments and spectra data, manually enter time range, create tplot variables 

	mvn_swia_load_l2_data,/loadmom,/loadspec,/tplot, trange = ['2014-03-19','2014-03-25']


; load all data, automatically select date range w/ call to timerange (will prompt for time range if not previously set), create tplot variables

	mvn_swia_load_l2_data,/loadall, /tplot

; load moment and spectra data with lower quality flags than default of 0.5

	mvn_swia_load_l2_data,/loadmom,/loadspec,/tplot,qlevel = 0.1

; load data in units of 'eflux' instead of 'counts'

	mvn_swia_load_l2_data,/loadall,/tplot,/eflux



; see what variables are loaded

	tplot_names

; plot them (variable naming convention:  'swim' = moments, 'swis' = spectra, 'swifs' = fine survey 3d distributions, 'swifa' = fine archive 3d distributions, 'swics' = coarse survey 3d distributions, 'swica' = coarse archive 3d distributions)
	
	tplot,['mvn_swi*']

; bring the arrays of data structures into the foreground if you want to work with raw data instead of tplot variables (arrays of structures have same naming convention as tplot variables, plus one called 'info_str' that contains things like energy and angle and sensitivity tables)

	common mvn_swia_data

; change variables of data in structures (slow!)

	mvn_swia_common_units,'flux'


; get standard 3d data structure

	ctime,t,npoints = 1

	fsdat = mvn_swia_get_3df(t)
	fadat = mvn_swia_get_3df(t,/archive)

	csdat = mvn_swia_get_3dc(t)
	cadat = mvn_swia_get_3dc(t,/archive)

	sdat = mvn_swia_get_3ds(t)

; change units of 3d data structure (wrapper routine that calls SWIA-specific conversion)

	csdat2 = conv_units(csdat,'df')


; use standard routines to compute moments (note that SW temperature is contaminated by alphas)

	n = n_3d(csdat)
	v = v_3d(csdat)
	t = t_3d(csdat)

; use standard routines to plot distributions

	plot3d_new,csdat
	spec3d,csdat

;Compute moments for all the 3-d distributions (and spectra)

	mvn_swia_part_moments

;Do it just for fine distributions

	mvn_swia_part_moments, type = ['fs','fa']

;Do it for a constrained energy, phi, theta, range

	mvn_swia_part_moments, erange = [100,200], phrange  = [160,200], thrange = [-20,20]

; compute separate proton and alpha moments (in instrument coordinates) from fine distributions using simple energy bisection and partial moment computation (takes awhile)

	mvn_swia_protonalphamoms

; compute separate proton and alpha moments from a single fine distribution (need to compile the wrapper mvn_swia_protonalphamoms first with '.r mvn_swia_protonalphamoms' if you haven't previously run)

	mvn_swia_protonalphamom, dat = fsdat, n1,t1,v1, n2,t2,v2,/plot

; load level 0 data (useful if L2 processing not complete)
; set /sync keyword for most efficient load
; will automatically select data range and find files if the 'files' variable isn't provided or 'trange' keyword is not set

	mvn_swia_load_l0_data,files,/tplot,/sync
	mvn_swia_load_l0_data,/tplot,/sync, trange = ['2014-10-14','2014-10-15']
	mvn_swia_load_l0_data,/tplot,/sync



