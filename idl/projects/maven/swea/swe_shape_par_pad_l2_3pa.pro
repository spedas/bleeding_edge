;+
;PROCEDURE:
;   swe_shape_par_pad_l2_3pa
;
;PURPOSE:
;
;   Calculate pitch angle resolved shape parameters for loaded SWEA L2
;   PAD survey data for three PA ranges and create tplot variable "Shape_PAD"
;
;AUTHOR:
;   Shaosui Xu
;
;CALLING SEQUENCE:
;
;   If desire to correct for spacecraft potential, first run "mvn_swe_sc_pot"
;
;INPUTS:
;
;   none
;
;KEYWORDS:
;
;   BURST:    If set to 1, then use burst data to calculate the shape parameter,
;             however, not tested yet
;
;   SPEC:     A pitch angle in degrees given to average.
;             PA [0,SPEC] & [(180-SPEC),180] for two directions.
;             The default value is 30
;
;   ERANGE:  Shape parameter calculated based on the spectrum within this energy
;            range. The default values are [20,80] eV
;
;   MIN_PAD_EFLUX: Minimum energy flux level.
;
;   MAG_GEO: A MAG structure that contains magnetic elevation angle. If not given,
;            The program will load MAG data in GEO coordinates.
;
;   POT:     If set to 1, this program will correct the spacecraft potential for
;            the electron energy spectrum.
;
;   NSMO:    Number of spectra to average over before calculating shape parameter.
;            Default = 1 (no smoothing).
;
;   TSMO:    Boxcar smooth the PADs with this width (in seconds) before calculating
;            the shape parameter.  This method is slower but handles data gaps and 
;            changes in instrument mode.  Takes precedence over NSMO.
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
; $LastChangedDate: 2025-06-23 10:14:21 -0700 (Mon, 23 Jun 2025) $
; $LastChangedRevision: 33407 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_shape_par_pad_l2_3pa.pro $
;
;CREATED BY:    Shaosui Xu  12-09-17
;-

Pro swe_shape_par_pad_l2_3pa, burst=burst, spec=spec, $
    nsmo=nsmo, erange=erange, mag_geo=mag_geo, pot=pot, $
    tsmo=tsmo, min_pad_eflux=min_pad_eflux

    @mvn_swe_com
    @mvn_scpot_com

   if (size(min_pad_eflux,/type) eq 0) then min_pad_eflux = 6.e4
    
    aflg = keyword_set(burst)
    if (size(mvn_swe_pad,/type) ne 8) then begin ;if pad data not loaded
        print,'Loading L2 PAD data ...'
        prod = aflg ? ['arcpad'] : ['svypad']
        mvn_swe_load_l2,prod=prod,/noerase
    endif

    old_units = mvn_swe_pad[0].units_name
    mvn_swe_convert_units, mvn_swe_pad, 'eflux'

; Extract data from PAD structure

    npad = n_elements(mvn_swe_pad)
    pdat = mvn_swe_pad.data

; Mask noisy data

    print, "Masking noisy PAD data"

    endx = where(abs(mvn_swe_pad[0].energy[*,0] - 130) lt 20.,n_e)
    indx = where(mean(reform(pdat[endx,*,*],n_e*16,npad),dim=1,/nan) lt min_pad_eflux, count)
    if (count gt 0L) then pdat[*,*,indx] = !values.f_nan

; Smooth the data for better statistics

    if (size(tsmo,/type) gt 0) then begin
      print, "Smoothing PAD data"
      if (tsmo ge 4D) then begin
        pdat = transpose(reform(pdat, 64L*16L, npad))
        pdat = smooth_in_time(pdat, mvn_swe_pad.time, tsmo)
        pdat = reform(transpose(pdat), 64, 16, npad)
        nsmo = 0  ; only one smoothing method
      endif
    endif

    if keyword_set(nsmo) then pdat = smooth(pdat,[1,1,nsmo],/nan)

    if not keyword_set(erange) then erange=[20,80]

    if (size(pot,/type) ne 0) then dopot=1 else dopot=0

    if (size(spec,/type) ne 0) then begin
        swidth = (float(abs(spec)) > 30.)*!dtor
    endif else begin
        swidth = 30.*!dtor
    endelse
    swidth = 30.*!dtor

    print, "Calculating shape parameter with PAD data"

    shape = fltarr(npad,3,3)
    f3pa = fltarr(64,3,3,npad)
    time = dblarr(npad)
    ratio = dblarr(npad,64)
    print, 'Total PAD data points: ', npad

    ;Use B elevation angle to determine towards/away the planet
    if NOT keyword_set(mag_geo) then begin
        get_data,'mvn_B_1sec_iau_mars',data=mag_geo,index=i
        if (i eq 0) then begin
          mvn_mag_load
          mvn_mag_geom
          get_data,'mvn_B_1sec_iau_mars',data=mag_geo
        endif
     endif

    bdx = nn(mag_geo.x, mvn_swe_pad.time)
    B_elev = mag_geo.elev[bdx]
    B_azim = mag_geo.azim[bdx]

    ;padall = mvn_swe_getpad(trange,archive=aflg,units='eflux')
    
    padall = mvn_swe_pad
    padall.data = pdat  ; don't overwrite mvn_swe_pad
    faway = dblarr(64,3,npad)
    ftwd = faway
    fmid = faway
    Bindx = where(B_elev le 0)
    parange = fltarr(npad,2)
    pots = fltarr(npad)
    pots[*] = !values.f_nan

    for n=0L, npad-1L do begin
        pad=padall[n]
        time[n] = pad.time
;        if (pad.time gt t_mtx[2]) then boom = 1 else boom = 0
;        indx = where(obins[pad.k3d,boom] eq 0B, count)
;        if (count gt 0L) then pad.data[*,indx] = !values.f_nan

        Fp = replicate(!values.f_nan,64,3)
        Fm = replicate(!values.f_nan,64,3)
        Fz = replicate(!values.f_nan,64,3)

        pndx = where(reform(pad.pa[63,*]) lt swidth, count)
        if (count gt 0L) then Fp[*,0] = average(reform(pad.data[*,pndx]*pad.dpa[*,pndx]), 2, /nan)$
            /average(pad.dpa[*,pndx], 2, /nan)
        pndx = where(reform(pad.pa[63,*]) lt 45.*!dtor, count)
        if (count gt 0L) then Fp[*,1] = average(reform(pad.data[*,pndx]*pad.dpa[*,pndx]), 2, /nan)$
            /average(pad.dpa[*,pndx], 2, /nan)
        pndx = where(reform(pad.pa[63,*]) lt 60.*!dtor, count)
        if (count gt 0L) then Fp[*,2] = average(reform(pad.data[*,pndx]*pad.dpa[*,pndx]), 2, /nan)$
            /average(pad.dpa[*,pndx], 2, /nan)
       
        mndx = where(reform(pad.pa[63,*]) gt (!pi - swidth), count)
        if (count gt 0L) then Fm[*,0] =average(reform(pad.data[*,mndx]*pad.dpa[*,mndx]), 2, /nan)$
            /average(pad.dpa[*,mndx], 2, /nan)
        mndx = where(reform(pad.pa[63,*]) gt (!pi - 45.*!dtor), count)
        if (count gt 0L) then Fm[*,1] =average(reform(pad.data[*,mndx]*pad.dpa[*,mndx]), 2, /nan)$
            /average(pad.dpa[*,mndx], 2, /nan)
        mndx = where(reform(pad.pa[63,*]) gt (!pi - 60.*!dtor), count)
        if (count gt 0L) then Fm[*,2] =average(reform(pad.data[*,mndx]*pad.dpa[*,mndx]), 2, /nan)$
            /average(pad.dpa[*,mndx], 2, /nan)

        zndx = where((reform(pad.pa[63,*]) lt (!pi - swidth)) and $
            (reform(pad.pa[63,*]) gt swidth), count)
        if (count gt 0L) then Fz[*,0] =average(reform(pad.data[*,zndx]*pad.dpa[*,zndx]), 2, /nan)$
            /average(pad.dpa[*,zndx], 2, /nan)
        zndx = where((reform(pad.pa[63,*]) lt (!pi - 45.*!dtor)) and $
            (reform(pad.pa[63,*]) gt 45.*!dtor), count)
        if (count gt 0L) then Fz[*,1] =average(reform(pad.data[*,zndx]*pad.dpa[*,zndx]), 2, /nan)$
            /average(pad.dpa[*,zndx], 2, /nan)
        zndx = where((reform(pad.pa[63,*]) lt (!pi - 60.*!dtor)) and $
            (reform(pad.pa[63,*]) gt 60.*!dtor), count)
        if (count gt 0L) then Fz[*,2] =average(reform(pad.data[*,zndx]*pad.dpa[*,zndx]), 2, /nan)$
            /average(pad.dpa[*,zndx], 2, /nan)

        parange[n,0]=max(pad.pa[63,*])
        parange[n,1]=min(pad.pa[63,*])

        Fpc = Fp
        Fzc = Fz
        Fmc = Fm
        if dopot then begin
            ipot = mvn_sc_pot[nn(mvn_sc_pot.time, pad.time)].potential
            pots[n] = ipot
            if ipot eq ipot and abs(ipot) le 20 then begin;and ipot le -2
               for ijk=0,2 do begin

                  mvn_swe_pot_conve, reform(pad.energy[*,0]), reform(Fp[*,ijk]), $
                                     outEn, tFpc, ipot
                  mvn_swe_pot_conve, reform(pad.energy[*,0]), reform(Fz[*,ijk]), $
                                     outEn, tFzc, ipot
                  mvn_swe_pot_conve, reform(pad.energy[*,0]), reform(Fm[*,ijk]), $
                                     outEn, tFmc, ipot
                  Fpc[*,ijk] = tFpc
                  Fzc[*,ijk] = tFzc
                  Fmc[*,ijk] = tFmc
               endfor
  
            endif 
        endif

        faway[*,*,n] = Fpc
        fmid[*,*,n] = Fzc
        ftwd[*,*,n] = Fmc
    endfor

    tmp1 =  faway[*,*,Bindx]
    tmp2 = ftwd[*,*,Bindx]
    ftwd[*,*,Bindx] = tmp1
    faway[*,*,Bindx] = tmp2
    ratio = transpose(faway/ftwd)
    
    f3pa[*,*,0,*] = faway
    f3pa[*,*,2,*] = fmid
    f3pa[*,*,1,*] = ftwd

    for ijk=0,2 do begin
       
       mvn_swe_calc_shape_arr, npad, reform(faway[*,ijk,*]), padall[1].energy[*,0], par_away, erange, aflg
       mvn_swe_calc_shape_arr, npad, reform(fmid[*,ijk,*]), padall[1].energy[*,0], par_mid, erange, aflg
       mvn_swe_calc_shape_arr, npad, reform(ftwd[*,ijk,*]), padall[1].energy[*,0], par_twd, erange, aflg

       shape[*,0,ijk] = par_away
       shape[*,1,ijk] = par_twd
       shape[*,2,ijk] = par_mid
    endfor
    ; stop
    ;create tplot variables
    store_data,'Shape_PAD',data={x:time, y:shape[*,0:1,0],mid:shape[*,2,0],$
        pots:pots,parange:parange,shape:shape,f3pa:f3pa}
    options,'Shape_PAD','ytitle','Shape_PAD'
    options,'Shape_PAD','labels',['Away','Towards']
    options,'Shape_PAD','labflag',1
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

    mvn_swe_convert_units, mvn_swe_pad, old_units

    return
end
