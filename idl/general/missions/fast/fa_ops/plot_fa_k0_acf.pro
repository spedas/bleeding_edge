pro plot_fa_k0_acf,acnames

default_names = ['HF_E_SPEC','VLF_E_SPEC','ELF_E_SPEC', $
                 'HF_B_SPEC','VLF_B_SPEC','ELF_B_SPEC', $
                 'HF_E_PWR','BBFE','VLF_E_PWR','LFFE','ELF_E_PWR', $
                 'HF_B_PWR','BBFB','VLF_B_PWR','LFFB','ELF_B_PWR']

ndn = n_elements(default_names)

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
    splot_time = [tstop-tstart]
endif else begin
    tstart = min(times)
    tstop = max(times) + splot_time
endelse

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
    orbit_num = strcompress(fix(median(onum.y)),/remove_all)
endelse

if acnames(0) then begin        ; produce AC page
    options,acnames,'ystyle',1
    options,acnames,'xstyle',1
    tplot,acnames,var_label=['MLT','ALT','ILAT'],title='FAST AC ' + $
      'Fields: Orbit '+orbit_num
endif

return
end
