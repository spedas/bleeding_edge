;+
;PROCEDURE:
;   mvn_swe_shape_par_pad
;
;PURPOSE:
;   
;   Calculate pitch angle resolved shape parameters for loaded SWEA PAD data
;   and create tplot variable "Shape_PAD"
;
;AUTHOR:
;   Shaosui Xu
;
;CALLING SEQUENCE:
;
;   Assume SWEA l0 data loaded
;   
;   If desire to correct for spacecraft potential, first run "mvn_swe_sc_pot"
;
;INPUTS:
;
;   none
;
;KEYWORDS:
;
;   BURST: If set to 1, then use burst data to calculate the shape parameter, 
;          however, not tested yet
;          
;   SPEC: A pitch angle in degrees given to average. 
;         PA [0,SPEC] & [(180-SPEC),180] for two directions.
;         The default value is 30
;         
;   ERANGE: Shape parameter calculated based on the spectrum within this energy
;           range. The default values are [20,80] eV
;
;   MAG_GEO: A MAG structure that contains magnetic elevation angle. If not given,
;            The program will load MAG data in GEO coordinates.
;
;   POT: If set to 1, this program will correct the spacecraft potential for 
;        the electron energy spectrum.
;   
;OUTPUTS:
;
;   Tplot variable "Shape_PAD": store shape parameters for two directions, as well
;       as the shape parameter for trapped population, spacecraft potentials, 
;       min/max pitch angle range to check if the PA coverage is enough
;   
;   Tplot variable "EFlux_ratio": store the flux ratio for two directions
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-10-24 11:30:20 -0700 (Thu, 24 Oct 2024) $
; $LastChangedRevision: 32897 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_shape_par_pad.pro $
;
;CREATED BY:    Shaosui Xu  06-22-16
;-

Pro mvn_swe_shape_par_pad, burst=burst, spec=spec, $
    smo=smo, erange=erange, obins=obins, mask_sc=mask_sc, $
    abins=abins, dbins=dbins, mag_geo=mag_geo, pot=pot

    @mvn_swe_com

    aflg=0 ;set to low resolution template
    
    if keyword_set(burst) then aflg=1
    
    if (aflg) then begin
        str_element, mvn_swe_pad_arc, 'time', trange, success=ok
        if (not ok) then str_element, a3, 'time', trange, success=ok
    endif else begin
        str_element, mvn_swe_pad, 'time', trange, success=ok
        if (not ok) then str_element, a2, 'time', trange, success=ok
    endelse
    if (not ok) then begin
        print,"No PAD data!"
        return
    endif
    
    
    print, "Calculating shape parameter with PAD data"

    if not keyword_set(smo) then smo = 1
    if not keyword_set(erange) then erange=[20,80]

    if (size(pot,/type) ne 0) then dopot=1 else dopot=0

    if (size(spec,/type) ne 0) then begin
        swidth = (float(abs(spec)) > 30.)*!dtor
    endif else begin
        swidth = 30.*!dtor
    endelse

    if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
    if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
    if (n_elements(obins) ne 96) then begin
        obins = replicate(1B, 96, 2)
        obins[*,0] = reform(abins # dbins, 96)
        obins[*,1] = obins[*,0]
    endif else obins = byte(obins # [1B,1B])
    if (size(mask_sc,/type) eq 0) then mask_sc = 1
    if keyword_set(mask_sc) then obins = swe_sc_mask * obins

    Nt = n_elements(trange)
    shape = fltarr(Nt, 3)
    time = dblarr(Nt)
    ratio = dblarr(Nt,64)
    print, 'Total PAD data points: ', Nt

    ;Use B elevation angle to determine towards/away the planet
    if NOT keyword_set(mag_geo) then begin
        get_data,'mvn_B_1sec_iau_mars',data=mag_geo,index=i
        if (i eq 0) then begin
          mvn_mag_load
          mvn_mag_geom
          get_data,'mvn_B_1sec_iau_mars',data=mag_geo
        endif
    endif
    bdx = nn2(mag_geo.x, trange)
    B_elev = mag_geo.elev[bdx]
    B_azim = mag_geo.azim[bdx]

    padall = mvn_swe_getpad(trange,archive=aflg,units='eflux')
    faway = dblarr(64,Nt)
    ftwd = faway
    fmid = faway
    Bindx = where(B_elev le 0)
    parange = fltarr(Nt,2)
    pots = fltarr(Nt)
    pots[*] = !values.f_nan

    for n=0L, Nt-1L do begin
        pad=padall[n]
        time[n] = pad.time
        if (pad.time gt t_mtx[2]) then boom = 1 else boom = 0
        indx = where(obins[pad.k3d,boom] eq 0B, count)
        if (count gt 0L) then pad.data[*,indx] = !values.f_nan

        Fp = replicate(!values.f_nan,64)
        Fm = replicate(!values.f_nan,64)
        Fz = replicate(!values.f_nan,64)

        pndx = where(reform(pad.pa_max[63,*]) lt swidth, count)
        if (count gt 0L) then Fp = average(reform(pad.data[*,pndx]*pad.domega[*,pndx]), 2, /nan)$
            /average(pad.domega[*,pndx], 2, /nan)
        mndx = where(reform(pad.pa_min[63,*]) gt (!pi - swidth), count)
        if (count gt 0L) then Fm =average(reform(pad.data[*,mndx]*pad.domega[*,mndx]), 2, /nan)$
            /average(pad.domega[*,mndx], 2, /nan)
        zndx = where((reform(pad.pa_max[63,*]) lt (!pi - swidth)) and $
            (reform(pad.pa_min[63,*]) gt swidth), count)
        if (count gt 0L) then Fz=average(reform(pad.data[*,zndx]*pad.domega[*,zndx]), 2, /nan)$
            /average(pad.domega[*,zndx], 2, /nan)

        parange[n,0]=max(pad.pa_min[63,*])
        parange[n,1]=min(pad.pa_max[63,*])

        if dopot then begin
            ipot = swe_sc_pot[nn2(swe_sc_pot.time, pad.time)].potential
            pots[n] = ipot
            if ipot eq ipot and finite(ipot) then begin;and ipot le -2
                mvn_swe_pot_conve, pad.energy[*,0], Fp, outEn, Fpc, ipot
                mvn_swe_pot_conve, pad.energy[*,0], Fz, outEn, Fzc, ipot
                mvn_swe_pot_conve, pad.energy[*,0], Fm, outEn, Fmc, ipot
                ;if ipot le -10 then stop
            endif else begin
                Fpc = Fp
                Fzc = Fz
                Fmc = Fm
            endelse
        endif else begin
            Fpc = Fp
            Fzc = Fz
            Fmc = Fm
        endelse

        faway[*,n] = Fpc
        fmid[*,n] = Fzc
        ftwd[*,n] = Fmc
    endfor


    tmp1 =  faway[*,Bindx]
    tmp2 = ftwd[*,Bindx]
    ftwd[*,Bindx] = tmp1
    faway[*,Bindx] = tmp2
    ratio = transpose(faway/ftwd)

    mvn_swe_calc_shape_arr, Nt, faway, padall[1].energy[*,0], par_away, erange, aflg
    mvn_swe_calc_shape_arr, Nt, fmid, padall[1].energy[*,0], par_mid, erange, aflg
    mvn_swe_calc_shape_arr, Nt, ftwd, padall[1].energy[*,0], par_twd, erange, aflg


    shape[*, 0] = par_away
    shape[*, 1] = par_twd
    shape[*, 2] = par_mid
    ; stop
    ;create tplot variables
    store_data,'Shape_PAD',data={x:time, y:shape[*,0:1],mid:shape[*,2],$
        pots:pots,parange:parange}
    options,'Shape_PAD','ytitle','Shape_PAD'
    options,'Shape_PAD','labels',['Away','Towards']
    options,'Shape_PAD','colors',[120,254]
    options,'Shape_PAD','constant',1.

    store_data,'EFlux_ratio',data={x:time,y:ratio,v:pad.energy[*,0]}
    ename='EFlux_ratio'
    options,ename,'spec',1
    ylim,ename,3,5000,1
    options,ename,'ytitle','Energy (eV)'
    options,ename,'yticks',0
    options,ename,'yminor',0
    zlim,ename,0.1,5,1
    options,ename,'ztitle',ename
    options,ename,'y_no_interp',1
    options,ename,'x_no_interp',1

    ;stop
    return
end