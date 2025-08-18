;+
;PROCEDURE:   sweiccd
;PURPOSE:
;  Performs SWEA-SWIA cross calibration.  This is the companion routine 
;  for sweicc.pro.  This is only intended for the SWEA team and is not
;  designed for general use.
;
;USAGE:
;  sweiccd
;
;INPUTS:
;
;KEYWORDS:
;
;       NBEEP:    Get the user's attention by beeping this many times.
;
;       ALPHA:    Calculate the ion density of H+ and He++ separately
;                 using SWIA code.  Can result in better estimates of the
;                 total ion number density.
;
;       CCRANGE:  Plotting limits for the cross calibration factor.
;
;       NOSWI:    Get ion density from the standard SWIA tplot variable
;                 instead of calculating it from L2.  Not recommended.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-05-06 16:33:10 -0700 (Mon, 06 May 2024) $
; $LastChangedRevision: 32558 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/sweiccd.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: sweiccd.pro
;-
pro sweiccd, nbeep=nbeep, alpha=alpha, noswi=noswi

  noswi = keyword_set(noswi)
  alpha = keyword_set(alpha)

;------------------------------------------------------------------
; Calculate densities and compare SWEA and SWIA

  mvn_swe_n1d, mom=1, qlevel=1
  mvn_swe_swi_cal, alpha=alpha, coarse=1, fine=0, burst=0, noswi=noswi
  ylim,'swe_swi_crosscal',1,4,0
  get_data,'swe_swi_crosscal',data=ccal
  swe_crosscal = mvn_swe_crosscal(ccal.x)
  ylim,'mvn_swics_en_eflux',25,25000,1
  options,'mvn_swics_en_eflux','ztitle','EFLUX'
  tplot_options,'title',string(swe_crosscal[0],format='("CROSSCAL =",f5.2)')
    options,'mvn_swim_atten_state','panel_size',0.05
    options,'mvn_swim_atten_state','no_color_scale',1
    options,'mvn_swim_atten_state','ytitle','SWI!cATT'
    options,'mvn_swim_atten_state','yticks',1
    options,'mvn_swim_atten_state','yminor',1
    options,'mvn_swim_atten_state','ytickname',[' ',' ']
    options,'mvn_swim_atten_state','x_no_interp',1
    options,'mvn_swim_atten_state','xstyle',1
    options,'mvn_swim_atten_state','ystyle',1

;------------------------------------------------------------------
; Get SWIA temperature and velocity moments

  get_data,'mvn_swics_velocity',data=vsw
  vmag = sqrt(total(vsw.y^2.,2))
  vphi = atan(vsw.y[*,1],vsw.y[*,0])*!radeg
  indx = where(vphi lt 0., count)
  if (count gt 0L) then vphi[indx] += 360.
  vthe = asin(vsw.y[*,2]/vmag)*!radeg

  store_data,'Vmag',data={x:vsw.x, y:vmag}
  ylim,'Vmag',100,1000,1
  options,'Vmag','ytitle','SWIA!c| V |!c[km/s]'
  store_data,'Vphi',data={x:vsw.x, y:(vphi-180.)}
  ylim,'Vphi',-20,20,0
  options,'Vphi','yticks',0
  options,'Vphi','yminor',0
  options,'Vphi','ytitle','Vphi-180'

  store_data,'Vthe',data={x:vsw.x, y:vthe}
  ylim,'Vthe',-20,20,0
  options,'Vthe','yticks',0
  options,'Vthe','yminor',0

  store_data,'Vangles',data=['Vphi','Vthe']
  ylim,'Vangles',-20,20,0
  options,'Vangles','ytitle','SWIA!cV direction!c[deg]'
  options,'Vangles','constant',[-10,0,10]
  options,'Vangles','colors',[4,6]
  options,'Vangles','labels',['Az-180','Elev']
  options,'Vangles','labflag',1

  get_data,'mvn_swics_temperature',data=tsw
  store_data,'Tsw',data={x:tsw.x, y:tsw.y[*,3]}
  ylim,'Tsw',3,300,1
  options,'Tsw','ytitle','SWIA!cIon Temp!c[eV]'

; Put it all together

  tplot,['mvn_swics_en_eflux','mvn_swim_atten_state','swe_a4_pot',$
         'mvn_att_bar','Vmag','Vangles','Tsw','ie_density',$
         'swe_swi_crosscal']

  if (size(nbeep,/type) gt 0) then annoy, nbeep

end

