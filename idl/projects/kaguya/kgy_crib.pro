;+
; PROCEDURE:
;       kgy_crib
; PURPOSE:
;       demonstrates how to load and plot Kaguya data
; CALLING SEQUENCE:
;       .r kgy_crib
;       or copy and paste each command
; CREATED BY:
;       Yuki Harada on 2016-09-12
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-09-12 10:51:26 -0700 (Mon, 12 Sep 2016) $
; $LastChangedRevision: 21814 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/kgy_crib.pro $
;-


;;; plot settings

init_devices
loadct2,43
tplot_options,'no_interp',1
tplot_options,'ygap',.5
tplot_options,'xmargin',[15,10]


;;; set time span

timespan,'2008-03-10',1


;;; load MAP (PACE+LMAG) and SPICE data

kgy_map_load


;;; load LRS data

kgy_lrs_load


;;; check tplot variables

tplot_names


dprint,'Data load complete'
dprint,'Now plot time series...'
wait,2


;;; time series plots

;;; ESA-S1

tplot,['kgy_esa1*']

dprint,'ESA-S1'
wait,2


;;; ESA-S2

tplot,['kgy_esa2*']

dprint,'ESA-S2'
wait,2


;;; IMA

tplot,['kgy_ima*']

dprint,'IMA'
wait,2


;;; IEA

tplot,['kgy_iea*']

dprint,'IEA'
wait,2


;;; LMAG

tplot,['kgy_lmag*']

dprint,'LMAG'
wait,2


;;; LRS

tplot,['kgy_lrs*']

dprint,'LRS'
wait,2


;;; summary plot
tplot,[ $
      'kgy_esa2_en_eflux','kgy_esa1_en_eflux', $ ;- electron
      'kgy_iea_en_eflux','kgy_ima_en_eflux', $   ;- ion
      'kgy_lmag_Bsse', $                         ;- B-field
      'kgy_lrs_wfc_Ey', $                        ;- E-field wave
      'kgy_lmag_alt','kgy_lmag_sza','kgy_lmag_lonlat' $ ;- S/C position
      ]

dprint,'Summary plot'
wait,2


;;; zoom in

tlimit,'2008-03-10/'+['10:30','12:30']

dprint,'Zoom in'
wait,2


;;; calculate electron pitch angle distributions

kgy_map_make_pad,sensor=[0,1],erange=[50,200], $
                 trange='2008-03-10/'+['10:00','13:00']

tplot,[ $
      'kgy_esa2_en_eflux', $
      'kgy_esa2_pa_eflux', $
      'kgy_esa1_en_eflux', $
      'kgy_esa1_pa_eflux', $
      'kgy_iea_en_eflux','kgy_ima_en_eflux', $
      'kgy_lmag_Bsse', $
      'kgy_lrs_wfc_Ey', $
      'kgy_lmag_alt','kgy_lmag_sza','kgy_lmag_lonlat' $
      ]

dprint,'Added electron PADs'




end
