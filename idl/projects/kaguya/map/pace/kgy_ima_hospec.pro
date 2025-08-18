;+
; PROCEDURE:
;       kgy_ima_hospec
; PURPOSE:
;       Generates energy-time spectrograms for H+ and O+
; CALLING SEQUENCE:
;       kgy_ima_hospec
; KEYWORDS:
;       trange: time range
;       tres: time resolution (Default: 512 s). Set tres=0 for highest res.
;       polrange: polar angle range - see Figs. 22 and 24 of Saito+2010
;       dtof: tof_cent*(1 +/- dtof) (Default: 0.1)
; CREATED BY:
;       Yuki Harada on 2022-05-25
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2021-11-08 22:03:15 +0900 (月, 08 11 2021) $
; $LastChangedRevision: 30409 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_ima_emspec.pro $
;-

pro kgy_ima_hospec,trange=trange,erange=erange,Kloss=Kloss,dtof=dtof,tres=tres,suffix=suffix,polrange=polrange

if ~keyword_set(dtof) then dtof = 0.1 ;- tof_cent*(1 +/- dtof)
if size(tres,/type) eq 0 then tres = 512d
tr = timerange(trange)
if n_elements(erange) eq 2 then er = minmax(erange) else er = [20,10e3]
if ~keyword_set(Kloss) then Kloss = 2 ;- 0, 1, 2, 3, 4, 5
if ~keyword_set(suffix) then suffix = ''

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


datind = value_locate( dat.index, ind )
cnt = float(dat[datind].cnt)    ;- pol, ene, tof, time
w = where( cnt eq uint(-1) , nw )
if nw gt 0 then cnt[w] = !values.f_nan
if n_elements(polrange) eq 2 then begin    ;- 0->90 range
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
endif
cnt = total(cnt,1,/nan)         ;- ene, tof, time
cnt[*,1022:1023,*] = 0.         ;- throw away mass bin 1022,1023
ene = average(reform(info.ene_4x16[0,*,*,4]),2)*1e3


tofbin = (findgen(1024)+.5)/1024.*1000. ;- Saito et al. (2010), Fig 17 caption

isort = sort(ene)
enesort = ene[isort]
cntsort = cnt[isort,*,*]

wene = where( enesort ge er[0] and enesort le er[1] , nwene )
if nwene eq 0 then begin
   dprint,'No valid energy steps in ',er
   return
endif


xp = tofbin
yp = enesort[wene]
zp = cntsort[wene,*,*] ;- ene, tof, time

zp_h = zp * 0.
zp_o = zp * 0.

;;; set IMA LEF voltage (Saito et al., 2010)
Vlef = 15
if mean(tr) lt time_double('2009-06-03') then Vlef = 12
if mean(tr) lt time_double('2008-05-24') then Vlef = 10
if mean(tr) lt time_double('2008-03-24') then Vlef = 8

;;; H and O spectra
marr = [1,16]
qarr = [1,1]
   
   ;;; neutral
for im=0,n_elements(marr)-1 do begin
   w = where( ima_tof_str.m eq marr[im] and ima_tof_str.q eq qarr[im] $
              and round(ima_tof_str.vlef) eq Vlef and round(ima_tof_str.kloss) eq kloss , nw )
   if nw eq 0 then continue
   tof_cent = interp( ima_tof_str[w].tofn , alog10(ima_tof_str[w].Kini) ,  alog10(yp) )
   for iene=0,n_elements(yp)-1 do begin
      w = where( xp gt tof_cent[iene]*(1.-dtof) and xp lt tof_cent[iene]*(1.+dtof) , nw )
      if im eq 0 then zp_h[iene,w,*] = zp[iene,w,*]
      if im eq 1 then zp_o[iene,w,*] = zp[iene,w,*]
   endfor
endfor
   ;;; negative
for im=0,n_elements(marr)-1 do begin
   w = where( ima_tof_str.m eq marr[im] and ima_tof_str.q eq qarr[im] $
              and round(ima_tof_str.vlef) eq Vlef and round(ima_tof_str.kloss) eq kloss , nw )
   if nw eq 0 then continue
   tof_cent = interp( ima_tof_str[w].tofneg , alog10(ima_tof_str[w].Kini) ,  alog10(yp) )
   for iene=0,n_elements(yp)-1 do begin
      w = where( xp gt tof_cent[iene]*(1.-dtof) and xp lt tof_cent[iene]*(1.+dtof) , nw )
      if im eq 0 then zp_h[iene,w,*] = zp[iene,w,*]
      if im eq 1 then zp_o[iene,w,*] = zp[iene,w,*]
   endfor
endfor
   ;;; positive
for im=0,n_elements(marr)-1 do begin
   w = where( ima_tof_str.m eq marr[im] and ima_tof_str.q eq qarr[im] $
              and round(ima_tof_str.vlef) eq Vlef and round(ima_tof_str.kloss) eq kloss , nw )
   if nw eq 0 then continue
   tof_cent = interp( ima_tof_str[w].tofL , alog10(ima_tof_str[w].Kini) ,  alog10(yp) )
   for iene=0,n_elements(yp)-1 do begin
      w = where( xp gt tof_cent[iene]*(1.-dtof) and xp lt tof_cent[iene]*(1.+dtof) , nw )
      if im eq 0 then zp_h[iene,w,*] = zp[iene,w,*]
      if im eq 1 then zp_o[iene,w,*] = zp[iene,w,*]
   endfor
endfor

;;; check -> looks okay
;; zp_htot = total(zp_h,3,/nan)
;; zp_otot = total(zp_o,3,/nan)
;; wset,0
;; lim = {xtitle:'TOF [ns]',xrange:[0,1000],xstyle:1, $
;;        ytitle:'Energy [eV/q]',ylog:1,yrange:er,ystyle:1, $
;;        xticklen:-.01,yticklen:-.01, $
;;        ztitle:'Counts',zlog:1,zrange:[.5,1e3],minzlog:1e-30, $
;;        no_interp:1,title:trange_str(tr),position:[.15,.55,.85,.95]}
;; specplot,xp,yp,transpose(zp_htot),lim=lim
;; lim = {xtitle:'TOF [ns]',xrange:[0,1000],xstyle:1, $
;;        ytitle:'Energy [eV/q]',ylog:1,yrange:er,ystyle:1, $
;;        xticklen:-.01,yticklen:-.01, $
;;        ztitle:'Counts',zlog:1,zrange:[.5,1e3],minzlog:1e-30, $
;;        no_interp:1,title:trange_str(tr),position:[.15,.05,.85,.45],noerase:1}
;; specplot,xp,yp,transpose(zp_otot),lim=lim

cnt_h = transpose(total(zp_h,2))
cnt_o = transpose(total(zp_o,2))

;;; FIXME: event correction
;;; FIXME: conv. to D.E.F.

;;; time integration
if keyword_set(tres) then begin
   cnt_h = time_average(times,cnt_h,newt=newt,trange=tr,res=tres,/ret_tot)
   cnt_o = time_average(times,cnt_o,newt=newt,trange=tr,res=tres,/ret_tot)
   times = newt
endif

store_data,'kgy_ima_H_en_counts'+suffix,times,cnt_h,yp, $
           dlim={yrange:er,ystyle:1,ylog:1,yticklen:-.01,ytitle:'IMA H!u+!n!cEnergy!c[eV]', $
                 spec:1,zlog:1,ztitle:'Counts'}
store_data,'kgy_ima_O_en_counts'+suffix,times,cnt_o,yp, $
           dlim={yrange:er,ystyle:1,ylog:1,yticklen:-.01,ytitle:'IMA O!u+!n!cEnergy!c[eV]', $
                 spec:1,zlog:1,ztitle:'Counts'}



end
