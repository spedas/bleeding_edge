;+
;PRO isee_induction_cal_resp
;
;PURPOSE:
; To make calibrated frequency-time spectrogram of ISEE induction magnetometers
;
; Calibration for power spectral density at a given frequency is peformed as follows:
;
;    S_calib(f) = S_org(f) / cal_table(f) / cal_table(f)
;
; where S_calib [nT^2/Hz] is calibrated power spectral density, S_org [V^2/Hz] is power spectral density
; computed from the data in CDF files, cal_table [V/nT] is the sensitivity included in CDF files.
;
;INPUT:
; site  = Observatory name, example, erg_load_gmag_stel_induction, site='msr',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['msr', 'sta']
;           or a single string delimited by spaces, e.g., 'msr sta'.
;           Sites: ath mgd ptk msr sta gak kap zgn hus(after 2018-09-06)
;
; nbox = number of FFT points
; nshift = number of shift points for FFT, nshift should be equal or lower than nbox
;
;EXAMPLE:
;  ;load 1 day data from Gakona and perform calibration
;  timespan,'2017-03-21',1,/day
;  erg_isee_induction_cal_resp,site='gak',nbox=8192,nshift=1024
;  ;plot uncalibrated and calibrated frequency-time spectrogram
;  tplot,['isee_induction_db_dt_gak_x_dpwrspc','isee_induction_db_dt_gak_x_dpwrspc_corr']
;
;HISTORY:
;   2018-03-22: Initial release by Satoshi Kurita (ISEE, Nagoya U., kurita@isee.nagoya-u.ac.jp)
;
; $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
; $LastChangedRevision: 27922 $
;
;-


pro isee_induction_cal_resp,site=site,nbox=nbox,nshift=nshift

if not keyword_set(nbox) then nbox=8192.
if not keyword_set(nshift) then nshift=1024.

comp=['x','y','z']

if(n_elements(site) ne 0) then begin
  site=strjoin(site, ' ')
  site=strsplit(strlowcase(site), ' ', /extract)

  for ii=0.,n_elements(site)-1 do begin

    erg_load_gmag_isee_induction,site=site[ii],frequency_dependent=fdepend
    tdpwrspc,'isee_induction_db_dt_'+site[ii],nbox=nbox,nshift=nshift

    ind_site=where(fdepend.site_code eq site[ii])

    for jj=0.,n_elements(comp)-1 do begin

      get_data,'isee_induction_db_dt_'+site[ii]+'_'+comp[jj]+'_dpwrspc',data=tmp,dlim=dlim

      if size(tmp,/type) eq 8 then begin

        nfreq=fdepend(ind_site).nfreq
        resp=fdepend(ind_site).sensitivity[0:nfreq-1,jj]
        freq=fdepend(ind_site).frequency[0:nfreq-1]
        resp=interpol(resp,freq,reform(tmp.v[0,*]))

        for kk=0.,n_elements(tmp.v[0,*])-1 do tmp.y[*,kk]=tmp.y[*,kk]/resp[kk]/resp[kk]

        store_data,'isee_induction_db_dt_'+site[ii]+'_'+comp[jj]+'_dpwrspc_corr',data=tmp,dlim=dlim
        options,'isee_induction_db_dt_'+site[ii]+'_'+comp[jj]+'_dpwrspc_corr',yrange=[1e-1,32],zrange=[1e-8,1e-3],ztitle='nT^2/Hz',ytitle=strupcase(site[ii])+'Frequency!C!C[Hz]',/ylog,/zlog
      endif
    endfor
  endfor
endif else dprint,'Site code must be set. Abort.'

end