;+
;PROCEDURE:   mvn_scpot_comp_dailysave
;PURPOSE:
;
;USAGE:
;  mvn_scpot_comp_dailysave,start_day=start_day,end_day=end_day,ndays=ndays
;
;INPUTS:
;       None
;
;KEYWORDS:
;       start_day:     Save data over this time range.  If not
;                      specified, then timerange() will be called
;
;       end_day:       The end day of intented time range 
;
;       ndays:         Number of dates to process. Will be overwritten
;                      if start_day & end_day are given. If both
;                      end_day and ndays are not specified, ndays=7
;
;
; $LastChangedBy: xussui $
; $LastChangedDate: 2025-04-10 11:39:12 -0700 (Thu, 10 Apr 2025) $
; $LastChangedRevision: 33251 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_scpot_comp_dailysave.pro $
;
;CREATED BY:    Shaosui Xu, 08/01/2017
;FILE: mvn_scpot_comp_dailysave.pro
;-

Pro mvn_scpot_comp_dailysave,start_day=start_day,end_day=end_day,ndays=ndays

    @mvn_swe_com
    @mvn_scpot_com

    dpath=root_data_dir()+'maven/data/sci/swe/l3/scpot/'
    froot='mvn_swe_l3_scpot_'
    vr='_v00_r01'
    oneday=86400.D

    if (size(ndays,/type) eq 0 and size(end_day,/type) eq 0) then ndays = 7
    dt = oneday

    if (size(start_day,/type) eq 0) then begin
       tr = timerange()
       start_day = tr[0]
       ndays = floor( (tr[1]-tr[0])/oneday )
    endif

    start_day2 = time_double(time_string(start_day,prec=-3))
    if (size(end_day,/type) ne 0 ) then $
       end_day2 = time_double(time_string(end_day,prec=-3)) $
    else end_day2 = time_double(time_string(start_day2+ndays*oneday,prec=-3))

    dt = end_day2 - start_day2
    nday = floor(dt/oneday)

    print,start_day2,end_day2,nday

    for j=0L,nday-1L do begin
        tst = start_day2+j*oneday
        print,j,' ',time_string(tst)
        tnd = tst+oneday
        opath = dpath + time_string(tst,tf='YYYY/MM/')
        file_mkdir2, opath, mode='0775'o ;create directory structure, if needed
        ofile = opath+froot+time_string(tst+1000.,tf='YYYYMMDD')+vr+'.sav'
        
        timespan,tst,1
        mvn_swe_spice_init,/force
        mvn_swe_clear
        mvn_swe_load_l2, apid=['a4']
        mvn_swe_stat, /silent, npkt=npkt
        if max(npkt) gt 0 then begin
            maven_orbit_tplot,/load,/shadow
            mvn_scpot, comp=0, shapot=1
            ; don't restore composite -> force a new calculation
            ; calculating potentials in the shadow
            pot_name=['-1: Invalid', '0: Manual', $
                      '1: pot_swelpw','2: pot_swepos','3: pot_sweneg',$
                      '4: pot_sta','5: pot_sweshdw']
            str1={time:0.d,potential:0.,method:-1,$
                  units_name:'V',pot_name:pot_name}
            
            pot_comp=replicate(str1,n_elements(mvn_sc_pot.time))
            pot_comp.time=mvn_sc_pot.time
            pot_comp.potential=mvn_sc_pot.potential
            pot_comp.method=mvn_sc_pot.method

            get_data,'mvn_swe_lpw_scpot_pol',data=pot,index=i
            str2={time:0d,potential:0.}
            if i gt 0 then begin              
               pot_swelpw=replicate(str2,n_elements(pot.x))
               pot_swelpw.time=pot.x
               pot_swelpw.potential=pot.y
            endif else begin
               pot_swelpw=replicate(str2,2)
               pot_swelpw.time=minmax(mvn_sc_pot.time)
               pot_swelpw.potential=[!values.f_nan,!values.f_nan]
            endelse

            get_data,'swe_pos',data=pot,index=i
            if i gt 0 then begin
               pot_swepos=replicate(str2,n_elements(pot.x))
               pot_swepos.time=pot.x
               pot_swepos.potential=pot.y
            endif else begin
               pot_swepos=replicate(str2,2)
               pot_swepos.time=minmax(mvn_sc_pot.time)
               pot_swepos.potential=[!values.f_nan,!values.f_nan]
            endelse

            get_data,'neg_pot',data=pot,index=i
            if i gt 0 then begin
               str2={time:0d,potential:0.}
               pot_sweneg=replicate(str2,n_elements(pot.x))
               pot_sweneg.time=pot.x
               pot_sweneg.potential=pot.y
            endif else begin
               pot_sweneg=replicate(str2,2)
               pot_sweneg.time=minmax(mvn_sc_pot.time)
               pot_sweneg.potential=[!values.f_nan,!values.f_nan]
            endelse   

            get_data,'mvn_sta_c6_scpot',data=pot,index=i
            if i gt 0 then begin
               str2={time:0d,potential:0.}
               pot_sta=replicate(str2,n_elements(pot.x))
               pot_sta.time=pot.x
               pot_sta.potential=pot.y
            endif else begin
               pot_sta=replicate(str2,2)
               pot_sta.time=minmax(mvn_sc_pot.time)
               pot_sta.potential=[!values.f_nan,!values.f_nan]
            endelse  

            get_data,'pot_inshdw',data=pot,index=i
            if i gt 0 then begin
               str2={time:0d,potential:0.}
               pot_sweshdw=replicate(str2,n_elements(pot.x))
               pot_sweshdw.time=pot.x
               pot_sweshdw.potential=pot.y
            endif else begin
               pot_sweshdw=replicate(str2,2)
               pot_sweshdw.time=minmax(mvn_sc_pot.time)
               pot_sweshdw.potential=[!values.f_nan,!values.f_nan]
            endelse


            mvn_scpot={pot_comp:pot_comp, pot_swelpw:pot_swelpw,$
                       pot_swepos:pot_swepos, pot_sweneg:pot_sweneg,$
                       pot_sta:pot_sta,pot_sweshdw:pot_sweshdw}
            save,mvn_scpot,file=ofile,/compress
            spawn,'chgrp maven '+ofile
            file_chmod, ofile, '0664'o
            ;spawn,'chmod g+w '+ofile
        endif
    endfor

end
