


function mav_sep_science_decom,msg,hkppkt=hkp, last=last, memdump=memdump

    if msg.valid eq 0 then return,0  ; fill_nan(last)

    tot = total(msg.data)
    mapid = keyword_set(hkp) ? hkp.mapid : 0b
    mem_addr = keyword_set(hkp) ? hkp.mem_addr : 0u
    event_cntr  = keyword_set(hkp) ? hkp.event_cntr : 0u
    diff_cntr  = keyword_set(last)  ? fix(tot)-fix(last.event_cntr) : 0

    pp = find_mpeaks(msg.data,threshold = 40,roiw=4,fitval=0,verbose=0)
    npp = n_elements(pp.g)
    p = pp.g[0]

if 0 then begin
    mp = mgauss(binsize = 1)
    mp.g.a  = p.a
    mp.g.x0 = p.x0
    mp.g.s  = p.s
    b = indgen(256)
;    w = where(
;    fit, msg.data[
endif

if keyword_set(memdump) then ranges=reform(memdump.range,2,12) else  ranges = transpose( [[indgen(12)*20],[indgen(12)*20+19]] )

if 1 then begin
    n = 12
    psum = fltarr(n)
    for i = 0,12-1 do   psum[i] = total(msg.data[ranges[0,i]:ranges[1,i] ])
;    psum = total(reform([msg.data,[0,0,0,0]],10,26),1)
;    dprint,/phelp,dwait=5,psum
endif

dprint,dlevel=4,transpose(ranges)
tdiff = msg.time-systime(1)
dprint,dlevel=4,byte(round(psum[0:11]))
if 1  && abs(tdiff) lt 10 then begin
    labels = strsplit('O T OT F FT FTO',' ',/extract)
    labels = transpose( [[labels+'_0'],[labels+'_1']] ) +'_'
    w = where(psum ge 1,nw)
    if nw eq 1 then begin
        prefix='multiples/'+labels[w[0]]
        if strpos(prefix,'T') ge 0 then begin
;            tek_screen_shot,prefix=prefix,filename=filename,window=7
            dprint,prefix,dlevel=3
        endif
    endif
endif



  ;  dprint,p.x0
    strct = {time      :    msg.time,      $
            mapid      :    mapid   ,  $
            mem_addr   :    mem_addr ,  $
            data       :    msg.data ,  $
            psum       :    psum,  $
            event_cntr :    event_cntr ,   $
            diff_cntr  :    diff_cntr  ,   $
            total      :    tot, $
            A      :    p.a   ,  $
            x0     :    p.x0  , $
            s      :    p.s   ,  $
            valid      :    msg.valid   }

    return,strct
end



