;+
; PROCEDURE:
;       mex_marsis_snap
; PURPOSE:
;       Plots ionograms for times selected with the cursor in a tplot window.
;       Hold down the left mouse button and slide for a movie effect.
; CALLING SEQUENCE:
;       mex_marsis_snap, /keepwin
; KEYWORDS:
;       window: window number (Def. a new window will be generated)
;       keepwin: do not delete the snap window
; CREATED BY:
;       Yuki Harada on 2017-05-11
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2024-01-24 23:36:07 -0800 (Wed, 24 Jan 2024) $
; $LastChangedRevision: 32408 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/marsis/mex_marsis_snap.pro $
;-

pro mex_marsis_snap, window=window, keepwin=keepwin, time=t0, _extra=_ex, nowindow=nowindow, noaalt=noaalt, symsize=symsize, noinv=noinv, nochfit=nochfit, csv_save=csv_save, aalt_return=aalt, td_return=td, freq_return=freq, sdens_return=sdens, psym_thld=psym_thld

@mex_marsis_com

if ~size(marsis_ionograms,/type) and ~size(marsis_inv,/type) then begin
   dprint,'No ionogram/inversion data are loaded'
   return
endif

if ~keyword_set(noinv) and size(marsis_inv,/type) ne 0 then inv=1 else inv=0
if ~keyword_set(symsize) then symsize = .5
if keyword_set(psym_thld) then if psym_thld eq 1 then psym_thld = 1e-15 ;- default threshold

tplot_options, get_opt=topt
str_element, topt, 'window', value=Twin, success=ok
if (not ok) then Twin = !d.window

;;; set up a window
dsize = get_screen_size()
if ~keyword_set(nowindow) then if size(window,/type) ne 0 then Iwin = window else begin
   window, /free, xsize=dsize[0]/2., ysize=dsize[1]*2./3.,xpos=0., ypos=dsize[1]/3.
   Iwin = !d.window
endelse

oldpmulti = !p.multi

if size(t0,/type) eq 0 then begin
   print, 'Use button 1 to select time; button 3 to quit.'
   ctime,t,npoints=1,/silent
endif else t = time_double(t0)

ok = 1
while (ok) do begin
   if ~keyword_set(nowindow) then wset,Iwin

   if size(marsis_ionograms,/type) ne 0 then begin
   ;;; get data
   tmp = min( abs(marsis_ionograms.time - t) , inow )
   orbstr = string(marsis_ionograms[inow].orbnum,f='(i0)')
   time = marsis_ionograms[inow].time
   freq = marsis_ionograms[inow].freq /1e6
   sdens = marsis_ionograms[inow].spec
   arange = 0.1499 * marsis_delay_times
   td = marsis_delay_times /1e3

   geom_str = ''
   alt =!values.f_nan
   if size(marsis_geometry,/type) ne 0 then begin
      alt = interp(marsis_geometry.alt,marsis_geometry.time,time, $
                   interp=10,/no_ex)
;;       tmp = min(abs(marsis_geometry.time-time),imin)
;;       if tmp lt 10 then alt = marsis_geometry[imin].alt
      geom_str = ', Alt: '+string(alt,f='(f6.1)')
   endif
   if ~keyword_set(noaalt) and finite(alt) then altflag = 1 else altflag = 0

   if inv then !p.multi = [0,1,2]

   dlim = {xmargin:[8,12+10*altflag],xtitle:'Frequency [MHz]',xstyle:1, $
           xrange:[0,max(freq)],xticklen:-.01,yticklen:-.01, $
           ymargin:[4,2],ytitle:'Time Delay [ms]', $
           yrange:[max(marsis_delay_times/1e3),0],ystyle:1+8*altflag, $
           ztitle:'Spectral Density!c[(V/m)!u2!n/Hz]', $
           zlog:1,zrange:[1e-18,1e-10],no_interp:1,zoffset:[1,2]+10*altflag, $
           minzlog:1e-30, $
           title:'Orb '+orbstr+', ' $
           +time_string(time,tf='YYYY-MM-DD/hh:mm:ss.fff')+geom_str}
   extract_tags,dlim,_ex
   specplot,freq,marsis_delay_times/1e3,sdens,lim=dlim
   if altflag then begin
      aalt = alt-0.1499*marsis_delay_times
      axis,yaxis=1,ystyle=1,ytitle='Apparent Alt. [km]',yticklen=-.01, $
           yrange=alt+[-0.1499*max(marsis_delay_times),0.]
   endif else aalt = marsis_delay_times * !values.f_nan

   if keyword_set(psym_thld) then begin
      w = where(sdens gt psym_thld , nw)
      if nw gt 0 then begin
         nx = n_elements(freq)
         ny = n_elements(marsis_delay_times)
         xx = rebin(freq,nx,ny)
         yy = transpose(rebin(marsis_delay_times/1e3,ny,nx))
         plots,xx[w],yy[w],psym=1,color=1,symsize=.5
      endif
   endif
   
   if keyword_set(csv_save) then begin
      csv_filename = 'iono_'+time_string(time,tf='YYYYMMDD_hhmmss')+'.csv'
      aalt = alt -0.1499*marsis_delay_times
      openw,unit,csv_filename,/get_lun
      line = 'aalt [km] (column) / freq [MHz] (row)'
      for ifreq=0,n_elements(freq)-1 do line += ', '+string(freq[ifreq],f='(f9.3)')
      printf,unit,line
      for iaalt=0,n_elements(aalt)-1 do begin
         line = string(aalt[iaalt],f='(f9.2)')
         for ifreq=0,n_elements(freq)-1 do begin
            line += ', '+string(sdens[ifreq,iaalt],f='(e9.2)')
         endfor
         printf,unit,line
      endfor
      free_lun,unit
   endif
   
   ;;; plots plasma line harmonics and electron cyclotron echoes
   if size(marsis_eledens_bmag,/type) eq 8 then begin
      tmp = min( abs(marsis_eledens_bmag.time - time) , inow )
      if tmp lt 7 then begin
         for i=1,16 do begin
            oplot,[1,1]*marsis_eledens_bmag[inow].fpe/1e3*i,[0,.167], $
                  color=6,thick=2
            oplot,[0,.1],[1,1]*marsis_eledens_bmag[inow].tce*i, $
                  color=6,thick=2
         endfor
      endif
   endif


   ;;; plots ionosphere trace
   if size(marsis_itrc,/type) ne 0 then begin
      tmp = min( abs(marsis_itrc.time - time) , inow )
      if tmp lt 7 then begin
         fr_itrc = marsis_itrc[inow].freq
         td_itrc = marsis_itrc[inow].td
         oplot,fr_itrc,td_itrc,color=6
         oplot,fr_itrc,td_itrc,color=6,psym=4,symsize=symsize
      endif
   endif

   endif ;- ionogram


   ;;; plot inversion results
   if inv then begin
      tmp = min(abs(marsis_inv.time-t),inow)
      if tmp lt 7. then begin
         alt_inv = marsis_inv[inow].alt
         aalt_inv = marsis_inv[inow].aalt
         dens_inv = marsis_inv[inow].dens
         alt_inv_interp = marsis_inv[inow].alt_interp
         dens_inv_interp = marsis_inv[inow].dens_interp
         plot,[0],/nodata, $
              xtitle='Density [cm!u-3!n]',xrange=[1e2,1e6],xlog=1, $
              ytitle='Altitude [km]',yrange=[0,max(alt_inv,/nan)], $
              title='inversion qflag = '+string(marsis_inv[inow].qflag,f='(i0)')
         oplot,dens_inv,aalt_inv,color=6
         oplot,dens_inv,aalt_inv,psym=4,symsize=symsize,color=6
         oplot,dens_inv_interp,alt_inv_interp
         oplot,dens_inv,alt_inv,psym=4,symsize=symsize
         ;;; Chapman fit
         if size(marsis_itrc,/type) eq 8 and ~keyword_set(nochfit) then begin
            tmp = min(abs(marsis_itrc.time-t),inow2)
            szanow = marsis_itrc[inow2].sza
            chapman_fit_set_sza,sza=szanow
            w = where(finite(dens_inv*alt_inv),nw)
            if nw gt 3 then begin
               x = alt_inv[w]
               y = dens_inv[w]
               freq_arr = 8980.*y^.5 *1e-6
               del_freq_arr = 0. * freq_arr + 1.e-6 * 10937.0/2.0
               chapman_fit, freq_arr, x, del_freq_arr, a_fit, sigma_a, rchisq, dof, fit_ind, fit_qual
               x_extend=findgen(1000)
               chapman_funct,x_extend,a_fit,f_extend
               oplot,exp(f_extend),x_extend,color=2
               xyouts,color=2,/norm,.8,.4, $
                      'n0 = '+string(exp(a_fit[0]),f='(e7.1)') $
                      +'!ch0 = '+string(a_fit[1],f='(f5.1)') $
                      +'!cH = '+string(a_fit[2],f='(f4.1)') $
                      +'!cSZA = '+string(szanow,f='(f5.1)') ;$
;                      +'!cqual = '+string(fit_qual)
            endif
         endif
      endif
      !p.multi = oldpmulti
   endif


   if size(t0,/type) eq 0 then begin
      wait,.1
      wset,Twin
      ctime,t,npoints=1,/silent
      if (data_type(t) eq 5) then ok = 1 else ok = 0
   endif else ok = 0
endwhile

if ~keyword_set(nowindow) then if ~keyword_set(keepwin) and size(t0,/type) eq 0 then wdelete,Iwin

end


