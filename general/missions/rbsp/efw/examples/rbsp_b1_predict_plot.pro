; 0, To use, edit jumpa/jumpb, prota/protb, colla/collb. They corresponds to
;    jumps, protected time, collection time.
; 1, First location is the first element in jump, so # of jump is always >1.
; 2, Use last location, or known jump to update "first location".
; 3, The predict curve should be very accurate.
; 4, Don't put jump in between collections. Add 1min pad time between 
;    jump and collection. Don't let collection time overlap.
; 5, To ensure accuracy, if update "first location" using last location, then 
;   set 1st collection start from last time, set earlier.


; **** combine jump & collection, sort, convert to abs memory id, print info,
; treat wrap, generate time & memory id for tplot, load contact time to tplot.
pro rbsp_b1_predict_plot_process, probe, jumps, colls, $
    lun = lun, time = t0, memf = memf, mems = mems

    ; constants.
    sz = 262144D            ; memory size, in block.
    s2b = sz/84890D         ; sec to 16438 block.
    s2b = sz/85890D         ; sec to 16438 block.
    s2b = sz/86916D         ; sec to 16438 block.
    print, 'conversion constant: ', s2b

    ; load contact times.
    rbsp_load_contact, conta, probe
    nrec = n_elements(conta)/2
    t0 = dblarr(nrec*3)
    for i = 0, nrec-1 do t0[i*3:i*3+2] = [reform(conta[i,*]),conta[i,1]+1e-5]
    tmp = dblarr(nrec*3) & tmp[2:*:3] = !values.d_nan

    vname = 'rbsp'+strlowcase(probe)+'_contact'
    store_data, vname, t0, tmp, limits = {labels:'contact', yrange:[-1,1], $
        ytitle:'', ytickformat:'(A1)', yticks:2, yminor:1, yticklen:0.01, $
        thick:5, panel_size:0.1, colors:2}

    if n_elements(lun) eq 0 then lun = -1
    ; combine jump and collection.
    njump = n_elements(jumps)/2 & ncoll = n_elements(colls)/3
    nmem = njump+ncoll
    mems = dblarr(nmem, 5)      ; [tsta, tend, memsta, memend, rate].
    mems[0:njump-1,0:1] = [[jumps[*,0]], [jumps[*,0]]]
    mems[0:njump-1,2:3] = [[jumps[*,1]], [jumps[*,1]]]
    mems[0:njump-1,4] = 0
    mems[njump:*,0:1] = colls[*,0:1]
    mems[njump:*,2:3] = 0
    mems[njump:*,4] = colls[*,2]
    idx = sort(mems[*,0])
    mems = mems[idx,*]

    ; convert to absolute memory id.
    for i = 0, nmem-1 do begin
        if mems[i,0] eq mems[i,1] then continue     ; jump.
        mems[i,2] = mems[i-1,3]
        mems[i,3] = mems[i,2]+(mems[i,1]-mems[i,0])*(mems[i,4]/16438D)*s2b
        mems[i,2:3] = long(mems[i,2:3]) mod sz      ; wrap absolute memory id.
    endfor

    ; print result.
    printf, lun, ''
    printf, lun, 'RBSP-'+strupcase(probe)
    fmt = '(I6)'
    for i = 0, nmem-1 do begin
        if mems[i,4] eq 0 then begin
            printf, lun, 'jump:          '+time_string(mems[i,0])+' to '+$
                string(mems[i,3],format=fmt)
        endif else if mems[i,4] eq -1 then begin
            printf, lun, 'wrap:          '+time_string(mems[i,0])
        endif else begin
            printf, lun, 'collection:    '+time_string(mems[i,0])+' to '+$
                time_string(mems[i,1])+'    '+string(mems[i,2],format=fmt)+$
                ' to '+string(mems[i,3],format=fmt)+' at '+$
                string(mems[i,4],format='(I5)')+' sample/s'
        endelse
    endfor

    ; treat memory overflow.
    i = 1 & dt = 0.1
    while i lt nmem do begin
        if mems[i,2] le mems[i,3] then begin        ; jump, or normal.
            if mems[i,0] eq mems[i,1] then begin    ; jump
                mems[i,1] = mems[i,0]+dt
                if i gt 1 then mems[i,2] = mems[i-1,3]
            endif
            i+=1 & continue
        endif
        twrap = mems[i,0]+(mems[i,1]-mems[i,0])*$
            (sz-1-mems[i,2])/(sz-1-mems[i,2]+mems[i,3])
        tmem = [twrap,twrap,!values.d_nan,!values.d_nan,-1]
        mems = [mems[0:i,*],transpose(tmem),mems[i:*,*]]
        mems[i,1] = twrap-dt & mems[i,3] = sz-1
        i+=2
        mems[i,0] = twrap+dt & mems[i,2] = 0
        i+=1
        nmem = n_elements(mems)/5
    endwhile

    ; convert to array.
    t0 = dblarr(nmem*2) & memf = dblarr(nmem*2)
    for i = 0, nmem-1 do begin
        t0[i*2:i*2+1] = mems[i,0:1]
        memf[i*2:i*2+1] = mems[i,2:3]
    endfor
end


timespan, systime(1)-10D*86400, 20

; jumps: [n,2], each record in [tsta, absolute memory id].
; The 1st record is always the start location.
jumpa = [$
    [time_double('2014-04-09/01:43'),  95350D]]
jumpb = [$
    [time_double('2014-04-08/01:11'),  78505D],$

    [time_double('2014-04-09/21:50'), 161480D],$
    [time_double('2014-04-10/07:42'), 179520D],$
    [time_double('2014-04-11/03:10'), 239650D],$
    [time_double('2014-04-11/11:08'), 255890D]]

jumpa = transpose(jumpa)
jumpb = transpose(jumpb)

; protected memory, [n,2], each record in [tsta, tend].
prota = [$
    [time_double(['2014-03-13/05:09', '2014-03-13/05:10'])]]
protb = [$
    [time_double(['2014-04-05/12:00', '2014-04-05/17:00'])]]
prota = transpose(prota)
protb = transpose(protb)

; collection, [n,3], each record in [tsta, tend, rate].
colla = [$
    [time_double(['2014-04-09/01:44', '2014-04-09/06:44']), 16384],$
    [time_double(['2014-04-09/10:42', '2014-04-09/15:42']), 16384],$
    [time_double(['2014-04-09/19:41', '2014-04-10/00:41']), 16384],$
    [time_double(['2014-04-10/04:40', '2014-04-10/09:40']), 16384],$
    [time_double(['2014-04-10/13:38', '2014-04-10/18:38']), 16384],$
    [time_double(['2014-04-10/22:37', '2014-04-11/03:37']), 16384],$
    [time_double(['2014-04-11/07:36', '2014-04-11/12:36']), 16384],$
    [time_double(['2014-04-11/16:35', '2014-04-11/21:35']), 16384]]

collb = [$
    [time_double(['2014-04-08/01:12', '2014-04-08/01:22']),16384],$
    [time_double(['2014-04-08/02:58', '2014-04-08/08:58']), 4096],$
    [time_double(['2014-04-08/11:59', '2014-04-08/17:59']), 4096],$
; new.
    [time_double(['2014-04-09/21:51', '2014-04-09/22:01']),16384],$
    [time_double(['2014-04-10/07:43', '2014-04-10/07:53']),16384],$
    [time_double(['2014-04-11/11:09', '2014-04-11/11:19']),16384],$

    [time_double(['2014-04-08/21:01', '2014-04-09/03:01']), 4096],$
    [time_double(['2014-04-09/06:03', '2014-04-09/12:03']), 4096],$
    [time_double(['2014-04-09/15:04', '2014-04-09/21:04']), 4096],$
    [time_double(['2014-04-10/00:06', '2014-04-10/06:06']), 4096],$
    [time_double(['2014-04-10/09:08', '2014-04-10/15:08']), 4096],$
    [time_double(['2014-04-10/18:09', '2014-04-11/00:09']), 4096],$
    [time_double(['2014-04-11/03:11', '2014-04-11/09:11']), 4096],$
    [time_double(['2014-04-11/12:13', '2014-04-11/18:13']), 4096],$
    [time_double(['2014-04-11/21:14', '2014-04-12/03:14']), 4096]]


colla = transpose(colla)
collb = transpose(collb)


; future lightning collection for April.
;    [time_double(['2014-04-12/22:11', '2014-04-12/22:21']),16384],$
;    [time_double(['2014-04-13/08:05', '2014-04-13/08:15']),16384],$
;    [time_double(['2014-04-14/11:25', '2014-04-14/11:35']),16384],$
;    [time_double(['2014-04-15/22:29', '2014-04-15/22:39']),16384],$
;    [time_double(['2014-04-16/08:23', '2014-04-16/08:33']),16384],$
;    [time_double(['2014-04-17/11:43', '2014-04-17/11:53']),16384],$
;    [time_double(['2014-04-18/22:48', '2014-04-18/22:58']),16384],$
;    [time_double(['2014-04-19/08:26', '2014-04-19/08:36']),16384],$
;    [time_double(['2014-04-20/02:14', '2014-04-20/02:24']),16384],$
;    [time_double(['2014-04-21/23:02', '2014-04-21/23:12']),16384],$
;    [time_double(['2014-04-22/08:50', '2014-04-22/09:00']),16384],$
;    [time_double(['2014-04-23/02:28', '2014-04-23/02:38']),16384],$
;    [time_double(['2014-04-24/23:16', '2014-04-24/23:26']),16384],$
;    [time_double(['2014-04-25/09:04', '2014-04-25/09:14']),16384],$
;    [time_double(['2014-04-26/02:42', '2014-04-26/02:52']),16384],$
;    [time_double(['2014-04-27/23:33', '2014-04-27/23:43']),16384],$
;    [time_double(['2014-04-28/09:16', '2014-04-28/09:26']),16384],$
;    [time_double(['2014-04-29/02:57', '2014-04-29/03:07']),16384],$
;    [time_double(['2014-04-30/23:49', '2014-04-30/23:59']),16384],$

rbsp_b1_predict_plot_process, 'a', jumpa, colla, $
    time = timea, memf = memaf, mems = mema
rbsp_b1_predict_plot_process, 'b', jumpb, collb, $
    time = timeb, memf = membf, mems = memb

; **** below are from Aaron.
; create a tplot variable with the future memory locations.
store_data,'future_a',data={x:timea,y:memaf}
store_data,'future_b',data={x:timeb,y:membf}
options,['future_a','future_b'],'colors',250
options,['future_a','future_b'],'thick',2

; treat protect memory.
get_data,'rbspa_efw_b1_fmt_block_index2',data=gootmpa
get_data,'rbspb_efw_b1_fmt_block_index2',data=gootmpb
gootmpa2 = gootmpa
gootmpb2 = gootmpb

gootmpa2.y = !values.f_nan
gootmpb2.y = !values.f_nan

tpa0 = reform(prota[*,0]) & tpa1 = reform(prota[*,1])
for vv=0,n_elements(tpa0)-1 do begin
    boob = where((gootmpa.x ge tpa0[vv]) and (gootmpa.x le tpa1[vv]))
    if boob[0] ne -1 then gootmpa2.y[boob] = gootmpa.y[boob]
endfor
tpb0 = reform(protb[*,0]) & tpb1 = reform(protb[*,1])
for vv=0,n_elements(tpb0)-1 do begin
    boob = where((gootmpb.x ge tpb0[vv]) and (gootmpb.x le tpb1[vv]))
    if boob[0] ne -1 then gootmpb2.y[boob] = gootmpb.y[boob]
endfor
store_data,'rbspa_efw_b1_fmt_block_index3',data=gootmpa2
store_data,'rbspb_efw_b1_fmt_block_index3',data=gootmpb2
options,'rbsp?_efw_b1_fmt_block_index3','colors',100
options,'rbsp?_efw_b1_fmt_block_index3','psym',4

; prepare tplot.
store_data,'comba',data=['rbspa_efw_b1_fmt_block_index_cutoff',$
    'rbspa_efw_b1_fmt_block_index','rbspa_efw_b1_fmt_block_index2',$
    'rbspa_efw_b1_fmt_block_index3','future_a','rbspa_contact']
store_data,'combb',data=['rbspb_efw_b1_fmt_block_index_cutoff',$
    'rbspb_efw_b1_fmt_block_index','rbspb_efw_b1_fmt_block_index2',$
    'rbspb_efw_b1_fmt_block_index3','future_b','rbspb_contact']
store_data, 'comba2', data = ['rbspa_efw_b1_fmt_block_index', 'future_a']
store_data, 'combb2', data = ['rbspb_efw_b1_fmt_block_index', 'future_b']

sz = 262144D            ; memory size, in block.
ylim,['comba','combb'],0,sz
options,'rbsp?_b1_status','panel_size',0.5
tplot,['comba','rbspa_b1_status','combb','rbspb_b1_status']


; print last position: time and memory id.
get_data, 'rbspa_efw_b1_fmt_block_index_cutoff', data = tmp
print, 'RBSP-A last pos:    '+time_string(tmp.x[1])+'    at    '+$
    string(tmp.y[1],format='(I6)')
get_data, 'future_a', t0, yy
idx = (where(tmp.x[1] le t0))[0]
loc = interpol(yy[[idx-1,idx]],t0[[idx-1,idx]],tmp.x[1])
print, 'RBSP-A predict pos: '+time_string(tmp.x[1])+'    at    '+$
    string(loc,format='(F8.1)')
print, yy[idx]
get_data, 'rbspb_efw_b1_fmt_block_index_cutoff', data = tmp
print, 'RBSP-B last pos:    '+time_string(tmp.x[1])+'    at    '+$
    string(tmp.y[1],format='(I6)')
get_data, 'future_b', t0, yy
idx = (where(tmp.x[1] le t0))[0]
loc = interpol(yy[[idx-1,idx]],t0[[idx-1,idx]],tmp.x[1])
print, 'RBSP-B predict pos: '+time_string(tmp.x[1])+'    at    '+$
    string(loc,format='(F8.1)')
print, yy[idx]


print,'type .c to print the plot to the desktop'
stop

pcharsize_saved=!p.charsize
pfont_saved=!p.font
pcharthick_saved=!p.charthick
pthick_saved=!p.thick

set_plot,'Z'
rbsp_efw_init,/reset ; try to get decent colors in the Z buffer

device,set_resolution=[3200,2400],set_font='helvetica',/tt_font,set_character_size=[28,35]

!p.thick=4.
!p.charthick=4.

options,['comba','combb'],'ytickformat','(I6.6)'

tplot_options,'xmargin',[14,12]
tplot
timebar,jumpa_s,color=50,varname=['comba','rbspa_b1_status']
timebar,jumpb_s,color=50,varname=['combb','rbspb_b1_status']


; take snapshot of z buffer
snapshot=tvrd()
device,/close

; convert snapshot from index colors to true colors
tvlct,r,g,b,/get

sz=size(snapshot,/dimensions)
snapshot3=bytarr(3,sz[0],sz[1])
snapshot3[0,*,*]=r[snapshot]
snapshot3[1,*,*]=g[snapshot]
snapshot3[2,*,*]=b[snapshot]

; shrink snapshot
xsize=800
ysize=600
snapshot3=rebin(snapshot3,3,xsize,ysize)

print, 'saving png ...'
; write a png
write_png,'~/Desktop/b1_status_predict.png',snapshot3

set_plot,'X'
rbsp_efw_init,/reset
!p.charsize=pcharsize_saved
!p.font=pfont_saved
!p.charthick=pcharthick_saved
!p.thick=pthick_saved

end
