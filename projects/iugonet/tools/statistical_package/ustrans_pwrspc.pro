;+
;PROCEDURE: 
; ustrans_pwrspc, varname, newname = newname
; 
;PURPOSE:
; Calculate the local power spectrum for given time-series data and return the structure
; which contains {st:, ph: freq:, time:} where st is the S Transform and
;   store the tplot variable.
;                   
;INPUT:
; varname = variable passed to get_data, example - uts_mag_ccnv
;
;KEYWORDS:
; newname: set output variable name
; \help               explains all the keywords and parameters
; \verbose            flags errors and size
; \samplingrate       if set returns array of frequency
; \maxfreq            maximum frequency performing the S transform
; \minfreq            minimum frequency performing the S transform
; \freqsmplingrate    frequency interval 
; \power              returns the power spectrum
; \abs                returns the absolute value spectrum
; \Rremoveedge        removes the edge with a 5% taper, and takes out least-sqares fit parabola
; 
; 
;HISTORY:
; 14-aug-2012, Atsuki Shinbori
;$LastChangedBy: jwl $
;$LastChangedDate: 2014-01-22 15:54:40 -0800 (Wed, 22 Jan 2014) $
;$LastChangedRevision: 13976 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/iugonet/tools/statistical_package/ustrans_pwrspc.pro $
;-

pro ustrans_pwrspc, varname, factor, newname = newname, trange = trange, help = help, verbose = verbose, samplingrate = samplingrate, maxfreq = maxfreq, minfreq = minfreq  $
                   , freqsamplingrate = freqsamplingrate, power = power, abs = abs, removeedge = removeedge,maskedges=maskedges $
                   , example = example
  print,varname
  tdeflag, varname,"linear",/overwrite
  get_data, varname, data = d, dlimits = dlimits, limits = limits
  if is_struct(d) eq 0 then begin
    dprint, 'No data in '+varname
  endif else begin
    sdy = size(d.y, /n_dimension)
      if(sdy eq 2) then begin
          ndj = n_elements(d.y[0, *])
          if(ndj eq 3) then begin
              split_vec, varname, polar = polar, names_out = vn_j
          endif else if(ndj gt 1) then begin
              split_vec, varname, names_out = vn_j, $
                suffix = '_'+strcompress(string(indgen(ndj)), /remove_all)
          endif
          for j = 0, ndj-1 do begin
              ustrans_pwrspc, vn_j[j],factor, newname = newname, trange = trange, verbose = verbose, samplingrate = samplingrate, maxfreq = maxfreq, minfreq = minfreq  $
                   , freqsamplingrate = freqsamplingrate, power = power, abs = abs, removeedge = removeedge,maskedges=maskedges $
                   , example = example
          endfor
          Return
      endif else if(sdy eq 1) then begin
         ;Definition of tplot_names of ts_trans data:
          nvn = varname+'_stpwrspc'      
         ;Now do the power spectrum
          y = d.y
          t = d.x
          if(n_elements(trange) eq 2) then begin
              tr = time_double(trange)
              ok = where(t ge tr[0] and t lt tr[1], nok)
              if(nok eq 0) then begin
                  dprint, 'No data in time range'
                  dprint,  time_string(tr)
                  dprint, 'No Dynamic Power spectrum for: '+varname
                  Return
              endif else begin
                  t = t[ok] & y = y[ok]
              endelse
          endif
          ;Filter out NaN's
          Ok = where(finite(y), nok)
          if(nok eq 0) then begin
              dprint, 'No finite data in time range'
              Return
          endif else begin
              t = t[ok] & y = y[ok]
          endelse
          t00 = d.x[0]
          t = t-t00

         ;=====================================
         ; The S-transformation for given data:
         ;=====================================
          y1 = s_trans(y, factor, help = help, verbose = verbose, samplingrate = samplingrate, $
                       maxfreq = maxfreq, minfreq = minfreq, freqsamplingrate = freqsamplingrate, $
                       power = power, abs = abs, removeedge = removeedge, maskedges=maskedges, $
                       example = example)

         ;Definition of tplot_names of ts_trans data:
          newname = nvn

          str_element, dlimits, 'data_type', 'dynamic_power_spectrum', /add
          str_element, dlimits, 'ytitle', 'Freq (Hz)'
          dd = {x:temporary(t+t00), y:temporary(y1.st), v:temporary(1/y1.freq)}
          print,newname
          store_data, newname, data = dd, dlimits = dlimits, limits = limits
          options, newname, spec = 1
          options, newname, ytitle = newname + '!CPeriod',ztitle = 'Amplitude'
          zlim,newname,0,max(y1.st)
          newname = nvn
       endif
   endelse 
end
