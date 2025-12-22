pro vel_disp_fit, $

   IONMASS=ionmass

;+  PROCEDURE:   vel_disp_fit
;
; This program assumes a multi-line tplot is already in an
; IDL window, and allows users to click on dispersive peaks
; and plots time offset vs inverse velocity.  The slope of the
; line is the source distance.  The program assumes field-aligned
; fluxes in its source distance calculation.
;
; INPUTS:  None
; OUTPUT: Produces plot of time offset vs inverse velocity
;
; KEYWORDS:
; IONMASS  if keyword not set, assumes electrons.  Otherwise, set to
;          m/q (in units of H+ m/q).
;          Set to
;          1 for H+
;          2 for He++
;          4 for He+
;          16 for O+
;
;  Written by Y-K Tung  96-11-29
;
;  Modification history:   97-5-7  Y-K Tung  added keyword IONMASS
;                          
;- 

; This first section loads a sample file, for testing purposes

;load_fa_k0_ees,filename='ee510.cdf',dir='~/fast/sdt/'
;tplot_names
;loadct,39
;tplot,[1,2,3]
;window,1
;options,[1,2,3],'yrange',[1e6,1e8]
;options,[1,2,3],'spec',0
;tplot,[1,2,3]

; Assumptions currently being made:
;  the xrange yrange are hard-wired into  offset vs invvelocity

moverq=9.1e-31
invvelrange=[0,1.6e-6]
symbolxcoord=[8e-7]
textxcoord=1e-6
if keyword_set(IONMASS) then begin
  moverq=ionmass*1.67e-27
  invvelrange=[0,6.8e-5]*sqrt(ionmass)
  symbolxcoord=[3.4e-5]*sqrt(ionmass)
  textxcoord=42.85e-6*sqrt(ionmass)
endif
window,2,ret=2
iter = 1
repeat begin
  exact=1
  inds=1
  vname=''
  ctime,a,b,inds=inds,exact=exact,vname=vname
  info=size(exact)
  length=info(1)     ;length contains the number of points clicked
  get_data,vname(0),data=mydata
  for i=0,length-1 do begin
    print,form="('Point #',i2,'   Time: ',a,'    Energy:  ',f10.3)",i,$
        time_to_str(mydata.x(inds(i))),mydata.v(inds(i),exact(i))
    if vname(i) ne vname(0) then begin
      endwidget=widget_base()
      endmessage=widget_message("You've clicked in"+ $ 
             " more than one plot. Exiting...")
      widget_control,endwidget,/realize
      widget_control,endwidget,/destroy
      return
    endif
  endfor
  velocity=sqrt(2d*mydata.v(inds,exact)*1.6e-19/moverq)
  starttime=min(mydata.x)
  offset=mydata.x(inds)-starttime
  if !d.window ne 2 then window,2,ret=2
  invvelocity=1/velocity
  plot,ytitle='offset (sec)',xtitle='1/velocity (s/m)',psym=iter,thick=0,$
     invvelocity,offset,/noerase,xrange=invvelrange,$
     yrange=[0,10000]
  lineparam=linfit(invvelocity,offset)
  dist=lineparam(1)   ; dist contains source distance (slope of line) in meters
; Find 2 points on the fitted line and then plot the fit
  x1=0
  y1=lineparam(0)
  x2=1.2*max(invvelocity)
  y2=y1+dist*x2
  plots, [x1,x2], [y1,y2]  ; plot fitted line
  plot,symbolxcoord,[8500-iter*500],/noerase,xrange=invvelrange,$
     psym=iter,yrange=[0,10000]    ; plot symbol used and fitted distance
  xyouts,textxcoord,8500-iter*500,'Set #'+strcompress(string(iter))+ $
     '   Distance (in m):'+ strcompress(string(dist))
; Query user whether to run program again, also check whether we've run
; out of plotting symbols (default is 7)
  if iter lt 7 then begin  
    askagain=widget_base(title='Again?')
    question=widget_label(askagain,value='Another set of points?',xoffset=10)
    yesanswer=widget_button(askagain,value='Yes',xoffset=40,yoffset=30)
    noanswer=widget_button(askagain,value='No',xoffset=90,yoffset=30)
    widget_control,askagain,/realize,xsize=150,ysize=60,tlb_set_xoffset=450,$
      tlb_set_yoffset=300
    event=widget_event(askagain)
    nomore = (event.id eq noanswer)
    widget_control,askagain,/destroy
    iter = iter + 1
  endif else begin
    endwidget=widget_base()
    endmessage=widget_message('Program has been run 7 times. Exiting...')
    widget_control,endwidget,/realize
    widget_control,endwidget,/destroy
    nomore=1
  endelse
endrep until nomore
end
