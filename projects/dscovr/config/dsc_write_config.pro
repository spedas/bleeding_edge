;+
;NAME: DSC_WRITE_CONFIG
;
;DESCRIPTION: 
; Writes the dsc_config file
;
;REQUIRED INPUTS:
; none (filename is hardcoded, 'dsc_config.txt', and is put in a folder
; given by the routine 'dsc_config_filedir', that uses the IDL routine
; app_user_dir to create/obtain it:
; 	e.g. (Windows)
; 	C:\Users\anarock\.idl\dsc\dsc_config-4-win32
;
;KEYWORD ARGUMENTS (OPTIONAL):
; COPY: If set, make a copy, creating a new file whose filename 
;       is timestamped with an appended !STIME.
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
;
;OUTPUT
; Nothing returned. The file is written, and a copy of any old file is generated. 
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/config/dsc_write_config.pro $
;-

PRO DSC_WRITE_CONFIG, COPY=copy, _EXTRA=_extra, VERBOSE=verbose

	COMPILE_OPT IDL2

	dsc_init
	if not isa(verbose,/int) then verbose=!dsc.verbose
		
	; get the filename
	dir = dsc_config_filedir()
	ll = strmid(dir, strlen(dir)-1,1)
	if (ll EQ '/' or ll EQ '\') then filex = dir+'dsc_config.txt' $
	  else filex = dir + PATH_SEP() + 'dsc_config.txt'
  
	; if we are copying the file, get a filename, header, and old configuration
	if (keyword_set(copy)) then begin
		xt = time_string(systime(/sec))
		ttt = strmid(xt, 0, 4) + strmid(xt, 5, 2) + strmid(xt, 8, 2) + $
		  '_' + strmid(xt, 11, 2) + strmid(xt, 14, 2) + strmid(xt, 17, 2)
		filex_out = filex + '_' + ttt
		cfg = dsc_read_config(header = hhh)
	endif else begin
		; does the file exist?  if so, then copy it
		if (file_search(filex) NE '') then dsc_write_config, /copy
		filex_out = filex
		cfg = {	$
			local_data_dir:!dsc.local_data_dir,		$
			remote_data_dir:!dsc.remote_data_dir,	$
			save_plots_dir:!dsc.save_plots_dir, $
			no_download:!dsc.no_download,			$
			no_update:!dsc.no_update,  $
			verbose:!dsc.verbose							$
			}
		hhh = [';dsc_config.txt', '; dsc configuration file', $
			';Created'+time_string(systime(/sec))]
	endelse

	; you need to be sure that the directory exists
	xdname = file_dirname(filex_out)
	if (xdname NE '') then file_mkdir, xdname

	; write the file
	;   write header
	openw, unit, filex_out, /get_lun
	for j=0, n_elements(hhh)-1 do printf, unit, hhh[j]
	;   write configuration information
	ctags = tag_names(cfg)
	nctags = n_elements(ctags)
	for j=0, nctags-1 do begin
		x0 = strtrim(ctags[j])  ; field tag
		x1 = cfg.(j)            ; associated data
		if (is_string(x1)) then x1 = strtrim(x1,2) else begin
			; odd things can happen with byte arrays-- convert to integer type
			if (size(x1, /type) EQ 1) then x1 = fix(x1)
			x1 = strcompress(/remove_all, string(x1))
		endelse
		printf, unit, x0 + '=' + x1
	endfor

	FREE_LUN, unit
	RETURN

END



