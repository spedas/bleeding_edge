;+
; PROCEDURE:
;     kgy_map_make_pad
; PURPOSE:
;     generates PAD tplot vairables
; CALLING SEQUENCE:
;     kgy_map_make_pad,sensor=[0,1],erange=[100,200]
; INPUTS:
;     none
; OPTIONAL KEYWORDS:
;     sensor: 0: ESA-S1, 1: ESA-S2, 2: IMA, 3: IEA (Def. [0,1])
;     trange: time range (Def. all)
;     erange: energy range (Def: [150,250])
;     num_pa: number of pitch angle bins 
;             (Def: 32 for high-angular resolutions, 16 for low res)
;     noinfoangle: if set, uses FOV angles instead of accurate INFO angles
;     nocntcorr: if set, does not conduct count correction (event & trash correction)
;     gf_thld: gfactor thresholds = [ esa1, esa2, ima, iea ]
;              gf < gf_thld => gf = 0
;              Def: [ 2.e-4, 2.e-5, 1.e-6, 1.e-6 ]
;     bkgd: background counts (Def. 0)
;           currently just subtracts uniform bkgd from each solid angle bin
;     thrange: |theta| range (def. [10,80])
;     suffix: suffix of the tplot variable name
; NOTES:
;     In high angular resolution mode, only high sensitivity angles
;     are used by default (i.e., counts in small gfactor bins are
;     discarded).
; CREATED BY:
;     Yuki Harada on 2015-01-23
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2025-02-20 21:55:42 -0800 (Thu, 20 Feb 2025) $
; $LastChangedRevision: 33143 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/kgy_map_make_pad.pro $
;-

pro kgy_map_make_pad, sensor=sensor, trange=trange, nocntcorr=nocntcorr, erange=erange, num_pa=num_pa, gf_thld=gf_thld, bkgd=bkgd, noinfoangle=noinfoangle, thrange=thrange, suffix=suffix, verbose=verbose

@kgy_pace_com
@kgy_lmag_com

  if ~keyword_set(nocntcorr) then cntcorr = 1 else contcorr = 0
  if ~keyword_set(noinfoangle) then infoangle = 1 else infoangle = 0

  if size(sensor,/type) eq 0 then sensor = [0,1] else sensor = long(sensor)
  if not keyword_set(erange) then erange = [150,250] $
  else erange = [min(erange),max(erange)]
  if keyword_set(num_pa) then begin
     num_pa_h = num_pa & num_pa_l = num_pa
  endif else begin
     num_pa_h = 32 & num_pa_l = 16
  endelse
  if ~keyword_set(gf_thld) or n_elements(gf_thld) ne 4 then begin
     gf_thld_esa1 = 2.e-4
     gf_thld_esa2 = 2.e-5
     gf_thld_ima = 1.e-6
     gf_thld_iea = 1.e-6
  endif else begin
     gf_thld_esa1 = gf_thld[0]
     gf_thld_esa2 = gf_thld[1]
     gf_thld_ima = gf_thld[2]
     gf_thld_iea = gf_thld[3]
  endelse
  if size(thrange,/n_ele) ne 2 then thrange = [10,80]
  if keyword_set(trange) then $
     trange = minmax(time_double(trange)) else $
        trange = time_double(['2007-09-14/00:00', '2009-06-19/24:00'])
  if ~keyword_set(suffix) then suffix=''

;- PACE
  for sensorID=0,3 do begin

     idx = where( sensor eq sensorID , idx_cnt )
     if idx_cnt eq 0 then continue ;- -> next sensorID 

     header_arr = 0
     case sensorID of
        0: begin
           sensorname = 'ESA-S1'
           sensornname = 'esa1'
           if size(esa1_header_arr,/tname) eq 'STRUCT' then $
              header_arr = esa1_header_arr
           get3d_func = 'kgy_esa1_get3d'
           gf_thld_now = gf_thld_esa1
           pad_h_type = '00'XB
           pad_h_type2 = -1
           pad_l_type = '01'XB
           pad_l_type2 = -1
        end
        1: begin
           sensorname = 'ESA-S2'
           sensornname = 'esa2'
           if size(esa2_header_arr,/tname) eq 'STRUCT' then $
              header_arr = esa2_header_arr
           get3d_func = 'kgy_esa2_get3d'
           gf_thld_now = gf_thld_esa2
           pad_h_type = '00'XB
           pad_h_type2 = -1
           pad_l_type = '01'XB
           pad_l_type2 = -1
        end
        2: begin
           sensorname = 'IMA'
           sensornname = 'ima'
           if size(ima_header_arr,/tname) eq 'STRUCT' then $
              header_arr = ima_header_arr
           get3d_func = 'kgy_ima_get3d'
           gf_thld_now = gf_thld_ima
           pad_h_type = '41'XB
           pad_h_type2 = -1
           pad_l_type = '42'XB
           pad_l_type2 = '43'XB
        end
        3: begin
           sensorname = 'IEA'
           sensornname = 'iea'
           if size(iea_header_arr,/tname) eq 'STRUCT' then $
              header_arr = iea_header_arr
           get3d_func = 'kgy_iea_get3d'
           gf_thld_now = gf_thld_iea
           pad_h_type = '81'XB
           pad_h_type2 = '82'XB
           pad_l_type = '80'XB
           pad_l_type2 = -1
        end
     endcase
     if size(header_arr,/tname) ne 'STRUCT' then continue ;- -> next sensorID

     times = $
        time_double( string(header_arr[*].yyyymmdd,format='(i8.8)'),tformat='YYYYMMDD' ) $
        + header_arr[*].time_ms/1d3 $
        ;; time_double( string(header_arr[*].yyyymmdd,format='(i8.8)') $
        ;;              +string(header_arr[*].hhmmss,format='(i6.6)'), $
        ;;              tformat='YYYYMMDDhhmmss' ) $
        + header_arr[*].time_resolution / 2.d3
     indexes = header_arr[*].index

     idx_time = where(times ge trange[0] and times le trange[1] , idx_time_cnt )
     if idx_time_cnt eq 0 then continue

     times = times[idx_time]
     indexes = indexes[idx_time]
     s = sort(times)
     stimes = times[s]
     sindexes = indexes[s]
     idx_uniq = uniq(stimes)

     pads = replicate(!values.f_nan,n_elements(idx_uniq),num_pa_h)
     pangles = replicate(!values.f_nan,n_elements(idx_uniq),num_pa_h)
     padsc = replicate(!values.f_nan,n_elements(idx_uniq),num_pa_h)

     for i=0l,n_elements(idx_uniq)-1 do begin
        if i mod 10 eq 0 then dprint,dlevel=1,verbose=verbose,sensornname,i,' /',n_elements(idx_uniq)-1,' : '+time_string(stimes[idx_uniq[i]])
        theindex = sindexes[idx_uniq[i]]
        dat = call_function(get3d_func,index=theindex,/sabin,cntcorr=cntcorr,infoangle=infoangle)
        if dat.valid ne 1 then continue

        if keyword_set(bkgd) then dat.data = dat.data - bkgd > 0 ;- bkgd subtraction
        dat2 = conv_units(dat,'eflux')

        idx_0 = where(dat.gfactor lt gf_thld_now $
                      or abs(dat.theta) lt thrange[0] $
                      or abs(dat.theta) gt thrange[1], idx_0_cnt)
        if idx_0_cnt gt 0 then dat.bins[idx_0] = 0

        if dat.type eq pad_h_type or dat.type eq pad_h_type2 then npa = num_pa_h $
        else if dat.type eq pad_l_type or dat.type eq pad_l_type2 then npa = num_pa_l else continue

        if total(finite(dat.magf)) ne 3 then continue
        xyz_to_polar,dat.magf,theta=bth,phi=bph
        pa = pangle(dat.theta,dat.phi,bth,bph)
        pab = fix(pa/180.*npa)  < (npa-1)

        for ipa=0,npa-1 do begin
           w = where( pab eq ipa and dat.bins eq 1 $
                      and dat.energy ge erange[0] and dat.energy le erange[1] $
                      , nw)
           if nw eq 0 then continue
           ww = dat.data * 0. & ww[w] = 1.
           pads[i,ipa] = total(dat2.data*dat.domega*dat.denergy*ww,/nan) $
                         /total(dat.domega*dat.denergy*ww,/nan)
           padsc[i,ipa] = total(dat.data*ww,/nan)
        endfor

        pangles[i,indgen(npa)] = (findgen(npa)+.5)*180./npa

     endfor

     w = where( ~finite(pangles[*,0]) , nw ) ;- prevents crash when making eps
     if nw gt 0 then pangles[w,*] = transpose(rebin((findgen(num_pa_h)+.5)*180./num_pa_h,num_pa_h,nw))

     store_data,'kgy_'+sensornname+'_pa_eflux'+suffix,verbose=verbose, $
                data={x:stimes[idx_uniq],y:pads,v:pangles}, $
                dlim={spec:1,ytitle:sensorname+'!c'+ $
                      string(erange[0],format='(i0)')+'-'+ $
                      string(erange[1],format='(i0)') $
                      +' eV!cPitch angle!c[deg.]', $
                      constant:[90], $
                      yrange:[0,180],ystyle:1,yminor:3,yticks:4, $
                      zlog:1,ztitle:'eflux',datagap:63,minzlog:1.e-30}
     store_data,'kgy_'+sensornname+'_pa_counts'+suffix,verbose=verbose, $
                data={x:stimes[idx_uniq],y:padsc,v:pangles}, $
                dlim={spec:1,ytitle:sensorname+'!c'+ $
                      string(erange[0],format='(i0)')+'-'+ $
                      string(erange[1],format='(i0)') $
                      +' eV!cPitch angle!c[deg.]', $
                      constant:[90], $
                      yrange:[0,180],ystyle:1,yminor:3,yticks:4, $
                      zlog:1,ztitle:'counts',datagap:63,minzlog:1.e-30}
  endfor                        ;- sensorID loop


end
