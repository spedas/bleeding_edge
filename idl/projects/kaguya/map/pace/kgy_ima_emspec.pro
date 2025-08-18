;+
; PROCEDURE:
;       kgy_ima_emspec
; PURPOSE:
;       Plots an energy-TOF profile
; CALLING SEQUENCE:
;       kgy_ima_emspec
; KEYWORDS:
;       trange: time range
; CREATED BY:
;       Yuki Harada on 2018-07-12
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2023-06-30 01:34:53 -0700 (Fri, 30 Jun 2023) $
; $LastChangedRevision: 31915 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_ima_emspec.pro $
;-

pro kgy_ima_emspec,trange=trange,window=window,erange=erange,tofrange=tofrange,speclimits=slim,sum=sum,linelimits=llim,Kloss=Kloss,nosplabel=nosplabel,polrange=polrange,emdata=emdata,splines=splines,Vlef=Vlef

tr = timerange(trange)
if size(sum,/type) eq 0 then sum = 4

@kgy_pace_com

dat = ima_type40_arr            ;- cnt: [4,32,1024]
info = ima_info_str
header = ima_header_arr
times = time_double( string(header.yyyymmdd,format='(i8.8)') $
                     +string(header.hhmmss,format='(i6.6)'), $
                     tformat='YYYYMMDDhhmmss' ) $
        + header.time_resolution / 2.d3 ;- center time
wt = where( times gt tr[0] and times lt tr[1] $
            and header.mode eq 17 , nwt )
if nwt eq 0 then begin
   dprint,'No valid times'
   return
endif
ind = header[wt].index
nind = nwt
times = times[wt]
ram = header[wt].svs_tbl
title = trange_str(tr)

datind = value_locate( dat.index, ind )
cnt = dat[datind].cnt ;- pol, ene, tof, time
w = where( cnt eq uint(-1) , nw )
if nw gt 0 then cnt[w] = !values.f_nan
if n_elements(polrange) eq 2 then begin ;- 0->90 range
   ;;; Note: Type 40 pol. sorted
   ;;; See momcal.c:
   ;; // tmp_sum_cnt4 += ((double)s_ima_type40.cnt[inv_pol_map4[j]][inv_ene_map32[i]][l]); // bug
   ;;    tmp_sum_cnt4 += ((double)s_ima_type40.cnt[j][inv_ene_map32[i]][l]);} // Type 40 pol. sorted
   pol = -1.*median(info.pol_4x16[ram,*,*,*],dim=4)    ;- ram, ene, pol, az -> time, ene, pol
   pol = transpose(rebin(pol,nwt,32,4,1024),[2,1,3,0]) ;- -> pol, ene, tof, time
   spol = sort(pol[*,0,0,0])
   pol = pol[spol,*,*,*]
   w = where( pol gt min(polrange) and pol lt max(polrange) , comp=cw, ncomp=ncw )
   if ncw gt 0 then cnt[cw] = 0.
   title += ', pol: '+string(polrange[0],f='(f5.1)')+' -> '+string(polrange[1],f='(f5.1)')
endif
totalcnt = total( total( cnt,4,/nan ) , 1,/nan ) ;- ene, tof
totalcnt[*,1022:1023] = 0.      ;- throw away mass bin 1022,1023

ene = average(reform(info.ene_4x16[0,*,*,4]),2)*1e3


tofbin = (findgen(1024)+.5)/1024.*1000. ;- Saito et al. (2010), Fig 17 caption

isort = sort(ene)
enesort = ene[isort]
cntsort = totalcnt[isort,*]

if keyword_set(sum) then begin
   nsum = 1024/sum
   ii = indgen(nsum)
   cntnew = make_array(value=0.,32,nsum)
   for ic=0,sum-1 do cntnew[*,ii] = cntnew[*,ii] + cntsort[*,ii*sum+ic]
   cntsort = cntnew
   tofbin = (findgen(nsum)+.5)/nsum*1000.
endif


if n_elements(erange) eq 2 then er = minmax(erange) else er = minmax(ene)
if n_elements(tofrange) eq 2 then tofr = minmax(tofrange) else tofr = [0,1000]

wene = where( enesort ge er[0] and enesort le er[1] , nwene )
if nwene eq 0 then begin
   dprint,'No valid energy steps in ',er
   return
endif
wtof = where( tofbin ge tofr[0] and tofbin le tofr[1] , nwtof )
if nwtof eq 0 then begin
   dprint,'No valid TOF bins in ',tofr
   return
endif

xp = tofbin[wtof]
yp = enesort[wene]
zp = transpose(cntsort[wene,*])
zp = zp[wtof,*]

;;; set IMA LEF voltage (Table 8 of Saito et al., 2010)
if ~keyword_set(Vlef) then begin
   Vlef = 15
   if mean(tr) lt time_double('2009-06-03') then Vlef = 12
   if mean(tr) lt time_double('2008-05-24') then Vlef = 10
   if mean(tr) lt time_double('2008-03-24') then Vlef = 8
endif
if size(Kloss,/type) eq 0 then Kloss = 2 ;- 0, 1, 2, 3, 4, 5



;;; plot
if keyword_set(window) then wset,window
lim = {xtitle:'TOF [ns]',xrange:tofr,xstyle:1, $
       ytitle:'Energy [eV/q]',ylog:1,yrange:er,ystyle:1, $
       xticklen:-.01,yticklen:-.01, $
       ztitle:'Counts',zlog:1, $
       no_interp:1,title:title,position:[.15,.55,.85,.95]}
if size(slim,/type) eq 8 then extract_tags,lim,slim
specplot,xp,yp,zp,lim=lim
emdata = {tof:xp,energy:yp,counts:zp}

undefine,splines
if size(ima_tof_str,/type) eq 8 and ~keyword_set(nosplabel) then begin
   ;;; neutral
   marr = [1,4,4,12,16,23,27,39,40,56]
   qarr = [1,2,1, 1, 1, 1, 1, 1, 1, 1]
   sparr = ['H!u+!n(0)','He!u++!n(0)','He!u+!n(0)','C!u+!n(0)','O!u+!n(0)','Na!u+!n(0)','Al!u+!n(0)','K!u+!n(0)','Ar!u+!n(0)','Fe!u+!n(0)']
   for im=0,n_elements(marr)-1 do begin
      w = where( ima_tof_str.m eq marr[im] and ima_tof_str.q eq qarr[im] $
                 and round(ima_tof_str.vlef) eq Vlef and round(ima_tof_str.kloss) eq kloss , nw )
      if nw eq 0 then continue
      xx = ima_tof_str[w].tofn
      yy = ima_tof_str[w].Kini
      oplot,xx,yy,color=1;255
      xyouts,/data,xx[-1],er[0]*(1.+(im mod 2)),sparr[im],align=.5,color=1;255
      spline = {sp:'',tof:make_array(value=!values.f_nan,10),energy:make_array(value=!values.f_nan,10)}
      spline.sp = sparr[im]
      spline.tof[0:(nw-1)] = xx
      spline.energy[0:(nw-1)] = yy
      append_array,splines,spline
   endfor
   ;;; negative
   marr = [1,16]
   qarr = [1, 1]
   sparr = ['H!u+!n(-)','O!u+!n(-)']
   for im=0,n_elements(marr)-1 do begin
      w = where( ima_tof_str.m eq marr[im] and ima_tof_str.q eq qarr[im] $
                 and round(ima_tof_str.vlef) eq Vlef and round(ima_tof_str.kloss) eq kloss , nw )
      if nw eq 0 then continue
      xx = ima_tof_str[w].tofneg
      yy = ima_tof_str[w].Kini
      oplot,xx,yy,color=4
      xyouts,/data,xx[-1],er[0]*1.5,sparr[im],align=.5,color=4
      spline = {sp:'',tof:make_array(value=!values.f_nan,10),energy:make_array(value=!values.f_nan,10)}
      spline.sp = sparr[im]
      spline.tof[0:(nw-1)] = xx
      spline.energy[0:(nw-1)] = yy
      append_array,splines,spline
   endfor
   ;;; positive
   marr = [1,16]
   qarr = [1, 1]
   sparr = ['H!u+!n(+)','O!u+!n(+)']
   for im=0,n_elements(marr)-1 do begin
      w = where( ima_tof_str.m eq marr[im] and ima_tof_str.q eq qarr[im] $
                 and round(ima_tof_str.vlef) eq Vlef and round(ima_tof_str.kloss) eq kloss , nw )
      if nw eq 0 then continue
      xx = ima_tof_str[w].tofL
      yy = ima_tof_str[w].Kini
      oplot,xx,yy,color=6
      xyouts,/data,xx[-1],er[0]/1.5,sparr[im],align=.5,color=6
      spline = {sp:'',tof:make_array(value=!values.f_nan,10),energy:make_array(value=!values.f_nan,10)}
      spline.sp = sparr[im]
      spline.tof[0:(nw-1)] = xx
      spline.energy[0:(nw-1)] = yy
      append_array,splines,spline
   endfor
endif


xp = xp
yp = total(zp,2)
lim = {xtitle:'TOF [ns]',xrange:tofr,xstyle:1, $
       ytitle:'Counts',ylog:1,yrange:[1,max(yp,/nan)], $
       position:[.15,.1,.85,.45],noerase:1}
if size(llim,/type) eq 8 then extract_tags,lim,llim
plot,xp,yp,_extra=lim

end
