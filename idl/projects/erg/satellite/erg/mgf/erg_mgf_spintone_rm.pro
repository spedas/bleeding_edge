;+
;Function: erg_mgf_spintone_rm
;
;Purpose:
;remove spin tone modurations from high-time-resolution Arase/MGF data.
;calculate parameters (A and B) by fitting the function A*cos(sp)+B*sin(sp) (sp:spin phase angle)
; to the high-pass filtered data. The linear fitting by the 'normal equation' is used.
;
;The parameters are interporated at every time indices and a model spin tone waveform is derived.
;The spin tone waveform is removed from input magnetic data.
;
;Rules of the road:
;The method in this procedure is described in the method section of Imajo et al. [2021].
;If you use the procedure for your research, please cite the following article.
;"Imajo, S., Miyoshi, Y., Kazama, Y. et al. Active auroral arc powered by accelerated electrons 
;from very high altitudes. Sci Rep 11, 1610 (2021). https://doi.org/10.1038/s41598-020-79665-5"
;
;Arguments:
;            mag_data = tplot variable of MGF magnetic data to be cleaned.
;
;            sp_data = array of the multi harmonic spin phase data [degrees] (time x sps). 
;            time index should be the same as mag_data.
;
;            dt = window width of data for estimating parameters [sec]. defualt=600 sec
;
;            w_hp = window of high pass filter [sec]. defualt= 32 sec
;            /linear = use linear interpolation instead of spline interpolation.
;            /extrapolate = extrapolate the fitting parapeters. deflualt=0
;
;            trange= time range for estimating parameters. defualt is t of get_timespan,t
;
;CALLING SEQUENCE;
;           erg_mgf_spin_tone_rm,'erg_mgf_l2_mag_64hz_dsi','erg_mgf_l2_spin_phase_64hz'

;Output:
;      '*_clean_spt'=cleaned data
;      '*_spt'=spin tone data to be removed
;      '*_?par'=fitting parameters
;
;Notes:
;NaN should be removed from input data.
;
;Examples:
;See a crib sheet.
;
;CREATED BY Shun Imajo (DACGSM, Kyoto Univ.)
;2020/07/28: array of the multi harmonic spin phase data can be accpeted as a input ("sp_data")
;2020/07/30: skip the interval that the number of the data points is not enough
;2021/06/07: The first release version for the bleeding edge.


pro erg_mgf_spintone_rm,mag_data,sp_data,dt=dt,w_hp=w_hp,linear=linear,extrapolate=extrapolate,trange=trange

    ;set initial parameters
    if not KEYWORD_SET(w_hp) then w_hp=32
    if not KEYWORD_SET(dt) then dt=600
    if not KEYWORD_SET(extrapolate) then no_extrapolate=1 else no_extrapolate=0
    if not KEYWORD_SET(extrapolate) then nan_extrapolate=1 else nan_extrapolate=0
    if not KEYWORD_SET(trange) then get_timespan,trange
    if not KEYWORD_SET(linear) then spline=1 else spline=0

    trange=time_double(trange)

    if trange[1]-trange[0] lt 3600 then begin
        print,'calculating period should be more than 1 hour'
        return
    endif


    tsmooth_in_time,mag_data,w_hp
    dif_data,mag_data,mag_data+'_smoothed',newname=mag_data+'_hp'
    get_data,mag_data+'_hp',data=mag,limit=l
    get_data,sp_data,data=sp

    if not array_equal(n_elements(mag.x),n_elements(sp.x)) then begin
        print,'time index of data and spin phase should be the same'
        return
    endif

    xpar=[] & ypar=[] & zpar=[]
    for i=trange[0],trange[1]-dt,dt do begin
        print,'calculating parameters between '+time_string(i)+' and '+time_string(i+dt)
        ind_range=nn(sp,[i,i+dt])
        if ind_range[1]-ind_range[0] le 256.*8.*4 then begin
            print,'not enough data point in the interval!'
            xpar0=findgen(2.*n_elements(sp.y[0,*]))* !values.f_nan
            ypar0=findgen(2.*n_elements(sp.y[0,*]))* !values.f_nan
            zpar0=findgen(2.*n_elements(sp.y[0,*]))* !values.f_nan
            xpar=[[xpar],[xpar0]]
            ypar=[[ypar],[ypar0]]
            zpar=[[zpar],[zpar0]]
            append_array,timei,i+dt/2.
            continue
        endif


        ind=[ind_range[0]:ind_range[1]]
        sinsp=sind(sp.y[ind,*])
        cossp=cosd(sp.y[ind,*])
        A=[[cossp],[sinsp]]
        inv=invert(transpose(A)#A)#transpose(A); solve normal equation
        xpar0=inv#mag.y[ind,0]
        ypar0=inv#mag.y[ind,1]
        zpar0=inv#mag.y[ind,2]
        xpar=[[xpar],[xpar0]]
        ypar=[[ypar],[ypar0]]
        zpar=[[zpar],[zpar0]]
        append_array,timei,i+dt/2.
    endfor


    ;restore fitting parameters
    store_data,mag_data+'_xpar',data={x:timei,y:transpose(xpar)}
    store_data,mag_data+'_ypar',data={x:timei,y:transpose(ypar)}
    store_data,mag_data+'_zpar',data={x:timei,y:transpose(zpar)}

    ;interpolate fitting parameters
    tinterpol,mag_data+'_xpar',mag_data,spline=spline,nan_extrapolate=nan_extrapolate,no_extrapolate=no_extrapolate
    tinterpol,mag_data+'_ypar',mag_data,spline=spline,nan_extrapolate=nan_extrapolate,no_extrapolate=no_extrapolate
    tinterpol,mag_data+'_zpar',mag_data,spline=spline,nan_extrapolate=nan_extrapolate,no_extrapolate=no_extrapolate
    ;tplot,mag_data+'_?par_interp'

    ;making spin tone
    get_data,sp_data,data=sp
    sinsp=sind(sp.y)
    cossp=cosd(sp.y)
    B=[[cossp],[sinsp]]
    get_data,mag_data+'_xpar_interp',data=xparinp
    get_data,mag_data+'_ypar_interp',data=yparinp
    get_data,mag_data+'_zpar_interp',data=zparinp
    xspt=total(xparinp.y*B,2)
    yspt=total(yparinp.y*B,2)
    zspt=total(zparinp.y*B,2)
    store_data,mag_data+'_spt',data={x:sp.x,y:[[xspt],[yspt],[zspt]]}

    ;subtracting spin tone
    dif_data,mag_data,mag_data+'_spt',newname=mag_data+'_clean_spt'

    store_data,mag_data+'_spt',limit=l
    store_data,mag_data+'_clean_spt',limit=l

    ;show RoR
    print, '**************** Rules of the road ****************************************'
    print, 'The method in this procedure is described in the method section of Imajo et al. [2021].'
    print, 'If you use the procedure for your research, please cite the following article.'
    print, 'Imajo, S., Miyoshi, Y., Kazama, Y. et al. Active auroral arc powered by accelerated electrons' 
    print, 'from very high altitudes. Sci Rep 11, 1610 (2021). https://doi.org/10.1038/s41598-020-79665-5'
    print, '**************************************************************************'

end
