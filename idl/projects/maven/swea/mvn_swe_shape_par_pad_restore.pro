;+
;PROCEDURE:   mvn_swe_shape_par_pad_restore
;PURPOSE:
;  Reads in tplot save/restore files swe_shape_par_pad 
;  Command line used to create the tplot
;
;USAGE:
;  mvn_swe_shape_par_pad_restore, trange
;
;INPUTS:
;       trange:        Restore data over this time range.  If not specified, then
;                      uses the current tplot range or timerange() will be called
;
;KEYWORDS:
;       ORBIT:         Restore pad data by orbit number.
;
;       LOADONLY:      Download but do not restore any pad data.
;
; $LastChangedBy: xussui_lap $
; $LastChangedDate: 2016-10-11 14:11:51 -0700 (Tue, 11 Oct 2016) $
; $LastChangedRevision: 22085 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_shape_par_pad_restore.pro $
;
;CREATED BY:    Shaosui Xu  10-11-16
;FILE: mvn_swe_shape_par_pad_restore.pro
;-

Pro mvn_swe_shape_par_pad_restore,trange,orbit=orbit,loadonly=loadonly

;   Process keywords
    rootdir='maven/data/sci/swe/l3/swe_shape_par_pad/YYYY/MM/'
    fname = 'mvn_swe_shape_par_pad_YYYYMMDD.tplot'

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

    if(keyword_set(loadonly)) then begin
       print,''
       print,'Files found:'
       for i=0,nfiles do print,file[i],format='("  ",a)'
       print,''
       return
    endif

    tplot_restore,filename=file,/append
end
