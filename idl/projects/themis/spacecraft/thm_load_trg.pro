;+
;Procedure: THM_LOAD_TRG
;
;Purpose:  Loads THEMIS Trigger function data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
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
;  /NO_DOWNLOAD: set this option to use only locally available files
;  /valid_names, if set, then this routine will return the valid
;  /NO_TIME_CLIP: disable time clipping
;probe, datatype
;
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  /relpathnames_all: the names of the files loaded will be returned
;in this named variable
;suffix: the name of the suffix to be added to returned tplot variables
;
;Example:
;   thg_load_trg,/get_support_data,probe=['a','b']
;Notes: (Most of this was shamelessly copied from thm_load_fbk)
;
;Here's a definition of what each byte means:
; Byte|Name |Time Resolution
; 0   |dAKR |1 Sec
; 1   |dFB  |1 Sec
; 2   |dEy  |1 Spin
; 3   |dBz  |1 Spin
; 4   |dNI  |1 Spin
; 5   |dVxy |1 Spin
; 6   |dPres|1 Spin
; 7   |Test |1 Spin
;
;Written by: Patrick Cruce(pcruce@gmail.com)
;Change Date: 2005-05-24

pro thm_load_trg,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data,no_download=no_download, $
                 varnames=varnames, valid_names = valid_names, files=files,relpathnames_all=relpathnames_all,$
                 suffix=suffix, _extra = _extra

  thm_load_xxx,sname=probe, datatype=datatype, trange=trange, no_download=no_download,$
               level=level, verbose=verbose, downloadonly=downloadonly, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, $
               varnames=varnames, valid_names = valid_names, files=files, $
               relpathnames_all=relpathnames_all,suffix=suffix,$
               vsnames = 'a b c d e f', $
               type_sname = 'probe', $
               vdatatypes = 'trg', $
               file_vdatatypes = 'trg', $
               vlevels = 'l1', $
               deflevel = 'l1', $
               version = 'v01', $
               _extra = _extra

end



