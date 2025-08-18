;+
; PROCEDURE:
;       mvn_swe_lpw_scpot
; PURPOSE:
;
;       !!! This routine could take a very long time to generate the data !!!
;       !!! To load pre-generated data quickly, use 'mvn_swe_lpw_scpot_restore' !!!
;
;       Empirically derives spacecraft potentials using SWEA/STA and LPW.
;       Inflection points in LPW I-V curves are tuned to positive and negative
;       spacecraft potentials estimated from SWEA/STA energy spectra
;       (mvn_swe_sc_pot, mvn_swe_sc_negpot, mvn_sta_scpot_load).
;
;       Does not work in shadow.
;
;       For more information, see 
;       http://research.ssl.berkeley.edu/~haraday/tools/mvn_swe_lpw_scpot.pdf
;
; CALLING SEQUENCE:
;       timespan,'16-01-01',14   ;- make sure to set a long time range
;       mvn_swe_lpw_scpot
; OUTPUT TPLOT VARIABLES:
;       mvn_swe_lpw_scpot :     best-estimate scpot data
;                               (currently "mvn_swe_lpw_scpot_pol")
;       mvn_swe_lpw_scpot_lin : spacecraft potentials derived from
;                               linear fitting of Vswe v. -Vinfl
;       mvn_swe_lpw_scpot_pol : spacecraft potentials derived from
;                               2nd-order polynomial fitting of Vswe v. -Vinfl
;       mvn_swe_lpw_scpot_pow : (obsolete)
; KEYWORDS:
;       trange: time range
;       norbwin: odd number of orbits used for Vswe-Vinfl fitting (Def. 37)
;       minndata: minimum number of data points for Vswe-Vinfl fitting
;                 (Def. 1e4)
;       maxgap: maximum time gap allowed for interpolation (Def. 257)
;       plot: if set, plot the time series and fitting
;       noload: if set, use pre-existing input tplot variables:
;               'swe_pos', 'mvn_lpw_swp1_IV'
;       vrinfl: voltage range for searching the inflection point
;               (Def. [-15,18])
;       ntsmo: time smooth width (Def. 3)
; NOTES:
;       1) The data quality are not good before 2015-01-24.
;       2) The peak fitting algorithm sometimes breaks down
;          when multiple peaks are present in dI/dV curves.
;          Check the quality flag: mvn_lpw_swp1_IV_vinfl_qflag
;                                  1 = good, 0 = bad
;          As a rule of thumb, the quality is generally good if flag > 0.8
;          You may need caution if 0.5 < flag < 0.8 (check the consistency with SWEA spectra)
;       3) Short time scale variations will be smoothed out by default.
;          Setting ntsmo=1 will improve the time resolution
;          at the expense of better statistics.
;       4) Potential values between 0 and +3 V are interpolated
;          - they cannot be verified by SWEA measurements
; CREATED BY:
;       Yuki Harada on 2016-02-29
;       Major update on 2017-07-24 - incl. negative pot
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-07-26 13:45:34 -0700 (Fri, 26 Jul 2024) $
; $LastChangedRevision: 32769 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_lpw_scpot.pro $
;-

pro mvn_swe_lpw_scpot, trange=trange, norbwin=norbwin, minndata=minndata, maxgap=maxgap, plot=plot, noload=noload, vrinfl=vrinfl, ntsmo=ntsmo, angcorr=angcorr, novinfl=novinfl, icur_thld=icur_thld, swel0=swel0, figdir=figdir, atrtname=atrtname, scatdir=scatdir, thld_out=thld_out, l2iv=l2iv, alt_swepos=alt_swepos, alt_sweneg=alt_sweneg, alt_sta=alt_sta, good_qflag=good_qflag


if size(figdir,/type) eq 0 then begin
   figdir = '/disks/maja/home/haraday/fig/maven/mvn_swe_lpw_scpot/'
   if ~file_test(figdir,/directory) then figdir = 0
endif


;;; set default parameters
if ~keyword_set(norbwin) then norbwin = 37 ;- odd number
if ~keyword_set(minndata) then minNdata = 1.e4
if ~keyword_set(maxgap) then maxgap = 257.
if ~keyword_set(vrinfl) then vrinfl = [-15,18] ;- inflection point V range
if ~keyword_set(ntsmo) then ntsmo = 3          ;- odd number, smooth IV curves in time
if ~keyword_set(atrtname) then atrtname = 'mvn_lpw_atr_swp'
if ~keyword_set(icur_thld) then icur_thld = -0.5 ;- 10^icur_thld drop from median -> invalid
if ~keyword_set(thld_out) then thld_out = 2.5    ;- reject outliers of scatter plots
if ~keyword_set(alt_swepos) then alt_swepos = [400,1e4] ;- alt range for SWE+
if ~keyword_set(alt_sta) then alt_sta = [170,400]       ;- alt range for STA
if ~keyword_set(alt_sweneg) then alt_sweneg = [0,170]   ;- alt range for SWE-
if ~keyword_set(good_qflag) then good_qflag = .7

tr = timerange(trange)

orbdata = mvn_orbit_num()
worb = where( orbdata.peri_time gt tr[0] $
              and orbdata.peri_time+4.6*3600. lt tr[1] , nworb )
orbnums = orbdata[worb].num
tperi0 = orbdata[worb].peri_time
tperi1 = orbdata[worb+1].peri_time

if nworb lt norbwin then begin
   dprint,'Time range is too short: minimum Norb = '+string(norbwin,f='(i0)')
   return
endif

;;; L2 lpiv usable after 2015-12-09/07:30, set l2iv=-1 to force to use L0
time_l2ok = time_double('2015-12-09/07:30')
if size(l2iv,/type) eq 0 then if tr[0] gt time_l2ok then l2iv = 1 else l2iv = 0


;;; load data
if ~keyword_set(noload) then begin
   maven_orbit_tplot, /current, /loadonly ;,result=scpos

   if l2iv gt 0 then begin
      mvn_lpw_load_l2,'lpiv',/notplot
      get_data,'mvn_lpw_lp_iv_l2',data=d,dtype=dtype
      if dtype ne 0 then store_data,'mvn_lpw_swp1_IV',data={x:d.x,y:d.y,v:d.v}
   endif else begin
   ;;; load LPW L0 data
      tf = ['mvn_lpw_swp1_IV','mvn_lpw_swp1_mode',atrtname] ;- wanted tplot variables
      f = mvn_pfp_file_retrieve(/l0,trange=tr)
      if getenv('ROOT_DATA_DIR') eq '' then setenv,'ROOT_DATA_DIR='+root_data_dir() ;- for LPW loader
      for ifile=0,n_elements(f)-1 do begin
         l0pref = 'mvn_pfp_all_l0_'
         idx = strpos(f[ifile],l0pref)
         today = time_double(strmid(f[ifile],idx+strlen(l0pref),8),tf='YYYYMMDD')
         YYYY_MM_DD = time_string(today,tf='YYYY-MM-DD')
         packet = 'nohsbm'
         s = execute( 'mvn_lpw_load, YYYY_MM_DD,/notatlasp,/noserver,/leavespice,packet=packet' )
         if ~s then s = execute( 'mvn_lpw_load, YYYY_MM_DD,/notatlasp,/noserver,/leavespice,packet=packet,/nospice' ) ;- try /nospice
         for itf=0,n_elements(tf)-1 do begin
            get_data,tf[itf],dtype=dtype
            if dtype eq 1 then tplot_rename,tf[itf],time_string(today,tf='YYYYMMDD_')+tf[itf]
         endfor
         store_data,'mvn_lpw_*',/del
         mvn_spc_clear_spice_kernels
         timespan,tr
      endfor
      ;;; concat and sort
      for itf=0,n_elements(tf)-1 do begin
         tn = tnames('????????_'+tf[itf],ntn)
         if ntn gt 0 then begin
            for itn=0,ntn-1 do begin
               get_data,tn[itn],data=d,dlim=dlim
               if itn eq 0 then begin
                  newx = d.x
                  newy = d.y
                  if tag_exist(d,'V') then newv = d.v
               endif else begin
                  newx = [newx,d.x]
                  newy = [newy,d.y]
                  if tag_exist(d,'V') then begin
                     if size(d.v,/n_dim) eq 2 then newv = [newv,d.v]
                  endif
               endelse
            endfor
            if tag_exist(d,'V') then $
               store_data,tf[itf],data={x:newx,y:newy,v:newv},dlim=dlim $
            else store_data,tf[itf],data={x:newx,y:newy},dlim=dlim
            tplot_sort,tf[itf]
            store_data,tn,/del
         endif
      endfor
      if l2iv ge 0 and tr[1] gt time_l2ok then begin ;- override L0 by L2 after time_l2ok
         mvn_lpw_load_l2,'lpiv',/notplot
         get_data,'mvn_lpw_swp1_IV',data=div,dtype=divtype
         get_data,'mvn_lpw_lp_iv_l2',data=d,dtype=dtype
         if dtype*divtype ne 0 then begin
            w0 = where( div.x lt time_l2ok , nw0 )
            w1 = where( d.x gt time_l2ok , nw1 )
            if nw0 gt 0 and nw1 gt 0 then begin
               tplot_rename,'mvn_lpw_swp1_IV','mvn_lpw_swp1_IV_old'
               dnew = { x:[div.x[w0],d.x[w1]], $
                        y:[div.y[w0,*],d.y[w1,*]], $
                        v:[div.v[w0,*],d.v[w1,*]] }
               store_data,'mvn_lpw_swp1_IV',data=dnew
            endif
         endif
      endif
   endelse

   ;;; load SWEA data
   if keyword_set(swel0) then mvn_swe_load_l0, tr $
   else mvn_swe_load_l2, tr, prod=['svyspec'], ddd=angcorr  ; new syntax, DLM - 03/18/2024
   mvn_swe_sumplot,/loadonly
;   mvn_swe_sc_pot,angcorr=angcorr
   mvn_scpot, comp=0, lpw=0, pospot=1, negpot=0, stapot=0, shapot=0, qlev=1, qint=8 ; bias=0.5 ;- recommended by Dave
                                                                                    ; now applied in another routine
                                                                                    ; DLM - 03/18/2024
   tplot_rename,'pot_swepos','swe_pos' ;-  (v03_r00)
   mvn_swe_sc_negpot
   mvn_sta_l2_load, sta_apid=['c6']
   mvn_sta_l2_tplot, /replace
endif                           ;- noload


;;; get LPW IV curves
get_data,'mvn_lpw_swp1_IV',data=div,dtype=divtype
if divtype eq 0 then begin
   dprint,'No valid tplot variables for lpw iv'
   return
endif

;;; get S/C pot
tscpot_all = [!values.d_nan]
scpot_all = [!values.f_nan]
get_data,'alt',data=dalt,dtype=dalttype
get_data,'swe_pos',data=dvswe,dtype=dvswetype
if dvswetype*dalttype ne 0 then begin
   alt = interp(dalt.y,dalt.x,dvswe.x,/no_ex,interp=600)
   w = where(finite(dvswe.y) and alt gt alt_swepos[0] and alt lt alt_swepos[1],nw)
   if nw gt 0 then begin
      tscpot_all = dvswe.x[w]
      scpot_all = dvswe.y[w]
   endif
endif
get_data,'neg_pot',data=dvsweneg,dtype=dvswenegtype
if dvswenegtype*dalttype ne 0 then begin
   alt = interp(dalt.y,dalt.x,dvsweneg.x,/no_ex,interp=600)
   w = where(finite(dvsweneg.y) and (alt gt alt_sweneg[0] and alt lt alt_sweneg[1]) $
             or dvsweneg.y lt -10 ,nw) ;- trust if V < -10 V
   if nw gt 0 then begin
      tscpot_all = [ tscpot_all, dvsweneg.x[w] ]
      scpot_all = [ scpot_all, dvsweneg.y[w] ]
   endif
endif
get_data,'mvn_sta_c6_scpot',data=dvsta,dtype=dvstatype
if dvstatype*dalttype ne 0 then begin
   alt = interp(dalt.y,dalt.x,dvsta.x,/no_ex,interp=600)
   w = where(dvsta.y lt 0 and alt gt alt_sta[0] and alt lt alt_sta[1] ,nw)
   if nw gt 0 then begin
      tscpot_all = [ tscpot_all, dvsta.x[w] ]
      scpot_all = [ scpot_all, dvsta.y[w] ]
   endif
endif
scpot_all = scpot_all[sort(tscpot_all)]
tscpot_all = tscpot_all[sort(tscpot_all)]
if total(finite(scpot_all)) eq 0 then begin
   dprint,'No valid scpot data'
   return
endif

store_data,'scpot0_all',data={x:tscpot_all,y:scpot_all},dlim={colors:1}




;;; if plot, set up tplot options
if keyword_set(plot) then begin
   options,'swe_a4',zrange=[1.e5,1.e9],minzlog=1.e-30,yticklen=-.01,datagap=maxgap
   options,'swe_pos',psym=3,constant=[3],yrange=[0,20]
   store_data,'swe_comb',data=['swe_a4','swe_pos'], $
              dlim={yrange:[3,4627.5],ystyle:1}
   options,'mvn_lpw_swp1_IV',spec=1,zrange=[-1.e-7,1.e-7],yrange=[-45,45],ystyle=1, $
           yticklen=-.01,no_interp=1,ytitle='LPW!cswp1',datagap=maxgap
   options,'alt2',panel_size=.5,ytitle='Alt!c[km]',ylog=1,yrange=[100,1e4], $
           constant=[alt_swepos,alt_sta,alt_sweneg]
   options,'mvn_sta_c6_neg_scpot',colors=6
   store_data,'sta_comb',data=['mvn_sta_c6_P1D_E','mvn_sta_c6_neg_scpot'], $
              dlim={ytitle:'STA c6!cEnergy!c[eV]',yticklen:-.01,yrange:[0.164,30e3],minzlog:1e-30}
   get_data,'mvn_lpw_swp1_mode',data=dmode,dtype=dtypemode
   if dtypemode ne 0 then $
      store_data,'mvn_lpw_swp1_mode_bar', $
                 data={x:dmode.x,y:[[dmode.y],[dmode.y]],v:[0,1]}, $
                 dlim={spec:1,panel_size:.1,no_color_scale:1,zrange:[0,15], $
                       ytitle:'',yticks:1,yminor:1, $
                       ytickname:[' ',' ']}
   options,'neg_pot',colors=6,psym=1,symsize=.1
endif                           ;- plot



;;; generate iv inflection voltages
if ~keyword_set(novinfl) then begin
;;; set up data containers
ders = fltarr(n_elements(div.x),128)*!values.f_nan
vols = transpose(rebin( (findgen(128)+.5)/128.* 40.-20. , $
                        128, n_elements(div.x)))
vinfl = replicate(!values.f_nan,n_elements(div.x))
vfloat = replicate(!values.f_nan,n_elements(div.x))
cursmo = div.y*!values.f_nan
chi2 = replicate(!values.f_nan,n_elements(div.x))

;;; check valid IV curves
validiv = replicate(1b,n_elements(div.x))
icur = reform(div.y[*,0])
icur_med = icur*!values.f_nan
;;; filter out positive/small Ii at V0 on an orbit-by-orbit basis
for iperi=0,n_elements(tperi0)-1 do begin
   ww = where( div.x ge tperi0[iperi] and div.x lt tperi1[iperi] $
               and finite(icur), nww )
   if nww eq 0 then continue
   medtmp = median( icur[ww] )
   icur_med[ww] = medtmp
   thld_now = medtmp * 10.^icur_thld < 0.
   ww = where( div.x ge tperi0[iperi] and div.x lt tperi1[iperi] $
               and icur gt thld_now, nww )
   if nww eq 0 then continue
   validiv[ww] = 0b
endfor


;;; quick fix to erroneous I-V curves when the mode changes before
;;; first atr info available in the beginning of the day
get_data,'mvn_lpw_swp1_mode',data=dmode,dtype=dmodetype
get_data,atrtname,data=datr,dtype=datrtype
if dmodetype*datrtype ne 0 then begin
   day0 = time_double(time_string(tr[0],tf='YYYY-MM-DD'))
   day1 = time_double(time_string(tr[1],tf='YYYY-MM-DD'))
   ndays = long((day1 - day0)/86400d) + 1
   for iday=0,ndays-1 do begin
      now = day0 + iday*86400d
      w0 = where( datr.x gt now , nw0 )
      w1 = where( dmode.x gt now , nw1 )
      if nw0*nw1 eq 0 then continue
      first_atr_time = datr.x[w0[0]]
      w2 = where( dmode.y[w1] ne dmode.y[w1[0]] , nw2 )
      if nw2 eq 0 then continue
      first_mode_change_time = dmode.x[w1[w2[0]]]
      if first_atr_time ge first_mode_change_time-1d then begin
         w = where( div.x gt now and div.x lt first_mode_change_time , nw )
         if nw gt 0 then validiv[w] = 0b
      endif
   endfor
endif



;;; loop through time steps
syst0 = systime(/sec)
secnow = 0.
for it=(ntsmo-1)/2,n_elements(div.x)-(ntsmo-1)/2-1 do begin
   if systime(/sec)-syst0 gt secnow+1 then begin
      secnow = secnow + 1
      dprint,'Calc Vinfl: ' $
             +string(100.*it/(n_elements(div.x)-1),f='(f8.4)') $
             +' %, '+time_string(div.x[it])
   endif

   if ~validiv[it] then continue

   vol = reform(div.v[it,*])

   ;;; smooth in time
   cur = reform(div.y[it,*]) * 0.
   nsum = 0.
   for itsmo=-(ntsmo-1)/2,(ntsmo-1)/2 do begin
      vdif0 = total(abs(div.v[it+itsmo,*]-div.v[it,*]))
      if vdif0 eq 0 and validiv[it+itsmo] then begin ;- only same V steps
         cur = cur + reform(div.y[it+itsmo,*])
         nsum = nsum + 1.
      endif
   endfor
   cur = cur / nsum
   cursmo[it,*] = cur


   ;;; compute the derivative from unique data points
   cur = cur[sort(vol)]
   vol = vol[sort(vol)]
   uni1 = uniq(vol)
   uni0 = [ 0, uni1[0:n_elements(uni1)-2]+1 ]
   uvol = vol[uni1]
   ucur = uvol*!values.f_nan
   for i=0,n_elements(uni1)-1 do ucur[i] = mean(cur[uni0[i]:uni1[i]])
   vol = uvol
   cur = ucur
   if n_elements(vol) lt 5 then continue
   der = deriv(vol,cur)

   ;;; smooth high-res noisy area
   w = where( abs(vol) lt 5 and (abs(vol-shift(vol,1)) lt .2 $
                                 or abs(vol-shift(vol,-1)) lt .2) ,nw)
   if nw gt 3 and max(vol[w])-min(vol[w]) gt .6 then begin
      cur2 = time_average(vol[w],cur[w],newt=vol2,tr=minmax(vol[w]),res=.2)
      der2 = deriv(vol2,cur2)
      cur[w[1]:w[nw-2]] = interp(cur2,vol2,vol[w[1]:w[nw-2]])
      der[w[1]:w[nw-2]] = interp(der2,vol2,vol[w[1]:w[nw-2]])
   endif

   ;;; get the floating potential
   cur = smooth(cur,7,/nan)
   w = where( vol gt -30 and vol lt 30 )
   mincur = min(abs(cur[w]),imin)
   maxcur = max(abs(cur[w]))
   if alog10(maxcur)-alog10(mincur) gt .5 then vfloat[it] = vol[w[imin]] $
   else continue                ;- flat curve -> skip

   ;;; discard edges
   w = where(finite(der),nw)
   if nw eq 0 then continue
   der[min(w)] = 0.
   der[max(w)] = 0.

   ;;; smooth the derivative here
   der = smooth(der,7,/nan)

   ;;; discard V >~ Vfloat, assuming Vinfl <~ Vfloat
   vbuffer = 2.
   w = where( vol gt vfloat[it]+vbuffer and finite(der) , nw)
   if nw gt 0 then der[w] = 0.

   if max(vol,/nan) lt 40 then begin
      ;;; average into 1 V regular bins and oversample
      der1v = time_average(vol,der,newt=vol1v,tr=[-20,20],res=1.)
      w = where(finite(der1v),nw)
      if nw eq 0 then continue
      ders[it,*] = interp( der1v[w], vol1v[w], vols[it,*], /no_ex )
      ders[it,*] = ders[it,*] / max(ders[it,*],/nan) ;- normalize
   endif else begin ;- +/-45 V sweep
      ders[it,*] = interp( der, vol, vols[it,*], /no_ex ) ;- no ave
      ders[it,*] = ders[it,*] / max(ders[it,*],/nan) ;- normalize
   endelse

    ;;; grab the dI/dV peak
    w = where( vols[it,*] gt vrinfl[0]-1 and vols[it,*] lt vrinfl[1]+1 $
              and finite(ders[it,*]), nw)
   if nw gt 6 then begin
      x = reform(vols[it,w])
      y = reform(ders[it,w])

      wpeaks = where( y gt .8 , nwpeaks )
      if nwpeaks gt 0 then begin  ;- only clear peaks
         imax = wpeaks[0]          ;- lowest-V peak is trustable
         p = {a:2.d*(2.*!pi)^.5,s:1.d,x0:double(x[imax])}
         fit,x,y,param=p,funct='gauss2',verb=-1 ;- initial fit
         y2 = y
         w = where( x gt p.x0+p.s or x lt p.x0-p.s or x gt p.x0+1. , nw ) ;- experimental, aggressive suppression of high-V tails
         if div.x[it] lt time_double('2015-04-04') then w = where( x gt p.x0+p.s or x lt p.x0-p.s , nw ) ;- conservative suppression at early mission
         if nw gt 0 then y2[w] = 0.                 ;- suppress the wings
         fit,x,y2,param=p,funct='gauss2',verb=-1, $ ;- 2nd fit
             fitvalues=yfit
         if p.x0 gt vrinfl[0] and p.x0 lt vrinfl[1] then begin
            vinfl[it] = p.x0    ;- This is what I want
            chi2[it] = total((y-yfit)^2)/(n_elements(y)-3.) ;- chi2 for qflag
         endif
      endif

      ;; ymax = max(y,imax,/nan)
      ;; if ymax gt .5 then begin  ;- only clear peaks
      ;;    p = {a:2.d*(2.*!pi)^.5,s:1.d,x0:double(x[imax])}
      ;;    fit,x,y,param=p,funct='gauss2',verb=-1 ;- initial fit
      ;;    y2 = y
      ;;    w = where( x gt p.x0+p.s or x lt p.x0-p.s , nw )
      ;;    if nw gt 0 then y2[w] = 0.                 ;- suppress the wings
      ;;    fit,x,y2,param=p,funct='gauss2',verb=-1, $ ;- 2nd fit
      ;;        fitvalues=yfit
      ;;    if p.x0 gt vrinfl[0] and p.x0 lt vrinfl[1] then begin
      ;;       vinfl[it] = p.x0    ;- This is what I want
      ;;       chi2[it] = total((y-yfit)^2)/(n_elements(y)-3.) ;- chi2 for qflag
      ;;    endif
      ;; endif
   endif
endfor                          ;- it loop

w = where(ders eq 0 , nw)
if nw gt 0 then ders[w] = !values.f_nan ;- Don't plot invalid parts

;;; store tplot variables
store_data,'mvn_lpw_swp1_IV_log', $
           data={x:div.x,y:alog10(abs(div.y)),v:div.v}, $
           dlim={zrange:[-9,-5],yrange:[-20,20],yticklen:-.01, $
                 ytitle:'LPW!cswp1!c[V]',datagap:maxgap,spec:1,no_interp:1, $
                 ztitle:'log!d10!n(|I|)!c(corrected)'}
store_data,'icur',data={x:div.x,y:alog10(abs(icur<0))}, $
           dlim={yrange:[-10,-7],ystyle:1, $
                 labels:['I!dV0!n'],labflag:1,ytitle:'log(-I)', $
                 datagap:maxgap,psym:0,constant:findgen(7)/2.-9.5}
store_data,'icur_med',data={x:div.x,y:alog10(abs(icur_med<0))}, $
           dlim={yrange:[-10,-7],ystyle:1,linestyle:2,colors:[2]}
store_data,'validiv',data={x:div.x,y:validiv}, $
           dlim={panel_size:.2,yrange:[-1,2],ystyle:1,psym:3, $
                 labels:'valid',labflag:1, $
                 ytitle:' ',yticks:1,yminor:1,ytickname:[' ',' ']}
store_data,'mvn_lpw_swp1_IV_log_smo', $
           data={x:div.x,y:alog10(abs(cursmo)),v:div.v}, $
           dlim={zrange:[-9,-5],yrange:[-20,20],yticklen:-.01, $
                 ytitle:'LPW!ctntsmo '+string(ntsmo,f='(i0)')+'!cswp1!c[V]', $
                 datagap:maxgap,spec:1,no_interp:1, $
                 ztitle:'log!d10!n(|I|)!c(corrected)'}
store_data,'mvn_lpw_swp1_dIV_smo',data={x:div.x,y:ders,v:vols}, $
           dlim={yrange:[-20,20],zrange:[0,1],spec:1,yticklen:-.01, $
                 ytitle:'LPW!cswp1!c[V]',ztitle:'Norm.!cdI/dV', $
                 constant:0,datagap:maxgap,no_interp:1}
store_data,'mvn_lpw_swp1_IV_vfloat',data={x:div.x,y:vfloat}, $
           dlim={colors:[5],datagap:maxgap}
store_data,'mvn_lpw_swp1_IV_vinfl',data={x:div.x,y:vinfl}, $
           dlim={colors:[3],datagap:maxgap}
store_data,'mvn_lpw_swp1_IV_vinfl_chi2',data={x:div.x,y:chi2}, $
           dlim={datagap:maxgap}
vinfl_qflag = exp(-chi2^2/2/.05^2)
store_data,'mvn_lpw_swp1_IV_vinfl_qflag', $ ;- experimental
           data={x:div.x,y:vinfl_qflag}, $
                       ;;; This is just an arbitrary function
                       ;;; which shows goodness of dI/dV peak fit
                       ;;; 1 = good, 0 = bad
           dlim={datagap:maxgap,yrange:[0,1],ytitle:'Vinfl!cqflag',constant:good_qflag}
store_data,'IV_log_smo_comb', $
           data=['mvn_lpw_swp1_IV_log_smo','mvn_lpw_swp1_IV_vfloat'], $
           dlim={yrange:[-20,20]}
store_data,'dIV_smo_comb', $
           data=['mvn_lpw_swp1_dIV_smo','mvn_lpw_swp1_IV_vinfl'], $
           dlim={yrange:[-20,20]}
endif                           ;- novinfl



;;; loop through orbits
get_data,'mvn_lpw_swp1_IV_vinfl',data=dvinfl
get_data,'mvn_lpw_swp1_IV_vinfl_qflag',data=dqflag
iorb0 = (norbwin-1)/2
iorb1 = nworb-1 - (norbwin-1)/2
for iorb=iorb0,iorb1 do begin
   orbstr = string(orbnums[iorb],f='(i5.5)')
   trorb = [ tperi0[iorb] , tperi1[iorb] ]
   trfit = [ tperi0[iorb-(norbwin-1)/2] , tperi1[iorb+(norbwin-1)/2] ]

   w = where(finite(scpot_all) and tscpot_all gt trfit[0] and tscpot_all lt trfit[1] , nw )
   times = tscpot_all[w]
   Vswe = scpot_all[w]

   a = [!values.d_nan,!values.d_nan]
   corr = !values.d_nan
   apol = [!values.d_nan,!values.d_nan,!values.d_nan]
   pow = {func:'power_law',h:!values.d_nan,p:!values.d_nan,bkg:!values.d_nan,x0:1.d0}
   Nscat = 0l

   ;;; LPW IV Vinfl v Vswe
   w = where( div.x gt trfit[0] and div.x lt trfit[1], nw )
   if nw gt minNdata then begin
      vinfl2 = interp(dvinfl.y,dvinfl.x,times,/no_ex,interp=maxgap)
      w = where( finite(vinfl2) ,nw )
      if nw gt minNdata then begin
         x = Vswe[w]
         y = -vinfl2[w]
         t = times[w]

;;          alad = ladfit(x,y)     ;- initial fit, obsolete
         apol0 = [ -2.7, .73, -0.012 ]    ;- nominal parameters

         ;;; filter out outliers and fit
;;          w = where( abs(x-(y/alad[1]-alad[0]/alad[1])) lt thld_out , nw ) ;- obsolete
         w = where( abs(apol0[0]+apol0[1]*x+apol0[2]*x^2 - y) lt thld_out , nw )
         Nscat = nw
         if nw gt minNdata then begin
            x2 = x[w]
            y2 = y[w]
            t2 = t[w]
            a = ladfit(x2,y2)   ;- linear fit
            corr = correlate(x2,y2)
            apol = poly_fit(x2,y2,2) ;- polynomial fit
            ww = where(x2 gt 0,nww) ;- power law fit, obsolete
            if nww gt minNdata then begin
               apow = ladfit(x2[ww]^.35,y2[ww]) ;- get initial guess
               pow = {func:'power_law',h:apow[1],p:.35d,bkg:apow[0],x0:1.d0}
               fit,x2[ww],y2[ww],para=pow,itmax=50,verb=-1,names='h p bkg'
            endif
            if keyword_set(scatdir) then begin
               file_mkdir,scatdir
               w2 = where(t2 gt trorb[0] and t2 lt trorb[1], nw2)
               if nw2 gt 0 then begin
                  scat = {t:t2[w2],vswe:x2[w2],vinfl:-y2[w2]}
                  save,scat,filename=scatdir+orbstr+'.sav',/compress
               endif
            endif
         endif

         w = where( dvinfl.x gt trorb[0] and dvinfl.x lt trorb[1] , nw )
         tvinfl = dvinfl.x[w]
         qflag = dqflag.y[w]
         scpot_lin = ( (-dvinfl.y[w]) - a[0] ) / a[1]
         scpot_pol = ( -apol[1] + sqrt(apol[1]^2 - 4.*(apol[0]+dvinfl.y[w])*apol[2]) ) / (2.*apol[2])
         scpot_pow = 10.^( alog10(((-dvinfl.y[w])-pow.bkg > 0.)/pow.h)/pow.p ) ;- obsolete

         w = where( ~finite(scpot_lin) , nw )
         if nw gt 0 then scpot_pow[w] = !values.f_nan
         if nw gt 0 then scpot_pol[w] = !values.f_nan

         ;;; Filter out shadow regions
         get_data, 'wake', data=dwake, dtype=dtype
         if dtype ne 0 then begin
            shadow = interp(float(finite(dwake.y)), dwake.x, tvinfl, /no_ex)
            w = where(shadow gt 0., nw)
            if nw gt 0 then scpot_lin[w] = !values.f_nan
            if nw gt 0 then scpot_pow[w] = !values.f_nan
            if nw gt 0 then scpot_pol[w] = !values.f_nan
         endif

         ;;; Filter out bad fits
         scpot_good = scpot_pol
         wgood = where( qflag gt good_qflag , comp=cw, ncomp=ncw )
         if ncw gt 0 then scpot_good[cw] = !values.f_nan

         ;;; store the results
         store_data,orbstr+'_mvn_swe_lpw_scpot_lin', $
                    data={x:tvinfl,y:scpot_lin}, $
                    dlim={colors:2,datagap:maxgap, $
                          ytitle:'linear fit!cscpot!c[V]'}
         store_data,orbstr+'_mvn_swe_lpw_scpot_pow', $
                    data={x:tvinfl,y:scpot_pow}, $
                    dlim={colors:6,datagap:maxgap, $
                          ytitle:'power law fit!cscpot!c[V]'}
         store_data,orbstr+'_mvn_swe_lpw_scpot_pol', $
                    data={x:tvinfl,y:scpot_pol}, $
                    dlim={colors:1,datagap:maxgap, $
                          ytitle:'poly fit!cscpot!c[V]'}
         store_data,orbstr+'_mvn_swe_lpw_scpot_good', $
                    data={x:tvinfl,y:scpot_good}, $
                    dlim={colors:1,datagap:maxgap, $
                          ytitle:'good!cscpot!c[V]'}
         store_data,orbstr+'_mvn_swe_lpw_scpot_lin_para', $
                    data={x:mean(trorb),y:[[a[0]],[a[1]],[corr]]}, $
                    dlim={psym:1,datagap:maxgap,labflag:1, $
                          labels:['offset','slope','corr'],colors:[2,6,0]}
         store_data,orbstr+'_mvn_swe_lpw_scpot_pow_para', $
                    data={x:mean(trorb),y:[[pow.p],[pow.h],[pow.bkg]]}, $
                    dlim={psym:1,datagap:maxgap,labflag:1, $
                          labels:['power','slope','offset'],colors:[0,2,6]}
         store_data,orbstr+'_mvn_swe_lpw_scpot_pol_para', $
                    data={x:mean(trorb),y:[[apol[0]],[apol[1]],[apol[2]]]}, $
                    dlim={psym:1,datagap:maxgap,labflag:1, $
                          labels:['a0','a1','a2'],colors:[2,6,0]}
         store_data,orbstr+'_mvn_swe_lpw_scpot_Ndata', $
                    data={x:mean(trorb),y:Nscat}, $
                    dlim={psym:1,datagap:maxgap}


         ;;; scat plot
         if keyword_set(plot) then begin
            bin2d,x,y,y,binsize=[.25,.25],xcent=xcent,ycent=ycent,flagnodata=!values.f_nan,binhist=binhist,xrange=[-20,20],yrange=[-20,20]
            w = where(xcent gt 10 ,nw)
            for iw=0,nw-1,2 do begin
               binhist[w[iw],*] = binhist[w[iw],*]+binhist[w[iw]+1,*]
               binhist[w[iw]+1,*] = binhist[w[iw],*]
            endfor
            specplot,xcent,ycent,binhist, $
                     limits={xrange:[-20,20],xstyle:1,yrange:[-20,20],ystyle:1, $
                             xtitle:'Vswe [V]',ytitle:'-Vinfl [V]', $
                             xmargin:[10,8],isotropic:1, $
                             title:time_string(trfit[0])+' -> ' $
                             +time_string(trfit[1]), $
                             no_interp:1,zlog:1, $
                             ztitle:'Ndata'}

            for il=-25,25,5 do oplot,[-100,100],[il,il],linestyle=1
            for il=-25,25,5 do oplot,[il,il],[-100,100],linestyle=1

            xplot = findgen(601)/10.-30.
            oplot,xplot,a[0]+a[1]*xplot,color=2
            oplot,xplot,apol[0]+apol[1]*xplot+apol[2]*xplot^2,color=1
;;             oplot,xplot,pow.bkg+pow.h*xplot^pow.p,color=6
;;             oplot,xplot,alad[0]+alad[1]*(xplot+thld_out),linestyle=2
;;             oplot,xplot,alad[0]+alad[1]*(xplot-thld_out),linestyle=2
            oplot,xplot,apol0[0]+apol0[1]*xplot+apol0[2]*xplot^2+thld_out,linestyle=2
            oplot,xplot,apol0[0]+apol0[1]*xplot+apol0[2]*xplot^2-thld_out,linestyle=2
            xyouts,/norm,color=2,.15,.97,'linear fit!c' + $
                   'y = '+string(a[0],f='(f5.2)') $
                   +string(a[1],f='(f+5.2)')+'x' $
                   +'!cCorr. = '+string(corr,f='(f5.2)') $
                   +'!cNdata = '+string(Nscat,f='(i0)')
;;             xyouts,/norm,color=6,.55,.97,'power law fit!c' + $
;;                    'y = '+string(pow.bkg,f='(f6.2)') $
;;                    +string(pow.h,f='(f+6.2)')+'x^' $
;;                    +string(pow.p,f='(f4.2)')
            xyouts,/norm,color=1,.55,.97,'poly fit!c' + $
                   'y = '+string(apol[0],f='(f6.2)') $
                   +string(apol[1],f='(f+6.2)')+'x' $
                   +string(apol[2],f='(f+8.4)')+'x^2'
            if keyword_set(figdir) then begin
               file_mkdir,figdir+time_string(mean(trorb),tf='scat/YYYY/MM/')
               makepng,figdir+time_string(mean(trorb),tf='scat/YYYY/MM/YYYYMMDD_')+orbstr
            endif
         endif

      endif                     ;- interp Vinfl to times -> minNdata
   endif                        ;- LPW Vinfl v Vswe


   store_data,'scpots', $
              data=[orbstr+'_mvn_swe_lpw_scpot_pol','swe_pos','neg_pot','mvn_sta_c6_scpot',orbstr+'_mvn_swe_lpw_scpot_good'], $
              dlim={labels:['swe/lpw','swe+','swe-','sta','swe/lpw'], $
                    colors:[1,2,6,4,0],labflag:1,datagap:maxgap,yrange:[-20,20], $
                    constant:[0],panel_size:1.5}

   ;;; tplot
   if keyword_set(plot) then begin
      tplot,[ $
            'sta_comb', $
            'swe_comb', $
            'mvn_lpw_swp1_mode_bar', $
            'icur', $
            'mvn_lpw_swp1_IV', $
;            'mvn_lpw_swp1_IV_log', $
            'IV_log_smo_comb', $
            'dIV_smo_comb', $
            'mvn_lpw_swp1_IV_vinfl_qflag', $
            'validiv', $
            'scpots', $
            'alt2' $
            ],trange=trorb,title='orbit #'+orbstr
      tplot_panel,var='icur',oplot='icur_med'
;      tplot_panel,var='scpots',oplot='scpot0_all',psym=3
      if keyword_set(figdir) then begin
         file_mkdir,figdir+time_string(mean(trorb),tf='times/YYYY/MM/')
         makepng,figdir+time_string(mean(trorb),tf='times/YYYY/MM/YYYYMMDD_')+orbstr
      endif
   endif                        ;- plot

endfor                          ;- iorb



;;; concat and sort
tf = ['mvn_swe_lpw_scpot_lin','mvn_swe_lpw_scpot_pol','mvn_swe_lpw_scpot_pow', $
      'mvn_swe_lpw_scpot_lin_para','mvn_swe_lpw_scpot_pol_para','mvn_swe_lpw_scpot_pow_para', $
      'mvn_swe_lpw_scpot_Ndata','mvn_swe_lpw_scpot_good' ]
for itf=0,n_elements(tf)-1 do begin
   tn = tnames('?????_'+tf[itf],ntn)
   if ntn gt 0 then begin
      for itn=0,ntn-1 do begin
         get_data,tn[itn],data=d,dlim=dlim
         if itn eq 0 then begin
            newx = d.x
            newy = d.y
            if tag_exist(d,'V') then newv = d.v
         endif else begin
            newx = [newx,d.x]
            newy = [newy,d.y]
            if tag_exist(d,'V') then begin
               if size(d.v,/n_dim) eq 2 then newv = [newv,d.v]
            endif
         endelse
      endfor
      if tag_exist(d,'V') then $
         store_data,tf[itf],data={x:newx,y:newy,v:newv},dlim=dlim $
      else store_data,tf[itf],data={x:newx,y:newy},dlim=dlim
      tplot_sort,tf[itf]
      store_data,tn,/del
   endif
endfor


def_scpot = 'mvn_swe_lpw_scpot_good'
get_data,def_scpot,data=d
store_data,'mvn_swe_lpw_scpot',data=d, $
           dlim={datagap:maxgap,ytitle:'SWEA-LPW!cscpot!c[V]'}

store_data,'scpots', $
           data=['mvn_swe_lpw_scpot_pol','swe_pos','neg_pot','mvn_sta_c6_scpot','mvn_swe_lpw_scpot'], $
           dlim={labels:['swe/lpw','swe+','swe-','sta','swe/lpw'], $
                 colors:[1,2,6,4,0],labflag:1,datagap:maxgap,yrange:[-20,20], $
                 constant:0}

end



