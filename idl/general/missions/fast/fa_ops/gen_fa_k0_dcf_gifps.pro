pro draw_zero_lines,names,EXCLUDE=exclude

if not defined(exclude) then exclude = ''

tzero = [0.,1.d19] ; good for a few hundred billion years or so...
zero = [0.,0.]

for i=0,n_elements(names)-1L do begin
    if (((where(names(i) eq exclude))(0) lt 0) and  $
        (find_handle(names(i)) gt 0)) then begin
        tplot_panel,var=names(i),delta=dt
        oplot,tzero,zero,linestyle=1
    endif
endfor


return
end
;
;
;
pro gen_fa_k0_dcf_gifps,dcnamesc, $
                        times=times,ptypes=ptypes,splot_time=splot_time, $
                        single=single, sdt = sdt, screen=screen, $
                        default_table = default_table, ps_table = $
                        ps_table

if not defined(default_table) then default_table = 39
if not defined(ps_table) then ps_table = 42

old_device = !d.name
old_window = !d.window
old_charsize = !p.charsize
old_ycharsize = !y.charsize

!p.charsize = 0.7

xgifsize = 512
ygifsize = 768
tplot_options,'xmargin',[12,15]  ; left and right x-margins, in chars

if keyword_set(sdt) then begin
    default_dc_names = $ 
      ['Ex','Ez','DENSITY','Bx','By','Bz', $
       'spin_angle','S/C potential','fields_modebar']
    mbarname = 'fields_modebar'
endif else begin
    default_dc_names = $ 
      ['EX','EZ','DENSITY','BX','BY','BZ', $
       'S/C POTENTIAL','SPIN ANGLE','MODEBAR']
    mbarname = 'MODEBAR'
endelse    

if not defined(dcnamesc) then begin
    dcnamesc = default_dc_names
endif

if (where(dcnamesc eq mbarname))(0) lt 0 then begin
    dcnames = [dcnamesc,mbarname]
endif else begin
    dcnames = dcnamesc
endelse

valid_names = bytarr(n_elements(dcnames))



if not keyword_set(splot_time) then splot_time = 20.d ; minutes
splot_sec = splot_time * 60.d

if not keyword_set(ptypes) then begin
    get_data,'spt',index=index,data=spt
    if index eq 0 then begin
        ptypes = 'oo'
        message,'WARNING: no plot types defined...',/continue
    endif else begin
        splot_sec = spt.length * 60.d
        ptypes = spt.types
        times = spt.times
        orbit_num = spt.onum
    endelse
endif

dcnamebase = 'dcfields'
tstop = 0.d
tstart = str_to_time('2001-01-01/00:00')


if not defined(times) then begin
    for i=0,n_elements(dcnames)-1l do begin
        get_data,dcnames(i),data=tmp,index=index
        if index ne 0 then begin
            tmpmin = min(tmp.x)
            tmpmax = max(tmp.x)
            
            if tmpmin lt tstart then tstart = tmpmin
            if tmpmax gt tstop  then tstop = tmpmax
            
        endif
    endfor
    times = [tstart]
    splot_time = [tstop-tstart]
endif else begin
    tstart = min(times)
    tstop = max(times) + splot_time
endelse

for i=0,n_elements(dcnames)-1l do begin
    get_data,dcnames(i),data=tmp,index=index
    if index ne 0 then valid_names(i) = 1b
endfor
do_plot = where(valid_names,ndo)
if ndo eq 0 then begin
    message,'No valid tplot names found!',/continue
    return
endif

if not defined(orbit_num) then begin
    if find_handle('ORBIT') eq 0 then begin
        get_fa_orbit,tstart,tstop
    endif 

    get_data,'ORBIT',data=onum
    if ((tstart gt max(onum.x)) or (tstop lt min(onum.x))) then begin
        get_fa_orbit,tstart,tstop
        get_data,'ORBIT',data=onum
    endif

    if ((max(onum.y) ne min(onum.y)) and $
        not keyword_set(single)) then begin
        orbit_num = strcompress(string(fix(min(onum.y)))+'-' $
                                +string(fix(max(onum.y))),/remove_all)
    endif else begin
        orbit_num = strcompress(onum.y(0),/remove_all)
    endelse
endif


get_data,mbarname,data=mbar,dlimit=mbardlim

if keyword_set(screen) then begin
    set_plot,'X'
    device,window_state=window_state
    use_window = min(where(window_state eq 0))
    window,use_window, xsize=xgifsize, ysize=ygifsize
endif else begin
    set_plot,'z'
    device,set_resolution=[xgifsize,ygifsize]
endelse

nptypes = n_elements(ptypes)
for j=1,nptypes do begin
    i = j-1
    timespan,times(i),splot_time,/minutes
    get_fa_orbit,times(i),times(i)+splot_sec
    dcfile = dcnamebase+'_'+orbit_num+'_'+ptypes(i)
    if dcnames(0) then begin    ; produce DC page...
        get_data,dcnames(0),data=chk,index=index
        if index ne 0 then begin
            plot_pick = $
              select_range(chk.x,times(i),times(i)+splot_sec)
            if plot_pick(0) ge 0 then begin 
                all_set = (where(finite(chk.y(plot_pick))))(0) ge 0
            endif else begin
                all_set = 0
            endelse
        endif else begin
            all_set = 0
        endelse
        
        if all_set then begin
            default_dc_limits,sdt=sdt, $
              tstart=times(i),tstop=times(i)+splot_sec
            options,dcnames(do_plot),'ystyle',1
            options,dcnames(do_plot),'xstyle',1
            popen,dcfile,ctable=ps_table,/port
            tplot,dcnames(do_plot),var_label=['MLT','ALT','ILAT'],title='FAST DC ' + $
              'Fields: Orbit '+orbit_num
            draw_zero_lines,dcnames,exclude=mbarname
            
            if find_handle(mbarname) gt 0 then begin
                annotate_modebar,sdt=sdt
            endif
            pclose
            
            loadct2,default_table
            tplot
            draw_zero_lines,dcnames,exclude=mbarname
            
            if find_handle(mbarname) gt 0 then begin
                annotate_modebar,sdt=sdt
            endif
            makegif,dcfile
        endif
    endif 
endfor

if keyword_set(screen) then wdelete,use_window
set_plot,old_device
if old_window gt 0 then wset,old_window
!p.charsize = old_charsize
!y.charsize = old_ycharsize

return
end



