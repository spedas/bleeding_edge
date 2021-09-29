;+
;NAME: PSP_SWP_INIT
;
;DESCRIPTION:
; Initializes system variables for Parker Solar Probe SWEAP instrument.  
; Can be called from idl_startup or customized for non-standard installations.  
; The system variable !PSP_SWEAP is defined here.  
;
;REQUIRED INPUTS:
; none
;
;KEYWORDS (OPTIONAL):
; RESET:	Reset !psp_sweap to values in config file, 
;         or default if no config values set
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-10-27 12:50:05 -0700 (Tue, 27 Oct 2020) $
; $LastChangedRevision: 29302 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/L3i/config/psp_swp_init.pro $
;-

PRO PSP_SWP_INIT,RESET=reset
	
init_struct = {					$
	local_data_dir: '',		$
	remote_data_dir: '',	$
	save_plots_dir: '',		$
	no_download: 0,			$
	no_update: 0,				$
	verbose: 0					$
	}

COMPILE_OPT IDL2	

rname = (scope_traceback(/structure))[1].routine
defsysv,'!psp_sweap',exists=exists
if ~keyword_set(exists) || keyword_set(reset) then begin
	defsysv,'!psp_sweap', init_struct
	ftest = psp_swp_read_config()
	if (size(ftest, /type) EQ 8) && ~keyword_set(reset) then begin
		dprint, dlevel=2, rname+': Loading saved PSP SWEAP config.'
		!psp_sweap.local_data_dir = ftest.local_data_dir
		!psp_sweap.remote_data_dir = ftest.remote_data_dir
		!psp_sweap.save_plots_dir = ftest.save_plots_dir
		!psp_sweap.no_download = ftest.no_download
		!psp_sweap.verbose = ftest.verbose
	endif else begin
		if keyword_set(reset) then begin
			dprint, dlevel=2, rname+': Resetting PSP SWEAP to default configuration'
		endif else begin
			dprint, dlevel=2, rname+': No PSP SWEAP config found.. creating default configuration'
		endelse

		!psp_sweap.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/'
		!psp_sweap.local_data_dir = root_data_dir() + 'psp/'
		
		if getenv('SPEDAS_DATA_DIR') ne '' then $
		  !psp_sweap.LOCAL_DATA_DIR = spd_addslash(getenv('SPEDAS_DATA_DIR'))+'psp/'
		  
		!psp_sweap.save_plots_dir = !psp_sweap.local_data_dir + 'plots/'
		!psp_sweap.no_download = file_test(!psp_sweap.local_data_dir + '.psp_master',/regular)
		!psp_sweap.verbose = 2
		dprint, dlevel=2, rname+': Saving default PSP SWEAP config...'
		psp_swp_write_config
	endelse
	printdat,/values,!psp_sweap,varname='!psp_sweap'
	spd_graphics_config
endif

RETURN
END
