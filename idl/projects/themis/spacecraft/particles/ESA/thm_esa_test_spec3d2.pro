;
;PROCEDURE: spec3d2,data
;   Plots 3d data as energy spectra.
;INPUTS:
;   data   - 3d data structure filled by themis routines get_th?_p???
;KEYWORDS:
;   LIMITS - A structure containing limits and display options.
;             see: "options", "xlim" and "ylim", to change limits
;   UNITS  - convert to given data units before plotting
;   COLOR  - array of colors to be used for each bin
;   BINS   - array of bins to be plotted  (see "edit3dbins" to change)
;   OVERPLOT  - Overplots last plot if set.
;   LABEL  - Puts bin labels on the plot if set.
;
;See "plot3d" for another means of plotting data.
;See "conv_units" to change units.
;See "time_stamp" to turn time stamping on and off.
;
;
;CREATED BY:	Davin Larson  June 1995
;FILE:  spec3d2.pro
;VERSION 1.25
;LAST MODIFICATION: 09-05-24	mcfadden keyword 'sec' added to plot
;internal secondary spectra
; 2015-05-15, jmm, added estimation of potential, changed the name to
; avoid conflicts
;
pro spec3d2,tempdat,   $
  LIMITS = limits, $
  UNITS = units,   $         ; obsolete.  Use units function 
  COLOR = col,     $
  BDIR = bdir,     $
  PHI = phi,       $
  THETA = theta,   $
  PITCHANGLE = pang,   $
  VECTOR = vec,    $
  SUNDIR = sundir, $
  a_color = a_color, $
  LABEL = label,   $
  xdat = xdat, $
  ydat = ydat, $
  dydat = dydat, $
  BINS = bins,     $
  VELOCITY = vel, $
  OVERPLOT = oplot, $
  sec = sec, $
  pot = pot, $
  title=title, $
  est_pot = est_pot, $    ;estimates potential, jmm, 2015-05-18
  _extra = _extra
;@wind_com.pro

if size(/type,tempdat) ne 8 || tempdat.valid eq 0 then begin
;if data_type(tempdat) ne 8 or tempdat.valid eq 0 then begin
  print,'Invalid Data'
  return
endif

a_color=''
str_element,limits,'a_color',a_color

case strlowcase(strmid(a_color,0,2)) of
'pi': pang=1
'su': sundir=1
'th': theta=1
'ph': phi=1
else:
endcase


str_element,limits,'pitchangle',value=pang
str_element,limits,'sundir',value=sundir
str_element,limits,'thetadir',value=theta


str_element,limits,'units',value=units
data3d = conv_units(tempdat,units)
if units ne 'counts' and units ne 'Counts' then data3d.data = data3d.data*data3d.denergy/(data3d.denergy+.00001)
if ndimen(data3d.data) eq ndimen(data3d.bins) then data3d.data=data3d.data*data3d.bins
str_element,limits,'color',value=col

nb = data3d.nbins

if not keyword_set(title) then begin
   If(data3d.project_name EQ 'THEMIS') Then $
      title = data3d.project_name+' '+strupcase(data3d.spacecraft)+' '+data3d.data_name $
   Else title = data3d.project_name+' '+data3d.data_name
   title = title+'!C'+trange_str(data3d.time,data3d.end_time)
endif

ytitle = units_string(data3d.units_name)

ydat = data3d.data

str_element,limits,'velocity',value=vel
if keyword_set(vel) then begin
   xdat = velocity(data3d.energy,data3d.mass)
   xtitle = "Velocity'  (km/s)"
endif else begin
   xdat = data3d.energy
   xtitle = 'Energy  (eV)'
endelse

;print,minmax(xdat)

 str_element,limits,'bins',bins


if keyword_set(phi) then begin
   phi = reform(data3d.phi[0, *])
;   col = bytescale(phi,range=[-180.,180.])
   col = bytescale(phi);,range=[-180.,180.])
endif 

if keyword_set(theta) then begin
   theta = reform(data3d.theta[0, *])  ; average theta
;   col = bytescale(theta,range=[-90.,90.])
   col = bytescale(theta);,range=[-90.,90.])
endif

if keyword_set(pang) then str_element,data3d,'magf',vec
if keyword_set(sundir) then vec = [-1.,0.,0.]


if keyword_set(vec)  then begin
   phi = average(data3d.phi,1,/nan)   ; average phi
   theta = average(data3d.theta,1,/nan)  ; average theta
   xyz_to_polar,vec,theta=bth,phi=bph
   p = pangle(theta,phi,bth,bph)
   col = bytescale(p,range=[0.,180.])   
endif


if keyword_set(col) then shades  = col
if keyword_set(label) then labels = strcompress(indgen(nb))

if not keyword_set(bins) then bins = replicate(1b,nb)

plot={title:title, $
     xtitle:xtitle,x:xdat,xlog:1, $
     ytitle:ytitle,y:ydat,ylog:1,bins:bins  }

str_element,data3d,'ddata',value =dydat
str_element,plot,'dy',dydat,/add

;wi,lim=limits


mplot,data=plot,COLORS=shades,limits=limits,LABELS=labels,OVERPLOT=oplot

; the following was added by mcfadden

if keyword_set(pot) then oplot,[tempdat.sc_pot,tempdat.sc_pot],[1.e-30,1.e30]
if keyword_set(sec) then begin
	inc_dat = conv_units(tempdat,'eflux')
	inc_dat1=inc_dat
	if inc_dat.nbins ne 1 then odat=omni3d(inc_dat) else odat=inc_dat

	energy=odat.energy
	nenergy=odat.nenergy
	sec_spec=dblarr(nenergy)
	sec_spec1=dblarr(nenergy)

	tmax = 2.283 & aa = 1.35 & delta_max = 1.0 & emax = 325. & en_acc = 0. & k = 2.2
	delta = delta_max * ((energy+en_acc)/emax)^(1-aa)*(1-exp(-tmax*((energy+en_acc)/emax)^aa))/(1-exp(-tmax))
	en_eff = (1-exp(-k*delta/delta_max))/(1-exp(-k))

	for k=1,nenergy-2 do begin
		sec_spec[k:nenergy-1]=sec_spec[k:nenergy-1]+odat.data[k]*0.4d*(energy[k]/10.)^.15/energy[k:nenergy-1]^2.
		sec_spec1[k:nenergy-1]=sec_spec1[k:nenergy-1]+odat.data[k]*1.2d*en_eff[k]/energy[k:nenergy-1]^2.0
	endfor
;	print,sec_spec
	inc_dat.data=sec_spec#replicate(1.d,tempdat.nbins)
	inc_dat1.data=sec_spec1#replicate(1.d,tempdat.nbins)
	sec_dat = conv_units(inc_dat,units)
	sec_dat1 = conv_units(inc_dat1,units)
	oplot,sec_dat.energy[*,0],sec_dat.data[*,0]
	oplot,sec_dat1.energy[*,0],sec_dat1.data[*,0],color=6
endif

if keyword_set(est_pot) then begin 
   sc_pot_est = thm_esa_dist2scpot(tempdat, /pr_slope, _extra = _extra)
   oplot,[sc_pot_est,sc_pot_est],[1.e-30,1.e30], color = 6, thick =2
endif

time_stamp

end
;+
;NAME:
; thm_esa_test_spec3d2
;PURPOSE:
; Wrapper for spec3d2, plots PEEF, PEER, PEEB data; the user clicks on
; a time, and spec3d2 estimates the sc potential for each mode, and
; plots the distribution with the potential overplotted. A black line
; for the measured potential, and a red line for the
; estimated potential
;INPUT:
; date = a date, e.g., '2008-01-05'
; probe = a probe, e.g., 'c'
;OUTPUT:
; plots of the 3d distribution for each mode, with SC_POT plotted on
; the graph.
; init = if set, read in a new set of data
; random_dp = if set, the input date and probe are randomized, note
;             that this keyword is unused if init is not set.
;HISTORY:
; 31-may-2015, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-07-24 15:57:59 -0700 (Fri, 24 Jul 2015) $
; $LastChangedRevision: 18252 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_test_spec3d2.pro $
;-
Pro thm_esa_test_spec3d2, date, probe, init = init, random_dp = random_dp, $
                          time_in = time_in, _extra = _extra

  If(keyword_set(init)) Then Begin
     del_data, '*'
     If(keyword_set(random_dp)) Then Begin
        probes = ['a', 'b', 'c', 'd', 'e']
        index = fix(5*randomu(seed))
        probe = probes[index]
;start in 2008
        t0 = time_double('2008-01-01')
        t1 = time_double(time_string(systime(/sec), /date))
        dt = t1-t0
        date = time_string(t0+dt*randomu(seed), /date)
     Endif
     sc = probe
     timespan, date
     print, 'date: ', date
     print, 'Probe: ', strupcase(sc)
     thm_load_esa_pkt, probe = sc
     thm_load_esa_pot, efi_datatype = 'mom', probe = sc
  Endif Else sc = probe

  window, xs = 1024, ys = 1024
  If(keyword_set(time_in)) Then t = time_double(time_in) Else Begin
     tplot, 'th'+sc+'_pee?_en_counts'
     ctime, t
  Endelse

  p = execute('d = get_th'+sc+'_peeb(t)')
  p1 = execute('d1 = get_th'+sc+'_peef(t)')
  p2 = execute('d2 = get_th'+sc+'_peer(t)')

  !p.multi = [0, 1, 3]
  !p.charsize = 2
  options, limits, 'xrange', [1.0d0, 1.0d5]
  options, limits, 'yrange', [1.0d4, 1.0d9]
  spec3d2, d, /pot, /sec, limits = limits, /est_pot, _extra = _extra
  spec3d2, d1, /pot, /sec, limits = limits, /est_pot, _extra = _extra
  spec3d2, d2, /pot, /sec, limits = limits, /est_pot, _extra = _extra

End
