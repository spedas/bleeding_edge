 ;+
;PROCEDURE:   mvn_lpw_prd_lp_sweep_plot
;
;INPUTS:
;KEYWORDS: PP, time, tnameV, tnameI, win
;     time   : Time to display. In format of 'YYYY-MM-DD/HH:MM:SS' or 'HH:MM:SS'
;     PP     : Sweep information structure
;     tnameV : 
;     tnameI :
;     win    :
;     ylims  : [y_min for linear plot, y_max for linear plot, y_min for log plot]
;     xlim   :
;EXAMPLE:
; sweep_plot,'2014-07-07/20:00:00.', tnameV='mvn_lpw_swp1_I1_pot', tnameI='mvn_lpw_swp1_I1'
;
;CREATED BY:   Michiko Morooka  10-06-14
;FILE:         sweep_plot.pro
;VERSION:      0.1
;LAST MODIFICATION: 
;   2014-10-20    Michiko Morooka Newly added to the product softwear.
;   2014-10-24    Michiko Morooka Miner change to add option to plot fitting result.
;   
;-

;------- this_version_mvn_lpw_prd_lp_sweep_plot -----------
function this_version_mvn_lpw_prd_lp_sweep_plot

  ver = 0.1
  pdr_ver= 'version mvn_lpw_prd_lp_sweep_plot: ' + string(ver,format='(F4.1)')
  return, pdr_ver
  
end
;-------------------------- mvn_lpw_prd_lp_sweep_plot -----

; ------- plot_res ----------------------------------------
function  plot_res, PP_org, win=win, Ie_ind=Ie_ind, $
                    Ii_ind=Ii_ind, Iion2=Iion2,ylim=ylim, $
                    nlog=nlog,prb12=prb12,info=info

  PP = PP_org
  title = PP.ptitle
  x_lim = PP.xlim & if x_lim(0) eq !values.F_nan then x_lim = [-10,20]  
  
  y_lim_dy = [-1e-8, 3e-7]
  
  help, win
  if keyword_set(ylim) eq 0 then ylim = [!Values.F_NAN,!Values.F_NAN,!Values.F_NAN]
  
  ; ===== window set up =====
 ;if strmatch(size(win,/tname),'UNDEFINED') ne 1 then wset, win $;WINDOW, win, XSIZE=900, YSIZE=1100, ypos=0, TITLE=title_txt $
  if keyword_set(win) eq 1 and win ne -1 then wset, win ;WINDOW, win, XSIZE=900, YSIZE=1100, ypos=0, TITLE=title_txt $
 ;else                          WINDOW, /free, XSIZE=900, YSIZE=1100, ypos=0, TITLE=title_txt
  win = !d.window

  charsize_org = !p.charsize

  !P.MULTI = [0, 1, 3]
  ;!P.title = title
  ;!p.background = 255
  ;!p.color = 0
  if win eq -1 then !p.charsize=2 else !p.charsize=3
  ;!p.font=0
  
  ; ===== plot set up =====
  ; Make a vector of 16 points, A[i] = 2pi/16:
  A = FINDGEN(17) * (!PI*2/16.)
  ; Define the symbol to be a unit circle with 16 points,
  ; and set the filled flag:
  if win eq -1 then USERSYM, 0.6*COS(A), 0.6*SIN(A), /FILL else USERSYM, 0.8*COS(A), 0.8*SIN(A), /FILL
  
  ;col sample: 'black','blue','green','red','Cyan','Magenta','black'
  if win eq -1 then   line_thick = 4 else  line_thick = 2
  cols = ['black','red','Green','Cyan','blue','Magenta']
  
  U = PP.voltage
  I = PP.current
  ; ===== LINEAR PLOT =====
  base_color = fsc_color('black')
  if PP.flg ne 0 then base_color = fsc_color('red')
  if finite(ylim(0)) then $
  plot,PP.voltage,PP.current,xstyle=9,psym=8, color=base_color, LINESTYLE=0, $
    XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1 ,XRange=x_lim, title=title, YRange=[ylim(0),ylim(1)],ystyle=1 $; , yrange=[-2e-7, 2e-6] ;ytitle='Current [A]'
  else $
    plot,PP.voltage,PP.current,xstyle=9,psym=8, color=base_color, LINESTYLE=0, $
    XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1 ,XRange=x_lim, title=title ; , yrange=[-2e-7, 2e-6] ;ytitle='Current [A]'
  oplot,PP.voltage,PP.current,color=fsc_color('black')     , thick=line_thick
  if keyword_set(prb12) then $
     oplot, PP.voltage_l0, PP.current_l0, color=fsc_color('red'), thick=line_thick
   if keyword_set(prb12) then $
     oplot, PP.voltage_l0, PP.current_l0, color=fsc_color('red'), thick=line_thick, psym=8     
  if finite(PP.Ne1) ne 0 then oplot, PP.voltage, PP.I_electron1, color=fsc_color('Cyan'), thick=line_thick
  if finite(PP.Ne2) ne 0 then oplot, PP.voltage, PP.I_electron2, color=fsc_color('Green'), thick=line_thick
  if finite(PP.Ne3) ne 0 then oplot, PP.voltage, PP.I_electron3, color=fsc_color('Olive'), thick=line_thick
  if Ie_ind              then oplot, PP.voltage, PP.Ie_ind, color=fsc_color('Violet'), thick=line_thick, psym=8
  if Ii_ind              then oplot, PP.voltage, PP.Ii_ind, color=fsc_color('Pink'), thick=line_thick
  if finite(PP.UV)  ne 0 then oplot, PP.voltage, PP.I_photo, color=fsc_color('Magenta'), thick=line_thick
  oplot, PP.voltage, PP.I_ion, color=fsc_color('red'), thick=line_thick
  if Iion2               then oplot, PP.voltage, PP.I_ion2, color=fsc_color('Pink'), thick=line_thick
  oplot, PP.voltage, PP.I_tot, color=fsc_color('blue'), thick=line_thick
  if finite(PP.U_zero) ne 0 then oplot, [PP.U_zero], [0.], psym=2, SYMSIZE=2, thick=line_thick, color=fsc_color('red')
  oplot, [-PP.Usc], [0.], psym=2, SYMSIZE=2, thick=line_thick, color=fsc_color('blue')
  ind = where(abs(pp.I_tot) eq min(abs(pp.I_tot)))
  oplot, [PP.voltage(ind)], [0.], psym=2, SYMSIZE=2, thick=line_thick, color=fsc_color('Cyan')
  oplot, -[pp.Usc,pp.Usc], [-1e-3,1e-3], linestyle=2, color=fsc_color('Olive')

  yyy = 0.02
  if n_elements(info) ne 0 then xyouts, 0.18, 0.95-indgen(n_elements(info))*yyy, info, charsize=!p.charsize-1.5, /normal

  ; ===== LOG PLOT =====
  if nlog then begin
    if finite(ylim(2)) then $
      plot,PP.voltage,alog(abs(PP.current)),psym=8, color=fsc_color('black'), LINESTYLE=0, $
                                            XRange=x_lim,xstyle=9, YRange=[ylim(2),ylim(1)],ystyle=1, $
                                            XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1,  $
                                            ytitle='log(I) [A]' $
    else $
      plot,PP.voltage,alog(abs(PP.current)),psym=8, color=fsc_color('black'), LINESTYLE=0, $
                                            XRange=x_lim, xstyle=9, $                                            
                                            XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1, $
                                            ytitle='log(I) [A]'
    oplot,PP.voltage,alog(abs(PP.current)),color=fsc_color('black'), thick=line_thick
    if keyword_set(prb12) then $
      oplot,PP.voltage_l0,alog(abs(PP.current_l0)),color=fsc_color('red'), thick=line_thick
    if keyword_set(prb12) then $
      oplot,PP.voltage_l0,alog(abs(PP.current_l0)),color=fsc_color('red'), thick=line_thick, psym=8
    if PP.Ne1 ne !values.F_nan then oplot, PP.voltage, alog(abs(PP.I_electron1)), color=fsc_color('Cyan'), thick=line_thick
    if PP.Ne2 ne !values.F_nan then oplot, PP.voltage, alog(abs(PP.I_electron2)), color=fsc_color('Green'), thick=line_thick
    if PP.Ne3 ne !values.F_nan then oplot, PP.voltage, alog(abs(PP.I_electron3)), color=fsc_color('Olive'), thick=line_thick
    if PP.UV  ne !values.F_nan then oplot, PP.voltage, alog(abs(PP.I_photo)), color=fsc_color('Magenta'), thick=line_thick
    oplot, PP.voltage, alog(abs(PP.I_ion)), color=fsc_color('red'), thick=line_thick
    if Iion2                   then oplot, PP.voltage, alog(abs(PP.I_ion2)), color=fsc_color('Pink'), thick=line_thick
    if Ie_ind                  then oplot, PP.voltage, alog(abs(PP.Ie_ind)), color=fsc_color('Violet'), thick=line_thick,psym=8
    if Ii_ind                  then oplot, PP.voltage, alog(abs(PP.Ii_ind)), color=fsc_color('Pink'), thick=line_thick    
    oplot, PP.voltage, alog(abs(PP.I_tot)), color=fsc_color('blue'), thick=line_thick
    oplot, -[pp.Usc,pp.Usc], [1e-10,1e-3], linestyle=2, color=fsc_color('Olive')
  endif else begin
    if finite(ylim(2)) then $
      plot,PP.voltage,abs(PP.current),psym=8, color=fsc_color('black'), LINESTYLE=0, /ylog, $
                                      XRange=x_lim,xstyle=9, YRange=[ylim(2),ylim(1)],ystyle=1, $
                                      XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1,  $
                                      ytitle='I [A]' $
    else $
      plot,PP.voltage,abs(PP.current),psym=8, color=fsc_color('black'), LINESTYLE=0, /ylog, $
                                      XRange=x_lim, xstyle=9, $
                                      XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1, $
                                      ytitle='I [A]'
    oplot,PP.voltage,abs(PP.current),color=fsc_color('black'), thick=line_thick
    if keyword_set(prb12) then $
      oplot,PP.voltage_l0,abs(PP.current_l0),color=fsc_color('red'), thick=line_thick
    if keyword_set(prb12) then $
      oplot,PP.voltage_l0,abs(PP.current_l0),color=fsc_color('red'), thick=line_thick, psym=8
    if PP.Ne1 ne !values.F_nan then oplot, PP.voltage, abs(PP.I_electron1), color=fsc_color('Cyan'), thick=line_thick
    if PP.Ne2 ne !values.F_nan then oplot, PP.voltage, abs(PP.I_electron2), color=fsc_color('Green'), thick=line_thick
    if PP.Ne3 ne !values.F_nan then oplot, PP.voltage, abs(PP.I_electron3), color=fsc_color('Olive'), thick=line_thick
    if Ie_ind                  then oplot, PP.voltage, abs(PP.Ie_ind), color=fsc_color('Violet'), thick=line_thick,psym=8
    if Ii_ind                  then oplot, PP.voltage, abs(PP.Ii_ind), color=fsc_color('Pink'), thick=line_thick
    if PP.UV  ne !values.F_nan then oplot, PP.voltage, abs(PP.I_photo), color=fsc_color('Magenta'), thick=line_thick
    oplot, PP.voltage, abs(PP.I_ion), color=fsc_color('red'), thick=line_thick
    if Iion2                   then oplot, PP.voltage, abs(PP.I_ion2), color=fsc_color('Pink'), thick=line_thick
    oplot, PP.voltage, abs(PP.I_tot), color=fsc_color('blue'), thick=line_thick    
    oplot, -[pp.Usc,pp.Usc], [1e-10,1e-3], linestyle=2, color=fsc_color('Olive')
  endelse
  
  yrange = [min([deriv(PP.voltage,PP.current),deriv(PP.voltage,PP.I_tot),deriv(PP.voltage_l0,PP.current_l0)],/nan), $
            max([deriv(PP.voltage,PP.current),deriv(PP.voltage,PP.I_tot),deriv(PP.voltage_l0,PP.current_l0)],/nan)]
; yrange=[0,1.5e-5]
  ; ===== DeRIVERTIVE PLOT =====
  plot,PP.voltage,deriv(PP.voltage,PP.current),xstyle=9,psym=8, color=fsc_color('black'), LINESTYLE=0, $
    XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1, $
    XRange=x_lim, YRange=yrange, $
    ytitle='dI/dV';, yrange=[0.0, 1.5e-8], ystyle=1
  oplot,PP.voltage,deriv(PP.voltage,PP.current),color=fsc_color('black'), thick=line_thick
  if keyword_set(prb12) then $
    oplot,PP.voltage_l0,deriv(PP.voltage_l0,PP.current_l0),color=fsc_color('red'), thick=line_thick  
  if keyword_set(prb12) then $
    oplot,PP.voltage_l0,deriv(PP.voltage_l0,PP.current_l0),color=fsc_color('red'), thick=line_thick, psym=8
  if PP.Ne1 ne !values.F_nan then oplot, PP.voltage, deriv(PP.voltage,PP.I_electron1), color=fsc_color('Cyan'), thick=line_thick
  if PP.Ne2 ne !values.F_nan then oplot, PP.voltage, deriv(PP.voltage,PP.I_electron2), color=fsc_color('Green'), thick=line_thick
  if PP.Ne3 ne !values.F_nan then oplot, PP.voltage, deriv(PP.voltage,PP.I_electron3), color=fsc_color('Olive'), thick=line_thick
  if Ie_ind                  then oplot, PP.voltage, deriv(PP.voltage,PP.Ie_ind), color=fsc_color('Violet'), thick=line_thick,psym=8
  if Ii_ind                  then oplot, PP.voltage, deriv(PP.voltage,PP.Ii_ind), color=fsc_color('Pink'), thick=line_thick
  if PP.UV  ne !values.F_nan then oplot, PP.voltage, deriv(PP.voltage,PP.I_photo), color=fsc_color('Magenta'), thick=line_thick
  oplot, PP.voltage, deriv(PP.voltage,PP.I_ion), color=fsc_color('red'), thick=line_thick
  if Iion2                  then oplot, PP.voltage, deriv(PP.voltage,PP.I_ion2), color=fsc_color('Pink'), thick=line_thick
  oplot, PP.voltage, deriv(PP.voltage,PP.I_tot), color=fsc_color('blue'), thick=line_thick
  oplot, -[pp.Usc,pp.Usc], [-1e-3,1e-3], linestyle=2, color=fsc_color('Olive')
  
  !P.MULTI = 0
  !p.charsize = charsize_org
  ;!P.title = ''
  ;wait, 0.1
  return, 1
end
; ------------------------------------------ plot_res -----

;------- convertstruc_ree2mm ------------------------------
function convertstruc_ree2mm, LP_ree

  print, 'Convert Ree struc to pp'
  PP = mvn_lpw_prd_lp_swp_setupparam('')

  PP.time = LP_ree.time
  PP.time_l0 = LP_ree.DATA.TSWP
  PP.probe   = LP_ree.boom
  PP.ptitle = strmid(PP.proj,0,5)+'_P'+string(LP_ree.boom,format='(I01)')+' '+ $
    time_string(PP.time_l0(0))+'-'+ $
    strmid(time_string(PP.time_l0(n_elements(PP.time_l0)-1)),11,18)
  ; PP.RXA    =
  ; PP.R_sun  =
  PP.swp_mode    = LP_ree.data.mode
  PP.VOLTAGE_L0  = LP_ree.data.Vswp
  PP.CURRENT_L0  = LP_ree.data.Iswp

 ;PP.VOLTAGE   =  LP_ree.data.Vswp;LP_ree.ree.arr.Vswp
 ;PP.CURRENT   =  LP_ree.data.Iswp ;LP_ree.ree.arr.Wswp is weight
  PP.VOLTAGE   =  LP_ree.data.Vswp; LP_ree.ree.arr.Vswp;LP_ree.ree.arr.Vswp
  PP.CURRENT   =   LP_ree.data.Iswp; LP_ree.ree.arr.Iswp ;LP_ree.ree.arr.Wswp is weight

  PP.I_PHOTO      = LP_ree.ree.arr.Iphe
  PP.I_ION        = LP_ree.ree.arr.Iion
  PP.I_ELECTRON1  = LP_ree.ree.arr.Ie
  PP.I_ELECTRON2  = LP_ree.ree.arr.Ihot
  ; PP.I_ELECTRON3
  PP.I_TOT        = LP_ree.ree.arr.Iall
  ; PP.I_TMP        =
  ; PP.I_ION2
  ; PP.I_TOT2
  PP.VSC          = LP_ree.anc.MSO_vel.mag
  PP.NO_E         = 1
  PP.NE_TOT       = LP_ree.ree.val.N *1e-6
  PP.NE1          = LP_ree.ree.val.N *1e-6
  PP.NE2          = LP_ree.ree.val.Nhot *1e-6
  ; PP.NE3
  ; PP.NEPROX
  ; PP.U_ZERO
  ; PP.U0              FLOAT               NaN
  ; PP.U1              FLOAT               NaN
  ; PP.U2              FLOAT               NaN
  ; PP.USC             FLOAT               NaN
  PP.Usc          = LP_ree.ree.val.Vsc
  PP.TE           = LP_ree.ree.val.TE
  PP.TE1          = LP_ree.ree.val.TE
  PP.TE2          = LP_ree.ree.val.THOT
  ; PP.TE3
  ; PP.FNORM
  ; PP.NI              FLOAT               NaN
  PP.TI           = LP_ree.ree.val.Ti
  ; PP.VI
  ; PP.M
  ; PP.B
  PP.MI           = LP_ree.ree.val.MI
  ; PP.MB_NORM
  ; pp.UV
  ; PP.II_IND          FLOAT     Array[128]
  ; PP.IE_IND          FLOAT     Array[128]
  ; EFIT_POINTS     INT              0
  if LP_ree.ree.val.valid eq 1 then pp.flg = 0 else pp.flg = -1
  ;PP.FLG          = LP_ree.ree.val.valid  
  
  ; FIT_ERR         FLOAT     Array[128, 2]
  ; FIT_ERR2        FLOAT               NaN
  ; PDR_VER         STRING    ' # version mvn_lpw_prd_lp_swp_setupparam:  2.1'
  PP.FIT_FUNCTION_NAME = 'Ree: '+LP_ree.ree.val.version
  ; U_INPUT         FLOAT     Array[3]

  if finite(PP.xlim(0)) ne 1 then PP.xlim = [min(PP.voltage,/Nan),max(PP.voltage,/Nan)]

  return, PP
end
;-------------------------------- convertstruc_ree2mm -----


;##################################################################################################
;   START MAIN PROCEDURE: mvn_lpw_prd_lp_sweep_plot
;##################################################################################################
pro mvn_lpw_prd_lp_sweep_plot, input, PP=PP, time=time, tnameV=tnameV, tnameI=tnameI, win=win, $
                               xlim=xlim, Ie_ind=Ie_ind,Ii_ind=Ii_ind, silent=silent, Iion2=Iion2, $
                               ylims=ylim, nlog=nlog, prb=prb, print_info=print_info
;------ the version number of this routine --------------------------------------------------------
  t_routine=SYSTIME(0)
  pdr_ver= this_version_mvn_lpw_prd_lp_sweep_plot()
  ;print, '------------------------------' & print, pdr_ver & print, '------------------------------'

;----- check inputs -------------------------------------------------------------------------------
  if keyword_set(input) eq 0 then begin
    if keyword_set(PP) and n_elements(PP) ne 1 and keyword_set(time) eq 0 then begin
      ctime,t,npoints=1, /silent ;,prompt="Use cursor to select a time"
        ;hours=hours,minutes=minutes,seconds=seconds,days=days,silent=silent
      time = time_string(t)
    endif else if keyword_set(PP) eq 0 and keyword_set(time) eq 0 then begin
      ctime,t,npoints=1, /silent ;,prompt="Use cursor to select a time"
      time = time_string(t)      
    endif
  endif
  if keyword_set(Ie_ind) eq 0 then Ie_ind = 0
  if keyword_set(Ii_ind) eq 0 then Ii_ind = 0
  if keyword_set(Iion2) eq 0 then Iion2 = 0
  if keyword_set(ylim) eq 0 then ylim = [!Values.F_NAN,!Values.F_NAN,!Values.F_NAN]

;----- check keywords -----------------------------------------------------------------------------
  if keyword_set(time) eq 0 and keyword_set(PP) eq 0 then begin & doc_library, 'mvn_lpw_prd_lp_sweep_plot' & retall & end
  if keyword_set(time) eq 1 and size(time,/type) ne 7 then begin & stop & doc_library, 'mvn_lpw_prd_lp_sweep_plot' & retall & end

  if keyword_set(prb) eq 0 then prb = 1
  if prb eq 12 then prb_char = string(1,format='(I0)') $
  else              prb_char = string(prb,format='(I0)')
  if keyword_set(tnameV) eq 0 then tnameV = 'mvn_lpw_swp'+prb_char+'_I'+prb_char+'_pot'
  if keyword_set(tnameI) eq 0 then tnameI = 'mvn_lpw_swp'+prb_char+'_I'+prb_char    
  
;----- Convert the input time ---------------------------------------------------------------------
  if keyword_set(time) then begin
    if strlen(time) ne 19 and strlen(time) ne 8 then  begin &  doc_library, 'mvn_lpw_prd_lp_sweep_plot' & retall & end
    if strlen(time) eq 8 then begin
      date = time_string(T0(0)) & date = strmid(date,0,11) & time = date+time
    endif
    time = time_double(time)    
  endif  
;--------------------------------------------------------------------------------------------------

;----- For giving PP set, define sweep time -------------------------------------------------------
  if keyword_set(PP) then begin
    if keyword_set(time) then begin
      if size(PP,/type) eq 11 then begin
        ttag = []
        for jj=0,n_elements(PP)-1 do ttag = [ttag, PP(jj).time]
      endif else begin
        ttag = PP.time
      endelse
      t_pp = where(ttag ge time)
      if (n_elements(t_pp) eq 1) then if(t_pp lt 0) then begin & print, 'No mached time.' & return &  endif
      t_pp = t_pp(0)
      PP_out = PP(t_pp)      
    endif else begin
      PP_out = PP
    endelse
    goto, jump1  ;--- plot parameters are ready to plot ----------------
  endif  
;--------------------------------------------------------------------------------------------------

;----- get sweep dataset from tplot value ---------------------------------------------------------
  get_data,tnameV,data=data_V,limit=limit_V,dlimit=dlimit_V
  get_data,tnameI,data=data_I,limit=limit_I,dlimit=dlimit_I
  T0 = data_V.x & V0 = data_V.y & I0 = data_I.y
  
;--- Split lp_data into sweep blocks --------------------------------------------------------------
  p_et = where(ts_diff(T0,1) lt -1.0)
  p_st = [0, p_et+1] & p_et = [p_et, n_elements(T0)-1]
  blk_no = n_elements(p_st)
;--------------------------------------------------------------------------------------------------

;----- pick up sweep set for input time, setup sweep dataset --------------------------------------  
  T = T0(p_st)
  ;pkt = where( T lt time) & pkt = pkt(n_elements(pkt)-1)
  pkt = where(T ge time and T le time+4.0)
  swp_t = T0(p_st(pkt):p_et(pkt)) & swp_u = V0(p_st(pkt):p_et(pkt)) & swp_i = I0(p_st(pkt):p_et(pkt))  

  ;PP = mm_swp_setupparam(dlimit_V)
  PP = mvn_lpw_prd_lp_swp_setupparam('')
  PP.time = swp_t(0) & PP.voltage = swp_u & PP.current = swp_i
  PP.ptitle = time_string(swp_t(0))+'-'+strmid(time_string(swp_t(n_elements(swp_t)-1)),11,18)+' prb'+prb_char
  PP.xlim = [min(swp_u),max(swp_u)]
  
  if prb eq 12 then begin
    get_data,'mvn_lpw_swp2_I2_pot',data=data_V,limit=limit_V,dlimit=dlimit_V
    get_data,'mvn_lpw_swp2_I2',    data=data_I,limit=limit_I,dlimit=dlimit_I
    T0 = data_V.x & V0 = data_V.y & I0 = data_I.y
    ;--- Split lp_data into sweep blocks ----------------------------------------------------------
    p_et = where(ts_diff(T0,1) lt -1.0)
    p_st = [0, p_et+1] & p_et = [p_et, n_elements(T0)-1]
    blk_no = n_elements(p_st)
    ;----------------------------------------------------------------------------------------------
    ;----- pick up sweep set for input time, setup sweep dataset ----------------------------------
    T = T0(p_st)
    ;pkt = where( T lt time) & pkt = pkt(n_elements(pkt)-1)

    pkt = where(T gt pp.time and T le pp.time+4.0)
    if pkt ne -1 then begin
      swp_t = T0(p_st(pkt):p_et(pkt)) & swp_u = V0(p_st(pkt):p_et(pkt)) & swp_i = I0(p_st(pkt):p_et(pkt))
      PP.voltage_l0 = swp_u & PP.current_l0 = swp_i
      
      pp.Ii_ind = abs(interpol(pp.current_l0, pp.voltage_l0,pp.voltage) - pp.current)
      prb12 = 1      
    endif
    
  endif else prb12 = 0
  
 PP_out = PP
;--------------------------------------------------------------------------------------------------
jump1:

  info = []
  if keyword_set(print_info) then begin
     if where(tag_names(pp_out) eq 'ANC') ne -1 then begin
       info = [info, 'Altitude: '+string(pp_out.anc.MSO_POS.alt,format='(F9.2)')]
       info = [info, 'BOOM_RAM_ANG: '+string(pp_out.anc.BOOM_RAM_ANG,format='(F6.2)')]
       info = [info, 'BOOM_SUN_ANG: '+string(pp_out.anc.BOOM_SUN_ANG,format='(F6.2)')]      
     endif     
  endif  
  if where(tag_names(pp_out) eq 'REE') ne -1 then pp_out = convertstruc_ree2mm(pp_out)
  if keyword_set(print_info) then begin
    info = [info, 'U0,1,2    [V]: '+strjoin(string([pp_out.U0,pp_out.U1,pp_out.U2],format='(F5.2)'),', ')]
    info = [info, 'Ne1,2,3 [/cc]: '+strjoin(string([pp_out.Ne1,pp_out.Ne2,pp_out.Ne3],format='(E9.2)'),', ')]
    info = [info, 'Te1,2,3  [eV]: '+strjoin(string([pp_out.Te1,pp_out.Te2,pp_out.Te3],format='(E9.2)'),', ')]    
  endif


;----- open plot window to check sweeps and fitting results ---------------------------------------
;  if strmatch(size(win,/tname),'UNDEFINED') then begin
;    window, /free & win = !d.window
;    print, '*********************************************************************'
;    print, '***** Adjust the plot window and continue. (.continue if ready) *****'
;    print, '*********************************************************************'
;    stop
;  endif
;--------------------------------------------------------------------------------------------------
  win2 = !d.window
  if keyword_set(xlim) then if finite(xlim(0)) then PP_out.xlim = xlim
  if keyword_set(nlog) eq 0 then nlog=0  
  
  if win2 eq -1 then dummy = plot_res(PP_out,win=win2,Ie_ind=Ie_ind,Ii_ind=Ii_ind,Iion2=Iion2,ylim=ylim,nlog=nlog,prb12=prb12,info=info) else $
  if keyword_set(win) ne 0 then dummy = plot_res(PP_out,win=win,Ie_ind=Ie_ind,Ii_ind=Ii_ind,Iion2=Iion2,ylim=ylim,nlog=nlog,prb12=prb12,info=info) else $
  dummy = plot_res(PP_out,win=!d.window,Ie_ind=Ie_ind,Ii_ind=Ii_ind,Iion2=Iion2,ylim=ylim,nlog=nlog,prb12=prb12,info=info)

  ;dummy = plot_res(PP_out,win=win)


  if keyword_set(silent) ne 1 then help, PP_out
  print, time_string(PP_out.time)
end
;##################################################################################################
