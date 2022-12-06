;+
;Procedure: THM_LOAD_BAU
;
;Purpose:  Loads THEMIS BAU data
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
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as 
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  /NO_TIME_CLIP: disable time clipping
;Example:
;   thg_load_bau,/get_suppport_data,probe=['a','b'] 
;Notes: (Much of this was shamelessly copied from thm_load_fbk)
;
;Written by: Patrick Cruce(pcruce@gmail.com)
;Change Date: 2005-05-24

pro thm_load_bau,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 varnames=varnames, valid_names = valid_names, files=files,suffix=suffix, $
                 _extra = _extra

  ;a bunch of fun code to construct the list of variable names using
  ;an economy of typing
  
  htr_list = ['prcshtrsrv2', 'pbsphtrcurr', 'pbsrhtrcurr', 'prcshtrsrv1', 'prcshtrsrv3', 'piphtrcurr', 'pirhtrcurr', 'pcbphtrcurr', 'pcbrhtrcurr']
  therm_list = ['btmpirua', 'btmpiruac', 'btmpirub', 'btmpirubc', 'btmpmsss', 'btmptopdk', 'btmpsband', 'btmpsapnl1',$
  'btmpsapnl3', 'btmpsatop', 'btmpsabot', 'btmpsapnl2', 'btmpsapnl4', 'btmpprtcal', 'btmpidpu', 'btmprcsln1',$
  'btmprcsln2', 'btmptnk1liq', 'btmptnk1gas', 'btmptnk2liq', 'btmptnk2gas', 'btmpthra1', 'btmpthra2', 'btmpthrt1',$
  'btmpthrt2', 'btmpbatta', 'btmpbattb', 'btmpiru', 'btmpsst', 'btmpaxbm', 'btmprcssvc', 'btmpesa', 'btmpefirad',$
  'btmprcsprvlv', 'btmpxpdrbase', 'btmprcvr', 'btmpxmtr', 'btmpbaubase', 'btmprcsprtk', 'btmpdpmbd', 'btmpcimbd', 'btmppcmbd',$
  'btmpcallvl', 'btmpprmbd', 'btmpacmbd']
  htr_list_raw = 'bau302_' + htr_list
  htr_list_cnv = 'bau302_cnv_'+htr_list
  therm_list_raw = 'bau301_'+therm_list+'_raw'
  therm_list_cnv = 'bau301_'+therm_list
  arr = strcompress('psa'+ string(indgen(4)+1), /REMOVE_ALL)

  arr = ['shunt', arr]+'curr'
  
  var_arr = ['sunpulse_met', $
             'spinper', $
             'sunangle', $
             'met', $
             'utc_offset']

  var_arr = [arr, var_arr]

  var_arr = [var_arr[0:4]+'_raw', var_arr]

  var_arr[0:9] = 'bau302_'+var_arr[0:9]
  var_arr[10:12] = 'bau305_'+var_arr[10:12]
  var_arr[13:14] = 'bau30c_'+var_arr[13:14]
  var_arr=[var_arr,htr_list_raw,htr_list_cnv,therm_list_raw,therm_list_cnv]

  var_list = ''

  var_list = strjoin(var_arr+' ')

  ;now we just let the library function do the work
  thm_load_xxx,sname=probe, datatype=datatype, trange=trange, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, $
               varnames=varnames, valid_names = valid_names, files=files, $
               vsnames = 'a b c d e', $
               type_sname = 'probe', $
               vdatatypes = var_list, $
               file_vdatatypes = 'bau', $
               vlevels = 'l1', $
               deflevel = 'l1', $
               version = 'v01', $
               suffix=suffix,$
               _extra = _extra

end


