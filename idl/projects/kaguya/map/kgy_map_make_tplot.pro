;+
; PROCEDURE:
;     kgy_map_make_tplot
; PURPOSE:
;     generates tplot variables from data stored in common blocks:
;        energy-time spectrograms from PACE data,
;        time-series B-fields and s/c locations from LMAG data 
; CALLING SEQUENCE:
;     kgy_map_make_tplot, sensor=[0,1]
; INPUTS:
;     none
; OPTIONAL KEYWORDS:
;     sensor: 0: ESA-S1, 1: ESA-S2, 2: IMA, 3: IEA, 4: LMAG (Def. all)
;     trange: time range (Def. all)
;     bkgd: background counts (Def. 0)
;           currently just subtracts uniform bkgd from each solid angle bin
;     suffix: suffix of the tplot variable names
; CREATED BY:
;     Yuki Harada on 2015-01-23
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2025-02-24 23:31:40 -0800 (Mon, 24 Feb 2025) $
; $LastChangedRevision: 33148 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/kgy_map_make_tplot.pro $
;-

pro kgy_map_make_tplot, sensor=sensor, trange=trange, bkgd=bkgd, suffix=suffix, verbose=verbose

@kgy_pace_com
@kgy_lmag_com

  if size(sensor,/type) eq 0 then sensor = [0,1,2,3,4] else sensor = long(sensor)
  if ~keyword_set(bkgd) then bkgd = 0. else bkgd = float(bkgd)
  if ~keyword_set(suffix) then suffix = ''

  eff = .6

  trange = timerange(trange)

  for sensorID=0,4 do begin

     idx = where( sensor eq sensorID , idx_cnt )
     if idx_cnt eq 0 then continue ;- -> next sensorID

;- PACE
     if sensorID le 3 then begin
        header_arr = 0
        case sensorID of
           0: begin
              sensorname = 'ESA-S1'
              sensornname = 'esa1'
              if size(esa1_header_arr,/tname) eq 'STRUCT' then $
                 header_arr = esa1_header_arr
              if size(esa1_fov_str,/tname) eq 'STRUCT' then $
                 fov_str = esa1_fov_str
              if size(esa1_info_str,/tname) eq 'STRUCT' then $
                 info_str = esa1_info_str
              if size(esa1_type00_arr,/tname) eq 'STRUCT' then $
                 data_arr0 = esa1_type00_arr
              if size(esa1_type01_arr,/tname) eq 'STRUCT' then $
                 data_arr1 = esa1_type01_arr
              if size(esa1_type02_arr,/tname) eq 'STRUCT' then $
                 data_arr2 = esa1_type02_arr
           end
           1: begin
              sensorname = 'ESA-S2'
              sensornname = 'esa2'
              if size(esa2_header_arr,/tname) eq 'STRUCT' then $
                 header_arr = esa2_header_arr
              if size(esa2_fov_str,/tname) eq 'STRUCT' then $
                 fov_str = esa2_fov_str
              if size(esa2_info_str,/tname) eq 'STRUCT' then $
                 info_str = esa2_info_str
              if size(esa2_type00_arr,/tname) eq 'STRUCT' then $
                 data_arr0 = esa2_type00_arr
              if size(esa2_type01_arr,/tname) eq 'STRUCT' then $
                 data_arr1 = esa2_type01_arr
              if size(esa2_type02_arr,/tname) eq 'STRUCT' then $
                 data_arr2 = esa2_type02_arr
           end
           2: begin
              sensorname = 'IMA'
              sensornname = 'ima'
              if size(ima_header_arr,/tname) eq 'STRUCT' then $
                 header_arr = ima_header_arr
              if size(ima_fov_str,/tname) eq 'STRUCT' then $
                 fov_str = ima_fov_str
              if size(ima_info_str,/tname) eq 'STRUCT' then $
                 info_str = ima_info_str
              if size(ima_type40_arr,/tname) eq 'STRUCT' then $
                 data_arr3 = ima_type40_arr
              if size(ima_type41_arr,/tname) eq 'STRUCT' then $
                 data_arr0 = ima_type41_arr
              if size(ima_type42_arr,/tname) eq 'STRUCT' then $
                 data_arr1 = ima_type42_arr
              if size(ima_type43_arr,/tname) eq 'STRUCT' then $
                 data_arr4 = ima_type43_arr
           end
           3: begin
              sensorname = 'IEA'
              sensornname = 'iea'
              if size(iea_header_arr,/tname) eq 'STRUCT' then $
                 header_arr = iea_header_arr
              if size(iea_fov_str,/tname) eq 'STRUCT' then $
                 fov_str = iea_fov_str
              if size(iea_info_str,/tname) eq 'STRUCT' then $
                 info_str = iea_info_str
              if size(iea_type80_arr,/tname) eq 'STRUCT' then $
                 data_arr0 = iea_type80_arr
              if size(iea_type81_arr,/tname) eq 'STRUCT' then $
                 data_arr1 = iea_type81_arr
              if size(iea_type82_arr,/tname) eq 'STRUCT' then $
                 data_arr5 = iea_type82_arr
           end
        endcase
        if size(header_arr,/tname) ne 'STRUCT' then continue ;- -> next sensorID

        if size(info_str,/tname) ne 'STRUCT' then noinfo = 1 else noinfo = 0

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

        counts = replicate(!values.f_nan,n_elements(idx_uniq),32)
        efluxes = replicate(!values.f_nan,n_elements(idx_uniq),32)
        energies = replicate(!values.f_nan,n_elements(idx_uniq),32)
        dts = replicate(!values.f_nan,n_elements(idx_uniq))
        rams = replicate(!values.f_nan,n_elements(idx_uniq))
        modes = replicate(0l,n_elements(idx_uniq))
        types = replicate(!values.f_nan,n_elements(idx_uniq))

        for iarr=0,5 do begin
           if iarr eq 0 then begin
              if size(data_arr0,/type) ne 8 then continue ;- [E,A,P]
              data_arr = data_arr0
              totalcnts = transpose(total(total(data_arr.cnt*long(data_arr.cnt ne uint(-1))-bkgd>0,3),2))
              fincnts = transpose(total(total(long(data_arr.cnt ne uint(-1)),3),2))
              w = where(~fincnts,nw)
              if nw gt 0 then totalcnts[w] = !values.f_nan
           endif
           if iarr eq 1 then begin
              if size(data_arr1,/type) ne 8 then continue ;- [E,A,P]
              data_arr = data_arr1
              totalcnts = transpose(total(total(data_arr.cnt*long(data_arr.cnt ne uint(-1))-bkgd>0,3),2))
              fincnts = transpose(total(total(long(data_arr.cnt ne uint(-1)),3),2))
              w = where(~fincnts,nw)
              if nw gt 0 then totalcnts[w] = !values.f_nan
           endif
           if iarr eq 2 then begin
              if size(data_arr2,/type) ne 8 then continue    ;- [E,P]
              data_arr = data_arr2
              ;;; decode type02 counts, see read_pbf_v1.c
              tmp_cnt = ishft( data_arr.cnt , -5 ) and '7ff'x
              tmp_sft = data_arr.cnt and '1f'x
              decode_cnt = ishft( tmp_cnt , tmp_sft )
              totalcnts = transpose( total( decode_cnt[0:3,*,*], 2 ) )
              totalcnts = totalcnts *!values.f_nan ;- FIXME: type02 data format
           endif
           if iarr eq 3 then begin
              if size(data_arr3,/type) ne 8 then continue ;- [P,E,M]
              data_arr = data_arr3
              totalcnts = transpose(total(total(data_arr.cnt*long(data_arr.cnt ne uint(-1))-bkgd>0,3),1))
              fincnts = transpose(total(total(long(data_arr.cnt ne uint(-1)),3),1))
              w = where(~fincnts,nw)
              if nw gt 0 then totalcnts[w] = !values.f_nan
           endif
           if iarr eq 4 then begin
              if size(data_arr4,/type) ne 8 then continue ;- [M,E,P,A]
              data_arr = data_arr4
              totalcnts = transpose(total(total(total(data_arr.cnt*long(data_arr.cnt ne uint(-1))-bkgd>0,4),3),1))
              fincnts = transpose(total(total(total(long(data_arr.cnt ne uint(-1)),4),3),1))
              w = where(~fincnts,nw)
              if nw gt 0 then totalcnts[w] = !values.f_nan
           endif
           if iarr eq 5 then begin
              if size(data_arr5,/type) ne 8 then continue ;- IEA type82
              data_arr = data_arr5
              totalcnts = transpose(total(total(data_arr.cnt*long(data_arr.cnt ne uint(-1))-bkgd>0,3),2))
              fincnts = transpose(total(total(long(data_arr.cnt ne uint(-1)),3),2))
              w = where(~fincnts,nw)
              if nw gt 0 then totalcnts[w] = !values.f_nan
;;                  totalcnts = transpose(total(data_arr.s_cnt*long(data_arr.s_cnt eq uint(-1))-bkgd>0,2))
           endif

           idx = value_locate( data_arr.index, sindexes[idx_uniq] )
           w = where( data_arr[idx].index - sindexes[idx_uniq] eq 0 $
                      and idx ge 0 ,nw)
           if nw gt 0 then begin
              dts[idx_uniq[w]] = header_arr[idx_uniq[w]].time_resolution/1000.
              rams[idx_uniq[w]] = header_arr[idx_uniq[w]].svs_tbl
              modes[idx_uniq[w]] = header_arr[idx_uniq[w]].mode
              types[idx_uniq[w]] = header_arr[idx_uniq[w]].type
              for iw=0,nw-1 do begin
                 ram = header_arr[idx_uniq[w[iw]]].svs_tbl
                 sene = sort(fov_str.ene[ram,*])
                 energies[idx_uniq[w[iw]],*] = fov_str.ene[ram,sene]*1000
                 counts[idx_uniq[w[iw]],*] = totalcnts[idx[w[iw]],sene]
                 if ~noinfo then begin
                    totalgf = reform(total(total(info_str.gfactor_4x16[ram,*,*,*],4),3)) * eff
                    integ_t = 16./header_arr[idx_uniq[w[iw]]].sampl_time
                    efluxes[idx_uniq[w[iw]],*] = totalcnts[idx[w[iw]],sene]/(integ_t*totalgf[sene])
                 endif
              endfor
           endif
        endfor                  ;- iarr
        store_data,'kgy_'+sensornname+'_en_counts'+suffix, verbose=verbose, $
                   data={x:stimes[idx_uniq],y:counts,v:energies}, $
                   dlim={spec:1,ylog:1,ytitle:sensorname+'!cEnergy!c[eV]', $
                         yrange:minmax(energies),ystyle:1,yticklen:-.01,$
                         zlog:1,ztitle:'counts',datagap:63,minzlog:1.e-30}
        if ~noinfo then $
        store_data,'kgy_'+sensornname+'_en_eflux'+suffix, verbose=verbose, $
                   data={x:stimes[idx_uniq],y:efluxes,v:energies}, $
                   dlim={spec:1,ylog:1,ytitle:sensorname+'!cEnergy!c[eV]', $
                         yrange:minmax(energies),ystyle:1,yticklen:-.01, $
                         zlog:1,ztitle:'eflux',datagap:63,minzlog:1.e-30}
        store_data,'kgy_'+sensornname+'_dt'+suffix, verbose=verbose, $
                   data={x:stimes[idx_uniq],y:dts}, $
                   dlim={ytitle:sensorname+'!cdt!c[s]',yrange:[0,32],colors:'r', $
                         psym:1}
        store_data,'kgy_'+sensornname+'_ram'+suffix, verbose=verbose, $
                   data={x:stimes[idx_uniq],y:rams}, $
                   dlim={ytitle:sensorname+'!cram #',yrange:[0,8],colors:'r', $
                         psym:1}
        modes_str = string(modes,f='(z)')
        modes_num = long(modes_str)
        store_data,'kgy_'+sensornname+'_mode'+suffix, verbose=verbose, $
                   data={x:stimes[idx_uniq],y:modes_num}, $
                   dlim={ytitle:sensorname+'!cmode',yrange:[11,29], $
                         colors:'r',psym:1}
        store_data,'kgy_'+sensornname+'_type'+suffix, verbose=verbose, $
                   data={x:stimes[idx_uniq],y:types}, $
                   dlim={ytitle:sensorname+'!ctype',colors:'r', $
                         psym:1}
     endif


;- LMAG
     if sensorID eq 4 then begin
        if size(lmag_pub,/tname) eq 'STRUCT' then begin
           idxt = where( lmag_pub.time ge trange[0] $
                         and lmag_pub.time le trange[1] , idxt_cnt )
           if idxt_cnt eq 0 then continue
           store_data,'kgy_lmag_Rme'+suffix, verbose=verbose, $
                      data={x:lmag_pub[idxt].time,y:transpose(lmag_pub[idxt].Rme)}, $
                      dlim={ytitle:'Rme!c[km]',colors:['b','g','r'], $
                            labels:['X','Y','Z'],labflag:1,constant:0, $
                            spice_frame:'MOON_ME'}
           store_data,'kgy_lmag_Bme'+suffix, verbose=verbose, $
                      data={x:lmag_pub[idxt].time,y:transpose(lmag_pub[idxt].Bme)}, $
                      dlim={ytitle:'Bme!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            spice_frame:'MOON_ME'}
           data_att = {units:'km',coord_sys:'gse',st_type:'pos'}
           store_data,'kgy_lmag_Rgse'+suffix, verbose=verbose, $
                      data={x:lmag_pub[idxt].time,y:transpose(lmag_pub[idxt].Rgse)}, $
                      dlim={ytitle:'Rgse!c[km]',colors:['b','g','r'], $
                            labels:['X','Y','Z'],labflag:1,constant:0, $
                            data_att:data_att,spice_frame:'GSE'}
           data_att = {units:'nT',coord_sys:'gse'}
           store_data,'kgy_lmag_Bgse'+suffix, verbose=verbose, $
                      data={x:lmag_pub[idxt].time,y:transpose(lmag_pub[idxt].Bgse)}, $
                      dlim={ytitle:'Bgse!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            data_att:data_att,spice_frame:'GSE'}
        endif

        if size(lmag_all,/tname) eq 'STRUCT' then begin
           idxt = where( lmag_all.time ge trange[0] $
                         and lmag_all.time le trange[1] , idxt_cnt )
           if idxt_cnt eq 0 then continue
           store_data,'kgy_lmag_Rme'+suffix, verbose=verbose, $
                      data={x:lmag_all[idxt].time,y:transpose(lmag_all[idxt].Rme)}, $
                      dlim={ytitle:'Rme!c[km]',colors:['b','g','r'], $
                            labels:['X','Y','Z'],labflag:1,constant:0, $
                            spice_frame:'MOON_ME'}
           store_data,'kgy_lmag_Bme'+suffix, verbose=verbose, $
                      data={x:lmag_all[idxt].time,y:transpose(lmag_all[idxt].Bme)}, $
                      dlim={ytitle:'Bme!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            spice_frame:'MOON_ME'}
           store_data,'kgy_lmag_Rgse'+suffix, verbose=verbose, $
                      data={x:lmag_all[idxt].time,y:transpose(lmag_all[idxt].Rgse)}, $
                      dlim={ytitle:'Rgse!c[km]',colors:['b','g','r'], $
                            labels:['X','Y','Z'],labflag:1,constant:0, $
                            spice_frame:'GSE'}
           store_data,'kgy_lmag_Bgse'+suffix, verbose=verbose, $
                      data={x:lmag_all[idxt].time,y:transpose(lmag_all[idxt].Bgse)}, $
                      dlim={ytitle:'Bgse!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            spice_frame:'GSE'}
           store_data,'kgy_lmag_Rsse'+suffix, verbose=verbose, $
                      data={x:lmag_all[idxt].time,y:transpose(lmag_all[idxt].Rsse)}, $
                      dlim={ytitle:'Rsse!c[km]',colors:['b','g','r'], $
                            labels:['X','Y','Z'],labflag:1,constant:0, $
                            spice_frame:'SSE'}
           store_data,'kgy_lmag_Bsse'+suffix, verbose=verbose, $
                      data={x:lmag_all[idxt].time,y:transpose(lmag_all[idxt].Bsse)}, $
                      dlim={ytitle:'Bsse!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            spice_frame:'SSE'}
           store_data,'kgy_lmag_Temp'+suffix, verbose=verbose, $
                      data={x:lmag_all[idxt].time,y:lmag_all[idxt].Temp}, $
                      dlim={ytitle:'Temp!c[degC]'}
           store_data,'kgy_lmag_sza'+suffix, verbose=verbose, $
                      data={x:lmag_all[idxt].time, $
                            y:acos(lmag_all[idxt].Rsse[0]/sqrt(lmag_all[idxt].Rsse[0]^2+lmag_all[idxt].Rsse[1]^2+lmag_all[idxt].Rsse[2]^2))*!radeg }, $
                      dlim={yrange:[0,180],ystyle:1,yticks:4,yminor:3, $
                            ytitle:'SZA!c[deg.]',colors:'b'}
        endif

        if size(lmag_all32hz,/tname) eq 'STRUCT' then begin
           idxt = where( lmag_all32hz.time ge trange[0] $
                         and lmag_all32hz.time le trange[1] , idxt_cnt )
           if idxt_cnt eq 0 then continue
           store_data,'kgy_lmag_32Hz_Rme'+suffix, verbose=verbose, $
                      data={x:lmag_all32hz[idxt].time,y:transpose(lmag_all32hz[idxt].Rme)}, $
                      dlim={ytitle:'Rme!c[km]',colors:['b','g','r'], $
                            labels:['X','Y','Z'],labflag:1,constant:0, $
                            spice_frame:'MOON_ME'}
           store_data,'kgy_lmag_32Hz_Bme'+suffix, verbose=verbose, $
                      data={x:lmag_all32hz[idxt].time,y:transpose(lmag_all32hz[idxt].Bme)}, $
                      dlim={ytitle:'Bme!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            spice_frame:'MOON_ME'}
           store_data,'kgy_lmag_32Hz_Rgse'+suffix, verbose=verbose, $
                      data={x:lmag_all32hz[idxt].time,y:transpose(lmag_all32hz[idxt].Rgse)}, $
                      dlim={ytitle:'Rgse!c[km]',colors:['b','g','r'], $
                            labels:['X','Y','Z'],labflag:1,constant:0, $
                            spice_frame:'GSE'}
           store_data,'kgy_lmag_32Hz_Bgse'+suffix, verbose=verbose, $
                      data={x:lmag_all32hz[idxt].time,y:transpose(lmag_all32hz[idxt].Bgse)}, $
                      dlim={ytitle:'Bgse!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            spice_frame:'GSE'}
           store_data,'kgy_lmag_32Hz_Rsse'+suffix, verbose=verbose, $
                      data={x:lmag_all32hz[idxt].time,y:transpose(lmag_all32hz[idxt].Rsse)}, $
                      dlim={ytitle:'Rsse!c[km]',colors:['b','g','r'], $
                            labels:['X','Y','Z'],labflag:1,constant:0, $
                            spice_frame:'SSE'}
           store_data,'kgy_lmag_32Hz_Bsse'+suffix, verbose=verbose, $
                      data={x:lmag_all32hz[idxt].time,y:transpose(lmag_all32hz[idxt].Bsse)}, $
                      dlim={ytitle:'Bsse!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            spice_frame:'SSE'}
           store_data,'kgy_lmag_32Hz_Temp'+suffix, verbose=verbose, $
                      data={x:lmag_all32hz[idxt].time,y:lmag_all32hz[idxt].Temp}, $
                      dlim={ytitle:'Temp!c[degC]'}
           store_data,'kgy_lmag_32Hz_sza'+suffix, verbose=verbose, $
                      data={x:lmag_all32hz[idxt].time, $
                            y:acos(lmag_all32hz[idxt].Rsse[0]/sqrt(lmag_all32hz[idxt].Rsse[0]^2+lmag_all32hz[idxt].Rsse[1]^2+lmag_all32hz[idxt].Rsse[2]^2))*!radeg }, $
                      dlim={yrange:[0,180],ystyle:1,yticks:4,yminor:3, $
                            ytitle:'SZA!c[deg.]',colors:'b'}
        endif

        if size(lmag_sat,/tname) eq 'STRUCT' then begin
           idxt = where( lmag_sat.time ge trange[0] $
                         and lmag_sat.time le trange[1] , idxt_cnt )
           if idxt_cnt eq 0 then continue
           store_data,'kgy_lmag_alt'+suffix, verbose=verbose, $
                      data={x:lmag_sat[idxt].time,y:lmag_sat[idxt].alt}, $
                      dlim={ytitle:'Altitude!c[km]'}
           store_data,'kgy_lmag_lat'+suffix, verbose=verbose, $
                      data={x:lmag_sat[idxt].time,y:lmag_sat[idxt].lat}, $
                      dlim={ytitle:'Latitude!c[deg.]',colors:'r', $
                            yrange:[-90,90],ystyle:1,yticks:4,yminor:3}
           store_data,'kgy_lmag_lon'+suffix, verbose=verbose, $
                      data={x:lmag_sat[idxt].time,y:lmag_sat[idxt].lon}, $
                      dlim={ytitle:'Longitude!c[deg.]',colors:'g', $
                            yrange:[-180,180],ystyle:1,yticks:4,yminor:3}
           store_data,'kgy_lmag_lonlat'+suffix, verbose=verbose, $
                      data={x:lmag_sat[idxt].time, $
                            y:[[lmag_sat[idxt].lon/180.],[lmag_sat[idxt].lat/90.]]}, $
                      dlim={ytitle:'Lon, Lat!c[deg.]',colors:['g','r'], $
                            ystyle:1,yrange:[-1,1],yticks:4,yminor:3, $
                            labels:['Lon/180','Lat/90'],labflag:1,constant:0}
           store_data,'kgy_lmag_Bsat'+suffix, verbose=verbose, $
                      data={x:lmag_sat[idxt].time,y:transpose(lmag_sat[idxt].Bsat)}, $
                      dlim={ytitle:'Bsat!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            spice_frame:'SELENE_M_SPACECRAFT'}
        endif

        if size(lmag_sat32hz,/tname) eq 'STRUCT' then begin
           idxt = where( lmag_sat32hz.time ge trange[0] $
                         and lmag_sat32hz.time le trange[1] , idxt_cnt )
           if idxt_cnt eq 0 then continue
           store_data,'kgy_lmag_32Hz_alt'+suffix, verbose=verbose, $
                      data={x:lmag_sat32hz[idxt].time,y:lmag_sat32hz[idxt].alt}, $
                      dlim={ytitle:'Altitude!c[km]'}
           store_data,'kgy_lmag_32Hz_lat'+suffix, verbose=verbose, $
                      data={x:lmag_sat32hz[idxt].time,y:lmag_sat32hz[idxt].lat}, $
                      dlim={ytitle:'Latitude!c[deg.]',colors:'r', $
                            yrange:[-90,90],ystyle:1,yticks:4,yminor:3}
           store_data,'kgy_lmag_32Hz_lon'+suffix, verbose=verbose, $
                      data={x:lmag_sat32hz[idxt].time,y:lmag_sat32hz[idxt].lon}, $
                      dlim={ytitle:'Longitude!c[deg.]',colors:'g', $
                            yrange:[-180,180],ystyle:1,yticks:4,yminor:3}
           store_data,'kgy_lmag_32Hz_lonlat'+suffix, verbose=verbose, $
                      data={x:lmag_sat32hz[idxt].time, $
                            y:[[lmag_sat32hz[idxt].lon/180.],[lmag_sat32hz[idxt].lat/90.]]}, $
                      dlim={ytitle:'Lon, Lat!c[deg.]',colors:['g','r'], $
                            ystyle:1,yrange:[-1,1],labels:['Lon','Lat'],labflag:1,constant:0, $
                            yticks:4,ytickname:['-180, -90',' ','0',' ','180, 90'], $
                            yminor:3}
           store_data,'kgy_lmag_32Hz_Bsat'+suffix, verbose=verbose, $
                      data={x:lmag_sat32hz[idxt].time,y:transpose(lmag_sat32hz[idxt].Bsat)}, $
                      dlim={ytitle:'Bsat!c[nT]',colors:['b','g','r'], $
                            labels:['Bx','By','Bz'],labflag:1,constant:0, $
                            spice_frame:'SELENE_M_SPACECRAFT'}
        endif
     endif                      ;- LMAG

  endfor                        ;- sensorID loop


  validtnames = tnames('kgy_*')
  if total(strlen(validtnames)) ne 0 then begin
     for i_tname=0,n_elements(validtnames)-1 do tplot_sort,validtnames[i_tname]
  endif


end
