;+
;NAME:
;fa_esa_l2_tplot
;CALLING SEQUENCE:
;fa_esa_l2_tplot
;PURPOSE:
;Create FAST ESA tplot variables, from L2 input
;INPUT:
;OUTPUT:
;KEYWORDS:
;
;all = 0/1, if not set, deletes all currently stored ESA tplot
;variables fa_esa* before generating new ones.
;
;type = ['ies', 'ees', 'ieb', 'eeb'] or some subset.
;
;counts = 0/1, if set, then use counts data rather than eflux to
;create tplot variables, good for comparison with L1 data
;
;HISTORY:
;2015-09-14, jmm, jimm@ssl.berkeley.edu, hacked from fa_load_esa_l1
;and mvn_sta_l2_tplot.
; $LastChangedBy: jimmpc1 $
; $LastChangedDate: 2019-02-21 17:14:26 -0800 (Thu, 21 Feb 2019) $
; $LastChangedRevision: 26668 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_l2_tplot.pro $
;-
Pro fa_esa_l2_tplot, all = all, type = type, counts = counts, _extra = _extra

;Unless all is set, delete old data
  IF(~keyword_set(all)) Then Begin
     If(keyword_set(counts)) Then store_data, delete = 'fa_*_l2_ct_quick' $
     Else store_data, delete = 'fa_*_l2_en_quick'
  Endif

;next define the common blocks
  common fa_information, info_struct
  common fa_ies_l2, get_ind_ies, all_dat_ies
  common fa_ees_l2, get_ind_ees, all_dat_ees
  common fa_ieb_l2, get_ind_ieb, all_dat_ieb
  common fa_eeb_l2, get_ind_eeb, all_dat_eeb

;Handle data types
  If(keyword_set(type)) Then Begin
     typex = strlowcase(strcompress(/remove_all, type))
  Endif Else typex = ['ies', 'ees', 'ieb', 'eeb']

;Recursive 
  If(n_elements(typex) Gt 1) Then Begin
     For i = 0, n_elements(typex)-1 Do fa_esa_l2_tplot, /all, $
        type = typex[i], counts = counts
     Return
  Endif

;Only one data type here now
  typex = typex[0]
  Case typex Of
     'ies': Begin
        If(size(all_dat_ies, /type) Eq 8) Then all_dat = all_dat_ies $
        Else Begin
           message, /info, 'No '+typex+' Data structure'
           Return
        Endelse
        ccvt = info_struct.byteto16_map
     End
     'ees': Begin
        If(size(all_dat_ees, /type) Eq 8) Then all_dat = all_dat_ees $
        Else Begin
           message, /info, 'No '+typex+' Data structure'
           Return
        Endelse
        ccvt = info_struct.byteto16_map
     End
     'ieb': Begin
        If(size(all_dat_ieb, /type) Eq 8) Then all_dat = all_dat_ieb $
        Else Begin
           message, /info, 'No '+typex+' Data structure'
           Return
        Endelse
        ccvt = info_struct.byteto14_map
     End
     'eeb': Begin
        If(size(all_dat_eeb, /type) Eq 8) Then all_dat = all_dat_eeb $
        Else Begin
           message, /info, 'No '+typex+' Data structure'
           Return
        Endelse
        ccvt = info_struct.byteto14_map
     End
     Else: Begin
        message, /info, 'Bad type input: '+typex
        Return
     End
  Endcase

;This part is hacked from load_esa_l1
  ntimes = n_elements(all_dat.time)
;data_tplot will be the total of all angles' eflux values at each time
  data_tplot = fltarr(ntimes, 96)+!values.f_nan
  energy_tplot = fltarr(ntimes, 96)+!values.f_nan
  For i = 0, ntimes-1 Do Begin
     nbj = all_dat.nenergy[i]
     nabj = all_dat.nbins[i]
     If(all_dat.mode_ind[i] EQ 0) Then Begin
        If(keyword_set(counts)) Then Begin
           data_tplot[i,0:nbj-1]=total(ccvt[all_dat.data[i, 0:nbj-1, 0:nabj-1]], 3)/(all_dat.integ_t[i]*nabj)
        Endif Else data_tplot[i, 0:nbj-1] = total(all_dat.eflux[i, 0:nbj-1, 0:nabj-1], 3)/nabj 
        energy_tplot[i, *] = all_dat.energy[*, 0, 0]
     Endif
     If(all_dat.mode_ind[i] EQ 1) Then Begin
        If(keyword_set(counts)) Then Begin
           data_tplot[i,0:nbj-1]=total(ccvt[all_dat.data[i, 0:nbj-1, 0:nabj-1]], 3)/(all_dat.integ_t[i]*nabj)
        Endif Else data_tplot[i, 0:nbj-1] = total(all_dat.eflux[i, 0:nbj-1, 0:nabj-1], 3)/nabj
        energy_tplot[i, *] = all_dat.energy[*, 0, 1]
     Endif
     If(all_dat.mode_ind[i] EQ 2) Then Begin
        If(keyword_set(counts)) Then Begin
           data_tplot[i,0:nbj-1]=total(ccvt[all_dat.data[i, 0:nbj-1, 0:nabj-1]], 3)/(all_dat.integ_t[i]*nabj)
        Endif Else data_tplot[i, 0:nbj-1] = total(all_dat.eflux[i, 0:nbj-1, 0:nabj-1], 3)/nabj
        energy_tplot[i, *] = all_dat.energy[*, 0, 2]
     Endif
  Endfor

;  data_tplot = data_tplot > 1.e-10
;Counts should have l1 in the name:
  If(keyword_set(counts)) Then Begin
     name_o_tplot = 'fa_'+typex+'_l2_ct_quick'
     ztitle = 'Rate'
  Endif Else Begin
     name_o_tplot = 'fa_'+typex+'_l2_en_quick'
     ztitle = 'Eflux'
  Endelse
  store_data, name_o_tplot, data = {x:(all_dat.time+all_dat.end_time)/2,y:data_tplot,v:energy_tplot}
;  zlim,name_o_tplot, 1.e1, 1.e6, 1
  ylim,name_o_tplot, 5., 40000., 1
  options, name_o_tplot, 'ztitle', 'Rate'
  options, name_o_tplot, 'ytitle',type+': eV'
  options, name_o_tplot, 'spec', 1
  options, name_o_tplot, 'x_no_interp', 1
  options, name_o_tplot, 'y_no_interp', 1
  options, name_o_tplot, datagap = 5
  options, name_o_tplot, 'zlog', 1

Return
End
