;helper function to find an energy value in a monotonically
;decreasing array, e0
Function value_locate_energy, e, e0
  sv0 = where(e0 Le e, nsv0)
  sv1 = where(e0 Gt e, nsv1)
  nenergy = n_elements(e0)
  If(nsv0 Eq 0) Then Begin ;just the last two energies
     s0 = nenergy-2 & s1 = nenergy-1
  Endif Else If(nsv1 Eq 0) Then Begin
     s0 = 0 & s1 = 1
  Endif Else Begin
     s0 = max(sv1)
     s1 = s0+1
  Endelse
  Return, [s0, s1]              ;remember energy(s0) > energy(s1)
End
;+
;NAME:
;fa_esa_l2_pad
;CALLING SEQUENCE:
;pdist = fa_esa_l2_pad(type)
;PURPOSE:
;Create FAST ESA pitch angle spectrum, from L2 input
;INPUT:
;type = one of ['ies', 'ees', 'ieb', 'eeb']
;OUTPUT:
;pdist = tplot variable name for pitch angle spectra in the given energy range
;KEYWORDS: (all from get_pa_spec.pro, but the interpretation may be
;           different because there are no 'counts')
;       trange: A time range, if set takes precedence over t1 and t2
;               below, defaults to timerange()
;	T1:		start time, seconds since 1970, defaults to timerange()[0]
;	T2:		end time, seconds since 1970, defaults to timerange()[1]
;	ENERGY:		fltarr(2)		energy range to sum over, eV
;	EBINRANGE:	intarr(2)		energy bin range to sum over
;	EBINS:		bytarr(dat.nenergy)	energy bins to sum over
;	gap_time: 	time gap big enough to signify a data gap 
;			(default 200 sec, 8 sec for FAST)
;	NO_DATA: 	returns 1 if no_data else returns 0
;	NAME:  		New name of the Data Quantity
;       SUFFIX:         Append this suffix to the tplot variable name,
;                       only used if the NAME keyword is not set.
;
;HISTORY:
; 2016-03-21, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2022-08-15 13:07:54 -0700 (Mon, 15 Aug 2022) $
; $LastChangedRevision: 31017 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_l2_pad.pro $
;-
Function fa_esa_l2_pad, type, $
                        trange = trange, $
                        T1=t1, $
                        T2=t2, $
                        ENERGY=energy, $
                        EBINRANGE=ebinrange, $
                        EBINS=ebins, $
                        gap_time=gap_time, $ 
                        no_data=no_data, $
                        name = name, $
                        suffix = suffix, $
                        wt_out = wt_out, $
                        _extra=_extra
;next define the common blocks
  common fa_information, info_struct

  typex = strlowcase(strcompress(/remove_all, type[0]))
  Case typex of
     'ies': Begin
        common fa_ies_l2, get_ind_ies, all_dat_ies
        all_dat = all_dat_ies
     End
     'ees': Begin
        common fa_ees_l2, get_ind_ees, all_dat_ees
        all_dat = all_dat_ees
     End
     'ieb': Begin
        common fa_ieb_l2, get_ind_ieb, all_dat_ieb
        all_dat = all_dat_ieb
     End
     'eeb': Begin
        common fa_eeb_l2, get_ind_eeb, all_dat_eeb
        all_dat = all_dat_eeb
     End
  Endcase

;One data type
  If(size(all_dat, /type) Ne 8) Then Begin
     message, /info, 'No '+typex+' Data structure'
     Return, ''
  Endif

;Get time intervals
  If(keyword_set(trange)) Then Begin
     tr = time_double(trange)
  Endif Else Begin
     If(keyword_set(t1) or keyword_set(t2)) Then Begin
        If(keyword_set(t1)) Then t1 = time_double(t1) Else Begin
           tr0 = timerange()
           t1 = time_double(tr0[0])
        Endelse
        If(keyword_set(t2)) Then t2 = time_double(t2) Else Begin
           tr0 = timerange()
           t2 = time_double(tr0[1])
        Endelse
        tr = [t1, t2]
     Endif Else tr = timerange()
  Endelse

  ntimes = n_elements(all_dat.time)
;Grab data in time range
  ss = where(all_dat.time Ge tr[0] And all_dat.time Lt tr[1], nss)
  If(nss Eq 0) Then Begin
     dprint, 'No '+typex+' data in time range: '
     print, time_string(tr)
     Return, ''
  Endif

;If nothing is set, then default to all bins, wt is a weight factor
  nbins = n_elements(all_dat.energy_full[0, *, 0])
  nab = n_elements(all_dat.energy_full[0, 0, *])
  wt = 1.0+fltarr(nbins, nab)

;If bins keywords are set, use them
  If(keyword_set(ebins)) Then Begin
     wt[*] = 0.0 & wt[ebins, *] = 1.0
  Endif
  If(keyword_set(ebinrange)) Then Begin
     ebr = minmax(ebinrange)
     nbd = ebr[1]-ebr[0]+1
     sbins = ebr[0]+indgen(nbd)
     wt[*] = 0.0 & wt[sbins, *] = 1.0
  Endif
;Use a loop
  eflux_out = fltarr(nss, nab)+!values.f_nan
  pad_out = eflux_out
  For j = 0, nss-1 Do Begin
     efullj = all_dat.energy_full[ss[j], *, 0] > 0
;get the number of bins
     nbj = all_dat.nenergy[ss[j]]
     nabj = all_dat.nbins[ss[j]]
     If(~keyword_set(energy)) Then Begin
        sbins = where(wt[*, 0] Gt 0, nsbins)
        dej = max(efullj[sbins])-min(efullj[sbins])
     Endif Else Begin
;Energy may be out of range
        If((energy[0] Gt efullj[0] And energy[1] Gt efullj[0]) Or $
           (energy[0] Lt efullj[nbins-1] And energy[1] Lt efullj[nbins-1])) Then Begin
           dprint, 'Energy range out of range: '
           print, energy
           Return, ''
        Endif
        wt[*] = 0.0
;The energy array is monotonically decreasing
        sx0 = value_locate_energy(energy[0], efullj) ;values will bracket energy, if it's in the range
        sx1 = value_locate_energy(energy[1], efullj) ;remember that sx1 will be le sx0
;First, if sx0 = sx1 then interpolate to the midpoint
        If(sx0[0] Eq sx1[0]) Then Begin
           eb = 0.5*(energy[0]+energy[1])
           ax = (eb-efullj[sx0[1]])/(efullj[sx0[0]]-efullj[sx0[1]])
           wt[sx0[1], *] = 1.0-ax
           wt[sx0[0], *] = ax
        Endif Else Begin        ;at least one energy is bracketed
           wt[sx1[1]:sx0[0], *] = 1.0  ;sx1[1] is lt energy[1] and sx0[0] gt energy[0]
;There may be partial bins
           wt[sx0[1], *] = (efullj[sx0[0]]-energy[0])/(efullj[sx0[0]]-efullj[sx0[1]])
           wt[sx1[0], *] = (energy[1]-efullj[sx1[1]])/(efullj[sx1[0]]-efullj[sx1[1]])
        Endelse
     Endelse
;contract eflux variable, reset fill values in data arrays to 0
     etmp = reform(all_dat.eflux[ss[j], 0:nbj-1, 0:nabj-1]) > 0
     detmp = reform(all_dat.denergy_full[ss[j], 0:nbj-1, 0:nabj-1]) > 0
     patmp = reform(all_dat.pitch_angle[ss[j], 0:nbj-1, 0:nabj-1]) > 0
     wttmp = wt[0:nbj-1, 0:nabj-1]
     If(n_elements(sbins) Eq 1) Then Begin
        eflux_otmp = reform(etmp[sbins[0], *])
        pad_otmp = reform(patmp[sbins[0], *])
     Endif Else Begin
        eflux_otmp = total(etmp*detmp*wttmp, 1)/total(detmp*wttmp, 1)
        pad_otmp = total(patmp*detmp*wttmp, 1)/total(detmp*wttmp, 1)
     Endelse
     ssk = sort(pad_otmp)
     eflux_out[j, 0:nabj-1] = eflux_otmp[ssk]
     pad_out[j, 0:nabj-1] = pad_otmp[ssk]
  Endfor
    
;setup tplot variable
  If(is_string(name)) Then name_o_tplot = name $
  Else Begin
     name_o_tplot = 'fa_'+typex+'_l2_pad'
     If(is_string(suffix)) Then name_o_tplot = name_o_tplot+suffix
  Endelse
  store_data, name_o_tplot, data = {x:(all_dat.time[ss]+all_dat.end_time[ss])/2,y:eflux_out,v:pad_out}

  ylim,name_o_tplot, 0., 360., 0
  options, name_o_tplot, 'ztitle', 'Eflux PAD'
  options, name_o_tplot, 'ytitle',type+'PA(degrees)'
  options, name_o_tplot, 'spec', 1
  options, name_o_tplot, 'x_no_interp', 1
  options, name_o_tplot, 'y_no_interp', 1
  options, name_o_tplot, 'zlog', 1
  options, name_o_tplot, datagap = 5
  options, name_o_tplot, 'units', 'eV/(cm^2-s-sr)', /default

  Return, name_o_tplot
End
