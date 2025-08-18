PRO eva_data_plot_options, paramlist

  imax = n_elements(paramlist)

  for i=0,imax-1 do begin
    tpv = paramlist[i]
    
;    get_data,tpv,data=D,dl=dl,lim=lim
;    if size(D,/type) eq 8 then begin; check if structure 
;      tn = strlowcase(tag_names(D))
;      idx = where(strmatch(tn,'y'),ct)
;      if ct eq 1 then begin; check if tag 'Y' exists
;        sz=size(D.y,/dim)
;        if n_elements(sz) eq 2 then begin; check if 2D array
;          if sz[1] eq 3 then begin; check if 3-element vector
;            coef = 0.5
;            ymax = coef*max(D.y,/nan)
;            ymin = coef*min(D.y,/nan)
;            options,tpv,labflag=3, labpos=[ymax,0,ymin]
;          endif
;        endif; check if 2D
;      endif; check if tag 'Y' exists
;    endif; check if structure
    
    ;-----------
    ; MMS FPI
    ;-----------
    
;    if strmatch(tpv,'*_fpi_eEnergySpectr_omni') then begin
;      options, tpv, 'spec', 1
;      options, tpv, 'ylog', 1
;      options, tpv, 'zlog', 1
;      options, tpv, 'no_interp', 1
;      options, tpv, 'ytitle', 'elec E, eV'
;      ylim, tpv, 10, 26000
;      zlim, tpv, .1, 2000
;    endif
;    
;    if strmatch(tpv,'*_fpi_iEnergySpectr_omni') then begin
;      options, tpv, 'spec', 1
;      options, tpv, 'ylog', 1
;      options, tpv, 'zlog', 1
;      options, tpv, 'no_interp', 1
;      options, tpv, 'ytitle', 'ion E, eV'
;      ylim, tpv, 10, 26000
;      zlim, tpv, .1, 2000
;    endif
;    
;    if strmatch(tpv,'*_fpi_ePitchAngDist_midEn') then begin
;      options, tpv, 'spec', 1
;      options, tpv, 'ylog', 0
;      options, tpv, 'zlog', 1
;      options, tpv, 'no_interp', 1
;      options, tpv, 'ytitle', 'ePADM, eV'
;      ylim, tpv, 1, 180
;      zlim, tpv, 100, 10000
;    endif
;    
;    if strmatch(tpv,'*_fpi_ePitchAngDist_highEn') then begin
;      options, tpv, 'spec', 1
;      options, tpv, 'ylog', 0
;      options, tpv, 'zlog', 1
;      options, tpv, 'no_interp', 1
;      options, tpv, 'ytitle', 'ePADH, eV'
;      ylim, tpv, 1, 180
;      zlim, tpv, 100, 10000
;    endif
;    
;    if strmatch(tpv,'*_fpi_DISnumberDensity') then begin
;      options, tpv, 'ylog', 1
;      options, tpv, 'ytitle', 'n, cm!U-3!N'
;    endif
;    
;    if strmatch(tpv,'*_fpi_iBulkV_DSC') then begin
;      options, tpv, labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
;      options, tpv, 'ytitle', 'V!DDSC!N, km/s'
;      options, tpv, 'colors', [2,4,6]
;    endif
    
    ; ESA spectrograms
    if strmatch(tpv,'*pe??_en_eflux*') then begin
      ylim, tpv,7,30000,1
      zlim, tpv, 1e+0,1e+6,1
      ;options, tpv,'ytitle', 'ESA'+strmid(tpv,6,1);pmms+'!Cele'
      ;options, tpv,'ysubtitle','[keV]'
      if strpos(tpv,'pee') ge 0 then begin
        zlim, tpv, 1e+4, 1e+9, 1
      endif
    endif

    ; SST
    if strmatch(tpv,'th*_ps*') then begin
      ;options, tpv,'ytitle', 'SST'+strmid(tpv,6,1);pmms+'!Cele'
      options, tpv,'ysubtitle','[keV]'
      spectrogram = 0
      options, tpv, 'spec', spectrogram
      if spectrogram then begin
        options, tpv, 'panel_size', 0.5
        ylim, tpv, 30000,800000,1
        zlim, tpv, 1e+0,1e+6,1
      endif
    endif

    ; FBK
    if strpos(tpv,'thb_fb_') ge 0 then begin
      if strpos(tpv,'edc') ge 0 then tag = 'E'
      if strpos(tpv,'scm') ge 0 then tag = 'B'
      options, tpv, 'spec',1
      options, tpv, 'zlog',1
      ;options, tpv, 'ytitle', lbl+'!CWave!C'+tag
      ;options, tpv, 'ysubtitle', '[Hz]'
      ylim, tpv, 2, 2000, 1
      if strpos(tpv,'edc') ge 0 then begin
        zlim, tpv, 0.005, 5.
      endif
    endif

    if strpos(tpv,'_tdn') ge 0 then begin
      spectrogram = 1
      options, tpv, 'spec', spectrogram
      options, tpv, 'ystyle', 0
      if spectrogram then options, tpv, 'ystyle', 1
    endif

  endfor; for i=0,imax-1
END
