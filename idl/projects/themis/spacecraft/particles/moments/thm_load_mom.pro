;+
;Procedure: THM_LOAD_MOM
;
;Purpose:  Loads THEMIS moments data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type(s) of data to be loaded.  May be single string of 
;             space-separate elements.  All data will be loaded if not set.
;
;             For level 1 this can specify type and specific quantity.
;               e.g.  'psim', 'flags', 'ptem_density', 'pxxm_pot'
;               
;             For level 2 it must specify a specific variable.
;               e.g.  'peim_flux', 'ptem_velocity_dsl'
;                
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  coord = (optional) String denoting coordinates system to transform 
;          valid 3-vectors into (e.g. 'gsm').
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named variable for output of pathnames of local files.
;          WARNING: performing operations on the file paths returned by this
;          keyword will break abstraction.  This can decrease the maintainability
;          of code based upon thm_load_mom.
;  /VERBOSE  set to output some useful info
;  raw     if set, then load raw data, without calibrating
;  type    added for compatibility with other THM_LOAD routines, if
;          set to 'raw', then load raw data with no calibration,
;          otherwise the default is to load calibrated data.
;  /NO_TIME_CLIP: Disables time clipping, which is the default
;  /dead_time_correct: If set, then calculate dead time correction
;                      based on ESA moments
;  /return_mag_rmat: If set, return a tplot variable (ntimes, 3, 3)
;                    for the rotation matrix used to rotate
;                    to field-aligned "_mag" variables. Note that this
;                    matrix needs to be inverted to be used correctly
;                    with TVECTOR_ROTATE, as here it is used with 
;                    velocity as a column vector.
;Example:
;   thm_load_mom,/get_suppport_data,probe=['a', 'b']
;Notes:
;  Written by Davin Larson Jan 2007.
;  Updated keywords KRB Feb 2007
;  If you aren't getting data and can't figure out why try
;  increasing your debug output level using:
;  'dprint,setdebug=3'
;  
;  New calibrations for ESA moments solar wind mode and non-solar wind
;  mode added Jul 23,2010 by pcruce (under Jim McFadden's direction.)
;  Detailed descriptions of methods in code.  These updated calibrations correct
;  most of the discrepancy between ground and on-board moments.
;  Some uncorrectable difference remains because on-board calculations
;  don't account for variation in energy sweep, different spacecraft
;  potential, and efficiency.
;
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-04-26 15:25:09 -0700 (Fri, 26 Apr 2019) $
; $LastChangedRevision: 27102 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_load_mom.pro $
;-

pro thm_clip_moment, tplotnames=tplotnames, trange=trange

    compile_opt idl2, hidden

  if undefined(tplotnames) then return

  ;ensure time range is set
  tr = timerange(trange) 
  
  ;clip specified new/altered variables
  ;loop here instead of in time_clip so that out-of-range vars can be deleted
  for i=0, n_elements(tplotnames)-1 do begin
    time_clip, tplotnames[i], min(tr), max(tr), /replace, error=tr_err
    if tr_err then del_data, tplotnames[i]
  endfor

end


;Helper function to perform coordinate transforms on valid moments data
pro thm_transform_moment, coord, tplotnames, $
                          probe=probe, trange=trange, state_loaded=state_loaded

    compile_opt idl2, hidden


  valid = where( stregex( tplotnames, '(flux|eflux|velocity)', /bool), n)

  if n gt 0 then begin

    ;load state data
    if ~keyword_set(state_loaded) then begin
      thm_load_state, probe=probe, /get_support_data, trange=trange
      state_loaded = 1b
    endif

    cotrans_names = tplotnames[valid]
    thm_cotrans, cotrans_names, out_coord = coord, $
                 use_spinaxis_correction=1, use_spinphase_correction=1

  endif

end



pro thm_store_moment,time,dens,flux,mflux,eflux,mag,prefix = prefix, suffix=sfx,mass=mass, $
        raw=raw, quantity=quantity, tplotnames=tplotnames, $
        probe=probe,use_eclipse_corrections=use_eclipse_corrections, $
        return_mag_rmat = return_mag_rmat

    compile_opt idl2, hidden

if use_eclipse_corrections GT 0 then begin
   ; Rotate vector quantities from pseudo-DSL (which drifts during eclipses) 
   ; to true DSL
                     
   ; Make sure spin model data is loaded.
;   thm_autoload_spinmodel,probe=probe,trange=minmax(time)
   thm_autoload_support, probe_in=probe, trange=minmax(time), /spinmodel, /spinaxis 

   ; Retrieve eclipse delta_phi values
    smp=spinmodel_get_ptr(probe,use_eclipse_corrections=use_eclipse_corrections)
    spinmodel_interp_t,model=smp,time=time,eclipse_delta_phi=delta_phi

    edp_idx=where(delta_phi NE 0.0, edp_count)
    if (edp_count NE 0) then begin
       dprint,"Nonzero eclipse delta_phi corrections found."
       correct_delta_phi_vector,delta_phi=delta_phi,xyz_in=flux 
       correct_delta_phi_vector,delta_phi=delta_phi,xyz_in=eflux 
       correct_delta_phi_tensor,tens=mflux,delta_phi=delta_phi
    endif
endif

;if no specific datatypes were requested then store all
if in_set(quantity, '') then quantity = '*'

for j=0,n_elements(quantity)-1 do begin
  
  case quantity[j] of
    'density': begin
      store_data,prefix+'density'+sfx, data={x:time, y:dens}, dlim={ysubtitle:'[#/cm3]',data_att:{units:'#/cm3'}}
      tplotnames = array_concat(prefix+'density'+sfx,tplotnames)
    end
    'flux': begin
      store_data,prefix+'flux'+sfx, data={x:time, y:flux}, dlim={colors:'bgr',ysubtitle:'[#/cm2/s]',data_att:{units:'#/cm2/s',coord_sys:'dsl'}}
      tplotnames = array_concat(prefix+'flux'+sfx,tplotnames)
    end
    'mftens': begin 
      store_data,prefix+'mftens'+sfx, data={x:time, y:mflux},dlim={colors:'bgrmcy',ysubtitle:'[eV/cm3]',data_att:{units:'eV/cm3',coord_sys:'dsl'}}
      tplotnames = array_concat(prefix+'mftens'+sfx,tplotnames)
    end
    'eflux': begin
      store_data,prefix+'eflux'+sfx, data={x:time, y:eflux}  ,dlim={colors:'bgr',ysubtitle:'[eV/cm2/s]',data_att:{units:'eV/cm2/s',coord_sys:'dsl'}}
      tplotnames = array_concat(prefix+'eflux'+sfx,tplotnames)
    end
    '*': begin
      store_data,prefix+'density'+sfx, data={x:time, y:dens}, dlim={ysubtitle:'[#/cm3]',data_att:{units:'#/cm3'}}
      store_data,prefix+'flux'+sfx, data={x:time, y:flux}     ,dlim={colors:'bgr',ysubtitle:'[#/s/cm2]',data_att:{units:'#/s/cm2',coord_sys:'dsl'}}
      store_data,prefix+'mftens'+sfx, data={x:time, y:mflux},dlim={colors:'bgrmcy',ysubtitle:'[eV/cm3]',data_att:{units:'eV/cm3',coord_sys:'dsl'}}
      store_data,prefix+'eflux'+sfx, data={x:time, y:eflux}  ,dlim={colors:'bgr',ysubtitle:'[eV/cm2/s]',data_att:{units:'eV/cm2/s',coord_sys:'dsl'}}
      tplotnames = array_concat(prefix+['density','flux','mftens','eflux']+sfx,tplotnames)
    end
    else:
  endcase
  
  if not keyword_set(raw) then begin

    vel = flux/[dens,dens,dens]/1e5
    if quantity[j] eq 'velocity' || quantity[j] eq '*' then begin
      store_data,prefix+'velocity'+sfx, data={x:time,  y:vel }, $
        dlim={colors:'bgrmcy',labels:['Vx','Vy','Vz'],ysubtitle:'[km/s]',data_att:{coord_sys:'dsl'}}
      tplotnames = array_concat(prefix+'velocity'+sfx,tplotnames)
    endif
    
    pressure = mflux
    pressure[*,0] -=  mass * flux[*,0]*flux[*,0]/dens/1e10
    pressure[*,1] -=  mass * flux[*,1]*flux[*,1]/dens/1e10
    pressure[*,2] -=  mass * flux[*,2]*flux[*,2]/dens/1e5/1e5
    pressure[*,3] -=  mass * flux[*,0]*flux[*,1]/dens/1e5/1e5
    pressure[*,4] -=  mass * flux[*,0]*flux[*,2]/dens/1e5/1e5
    pressure[*,5] -=  mass * flux[*,1]*flux[*,2]/dens/1e5/1e5

    if quantity[j] eq 'ptens' || quantity[j] eq '*' then begin
      press_labels=['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz']
      store_data,prefix+'ptens'+sfx, data={x:time, y:pressure }, $
        dlim={colors:'bgrmcy',labels:press_labels,constant:0.,ysubtitle:'[eV/cc]'}
      tplotnames = array_concat(prefix+'ptens'+sfx,tplotnames)
;      store_data,prefix+'t3'+sfx,data={x:time,y:pressure[*,0:2]/[dens,dens,dens]},$
;                 dlim={colors:'bgrmcy',labels:['Tx','Ty','Tz'],ysubtitle:'[eV]',data_att:{units:'eV'}}
;      tplotnames = array_concat(prefix+'t3'+sfx,tplotnames)
    endif

    ptot = total(pressure[*,0:2],2)/3
    if quantity[j] eq 'ptot' || quantity[j] eq '*' then begin
      store_data,prefix+'ptot'+sfx, data={x:time, y:ptot } ;,dlim={colors:'bgrmcy',labels:press_labels}
      tplotnames = array_concat(prefix+'ptot'+sfx,tplotnames)
    endif
  endif
  if keyword_set(mag) then begin
     map3x3 = [[0,3,4],[3,1,5],[4,5,2]]
     mapt   = [0,4,8,1,2,5]
     n = n_elements(time)
     ptens_mag = fltarr(n,6)
     mftens_mag = fltarr(n,6)
     vel_mag   = fltarr(n,3)
     vxz = [1,0,0.]
     If(keyword_set(return_mag_rmat)) Then rmat = fltarr(n, 3, 3)
     for i=0L,n-1 do begin   ; this could easily be speeded up, but it's fast enough now.
;         vxz = reform(flux[i,*])
         rot = rot_mat(reform(mag[i,*]),vxz)
         If(keyword_set(return_mag_rmat)) Then rmat[i, *, *] = rot
         pt = reform(pressure[i,map3x3],3,3)
         magpt3x3 = invert(rot) # (pt # rot)
         ptens_mag[i,*] = magpt3x3[mapt]
         mt = reform(mflux[i,map3x3],3,3)
         magmt3x3 = invert(rot) # (mt # rot)
         mftens_mag[i,*] = magmt3x3[mapt]
         vm = reform(vel[i,*]) # rot
         vel_mag[i,*] = vm
     endfor
     store_data,prefix+'velocity_mag'+sfx,data={x:time,y:vel_mag} ,dlim={colors:'bgr',labels:['Vperp1','Vperp2','Vpar'],ysubtitle:'[km/s]',data_att:{units:'km/s',coord_sys:'mfa'}}
     store_data,prefix+'ptens_mag'+sfx,data={x:time,y:ptens_mag},dlim={colors:'bgrmcy',labels:['Pperp1','Pperp2','Ppar','','',''],ysubtitle:'[eV/cc]',data_att:{units:'eV/cm3'}}
     store_data,prefix+'mftens_mag'+sfx,data={x:time,y:mftens_mag},dlim={colors:'bgrmcy',labels:['MFperp1','MFperp2','MFpar','','',''],ysubtitle:'[eV/cc]',data_att:{units:'eV/cm3'}}
     store_data,prefix+'t3_mag'+sfx,data={x:time,y:ptens_mag[*,0:2]/[dens,dens,dens]},dlim={colors:'bgrmcy',labels:['Tperp1','Tperp2','Tpar'],ysubtitle:'[eV]',data_att:{units:'eV'}}
     store_data,prefix+'mag'+sfx,data={x:time,y:mag},dlim={colors:'bgr',ysubtitle:'[nT]'}
     tplotnames = array_concat(prefix+['velocity_mag','ptens_mag','mftens_mag','t3_mag','mag']+sfx,tplotnames)
     If(keyword_set(return_mag_rmat)) Then Begin
        store_data,prefix+'rmat'+sfx,data={x:time,y:rmat}
        tplotnames = array_concat(prefix+'rmat'+sfx,tplotnames)
     Endif

  endif

endfor ; loop over quantity

end

pro thm_load_mom_cal_array,time,momraw,scpotraw,qf,shft,$
  iesa_sweep, iesa_sweep_time, eesa_sweep, eesa_sweep_time, $ ;added sweep variables, 1-mar-2010, jmm
  iesa_solarwind_flag, eesa_solarwind_flag, $                 ;solarwind_flag variables don't have the same time array as sweep, 26-jul-2010
  iesa_config, iesa_config_time,eesa_config, eesa_config_time, $
  isst_config, isst_config_time,esst_config, esst_config_time, $
  iesa_solarwind_time, eesa_solarwind_time, $
  probe=probe,caldata=caldata, coord=coord, $
  verbose=verbose,raw=raw,comptest=comptest, datatype=datatype, $
  use_eclipse_corrections=use_eclipse_corrections, suffix = suffix, $
  tplotnames=tplotnames,return_mag_rmat=return_mag_rmat

  compile_opt idl2, hidden

  ;each instrument has its own cal file,23-jul-2009
  ;reverted to pre-July 2009 version to avoid conflicts with
  ;thm_load_esa_pot routine, which also makes a correction, jmm,
  ;2010-02-08.
  ;2010-06-23 Now uses new file that contains updated corrections and solar wind mode corrections, pcruce
;Uses text calibration file instead of IDL save file,jmm,4-oct-2010
  caldata = thm_read_mom_cal_file(cal_file = cal_file,probe=probe)
  dprint,dlevel=2,verbose=!themis.verbose,'THEMIS moment calibration file: ',cal_file
  dprint,dlevel=4,verbose=!themis.verbose,caldata,phelp=3
  dprint,dlevel=3,phelp=3,qf
  dprint,dlevel=3,phelp=3,shft
  
  if keyword_set(raw) then begin
     sfx='_raw'
     caldata.mom_scale = 1.
     caldata.scpot_scale[*] = 1.
   endif else if(keyword_set(suffix)) then begin ;jmm, 9-aug-2011
    sfx = suffix
  endif else sfx = ''
  if keyword_set(comptest) then begin
     sfx+='_cmptest'
  ;   momraw = momraw / 2l^16
  ;   momraw = momraw * 2l^16
     momraw = momraw and 'ffff0000'xl
     momraw = momraw or  '00008000'xl
  endif
  
  one = replicate(1.d,n_elements(time))
  bad = where((qf and 'c'x) ne 0,nbad)
  if nbad gt 0 then one[bad] = !values.f_nan

  nt = n_elements(time)
  thx = 'th'+probe
  instrs= 'p'+['ei','ee','si','se'] +'m'
;  sh = shft
  me = 510998.918d/299792d^2
  mi = 1836*me
  mass=[mi,me,mi,me]
  s2_cluge = [3,0,3,0]
  totmom_flag = 1 &&  ~keyword_set(raw)
  if keyword_set(totmom_flag) then begin
    n_e_tot = 0
    nv_e_tot = 0
    nvv_e_tot = 0
    nvvv_e_tot = 0
    n_i_tot = 0
    nv_i_tot = 0
    nvv_i_tot = 0
    nvvv_i_tot = 0
  endif

  ;get any subquantities from the datatype
  ;it would be preferable for the helper routines to worry about this
  quantities = stregex( datatype, '[^_]+_(.*)', /subexpr, /extract)
  quantities = reform(quantities[1,*])

  ; get mag data at same time steps
  mag = data_cut(thx+'_fgs',time)  ; Note:  'thx_fgs' must be in spacecraft coordinates!
  if(n_elements(mag) eq 1 && mag[0] eq 0) then mag = data_cut(thx+'_fgs_dsl',time) ;allow L2 fgs data

  ;reform calibration parameters so that it is easy to switch between solar-wind and non-solar wind mode using vectorized calculations.
  cal_params = dblarr([dimen(caldata.mom_scale),2])
  cal_params[*,*,0] = caldata.mom_scale
  cal_params[*,*,1] = caldata.mom_scale_sw1
  
  ;loop over p[es][ie]m datatypes
  for i=0,3 do begin
;       s2 = sh and 7
;       sh = sh / 16
        
       ;truncation and shift based compression is used on-board.  Bitpacked values in the shft variable indicate how much
       ;shift needs to be applied to each moment type (iESA,eESA,iSST,eSST)
       ;each shift field is 3 bits, indicating a shift of 1-8 bits.  
       ;bits 2-0 = eSST shift
       ;bits 6-4 = iSST shift
       ;bits 10-8 = eESA shift
       ;bits 14-12 = iESA shift
       
    ;This unpacks the shift field.
    s2 = ishft(shft,(i-3)*4) and 7
            
    instr = instrs[i]     
    ion = (i and 1) eq 0

    if (i eq 2) || (i eq 3) then begin   ; Special treatment for SST attenuators
     
      geom = replicate(!values.f_nan,n_elements(time))
      geom[*] = 1.
      w_open = where( (qf and '0f00'x) eq '0A00'x , nw_open )       
      if nw_open gt 0 then geom[w_open] = 1.
      
      w_clsd = where( (qf and '0f00'x) eq '0500'x , nw_clsd )
      ;if nw_clsd gt 0 then geom[w_clsd] = 1/128. ;old code
      ;changing attenuator factor to 1/64.
      if nw_clsd gt 0 then geom[w_clsd] = 1./64 ;new code

      ;Note, one attenuator on themis D broke during early April and was in ambiguous state for ~3 months.  Data during this interval is treated as missing.
      if (nw_open + nw_clsd) ne n_elements(geom) then begin
        dprint,'Attenuator flags are ambiguous for ' + strtrim(n_elements(geom) - nw_open - nw_clsd,2) + ' samples.'
      endif
  
    endif else begin
      esa_cal = get_thm_esa_cal(time= time,sc=probe,ion=ion)
      geom= esa_cal.rel_gf * esa_cal.geom_factor / 0.00153000 * 1.5  ; 1.5 fudge factor
    endelse
    
;       s2=s2_cluge[i]
;       s2 = 0
    if keyword_set(raw) then s2=0
    dprint,dlevel=3,instrs[i],'  shift=',s2[0]
       
       ;caldata.mom_scale factors for ESA determined by comparing data to ground processed moments when not in solar wind mode.
       ;Note that efficiency, dead time, and energy sweep variation corrections are only performed on ground.
       ;Also a different spacecraft potential will be used.
       ;This means there will be some discrepancy between on-board and ground based moments that is unresolved with this model.
       ;To determine these factors, ground corrections that are not done on-board were turned off, and on-board sc_pot was used. 
       ;The dates were determined by comparing moments from plasma sheath with the following dates/probes:
       ;THB 2008-11-30/00:00:00 16 hours 
       ;THB 2008-12-02/04:00:00 20 hours 
       ;THB 2008-12-06/00:00:00 24 hours 
       ;THB 2008-12-10/08:00:00 16 hours 
       ;THB 2009-04-10/04:00:00 20 hours
       ;THB 2009-04-22/00:00:00 24 hours (Note that the peem component contains uncorrectable digitization on this day that make fit for this component invalid.) 
       ;THB 2009-04-25/00:00:00 24 hours 
       ;THC 2007-11-25/02:00:00 16 hours 
       ;THC 2008-11-26/08:00:00 16 hours (Note this date contains a few large glitches(spikes) that need to be removed before you can get a good fit)
       ;THC 2008-11-28/08:00:00 16 hours
       
       ;Efficiency corrections cause larger discrepancies in ions than electrons.  These can be as large as 5% at high ion velocities(400 km/s)
       
       ;caldata.mom_scale_sw1 factors for ESA determined by comparing data to ground processed moments when in solar wind mode.
       ;As above, ground-only corrections were turned off, and on-board scpot was used.
       ;Also,note that electron eflux results can be erratic because of intermittent digitization error.
       ;Dates used follow:
       ;THB 2008-08-11/00:00:00 24 hours   
       ;THB 2008-08-14/00:00:00 24 hours
       ;THB 2008-08-15/00:00:00 24 hours
       ;THB 2008-08-18/00:00:00 24 hours
       ;THB 2008-08-19/00:00:00 24 hours
      
    ;select appropriate parameters for solarwind/non-solar wind if correct inputs available, default is to use only non-solar wind parameters
    if i eq 0 && ptr_valid(iesa_solarwind_flag) && ptr_valid(iesa_solarwind_time) then begin 
      ;times don't always match exactly.  This interpolates to matching time grids.  Flag is boolean, so intermediate values are rounded.
      sw_flags = 0 > round(interpol(*iesa_solarwind_flag,*iesa_solarwind_time,time)) < 1
    endif else if i eq 1 && ptr_valid(eesa_solarwind_flag) && ptr_valid(eesa_solarwind_time) then begin
      ;same intepolation as above, but for electrons
      sw_flags = 0 > round(interpol(*eesa_solarwind_flag,*eesa_solarwind_time,time)) < 1
    endif else begin
      sw_flags = dblarr((dimen(momraw))[0])
    endelse

    dens  = ulong(momraw[*,0,i]) * cal_params[0,i,sw_flags] * one * 2.^s2 / geom
    flux = fltarr(nt,3)
    for m = 0,2 do flux[*,m] = momraw[*,1+m,i]  * cal_params[1+m,i,sw_flags] * one * 2.^s2 / geom ;* 1e5
    mflux = fltarr(nt,6)
    for m = 0,5 do mflux[*,m] = momraw[*,4+m,i]  * cal_params[4+m,i,sw_flags] * one * 2.^s2  /geom  ; * 1e2; * mass[i]
    eflux = fltarr(nt,3)
      
    ;1e5 is unit conversion from (eV/cm^2)*(km/sec) to eV/cm2/sec
    for m = 0,2 do eflux[*,m] = momraw[*,10+m,i]  * cal_params[10+m,i,sw_flags] * one * 2.^s2  /geom * 1e5; * 1e1 ; * mass[i]   
     
    if not keyword_set(raw) then begin
      if keyword_set(totmom_flag) then begin
        if i and 1 eq 1 then begin   ; electrons
          n_e_tot     += dens
          nv_e_tot    += flux
          nvv_e_tot   += mflux
          nvvv_e_tot  += eflux
        endif else begin             ; ions
          n_i_tot     += dens
          nv_i_tot    += flux
          nvv_i_tot   += mflux
          nvvv_i_tot  += eflux
        endelse
      endif
;          press_labels=['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz']
;          store_data,thx+'_'+instr+'_velocity'+sfx, data={x:time,  y:flux/[dens,dens,dens]/1e5 } ,dlim={colors:'bgrmcy',labels:['Vx','Vy','Vz'],ysubtitle:'km/s'}
;               pressure = mflux
;               pressure[*,0] -=  mass[i] * flux[*,0]*flux[*,0]/dens/1e10
;               pressure[*,1] -=  mass[i] * flux[*,1]*flux[*,1]/dens/1e10
;               pressure[*,2] -=  mass[i] * flux[*,2]*flux[*,2]/dens/1e5/1e5
;               pressure[*,3] -=  mass[i] * flux[*,0]*flux[*,1]/dens/1e5/1e5
;               pressure[*,4] -=  mass[i] * flux[*,0]*flux[*,2]/dens/1e5/1e5
;               pressure[*,5] -=  mass[i] * flux[*,1]*flux[*,2]/dens/1e5 /1e5
;          store_data,thx+'_'+instr+'_press'+sfx, data =    {x:time,  y:pressure } ,dlim={colors:'bgrmcy',labels:press_labels}
    endif

    ;check if current datatype is requested, continue if not
    idx = where( stregex(datatype,'('+instr+'|\*)',/bool), n)
    if n eq 0 then continue

    ;store variables for this data type
    thm_store_moment,time,dens,flux,mflux,eflux,mag,prefix = thx+'_'+instr+'_', $
      suffix=sfx,mass=mass[i],raw=raw, quantity=quantities[idx], tplotnames=tplotnames, $
      probe=probe, use_eclipse_corrections=use_eclipse_corrections,return_mag_rmat=return_mag_rmat
  endfor
    
    
  ;store pt?m variables
  if not keyword_set(raw) && totmom_flag then begin
     
    idx = where( stregex(datatype,'(ptim|\*)',/bool), n)
    if n gt 0 then begin
      thm_store_moment,time,n_i_tot,nv_i_tot,nvv_i_tot,nvvv_i_tot,mag,$
        prefix = thx+'_'+'ptim_', suffix=sfx,mass=mass[0],raw=raw, quantity=quantities[idx],$
        probe=probe, use_eclipse_corrections=use_eclipse_corrections, $
        tplotnames=tplotnames,return_mag_rmat=return_mag_rmat
          
    endif
     
    idx = where( stregex(datatype,'(ptem|\*)',/bool), n)
    if n gt 0 then begin
      thm_store_moment,time,n_e_tot,nv_e_tot,nvv_e_tot,nvvv_e_tot,mag,$
        prefix = thx+'_'+'ptem_', suffix=sfx,mass=mass[1],raw=raw, quantity=quantities[idx],$
        probe=probe, use_eclipse_corrections=use_eclipse_corrections, $
        tplotnames=tplotnames,return_mag_rmat=return_mag_rmat
    endif

  endif


  ;time-dependent scpot scaling, jmm, 23-jul-2009,was removed on 8-feb-2010, jmm
  
  ;now uses fixed scpot scaling
  scpot = scpotraw*caldata.scpot_scale


  ;store pxxm variables
  idx = where(  stregex(datatype,'(pxxm|\*)',/bool), n)
  if n gt 0 then begin
    
    quantity = quantities[idx]
    if in_set(quantity, '') then quantity = '*'
    
    if total( stregex(quantity,'(pot|\*)',/bool) ) gt 0 then begin
      store_data,thx+'_pxxm_pot'+sfx,data={x:time,  y:scpot },dlimit={ysubtitle:'[Volts]'}
      tplotnames = array_concat(thx+'_pxxm_pot'+sfx,tplotnames)
    endif
    if total( stregex(quantity,'(qf|\*)',/bool) ) gt 0 then begin
      store_data,thx+'_pxxm_qf'+sfx,data={x:time, y:qf}, dlimit={tplot_routine:'bitplot'}
      tplotnames = array_concat(thx+'_pxxm_qf'+sfx,tplotnames)
    endif
    if total( stregex(quantity,'(shft|\*)',/bool) ) gt 0 then begin
      store_data,thx+'_pxxm_shft'+sfx,data={x:time, y:shft}, dlimit={tplot_routine:'bitplot'}
      tplotnames = array_concat(thx+'_pxxm_shft'+sfx,tplotnames)
    endif
    
  endif


  ;store flags
  if total( stregex(datatype, '(flags|\*)', /bool) ) gt 0 then begin
    
    ;ESA sweep mode variables, 1-mar-2010, jmm
    if(ptr_valid(iesa_sweep) && ptr_valid(iesa_sweep_time)) then begin
      store_data, thx+'_iesa_sweep'+sfx, data = {x:*iesa_sweep_time, y:*iesa_sweep}, dlimit={tplot_routine:'bitplot'}
      tplotnames = array_concat(thx+'_iesa_sweep'+sfx,tplotnames)
    endif
    if(ptr_valid(eesa_sweep) && ptr_valid(eesa_sweep_time)) then begin
      store_data, thx+'_eesa_sweep'+sfx, data = {x:*eesa_sweep_time, y:*eesa_sweep}, dlimit={tplot_routine:'bitplot'}
      tplotnames = array_concat(thx+'_eesa_sweep'+sfx,tplotnames)
    endif

    ;ESA solar wind mode variables, 1-mar-2010, jmm
    if(ptr_valid(iesa_solarwind_flag) && ptr_valid(iesa_solarwind_time)) then begin
      store_data, thx+'_iesa_solarwind_flag'+sfx, data = {x:*iesa_solarwind_time, y:*iesa_solarwind_flag}
      tplotnames = array_concat(thx+'_iesa_solarwind_flag'+sfx,tplotnames)
    endif
    if(ptr_valid(eesa_solarwind_flag) && ptr_valid(eesa_solarwind_time)) then begin
      store_data, thx+'_eesa_solarwind_flag'+sfx, data = {x:*eesa_solarwind_time, y:*eesa_solarwind_flag}
      tplotnames = array_concat(thx+'_eesa_solarwind_flag'+sfx,tplotnames)
    endif

    ;ESA configuration
    if(ptr_valid(iesa_config) && ptr_valid(iesa_config_time)) then begin
      store_data, thx+'_iesa_config'+sfx, data = {x:*iesa_config_time, y:*iesa_config}
      tplotnames = array_concat( thx+'_iesa_config'+sfx,tplotnames)
    endif
    if(ptr_valid(eesa_config) && ptr_valid(eesa_config_time)) then begin
      store_data, thx+'_eesa_config'+sfx, data = {x:*eesa_config_time, y:*eesa_config}
      tplotnames = array_concat(thx+'_eesa_config'+sfx,tplotnames)
    endif
    
    ;SST configuration
    if(ptr_valid(isst_config) && ptr_valid(isst_config_time)) then begin
      store_data, thx+'_isst_config'+sfx, data = {x:*isst_config_time, y:*isst_config}
      tplotnames = array_concat(thx+'_isst_config'+sfx,tplotnames)
    endif
    if(ptr_valid(esst_config) && ptr_valid(esst_config_time)) then begin
      store_data, thx+'_esst_config'+sfx, data = {x:*esst_config_time, y:*esst_config}
      tplotnames = array_concat(thx+'_esst_config'+sfx,tplotnames)
    endif
  endif
  
  
  ;transform 3-vectors if requested
  if is_string(coord) then begin
    thm_transform_moment, coord, tplotnames, $
                          probe=probe, trange=trange, $
                          state_loaded=state_loaded
  endif
      
end


; this appears not to be in use  (aaf 2014-05-21)
;;+
;; Themis moment calibration routine.
;; Author: Davin Larson
;;-
;pro thm_load_mom_cal,probes=probes, create=create, verbose=verbose
;
;if not keyword_set(probes) then probes = ['a','b','c','d','e']
;
;for s=0,n_elements(probes)-1 do begin
;  thx = 'th'+probes(s)
;  get_data,thx+'_mom_raw',ptr=p
;  get_data,thx+'_mom_pot_raw',ptr=pot
;  get_data,thx+'_mom_qf_raw',ptr
;
;  if keyword_set(p) then begin
;    thm_load_mom_cal_array,*p.x,*p.y,0 ,probe=probe
;
;    dprint,dlevel=4,'Finished with cal on '+thx
;  endif
;
;
;endfor
;
;
;end


pro thm_load_mom, probe = probe, datatype = datatype_in, trange = trange, all = all, $
                  level = level, verbose = verbose, downloadonly = downloadonly, $
                  varnames = varnames, valid_names = valid_names, raw = raw, $
                  comptest = comptest, suffix = suffix, coord = coord, $
                  source_options = source, type = type, $
                  progobj = progobj, files = files, no_time_clip = no_time_clip, $
                  true_dsl = true_dsl, use_eclipse_corrections = use_eclipse_corrections, $
                  dead_time_correct = dead_time_correct, return_mag_rmat = return_mag_rmat

compile_opt idl2


thm_init
thm_load_esa_cal
  
vprobes = ['a','b','c','d','e']
vlevels = ['l1','l2']
deflevel = 'l1'   ; leave at level 1 until level 2 is validated.

if n_elements(probe) eq 1 then if probe eq 'f' then vprobes=[vprobes,'f']


if not keyword_set(probe) then probe=vprobes
probes = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)

lvl = thm_valid_input(level,'Level',vinputs=strjoin(vlevels, ' '), $
                      definput=deflevel, format="('l', I1)", verbose=0)
if lvl eq '' then return

if lvl eq 'l2' and keyword_set(type) then begin
   dprint,dlevel=0,"Type keyword not valid for level 2 data."
   return
endif

;grab downloadonly flag from !themis structure
if undefined(downloadonly) then begin
  downloadonly = !themis.downloadonly
endif 

if keyword_set(type) && ~keyword_set(raw) then begin ;if type is set to 'raw' then set the raw keyword
  if strcompress(/remove_all, strlowcase(type)) Eq 'raw' then raw = 1b else raw = 0b
endif

if arg_present(files) then begin ;needed because files is a variable used internally
  file_list_flag = 1
endif else begin
  file_list_flag = 0
endelse

;Reads Level 2 data files
if (lvl eq 'l2') or (lvl eq 'l1' and keyword_set(valid_names)) then begin
  thm_load_mom_l2, probe = probe, datatype = datatype_in, $
    trange = trange, level = lvl, verbose = verbose, $
    downloadonly = downloadonly, valid_names = valid_names, $
    source_options = source_options, progobj = progobj, files = files, $
    suffix = suffix, no_time_clip = no_time_clip
  return
endif

;this appears to be handled in thm_load_mom_l2
;if keyword_set(valid_names) then begin
;   probe = vprobes
;   dprint, string(strjoin(probe, ','), $
;                          format = '( "Valid probes:",X,A,".")')
;   datatype_in = vdatatypes
;   dprint, string(strjoin(datatype_in, ','), $
;                          format = '( "Valid '+lvl+' datatypes:",X,A,".")')
;
;   level = vlevels
;   dprint, string(strjoin(level, ','), format = '( "Valid levels:",X,A,".")')
;   return
;endif

;get requested datatype(s)
if is_string(datatype_in) then begin
  datatype = spd_str_split(strlowcase(datatype_in),' ',/extract)
  if n_elements(datatype) eq 1 && stregex(datatype,'(all|mom)',/bool) then datatype = '*'
endif else begin
  datatype = '*'
endelse

if not keyword_set(source) then source = !themis
if not keyword_set(verbose) then verbose = source.verbose

; JWL 2012-08-01
; In TDAS 7.0, it was necessary to specify both true_dsl=1 and
; use_eclipse_corrections=1 to use the fully corrected eclipse
; spin model.

; true_dsl is no longer necessary, and now use_eclipse_corrections=2
; is the setting for full eclipse corrections.  If true_dsl is
; specified, warn the user, assume that full corrections are
; being requested, and set use_eclipse_corrections=2 here, overriding
; that keyword argument.

if (n_elements(true_dsl) GT 0) then begin
   dprint,dlevel=1,'true_dsl keyword no longer required.'
   dprint,dlevel=1,'Setting use_eclipse_corrections=2 to use fully corrected eclipse spin model.'
   use_eclipse_corrections=2
endif


; use_eclipse_corrections: use eclipse spin model as the reference spin phase
; Defaults to 0 for now.

if n_elements(use_eclipse_corrections) LT 1 then begin
   use_eclipse_corrections=0
   dprint,dlevel=2,'Defaulting to use_eclipse_corrections=0 (no eclipse spin model corrections).'
endif

; Warn user if partial eclipse corrections requested -- not recommended
; except for SOC processing.

if (use_eclipse_corrections EQ 1) then begin
   dprint,dlevel=1,'Caution: partial eclipse corrections requested. use_eclipse_corrections=2 for full corrections (when available).'
endif


addmaster=0

for s=0,n_elements(probes)-1 do begin
     thx = 'th'+ probes[s]

     pathformat = thx+'/'+lvl+'/mom/YYYY/'+thx+'_'+lvl+'_mom_YYYYMMDD_v01.cdf'
     dprint,dlevel=3,'pathformat: ',pathformat,verbose=verbose

     relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)
     files = spd_download(remote_file=relpathnames, _extra=source)
     
     if file_list_flag then begin ;concatenate the list
      if n_elements(file_list) eq 0 then begin
        file_list = [files]
      endif else begin
        file_list = [file_list,files]
      endelse
    endif

     if keyword_set(downloadonly) then continue

     suf=''
     suf='_raw'
     if 1 then begin
     cdfi = cdf_load_vars(files,varnames=varnames2,verbose=verbose,/all);,/no_attributes)
     if not keyword_set(cdfi) then continue
     vns = cdfi.vars.name
     time = cdfi.vars[where(vns eq thx+'_mom_time')].dataptr
     mom  = cdfi.vars[where(vns eq thx+'_mom')].dataptr
     qf   = cdfi.vars[where(vns eq thx+'_mom_qf')].dataptr
     pot  = cdfi.vars[where(vns eq thx+'_mom_pot')].dataptr
     hed      = cdfi.vars[where(vns eq thx+'_mom_hed')].dataptr
     hed_time = cdfi.vars[where(vns eq thx+'_mom_hed_time')].dataptr
     iesa_sweep = cdfi.vars[where(vns eq thx+'_mom_iesa_sweep')].dataptr
     iesa_sweep_time = cdfi.vars[where(vns eq thx+'_mom_iesa_sweep_time')].dataptr
     eesa_sweep = cdfi.vars[where(vns eq thx+'_mom_eesa_sweep')].dataptr
     eesa_sweep_time = cdfi.vars[where(vns eq thx+'_mom_eesa_sweep_time')].dataptr
     iesa_solarwind_flag = cdfi.vars[where(vns eq thx+'_mom_iesa_solarwind_flag')].dataptr
     eesa_solarwind_flag = cdfi.vars[where(vns eq thx+'_mom_eesa_solarwind_flag')].dataptr
     iesa_solarwind_time = cdfi.vars[where(vns eq thx+'_mom_iesa_solarwind_flag_time')].dataptr
     eesa_solarwind_time = cdfi.vars[where(vns eq thx+'_mom_eesa_solarwind_flag_time')].dataptr
     iesa_config = cdfi.vars[where(vns eq thx+'_mom_iesa_config')].dataptr
     iesa_config_time = cdfi.vars[where(vns eq thx+'_mom_iesa_config_time')].dataptr
     eesa_config = cdfi.vars[where(vns eq thx+'_mom_eesa_config')].dataptr
     eesa_config_time = cdfi.vars[where(vns eq thx+'_mom_eesa_config_time')].dataptr 
     isst_config = cdfi.vars[where(vns eq thx+'_mom_isst_config')].dataptr
     isst_config_time = cdfi.vars[where(vns eq thx+'_mom_isst_config_time')].dataptr
     esst_config = cdfi.vars[where(vns eq thx+'_mom_esst_config')].dataptr
     esst_config_time = cdfi.vars[where(vns eq thx+'_mom_esst_config_time')].dataptr 
     
;quick fix for mismatches in solarwind flag times and sweep times,
;jmm, 30-jul-2010
     If(ptr_valid(eesa_sweep_time) && ptr_valid(eesa_solarwind_time)) Then Begin
       If(n_elements(*eesa_sweep_time) Ne n_elements(*eesa_solarwind_time)) Then Begin
         tsw = *eesa_solarwind_time
         x = where(tsw[1:*] Eq tsw[0:n_elements(tsw)-2])
         If(x[0] Ne -1) Then Begin
           fsw = *eesa_solarwind_flag
           ntsw = n_elements(tsw)
           keep_flag = bytarr(ntsw)+1b
;The times tsw[x] and tsw[x+1] are the same -- you want to discard the
;times for which fsw is zero, or better yet, simply discard
;duplicates and set the flag to 1 for the leftovers
           keep_flag[x] = 0b
           fsw[x+1] = 1
           ok = where(keep_flag Eq 1)
           If(ok[0] Ne -1) Then Begin
             tsw = tsw[ok] & fsw = fsw[ok]
             ptr_free, eesa_solarwind_time
             eesa_solarwind_time = ptr_new(temporary(tsw))
             ptr_free, eesa_solarwind_flag
             eesa_solarwind_flag = ptr_new(temporary(fsw))
           Endif Else dprint, 'No non-duplicate OK times for EESA SWflag'
         Endif Else dprint, 'Sweep time and SWflag time mismatch, but no duplicate times'
       Endif
     Endif
;check for valid data, jmm, 25-mar-2008
     if(ptr_valid(time) eq 0 or ptr_valid(mom) eq 0 $
       or ptr_valid(qf) eq 0 or ptr_valid(pot) eq 0 $
       or ptr_valid(hed) eq 0 or ptr_valid(hed_time) eq 0) then begin
           dprint,dlevel=1,'Invalid data found in file(s): ' + files,verbose=verbose
           dprint,dlevel=1,'Skipping probe.'      ,verbose=verbose
           continue
      endif

     shft_index = round(interp(findgen(n_elements(*hed_time)) ,*hed_time, *time))
     shft = (*hed)[*,14 ]+  256u*  (*hed)[*,15]
     shft = shft[shft_index]

     thm_load_mom_cal_array,*time,*mom,*pot,*qf,shft,$
       iesa_sweep,iesa_sweep_time,eesa_sweep,eesa_sweep_time, $
       iesa_solarwind_flag, eesa_solarwind_flag, probe = probes[s], $
       iesa_config, iesa_config_time, eesa_config, eesa_config_time,$
       isst_config, isst_config_time, esst_config, esst_config_time,$
       iesa_solarwind_time, eesa_solarwind_time, coord=coord, $
       raw = raw, verbose = verbose, comptest = comptest, datatype = datatype, $
       use_eclipse_corrections=use_eclipse_corrections, suffix = suffix, $
       tplotnames=tplotnames,return_mag_rmat=return_mag_rmat

     tplot_ptrs = ptr_extract(tnames(/dataquant))
     unused_ptrs = ptr_extract(cdfi,except=tplot_ptrs)
     ptr_free,unused_ptrs

     endif else begin
        message," Don't do this!"

;     spd_cdf2tplot,file=files,all=all,suffix=suf,verbose=verbose ,get_support_data=1 ;get_support_data    ; load data into tplot variables
;
;     get_data,thx+'_mom'+suf,ptr=p
;     get_data,thx+'_mom_pot'+suf,ptr=p_pot
;
;     options,thx+'_mom_qf'+suf,tplot_routine='bitplot'
;
;     get_data,thx+'_mom_hed'+suf,ptr=phed
;     if keyword_set(phed) then begin
;        store_data,thx+'_mom_CompCfg',data={x:phed.x, y:(*phed.y)[*,12] }, dlim={tplot_routine:'bitplot'}
;        store_data,thx+'_mom_covers',data={x:phed.x, y:(*phed.y)[*,13] }, dlim={tplot_routine:'bitplot'}
;        shft = (*phed.y)[*,14] + (*phed.y)[*,15]*256u
;        store_data,thx+'_mom_shift',data={x:phed.x, y:shft }, dlim={tplot_routine:'bitplot',colors:'r'}
;     endif
;     thm_load_mom_cal,probe=probes[s]

     endelse
;Apply dead time correction, if asked for
     If(keyword_set(dead_time_correct)) Then Begin
        thm_apply_esa_mom_dtc, probe = probes[s], trange = trange, in_suffix = suffix
     Endif
endfor

if file_list_flag && n_elements(file_list) ne 0 then begin
  files=file_list
endif

;clip data to requested time range
if ~keyword_set(no_time_clip) then begin
  thm_clip_moment, tplotnames=tplotnames, trange=trange 
endif

end
