;	@(#)load_fields_modebar.pro	1.29	
pro load_fields_modebar,particles=particles


nhigh = 3l                      ; number of elements in mode bar column
best_burst_dqd = 'ADC_1054_Hdr'

if keyword_set(particles) then begin
    spin_per = 5.01
    get_data,'el_0',data=el0,index=index
    if index eq 0 then begin
        message,'Hey McFadden! Load up EL_0 before calling ' + $
          'LOAD_FIELDS_MODEBAR!!',/continue
        return
    endif
    spin_times = el0.x
    reduce_resolution,spin_times,spin_times,spin_per ; use dummy x-array for
                                ; now...
endif else begin
    get_data,'spin_times',data=st,index=index
    if index eq 0 then begin
        message,'Must have spin times loaded...',/continue
        return
    endif
    spin_times = st.x
endelse

nst = n_elements(spin_times)

; get_hsbmtimes
hsbm_times = [!values.d_nan]

catch,err_stat
if (err_stat ne 0) then begin
    case err_stat of 
        -151:begin
            print,err_stat
            message ,'Must have HSBM header loaded by ' + $
              'SDT...',/continue
            goto,get_mode_hdr
        end
        else:begin
            print,err_stat
            if passed_hsbm eq 0 then goto,get_mode_hdr
            message,!err_string,/continue
            catch,/cancel
            return
        end
    endcase
endif
passed_hsbm = 0
get_fa_hsbm_hdr,hsbm_times
passed_hsbm = 1

get_mode_hdr: catch,/cancel
hdr = get_fa_fields('DataHdr_1032',/all)
if not hdr.valid then begin
    message,'Must have 1032 header loaded by SDT...',/continue
    return
endif


tfs = hdr.time
fs = interp(byte(reform(hdr.comp1(4,*))) and 7b,tfs,spin_times)
fmode = interp(byte(reform(hdr.comp1(13,*))),tfs,spin_times)

fast_survey = where(fs lt 6,nfs) 
slow_survey = where(fs ge 6,nss)
back_orbit = where(fmode eq 255,nbo)


;max_color = !d.n_colors
max_color = 255b
boc = 0b
ssc = max_color/2b
fsc = max_color
hsbm_color = max_color

mbar = bytarr(nst,nhigh)
speeds = strarr(nst)
if nfs gt 0 then begin
    mbar(fast_survey,*) = fsc
    speeds(fast_survey) = 'fast'
endif
if nss gt 0 then begin
    mbar(slow_survey,*) = ssc
    speeds(slow_survey) = 'slow'
endif
if nbo gt 0 then begin
    mbar(back_orbit,*) = boc
    speeds(back_orbit) = 'back'
endif
;
; check for bursts...
;

burst_hdr = get_fa_fields(best_burst_dqd,min(spin_times),max(spin_times))
if burst_hdr.valid then begin
    burst_times = burst_hdr.time

    for i=1,nst-1l do begin
        ihdr = select_range(burst_times,spin_times(i-1l),spin_times(i))
        if (ihdr(0) ge 0) then begin
            mbar(i-1l:i,nhigh/2) = boc
        endif
    endfor
endif

too_big = where(hsbm_times gt max(spin_times),ntoobig)
too_small = where(hsbm_times lt min(spin_times),ntoosmall)

if ntoobig gt 0 then hsbm_times(too_big) = max(spin_times)
if ntoosmall gt 0 then hsbm_times(too_small) = min(spin_times)

if (where(finite(hsbm_times)))(0) ge 0 then begin
    hsi = long((hsbm_times-min(spin_times))/ $
               (max(spin_times)-min(spin_times))*(nst-1l))
    nhsi = n_elements(hsi)
    ok_hsi = where((hsi ge 0) and (hsi lt nst),noh)
    if noh eq 0 then goto,no_hsbm ; skips out if hsbm_times lie
                                ; outside spin_times range, i.e. a
                                ; burst from a previous orbit, etc. 
    hsi = hsi(ok_hsi)
    nhsi = n_elements(hsi)

    if nhsi gt 2 then begin
        hsi = hsi(uniq(hsi,sort(hsi)))
        nhsi = n_elements(hsi)
        if nhsi gt 2 then begin
            repeat begin
                nhsi = n_elements(hsi)
                dhsi = [hsi(1:nhsi-1l) - hsi(0:nhsi-2l),2l] ; last hsi is
                                ; always ok
                crunched = dhsi le 1
                bunches = where(crunched eq 1,nb)
                ok = where(crunched eq 0,nok)
                if (nb gt 1) then begin
                    pick = lindgen(nb/2l)*2l
                    if nok eq 0 then begin
                        hsi = hsi((bunches(pick)))
                    endif else begin
                        indices = [ok,bunches(pick)]
                        indices = indices(sort(indices))
                        hsi = hsi(indices)
                    endelse
                endif
                if (nb eq 1) then begin
                    hsi = hsi(ok)
                    nb = 0
                endif
            endrep until(nb eq 0)
        endif 
    endif 
    nhsi = n_elements(hsi)
    
    him = lonarr(nhsi)
    hip = lonarr(nhsi)
    
    for i=0,nhsi-1l do begin
        case 1 of 
            hsi(i) eq nhsi-1l:begin
                him(i) = hsi(i)-2l
                hsi(i) = hsi(i)-1l
                hip(i) = hsi(i)+1L
            end
            hsi(i) eq 0:begin
                him(i) = 0l
                hsi(i) = 1l
                hip(i) = 2l
            end
            else:begin
                him(i) = hsi(i)-1l
                hip(i) = hsi(i)+1l
            end
        endcase
    endfor
    
    mbar(hip,0) = boc
    mbar(hip,nhigh-1l) = boc
    mbar(hsi,0) = hsbm_color
    mbar(hsi,nhigh-1l) = hsbm_color
    mbar(him,0) = boc
    mbar(him,nhigh-1l) = boc
endif
no_hsbm:do_nothing=0

store_data,'fields_modebar', $
  data={x:spin_times,y:mbar,v:findgen(nhigh)}


if not keyword_set(particles) then begin
    store_data,'speeds',data={speeds:speeds}
endif

default_ac_limits,/sdt


return
end
