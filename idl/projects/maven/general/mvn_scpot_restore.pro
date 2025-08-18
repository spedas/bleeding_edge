;+
;PROCEDURE:   mvn_scpot_restore
;PURPOSE:
;  Reads in save files mvn_swe_l3_scpot_YYYYMMDD_v??_r??, create tplot
;  varibles for s/c pot, store potential structures in results and/or full
;
;USAGE:
;  mvn_scpot_restore, trange
;
;INPUTS:
;       trange:        Restore data over this time range.  If not specified, then
;                      uses the current tplot range or timerange() will be called
;
;KEYWORDS:
;       ORBIT:         Restore mvn_swe_l3_scpot data by orbit number.
;
;       RESULTS:       Hold the structure of composited potentials
;
;       TPLOT:         Create tplot varibles for the composited s/c
;                      potentials as well as for all the available s/c pots
;
;       FULL:          Hold the structure of composited potentials and
;                      all other potential structures       
;
;       SUCCESS:       Set to 1 if valid potentials are found.
;       
; $LastChangedBy: hara $
; $LastChangedDate: 2024-02-23 14:47:10 -0800 (Fri, 23 Feb 2024) $
; $LastChangedRevision: 32458 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_scpot_restore.pro $
;
;CREATED BY:    Shaosui Xu  06-23-17
;FILE: mvn_scpot_restore
;-

Pro mvn_scpot_restore, trange, results=results, tplot=tplot, orbit=orbit, full=full, $
                       success=ok, no_server=no_server

    ok = 0

    ;   Process keywords
    rootdir='maven/data/sci/swe/l3/scpot/YYYY/MM/'
    fname = 'mvn_swe_l3_scpot_YYYYMMDD_v??_r??.sav'

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
    file = mvn_pfp_file_retrieve(rootdir+fname,trange=[tmin,tmax],/daily_names,no_server=no_server)
    nfiles = n_elements(file)

    finfo = file_info(file)
    indx = where(finfo.exists,nfiles,comp=jndx,ncomp=n)

    for j=0,n-1 do print,'File not found:',file[jndx[j]]
    if (nfiles eq 0) then begin
       results=0
       return
    endif
    file = file[indx]

    restore,filename=file[0]
    str0 = mvn_scpot.pot_comp[0]
    str0.time = 0.d
    pot_comp = replicate(str0,45000.*nfiles)
    str1 = mvn_scpot.pot_swepos[0]
    str1.time = 0.d
    pot_swelpw = replicate(str1,45000.*nfiles)
    pot_swepos = pot_swelpw
    pot_sweneg = pot_swelpw
    pot_sta    = pot_swelpw
    pot_sweshdw = pot_swelpw
    ct1 = 0
    ct2 = 0
    ct3 = 0
    ct4 = 0
    ct5 = 0
    ct6 = 0
    for j=0,nfiles-1 do begin
       restore,filename=file[j]

       npt1 = n_elements(mvn_scpot.pot_comp)
       pot_comp[ct1:ct1+npt1-1] = mvn_scpot.pot_comp
       ct1 = ct1 + npt1
       ;; pot_comp=[temporary(pot_comp),mvn_scpot.pot_comp]
       
       npt2 = n_elements(mvn_scpot.pot_swelpw)
       pot_swelpw[ct2:ct2+npt2-1] = mvn_scpot.pot_swelpw
       ct2 = ct2 + npt2
       ;; pot_swelpw=[temporary(pot_swelpw),mvn_scpot.pot_swelpw]       
       
       npt3 = n_elements(mvn_scpot.pot_swepos)
       pot_swepos[ct3:ct3+npt3-1] = mvn_scpot.pot_swepos
       ct3 = ct3 + npt3
       ;; pot_swepos=[temporary(pot_swepos),mvn_scpot.pot_swepos]       

       npt4 = n_elements(mvn_scpot.pot_sweneg)
       pot_sweneg[ct4:ct4+npt4-1] = mvn_scpot.pot_sweneg
       ct4 = ct4 + npt4
       ;; pot_sweneg=[temporary(pot_sweneg),mvn_scpot.pot_sweneg]       

       npt5 = n_elements(mvn_scpot.pot_sta)
       pot_sta[ct5:ct5+npt5-1] = mvn_scpot.pot_sta
       ct5 = ct5 + npt5
       ;; pot_sta=[temporary(pot_sta),mvn_scpot.pot_sta]       

       npt6 = n_elements(mvn_scpot.pot_sweshdw)
       pot_sweshdw[ct6:ct6+npt6-1] = mvn_scpot.pot_sweshdw
       ct6 = ct6 + npt6
       ;; pot_sweshdw=[temporary(pot_sweshdw),mvn_scpot.pot_sweshdw]
       
    endfor
    
    ;trim data
    intx=where(pot_comp.time ge tmin and pot_comp.time le tmax)
    pot_comp=pot_comp[intx]
    intx=where(pot_swelpw.time ge tmin and pot_swelpw.time le tmax)
    pot_swelpw=pot_swelpw[intx]
    intx=where(pot_swepos.time ge tmin and pot_swepos.time le tmax)
    pot_swepos=pot_swepos[intx]
    intx=where(pot_sweneg.time ge tmin and pot_sweneg.time le tmax)
    pot_sweneg=pot_sweneg[intx]
    intx=where(pot_sta.time ge tmin and pot_sta.time le tmax)
    pot_sta=pot_sta[intx]
    intx=where(pot_sweshdw.time ge tmin and pot_sweshdw.time le tmax)
    pot_sweshdw=pot_sweshdw[intx]

    scpot={pot_comp:pot_comp, pot_swelpw:pot_swelpw,$
                       pot_swepos:pot_swepos, pot_sweneg:pot_sweneg,$
                       pot_sta:pot_sta,pot_sweshdw:pot_sweshdw}
    results=scpot.pot_comp
    full=scpot
    ok = 1
    
    if(keyword_set(tplot)) then begin
       ;tplot variable "scpot_comp"
       varname=scpot.pot_comp[0].pot_name
       varname=['pot_swelpw','pot_swepos','pot_sweneg','pot_staneg','pot_sweshdw']
       clr=[!p.color,2,6,4,1]
       nv=n_elements(varname)
       for i=0,nv-1 do begin
          x=scpot.pot_comp.time
          y=replicate(!values.f_nan,n_elements(x))
          inx=where(scpot.pot_comp.method eq i+1,cts)
          if cts gt 0L then begin
             y[inx]=scpot.pot_comp[inx].potential
             store_data,varname[i],data={x:x,y:y}
             ename=varname[i]
             options,ename,'color',clr[i]            
          endif

          x=scpot.(i+1).time
          y=scpot.(i+1).potential
          store_data,varname[i]+'_full',data={x:x,y:y}
          ename=varname[i]+'_full'
          options,ename,'color',clr[i]
          options,ename,'psym',3
       endfor
       store_data,'swe_pot_lab',data={x:[tmin,tmax],$
                                      y:replicate(!values.f_nan,2,5)}
       options,'swe_pot_lab','labels',$
               ['swe-(sh)','sta','swe-','swe+','swe/lpw']
       options,'swe_pot_lab','colors',[1,4,6,2,!p.color]
       options,'swe_pot_lab','labflag',1

       store_data,'scpot_comp',data=[varname,'swe_pot_lab']                           
       vname='scpot_comp'
       options,vname,'constant',[-1,1]
       options,vname,'ytitle','S/C Pot Comp.!cVolts'

       ;tplot variable "scpot_all"
       store_data,'scpot_all',data=[varname[*]+'_full','swe_pot_lab']
       vname='scpot_all'
       options,vname,'constant',[-1,1]
       options,vname,'ytitle','S/C Pot !cVolts'
    endif
end
