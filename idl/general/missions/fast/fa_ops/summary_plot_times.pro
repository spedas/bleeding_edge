pro summary_plot_times, times = times, ptypes = ptypes, use_data = $
                        use_data, orbit_num= orbit_num,  $
                        splot_time = splot_time, test = test, fresh = $
                        fresh

catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    catch,/cancel
    return
endif
catch,/cancel

get_data,'splot_times',data=spt,index=index
if ((index gt 0) and not (keyword_set(fresh))) then begin
    times = spt.times
    splot_time = spt.length
    orbit_num = spt.onum
    ptypes = spt.types
    catch,/cancel
    return
endif

three_hours = 3.d*3600.d  
ilatpass = 60.                  ; abs(ILAT) must be greater than
                                ; ilatpass or else it's not a pass!

if not defined(splot_time) then begin
    splot_time = 20.d
endif
splot_sec = double(splot_time)*60.d

udtype = idl_type(use_data)
if udtype eq 'string' then begin
    if use_data eq '' then use_data = 0 ; pretend it wasn't set!
endif

if keyword_set(use_data) then begin
    handle = ((udtype eq 'string') or  $
              (udtype eq 'integer') or  $
              (udtype eq 'byte') or  $
              (udtype eq 'long'))
    struc = (udtype eq 'structure')
    
    case 1 of
        handle:begin
            if find_handle(use_data) gt 0 then begin
                get_data,use_data,data=tmp
                tstartdat = min(tmp.x)
                tstopdat = max(tmp.x)
            endif else begin
                message,'can''t find data in handle ' + $
                  ''+string(use_data),/continue
            endelse
        end
        struc:begin
            if missing_tags(use_data,'x',/quiet) eq 0 then begin
                tstartdat = min(use_data.x)
                tstopdat = max(use_data.x)
            endif else begin
                if missing_tags(use_data,'time',/quiet) eq 0 then begin
                    tstartdat = min(use_data.time)
                    tstopdat = max(use_data.time)
                endif else begin 
                    message,'need a TIME or X tag in USE_DATA ' + $
                      'structure...',/continue
                endelse
            endelse
        end
        else:begin
            message,'improper type for value of USE_DATA ' + $
              'keyword...',/continue
        end
    endcase
    tstart = tstartdat
    tstop = tstopdat
endif 

if (find_handle('spin_times') ne 0) then begin
    get_data,'spin_times',data=spin_times
    tstart = min(spin_times.x)
    tstop = max(spin_times.x)
    tstartdat = tstart
    tstopdat = tstop
endif else begin
    if not keyword_set(use_data) then begin
        hdr1032 = get_fa_fields('DataHdr_1032',/all)
        if hdr1032.valid then begin
            tstart = min(hdr1032.time,itmin)
            tstop = max(hdr1032.time,itmax)
            if not (((tstop - tstart) lt three_hours) and  $
                    (tstop gt tstart) and $
                    (itmin eq 0) and $
                    (itmax eq n_elements(hdr1032.time)-1L)) then begin 
                message,'Bad time tag! Patching...',/continue
                idlorb = getenv('IDLORBIT')
                if idlorb then begin
                    report_orbit = ' using IDLORBIT = '+ $
                      strcompress(idlorb,/remove_all)
                    idlorb = long(idlorb)
                    message,report_orbit
                    load_correct_orbit,tstart,tstop,orbit
                    tstartdat = tstart
                    tstopdat = tstop
                endif else begin
                    message,'WARNING: using old unreliable time tag ' + $
                      'patch! Please setenv IDLORBIT!',/continue
                    tt = hdr1032.time
                    ntt = n_elements(tt)
                    medt = median(tt)
;
; is tstart too small?
;
                    while ((medt - tstart) gt three_hours/2.d) do begin
                        tt = [tt(0:itmin),tt(itmin:ntt-1)]
                        ntt = n_elements(tt)
                        medt = median(tt)
                        tstart = min(tt,itmin)
                    endwhile
;
; is tstop too large?        
;
                    tt = hdr1032.time
                    ntt = n_elements(tt)
                    while ((tstop - medt) gt three_hours/2.d) do begin
                        tt = [tt(0:itmax),tt(itmax:ntt-1)]
                        ntt = n_elements(tt)
                        medt = median(tt)
                        tstop = max(tt,itmax)
                    endwhile
                endelse 
                
                tstartdat = tstart
                tstopdat = tstop

            endif else begin
                message,'need to have FastFieldsMode1032 (DQD is ' + $
                  'DataHdr_1032) in shared memory...',/continue
                catch,/cancel
                return
            endelse
        endif  
    endif
endelse


neither_end = 0 
repeat begin
    get_fa_orbit,tstart,tstop,/no_store,struc=orb
    ilat = orb.ilat
    nilat = n_elements(ilat)
    ilatmin = min(ilat,mindex)
    ilatmax = max(ilat,maxdex)

    if (not((maxdex eq 0) or (maxdex eq nilat-1l)) and  $
        not((mindex eq 0) or (mindex eq nilat-1l))) then begin
        neither_end = 1
    endif else begin
        if (mindex eq 0) or (maxdex eq 0) then begin
            tstart = tstart- splot_sec
        endif
        if (mindex eq nilat-1l) or (maxdex eq nilat-1l) then begin
            tstop = tstop + splot_sec
        endif
    endelse
endrep until(neither_end)

t_ilatmin = orb.time(mindex)
t_ilatmax = orb.time(maxdex)

if neither_end then begin
;
;------------- Mcfadden time interpolation thing...
;
    f0 = ilat(mindex)
    fp = ilat(mindex+1)
    fm = ilat(mindex-1)
    dt = orb.time(mindex) - orb.time(mindex-1)
    denom = (fp+fm-2.*f0)
    if denom ne 0.0 then begin
        delta_t = (dt/2)*(fm-fp)/(fp+fm-2.*f0)
    endif else begin            ; not likely...
        delta_t = 0.0d
    endelse

    t_ilatmin = orb.time(mindex) + delta_t

    f0 = ilat(maxdex)
    fp = ilat(maxdex+1)
    fm = ilat(maxdex-1)
    dt = orb.time(maxdex) - orb.time(maxdex-1)
    denom = (fp+fm-2.*f0)
    if denom ne 0.0 then begin
        delta_t = (dt/2)*(fm-fp)/(fp+fm-2.*f0)
    endif else begin            ; not likely...
        delta_t = 0.0d
    endelse

    t_ilatmax = orb.time(maxdex) + delta_t
;
;---------------end Mcfadden interpolation
;
    tis = t_ilatmin - splot_sec
    tos = t_ilatmin
    tin = t_ilatmax - splot_sec
    ton = t_ilatmax

endif else begin                ; instrument not functioning at both ilat
                                ; extremes
    tis = -1.d & tos = -1.d & tin = -1.d & ton = -1.d

    if maxdex eq 0 then begin
        if ilat(maxdex) ge ilatpass then begin ; outbound North
            ton = t_ilatmax
        endif
    endif
    if maxdex eq nilat-1 then begin
        if ilat(maxdex) ge ilatpass then begin ; inbound North
            tin = t_ilatmax - splot_sec
        endif
    endif
    if mindex eq 0 then begin
        if ilat(mindex) le -ilatpass then begin ; outbound South
            tos = t_ilatmin
        endif
    endif
    if mindex eq nilat-1 then begin
        if ilat(mindex) le -ilatpass then begin ; inbound South
            tis = t_ilatmin - splot_sec
        endif
    endif
endelse
;
; make sure ilat extremes are extreme enough...
;
if ilatmax lt ilatpass then begin
    tin = -1.d
    ton = -1.d
endif
if ilatmin gt -ilatpass then begin
    tis = -1.d
    tos = -1.d
endif

times = [tis,tos,tin,ton]
ptypes = ['is','os','in','on']
pos = where(times gt 0.d, npos)
if npos eq 0 then begin
    message,'no data available!',/continue
    times=0
    ptypes = ''
endif else begin 
    times = times(pos)
    ptypes = ptypes(pos)
    st = sort(times)
    times = times(st)
    ptypes = ptypes(st)
endelse

good = where((times + splot_sec) ge tstartdat and (times le tstopdat),ngood)
if (ngood gt 0) then begin
    times = times(good)
    ptypes = ptypes(good)
    get_fa_orbit,times(0),times(ngood-1)+splot_sec
endif else begin
    if npos gt 0 then message,'no data available!',/continue
    times = 0
    ptypes = ''
endelse

nilat = n_elements(ilat)
ilatmin = min(ilat,mindex)
ilatmax = max(ilat,maxdex)


get_data,'ORBIT',data=tmp
orbit_num1=orb.orbit(mindex)
orbit_num2=orb.orbit(maxdex)

if orbit_num1 eq orbit_num2 then begin
    orbit_num = strcompress(string(orbit_num1),/remove_all)
endif else begin
    message,'YIKES! Data from more than one orbit! Returning ' + $
      'median orbit number...',/continue
    orbit_num=strcompress(string(fix(median(tmp.y))),/remove_all)
endelse

store_data,'spt',  data = {times:times, $
                           length:splot_time, $
                           onum:orbit_num, $
                           types:ptypes}

catch,/cancel
return

end






