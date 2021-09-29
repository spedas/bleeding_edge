;+
;NAME: DSC_LOAD_ALL
;
;DESCRIPTION: 
; Loads all DSCOVR data products
;
;KEYWORDS: (Optional)			
; DOWNLOADONLY: Set to download files but *not* store data in TPLOT. 
; KEEP_BAD:     Set to keep quality flag variable and flagged data in the data arrays
; NO_DOWNLOAD:  Set to use only locally available files. Default is !dsc config.
; NO_UPDATE:    Set to only download new filenames. Default is !dsc config.
; TRANGE=:      Time range of interest stored as a 2 element array of
;                 doubles (as output by timerange()) or strings (as accepted by timerange()).
;                 Defaults to the range set in tplot or prompts for date if not yet set.
; VERBOSE=:     Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
; 
;KEYWORD OUTPUTS:
; TPLOTNAMES=: Named variable to hold array of TPLOT variable names loaded 
;   
;EXAMPLE:
;		dsc_load_all
;		dsc_load_all,trange=['2017-01-02/00:00:00','2017-01-03/12:00:00'],tplotnames=tn
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/load/dsc_load_all.pro $
;-

PRO DSC_LOAD_ALL,TRANGE=trange,DOWNLOADONLY=downloadonly,NO_DOWNLOAD=no_download, $
	NO_UPDATE=no_update,VERBOSE=verbose,KEEP_BAD=keep_bad,TPLOTNAMES=tn

COMPILE_OPT IDL2
tn_att	= []
tn_or	= []
tn_mag	= []
tn_fc	= []
dsc_load_att,trange=trange,downloadonly=downloadonly,no_download=no_download, $
	no_update=no_update,tplotnames=tn_att,verbose=verbose
dsc_load_or,trange=trange,downloadonly=downloadonly,no_download=no_download, $
	no_update=no_update,tplotnames=tn_or,verbose=verbose
dsc_load_mag,trange=trange,downloadonly=downloadonly,no_download=no_download, $
	no_update=no_update,tplotnames=tn_mag,verbose=verbose,keep_bad=keep_bad
dsc_load_fc,trange=trange,downloadonly=downloadonly,no_download=no_download, $
	no_update=no_update,tplotnames=tn_fc,verbose=verbose,keep_bad=keep_bad
	
tn = [tn_att,tn_or,tn_mag,tn_fc]
END