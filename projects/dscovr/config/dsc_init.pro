;+
;NAME: DSC_INIT
;
;DESCRIPTION:
; Initializes system variables for DSCOVR.  Can be called 
; from idl_startup or customized for non-standard installations.  The
; system variable !DSC is defined here.  
;
;REQUIRED INPUTS:
; none
;
;KEYWORDS (OPTIONAL):
; RESET:	Reset !dsc to values in config file, or default if no config values set
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-08-06 11:38:38 -0700 (Thu, 06 Aug 2020) $
; $LastChangedRevision: 29002 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/config/dsc_init.pro $
;-

PRO DSC_INIT,RESET=reset
	
init_struct = {					$
	local_data_dir: '',		$
	remote_data_dir: '',	$
	save_plots_dir: '',		$
	no_download: 0,			$
	no_update: 0,				$
	verbose: 0					$
	}

COMPILE_OPT IDL2	
rname = dsc_getrname()	
defsysv,'!dsc',exists=exists
if ~keyword_set(exists) || keyword_set(reset) then begin
	defsysv,'!dsc', init_struct
	ftest = dsc_read_config()
	if (size(ftest, /type) EQ 8) && ~keyword_set(reset) then begin
		dprint, dlevel=2, rname+': Loading saved dsc config.'
		!dsc.local_data_dir = ftest.local_data_dir
		!dsc.remote_data_dir = ftest.remote_data_dir
		!dsc.save_plots_dir = ftest.save_plots_dir
		!dsc.no_download = ftest.no_download
		!dsc.verbose = ftest.verbose
	endif else begin
		if keyword_set(reset) then begin
			dprint, dlevel=2, rname+': Resetting dsc to default configuration'
		endif else begin
			dprint, dlevel=2, rname+': No dsc config found.. creating default configuration'
		endelse

		!dsc.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/'
		!dsc.local_data_dir = root_data_dir() + 'dsc/'
		
		if getenv('SPEDAS_DATA_DIR') ne '' then $
		  !dsc.LOCAL_DATA_DIR = spd_addslash(getenv('SPEDAS_DATA_DIR'))+'dsc/'
		  
		!dsc.save_plots_dir = !dsc.local_data_dir + 'plots/'
		!dsc.no_download = file_test(!dsc.local_data_dir + '.dsc_master',/regular)
		!dsc.verbose = 2
		dprint, dlevel=2, rname+': Saving default dsc config...'
		dsc_write_config
	endelse
	printdat,/values,!dsc,varname='!dsc'
	spd_graphics_config
endif

RETURN
END
