;+
; PROCEDURE:
;     kgy_map_load
; PURPOSE:
;     downloads and reads in Kaguya MAP/PACE+LMAG and SPICE data files
;     and generates tplot variables
;      (wrapper routine for 'kgy_read_*' and 'kgy_map_make_tplot')
; CALLING SEQUENCE:
;     timespan,'2008-01-01',2
;     kgy_map_load, sensor=[0,1,4]
; OPTIONAL KEYWORDS:
;     sensor: 0: ESA-S1, 1: ESA-S2, 2: IMA, 3: IEA, 4: LMAG (Def. all) 
;     append: if set, does not clear data common blocks
;     trange: time range
;     bkgd: background counts
;           currently just subtracts uniform bkgd from each solid angle bin
;     nospice: if set, does not load SPICE
; NOTES:
;     Eflux is converted from total counts at each energy step
;     without taking into account relative sensitivity variation and 
;     count correction.
; CREATED BY:
;     Yuki Harada on 2014-07-02
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-15 00:54:22 -0700 (Tue, 15 May 2018) $
; $LastChangedRevision: 25223 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/kgy_map_load.pro $
;-

pro kgy_map_load, sensor=sensor, append=append, files=files, infofiles=infofiles, fovfiles=fovfiles, trange=trange, bkgd=bkgd, pbfpubversion=pbfpubversion, lmagpubversion=lmagpubversion, _extra=_extra, public=public, nospice=nospice


if size(public,/type) eq 0 then public = 1 ;- set public by default
if size(sensor,/type) eq 0 then sensor = [0,1,2,3,4] else sensor = long(sensor)
if ~keyword_set(append) then kgy_clear_com,/onlydata ;- overwrite old data by default
if ~keyword_set(pbfpubversion) then pbfpubversion='003' ;- incapable of version search
pbfpubversion2 = strmid(pbfpubversion,2,1)+'.0'
if ~keyword_set(lmagpubversion) then lmagpubversion='1.0' ;- incapable of version search

rL = 1737.4

;;; public version
if keyword_set(public) then begin

   ;;; PACE information files
   w = where(sensor eq 0 or sensor eq 1 or sensor eq 2 or sensor eq 3, nw)
   if nw gt 0 then begin
      kgy_read_fov,/load        ;- load fov files
      kgy_read_inf,/load        ;- load inf files
   endif

   ;;; ESA1
   w = where(sensor eq 0, nw)
   if nw gt 0 then begin
      pf = 'sln-l-pace-3-pbf1-v'+pbfpubversion2+'/YYYYMMDD/data/IPACE_PBF1_yyMMDD_ESA1_V'+pbfpubversion+'.dat.gz'
;      pf = 'IPACE_PBF1_yyMMDD_ESA1_V'+pbfpubversion ;- obsolete
      f = kgy_file_retrieve(pf,trange=trange,/public)
      if total(strlen(f)) gt 0 then kgy_read_pbf, f
      kgy_map_make_tplot, sensor=[0], trange=trange, bkgd=bkgd
   endif

   ;;; ESA2
   w = where(sensor eq 1, nw)
   if nw gt 0 then begin
      pf = 'sln-l-pace-3-pbf1-v'+pbfpubversion2+'/YYYYMMDD/data/IPACE_PBF1_yyMMDD_ESA2_V'+pbfpubversion+'.dat.gz'
;      pf = 'IPACE_PBF1_yyMMDD_ESA2_V'+pbfpubversion ;- obsolete
      f = kgy_file_retrieve(pf,trange=trange,/public)
      if total(strlen(f)) gt 0 then kgy_read_pbf, f
      kgy_map_make_tplot, sensor=[1], trange=trange, bkgd=bkgd
   endif

   ;;; IMA
   w = where(sensor eq 2, nw)
   if nw gt 0 then begin
      pf = 'sln-l-pace-3-pbf1-v'+pbfpubversion2+'/YYYYMMDD/data/IPACE_PBF1_yyMMDD_IMA_V'+pbfpubversion+'.dat.gz'
;      pf = 'IPACE_PBF1_yyMMDD_IMA_V'+pbfpubversion ;- obsolete
      f = kgy_file_retrieve(pf,trange=trange,/public)
      if total(strlen(f)) gt 0 then kgy_read_pbf, f
      kgy_map_make_tplot, sensor=[2], trange=trange, bkgd=bkgd
   endif

   ;;; IEA
   w = where(sensor eq 3, nw)
   if nw gt 0 then begin
      pf = 'sln-l-pace-3-pbf1-v'+pbfpubversion2+'/YYYYMMDD/data/IPACE_PBF1_yyMMDD_IEA_V'+pbfpubversion+'.dat.gz'
;      pf = 'IPACE_PBF1_yyMMDD_IEA_V'+pbfpubversion ;- obsolete
      f = kgy_file_retrieve(pf,trange=trange,/public)
      if total(strlen(f)) gt 0 then kgy_read_pbf, f
      kgy_map_make_tplot, sensor=[3], trange=trange, bkgd=bkgd
   endif

   ;;; LMAG
   w = where(sensor eq 4, nw)
   if nw gt 0 then begin
      pf = 'sln-l-lmag-3-mag-ts-v'+lmagpubversion+'/nominal/YYYYMMDD/data/MAG_TSYYYYMMDD.dat' ;- -2008-10-31
;      pf = 'MAG_TSYYYYMMDD'     ;- 2008 obsolete
      f = kgy_file_retrieve(pf,trange=trange,/public)
      if total(strlen(f)) gt 0 then kgy_read_lmag, f

      pf = 'sln-l-lmag-3-mag-ts-v'+lmagpubversion+'/optional/YYYYMMDD/data/MAG_TSOPYYYYMMDD.dat' ;- 2008-11-01-
;      pf = 'MAG_TSOPYYYYMMDD'   ;- 2009 obsolete
      f = kgy_file_retrieve(pf,trange=trange,/public)
      if total(strlen(f)) gt 0 then kgy_read_lmag, f
      kgy_map_make_tplot, sensor=[4], trange=trange
   endif

   ;;; LMAG + SPICE
   if ~keyword_set(nospice) then begin
      kk = kgy_spice_kernels(/load,trange=trange)
      ;;; available frames: SELENE_M_SPACECRAFT, MOON_ME, SSE, GSE

      ;;; add Bsat, generate tplot, etc.
      @kgy_lmag_com
      if size(lmag_pub,/type) eq 8 and size(lmag_sat,/type) ne 8 then begin
         ttt = lmag_pub.time
         rme = lmag_pub.rme
         bme = lmag_pub.bme
         bgse = lmag_pub.bgse

         cart_to_sphere,rme[0,*],rme[1,*],rme[2,*],rrr,lat,lon
         alt = reform(rrr-rL)   ;- not very precise
         lat = reform(lat)
         lon = reform(lon)
         store_data,'kgy_lmag_lat',data={x:ttt,y:lat}, $
                    dlim={ytitle:'Latitude!c[deg.]',colors:'r', $
                          yrange:[-90,90],ystyle:1,yticks:4,yminor:3}
         store_data,'kgy_lmag_lon',data={x:ttt,y:lon}, $
                    dlim={ytitle:'Longitude!c[deg.]',colors:'g', $
                          yrange:[-180,180],ystyle:1,yticks:4,yminor:3}
         store_data,'kgy_lmag_lonlat',data={x:ttt,y:[[lon/180.],[lat/90.]]}, $
                    dlim={ytitle:'Lon, Lat!c[deg.]',colors:['g','r'], $
                          ystyle:1,yrange:[-1,1],yticks:4,yminor:3, $
                          labels:['Lon/180','Lat/90'],labflag:1,constant:0}

         ;;; SAT
         bsat = spice_vector_rotate(bme,ttt,'MOON_ME','SELENE_M_SPACECRAFT',check='SELENE')
         lmag_sat_line $
            = {time:0.d, alt:!values.f_nan, lat:!values.f_nan, lon:!values.f_nan, Bsat:fltarr(3)}
         lmag_sat = replicate( lmag_sat_line, n_elements(ttt) )
         lmag_sat.time = ttt
         lmag_sat.bsat = bsat   ;- store Bsat in common block
         store_data,'kgy_lmag_Bsat',data={x:ttt,y:transpose(bsat)}, $
                    dlim={ytitle:'Bsat!c[nT]',colors:['b','g','r'], $
                          labels:['Bx','By','Bz'],labflag:1,constant:0, $
                          spice_frame:'SELENE_M_SPACECRAFT'}

         ;;; SSE
         rsse = spice_body_pos('SELENE','MOON',utc=ttt,frame='SSE', $
                               check='SELENE')
         store_data,'kgy_lmag_Rsse',data={x:ttt,y:transpose(rsse)}, $
                    dlim={ytitle:'Rsse!c[km]',colors:['b','g','r'], $
                          labels:['X','Y','Z'],labflag:1,constant:0, $
                          spice_frame:'SSE'}
         alt = total(rsse^2,1)^.5-rL ;- alt from SPICE
         store_data,'kgy_lmag_alt',data={x:ttt,y:alt}, $
                    dlim={ytitle:'Altitude!c[km]'}
         sza = reform( acos(rsse[0,*]/total(rsse^2,1)^.5)*!radeg )
         store_data,'kgy_lmag_sza',data={x:ttt,y:sza}, $
                    dlim={yrange:[0,180],ystyle:1,yticks:4,yminor:3, $
                          ytitle:'SZA!c[deg.]',colors:'b',constant:90}
         bsse = spice_vector_rotate(bgse,ttt,'GSE','SSE')
         store_data,'kgy_lmag_Bsse',data={x:ttt,y:transpose(bsse)}, $
                    dlim={ytitle:'Bsse!c[nT]',colors:['b','g','r'], $
                          labels:['Bx','By','Bz'],labflag:1,constant:0, $
                          spice_frame:'SSE'}
      endif
   endif

   return
endif




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; private stuff below
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;- set default paths to files, will be appended to local_data_dir
infopath = 'pace/INFO/*.dat'
fovpath = 'pace/FOV/FOV_ANGLE_*/*/*angle*'
pbfpath = 'pace/pbf/LEVEL1_VER1/YYYYMMDD/PBF1_C_YYYYMMDD_*_I.DAT*'
lmagpath = 'lmag/???/YYYYMM/magYYYYMMDD.*.1sec*'

trange = timerange(trange)

s = kgy_file_source(_extra=_extra)

;- read in files
if keyword_set(infofiles) then kgy_read_inf, infofiles else begin
   if sensor[0] ne 4 and size(esa1_info_str,/type) ne 8 then begin
      f = file_search( s.local_data_dir + infopath )
      if total(strlen(f)) gt 0 then kgy_read_inf, f
   endif
endelse
if keyword_set(fovfiles) then kgy_read_fov, fovfiles else begin
   if sensor[0] ne 4 and size(esa1_fov_str,/type) ne 8 then begin
      f = file_search( s.local_data_dir + fovpath )
      if total(strlen(f)) gt 0 then kgy_read_fov, f
   endif
endelse

if keyword_set(files) then begin
   idx = where( strmatch(files,'*/PBF*') eq 1 , idx_cnt )
   if idx_cnt gt 0 then kgy_read_pbf,files[idx],trange=trange

   idx = where( strmatch(files,'*/mag*') eq 1 , idx_cnt )
   if idx_cnt gt 0 then kgy_read_lmag,files[idx],trange=trange
endif else begin


   f = file_search(time_intervals(trange=trange,tf=s.local_data_dir+pbfpath,/daily))
   fpbf = ''
   senstrs = ['*ESA1*','*ESA2*','*IMA*','*IEA*','*LMAG*']
   for isen=0,n_elements(sensor)-1 do begin
      w0 = where(strmatch(f,senstrs[sensor[isen]]),nw0)
      if nw0 gt 0 then fpbf = [fpbf,f[w0]]
   endfor
   if n_elements(fpbf) gt 1 then begin
      f = fpbf[1:n_elements(fpbf)-1]
      kgy_read_pbf,f,trange=trange
   endif

   w = where(sensor eq 4, nw)
   if nw gt 0 then begin
      f = file_search(time_intervals(trange=trange,tf=s.local_data_dir+lmagpath,/daily))
      kgy_read_lmag,f,trange=trange
   endif
endelse


;- generates tplot variables
kgy_map_make_tplot, sensor=sensor, trange=trange, bkgd=bkgd


end
