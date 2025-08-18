; NAME:
;   spd_unh_mms_file_filter
;
; PURPOSE:
;+
;   Filter MMS file names by time and version. File names are assumed to be identical
;   except in the TSTART and VERSION fields.
;
; :Params:
;       FILENAMES:      in, required, type=string/strarr
;                       Names of files to be filtered.
;
; :Keywords:
;       COUNT:          out, optional, type=integer
;                       Number of output files that passed filter.
;       TRANGE:         in, optional, type=strarr(2), default=time_string(timerange())
;                       Time interval over which to select files.
;       MAJOR_VERSION:  in, optional, type=boolean, default=0
;                       If set, only the latest major version of each file is returned. Cannot
;                           be used with `MIN_VERSION`, LATEST_VERSION or `VERSION`
;       LATEST_VERSION: in, optional, type=boolean, default=0
;                       If set, only the latest version of each file is returned. Cannot
;                           be used with `MIN_VERSION` or `VERSION`
;       MIN_VERSION:    in, optional, type=string
;                       Minimum file version to accept, formatted as 'X.Y.Z', where
;                           X, Y, and Z are integers. Cannot be used with `LATEST_VERSION`
;                           or `VERSION`.
;       VERSION:        in, optional, type=string
;                       Version of files to accept, formatted as 'X.Y.Z', where
;                           X, Y, and Z are integers. Cannot be used with `LATEST_VERSION`
;                           or `MIN_VERSION`.
;
; :Returns:
;       FILES_OUT:      Those files within `FILENAMES` that pass the filter criterion.
;       
;       LOADED_VERSIONS: The CDF version #s
;
;  Forked and renamed from MMS for SPEDAS general (to keep general self-contained) -- jwl@ssl
;       
; $LastChangedBy: jwl $
; $LastChangedDate: 2019-04-26 16:14:42 -0700 (Fri, 26 Apr 2019) $
; $LastChangedRevision: 27107 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/spd_unh_mms_file_filter.pro $
;-
function spd_unh_mms_file_filter, filenames, $
COUNT=count, $
TRANGE=trange_in, $
MAJOR_VERSION=major_version, $
LATEST_VERSION=latest_version, $
MIN_VERSION=min_version, $
NO_TIME=no_time, $
VERSION=version, $
LOADED_VERSIONS=loaded_versions
	compile_opt idl2
	on_error, 2
	
	; allow the user to specify partial version #s
	if keyword_set(min_version) then begin
	  if n_elements(strsplit(min_version, '.')) eq 1 then min_version = min_version + '.0.0'
	  if n_elements(strsplit(min_version, '.')) eq 2 then min_version = min_version + '.0'
	endif
	if keyword_set(version) then begin
	  if n_elements(strsplit(version, '.')) eq 1 then version = version + '.0.0'
	  if n_elements(strsplit(version, '.')) eq 2 then version = version + '.0'
	endif
	
	;Defaults
	tf_time   = ~keyword_set(no_time)
	tf_checkv = n_elements(version)     gt 0
	tf_minv   = n_elements(min_version) gt 0
	tf_latest = keyword_set(latest_version)
	tf_major = keyword_set(major_version)
	
	if tf_checkv + tf_minv + tf_latest + tf_major gt 1 $
		then message, 'VERSION, MIN_VERSION, LATEST_VERSION and MAJOR_VERSION are mutually exclusive.'

	;Results
	files_out = filenames
	count     = n_elements(filenames)

;------------------------------------;
; Filter Time                        ;
;------------------------------------;
	if tf_time then begin
		;Default time range
		if n_elements(trange_in) eq 0 $
			then trange = timerange() $
			else trange = timerange(trange_in)

	;------------------------------------;
	; Sort Time                          ;
	;------------------------------------;
	
		;Parse the file names
		mms_parse_file_name, filenames, void, void, void, void, void, void, fstart
	
		;Parse the start times
		;   - Convert to TT2000
		mms_parse_start_string, fstart, month, day, year, hour, minute, second
		cdf_tt2000, tt2000, year, month, day, hour, minute, second, /COMPUTE_EPOCH
	
		;Sort by time
		nfiles    = n_elements(filenames)
		isort     = sort(tt2000)
		files_out = filenames[isort]
		tt2000    = tt2000[isort]

	;------------------------------------;
	; Filter Time                        ;
	;------------------------------------;

		;TT2000 values for the start and end times
		mms_parse_start_string, strjoin(strsplit(time_string(trange[0]), '-/:', /EXTRACT)), smo, sday, sry, shr, smnt, ssec
		cdf_tt2000, tt2000_start, sry, smo, sday, shr, smnt, ssec, /COMPUTE_EPOCH
		mms_parse_start_string, strjoin(strsplit(time_string(trange[1]), '-/:', /EXTRACT)), emo, eday, eyr, ehr, emnt, esec, second
		cdf_tt2000, tt2000_end, eyr, emo, eday, ehr, emnt, esec, /COMPUTE_EPOCH
	
		;Filter files by end time
		;   - Any files that start after TRANGE[1] can be discarded
		iend = where( tt2000 le tt2000_end[0], count )
		if count gt 0 then begin
			files_out = files_out[iend]
			tt2000    = tt2000[iend]
		endif

		;Filter files by begin time
		;   - Any file with TSTART < TRANGE[0] can potentially have data
		;     in our time interval of interest.
		;   - Assume the start time of one file marks the end time of the previous file.
		;   - With this, we look for the file that begins just prior to TRANGE[0] and
		;     throw away any files that start before it.
		istart = where( tt2000 le tt2000_start[0], count )

		if count gt 0 then begin
			;Select the file time that starts closest to the given time without
			;going over.
			istart = istart[count-1]
		
			;Find all files with start time on or after the selected time
			ifiles = where(tt2000 ge tt2000[istart], count)
			if count gt 0 then begin
				files_out = files_out[ifiles]
				tt2000    = tt2000[ifiles]
			endif
		endif

		;Number of files kept
		if count eq 0 then begin
			message, 'No files in time interval.', /INFORMATIONAL
			return, ''
		endif

		;The last caveat:
		;   - Our filter may be too lenient. The first file may or may not contain
		;     data within our interval.
		;   - Check if it starts on the same day. If not, toss it
		;   - There may be many files with the same start time, but different
		;     version numbers. Make sure we get all copies of the first start
		;     time.
		cdf_tt2000, tt2000[0], year, month, day, hour, /BREAKDOWN, /TOINTEGER
		if year ne sry || month ne smo || day ne sday then begin
			;Filter out all files matching the first starting date
			ibad = where( tt2000 eq tt2000[0], nbad, COMPLEMENT=igood, NCOMPLEMENT=count)
		
			;Extract files
			if count gt 0 then begin
				files_out = files_out[igood]
			endif else begin
				message, 'No files in time interval.', /INFORMATIONAL
				files_out = ''
			endelse
		endif
	endif

;------------------------------------;
; Filter Version                     ;
;------------------------------------;

  ;Extract X, Y, Z version numbers from file
  fversion = stregex(files_out, 'v([0-9]+)\.([0-9]+)\.([0-9]+)\.cdf$', /SUBEXP, /EXTRACT)
  fv = fix(fversion[1:3,*])

	;Filter by minimum version number
	if count gt 0 && (tf_checkv || tf_minv || tf_latest || tf_major) then begin
		;MINIMUM Version
		if tf_minv then begin
			;Version numbers to match
			min_vXYZ = fix(strsplit(min_version, '.', /EXTRACT))
		
			;Select file versions
			iv = where(   (fv[0,*] gt min_vXYZ[0]) or $
			            ( (fv[0,*] eq min_vXYZ[0]) and (fv[1,*] gt min_vXYZ[1]) ) or $
			            ( (fv[0,*] eq min_vXYZ[0]) and (fv[1,*] eq min_vXYZ[1]) and (fv[2,*] ge min_vXYZ[2]) ), count )
			if count gt 0 then files_out = files_out[iv]
		
		;EXACT Version
		endif else if tf_checkv then begin
			;Version numbers to match
			vXYZ  = fix(strsplit(version, '.', /EXTRACT))
			
			;Select file versions
			iv = where( (fv[0,*] eq vXYZ[0]) and (fv[1,*] eq vXYZ[1]) and (fv[2,*] eq vXYZ[2]), count )
			if count gt 0 then files_out = files_out[iv]
		
		;LATEST Version
		endif else if tf_latest then begin
			;Step through X, Y, Z version numbers
			for i = 0, 2 do begin
				;Find latest X, Y, Z version
				iv = where( fv[i,*] eq max(fv[i,*]), count)
				
				;Select version
				fv        = fv[*,iv]
				files_out = files_out[iv]
			endfor
		;LATEST major version
		endif else if tf_major then begin
      ;Find latest X version
      iv = where( fv[0,*] eq max(fv[0,*]), count)

      ;Select version
      fv        = fv[*,iv]
      files_out = files_out[iv]
		endif
		
		;Apply filter
		if count eq 0 then begin
			message, 'No matching file versions.', /INFORMATIONAL
			files_out = ''
		endif
	endif
	
	; again, this time only on filtered files_out
	fversion = stregex(files_out, 'v([0-9]+)\.([0-9]+)\.([0-9]+)\.cdf$', /SUBEXP, /EXTRACT)
	fv = fix(fversion[1:3,*])
	if n_elements(files_out) eq 1 then loaded_versions = transpose(fv) else  loaded_versions = transpose(fv, [1, 0])

	if count eq 1 then files_out = files_out[0]
	return, files_out
end
