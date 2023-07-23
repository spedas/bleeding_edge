;+
;
; ESC_IESA_FM1_ANO
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 31963 $
; $LastChangedDate: 2023-07-21 12:05:49 -0700 (Fri, 21 Jul 2023) $
; $LastChangedBy: rlivi04 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_fm1_ano.pro $
;
;-

PRO esc_iesa_fm1_ano, ano
   
   ;; Anode Board Dimensions [in]
   nn = 10.
   rad1 = 0.818
   rad2 = 1.147
   rad3 = 1.246
   rad4 = 1.813
   anode_dim = fltarr(27,2,nn*2+2)

   ;; Start Anodes
   pp = indgen(nn+1)/nn*22.5*!DTOR
   off = 180*!DTOR 
   FOR i=0, 10 DO $
    anode_dim[i,*,*] = transpose($
    [[cos(pp+22.5*i*!DTOR+off)*rad1,$
      cos(reverse(pp)+22.5*i*!DTOR+off)*rad2],$
     [sin(pp+22.5*i*!DTOR+off)*rad1,$
      sin(reverse(pp)+22.5*i*!DTOR+off)*rad2]])

   ;; Small Stop Anodes
   pp = indgen(nn+1)/nn*11.25*!DTOR
   off =  180*!DTOR - (90.+11.25*3)*!DTOR
   FOR i=11, 20 DO $
    anode_dim[i,*,*] = transpose($
    [[cos(pp+11.25*i*!DTOR+off)*rad3,$
      cos(reverse(pp)+11.25*i*!DTOR+off)*rad4],$
     [sin(pp+11.25*i*!DTOR+off)*rad3,$
      sin(reverse(pp)+11.25*i*!DTOR+off)*rad4]])

   ;; Large Stop Anodes
   pp = indgen(nn+1)/nn*22.5*!DTOR
   offs = 11.*11.25*!DTOR
   FOR i=21, 26 DO $
    anode_dim[i,*,*] = transpose($
    [[cos(pp+22.5*i*!DTOR+offs+off)*rad3,$
      cos(reverse(pp)+22.5*i*!DTOR+offs+off)*rad4],$
     [sin(pp+22.5*i*!DTOR+offs+off)*rad3,$
      sin(reverse(pp)+22.5*i*!DTOR+offs+off)*rad4]])

   ;; PLOT ANODE BOARD
   IF keyword_set(plot_anodes) THEN begin
      window, 0, xsize = 900,ysize = 900
      plot, [0,1],[0,1],xr=[-3,3],yr=[-3,3],/iso,xs=1,ys=1, /nodata
      FOR i=0,26 DO begin
         xx = [reform(anode_dim[i,0,*]),anode_dim[i,0,0]]
         yy = [reform(anode_dim[i,1,*]),anode_dim[i,1,0]]
         oplot, xx, yy
      ENDFOR
   ENDIF

   ano =  {rad1:rad1,$
           rad2:rad2,$
           rad3:rad3,$
           rad4:rad4,$
           anode_dim:anode_dim}

END 
