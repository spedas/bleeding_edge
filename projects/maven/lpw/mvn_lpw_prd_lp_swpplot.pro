;+
;;PROCEDURE: mvn_lpw_prd_lp_swpplot
; Standard plot for Langmuir Probe sweeps. Displays V-I curve of liner, logalithmic, and derivertive.
;
;;INPUT:
; sweep_data: list of structured sweep data. To plot mvn lpw data, use 'mvn_lpw_swpextracr'
;             data structure must contain 'U' as voltage and 'I' as current
;
;KEYWORDS:
;
;;CREATED BY:  Michiko W. Morooka Apr. 2014
;FILE      : mvn_lpw_prd_lp_make_l0filelist.pro
;VERSION:   0.0
;LAST MODIFICATION:   04/18/14
;
;-


pro mvn_lpw_prd_lp_swpplot, sweep_data, txt=txt, col=col, U_zero=U_zero, win=win, title_txt=title_txt, limy=limy, limx=limx, limdy=limdy
  ;--------------------- Constants ------------------------------------
  t_routine=SYSTIME(0)
  pdr_ver= 'pdr_ver 0.0'
  ;--------------------

  if ~keyword_set(txt) then txt = list('line 1','line 2','line 3','line 4','line 5')
  if ~keyword_set(col) then col = list('black','blue','green','red','Cyan','Magenta','black')

  if ~keyword_set(title_txt) then begin
    if keyword_set(time) then begin
      title_txt = 'MAVEN LPW ' + time_string(time)
    endif else title_txt = 'LP SWEEP'
  endif

  if not keyword_set(win) then win = 4
  ;print, win
  ; ===== window set up =====
  WINDOW, win, XSIZE=600, YSIZE=700, TITLE=title_txt
  !P.MULTI = [0, 1, 3]
  !p.background = 255
  !p.color = 0
  !p.charsize=2
  !p.font=0

  ; ===== plot set up =====
  ; Make a vector of 16 points, A[i] = 2pi/16:
  A = FINDGEN(17) * (!PI*2/16.)
  ; Define the symbol to be a unit circle with 16 points,
  ; and set the filled flag:
  USERSYM, 0.5*COS(A), 0.5*SIN(A), /FILL

  n_plot = size(sweep_data,/n_elements)-1

  ; ===== Define ploting limiys =====
  ; ----- define xlim           -----
  if ~keyword_set(limx) then begin
    if strcmp(typename(sweep_data),'LIST') then begin
      limx = [0.0, 0.0]
      for ii=0,n_plot do begin
        limx[0] = min([limx[0], min(sweep_data[ii].U) ])
        limx[1] = max([limx[1], max(sweep_data[ii].U) ])
      endfor
    endif else begin
      limx  = [min(sweep_data.U), max(sweep_data.U)]
    endelse
  endif
  ; ----- define ylim           -----
  if ~keyword_set(limy) then begin
    if strcmp(typename(sweep_data),'LIST') then begin
      limy = [0, 0, 1e-5]
      for ii=0,n_plot do begin
        limy[0] = min([limy[0], min(sweep_data[ii].I) ])
        limy[1] = 1.005*max([limy[1], max(sweep_data[ii].I) ])
        limy[2] = min([limy[2], min(abs(sweep_data[ii].I))])
      endfor
    endif else begin
      limy  = [min(sweep_data.I), max(sweep_data.I), min(abs(sweep_data.I))]
    endelse
  endif
  ; ----- define dylim          -----
  if ~keyword_set(limdy) then begin
    if strcmp(typename(sweep_data),'LIST') then begin
      limdy = [0.0,0.0]
      for ii=0,n_plot do begin
        limdy[0] = min([limdy[0], min(deriv(sweep_data[ii].U, sweep_data[ii].I))])
        limdy[1] = max([limdy[1], max(deriv(sweep_data[ii].U, sweep_data[ii].I))])
      endfor
    endif else begin
      limdy = [min(deriv(sweep_data.U, sweep_data.I)), max(deriv(sweep_data.U, sweep_data.I)) ]
    endelse
  endif

  ;print, limx, limy, limdy

  ; ===== LINEAR PLOT =====
  for ii=0,n_plot do begin
    if ii eq 0 then begin
      plot,sweep_data[ii].U,sweep_data[ii].I,psym=8, color=fsc_color(col[ii]), LINESTYLE=1, $
        XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1, XRange=limx,YRange=limy([0,1]), $
        ytitle='Current [A]'
    endif else $
      oplot, sweep_data[ii].U,sweep_data[ii].I,psym=8, LINESTYLE=1, color=fsc_color(col[ii])
    oplot, sweep_data[ii].U, sweep_data[ii].I, color=fsc_color(col[ii])
  endfor

  ; ===== LOG PLOT =====
  for ii=0,n_plot do begin
    if ii eq 0 then begin
      plot,sweep_data[ii].U,abs(sweep_data[ii].I),psym=8, color=fsc_color(col[ii]), LINESTYLE=1, $
        XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1, XRange=limx, YRange=limy([2,1]), $
        ytitle='Current [A]', /ylog
    endif else $
      oplot, sweep_data[ii].U, abs(sweep_data[ii].I), psym=8, LINESTYLE=1, color=fsc_color(col[ii])
    oplot, sweep_data[ii].U, abs(sweep_data[ii].I), color=fsc_color(col[ii])
  endfor

  ; ===== DeRIVERTIVE PLOT =====
  for ii=0,n_plot do begin
    if ii eq 0 then begin
      plot,sweep_data[ii].U, deriv(sweep_data[ii].U, sweep_data[ii].I),psym=8, color=fsc_color(col[ii]), LINESTYLE=1, $
        XTickLen=1, XGridStyle=1, YTickLen=1, YGridStyle=1, XRange=limx, yrange=limdy, $
        ytitle='Current derivertive [A/V]'
    endif else $
      oplot, sweep_data[ii].U, deriv(sweep_data[ii].U, sweep_data[ii].I), color=fsc_color(col[ii]), psym=8, LINESTYLE=1
    oplot, sweep_data[ii].U, deriv(sweep_data[ii].U, sweep_data[ii].I), color=fsc_color(col[ii])
  endfor

  !p.multi=0
end