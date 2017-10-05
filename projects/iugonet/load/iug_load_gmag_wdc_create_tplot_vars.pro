;+
;Procedure: IUG_LOAD_GMAG_WDC_CREATE_TPLOT_VARS
; iug_load_gmag_wdc_create_tplot_vars, $
;    sname = sname, $
;    element = element, $
;    resolution = res, $
;    level = level, $
;    tplot_name, $
;    tplot_ytitle, tplot_ysubtitle, tplot_labels, $
;    tplot_colors, tplot_dlimit
;
;Notes:
;  This procedure is called from load procedures for WDC format data,
;  'iug_load_gmag_wdc*' provided by WDC Kyoto.
;
;Written by:  Daiki Yoshida,  Aug 2010
;Updated by:  Daiki Yoshida,  Sep 14, 2010
;Updated by:  Daiki Yoshida,  Nov 12, 2010
;Updated by:  Daiki Yoshida,  Jan 11, 2011
;Updated by:  Yukinobu KOYAMA, Jan 21, 2012
;
;-

pro iug_load_gmag_wdc_create_tplot_vars, $
    sname = sname, $
    element = element, $
    resolution = res, $
    level = level, $
    tplot_name, $
    tplot_ytitle, tplot_ysubtitle, tplot_labels, $
    tplot_colors, tplot_dlimit
    
  ; for acknowledgment
  acknowledg_str_dst = $
    'The DST data are provided by the World Data Center for Geomagnetism, Kyoto, and'+ $
    ' are not for redistribution (http://wdc.kugi.kyoto-u.ac.jp/). Furthermore, we thank'+ $
    ' the geomagnetic observatories (Kakioka [JMA], Honolulu and San Juan [USGS], Hermanus'+ $
    ' [RSA], Alibag [IIG]), NiCT, INTERMAGNET, and many others for their cooperation to'+ $
    ' make the Dst index available.'$
   +'The distribution of DST data has been partly supported by the IUGONET (Inter-university Upper atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'
  acknowledg_str = $
    'The rules for the data use and exchange are defined'+ $
    ' by the Guide on the World Data Center System '+ $
    ' (ICSU Panel on World Data Centers, 1996).'+$
    ' Note that information on the appropriate institution(s)'+$
    ' is also supplied with the WDC data sets.'+$
    ' If the data are used in publications and presentations,'+$
    ' the data suppliers and the WDC for Geomagnetism, Kyoto'+$
    ' must properly be acknowledged.'+$
    ' Commercial use and re-distribution of WDC data are, in general, not allowed.'+$
    ' Please ask for the information of each observatory to the WDC.'$
   +'The distribution of the data has been partly supported by the IUGONET (Inter-university Upper atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'
    
  if strlowcase(sname) eq 'dst' then begin
    tplot_dlimit = create_struct('data_att', $
      create_struct('acknowledgment', acknowledg_str_dst))
  endif else begin
    tplot_dlimit = create_struct('data_att', $
      create_struct('acknowledgment', acknowledg_str))
  endelse
  
  
  ; create tplot variable options
  if strlowcase(sname) eq 'dst' then begin
  
    if strcmp(level, 'prov', 4, /fold_case) eq 1 then begin
      tplot_name = 'wdc_mag_dst_prov'
      tplot_ytitle = 'Prov. Dst'
    endif else begin
      tplot_name = 'wdc_mag_dst'
      tplot_ytitle = 'Dst'
    endelse
    tplot_ysubtitle = '[nT]'
    tplot_labels = 'Dst'
    
  endif else if strlowcase(sname) eq 'sym' or strlowcase(sname) eq 'asy' then begin
  
    if n_elements(element) eq 1 then begin
      tplot_name = 'wdc_mag_' + strlowcase(sname+'-'+element)
      tplot_ytitle = strupcase(sname+'-'+element)
    endif else begin
      tplot_name = 'wdc_mag_' + strlowcase(sname)
      tplot_ytitle = strupcase(sname)
    endelse
    tplot_ysubtitle = '[nT]'
    
    if n_elements(element) gt 0 then begin
      tplot_labels = strupcase(sname+'-'+element)
    endif else begin
      tplot_labels = strupcase(sname)
    endelse
    
  endif else if strlowcase(sname) eq 'ae' then begin
  
    if (~keyword_set(res)) then res = 'min'
    
    if n_elements(element) eq 1 then begin
    
      tplot_name = 'wdc_mag_a' + strlowcase(element)
      tplot_ytitle = 'A' + strupcase(element)
      
      if strupcase(element) eq 'X' then begin
        tplot_ysubtitle = '[#]'
      endif else begin
        tplot_ysubtitle = '[nT]'
      endelse
      
    endif else begin
      tplot_name = 'wdc_mag_ae'
      tplot_ytitle = 'AE'
      tplot_ysubtitle = '[nT]'
    endelse
    
    if n_elements(element) gt 0 then begin
      tplot_labels = 'A' + strupcase(element)
    endif else begin
      tplot_labels = 'AE'
    endelse
    
    if strcmp(level, 'prov', 4, /fold_case) eq 1 then begin
      tplot_name = tplot_name + '_prov'
      tplot_ytitle = 'Prov. ' + tplot_ytitle
    endif
    
    if res eq 'min' then begin
      tplot_name = tplot_name + '_1min'
      tplot_ytitle = tplot_ytitle + '!c(1-min)'
    endif else if res eq 'hour' or res eq 'hr' then begin
      tplot_name = tplot_name + '_1hr'
      tplot_ytitle = tplot_ytitle + '!c(hourly)'
    endif
    
    
    
  endif else begin
  
    tplot_name = 'wdc_mag_' + strlowcase(sname)
    tplot_ytitle = strupcase(sname)
    
    if n_elements(element) eq 1 then begin
      tplot_name = tplot_name + '_' + strlowcase(element)
      tplot_ytitle = tplot_ytitle + ' ' + strupcase(element)
      
      if strupcase(element) eq 'D' or $
        strupcase(element) eq 'I' then begin
        tplot_ysubtitle = '[deg]'
      endif else begin
        tplot_ysubtitle = '[nT]'
      endelse
    endif
    
    if strcmp(level, 'prov', 4, /fold_case) eq 1 then begin
      tplot_name = tplot_name + '_prov'
      tplot_ytitle = tplot_ytitle + ' Prov.'
    endif else if strcmp(level, 'ql', 2, /fold_case) eq 1 or $
      strlowcase(level) eq 'quicklook' then begin
      tplot_name = tplot_name + '_ql'
      tplot_ytitle = tplot_ytitle + ' QL'
    endif
    
    if res eq 'min' then begin
      tplot_name = tplot_name + '_1min'
      tplot_ytitle = tplot_ytitle + '!c(1-min)'
    endif else if res eq 'hour' or res eq 'hr' then begin
      tplot_name = tplot_name + '_1hr'
      tplot_ytitle = tplot_ytitle + '!c(hourly)'
    endif
    
    if n_elements(element) gt 0 then begin
      tplot_labels = strupcase(element)
      for i = 0l, n_elements(element) - 1 do begin
        if tplot_labels[i] eq 'D' or $
          tplot_labels[i] eq 'I' then begin
          tplot_labels[i] = tplot_labels[i] + ' [deg]'
        endif else begin
          tplot_labels[i] = tplot_labels[i] + ' [nT]'
        endelse
      endfor
    endif else begin
      tplot_labels = strupcase(sname)
    endelse
    
  endelse

  ; setup tplot_colors
  tplot_colors=intarr(n_elements(element))
  for i = 0l, n_elements(element)-1 do begin
     if element[i] eq 'H' then tplot_colors[i]=2
     if element[i] eq 'D' then tplot_colors[i]=4
     if element[i] eq 'Z' then tplot_colors[i]=6
     if element[i] eq 'X' then tplot_colors[i]=3
     if element[i] eq 'Y' then tplot_colors[i]=5
     if element[i] eq 'F' then tplot_colors[i]=0
     if element[i] eq 'I' then tplot_colors[i]=1
  endfor
  
end
