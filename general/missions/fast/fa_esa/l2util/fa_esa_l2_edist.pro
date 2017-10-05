;+
;NAME:
;fa_esa_l2_edist
;CALLING SEQUENCE:
;eflux = fa_esa_l2_edist(type)
;PURPOSE:
;Create FAST ESA energy spectrum, from L2 input
;INPUT:
;type = one of ['ies', 'ees', 'ieb', 'eeb']
;OUTPUT:
;eflux = tplot variable name for energy spectrum in the given pitch
;        angle range
;KEYWORDS: (all from get_pa_spec.pro, but the interpretation may be
;           different because there are no 'counts')
;       trange: A time range, if set takes precedence over t1 and t2
;               below, defaults to timerange()
;	T1:		start time, seconds since 1970, defaults to timerange()[0]
;	T2:		end time, seconds since 1970, defaults to timerange()[1]
;	PARANGE:		fltarr(2)		pitch angle range to sum over
;	gap_time: 	time gap big enough to signify a data gap 
;			(default 200 sec, 8 sec for FAST)
;	NO_DATA: 	returns 1 if no_data else returns 0
;	NAME:  		New name of the Data Quantity
;       SUFFIX:         Append this suffix to the tplot variable name,
;                       only used if the NAME keyword is not set.
;
;HISTORY:
; 2016-04-12, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-10-24 12:02:05 -0700 (Mon, 24 Oct 2016) $
; $LastChangedRevision: 22189 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_l2_edist.pro $
;-
Function fa_esa_l2_edist, type, $
                          T1=t1, $
                          T2=t2, $
                          trange = trange, $
                          parange=parange, $
                          gap_time=gap_time, $ 
                          no_data=no_data, $
                          name = name, $
                          suffix = suffix, $
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

;change the pitch angle range so that range[1] is gt range[0]
  If(keyword_set(parange)) Then Begin
     If(n_elements(parange) Eq 1) Then par0 = [parange, parange] $
     Else par0 = parange
;pa range needs to be between 0 and 360, or 720 when wrapping
     xxx = where(par0 Gt 360, nxxx)
     If(nxxx Gt 0) Then par0[xxx]=par0[xxx] mod 360.0
     yyy = where(par0 Lt 0, nyyy)
     If(nyyy gt 0) Then par0[yyy]=par0[yyy]+360.0
     If(par0[0] Gt par0[1]) Then par0[1] = par0[1]+360.0
  Endif
;Since the pitch angle varies with energy, you'll need loops
;over time and energy, first get the nubmer of bins
  eflux_out = fltarr(nss, nbins)+!values.f_nan
  energy_out = eflux_out
  For j = 0, nss-1 Do Begin
     nbj = all_dat.nenergy[ss[j]]
     nabj = all_dat.nbins[ss[j]]
     For k = 0, nbj-1 Do Begin
        If(keyword_set(parange) && (parange[1]-parange[0]) Lt 360) Then Begin
           wt[k, *] = 0.0
           pajk = reform(all_dat.pitch_angle[ss[j], k, 0:nabj-1])
;pitch angle wraps, so sort
           ssjk = sort(pajk)
           pajk = pajk[ssjk]
;pakjk2 will help for wrapped cases
           pajk2 = [pajk, 360.0+pajk]
;If one pitch angle - interpolate
           If(par0[1] Eq par0[0]) Then Begin
              interp_it:
              s1 = value_locate(pajk, par0[0])
;This handles the wrapping pretty explicitly, but it should be ok
              If(s1 Eq -1 Or s1 Eq nabj-1) Then Begin
                 i = nabj-1 & i1 = 0
                 If(par0[0] Lt 0) Then Begin ;shouldn't happen
                    a = (par0[0]-pajk[i])/(360.0+pajk[i1]-pajk[i])
                 Endif Else Begin
                    a = (360.0+par0[0]-pajk[i])/(360.0+pajk[i1]-pajk[i])
                 Endelse
              Endif Else Begin
                 i = s1 & i1=i+1
                 a = (par0[0]-pajk[i])/(pajk[i1]-pajk[i])
              Endelse
              wt[k, ssjk[i]] = (1.0-a)
              wt[k, ssjk[i1]] = a
           Endif Else Begin    ;use a weight array that's twice as long for wrapping
              wtf = fltarr(2*nabj)
              s1 = value_locate(pajk2, par0)
              If(s1[1] Eq s1[0]) Then Begin ;interpolate to the midpoint
                 par0[0] = ((par0[0]+par0[1])/2.0) Mod 360.0
                 par0[1] = par0[0]
                 goto, interp_it
              Endif
;Here we know that s1[1] > s1[0]
;The first bin may be partial
              If(s1[0] Eq -1) Then Begin
                 wtf[nabj-1] = 1.0
                 wtf[0:s1[1]] = 1.0
                 i = nabj-1 & i1 = 0
                 If(par0[0]+360.0 Gt pajk[i]) Then $
                    wts10 = (par0[0]+360.0-pajk2[i])/(pajk2[i1]-pajk2[i])
                 wtf[s1[0]] = wts10                 
              Endif Else Begin
                 wtf[s1[0]:s1[1]] = 1.0
                 i = s1[0] & i1 = i+1
                 If(pajk2[i] Eq par0[0]) Then wts10 = 1.0 $
                 Else wts10 = (pajk2[i1]-par0[0])/(pajk2[i1]-pajk2[i])
                 wtf[s1[0]] = wts10
              Endelse
;There may be an extra partial bin after s1[1]
              i = s1[1] & i1=i+1
              If(par0[1] Gt pajk2[i]) Then Begin
                 wts11 = (par0[1]-pajk2[i])/(pajk2[i1]-pajk2[i])
                 wtf[i1] = wts11
              Endif
;contract wtf
              wtf = wtf[0:nabj-1]+wtf[nabj:*]
              wt[k, ssjk] = wtf
           Endelse
        Endif
     Endfor
     oops = where(wt Gt 1.0, noops)
     If(oops[0] Ne -1) Then Begin
        dprint, 'Wt factor is too large for: '+strcompress(string(noops))+' Points'
        wt = wt < 1.0
     Endif
;contract eflux variable
     eflux_otmp = reform(all_dat.eflux[ss[j], 0:nbj-1, 0:nabj-1])
     domega_otmp = reform(all_dat.domega[ss[j], 0:nbj-1, 0:nabj-1])
     wttmp = wt[0:nbj-1, 0:nabj-1]
     eflux_out[j, 0:nbj-1] = total(eflux_otmp*domega_otmp*wttmp, 2)/ $
                             total(domega_otmp*wttmp, 2)
     energy_out[j, 0:nbj-1] = all_dat.energy_full[ss[j], 0:nbj-1, 0]
  Endfor

;setup tplot variable
  If(is_string(name)) Then name_o_tplot = name $
  Else Begin
     name_o_tplot = 'fa_'+typex+'_l2_eflux'
     If(is_string(suffix)) Then name_o_tplot = name_o_tplot+suffix
  Endelse

  store_data, name_o_tplot, data = {x:(all_dat.time[ss]+all_dat.end_time[ss])/2,y:eflux_out,v:energy_out}
;  zlim,name_o_tplot, 1.e1, 1.e6, 1
  ylim, name_o_tplot, 5., 40000., 1
  options, name_o_tplot, 'ztitle', 'Eflux'
  options, name_o_tplot, 'ytitle',type+': eV'
  options, name_o_tplot, 'spec', 1
  options, name_o_tplot, 'x_no_interp', 1
  options, name_o_tplot, 'y_no_interp', 1
  options, name_o_tplot, datagap = 5
  options, name_o_tplot, 'zlog', 1
  options, name_o_tplot, 'units', 'eV/(cm^2-s-eV)', /default

  Return, name_o_tplot
End
