;+
; PROCEDURE:
;         mms_load_fpi_calc_omni
;
; PURPOSE:
;         Calculates the omni-directional energy spectra (summed and averaged) 
;         from the individual tplot variables
;
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-03-16 09:33:25 -0700 (Wed, 16 Mar 2016) $
;$LastChangedRevision: 20473 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi_calc_omni.pro $
;-
pro mms_load_fpi_calc_omni, probe, autoscale = autoscale, level = level, datatype = datatype, $
    data_rate = data_rate, suffix = suffix
    if undefined(suffix) then suffix = ''
    if undefined(datatype) then begin
      dprint, dlevel = 0, 'Error, must provide a datatype to mms_load_fpi_calc_omni'
      return
    endif
    if undefined(data_rate) then data_rate=''
    if undefined(autoscale) then autoscale = 1
    if undefined(level) then level = 'sitl'
    
    ; in case the user passes datatype = '*'
    if (datatype[0] eq '*' || datatype[0] eq '') && level eq 'ql' then datatype=['des', 'dis']
    if (datatype[0] eq '*' || datatype[0] eq '') && level ne 'ql' then datatype=['des-dist', 'dis-dist']

    species = strmid(datatype, 1, 1)

    for sidx=0, n_elements(species)-1 do begin
        spec_str_format = level eq 'sitl' ? 'EnergySpectr' : 'energySpectr'
        obs_str_format = level eq 'sitl' ? '_fpi_'+species[sidx] : '_d'+species[sidx]+'s_'
        obsstr='mms'+STRING(probe,FORMAT='(I1)')+obs_str_format

        ; include the data rate as the suffix for L2 data
        dtype_suffix = level eq 'l2' ? '_'+data_rate+suffix : suffix
        
        ; L2 variable names are all lower case
        plusminus_vars = obsstr+spec_str_format+['_pX', '_mX', '_pY', '_mY', '_pZ', '_mZ']+dtype_suffix
        plusminus_vars = level eq 'l2' ? strlowcase(plusminus_vars) : plusminus_vars
        
        ; get the energy spectra from the tplot variables
        get_data, plusminus_vars[0], data=pX, dlimits=dl
        get_data, plusminus_vars[1], data=mX, dlimits=dl
        get_data, plusminus_vars[2], data=pY, dlimits=dl
        get_data, plusminus_vars[3], data=mY, dlimits=dl
        get_data, plusminus_vars[4], data=pZ, dlimits=dl
        get_data, plusminus_vars[5], data=mZ, dlimits=dl

        ; skip avg/sum when we can't find the tplot names
        if ~is_struct(pX) || ~is_struct(mX) || ~is_struct(pY) || ~is_struct(mY) || ~is_struct(pZ) || ~is_struct(mZ) then continue

        e_omni_sum=(pX.Y+mX.Y+pY.Y+mY.Y+pZ.Y+mZ.Y)
        e_omni_avg=e_omni_sum/6.0

        if is_array(e_omni_sum) then begin
            omni_avg_name = obsstr+'EnergySpectr_omni_avg'+suffix
            ; lower case for level 2
            if level eq 'l2' then omni_avg_name = strlowcase(omni_avg_name)
            store_data, omni_avg_name, data = {x:pX.X, y:e_omni_avg, v:pX.V}, dlimits=dl
            ; still creating the sum for the QL plots
            if level eq 'ql' then store_data, obsstr+'EnergySpectr_omni_sum'+suffix, data = {x:pX.X, y:e_omni_sum, v:pX.V}, dlimits=dl
        endif

        species_str = species[sidx] eq 'e' ? 'electron' : 'ion'
        ; set the metadata for omnidirectional spectra
        if level eq 'ql' then options, obsstr+'EnergySpectr_omni_sum'+suffix, ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str+'!Csum'
        options, omni_avg_name, ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str+'!Cavg'
        
        if level eq 'ql' || level eq 'sitl' then begin
            options, omni_avg_name, ztitle='Counts'
        endif else begin
            options, omni_avg_name, ztitle='eV/(cm!U2!N s sr eV)'
        endelse
        
        ylim, omni_avg_name, min(pX.V), max(pX.V), 1
        if autoscale then zlim, omni_avg_name, 0, 0, 1 else $
            zlim, omni_avg_name, min(e_omni_avg), max(e_omni_avg), 1
            
        if level eq 'ql' then begin
            ylim, obsstr+'EnergySpectr_omni_sum'+suffix, min(pX.V), max(pX.V), 1
            if autoscale then zlim, obsstr+'EnergySpectr_omni_sum'+suffix, 0, 0, 1 else $
                zlim, obsstr+'EnergySpectr_omni_sum'+suffix, min(e_omni_sum), max(e_omni_sum), 1
        endif

        ; if autoscale isn't set, set the scale to the min/max of the average
        if ~autoscale then zlim, obsstr+'EnergySpectr_'+['pX', 'mX', 'pY', 'mY', 'pZ', 'mZ']+suffix, min(e_omni_avg), max(e_omni_avg), 1
    endfor
end