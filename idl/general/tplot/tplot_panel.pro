;+
;PROCEDURE: tplot_panel [,time,y]
;INPUTS: (optional)
;   time:      dblarr of time values associated with a variable to overplot
;	       in a designated "tplot" panel.
;   y:	       array of variable values to be plotted.
;KEYWORDS:
;   VARIABLE:  (string) name of previously plotted tplot variable.
;   OPLOTVAR:  Data that will be plotted on top of the selected panel
;   DELTATIME: Named variable in which time offset is returned.
;   PANEL:     Returns panel number of designated tplot variable.
;   PSYM:      Sets the IDL plot PSYM value for overplot data.
;PURPOSE:
;  Sets the graphics parameters to the specified tplot panel.
;  The time offset is returned through the optional keyword DELTATIME.
;
;LAST MODIFICATION:	@(#)tplot_panel.pro	1.9 02/04/17
;-

pro tplot_panel,time,y,panel=pan,deltatime=dt,variable=var,oplotvar=opvar , psym=psym

@tplot_com.pro

str_element,tplot_vars,'options.window',tplot_window
str_element,tplot_vars,'settings.x',tplot_x
str_element,tplot_vars,'settings.y',tplot_y
str_element,tplot_vars,'settings.clip',tplot_clip
str_element,tplot_vars,'settings.time_offset',time_offset
tplot_var= ''
str_element,tplot_vars,'options.varnames',tplot_var
;help
dt = 0.

if keyword_set(var) then begin
   i = where(tplot_var eq var,n)
   if n ne 0 then pan=i
endif

if n_elements(pan) eq 0 then begin
   dprint,dlevel=1,var+' Not plotted yet!'
   return
endif

ps = get_plot_state()
wi,tplot_window
!p.clip = tplot_clip[*,pan]
!x = tplot_x
!y = tplot_y[pan]
dt = time_offset

if n_params() eq 2 then  opvar = {x:time,y:y}

if keyword_set(opvar) then begin
   if size(/type,opvar) eq 7 then  get_data,opvar,data=d,alimi=l
   if size(/type,opvar) eq 8 then  d =opvar
   if size(/type,d) eq 8 then begin
      d.x = (d.x-time_offset)
      str_element,/add,l,'psym',psym
      mplot,data=d,limit=l,/overplot
   endif
endif
restore_plot_state,ps
end
