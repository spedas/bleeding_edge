;+
;NAME: DSC_LOAD_ATT
;
;DESCRIPTION:
; Loads DSCOVR Attitude data
;
;KEYWORDS: (Optional)			
; DOWNLOADONLY: Set to download files but *not* store data in TPLOT. 
; NO_DOWNLOAD:  Set to use only locally available files. Default is !dsc config.
; NO_UPDATE:    Set to only download new filenames. Default is !dsc config.
; TRANGE=:      Time range of interest stored as a 2 element array of
;                 doubles (as output by timerange()) or strings (as accepted by timerange()).
;                 Defaults to the range set in tplot or prompts for date if not yet set.
; VARFORMAT=:   Specify a subset of variables to store
; VERBOSE=:     Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
; 
;KEYWORD OUTPUTS:
; TPLOTNAMES=: Named variable to hold array of TPLOT variable names loaded 
;   
;EXAMPLE:
;		dsc_load_att
;		dsc_load_att,trange=['2017-01-01','2017-01-02']),verbose=2
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/load/dsc_load_att.pro $
;-


PRO DSC_LOAD_ATT,TRANGE=trange,DOWNLOADONLY=downloadonly,VARFORMAT=varformat, $
	NO_DOWNLOAD=no_download,NO_UPDATE=no_update,VERBOSE=verbose,TPLOTNAMES=tn

COMPILE_OPT IDL2

dsc_init

rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!dsc.verbose
if not isa(no_download,/int) then no_download = !dsc.no_download
if not isa(no_update,/int) then no_update = !dsc.no_update
if not keyword_set(varformat) then varformat = '*'

pathformat = 'dscovr/orbit/def_at/YYYY/dscovr_at_def_YYYYMMDD_v??.cdf'
relpathnames = file_dailynames(file_format=pathformat,trange=trange)
files = spd_download( $
	remote_file=relpathnames, remote_path=!dsc.remote_data_dir, local_path = !dsc.local_data_dir, $
	no_download = no_download, no_update = no_update, /last_version, /valid_only, $
	file_mode = '666'o, dir_mode = '777'o)

if files[0] eq '' then begin
	dprint,dlevel=2,verbose=verbose,rname+': No DSCOVR files found'
	return
endif
if keyword_set(downloadonly) then return

prefix = 'dsc_att_'
cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn,/load_labels    ; load data into tplot variables
dprint,dlevel=4,verbose=verbose,rname+': tplotnames: ',tn

; Remove bad/unwanted data and set default plot options
del_str = '*PB5*'
tn = strfilter(tn,del_str,/negate)
store_data,delete=del_str

if ~((tn.length eq 1) and (tn[0] eq '')) then begin
	for i=0,tn.length-1 do begin
		get_data,tn[i],data=d,dlimits=md
		dsc_set_ytitle,tn[i],metadata=md,verbose=verbose
	endfor
endif
options,/def,tn,datagap=-1

end
