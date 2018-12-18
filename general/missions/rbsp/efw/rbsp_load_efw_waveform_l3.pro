;+
;Procedure: RBSP_LOAD_EFW_WAVEFORM_L3
;
;Purpose:  Loads RBSP EFW L3 Waveform data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  varformat=strin
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;                       kw to narrow the data products.  Wildcards and glob-style patterns accepted (e.g., ef?, *_dot0).
;  VARNAMES: names of variables to load from cdf: default is all.
;  /DOWNLOADONLY: download file but don't read it. (NOT IMPLEMENTED YET)
;  /ETU: If set, load data from the ETU.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;   tper: (In, optional) Tplot name of spin period data. By default,
;         tper = pertvar. If tper is set, pertvar = tper.
;   tphase: (In, optional) Tplot name of spin phase data. By default,
;         tphase = 'rbsp' + strlowcase(sc[0]) + '_spinphase'
;         Note: tper and and tphase are mostly used for using eclipse-corrected
;         spin data.
;Example:
;   rbsp_load_efw_waveform_l3,probe=['a', 'b']
;
; HISTORY:
;   1. Written by Peter Schroeder, February 2012
;   2012-11-06: JBT, SSL/UCB.
;         1. Added keywords *coord*, *tper*, and *tphase* that are passed into
;             *rbsp_efw_cal_waveform*.
;
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2018-12-17 14:19:27 -0800 (Mon, 17 Dec 2018) $
; $LastChangedRevision: 26343 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_efw_waveform_l3.pro $
;-

pro rbsp_load_efw_waveform_l3,probe=probe, trange=trange, $
                              verbose=verbose, downloadonly=downloadonly, $
                              cdf_data=cdf_data,$
                              tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                              varformat=varformat, valid_names = valid_names, files=files,$
                              etu=etu,tper = tper, tphase = tphase, _extra = _extra

  rbsp_efw_init
  dprint,verbose=verbose,dlevel=4,'$Id: rbsp_load_efw_waveform_l3.pro 26343 2018-12-17 22:19:27Z aaronbreneman $'

  UMN_data_location = 'http://rbsp.space.umn.edu/data/rbsp/'
  cache_remote_data_dir = !rbsp_efw.remote_data_dir
  !rbsp_efw.remote_data_dir = UMN_data_location

  if keyword_set(etu) then probe = 'a'

  if(keyword_set(probe)) then $
     p_var = strlowcase(probe)

  vb = keyword_set(verbose) ? verbose : 0
  vb = vb > !rbsp_efw.verbose

  vprobes = ['a','b']
  default_data_att = {units: 'ADC', coord_sys: '', st_type: 'none'}
  support_data_keep = ['BEB_config','DFB_config']

  if keyword_set(valid_names) then begin
     probe = vprobes
     return
  endif

  if not keyword_set(p_var) then p_var='*'
  p_var = strfilter(vprobes, p_var ,delimiter=' ',/string)

  addmaster=0

  color_array = [2,4,6,1,3,2,4,6,1,3]

  for s=0,n_elements(p_var)-1 do begin
    rbspx = 'rbsp'+ p_var[s]
    rbsppref = rbspx + '/l3'

    ;Find out what files are online
    format = rbsppref + '/YYYY/'+rbspx+'_efw-l3_YYYYMMDD_v*.cdf'
    relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)

    ;...and load them
    file_loaded = []
    for ff=0, n_elements(relpathnames)-1 do begin
      undefine,lf
      localpath = file_dirname(relpathnames[ff])+'/'
      locpath = !rbsp_efw.local_data_dir+localpath
      remfile = !rbsp_efw.remote_data_dir+relpathnames[ff]
      tmp = spd_download(remote_file=remfile, local_path=locpath, local_file=lf,/last_version)
      locfile = locpath+lf
      if file_test(locfile) eq 0 then locfile = file_search(locfile)
      if locfile[0] ne '' then file_loaded = [file_loaded,locfile]
    endfor

    if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue
    suf=''
    prefix=rbspx+'_efw_'
    cdf2tplot,file=file_loaded,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
         tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables


    ;If files have been loaded then continue
    if is_string(tns) then begin

      old_name = rbspx+'_efw_'
      new_name = rbspx+'_efw_'

      dprint, dlevel = 5, verbose = verbose, 'Setting options...'

      options, /def, tns, code_id = '$Id: rbsp_load_efw_waveform_l3.pro 26343 2018-12-17 22:19:27Z aaronbreneman $'

      store_data,new_name,/delete
      store_data,old_name,newname=new_name
      get_data,new_name,dlimits=mydlimits
      str_element,mydlimits,'data_att',default_data_att,/add
      store_data,new_name,dlimits=mydlimits

      options,new_name,'labels',labels
      options,new_name,'labflag',1

      dprint, dlevel = 4, verbose = verbose,' data Loaded for probe: '+p_var[s]


      for i = 0, n_elements(tns) - 1 do begin
         if strfilter(tns[i],'*'+support_data_keep) eq '' then begin
            get_data,tns[i],dlimits=thisdlimits
            cdf_str = 0
            str_element,thisdlimits,'cdf',cdf_str
            if keyword_set(cdf_str) then if cdf_str.vatt.var_type eq 'support_data' then $
               store_data,tns[i],/delete, verbose = 0
         endif
      endfor

    endif else begin
      dprint, dlevel = 0, verbose = verbose, 'No EFW ' + $
              ' data loaded...'+' Probe: '+p_var[s]
    endelse
  endfor


  !rbsp_efw.remote_data_dir = cache_remote_data_dir

end
