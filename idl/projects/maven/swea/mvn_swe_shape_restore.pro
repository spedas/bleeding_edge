;+
;PROCEDURE:   mvn_swe_shape_restore
;PURPOSE:
;  Reads in save files swe_shape_par_pad
;
;USAGE:
;  mvn_swe_shape_restore, trange
;
;INPUTS:
;       trange:        Restore data over this time range.  If not specified, then
;                      uses the current tplot range or timerange() will be called
;
;KEYWORDS:
;       ORBIT:         Restore shape_par_pad data by orbit number.
;
;       RESULTS:       Hold the full structure of shape parameters and other parameters
;
;       TPLOT:         Create tplot varible for two-stream shape parameter, being
;                      stored as tplot variable "Shape_PAD" and "rat_a2t"
;
;       PARNG:         Shape parameter calculated based on 30, 45, and 60 deg, 
;                      corresponding to PARNG=1,2,3. Default is PA=45
;       
; $LastChangedBy: xussui_lap $
; $LastChangedDate: 2024-09-17 15:35:33 -0700 (Tue, 17 Sep 2024) $
; $LastChangedRevision: 32842 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_shape_restore.pro $
;
;CREATED BY:    Shaosui Xu  06-23-17
;FILE: mvn_swe_shape_restore
;-

Pro mvn_swe_shape_restore,trange,results=results,tplot=tplot,orbit=orbit,parng=parng

    ;   Process keywords
    ;rootdir='maven/data/sci/swe/l3/swe_shape_par_pad/YYYY/MM/'
    ;fname = 'mvn_swe_shape_par_pad_YYYYMMDD.sav'
    rootdir='maven/data/sci/swe/l3/shape/YYYY/MM/'
    fname = 'mvn_swe_l3_shape_YYYYMMDD_v??_r??.sav'

    if keyword_set(orbit) then begin
        imin = min(orbit, max=imax)
        trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
    endif

    tplot_options,get_opt=topt
    tspan_exists = (max(topt.trange_full) gt time_double('2014-12-01'))
    if((size(trange,/type) eq 0) and tspan_exists) then $
        trange=topt.trange_full

    if(size(trange,/type) eq 0) then trange=timerange()

    tmin = min(time_double(trange),max=tmax)
    file = mvn_pfp_file_retrieve(rootdir+fname,trange=[tmin,tmax],/daily_names)
    nfiles = n_elements(file)

    finfo = file_info(file)
    indx = where(finfo.exists,nfiles,comp=jndx,ncomp=n)

    for j=0,n-1 do print,'File not found:',file[jndx[j]]
    if (nfiles eq 0) then return
    file = file[indx]

;---- Edit to improve speed -- initialize array first
    print, 'Determining Array Size...'
    arraySize = 0
    for j=0,(nfiles-1) do begin
      if j eq 0 then print, 0, '% complete' else print, (j)/float(nfiles-1)*100., '% complete'
      restore, filename=file[J]
      arraySize = arraySize + n_elements(strday)
    endfor 
    print, 'Initializing Array...'
    emptyShp =  {t:0.D,shape:fltarr(3,3),parange:[0.,0.],$
      alt:0.,sza:0.,lst:0., lat:0.,lon:0.,$
      xmso:0., ymso:0.,zmso:0., xgeo:0.,$
      ygeo:0., zgeo:0., mid:0., f40:0., $
      Bmag:0.,Belev:0.,Baz:0.,Bclk:0.,pot:0.,mag_level:0,$
      fratio_a2t:fltarr(2,3)}

    shp =  replicate(emptyShp,arraySize)
    
    arrayIndex = 0
    for j=0,nfiles-1 do begin
      restore,filename=file[j]
      num = n_elements(strday)
      shp[arrayIndex:(arrayIndex+num-1)] = strday
      arrayIndex = arrayIndex+num
    endfor
;---

;--- Previous Method
;    for j=0,nfiles-1 do begin
;        restore,filename=file[j]
;        shp=[temporary(shp),strday]
;    endfor
;---


    intx=where(shp.t ge tmin and shp.t le tmax)
    if intx[0] eq -1 then begin
       shp = !values.f_nan
       results = shp
    endif else begin
       shp=shp[intx]
       results=shp 
    endelse
    
    if(keyword_set(tplot) and size(shp,/type) eq 8) then begin
        if (size(parng,/type) eq 0) then parng=2 else parng=fix(parng[0])
        if (parng lt 1 or parng gt 3) then begin
            print,'PARNG is only allowed to be 1, 2, or 3.'+$
                'reset to 2 (PA=45 deg)'
            parng=2
        endif
        npa=''
        if (parng eq 1) then npa='PA 0-30'
        if (parng eq 2) then npa='PA 0-45'
        if (parng eq 3) then npa='PA 0-60'
        indx = parng-1
        store_data,'Shape_PAD',data={x:shp.t, y:transpose(shp.shape[0:1,indx])}
        options,'Shape_PAD','ytitle',('Shape Par!c'+npa)
        options,'Shape_PAD','labels',['Away','Towards']
        options,'Shape_PAD','labflag',1
        options,'Shape_PAD','colors',[120,254]
        options,'Shape_PAD','constant',1.
        ylim,'Shape_PAD',0,3,0

        store_data,'rat_a2t',data={x:shp.t,y:transpose(shp.fratio_a2t[0:1,indx])}
        ename='rat_a2t'
        options,ename,'ytitle',('flux ratio!c away/twd !c'+npa)
        options,ename,'labels',['35-60 eV','100-300 eV']
        options,ename,'labflag',1
        options,ename,'colors',[1,2]
        options,ename,'constant',[1.,0.75]
        ylim,ename,0,2.5,0
    endif
end
