;+
;Procedure: THM_LOAD_SPIN
;
;Purpose:  Loads THEMIS spin model parameters, performs some post-processing
; of data loaded from the SPIN CDFs, and stashes the resulting spin model
; in a common block.
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;          Flatsat data (probe 'f') is not returned unless explicitly
;          mentioned.
;  datatype = The type of data to be loaded, can be an array of strings 
;          or single string separate by spaces.  The default is 'all'
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables 
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as 
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;Example:
;   thm_load_spin,probe=['a','b'] 
;
;Written by: Jim Lewis (jwl@ssl.berkeley.edu)
;Change Date: 2007-10-08
;-

pro thm_load_spin,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 varnames=varnames, valid_names = valid_names, files=files, $
                 progobj=progobj, no_update=no_update, suffix=suffix, _extra=_extra

spinvars = 'spin_spinper spin_time spin_tend spin_c spin_phaserr spin_nspins spin_npts spin_maxgap'

; Default probe selection is 'a b c d e' if no probe argument is
; passed, or if 'all' is passed.  If you want probe f (flatsat),
; you have to explicitly ask for it.

if (keyword_set(probe) NE 1) then probe='a b c d e'
if array_equal(probe,'all') then probe='a b c d e'

  thm_load_xxx,sname=probe, datatype=datatype, trange=trange, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, $
               varnames=varnames, valid_names = valid_names, files=files, $
               vsnames = 'a b c d e f', $
               type_sname = 'probe', $
               vdatatypes = spinvars, $
               file_vdatatypes = 'spin', $
               vlevels = 'l1', $
               deflevel = 'l1', $
               version = 'v01', $
               midfix='',$
               suffix=suffix,$
               post_process_proc = 'spinmodel_post_process', $
               progobj=progobj, no_update=no_update, $
               _extra = _extra

end
