pro gen_fa_k0_acf_gifps,acnames,times=times,ptypes=ptypes, $
                        splot_time=splot_time, $
                        single = single,sdt = sdt,$
                        default_table=default_table,  $
                        ps_table=ps_table, screen = screen

if keyword_set(sdt) then begin
    default_names = ['HF E','VLF E','ELF E', $
                     'HF B','VLF B','ELF B', $
                     'HF PWR','BBFE','VLF PWR','LFFE','ELF PWR', $
                     'BBFB','LFFB','fields_modebar','w_ce','w_cp']
    hfquants = ['HF E','HF B']
    elfquants =['ELF E','ELF B']
    hpwr = 'HF PWR'
    vpwr = 'VLF PWR'
    epwr = 'ELF PWR'
    bq = 'fields_modebar'
endif else begin
    default_names = ['HF_E_SPEC','VLF_E_SPEC','ELF_E_SPEC', $
                     'HF_B_SPEC','VLF_B_SPEC','ELF_B_SPEC', $
                     'HF_PWR','BBFE','VLF_PWR','LFFE','ELF_PWR', $
                     'BBFB','LFFB','MODEBAR','w_ce','w_cp']
    hfquants = ['HF_E_SPEC','HF_B_SPEC']
    elfquants =['ELF_E_SPEC','ELF_B_SPEC']
    hpwr = 'HF_PWR'
    vpwr = 'VLF_PWR'
    epwr = 'ELF_PWR'
    bq = 'MODEBAR'
endelse

tplot_options,'xmargin',[12,15] ; left and right x-margins, in chars

time_stamp,/off

if not defined(default_table) then default_table = 39 ; rainbow and white

ndn = n_elements(default_names)

old_device = !d.name
old_window = !d.window
old_charsize = !p.charsize
old_ycharsize = !y.charsize

!p.charsize = 0.7

xgifsize = 512
ygifsize = 768
epwr_lab = 'E!E2!N (mV/m)!E2!N'
bpwr_lab = 'B!E2!N nT!E2!N'

if not defined(acnames) then begin
    acnames = ''
    for i=0,ndn-1l do begin
        if find_handle(default_names(i)) ne 0 then begin
            acnames = [acnames,default_names(i)]
        endif
    endfor
    nacn = n_elements(acnames)
    if nacn gt 1 then begin
        acnames = acnames(1:nacn-1l)
    endif else begin
        message,'need to load AC fields ' + $
          'quantities...',/continue
        return
    endelse
endif

bar_set = (where(acnames eq bq))(0) ge 0
if not bar_set then acnames = [acnames,bq]

wce_spot = (where(acnames eq 'w_ce'))
wce_set = wce_spot(0) gt 0
wcp_spot = (where(acnames eq 'w_cp'))
wcp_set = wcp_spot(0) gt 0

if wce_spot(0) gt 0 then begin
    acnames = acnames(where(acnames ne 'w_ce'))
endif
if wcp_spot(0) gt 0 then begin
    acnames = acnames(where(acnames ne 'w_cp'))
endif

;
; Now clean up the acnames, remove undefined names...(names which have
; not been loaded)
;
nacn = n_elements(acnames)
good_names = [' ']
for i=0,nacn-1l do begin
    if find_handle(acnames(i)) ne 0 then good_names = $
      [good_names,acnames(i)]
endfor
acnames = good_names(1:n_elements(good_names)-1l)
nacn = n_elements(acnames)
    

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
    endelse
endif

acnamebase = 'acfields'
tstop = 0.d
tstart = str_to_time('2001-01-01/00:00')

if not defined(times) then begin
    for i=0,n_elements(acnames)-1l do begin
        get_data,acnames(i),data=tmp,index=index
        if index ne 0 then begin
            tmpmin = min(tmp.x)
            tmpmax = max(tmp.x)
            
            if tmpmin lt tstart then tstart = tmpmin
            if tmpmax gt tstop  then tstop = tmpmax
        endif
    endfor
    times = [tstart]
    splot_time = [tstop-tstart]/60.d
endif else begin
    tstart = min(times)
    tstop = max(times) + splot_time
endelse

if find_handle('orbit') eq 0 then begin
    get_fa_orbit,tstart,tstop
endif 

get_data,'orbit',data=onum
if ((tstart gt max(onum.x)) or (tstop lt min(onum.x))) then begin
    get_fa_orbit,tstart,tstop
    get_data,'orbit',data=onum
endif

if ((max(onum.y) ne min(onum.y)) and $
    not keyword_set(single)) then begin
    orbit_num = strcompress(string(fix(min(onum.y)))+'-' $
                            +string(fix(max(onum.y))),/remove_all)
endif else begin
    orbit_num = strcompress(fix(median(onum.y)),/remove_all)
endelse

get_data,bq,data=mbar,dlimit=mbardlim


if keyword_set(screen) then begin
    set_plot,'X'
    device,window_state=window_state
    use_window = min(where(window_state eq 0))
    window,use_window, xsize=xgifsize, ysize=ygifsize
endif else begin
    set_plot,'z'
    device,set_resolution=[xgifsize,ygifsize]
endelse

default_ac_limits, SDT = sdt

nptypes = n_elements(ptypes)
for j=1,nptypes do begin
    i = j-1
    timespan,times(i),splot_time,/minutes
    get_fa_orbit,times(i),times(i)+splot_sec
    acfile = acnamebase+'_'+orbit_num+'_'+ptypes(i)
    if acnames(0) then begin    ; produce AC page
        get_data,acnames(0),data=chk,index=index
        
        all_set = 0
        npp = 0
        if index ne 0 then begin
            plot_pick = $
              select_range(chk.x,times(i),times(i)+splot_sec,npp)
        endif 
        all_set = npp gt 0 
        
        if all_set then begin
            options,acnames,'ystyle',1
            options,acnames,'xstyle',1
            
            popen,acfile,ctable=ps_table,/port
            tplot,acnames,var_label=['MLT','ALT','ILAT'],title='FAST AC ' + $
              'Fields: Orbit '+orbit_num

            for ihfquants=0,1 do begin
                if ((find_handle(hfquants(ihfquants)) gt 0) and wce_set) then begin
                    tplot_panel,variable=hfquants(ihfquants),oplotvar='w_ce'
                endif
            endfor
            for ielfquants=0,1 do begin
                if ((find_handle(elfquants(ielfquants)) gt 0) and wcp_set) then begin
                    tplot_panel,variable=elfquants(ielfquants),oplotvar='w_cp'
                endif
            endfor
            
            if find_handle(hpwr) ne 0 then begin
                get_data,hpwr,dlim=dlim 
                tplot_panel,var=hpwr
                axis,yaxis=1,ytickv=dlim.ytickv,ytickname=dlim.yname2, $
                 yticks=dlim.yticks
            endif
            if find_handle(vpwr) ne 0 then begin
                get_data,vpwr,dlim=dlim 
                tplot_panel,var=vpwr
                axis,yaxis=1,ytickv=dlim.ytickv,ytickname=dlim.yname2, $
                  yticks=dlim.yticks
                annotate_power,sdt=sdt
            endif
            if find_handle(epwr) ne 0 then begin
                get_data,epwr,dlim=dlim 
                tplot_panel,var=epwr
                axis,yaxis=1,ytickv=dlim.ytickv,ytickname=dlim.yname2, $
                  yticks=dlim.yticks
            endif
            
            
            if find_handle(bq) ne 0 then begin
                annotate_modebar,sdt=sdt
            endif
            pclose
            
            loadct2,default_table
            tplot
            for ihfquants=0,1 do begin
                if ((find_handle(hfquants(ihfquants)) gt 0) and wce_set) then begin
                    tplot_panel,variable=hfquants(ihfquants),oplotvar='w_ce'
                endif
            endfor
            for ielfquants=0,1 do begin
                if ((find_handle(elfquants(ielfquants)) gt 0) and wcp_set) then begin
                    tplot_panel,variable=elfquants(ielfquants),oplotvar='w_cp'
                endif
            endfor
            
            if find_handle(hpwr) ne 0 then begin
                get_data,hpwr,dlim=dlim 
                tplot_panel,var=hpwr
                axis,yaxis=1,ytickv=dlim.ytickv,ytickname=dlim.yname2, $
                 yticks=dlim.yticks
            endif
            if find_handle(vpwr) ne 0 then begin
                get_data,vpwr,dlim=dlim 
                tplot_panel,var=vpwr
                axis,yaxis=1,ytickv=dlim.ytickv,ytickname=dlim.yname2, $
                  yticks=dlim.yticks
                annotate_power,sdt=sdt
            endif
            if find_handle(epwr) ne 0 then begin
                get_data,epwr,dlim=dlim 
                tplot_panel,var=epwr
                axis,yaxis=1,ytickv=dlim.ytickv,ytickname=dlim.yname2, $
                  yticks=dlim.yticks
            endif

            if find_handle(bq) ne 0 then begin
                 annotate_modebar,sdt=sdt
            endif
            makegif,acfile
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
