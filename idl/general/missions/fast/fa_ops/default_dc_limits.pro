;+
;
; This code contains the default limits for DC fields summary
; plots. There are separate limits for electric field, magnetic field,
; probe current, spin angle, and spacecraft potential. Within those
; categories, the limits are all the same. 
;
; There are several choices for each limit, the data determine which
; choice is used. At least MIN_ON_SCALE of the points must be on
; scale, otherwise the next larger choice is tried. 
;
;-

function pick_limits, name, choices, tstart, tstop, positive=positive, $
                      frac_on_scale = frac_on_scale

if not defined(frac_on_scale) then frac_on_scale = 0.98

get_data,name,data=data,index=index

if ((index eq 0) or not defined(data)) then return,choices(0)

nx = n_elements(data.x)
in_range = lindgen(nx)
if defined(tstart) and defined(tstop) then begin
    in_range = select_range(data.x,tstart,tstop,nin)
    if nin eq 0 then begin
        message,'No '+name+' data in time range...',/continue
        return,choices(0)
    endif
endif

oktmp  = where(finite((data.y)(in_range)),nok)
if nok eq 0 then begin
    message,'all '+name+' data are NaN...',/continue
    return,choices(0)
endif
ok = in_range(oktmp)

val = data.y(ok)

nchoices = n_elements(choices)
fok = float(nok)
cc = choices(sort(choices))
i=-1
repeat begin
    i=i+1
    wos = select_range(val,-cc(i),cc(i),nos)
    fos = float(nos)
    on_scale = fos/fok
endrep until ((on_scale ge frac_on_scale) or (i eq nchoices-1l))

return,choices(i)
end

pro default_dc_limits,SDT = sdt, tstart = tstart, tstop = tstop


if keyword_set(sdt) then begin
    ex = 'Ex'
    ez = 'Ez'
    density = 'DENSITY'
    bx = 'Bx'
    by = 'By'
    bz = 'Bz'
    pot = 'S/C potential'
    s_ang = 'spin angle'
    mbar = 'fields_modebar'
endif else begin
    ex = 'EX'
    ez = 'EZ'
    density = 'DENSITY'
    bx = 'BX'
    by = 'BY'
    bz = 'BZ'
    pot = 'S/C POTENTIAL'
    s_ang = 'SPIN ANGLE'
    mbar = 'MODEBAR'
endelse

erange = 150.			; mV/m
brange = 500.			; nT
drange = 10000  		; nA
max_spin_angle = 10.		; degrees
prange = 50.			; volts

if (find_handle(ex) +  $
    find_handle(ez)) gt 0 then begin
    echoices = [10.,20.,50.,100.,200.,500.,1000.,2000.]
    erange = pick_limits(ex,echoices,tstart,tstop) > pick_limits(ez,echoices,tstart,tstop)
endif

if (find_handle(bx) +  $
    find_handle(by) +  $
    find_handle(bz)) gt 0 then begin
    bchoices = [10.,20.,50.,100.,200.,500.,1000.,2000.]
    brange = pick_limits(bx,bchoices,tstart,tstop) >  $
      (pick_limits(by,bchoices,tstart,tstop) >  $
       pick_limits(bz,bchoices,tstart,tstop))
endif

if find_handle(density) gt 0 then begin
    dchoices = [1.e+04,1.e+06]
    drange = pick_limits(density,dchoices,tstart,tstop)
endif

if find_handle(pot) gt 0 then begin
    pchoices = float([1,2,5,10,20,50,100])
    prange = pick_limits(pot,pchoices,tstart,tstop)
endif

if find_handle(s_ang) gt 0 then begin
    sachoices = float([1,2,5,10,20])
    max_spin_angle = pick_limits(s_ang,sachoices,tstart,tstop)
endif
    
if find_handle(ex) ne 0 then begin
    store_data,ex, $
      dlimit={yrange:[-1,1]*erange,yticks:4, $
              ytitle:'E (eq''ward) !C!C (mV/m)',ystyle:1}
endif

if find_handle(ez) ne 0 then begin
    store_data,ez, $
      dlimit={yrange:[-1,1]*erange,yticks:4, $
              ytitle:'E (near B) !C!C (mV/m)',ystyle:1}
endif

if find_handle(bx) ne 0 then begin
    store_data,bx, $
      dlimit={yrange:[-1,1]*brange,yticks:4, $
              ytitle:'dB (eq''ward) !C!C (nT)',ystyle:1}
endif

if find_handle(by) ne 0 then begin
    store_data,by, $
      dlimit={yrange:[-1,1]*brange,yticks:4, $
              ytitle:'dB (West) !C!C (nT)',ystyle:1}
endif

if find_handle(bz) ne 0 then begin
    store_data,bz, $
      dlimit={yrange:[-1,1]*brange,yticks:4, $
              ytitle:'dB (near B) !C!C ' + $
              '(nT)',ystyle:1}
endif

if find_handle(density) ne 0 then begin
    tic1str = strcompress(string(fix(alog10(drange)/2.)),/remove_all)
    tic2str = strcompress(string(fix(alog10(drange))),/remove_all)
    store_data,density, $
      dlimit={yrange:[1,drange], $
              ytitle:'N!Le!N !C!C!C (nA)', $
              yticks:4, ylog:1, yminor:1, $
              ytickvalue:[1,sqrt(drange),drange], $
              ytickname:['10!E0!N',' ', $
                         '10!E'+tic1str+'!N',' ', $
                         '10!E'+tic2str+'!N'], $
              ystyle:1}
endif

if find_handle(pot) ne 0 then begin
    store_data,pot, $
      dlimit={yrange:[-1,1]*prange, $
              ytitle:'S/C potential !C!C!C (volts)', $
              yticks:4, yminor:1,ystyle:1}
endif

if find_handle(s_ang) ne 0 then begin
    store_data,s_ang, $
      dlimit={yrange:[0,max_spin_angle],panel_size:0.5, $
              ytitle:'spin angle !C!C (abs deg)',yticks:2,ystyle:1}
endif

if find_handle(mbar) ne 0 then begin
    get_data,mbar,data=mbardat
    store_data,mbar, $
      dlimit={ystyle:1,panel_size:0.17, $
              yticks:1,ytickv:[0,1],ytickname:[' ',' '], $
              ytitle:' ',no_color_scale:1,y_no_interp:1, $
              spec:1, colors:[255b,127b],$
              zrange:[0,255],ticklen:0,x_no_interp:1}
endif 

return
end
