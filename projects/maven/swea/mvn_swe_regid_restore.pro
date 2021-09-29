;+
;PROCEDURE:   mvn_swe_regid_restore
;PURPOSE:
;  Reads in save files mvn_swia_regid
;
;USAGE:
;  mvn_swe_regid_restore, trange
;
;INPUTS:
;       trange:        Restore data over this time range.  If not
;                      specified, then uses the current tplot range
;                      or timerange() will be called
;
;KEYWORDS:
;       ORBIT:         Restore mvn_swia_regid data by orbit number.
;
;       RESULTS:       Hold the full structure of region id
;
;       TPLOT:         Create tplot varible for region id "reg_id"
;       
; $LastChangedBy: xussui $
; $LastChangedDate: 2018-07-18 12:28:53 -0700 (Wed, 18 Jul 2018) $
; $LastChangedRevision: 25488 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_regid_restore.pro $
;
;CREATED BY:    Shaosui Xu  11-17-17
;FILE: mvn_swe_regid_restore
;-

Pro mvn_swe_regid_restore,trange,results=results,tplot=tplot,orbit=orbit

    ;   Process keywords
    rootdir='maven/data/sci/swe/l3/swia_regid/YYYY/MM/'
    fname = 'mvn_swia_regid_YYYYMMDD_v??_r??.sav'

    if keyword_set(orbit) then begin
        imin = min(orbit, max=imax)
        trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
     endif

    tplot_options,get_opt=topt
    tspan_exists = (max(topt.trange_full) gt time_double('2014-12-01'))
    if((size(trange,/type) eq 0) and tspan_exists) then $
        trange=topt.trange_full

    if (size(trange,/type) eq 0) then begin
       print,"You must specify a time or orbit range."
       return
    endif

    ;if(size(trange,/type) eq 0) then trange=timerange()

    tmin = min(time_double(trange),max=tmax)
    file = mvn_pfp_file_retrieve(rootdir+fname,trange=[tmin,tmax],/daily_names)
    nfiles = n_elements(file)

    finfo = file_info(file)
    indx = where(finfo.exists,nfiles,comp=jndx,ncomp=n)

    for j=0,n-1 do print,'File not found:',file[jndx[j]]
    if (nfiles eq 0) then begin
       results=0
       return
    endif
    file = file[indx]

    str={time:0.d,id:-1}
    id=replicate(str,25000.*nfiles)
    ct=0
    for j=0,nfiles-1 do begin
        restore,filename=file[j]
        ;if (size(id, /type) eq 0) then id=regid $
        ;   else id=[temporary(id),regid]

        npt=n_elements(regid.time)
        id[ct:ct+npt-1]=regid
        ct=ct+npt

     endfor
    intx=where(id.time ge tmin and id.time le tmax,count)
    if (count eq 0) then begin
       results=0
       return
    endif
    id=id[intx]
    results=id

    if (keyword_set(tplot)) then begin
       store_data,'reg_id',data={x:id.time,y:id.id}
       options,'reg_id','psym',4
       options,'reg_id','symsize',0.35
       ylim,'reg_id',-1,6

       y = replicate(0.,n_elements(id.time),2)
       indx = where(id.id eq 1, count)
       if (count gt 0L) then y[indx,*] = 1.

       bname = 'sw_bar'
       store_data,bname,data={x:id.time, y:y, v:[0,1]}
       ylim,bname,0,1,0
       zlim,bname,-0.5,3.5,0 ; optimized for color table 43
       options,bname,'spec',1
       options,bname,'panel_size',0.05
       options,bname,'ytitle',''
       options,bname,'yticks',1
       options,bname,'yminor',1
       options,bname,'no_interp',1
       options,bname,'xstyle',4
       options,bname,'ystyle',4
       options,bname,'no_color_scale',1
    endif

end
