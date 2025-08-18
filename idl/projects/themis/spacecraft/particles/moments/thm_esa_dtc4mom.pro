;+
;NAME:
; thm_esa_dtc4mom
;PURPOSE:
; calculates a dead-time correction value for ESA particle moments,
; which then can be applied to on-board MOM data.
;CALLING SEQUENCE:
; thm_esa_dtc4mom, probe=probe, trange=trange
;INPUT:
; All via keyword
;OUTPUT:
; None explicit, a number of tplot variables are created.
;KEYWORDS:
; probe='a','b','c','d' or 'e'
; trange = an input time range, otherwise the current time range is
;          used.
; noload = if set, make the assumption that the data is there, and
;          don't load it
; use_esa_mode = 'f','r', or 'b', use this mode for the ESA data to get
;                the dead time correction, the default is 'f'
; scpot_correct = if set, use thm_load_esa_pot to correct for SC
;                 potential in moments. The default is to avoid the correction
;HISTORY:
; 10-may-2011, jmm, jimm@ssl.berkeley.edu
; 27-may-2011, jmm, This version deletes the temporary ESA moments
; 5-dec-2014, jmm, uses thm_part_products directly
; 10-jan-2017, jmm, set ESA background removal to 0
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-01-10 12:46:45 -0800 (Tue, 10 Jan 2017) $
; $LastChangedRevision: 22565 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_esa_dtc4mom.pro $
;-

Pro thm_esa_dtc4mom, probe = probe, trange = trange, noload = noload, $
                     use_esa_mode = use_esa_mode, scpot_correct = scpot_correct, $
                     out_suffix = out_suffix, keep_temp_moments = keep_temp_moments, $
                     no_despike = no_despike, nsig_despike = nsig_despike, _extra = _extra

  dtc_denom = 1                 ;init to no-dead-time
  thm_init                      ;this program can be called at start
  vprobes = ['a', 'b', 'c', 'd', 'e']
  If(keyword_set(probe)) Then Begin
     probes = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)
     If(is_string(probes) Eq 0) Then Begin
        dprint, 'No valid probe input: '+probe
        Return
     Endif
  Endif Else probes = vprobes

  If(keyword_set(trange) && n_elements(trange) Eq 2) $
  Then tr = timerange(trange) Else tr = timerange()

  If(is_string(use_esa_mode)) Then Begin
     mode = strlowcase(strcompress(use_esa_mode, /remove_all))
  Endif Else mode = 'f'

  Case mode Of
     'f': datat = ['peif', 'peef']
     'r': datat = ['peir', 'peer']
     'b': datat = ['peib', 'peeb']
     Else: Begin
        dprint, "Please use 'f', 'r', or 'b' for mode, Setting mode to 'f'"
        datat = ['peif', 'peef']
     End
  Endcase

  If(n_elements(trange) Eq 2) Then tr0 = time_double(trange) $
  Else tr0 = timerange()        ;should be defined already, since this is only called after MOM data is loaded
;set this to get through the ESA data load
  timespan, tr0[0], tr0[1]-tr0[0], /seconds

  If(keyword_set(out_suffix)) Then osfx = out_suffix Else osfx = ''
;ii are the instrument types for MOM data, vv are the different
;moments that will need to be dealt with
  ii = ['peim', 'peem']
  vv = ['density', 'flux', 'mftens', 'eflux', 'velocity', 'ptens', 'ptot']

;for each probe
  np = n_elements(probes)
  For j = 0, np-1 Do Begin
     sc = probes[j] & thx = 'th'+sc
;here check to see if the appropriate data has been loaded, and load
;if necessary
     have_i_data = thm_part_check_trange(sc, datat[0], tr0)
     have_e_data = thm_part_check_trange(sc, datat[1], tr0)
     If(~keyword_set(noload)) Then Begin
        If(have_i_data Eq 0) Then thm_part_load, probe = sc, trange = tr0, datatype = datat[0], $
           suffix = '_temp4dtc'
        If(have_e_data Eq 0) Then thm_part_load, probe = sc, trange = tr0, datatype = datat[1], $
           suffix = '_temp4dtc'
     Endif
;you need the potential for the moments
     If(keyword_set(scpot_correct)) Then Begin
        thm_load_esa_pot, sc = sc, efi_datatype = 'mom'
        sc_pot_name = thx+'_esa_pot'
     Endif Else sc_pot_name = ''
;now get moments - without dead time corrections - and without
;                  background removal
     For i = 0, 1 Do Begin
        thm_part_products, probe = sc, datatype = datat[i], /zero_dead_time, $
                           sc_pot_name = sc_pot_name, suffix = '_temp4dtc_0', $
                           outputs = 'moments', esa_bgnd_remove = 0

;'ptot' variable
        get_data, thx+'_'+datat[i]+'_ptens_temp4dtc_0', data = ptd, dlimits = dl
        If(is_struct(ptd)) Then Begin
           IF(n_elements(ptd.x) Gt 1) Then ptot = total(ptd.y[*, 0:2], 2)/3.0 $
           Else ptot = total(ptd.y[0:2])/3.0
           store_data, thx+'_'+datat[i]+'_ptot_temp4dtc_0', data = {x:ptd.x, y:ptot}, $
                       dlimits = dl
        Endif
     Endfor
;now get moments - with dead time corrections
     For i = 0, 1 Do Begin
        thm_part_products, probe = sc, datatype = datat[i], $
                           sc_pot_name = sc_pot_name, suffix = '_temp4dtc', $
                           outputs = 'moments', esa_bgnd_remove = 0
;'ptot' variable
        get_data, thx+'_'+datat[i]+'_ptens_temp4dtc', data = ptd, dlimits = dl
        If(is_struct(ptd)) Then Begin
           IF(n_elements(ptd.x) Gt 1) Then ptot = total(ptd.y[*, 0:2], 2)/3.0 $
           Else ptot = total(ptd.y[0:2])/3.0
           store_data, thx+'_'+datat[i]+'_ptot_temp4dtc', data = {X:ptd.x, y:ptot}, $
                       dlimits = dl
        Endif
     Endfor

    ;;; Calling tplot_force_monotonic to repair repeats in tplot variables *_temp4dtc
     tplot_force_monotonic,'*_temp4dtc',/forward

;Now get corrections
     If(keyword_set(nsig_despike)) Then nsg = nsig_despike Else nsg = 0.5
     vv = [vv, 'ptot']

     tvars = thx+'_'+datat[0]+'_'+vv+'_temp4dtc'
     tvars0 = tvars+'_0'
     tvars_dtc = thx+'_'+datat[0]+'_'+vv+'_dtc'+osfx
     For k = 0, n_elements(vv)-1 Do Begin
        get_data, tvars[k], data = dd
        get_data, tvars0[k], data = dd0
        dtc = dd.y/dd0.y
;despike dtc
        If(~keyword_set(no_despike)) Then Begin
           ndim = n_elements(dtc[0,*])
           For ll = 0, ndim -1 Do Begin
              flag = dydt_spike_test(dd.x-dd.x[0], abs(dtc[*, ll]), nsig = nsg)
              spike_ss = where(flag Eq 1, nspike) & ok_ss = where(flag Eq 0, nok)
              If(nok Lt 3) Then Begin
                 dprint, dlevel=2, 'Data for '+thx+datat[0]+'_'+vv[k]+' is all spikes, '+$
                         'suggests larger value of nsig_despike needed. Not despiking'
              Endif Else Begin
                 If(nspike Gt 0) Then Begin ;interpolate over spike values
                    dtc[*,ll] = interpol(dtc[ok_ss,ll], dd.x[ok_ss], dd.x)
                 Endif 
              Endelse
           Endfor
        Endif
        store_data, tvars_dtc[k], data = {x:dd.x, y:dtc}
     Endfor

     tvars = thx+'_'+datat[1]+'_'+vv+'_temp4dtc'
     tvars0 = tvars+'_0'
     tvars_dtc = thx+'_'+datat[1]+'_'+vv+'_dtc'+osfx
     For k = 0, n_elements(vv)-1 Do Begin
        get_data, tvars[k], data = dd
        get_data, tvars0[k], data = dd0
        dtc = dd.y/dd0.y
;despike dtc
        If(~keyword_set(no_despike)) Then Begin
           ndim = n_elements(dtc[0,*])
           For ll = 0, ndim -1 Do Begin
              flag = dydt_spike_test(dd.x-dd.x[0], abs(dtc[*, ll]), nsig = nsg)
              spike_ss = where(flag Eq 1, nspike) & ok_ss = where(flag Eq 0, nok)
              If(nok Lt 3) Then Begin
                 dprint, dlevel=2, 'Data for '+thx+datat[1]+'_'+vv[k]+' is all spikes, '+$
                         'suggests larger value of nsig_despike needed. Not despiking'
              Endif Else Begin
                 If(nspike Gt 0) Then Begin ;interpolate over spike values
                    dtc[*,ll] = interpol(dtc[ok_ss,ll], dd.x[ok_ss], dd.x)
                 Endif 
              Endelse
           Endfor
        Endif
        store_data, tvars_dtc[k], data = {x:dd.x, y:dtc}
     Endfor

;Delete temporary moments
     If(~keyword_set(keep_temp_moments)) Then Begin
        del_data, '*_temp4dtc'
        del_data, '*_temp4dtc_0'
     Endif
     options, thx+'*_dtc'+osfx, 'ynozero', 1
  Endfor

  Return
End
