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
; $LastChangedDate: 2018-04-06 01:38:33 -0700 (Fri, 06 Apr 2018) $
; $LastChangedRevision: 25009 $
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
