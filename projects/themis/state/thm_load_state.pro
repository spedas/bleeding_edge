;+
;Procedure: THM_LOAD_STATE
;
;Purpose:  Loads THEMIS STATE (orbit and attitude) data
;
;;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, can be an array of strings
;          or single string separate by spaces.  The default is 'pos vel'
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  version = the version of the state file, one of 'v00', 'v01', 'v02', 'v03'.
;            defaults to 'v01'
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  suffix= suffix to add to tplot variable names.  Note: this will get added
;          support_data variables as well as regular data variables.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /no_download: use only files which are online locally.
;  /NO_UPDATE: prevent contact to server if local file already exists.
;  relpathnames_all: named variable in which to return all files that are
;          required for specified timespan, probe, datatype, and level.
;          If present, no files will be downloaded, and no data will be loaded.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          level, and version options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  coord: Can specify the coordinate system you would like data
;  returned in.
;  no_spin: if set, do not call thm_load_spin to load spinmodel data.
;
;Example:
;   thm_load_state
;Notes:
;
;Modifications:
;  If /GET_SUPPORT_DATA and ~/NO_SPIN, then call THM_LOAD_SPIN, W.M.Feuerstein,
;    4/10/2008.
;  Delete th?_spin* TPLOT variables after calling THM_LOAD_SPIN (as long as
;    ~/KEEP_SPIN_DATA), add KEEP_SPIN_DATA kw, include a couple of (normally
;    commented) lines to chck consistency of spinmodel, WMF, 4/10/08.
;
; coordinate systems of returned variables:
; *_pos : gei
; *_vel : gei
; *_ras : gei
; *_dec : gei
; *_alpha : spg
; *_beta : spg
; *_spinper : none(listed in dlimits as unknown)
; *_spinphase : none(listed in dlimits as unknown)
; *_roi : none(listed in dlimits as unknown)
; *_man : none(listed in dlimits as unknown)
;
; If you modify the d_names constant make sure to make the
; corresponding changes to the c_names constant
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-10-07 12:12:46 -0700 (Fri, 07 Oct 2016) $
; $LastChangedRevision: 22069 $
; $URL $
;-

pro thm_load_state_post, sname=probe, datatype=dt, level=lvl, $
                         tplotnames = tplotnames, $
                         suffix = suffix, proc_type = proc_type, coord = coord, $
                         delete_support_data = delete_support_data, $
                         c_names = c_names, $
                         d_names = d_names, $
                         u_names = u_names, $
                         get_support_data = get_support_data, no_spin = no_spin, $
                         keep_spin_data = keep_spin_data, $
                         trange = trange, $
                         no_time_clip=no_time_clip, $
                         _extra = _extra

;=================================================================
;If /GET_SUPPORT_DATA and ~/NO_SPIN then post-process spinmodel variables 
; by calling SPINMODEL_POST_PROCESS.PRO.  Data is stored in the 
; SPINMODEL_COMMON common block, so delete (if ~/KEEP_SPIN_DATA) 
; th?_state_spin_* TPLOT variables when done:
;=================================================================
if keyword_set(get_support_data) && ~keyword_set(no_spin) then begin
  spinmodel_post_process,sname=probe,midfix='_state', suffix=suffix, no_update=no_update
  if ~keyword_set(keep_spin_data) then begin
    ;tplot_names,'th?_state_spin_*',names=tp_spin_names
    tp_spin_names = tnames('th?_state_spin_*')
    store_data,tp_spin_names,/delete
  endif
  ;=================================================
  ;For QA testing.  Uncomment and set break for test,
  ;and .stepover to get consistency messages:
  ;(Does not work with PROBE= a regular erxpression.
  ;=================================================
  ;spinmodel_test,spinmodel_ptr
  ;spinmodel_ptr = spinmodel_get_ptr(probe)
endif

; Apply the spin axis RA and Dec corrections, creating new tplot variables

spinras_var='th'+probe+'_state_spinras'
delta_spinras_var='th'+probe+'_state_spinras_correction'
corrected_spinras_var='th'+probe+'_state_spinras_corrected'

spindec_var='th'+probe+'_state_spindec'
delta_spindec_var='th'+probe+'_state_spindec_correction'
corrected_spindec_var='th'+probe+'_state_spindec_corrected'

if keyword_set(suffix) then begin
   ; Add suffix to spin axis correction variables
   spinras_var = spinras_var + suffix
   delta_spinras_var = delta_spinras_var + suffix
   corrected_spinras_var = corrected_spinras_var + suffix

   spindec_var = spindec_var + suffix
   delta_spindec_var = delta_spindec_var + suffix
   corrected_spindec_var = corrected_spindec_var + suffix
endif

apply_spinaxis_corrections,spinras=spinras_var,delta_spinras=delta_spinras_var, $
  corrected_spinras=corrected_spinras_var, spindec=spindec_var, $
  delta_spindec=delta_spindec_var, corrected_spindec=corrected_spindec_var

 ;set the coords meta data properly

dt_temp = strsplit(dt,' ',/extract)

;if a coordinate transformation is being done
;support data must be loaded
if keyword_set(coord) then begin
    tn_before = [tnames('*')]
    thm_load_state, probe = probe, /get_support_data, suffix = '_state_temp', trange = trange  ;jmm, 2009-10-08
    tn_after = [tnames('*')]
endif

; Default to "clip", if no_time_clip is not passed.  (should not happen!)

if (n_elements(no_time_clip) EQ 0) then no_time_clip=0

for i = 0,n_elements(dt_temp)-1L do begin
    
    if(keyword_set(suffix)) then $
       var_name = 'th'+probe+'_state_'+dt_temp[i]+suffix $
    else $
       var_name = 'th'+probe+'_state_'+dt_temp[i]
        
    idx = where(dt_temp[i] eq d_names)
    if(idx[0] eq -1L) then begin
        dprint,'thm_load_state_post error setting coords, found unrecognized datatype: ' + dt_temp[i]
        coord_name = 'unknown'
        unit_name = 'unknown'
    endif else begin
        coord_name = c_names[idx[0]]
        unit_name = u_names[idx[0]]
    endelse    

    if(tnames(var_name) ne '') then begin

        ; If trange is set, and no_time_clip=0, go ahead and clip
        ; non-spinmodel-related values  (Currently, no_time_clip
        ; should always be set and passed via thm_load_xxx)
      
        If (keyword_set(trange) && n_elements(trange) Eq 2 && no_time_clip EQ 0) then begin
           if (STRMATCH(var_name,'*spin*') NE 1) then begin
              time_clip, var_name, trange[0], trange[1], /replace
           endif
        endif
      
        get_data,var_name,data=d,limit=l,dlimit=dl
        cotrans_set_coord,dl,coord_name


        ; Populate dlimits.colors to match tplot defaults
        ; for pos and vel variables.
        tdas_default_colors=[2,4,6]        
        ;add labels indicating whether data is pos, vel, or neither
        if stregex(dt_temp[i],'pos',/boolean) then begin
          str_element,dl,'data_att.st_type','pos',/add
          str_element,dl,'colors',tdas_default_colors,/add
        endif else if stregex(dt_temp[i],'vel',/boolean) then begin
          str_element,dl,'data_att.st_type','vel',/add
          str_element,dl,'colors',tdas_default_colors,/add
        endif else begin
          str_element,dl,'data_att.st_type','none',/add
        endelse
        
        store_data,var_name,data=d,limit=l,dlimit=dl
        spd_new_units,var_name,units_in=unit_name

;        if keyword_set(coord) && $
;          coord_name ne 'unknown' && $
;          strlowcase(coord) ne coord_name && $
;          (dt_temp[i] eq 'pos' || dt_temp[i] eq 'vel') then begin
        if keyword_set(coord) && $
          coord_name ne 'unknown' && $
          strlowcase(coord) ne coord_name && $
          (dt_temp[i] eq 'pos' || dt_temp[i] eq 'vel') then begin

            if dt_temp[i] eq 'vel' then begin
              dprint,'WARNING.  thm_cotrans does not account for the rotational component in velocity transformations: ' +var_name+ ' may have errors' 
            endif       
       
            if (strlowcase(coord) eq 'sse' || strlowcase(coord) eq 'sel') then begin
               thm_autoload_support, vname=var_name, slp=1
            endif 
            get_data, var_name, data=d, dlimits=dl
            thm_cotrans, var_name, out_coord = coord,support_suffix='_state_temp'
            
        endif
        
        ; convert the spin attitude as well  
        if keyword_set(coord) && $
          coord_name ne 'unknown' && $
          strlowcase(coord) ne coord_name && $
          (dt_temp[i] eq 'spinras' || dt_temp[i] eq 'spindec') then begin

          ; get ras - if needed load ras 
          ind=where(strmatch(tnames('*'),spinras_var) eq 1, ncnt)
          if ncnt eq 0 then begin
             thm_load_state, probe = probe, datatype='spinras', suffix='_state_temp', trange = trange  ;jmm, 2009-10-08
             tn_after = [tn_after, 'th'+probe+'_state_spinras_state_temp']
          endif   
          get_data, 'th'+probe+'_state_spinras_state_temp', data=ras, dlimits=dlras, limits=lras
 
          ; get dec - if needed load dec          
          ind=where(strmatch(tnames('*'),spindec_var) eq 1, ncnt)
          if ncnt eq 0 then begin
             thm_load_state, probe = probe, datatype='spindec', suffix='_state_temp', trange = trange  ;jmm, 2009-10-08
             tn_after = [tn_after, 'th'+probe+'_state_spindec_state_temp']
          endif   
          get_data, 'th'+probe+'_state_spindec_state_temp', data=dec, dlimits=dldec, limits=ldec

          ; convert to cartesian coordinates and create new tplot var
          r = make_array(n_elements(ras.x), /double)+1.0
          sphere_to_cart, r, dec.y, ras.y, vec=xyz
          spin_att_tname = 'th'+probe+'_state_spin_att'
          if dt_temp[i] eq 'spinras' then dl=dlras else dl=dldec
          if dt_temp[i] eq 'spinras' then l=lras else l=ldec            
          store_data, spin_att_tname, data={x:ras.x, y:xyz}, dlimits=dl, limits=l
             
          ; perform the coordinate transform and convert back to spherical 
          thm_cotrans, spin_att_tname, out_coord=coord, support_suffix='_state_temp'
          get_data, spin_att_tname, data=d, dlimits=dl, limits=l
          cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, dec1, ras1, PH_0_360=1 

          ; add state spin att to tn_after (for deletion at end of program)
          tn_after = [tn_after, spin_att_tname]

          ; place the transformed ras or dec back in the tplot variable
          if dt_temp[i] eq 'spinras' then d={x:ras.x, y:ras1} else d={x:dec.x, y:dec1}
          store_data, var_name, data=d, dlimits=dl, limits=l

        endif

        is_pos = strmatch(tnames(var_name), 'th?_state_pos*')
        is_vel = strmatch(tnames(var_name), 'th?_state_vel*')
        If(is_pos Eq 1 Or is_vel Eq 1) Then Begin
          If(is_pos Eq 1) Then begin
             if keyword_set(coord) then labels = [ 'x_'+coord, 'y_'+coord, 'z_'+coord] $
                else labels = ['x', 'y', 'z'] 
             
          endif else begin
             if keyword_set(coord) then labels = [ 'vx_'+coord, 'vy_'+coord, 'vz_'+coord] $
                else labels = ['vx', 'vy', 'vz']
          endelse
          options, var_name, labels = labels,/def
          options, var_name, 'ysubtitle', '['+unit_name+']', /add,/def
        Endif
    endif

endfor

;set options for roi data, bitplot, labels
roi_labels = ['ESH', 'LSH', 'AAZ', 'SAA', 'NAZ', 'SAZ', 'PAP', $
              'RBT', 'PSP', 'SHK', 'SWB', 'HMF', 'APS', 'BSC', $
              'MPC', 'GBO', 'C2D', 'C4D', 'TBC', 'RD1', 'ORO', $
              'ORI', 'LWK', 'MTL', 'MSH', 'SCI']
; Check to see if ROI data is loaded, otherwise the options call will
; generate a diagnostic
tn_roi=tnames('th?_state_roi')
if (n_elements(tn_roi) GT 1) OR ((n_elements(tn_roi) EQ 1) AND (tn_roi[0] NE '')) then begin
   options, 'th?_state_roi', tplot_routine = 'bitplot', colors = 'rbgmc', labels = roi_labels, $
      yrange = [-1, 26], /ystyle
end

;delete any support data that was loaded for coordinate transformation
if(keyword_set(coord) && tn_before[0] ne '' && tn_after[0] ne '') then begin
    to_delete = ssl_set_complement(tn_before,tn_after)
    if(size(to_delete,/n_dim) ne 0 || to_delete[0] ne -1L) then $
      del_data,to_delete
endif


end

pro thm_load_state,probe=probe, datatype=datatype, trange=trange, $
                   level=level, verbose=verbose, downloadonly=downloadonly,$
                   relpathnames_all=relpathnames_all, no_download=no_download,$
                   cdf_data=cdf_data,get_support_data=get_support_data, $
                   varnames=varnames, valid_names = valid_names, files=files, $
                   version=version, suffix=suffix, progobj=progobj,coord=coord, $
                   no_spin=no_spin, keep_spin_data=keep_spin_data, $
                   no_update=no_update

;defining constants
;probe names
  p_names = 'a b c d e'

;datatype names
  d_names = 'pos pos_gse pos_gsm pos_sse pos_sel vel vel_gse ' + $
            'vel_gsm vel_sse vel_sel man roi spinras spindec ' + $
            'spinalpha spinbeta spinper spinphase ' + $
            'spin_spinper spin_time spin_tend spin_c spin_phaserr spin_nspins ' + $
            'spin_npts spin_maxgap spin_correction spin_initial_delta_phi spin_idpu_spinper ' + $
            'spin_segflags spin_fgm_corr_time spin_fgm_corr_tend spin_fgm_corr_offset ' + $
            'spinras_correction spindec_correction ' + $
            'spin_ecl_spinper spin_ecl_time spin_ecl_tend spin_ecl_c spin_ecl_phaserr spin_ecl_nspins spin_ecl_npts ' + $
            'spin_ecl_maxgap spin_ecl_initial_delta_phi spin_ecl_idpu_spinper spin_ecl_segflags spin_ecl_fgm_corr_time spin_ecl_fgm_corr_tend spin_ecl_fgm_corr_offset'

;coordinate names(should have same number of elements as d_names
;because they are in a 1-1 correspondence)
  c_names = 'gei gse gsm sse sel gei gse ' + $
            'gsm sse sel unknown unknown gei gei ' + $
            'spg spg unknown unknown ' + $
            'unknown unknown unknown unknown unknown unknown ' + $
            'unknown unknown unknown unknown unknown ' + $
            'unknown unknown unknown unknown ' + $
            'gei gei ' + $
            'unknown unknown unknown unknown unknown unknown unknown ' + $
            'unknown unknown unknown unknown unknown unknown unknown' 
  
;units for each d_name
  u_names = 'km km km km km km/s km/s ' + $
            'km/s km/s km/s unknown unknown deg deg ' + $
            'deg deg sec deg ' + $
            'sec sec sec deg/sec^2 sec spins ' + $
            'points sec deg deg sec ' + $
            'unknown sec sec deg ' + $
            'deg deg ' + $
            'sec sec sec deg/sec^2 sec spins points ' + $
            'sec deg sec unknown sec sec deg'


; Support variables.  We need an explicit list of support variables here,
; rather than the usual behavior of adding the implicit wildcard '*'
; to the variable list when /get_support_data is specified. thm_load_state
; uses the /no_explicit_wildcard option when it calls thm_load_xxx,
; so we only get what we explicitly ask for.

  supp_names = 'man roi ' + $
               'spinras spindec spinalpha spinbeta spinper spinphase ' + $
               'spin_spinper spin_time spin_tend spin_c spin_phaserr ' + $
               'spin_nspins spin_npts spin_maxgap spin_correction ' + $
               'spin_initial_delta_phi spin_idpu_spinper spin_segflags spinras_correction spindec_correction ' + $
               'spin_fgm_corr_time spin_fgm_corr_tend spin_fgm_corr_offset ' + $
               'spin_ecl_spinper spin_ecl_time spin_ecl_tend spin_ecl_c ' + $
               'spin_ecl_phaserr spin_ecl_nspins spin_ecl_npts spin_ecl_maxgap ' + $
               'spin_ecl_initial_delta_phi spin_ecl_idpu_spinper spin_ecl_segflags ' + $
               'spin_ecl_fgm_corr_time spin_ecl_fgm_corr_tend spin_ecl_fgm_corr_offset'


  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end

  if not keyword_set(version) then begin
     version=''
  endif

  vversions='v00 v01 v02 v03'
  if not keyword_set(valid_names) then begin
     vers = thm_valid_input(version,'Version',vinputs=vversions, $
                            definput='v01', format="('v', I02)", $
                            verbose=verbose,no_download=no_download)
     if vers eq '' then return
  endif
;  probe_colors = ['m','b','c','g','r','y']

  ;; default datatypes to load are just pos and vel if get_support_data not set
  if not keyword_set(datatype) then begin
     if not keyword_set(get_support_data) then datatype = 'pos vel'
  endif else begin
     ; We want to support 'pseudo-datatypes' spinras_corrected and
     ; spindec_corrected, mainly for the sake of the GUI.  If present,
     ; they're removed from the datatype list (to prevent thm_load_xxx
     ; from trying to load them from the CDF), and spin{ras,dec}
     ; and spin{ras,dec}_corrected are added to the list.  So
     ; by the time the post-processing is done, the dependencies
     ; exist and the spin{ras_dec}_corrected variables get created.

     if (size(datatype,/n_dim) EQ 0) then begin
        datatype_arr = strsplit(strlowcase(datatype),' ',/extract)
     endif else begin
        datatype_arr = strlowcase(datatype)
     endelse
     ; Now datatype_arr is an array of lowcased datatype strings.
     ; Does it contain spinras_corrected?
     ras_corrected_ind = where(strmatch(datatype_arr,'spinras_corrected'),mcount)
     if (mcount NE 0) then begin
        datatype_arr[ras_corrected_ind] = 'spinras'
        datatype_arr = [datatype_arr,'spinras_correction']
     endif
     ; datatype_arr now has all instances of spinras_corrected replaced
     ; with 'spinras', and 'spinras_correction' has been appended.

     ; repeat for spindec_correction
     dec_corrected_ind = where(strmatch(datatype_arr,'spindec_corrected'),mcount)
     if (mcount NE 0) then begin
        datatype_arr[dec_corrected_ind] = 'spindec'
        datatype_arr = [datatype_arr,'spindec_correction']
     endif

     ; Now convert datatype_arr back to a space-delimited string.
     datatype = strjoin(datatype_arr,' ') 
     if keyword_set(get_support_data) then begin
        ; Append support variable names
        datatype = datatype + ' ' + supp_names;
     endif
  endelse

  thm_load_xxx,sname=probe, datatype=datatype, trange=trange, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               relpathnames_all=relpathnames_all, no_download=no_download, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, no_update=no_update, $
               varnames=varnames, valid_names = valid_names, files=files, $
               vsnames = p_names, $
               type_sname = 'probe', $
               vdatatypes = d_names, $
               file_vdatatypes = 'state', $
               midfix = 'state_', $
               vlevels = 'l1', $
               deflevel = 'l1', $
               version = version, $ 
               suffix=suffix, $
               post_process_proc = 'thm_load_state_post', $
               progobj = progobj, $
               c_names = strsplit(c_names,' ',/extract), $ ; tricky inheritance to get names to
               d_names = strsplit(d_names,' ',/extract), $ ; the post process proc
               u_names = strsplit(u_names,' ',/extract), $
               no_spin = no_spin, $
               keep_spin_data = keep_spin_data, $
               coord=coord, $
               /no_time_clip , $
               /no_implicit_wildcard, $
               relpath_funct ='thm_load_state_relpath', $
               msg_out=msg_out, $
               _extra = _extra


  if keyword_set(valid_names) then  begin
     version = vversions
     dprint,  $
                string(strjoin(strsplit(vversions, ' ', /extract), ','), $
                       format = '( "Valid versions:",X,A,".")')
  endif

  ;print accumulated error messages now that loading is complete
  if keyword_set(msg_out) then begin
    for i=0, n_elements(msg_out)-1 do begin
      if msg_out[i] ne '' then dprint, dlevel=1, msg_out[i]
    endfor
  endif

end
