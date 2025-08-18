;+
; PROCEDURE:
;       mex_marsis_tplot
; PURPOSE:
;       generates tplot variables from data stored in common blocks
; CALLING SEQUENCE:
;       mex_marsis_tplot
; KEYWORDS:
;       
; CREATED BY:
;       Yuki Harada on 2017-05-11
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2023-06-20 01:30:32 -0700 (Tue, 20 Jun 2023) $
; $LastChangedRevision: 31900 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/marsis/mex_marsis_tplot.pro $
;-

pro mex_marsis_tplot, types=types

if ~keyword_set(types) then types = ['geometry','eledens_bmag','ionogram'] else types = strlowcase(types)

@mex_marsis_com

;;; geometry
if total(strmatch(types,'geometry')) gt 0 then begin
   if size(marsis_geometry,/type) eq 0 then $
      dprint,'No geometry data stored' $
   else begin
      times = marsis_geometry.time
      if total(finite(marsis_geometry.alt)) gt 0 then $
         store_data,'mex_marsis_alt',data={x:times,y:marsis_geometry.alt}, $
                    dlim={ytitle:'MEX!cAlt.!c[km]',datagap:60}
      if total(finite(marsis_geometry.lat)) gt 0 then $
         store_data,'mex_marsis_lat',data={x:times,y:marsis_geometry.lat}, $
                    dlim={ytitle:'MEX!cLat.!c[deg.]',datagap:60}
      if total(finite(marsis_geometry.lon)) gt 0 then $
         store_data,'mex_marsis_lon',data={x:times,y:marsis_geometry.lon}, $
                    dlim={ytitle:'MEX!cLon.!c[deg.]',datagap:60}
      if total(finite(marsis_geometry.sol_lon)) gt 0 then $
         store_data,'mex_marsis_sol_lon', $
                    data={x:times,y:marsis_geometry.sol_lon}, $
                    dlim={ytitle:'Solar Lon.!c[deg.]',datagap:60}
      if total(finite(marsis_geometry.subsol_lat)) gt 0 then $
         store_data,'mex_marsis_subsol_lat', $
                    data={x:times,y:marsis_geometry.subsol_lat}, $
                    dlim={ytitle:'Subsolar Lat.!c[deg.]',datagap:60}
      if total(finite(marsis_geometry.subsol_lon)) gt 0 then $
         store_data,'mex_marsis_subsol_lon', $
                    data={x:times,y:marsis_geometry.subsol_lon}, $
                    dlim={ytitle:'Subsolar Lon.!c[deg.]',datagap:60}
      if total(finite(marsis_geometry.loctime)) gt 0 then $
         store_data,'mex_marsis_locsoltime', $
                    data={x:times,y:marsis_geometry.loctime}, $
                    dlim={ytitle:'MEX!cLocal Sol. Time',datagap:60}
   endelse
endif
;;; geometry


;;; eledens_bmag
if total(strmatch(types,'eledens_bmag')) gt 0 then begin
   if size(marsis_eledens_bmag,/type) eq 0 then $
      dprint,'No eledens_bmag data stored' $
   else begin
      times = marsis_eledens_bmag.time
      store_data,'mex_marsis_fpe', $
                 data={x:times,y:marsis_eledens_bmag.fpe}, $
                 dlim={ytitle:'Fpe!c[kHz]',datagap:10}
      store_data,'mex_marsis_fpe_quality', $
                 data={x:times,y:marsis_eledens_bmag.fpe_quality}, $
                 dlim={ytitle:'Fpe!cQuality',datagap:10}
      store_data,'mex_marsis_eledens', $
                 data={x:times,y:marsis_eledens_bmag.eledens}, $
                 dlim={ytitle:'MARSIS!cLocal Ne!c[cm!u-3!n]',datagap:10, $
                       ylog:1}
      store_data,'mex_marsis_tce', $
                 data={x:times,y:marsis_eledens_bmag.tce}, $
                 dlim={ytitle:'Tce!c[msec]',datagap:10}
      store_data,'mex_marsis_fce_quality', $
                 data={x:times,y:marsis_eledens_bmag.fce_quality}, $
                 dlim={ytitle:'Fce!cQuality',datagap:10}
      store_data,'mex_marsis_bmag', $
                 data={x:times,y:marsis_eledens_bmag.bmag}, $
                 dlim={ytitle:'MARSIS!cLocal |B|!c[nT]',datagap:10}
   endelse
endif
;;; eledens_bmag



;;; ionogram
if total(strmatch(types,'ionogram')) gt 0 then begin
   mex_marsis_radargram
   mex_marsis_spectrogram
endif
;;; ionogram


;;; ss
if total(strmatch(types,'ss')) gt 0 then begin
   if size(marsis_ss,/type) eq 0 then $
      dprint,'No SS data stored' $
   else begin
      if total(finite(marsis_ss.alt)) gt 0 then $
         store_data,'mex_marsis_ss_alt', $
                    data={x:marsis_ss.time,y:marsis_ss.alt}, $
                    dlim={ytitle:'Alt.!c[km]',datagap:60}
         store_data,'mex_marsis_ss_lon', $
                    data={x:marsis_ss.time,y:marsis_ss.lon}, $
                    dlim={ytitle:'Lon.!c[deg.]',datagap:60}
         store_data,'mex_marsis_ss_lat', $
                    data={x:marsis_ss.time,y:marsis_ss.lat}, $
                    dlim={ytitle:'Lat.!c[deg.]',datagap:60}
         store_data,'mex_marsis_ss_loct', $
                    data={x:marsis_ss.time,y:marsis_ss.loct}, $
                    dlim={ytitle:'Local True!cSolar Time!c[h]',datagap:60}
         store_data,'mex_marsis_ss_sza', $
                    data={x:marsis_ss.time,y:marsis_ss.sza}, $
                    dlim={ytitle:'SZA!c[deg.]',datagap:60}
         ;;; https://pds-geosciences.wustl.edu/mex/mex-m-marsis-3-rdr-ss-v2/mexmrs_1001/document/marsis_eaicd.pdf
         ;;; The first sample of a processed frame is positioned at an altitude of 25 km above the Martian ellipsoid, while each subsequent sample is 1/1.4 MHz, or 0.7143 μs from the previous one.
         td = 0.7143 * indgen(512) ;- micro sec
         freqs = [1.8,3,4,5]
         for ifreq=0,n_elements(freqs)-1 do begin
            w = where( round(marsis_ss.freq1/1e5) eq round(freqs[ifreq]*10) , nw )
            if nw gt 0 then begin
               store_data,'mex_marsis_ss_radargram_1z_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].data1_z),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:1,zrange:[1,1e4],ztitle:'modulus'}
            endif
            w = where( round(marsis_ss.freq2/1e5) eq round(freqs[ifreq]*10) , nw )
            if nw gt 0 then begin
               store_data,'mex_marsis_ss_radargram_2z_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].data2_z),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:1,zrange:[1,1e4],ztitle:'modulus'}
            endif
         endfor
   endelse
endif
;;; ss


;;; ssall
if total(strmatch(types,'ssall')) gt 0 then begin
   if size(marsis_ss,/type) eq 0 then $
      dprint,'No SS data stored' $
   else begin
      if total(finite(marsis_ss.alt)) gt 0 then $
         store_data,'mex_marsis_ss_alt', $
                    data={x:marsis_ss.time,y:marsis_ss.alt}, $
                    dlim={ytitle:'Alt.!c[km]',datagap:60}
         store_data,'mex_marsis_ss_lon', $
                    data={x:marsis_ss.time,y:marsis_ss.lon}, $
                    dlim={ytitle:'Lon.!c[deg.]',datagap:60}
         store_data,'mex_marsis_ss_lat', $
                    data={x:marsis_ss.time,y:marsis_ss.lat}, $
                    dlim={ytitle:'Lat.!c[deg.]',datagap:60}
         store_data,'mex_marsis_ss_loct', $
                    data={x:marsis_ss.time,y:marsis_ss.loct}, $
                    dlim={ytitle:'Local True!cSolar Time!c[h]',datagap:60}
         store_data,'mex_marsis_ss_sza', $
                    data={x:marsis_ss.time,y:marsis_ss.sza}, $
                    dlim={ytitle:'SZA!c[deg.]',datagap:60}
         ;;; https://pds-geosciences.wustl.edu/mex/mex-m-marsis-3-rdr-ss-v2/mexmrs_1001/document/marsis_eaicd.pdf
         ;;; The first sample of a processed frame is positioned at an altitude of 25 km above the Martian ellipsoid, while each subsequent sample is 1/1.4 MHz, or 0.7143 μs from the previous one.
         td = 0.7143 * indgen(512) ;- micro sec
         freqs = [1.8,3,4,5]
         for ifreq=0,n_elements(freqs)-1 do begin
            w = where( round(marsis_ss.freq1/1e5) eq round(freqs[ifreq]*10) , nw )
            if nw gt 0 then begin
               store_data,'mex_marsis_ss_radargram_1m_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].data1_m),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz -1 Filter!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:1,zrange:[1,1e4],ztitle:'modulus'}
               store_data,'mex_marsis_ss_radargram_1z_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].data1_z),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:1,zrange:[1,1e4],ztitle:'modulus'}
               store_data,'mex_marsis_ss_radargram_1p_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].data1_p),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz +1 Filter!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:1,zrange:[1,1e4],ztitle:'modulus'}
               store_data,'mex_marsis_ss_radargram_phase_1m_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].phase1_m),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz -1 Filter!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:0,zrange:[-!pi,!pi],ztitle:'phase'}
               store_data,'mex_marsis_ss_radargram_phase_1z_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].phase1_z),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:0,zrange:[-!pi,!pi],ztitle:'phase'}
               store_data,'mex_marsis_ss_radargram_phase_1p_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].phase1_p),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz +1 Filter!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:0,zrange:[-!pi,!pi],ztitle:'phase'}
            endif
            w = where( round(marsis_ss.freq2/1e5) eq round(freqs[ifreq]*10) , nw )
            if nw gt 0 then begin
               store_data,'mex_marsis_ss_radargram_2m_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].data2_m),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz -1 Filter!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:1,zrange:[1,1e4],ztitle:'modulus'}
               store_data,'mex_marsis_ss_radargram_2z_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].data2_z),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:1,zrange:[1,1e4],ztitle:'modulus'}
               store_data,'mex_marsis_ss_radargram_2p_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].data2_p),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz +1 Filter!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:1,zrange:[1,1e4],ztitle:'modulus'}
               store_data,'mex_marsis_ss_radargram_phase_2m_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].phase2_m),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz -1 Filter!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:0,zrange:[-!pi,!pi],ztitle:'phase'}
               store_data,'mex_marsis_ss_radargram_phase_2z_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].phase2_z),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:0,zrange:[-!pi,!pi],ztitle:'phase'}
               store_data,'mex_marsis_ss_radargram_phase_2p_'+string(freqs[ifreq]*10,f='(i0)'), $
                          data={x:marsis_ss[w].time,y:transpose(marsis_ss[w].phase2_p),v:td/100}, $
                          dlim={ytitle:string(freqs[ifreq],f='(f3.1)')+' MHz +1 Filter!cTime Delay!c[10!u-4!n s]', $
                                datagap:60,yrange:[max(td/100),0],ystyle:1,spec:1, $
                                zlog:0,zrange:[-!pi,!pi],ztitle:'phase'}
            endif
         endfor
   endelse
endif
;;; ssall


;;; xml
if total(strmatch(types,'xml')) gt 0 then begin
   if size(marsis_xml_trace,/type) eq 0 then $
      dprint,'No trace xml data stored' $
   else begin

      times = marsis_xml_trace.time

      fpe = marsis_xml_trace.fpe * 1e6
      q_fpe = marsis_xml_trace.q_fpe
      w = where( q_fpe eq 0 , nw )
      if nw gt 0 then fpe[w] = !values.f_nan
      edens = (fpe/8980.)^2

      store_data,'mex_marsis_xml_fpe',data={x:times,y:fpe}, $
                 dlim={ytitle:'Fpe!c[Hz]',psym:4,ylog:1}
      store_data,'mex_marsis_xml_fpe_quality',data={x:times,y:q_fpe}, $
                 dlim={ytitle:'Fpe!cQuality',psym:4}
      store_data,'mex_marsis_xml_eledens',data={x:times,y:edens}, $
                 dlim={ytitle:'MARSIS!cLocal Ne!c[cm!u-3!n]',psym:4,ylog:1}

      tce = marsis_xml_trace.tce * 1e-3
      q_tce = marsis_xml_trace.q_tce
      w = where( q_tce eq 0 , nw )
      if nw gt 0 then tce[w] = !values.f_nan
      bmag = 1./(28.*tce)

      store_data,'mex_marsis_xml_tce',data={x:times,y:tce}, $
                 dlim={ytitle:'Tce!c[s]',psym:4}
      store_data,'mex_marsis_xml_tce_quality',data={x:times,y:q_tce}, $
                 dlim={ytitle:'Tce!cQuality',psym:4}
      store_data,'mex_marsis_xml_bmag',data={x:times,y:bmag}, $
                 dlim={ytitle:'MARSIS!cLocal |B|!c[nT]',psym:4}

      n_itrc = total(finite(marsis_xml_trace[*].itrc[*,0]),1)
      store_data,'mex_marsis_xml_n_itrc',data={x:times,y:n_itrc}, $
                 dlim={psym:4}

      max_f = max(marsis_xml_trace[*].itrc[*,0],/nan,dim=1)
      store_data,'mex_marsis_xml_maxf_itrc',data={x:times,y:max_f}, $
                 dlim={psym:4,ytitle:'fp(max)!c[MHz]'}

   endelse
endif
;;; xml



end
