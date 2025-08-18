;+
;Procedure: RBSP_LOAD_EFW_WAVEFORM
;
;Purpose:  Loads RBSP EFW Waveform data
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
;  DATATYPE:    Input, string.  Default setting is to calibrate all raw quantites and also produce all _0 and _dot0 quantities.  Use DATATYPE
;                       kw to narrow the data products.  Wildcards and glob-style patterns accepted (e.g., ef?, *_dot0).
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables. (NOT IMPLEMENTED YET)
;  /DOWNLOADONLY: download file but don't read it. (NOT IMPLEMENTED YET)
;  /QA: If set, load data from l1_qa testing directory.
;  /INTEGRATION: If set, load data from integration.
;  /MSIM: If set, load data from mission simulations.
;  /ETU: If set, load data from the ETU.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  type:  set to 'calibrated' to automatically convert data into physical units
;  coord: Set to 'uvw' to return data in UVW. Otherwise the output is in DSC
;          coordinate system
;   tper: (In, optional) Tplot name of spin period data. By default,
;         tper = pertvar. If tper is set, pertvar = tper.
;   tphase: (In, optional) Tplot name of spin phase data. By default,
;         tphase = 'rbsp' + strlowcase(sc[0]) + '_spinphase'
;         Note: tper and and tphase are mostly used for using eclipse-corrected
;         spin data.
;Example:
;   rbsp_load_efw_waveform,/get_suppport_data,probe=['a', 'b']
;
; HISTORY:
;   1. Written by Peter Schroeder, February 2012
;   2012-11-06: JBT, SSL/UCB.
;         1. Added keywords *coord*, *tper*, and *tphase* that are passed into
;             *rbsp_efw_cal_waveform*.
;
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2018-12-17 14:06:25 -0800 (Mon, 17 Dec 2018) $
; $LastChangedRevision: 26341 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_efw_waveform.pro $
;-

pro rbsp_load_efw_waveform,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                 varformat=varformat, valid_names = valid_names, files=files,$
                 type=type, integration=integration, msim=msim, etu=etu, $
                 qa=qa, coord = coord, noclean = noclean, $
                 tper = tper, tphase = tphase, _extra = _extra

rbsp_efw_init
dprint,verbose=verbose,dlevel=4,'$Id: rbsp_load_efw_waveform.pro 26341 2018-12-17 22:06:25Z aaronbreneman $'

if keyword_set(etu) then probe = 'a'

if(keyword_set(probe)) then $
  p_var = strlowcase(probe)

vb = keyword_set(verbose) ? verbose : 0
vb = vb > !rbsp_efw.verbose

vprobes = ['a','b']
vlevels = ['l1','l2']
vdatatypes=['esvy', 'vsvy', 'magsvy', 'eb1', 'vb1', 'mscb1', 'eb2', 'vb2', 'mscb2']
default_data_att = {units: 'ADC', coord_sys: 'uvw', st_type: 'none'}
support_data_keep = ['BEB_config','DFB_config']

;-------------------------------------------------
;Load the level 2 online EFW waveform data product
;-------------------------------------------------

if keyword_set(level) then if level eq 'l2' then begin
   rbsp_load_efw_waveform_l2,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                 varformat=varformat, valid_names = valid_names, files=files,$
                 type=type, integration=integration, msim=msim, etu=etu, $
                 qa=qa, coord = coord, noclean = noclean, $
                 tper = tper, tphase = tphase, _extra = _extra
   return
endif

if ~keyword_set(type) then type = 'calibrated'


if keyword_set(valid_names) then begin
    probe = vprobes
    level = vlevels
    datatype = vdatatypes
    return
endif

if not keyword_set(p_var) then p_var='*'
p_var = strfilter(vprobes, p_var ,delimiter=' ',/string)

if not keyword_set(datatype) then datatype='*'
datatype = strfilter(vdatatypes, datatype ,delimiter=' ',/string)

if not keyword_set(level) then level='l1'
level = strfilter(vlevels, level ,delimiter=' ',/string)

addmaster=0

color_array = [2,4,6,1,3,2,4,6,1,3]

for s=0,n_elements(p_var)-1 do begin
  for typeindex = 0,n_elements(datatype)-1 do begin
    rbspx = 'rbsp'+ p_var[s]
    if keyword_set(integration) then rbsppref = rbspx + '/l1_int' $
      else if keyword_set(msim) then rbsppref = rbspx+ '/l1_msim' $
      else if keyword_set(etu) then rbsppref = rbspx+ '/l1_etu' $
      else if keyword_set(qa) then rbsppref = rbspx+ '/l1_qa' $
      else rbsppref = rbspx + '/l1'

    ;Find out what files are available online
    format = rbsppref + '/'+datatype[typeindex]+'/YYYY/'+rbspx+'_l1_'+datatype[typeindex]+'_YYYYMMDD_v*.cdf'
    relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)


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
    prefix=rbspx+'_efw_'+datatype[typeindex]+'_'
    cdf2tplot,file=file_loaded,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
         tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables


    ;If there are actually files that have been loaded then continue
    if is_string(tns) then begin

       old_name = rbspx+'_efw_'+datatype[typeindex]+'_'+datatype[typeindex]
       new_name = rbspx+'_efw_'+datatype[typeindex]


       dprint, dlevel = 5, verbose = verbose, 'Setting options...'

       case datatype[typeindex] of
          'esvy': labels = ['E12 (U)', 'E34 (V)', 'E56 (W)']
          'vsvy': labels = ['V1', 'V2', 'V3', 'V4', 'V5', 'V6']
          'magsvy': labels = ['MAGU', 'MAGV', 'MAGW']
          'eb1': labels = ['E12 (U)', 'E34 (V)', 'E56 (W)']
          'vb1': labels = ['V1', 'V2', 'V3', 'V4', 'V5', 'V6']
          'mscb1': labels = ['SCMU', 'SCMV', 'SCMW']
          'eb2': labels = ['E12DC (U)', 'E34DC (V)', 'E56DC (W)', 'EDCpar', 'EDCperp', $
             'E12AC (U)', 'E34AC (V)', 'E56AC (W)', 'EACpar', 'EACperp' ]
          'vb2': labels = ['V1', 'V2', 'V3', 'V4', 'V5', 'V6']
          'mscb2': labels = ['SCMU', 'SCMV', 'SCMW', 'SCMpar', 'SCMperp']
       else: labels = 0
       endcase

      colors = color_array[0:n_elements(labels)-1]

      options, /def, tns, code_id = '$Id: rbsp_load_efw_waveform.pro 26341 2018-12-17 22:06:25Z aaronbreneman $'

      store_data,new_name,/delete
      store_data,old_name,newname=new_name
      get_data,new_name,dlimits=mydlimits
      str_element,mydlimits,'data_att',default_data_att,/add
      store_data,new_name,dlimits=mydlimits

      options,new_name,'labels',labels
      options,new_name,'colors',colors
      options,new_name,'labflag',1

      dprint, dlevel = 4, verbose = verbose, datatype[typeindex] + ' data Loaded for probe: '+p_var[s]

      if ~strcmp(type, 'raw', /fold) then begin
        rbsp_efw_cal_waveform, probe = p_var[s], $
          datatype = datatype[typeindex], trange = trange, $
          get_support_data = get_support_data, coord = coord, $
          tper = tper, tphase = tphase, noclean = noclean, _extra = _extra
      endif

      if not keyword_set(get_support_data) then begin
        for i = 0, n_elements(tns) - 1 do begin
          if strfilter(tns[i],'*'+support_data_keep) eq '' then begin
            get_data,tns[i],dlimits=thisdlimits
            cdf_str = 0
            str_element,thisdlimits,'cdf',cdf_str
            if keyword_set(cdf_str) then if cdf_str.vatt.var_type eq 'support_data' then $
              store_data,tns[i],/delete, verbose = 0
           endif
        endfor
      endif

    endif else begin
      dprint, dlevel = 0, verbose = verbose, 'No EFW ' + $
      datatype[typeindex] + ' data loaded...'+' Probe: '+p_var[s]
    endelse
  endfor
endfor


end
