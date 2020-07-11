;Procedure: RBSP_LOAD_EMFISIS
;
;Purpose:  Loads RBSP EMFISIS data. Loads L3 data unless the quicklook keyword is
;			specified.
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  varformat=string
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables. (NOT IMPLEMENTED YET)
;  /MSIM3: If set, load data from MSIM3.
;  /QUICKLOOK: If set, load quicklook data.
;  /DOWNLOADONLY: download file but don't read it. (NOT IMPLEMENTED YET)
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  type:  set to 'calibrated' to automatically convert data into physical units
;
;  coord: defaults to 'uvw', can also be gei,geo,gse,gsm,sm
;  cadence: defaults to cadence of the uvw data which is 64 S/s.
;			Can also set to '1sec', '4sec', 'hires'. See possible file names below:
;
;	/REMOVE_SPIKES  set to remove spikes at mag range change (hires and uvw data)
;
;  Possible data products (from EMFISIS website: http://emfisis.physics.uiowa.edu/Flight/)
;	Magnetometer 1sec cadence GEI (Survey):	rbsp-<?>_magnetometer_1sec-gei_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer 1sec cadence GEO (Survey):	rbsp-<?>_magnetometer_1sec-geo_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer 1sec cadence GSE (Survey):	rbsp-<?>_magnetometer_1sec-gse_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer 1sec cadence GSM (Survey):	rbsp-<?>_magnetometer_1sec-gsm_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer 1sec cadence SM (Survey):	rbsp-<?>_magnetometer_1sec-sm_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer 4sec cadence GEI (Survey):	rbsp-<?>_magnetometer_4sec-gei_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer 4sec cadence GEO (Survey):	rbsp-<?>_magnetometer_4sec-geo_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer 4sec cadence GSE (Survey):	rbsp-<?>_magnetometer_4sec-gse_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer 4sec cadence GSM (Survey):	rbsp-<?>_magnetometer_4sec-gsm_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer 4sec cadence SM (Survey):	rbsp-<?>_magnetometer_4sec-sm_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer full cadence GEI (Survey):	rbsp-<?>_magnetometer_hires-gei_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer full cadence SM (Survey):	rbsp-<?>_magnetometer_hires-sm_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;	Magnetometer full cadence UVW (Survey):	rbsp-<?>_magnetometer_uvw_emfisis-<xx>_<YYYYmmdd>_<version>.cdf
;
;
;
;Examples:
;
;	LOAD HIRES UVW COORD QUICKLOOK DATA
;   	rbsp_load_emfisis,probe=['a','b'],/quicklook
;
;	LOAD HIRES SM L3 DATA
;		rbsp_load_emfisis,probe=['a','b'],cadence='hires',coord='sm'
;
;
;
;Notes:
; 1. Written by Peter Schroeder, May 2012
;
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2020-07-10 14:15:01 -0700 (Fri, 10 Jul 2020) $
; $LastChangedRevision: 28872 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/emfisis/rbsp_load_emfisis.pro $
;-



;rbsp_load_emfisis,probe='a',coord='gse',level='l3',cadence='4sec'

pro rbsp_load_emfisis,probe=probe, datatype=datatype, trange=trange, $
  level=level, verbose=verbose, downloadonly=downloadonly, $
  cdf_data=cdf_data,get_support_data=get_support_data, $
  tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
  varformat=varformat, valid_names = valid_names, files=files,$
  type=type, msim3=msim3, quicklook = quicklook,$
  coord=coord, cadence=cadence, remove_spikes=remove_spikes


  rbsp_emfisis_init
  dprint,verbose=verbose,dlevel=4,'$Id: rbsp_load_emfisis.pro 28872 2020-07-10 21:15:01Z aaronbreneman $'

  if keyword_set(quicklook) then level = 'Quick-Look'
  if(keyword_set(probe)) then p_var = strlowcase(probe)


  vb = keyword_set(verbose) ? verbose : 0
  vb = vb > !rbsp_emfisis.verbose

  vprobes = ['a','b']
  vlevels = ['l1','l2','l3']
  vdatatypes=['mag']


  if ~keyword_set(type) then type = 'raw'


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

  ; default to L3 data
  if ~keyword_set(level) then begin
    message,'Using default L3 data.',/continue
    level='l3'
  endif


  case level of
    'Quick-Look':begin
    prod='Quick-Look'
    if ~keyword_set(coord) then begin
      message,'Using default L1 Quick-Look coordinates: uvw.',/continue
      coord='uvw'
    endif else begin
      coord=strlowcase(coord)
      if coord ne 'uvw' then begin
        message,'L1 Quick-Look is only available in uvw coordinates.  Returning...',/continue
        return
      endif
    endelse
    if keyword_set(cadence) then $
    message,'L1 Quick-Look data is full resolution.  Ignoring cadence keyword...',/continue
    cadence=''
  end
  'l2':begin
  prod='L2'
  if ~keyword_set(coord) then coord=''
  if coord ne 'uvw' and coord ne 'xyz' then begin
    message,'Unrecognized L2 coordinate system.  Returning...',/continue
    message,'Please specify coord="uvw" or "xyz" for L2 data.',/continue
    return
  endif
  if keyword_set(cadence) then $
  message,'L2 data is full resolution.  Ignoring cadence keyword...',/continue
  cadence=''
  end
  'l3':begin
  prod='L3'
  vcoords=['gei','geo','gse','gsm','sm']
  if ~keyword_set(coord) then coord=''
  if (where(vcoords eq coord) eq -1) then begin
    message,'Unrecognized L3 coordinate system.',/continue
    message,'Specify coord="gei", "geo", "gse", "gsm", or "sm" for L3 data.',/continue
    return
  endif
  vcadence=['1sec','4sec','hires']
  if ~keyword_set(cadence) then begin
    message,'Loading default 4sec L3 data...',/continue
    cadence='4sec'
  endif
  if (where(vcadence eq cadence) eq -1) then begin
    message,'Unrecognized L3 cadence.',/continue
    message,'Specify cadence="1sec", "4sec", or "hires" for L3 data.',/continue
    return
  endif
  end
  endcase


  addmaster=0

  probe_colors = ['m','b']


  tr = timerange()
  date = time_string(tr[0],/date_only,tformat='YYYYMMDD')
  yyyy = strmid(date,0,4)
  mm = strmid(date,4,2)
  dd = strmid(date,6,2)



  for s=0,n_elements(p_var)-1 do begin

    rbspprex = 'RBSP-'+ strupcase(p_var[s])
    rbspx = 'rbsp'+p_var[s]
    if keyword_set(MSIM3) then rbsppref = 'Pre-flight' $
    else rbsppref = 'Flight'


    if level eq 'l3' then begin
      rp = !rbsp_emfisis.remote_data_dir + 'Flight/RBSP-'+strupcase(probe)+'/'+strupcase(level)+'/'+yyyy+'/'+mm+'/'+dd+'/'
      rf = 'rbsp-'+probe+'_magnetometer_'+cadence+'-'+coord+'_emfisis-L3_'+date+'_*.cdf'
    endif
    if level eq 'Quick-Look' then begin
      rp = !rbsp_emfisis.remote_data_dir + 'Flight/RBSP-'+strupcase(probe)+'/Quick-Look/'+yyyy+'/'+mm+'/'+dd+'/'
      rf = 'rbsp-'+probe+'_magnetometer_'+coord+'_emfisis-Quick-Look_'+date+'_*.cdf'
    endif
    if level eq 'l2' then begin
      rp = !rbsp_emfisis.remote_data_dir + 'Flight/RBSP-'+strupcase(probe)+'/'+strupcase(level)+'/'+yyyy+'/'+mm+'/'+dd+'/'
      rf = 'rbsp-'+probe+'_magnetometer_'+coord+'_emfisis-L2_'+date+'_*.cdf'
    endif





    if level eq 'Quick-Look' then file = spd_download(remote_path=rp,remote_file=rf,$
    local_path=!rbsp_emfisis.local_data_dir+'Flight/RBSP-'+strupcase(probe)+'/Quick-Look/'+yyyy+'/'+mm+'/'+dd+'/',$
    /last_version)
    if level eq 'l3' then file = spd_download(remote_path=rp,remote_file=rf,$
    local_path=!rbsp_emfisis.local_data_dir+'Flight/RBSP-'+strupcase(probe)+'/L3/'+yyyy+'/'+mm+'/'+dd+'/',$
    /last_version)
    if level eq 'l2' then file = spd_download(remote_path=rp,remote_file=rf,$
    local_path=!rbsp_emfisis.local_data_dir+'Flight/RBSP-'+strupcase(probe)+'/L2/'+yyyy+'/'+mm+'/'+dd+'/',$
    /last_version)




    if keyword_set(!rbsp_emfisis.downloadonly) or keyword_set(downloadonly) then continue

    suf=''

    case level of
      'Quick-Look':ptag='quicklook'
      'l1':ptag='quicklook'
      'l2':ptag=level+'_'+coord
      'l3':ptag=level+'_'+cadence+'_'+coord
    endcase
    prefix = rbspx + '_emfisis_'+ptag+'_'


    cdf2tplot,file=file,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
    tplotnames=tns,/convert_int1_to_int2,get_support_data=get_support_data ; load data into tplot variables


    if is_string(tns) then begin

      ; Remove spikes due to change of mag range in hires data
      ; (adapted from JBT's rbsp_load_emfisis_quicklook)
      if (cadence eq 'hires' or coord eq 'uvw') and keyword_set(remove_spikes) then begin
        tvar=prefix+'Mag'
        get_data, tvar, data = data, dlim = dlim, lim = lim
        btot = sqrt(total(data.y^2,2))
        bsm = thm_lsp_median_smooth(btot, 21)
        bdiff = abs(btot - bsm)
        ind = where(bdiff gt 100)
        data.y[ind, *] = !values.d_nan
        data.y[*,0] = interp(data.y[*,0], data.x, data.x, /ignore_nan)
        data.y[*,1] = interp(data.y[*,1], data.x, data.x, /ignore_nan)
        data.y[*,2] = interp(data.y[*,2], data.x, data.x, /ignore_nan)
        store_data, tvar, data = data, dlim = dlim, lim = lim
      endif



      ;Remove spikes that occur due to change in datarate once 3000 nT is crossed
      rbsp_emfisis_remove_perigee_spike, prefix + 'Mag'
      get_data,prefix + 'Mag',data=dd
      ;Create Magnitude variable without spikes
      ;get limits structures
      get_data,prefix + 'Magnitude',dlim=dlim,lim=lim

      bmag = sqrt(dd.y[*,0]^2 + dd.y[*,1]^2 + dd.y[*,2]^2)
      store_data,prefix + 'Magnitude',dd.x,bmag,dlim=dlim,lim=lim



      dprint, dlevel = 5, verbose = verbose, 'Setting options...'

      ; set data_att
      options,prefix+'Mag',data_att={units:'nT',coord_sys:coord},/def
      options,prefix+'Magnitude',data_att={units:'nT'},/def

      pn = byte(p_var[s]) - byte('a')
      options, /def, tns, colors = probe_colors[pn]

      options, /def, tns, code_id = '$Id: rbsp_load_emfisis.pro 28872 2020-07-10 21:15:01Z aaronbreneman $'

      c_var = [1, 2, 3, 4, 5, 6]

      ;       hsk_options_grp = [thx+'_hsk_iefi_ibias',thx+'_hsk_iefi_usher',thx+'_hsk_iefi_guard']
      ;       hsk_options_ele = [thx+'_hsk_iefi_ibias?',thx+'_hsk_iefi_usher?',thx+'_hsk_iefi_guard?']


      ;       options, hsk_options_grp+'_raw', data_att = {units:'ADC'}, $
      ;         ysubtitle = '[ADC]', colors = c_var, labels = string(c_var), $
      ;         labflag = 1, /def
      ;       options, hsk_options_ele+'_raw', ata_att = {units:'ADC'}, $
      ;         ysubtitle = '[ADC]', labflag = 1, /def
      ;       options, thx+'_hsk_iefi_braid_raw', data_att = {units:'ADC'}, $
      ;         ysubtitle = '[ADC]', /def
      ;       options, hsk_options_grp+'_cal', colors = c_var, labels = string(c_var), $
      ;         labflag = 1, /def

      ;       options, /def, strfilter(tns, '*ietc_covers*'), tplot_routine = 'bitplot', colors = ''
      ;       options, /def ,strfilter(tns, '*ipwrswitch*'), tplot_routine = 'bitplot', colors= ''
      dprint, dwait = 5., verbose = verbose, 'Flushing output'
      dprint, dlevel = 4, verbose = verbose, 'EMFISIS MAG SEN data Loaded for probe: '+p_var[s]

    endif else begin
      dprint, dlevel = 0, verbose = verbose, 'No EMFISIS MAG SEN data loaded...'+' Probe: '+p_var[s]
      ;       dprint, dlevel = 0, verbose = verbose, 'Try using get_support_data keyword'
    endelse

  endfor

;if keyword_set(make_multi_tplotvar) then begin
;   tns = tnames('th?_hsk_*')
;   tns_suf = strmid(tns,8)
;   tns_suf = tns_suf[uniq(tns_suf,sort(tns_suf))]
;   for i=0,n_elements(tns_suf)-1 do store_data,'Thx_hsk_'+tns_suf[i],data=tnames('th?_hsk_'+tns_suf[i])
;endif





end
