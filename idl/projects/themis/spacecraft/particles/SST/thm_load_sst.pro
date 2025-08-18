;----------------------
;Procedure: THM_LOAD_SST
;
;Purpose:  Loads THEMIS SST data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, for this case, there is only
;          one option, the default value of 'sst', so this is a
;          placeholder should there be more that one data type. 'all'
;          can be passed in also, to get all variables.
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
;  /NO_TIME_CLIP: Disables time clipping, which is the default
;Example:
;   thg_load_sst,/get_suppport_data,probe=['a', 'b']
;   
;Notes on SST attenuator status bits (e.g thx_*_atten variables from L1 SST data):
;
;atten_flags are a 4-bit value for the attenuator flags
;Defined as MSB,Open Equatorial Attenuator,Closed Equatorial Attenuator,Open Polar Attenuator,Closed Polar Attenuator, LSB
;With MSB/LSB not representing actual bits, but as labels to clarify bit order.
;Some examples:
; 0x5: both attenuators closed
; 0xA: both attenuators open
; 0x6: equatorial closed, polar open  (Occurs during stuck atten error on themis D)
; 0xf: Error state. Invalid data.
; 0x9: equatorial open, polar closed (This should never actually happen)
;
;Notes:
; Written by Davin Larson, Dec 2006
; Updated to use thm_load_xxx by KRB, 2007-2-5
; Update removed to not use thm_load_xxx by DEL
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-02-11 15:44:23 -0800 (Tue, 11 Feb 2025) $
; $LastChangedRevision: 33123 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_load_sst.pro $
;-


;change Matt D. 6/29
;----------------------

function thm_load_sst_relpath, sname=probe, filetype=ft, $
                               level=lvl, trange=trange, $
                               addmaster=addmaster, _extra=_extra

  compile_opt idl2,hidden

  relpath = 'th'+probe+'/'+lvl+'/'+ ft+'/'
  prefix = 'th'+probe+'_'+lvl+'_'+ft+'_'
  dir = 'YYYY/'
  ending = '_v01.cdf'

  return, file_dailynames(relpath, prefix, ending, dir=dir, $
                          trange = trange,addmaster=addmaster)
end

;abstacting L1, to get rid of an annoying "goto"
pro thm_load_sst_l1,datatype=datatype,vdatatypes=vdatatypes,probe=probe,$
  trange=trange,my_themis=my_themis,downloadonly=downloadonly,verbose=vb,$
  use_eclipse_corrections=use_eclipse_corrections,suffix=suffix,no_time_clip=no_time_clip,$
  files=files_out


  compile_opt idl2,hidden
  
  tn_pre_proc = tnames()
  
  if not keyword_set(datatype) then datatype='*'
  if not keyword_set(suffix) then suffix=''
  
  datatype = strfilter(vdatatypes, datatype ,delimiter=' ',/string)
 
  addmaster=0
  
  for s=0,n_elements(probe)-1 do begin
    sc = 'th'+ probe[s]
    
    ;     format = sc+'l1/sst/YYYY/'+sc+'_l1_sst_YYYYMMDD_v01.cdf'   ; Won't work! for sst
    relpathnames = file_dailynames(sc+'/l1/sst/',dir='YYYY/',sc+'_l1_sst_','_v01.cdf',trange=trange,addmaster=addmaster)
    files = spd_download(remote_file=relpathnames, _extra=my_themis ) ;, nowait=downloadonly)
    
    if keyword_set(files) then begin
      files_out=array_concat(files,files_out)
    endif
    
    if keyword_set(downloadonly) or my_themis.downloadonly then continue
    
    cdfi = cdf_load_vars(files,/all,verbose=vb)
    if not keyword_set(cdfi) then begin
      continue
    endif
    
    cdf_data=cdfi
    
    ;     name = sc+'_sst_raw_data'
    ;     data_cache,name,data,/set,/no_copy
    vns = cdfi.vars.name
    
    ;     distdat = {  $
    ;        data:ptr_new()       ,$
    ;        time:ptr_new()    ,$
    ;        cnfg:ptr_new()    ,$
    ;        emode: ptr_new()    ,$
    ;        amode: ptr_new()    $
    ;     }

    cache = {  $
      project_name:    ''     , $
      data_name:  'SST data'  , $
      sc_name:      probe[s]    , $
      sif_064_time  : cdfi.vars[where(vns eq sc+'_sif_064_time')].dataptr   , $
      sif_064_cnfg  : cdfi.vars[where(vns eq sc+'_sif_064_config')].dataptr   , $
      sif_064_nspins: cdfi.vars[where(vns eq sc+'_sif_064_nspins')].dataptr   , $
      sif_064_atten : cdfi.vars[where(vns eq sc+'_sif_064_atten')].dataptr   , $
      ;     sif_064_hed   : cdfi.vars[where(vns eq sc+'_sif_064_hed')].dataptr   , $
      sif_064_data  : cdfi.vars[where(vns eq sc+'_sif_064')].dataptr  , $
      sif_064_edphi : ptr_new(), $
      
      sef_064_time  : cdfi.vars[where(vns eq sc+'_sef_064_time')].dataptr  , $
      sef_064_cnfg  : cdfi.vars[where(vns eq sc+'_sef_064_config')].dataptr  , $
      sef_064_nspins: cdfi.vars[where(vns eq sc+'_sef_064_nspins')].dataptr   , $
      sef_064_atten : cdfi.vars[where(vns eq sc+'_sef_064_atten')].dataptr   , $
      ;     sef_064_hed   : cdfi.vars[where(vns eq sc+'_sef_064_hed')].dataptr   , $
      sef_064_data  : cdfi.vars[where(vns eq sc+'_sef_064')].dataptr  , $
      sef_064_edphi : ptr_new(), $
      
      seb_064_time  : cdfi.vars[where(vns eq sc+'_seb_064_time')].dataptr  , $
      seb_064_cnfg  : cdfi.vars[where(vns eq sc+'_seb_064_config')].dataptr  , $
      seb_064_nspins: cdfi.vars[where(vns eq sc+'_seb_064_nspins')].dataptr   , $
      seb_064_atten : cdfi.vars[where(vns eq sc+'_seb_064_atten')].dataptr   , $
      ;     seb_064_hed   : cdfi.vars[where(vns eq sc+'_seb_064_hed')].dataptr   , $
      seb_064_data  : cdfi.vars[where(vns eq sc+'_seb_064')].dataptr  , $
      seb_064_edphi : ptr_new(), $
      
      sir_001_time  : cdfi.vars[where(vns eq sc+'_sir_001_time')].dataptr  , $
      sir_001_cnfg  : cdfi.vars[where(vns eq sc+'_sir_001_config')].dataptr  , $
      sir_001_nspins: cdfi.vars[where(vns eq sc+'_sir_001_nspins')].dataptr   , $
      sir_001_atten : cdfi.vars[where(vns eq sc+'_sir_001_atten')].dataptr   , $
      ;     sir_001_hed   : cdfi.vars[where(vns eq sc+'_sir_001_hed')].dataptr   , $
      sir_001_data  : cdfi.vars[where(vns eq sc+'_sir_001')].dataptr  , $
      sir_001_edphi : ptr_new(), $
      
      ser_001_time  : cdfi.vars[where(vns eq sc+'_ser_001_time')].dataptr  , $
      ser_001_cnfg  : cdfi.vars[where(vns eq sc+'_ser_001_config')].dataptr  , $
      ser_001_nspins: cdfi.vars[where(vns eq sc+'_ser_001_nspins')].dataptr   , $
      ser_001_atten : cdfi.vars[where(vns eq sc+'_ser_001_atten')].dataptr   , $
      ;     ser_001_hed   : cdfi.vars[where(vns eq sc+'_ser_001_hed')].dataptr   , $
      ser_001_data  : cdfi.vars[where(vns eq sc+'_ser_001')].dataptr  , $
      ser_001_edphi : ptr_new(), $
      
      sir_006_time  : cdfi.vars[where(vns eq sc+'_sir_006_time')].dataptr  , $
      sir_006_cnfg  : cdfi.vars[where(vns eq sc+'_sir_006_config')].dataptr  , $
      sir_006_nspins: cdfi.vars[where(vns eq sc+'_sir_006_nspins')].dataptr   , $
      sir_006_atten : cdfi.vars[where(vns eq sc+'_sir_006_atten')].dataptr   , $
      sir_006_data  : cdfi.vars[where(vns eq sc+'_sir_006')].dataptr  , $
      sir_006_edphi : ptr_new(), $
      
      ser_006_time  : cdfi.vars[where(vns eq sc+'_ser_006_time')].dataptr  , $
      ser_006_cnfg  : cdfi.vars[where(vns eq sc+'_ser_006_config')].dataptr  , $
      ser_006_nspins: cdfi.vars[where(vns eq sc+'_ser_006_nspins')].dataptr   , $
      ser_006_atten : cdfi.vars[where(vns eq sc+'_ser_006_atten')].dataptr   , $
      ser_006_data  : cdfi.vars[where(vns eq sc+'_ser_006')].dataptr  , $
      ser_006_edphi  : ptr_new(), $
      
      isst_config  : cdfi.vars[where(vns eq sc+'_isst_config')].dataptr  , $
      isst_config_time  : cdfi.vars[where(vns eq sc+'_isst_config_time')].dataptr  , $
      esst_config  : cdfi.vars[where(vns eq sc+'_esst_config')].dataptr  , $
      esst_config_time  : cdfi.vars[where(vns eq sc+'_esst_config_time')].dataptr  , $
      
      sst_atten_time : cdfi.vars[where(vns eq sc+'_sst_atten_time')].dataptr  , $
      sst_atten : cdfi.vars[where(vns eq sc+'_sst_atten')].dataptr  , $

      sir_mix_time  : ptr_new() , $
      sir_mix_index : ptr_new() , $
      sir_mix_mode  : ptr_new() , $
      ser_mix_time  : ptr_new() , $
      ser_mix_index : ptr_new() , $
      ser_mix_mode  : ptr_new() , $
      
      valid : 1 }
      
    If(ptr_valid(cache.isst_config_time) && ptr_valid(cache.isst_config)) Then $
       store_data,sc+'_isst_config' +suffix[0],data={x:*cache.isst_config_time,y:*cache.isst_config}
    If(ptr_valid(cache.esst_config_time) && ptr_valid(cache.esst_config)) Then $
       store_data,sc+'_esst_config' +suffix[0],data={x:*cache.esst_config_time,y:*cache.esst_config}

    If(ptr_valid(cache.sst_atten_time) && ptr_valid(cache.sst_atten)) Then $
       store_data,sc+'_sst_atten' +suffix[0],data={x:*cache.sst_atten_time,y:*cache.sst_atten}, $
                  dlimit={tplot_routine:'bitplot'}
    
    if ptr_valid(cache.sir_006_time) && ptr_valid(cache.sir_001_time) then begin
    
      sir_mix_time  = [ *cache.sir_006_time, *cache.sir_001_time ] ; this can easily fail!
      sir_mix_index = [lindgen(n_elements(*cache.sir_006_time)), lindgen(n_elements(*cache.sir_001_time)) ]
      sir_mix_mode  = [replicate(0,n_elements(*cache.sir_006_time)), replicate(1,n_elements(*cache.sir_001_time)) ]
      
    endif else if ptr_valid(cache.sir_001_time) then begin
    
      sir_mix_time  = [ *cache.sir_001_time ] ; this can easily fail!
      sir_mix_index = [ lindgen(n_elements(*cache.sir_001_time)) ]
      sir_mix_mode  = [ replicate(1,n_elements(*cache.sir_001_time)) ]
      
    endif else if ptr_valid(cache.sir_006_time) then begin
    
      sir_mix_time  = [ *cache.sir_006_time ] ; this can easily fail!
      sir_mix_index = [ lindgen(n_elements(*cache.sir_006_time)) ]
      sir_mix_mode  = [ replicate(1,n_elements(*cache.sir_006_time)) ]
      
    endif else begin
    
      dprint,dlevel=0,'No valid ion data in interval'
      return
      
    endelse
    
    srt = sort(sir_mix_time)
    cache.sir_mix_time  = ptr_new( sir_mix_time[srt] )
    cache.sir_mix_index = ptr_new( sir_mix_index[srt] )
    cache.sir_mix_mode  = ptr_new( sir_mix_mode[srt] )
    
    if ptr_valid(cache.ser_006_time) && ptr_valid(cache.ser_001_time) then begin
    
      ser_mix_time  = [ *cache.ser_006_time, *cache.ser_001_time ] ; this can easily fail!
      ser_mix_index = [lindgen(n_elements(*cache.ser_006_time)), lindgen(n_elements(*cache.ser_001_time)) ]
      ser_mix_mode  = [replicate(0,n_elements(*cache.ser_006_time)), replicate(1,n_elements(*cache.ser_001_time)) ]
      
    endif else if ptr_valid(cache.ser_001_time) then begin
    
      ser_mix_time  = [*cache.ser_001_time ] ; this can easily fail!
      ser_mix_index = [lindgen(n_elements(*cache.ser_001_time)) ]
      ser_mix_mode  = [replicate(1,n_elements(*cache.ser_001_time)) ]
      
    endif else if ptr_valid(cache.ser_006_time) then begin
    
      ser_mix_time  = [*cache.ser_006_time ] ; this can easily fail!
      ser_mix_index = [lindgen(n_elements(*cache.ser_006_time)) ]
      ser_mix_mode  = [replicate(1,n_elements(*cache.ser_006_time)) ]
      
    endif else begin
    
      dprint,dlevel=0,'No valid ion data in interval'
      return
      
    endelse
    
    srt = sort(ser_mix_time)
    cache.ser_mix_time  = ptr_new( ser_mix_time[srt] )
    cache.ser_mix_index = ptr_new( ser_mix_index[srt] )
    cache.ser_mix_mode  = ptr_new( ser_mix_mode[srt] )
    
    
    ptrs = ptr_extract(cdfi,except=ptr_extract(cache))
    ptr_free,ptrs
    name = sc+'_sst_raw_data'
    
    ; Check for timing problems:
    ctags = tag_names(cache)
    wt = strfilter(ctags,'*TIME',count=c,/index)
    for i=0,c-1 do begin
      if ptr_valid( cache.(wt[i]) ) then begin
        t = *( cache.(wt[i]) )
        dt = t-shift(t,1)
        If(n_elements(dt) Gt 1) Then dt[0] = dt[1]
        w = where(dt le 0,nw)
        if nw gt 0 then begin
          ;                beep
          ;2012-July  raised debug level, does not appear necessary
          dprint,dlevel=4,'Data File Error: ',name,'  ',ctags[wt[i]]
          dprint,dlevel=4,/phelp,w
          dprint,dlevel=4,/phelp,dt[w]  ;,varname='dt'
          dprint,dlevel=4,/phelp,time_string(t[w])  ;,varname='time'
          ;                wait,1.             ;bp
        endif
      endif
    endfor
    
    thm_sst_add_spindata, cache, trange=trange, use_eclipse_corrections=use_eclipse_corrections
    
    thm_sst_set_trange, cache, trange=trange, use_eclipse_corrections=use_eclipse_corrections
    
    data_cache,name,cache,/set,/no_copy
    
    thm_sst_to_tplot,probe=probe[s], suffix=suffix
    
    ; make sure tplot_vars created in post_procs get added to list
    tn_post_proc = tnames()
    
    if ~array_equal(tn_pre_proc, '') then begin
    
      ; make ssl_set_intersection doesn't get scalar inputs
      if n_elements(tn_pre_proc) eq 1 then tn_pre_proc=[tn_pre_proc]
      if n_elements(tn_post_proc) eq 1 then tn_post_proc=[tn_post_proc]
      
      post_proc_names = ssl_set_complement(tn_pre_proc, tn_post_proc)
      if size(post_proc_names, /type) eq 7 then tplotnames = post_proc_names
    endif else tplotnames = tn_post_proc
    ; clip data to requested trange
    If(~keyword_set(no_time_clip)) Then Begin
      If (keyword_set(trange) && n_elements(trange) Eq 2) $
        Then tr = timerange(trange) Else tr = timerange()
      for i = 0, n_elements(tplotnames)-1 do begin
        if tnames(tplotnames[i]) eq '' then continue
        time_clip, tplotnames[i], min(tr), max(tr), /replace, error = tr_err
        if tr_err then del_data, tplotnames[i]
      endfor
    Endif
  endfor
  
  
  return

end

;abstacting L2, to get rid of an annoying "goto"
pro thm_load_sst_l2,relpathnames_all=relpathnames_all,suffix=suffix,level=level,$
  probe=probe,datatype=datatype,trange=trange,verbose=verbose,downloadonly=downloadonly,$
  no_download=no_download,cdf_data=cdf_data,get_support_data=get_support_data,$
  varnames=varnames,valid_names=valid_names,files=files,progobj=progobjs,$
  varformat=varformat,get_cdf_data=get_cdf_data,no_time_clip=no_time_clip

  compile_opt idl2,hidden
  
  if not keyword_set(suffix) then suffix = ''
  
  vlevels_str = 'l1 l2'
  deflevel = 'l2'
  lvl = thm_valid_input(level,'Level',vinputs=vlevels_str,definput=deflevel,$
    format="('l', I1)", verbose=0)
  if lvl eq '' then return
 
  l2_datatype_root_list = ['delta_time','en_eflux','density','avgtemp','vthermal','sc_pot','t3','magt3','ptens','mftens','flux','symm',$
    'symm_ang','magf','velocity_dsl','velocity_gse','velocity_gsm','data_quality']
  vL2datatypes=  strjoin(['psif_'+l2_datatype_root_list,'psef_'+ l2_datatype_root_list, $
     'psib_'+l2_datatype_root_list,'pseb_'+ l2_datatype_root_list],' ')
 
  thm_load_xxx,sname=probe, datatype=datatype, trange=trange, $
    level=level, verbose=verbose, downloadonly=downloadonly, $
    relpathnames_all=relpathnames_all, no_download=no_download, $
    cdf_data=cdf_data,get_cdf_data=get_cdf_data, $
    get_support_data=get_support_data, $
    varnames=varnames, valid_names = valid_names, files=files, $
    vsnames = 'a b c d e', $
    type_sname = 'probe', $
    vdatatypes = 'sst', $
    file_vdatatypes = 'sst', $
    vlevels = vlevels_str, $
    vL2datatypes = vL2datatypes, $
    vL2coord = '', $
    deflevel = deflevel, $
    version = 'v01', $
    relpath_funct = 'thm_load_sst_relpath', $
    suffix=suffix, $
    progobj=progobj,$
    varformat=varformat, no_time_clip = no_time_clip,$
    tplotnames=tplotnames
    
    
  ;set good metadata settings on output variables
  ;
  ;filter list of vars from tplotnames so we don't accidentally mutate settings on other similarly named tplot variables
  
  if ~undefined(tplotnames) then begin
    ;eflux spectra
    en_eflux_vars = strfilter(tplotnames,'*en_eflux*')
    options,en_eflux_vars,/default,/zlog,/ylog
    spd_new_units, en_eflux_vars, units_in = 'eV/(cm^2-sec-sr-eV)'
    spd_new_coords,en_eflux_vars, coords_in = 'DSL'
    thm_fix_spec_units, en_eflux_vars
    
    ;flux vectors
    flux_vars = strfilter(tplotnames,'*_flux*')
    options,flux_vars,/def,/ystyle
    spd_new_coords,flux_vars, coords_in = 'DSL'
    
    ;density
    den_vars = strfilter(tplotnames,'*density*')
    options,den_vars,/default,/ylog,/ystyle
    spd_new_units, den_vars, units_in = '1/cm^3'
    
    ;temperature vectors
    t3_vars =  strfilter(tplotnames,'*t3*')
    options,t3_vars,/default,/ylog,colors='bgr',/ystyle
    spd_new_units, t3_vars, units_in = 'eV'
    
    spd_new_coords,strfilter(tplotnames,'*_t3*'), coords_in = 'DSL'
    spd_new_coords,strfilter(tplotnames,'*_magt3*'), coords_in = 'FA'
    
    ;tensors
    tens_vars = strfilter(tplotnames,'*tens*')
    options,tens_vars,/default,colors='bgrmcy',/ystyle
    spd_new_coords,tens_vars, coords_in = 'DSL'
    
    ;velocity vectors
    vel_vars = strfilter(tplotnames,'*velocity*')
    options,vel_vars,/defaults,/ystyle
    spd_new_units, vel_vars, units_in = 'km/s'
    
    spd_new_coords, strfilter(tplotnames,'*_velocity_dsl*'), coords_in = 'DSL'
    spd_new_coords, strfilter(tplotnames,'*_velocity_gse*'), coords_in = 'GSE'
    spd_new_coords, strfilter(tplotnames,'*_velocity_gsm*'), coords_in = 'GSM'
    
    ;magnetic field support data
    mag_names = strfilter(tplotnames,'*_magf*')
    spd_new_units,mag_names, units_in ='nT'
    spd_new_coords,mag_names, coords_in = 'DSL'
    
    ;spacecraft potential support data
    scpot_names = strfilter(tplotnames,'*_sc_pot*')
    spd_new_units,scpot_names, units_in ='V'
    
    symm_ang_names = strfilter(tplotnames,'*_symm_ange*')
    spd_new_units,scpot_names, units_in ='degrees'

  endif

end

pro thm_load_sst,probe=probematch, datatype=datatype0, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 varnames=varnames, valid_names = valid_names, files=files, $
                 use_eclipse_corrections=use_eclipse_corrections, $
                 source_options = source_options, $
                 progobj=progobj, varformat=varformat, $
                 suffix = suffix, no_time_clip = no_time_clip

compile_opt idl2

if not keyword_set(source_options) then begin
   thm_init
   source_options = !themis
endif
my_themis = source_options
;my_themis.remote_data_dir += 'qa/'  ; remove this line after files have moved to proper location.

if size(/type,datatype0) gt 0 then datatype = datatype0 ;keep input vars from being altered

vb = keyword_set(verbose) ? verbose : 0
vb = vb > my_themis.verbose
dprint,dlevel=4,verbose=vb,'Start; $Id: thm_load_sst.pro 33123 2025-02-11 23:44:23Z jwl $'

vprobes = ['a','b','c','d','e'];,'f']
vlevels = ['l1','l2']
vdatatypes=['sst']

if keyword_set(valid_names) then begin
    probematch = vprobes
    level = vlevels
    datatype = vdatatypes
    return
endif

if n_elements(probematch) eq 1 then if probematch eq 'f' then vprobes = ['f']

;if not keyword_set(probematch) then probematch='*'
;probe = strfilter(vprobes, probematch ,delimiter=' ',/string)

if not keyword_set(probematch) then probematch=vprobes
probe=ssl_check_valid_name(strtrim(strlowcase(probematch),2),vprobes,/include_all, $
                           invalid=msg_probe, type='probe')

if probe[0] eq '' then begin
  dprint, "Invalid probes selected.  Valid probes: 'a','b','c','d' or 'e'  (ie, probe='a')"
  return
end

;change Matt D. 6/29
;----------------------
vlevels_str='l1 l2'
deflevel='l1'
lvl = thm_valid_input(level,'Level',vinputs=vlevels_str,definput=deflevel,$
                        format="('l', I1)", verbose=0)

  if lvl eq 'l2' then begin 
    
    if arg_present(relpathnames_all) then begin
      downloadonly=1
      no_download=1
    end
    get_cdf_data = arg_present(cdf_data)
    
    thm_load_sst_l2,relpathnames_all=relpathnames_all,suffix=suffix,level=level,$
       probe=probe,datatype=datatype,trange=trange,verbose=verbose,downloadonly=downloadonly,$
       no_download=no_download,cdf_data=cdf_data,get_support_data=get_support_data,$
       varnames=varnames,valid_names=valid_names,files=files,progobj=progobjs,$
       varformat=varformat,get_cdf_data=get_cdf_data
       
  endif else begin
    thm_load_sst_l1,datatype=datatype,vdatatypes=vdatatypes,probe=probe,$
      trange=trange,my_themis=my_themis,downloadonly=downloadonly,verbose=vb,files=files,$
      use_eclipse_corrections=use_eclipse_corrections,suffix=suffix,no_time_clip=no_time_clip
      
  endelse

  ;----------------------

  ;notify user of invalid input
  if keyword_set(msg_probe) then dprint, dlevel=1, msg_probe

end







