;+
;PROCEDURE:   sweicc
;PURPOSE:
;  Performs SWEA-SWIA cross calibration.  This is only intended for the
;  SWEA team and is not designed for general use.
;
;USAGE:
;  sweicc
;
;INPUTS:
;
;KEYWORDS:
;
;       NBEEP:    Get the user's attention by beeping this many times.
;
;       ODAT:     Spacecraft orbit database.  If not set, then it is 
;                 regenerated.
;
;       CCRANGE:  Plotting limits for the cross calibration factor.
;
;       NODEN:    Do not calculate ion or electron densities, which means
;                 that the cross calibration is interrupted before it can
;                 finish.  This interruption is needed to check and, if
;                 necessary, refine the s/c potential.
;
;       NOPAD:    Suppress the PAD panel to save time.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-05-06 16:33:10 -0700 (Mon, 06 May 2024) $
; $LastChangedRevision: 32558 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/sweicc.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: sweicc.pro
;-
pro sweicc, date, nbeep=nbeep, odat=odat, ccrange=ccrange, noden=noden, nopad=nopad

  if (size(odat,/type) ne 8) then odat = mvn_orbit_num()
  dopad = ~keyword_set(nopad)

  timespan, date
  mvn_swe_load_l0
  mvn_sundir,frame='swea',/polar
  mvn_earthdir
  options,'Earth_Spacecraft_The','color',2
  mvn_swe_addmag,/usepad
  cc = mvn_swe_crosscal(/off)
  mvn_swe_makespec
  mvn_swe_set_quality, refresh=0, /doplot, /silent

  mvn_mag_geom
  mvn_mag_tplot
  mvn_swe_sumplot,/load
  if (dopad) then mvn_swe_pad_restore
  mvn_scpot,sta=0,sha=0,qlevel=1,qint=3
  options,'swe_a4','ytitle','SWEA!cEnergy (eV)'
  options,'Sun_SWEA_The','colors',[4]
  ylim,'mvn_mag_bamp',0.1,100,1
  options,'mvn_mag_bamp','constant',[1.,10.]
  tplot,['alt2','Sun_Earth_The','mvn_mag_bamp','mvn_mag_bang',$
         'mvn_swe_pad_resample','swe_quality','swe_a4_pot']
  timebar,odat.peri_time,/line

  if ~keyword_set(noden) then begin
    mvn_swe_n1d, /mom, qlevel=1
    mvn_swe_swi_cal, alpha=1
    ylim,'swe_swi_crosscal',1,4,0
    get_data,'swe_swi_crosscal',data=ccal
    swe_crosscal = mvn_swe_crosscal(ccal.x)
    ylim,'mvn_swics_en_eflux',25,25000,1
    case n_elements(ccrange) of
        0  : ylim,'swe_swi_crosscal',1,4.5,0
        1  : ylim,'swe_swi_crosscal',1,ccrange[0],0
        2  : ylim,'swe_swi_crosscal',ccrange,0
      else : ylim,'swe_swi_crosscal',ccrange[0:2]
    endcase
    options,'mvn_swim_atten_state','panel_size',0.05
    options,'mvn_swim_atten_state','no_color_scale',1
    options,'mvn_swim_atten_state','ytitle','SWI!cATT'
    options,'mvn_swim_atten_state','yticks',1
    options,'mvn_swim_atten_state','yminor',1
    options,'mvn_swim_atten_state','ytickname',[' ',' ']
    options,'mvn_swim_atten_state','x_no_interp',1
    options,'mvn_swim_atten_state','xstyle',1
    options,'mvn_swim_atten_state','ystyle',1
    tplot_options,'title',string(swe_crosscal[0],format='("CROSSCAL =",f5.2)')
    tplot,['alt2','Sun_Earth_The','mvn_mag_bamp','mvn_mag_bang','swe_swi_crosscal',$
           'ie_density','mvn_swics_en_eflux','mvn_swim_atten_state','swe_a4_pot']
  endif else begin
    tplot_options,'title','Potential Evaluation'
    tplot,['alt2','Sun_Earth_The','mvn_mag_bamp','mvn_mag_bang', $
           'mvn_swe_pad_resample','swe_a4_pot']
  endelse

  timebar,odat.peri_time,/line

  if (size(nbeep,/type) gt 0) then annoy, nbeep

end

