;+
;	Name:       THM_MAKE_AE
;
;	Purpose:    This routine calculates the "pseudo" AE, AL, and AU geomagnetic
;                   indices by using ground magnetometer data from THEMIS GBOs. The names
;                   of all stations used for calculation are printed on the screen.
;                   In future, it will be possible to include ground data from other
;                   magnetometer networks. Note that currently the calculation of
;                   the "pseudo" indices does not subtract quiet day variation but
;                   simply the median.
;
;       Syntax:     THM_MAKE_AE [, RES = float] [, SITES = string ] [, /NO_LOAD ]
;
;	Parameters: None.
;
;	Keywords:   res     = sampling interval (by default 60 sec)
;                   sites   = observatory name; default is to use high-latitude
;                             For dates prior to 2015-01-01 THEMIS sites are: 
;                             ['atha', 'chbg', 'ekat', 'fsim', 'fsmi', 'fykn', $
;                              'gako', 'gbay', 'gill', 'inuv', 'kapu', 'kian', $
;                              'kuuj', 'mcgr', 'pgeo', 'pina', 'rank', 'snap', $
;                              'snkq', 'tpas', 'whit', 'yknf', 'fcc', 'cmo', $
;                              'naq', 'lrv'] ;made an array to facilitate the use of split_vec later
;                             For dates on or after 2015-01-01 sites are:
;                   sites = ['atha', 'chbg', 'ekat', 'fsim', 'fsmi', 'fykn', $
;                             'gako', 'gbay', 'gill', 'inuv', 'kapu', 'kian', $
;                             'kuuj', 'mcgr', 'pgeo', 'pina', 'rank', 'snap', $
;                             'snkq', 'tpas', 'whit', 'yknf', 'fcc', 'cmo', $
;                             'naq', 'lrv'] 
;                              ** Sites were changed from 2015 because many of the 
;                                 original sites were no longer operational or 
;                                 had poor quality data. Also because so many new
;                                 networks were added to the magnetometer data
;                                 served at UCB and UCLA
;                             If set to 'all', all available sites
;                             will be loaded and used.
;                             
;                             
;                   no_load = if set, use existing gmag (THEMIS) tplot variables which have
;                             already been loaded into the active TDAS environment
;                             if not set, load gmag data (either
;                             remotely or from computer disk)
;                   max_deviation = The maximum deviation that the
;                                   magnetic field  data can go from the median;
;                                   points that exceed this value are omitted.
;                   		    The default value is plus or minus 1500 nT
;
;
;	Example:    see crib sheet "thm_crib_make_AE.pro"
;
;       Notes:      Written by Andreas Keiling, 15 May 2008
;
;       Modifications:
;                   Edited header, put subroutine before main body so
;                   that it would compile before being called by the
;                   main body, W.M.Feuerstein, 6/2/2008.
;                   Changed default sites to be only high-lat THEMIS
;                   stations:  jmm, 25-nov-2009
;                   Added FCC, CMO, NAQ, LRV as sites, 17-sep-2012,
;                   jmm
;                   Added max deviation, extra despike of magnetic
;                   field prior to index calculation, 4-nov-2013, jmm
;                   Added new site list for 2015 and later 22-may-2015, clr
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2025-01-28 09:39:01 -0800 (Tue, 28 Jan 2025) $
; $LastChangedRevision: 33099 $
; $URL $
;-


pro tdespike_AEALAU, lower, upper, quant=quant
; this routine removes artificial spikes
;
; variables:  lower = lower cutoff of spikes to be removed
;             upper = upper cutoff of spikes to be removed
;

get_data, quant, data=A_index
last=n_elements(A_index.y)-1
NaN=!values.f_nan

indices = where(A_index.y gt upper OR A_index.y lt lower , count)
if count ne 0 then begin
   for k=0,count-1 do begin
       i=indices[k]
       if (i eq 0 OR i eq 1 ) then begin
          A_index.y[0]=NaN
          A_index.y[1]=NaN
       endif else begin
          if (i eq last-1 OR i eq last) then begin
               A_index.y[last-1]=NaN
               A_index.y[last] = NaN
          endif else begin
               A_index.y[i-2]=NaN
               A_index.y[i-1]=NaN
               A_index.y[i] = NaN
               A_index.y[i+1]=NaN
               A_index.y[i+2]=NaN
          endelse
       endelse
   endfor
endif

store_data, quant+'_despike', data=A_index

end

;#######################################################

pro thm_make_AE, res = res, sites = sites, no_load = no_load, max_deviation = max_deviation, _extra = _extra

@tplot_com

; set default time resolution
;----------------------------
if not keyword_set(res) then res = 60d   ; 60 sec resolution
res=double(res)
date2015=time_double('2015-01-01')
date2023=time_double('2023-09-01')

; load gmag data
;----------------
if not keyword_set(no_load) then begin
;allow for sites keyword to operate
  if keyword_set(sites) then begin
    thm_load_gmag, site = vsites, /valid_names ;check name validity here:
    ;x4 = where(strlen(vsites) Eq 4) ;avoid alt greenland sites
    ;vsites = vsites[x4]
    site_load = ssl_check_valid_name(sites, vsites, /ignore_case, /include_all, /no_warning)
    If(is_string(site_load) Eq 0) Then Begin
      dprint, 'No Valid sites? '+sites
      Return
    Endif
  endif else begin
    if tplot_vars.options.trange[0] EQ 0 OR tplot_vars.options.trange[0] GE date2023 then begin
      site_load = ['and', 'atu', 'bfe', 'bjn', 'dmh', 'dob', 'don', 'gako', 'gdn',   $
        'gill', 'hop', 'hov', 'jan', 'jck', 'kar', 'kuv', 'lrv', 'lyr',   $
        'nal', 'naq', 'nor', 'ptrs', 'roe', 'roth', 'rvk', 'salu',   $
        'sept', 'skt', 'pina', 'pokr', 'rank', 'sol', 'shu', 'sor',   $
        'stf', 'svs', 'trap', 'thl', 'tro', 'upn', 'vldr']
    endif else begin 
      if tplot_vars.options.trange[0] EQ 0 OR tplot_vars.options.trange[0] GE date2015 then begin
       site_load = ['pbk', 'tik', 'dik', 'amd', 'nor', 'hop', 'jck', 'and', 'nal',   $
             'roe', 'dob', 'sol', 'dmh', 'lvr', 'leth', 'naq', 'stf', 'kuv',   $
             'nain', 'sept', 'thl', 'salu', 'vldr', 'inuk', 'rbay', 'rank',   $
             'fsmi', 'atha', 'gill', 'fsim', 'inuv', 'whit', 'sit', 'kako',   $
             'fykn', 'cigo', 'trap', 'ded', 'brw', 'kian', 'shu']
      endif else begin
       site_load = ['atha', 'chbg', 'ekat', 'fsim', 'fsmi', 'fykn', $
                   'gako', 'gbay', 'gill', 'inuv', 'kapu', 'kian', $
                   'kuuj', 'mcgr', 'pgeo', 'pina', 'rank', 'snap', $
                   'snkq', 'tpas', 'whit', 'yknf', 'fcc', 'cmo', $
                   'naq', 'lrv'] ;made an array to facilitate the use of split_vec later
      endelse   
   endelse
   
  endelse
  thm_load_gmag, /subtract_median, site = site_load
  sites_varnames = tnames('thg_mag_'+site_load)
endif else begin
  sites_varnames = [tnames('thg_mag_????'),tnames('thg_mag_???')]
endelse
If(is_string(sites_varnames) Eq 0) Then Begin
  dprint, 'No Valid sites? '
  Return
Endif
split_vec, sites_varnames
stations = sites_varnames+'_x'

;Despike and clip Bfield data here, as in stackplot program
If(keyword_set(max_deviation)) Then Begin
    If(n_elements(max_deviation) Eq 1) Then Begin
        max_dev = [-max_deviation, max_deviation]
    Endif Else max_dev = max_deviation
Endif Else max_dev = [-1500., 1500.]
nstat = n_elements(stations)
min_despike_datapoints=10
For j = 0, nstat-1 Do Begin
    get_data, stations[j], data=dd
    if n_elements(dd.x) ge 10 then begin
       t = dd.x & dt = t[1:*]-t
       yj = dd.y[*, 0]
       median_dt = median(dt)
       spike_test_width = (long(120.1/median_dt)+1) >3 ;typically 2 minutes
       yj = simple_despike_1d(yj, spike_threshold = 3, width = spike_test_width)
       xclip, max_dev[0], max_dev[1], yj, /clip_adjacent
       dd.y[*, 0] = yj
       store_data, stations[j], data = dd
    endif else begin
      dprint, 'Station ' + stations[j] + ' has fewer than '+ string(min_despike_datapoints)+ ' samples, skipping despike.'
    endelse
Endfor

; calculate indices
;------------------
superpo_histo,stations,dif='thmAE',min='thmAL',max='thmAU',res=res

; thresholds can be changed if desired
;-------------------------------------
;cut=1500
;tdespike_AEALAU,-cut,cut, quant='thmAE'
;tdespike_AEALAU,-cut,cut, quant='thmAL'
;tdespike_AEALAU,-cut,cut, quant='thmAU'

;clean_spikes, 'thmAE_despike', new_name = 'thmAE', thresh = 5
;clean_spikes, 'thmAL_despike', new_name = 'thmAL', thresh = 5
;clean_spikes, 'thmAU_despike', new_name = 'thmAU', thresh = 5

options,'thmAE',ytitle='THEMIS!CAE Index'
options,'thmAL',ytitle='THEMIS!CAL Index'
options,'thmAU',ytitle='THEMIS!CAU Index'


; delete obsolete data
;---------------------
;del_data,'thmAE_despike'
;del_data,'thmAU_despike'
;del_data,'thmAL_despike'


; print station names used for calculation
;-----------------------------------------
dprint, 'The following stations contributed to the index calculation:'
tplot_names, stations           ;jmm, 2009-11-30
dprint, '-----------------------------'

end



