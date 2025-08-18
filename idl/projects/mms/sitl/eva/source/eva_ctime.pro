;#######################################
; This is a modified version of 'ctime'. 
;#######################################
; 
; CTIME enables a user to pick one or more time point.
; 
; EVA_CTIME was created because of the following reasons. 
; 1. To execute user-specified routine after selection of each time point.
; 2. The original CTIME can also do #1 by using the ROUTINE_NAME keyword, 
;    but, in some cases, EVA needs to select one or more time intervals and 
;    to execute a routine after every selectin of the time intervals 
;    (i.e. The routine needs to be executed after two left-clicks rather than 
;    just one-click).
; 3. Perhaps, #2 can still be done by calling "CTIME,/npoints=2' multiple times.
;    But, in this case, the program needs to know when the user finishes 
;    selecting all time intervals. But CTIME would be called from EVA (cw_sitl.pro) 
;    whereas the user's button state would be detected by XTPLOT or by direct graphics.
;    Implementation of such detection is relatively complicated.
; Therefore, 'eva_ctime_exclusive' and some keywords are added to CTIME and
; the entire procedure is now renamed as EVA_CTIME. 
; 
; With EVA_CTIME, everytime a time interval is selected, an external procedure
; specified by "routine_name" keyword will be called.
; This external procedure takes the following inputs:
;   trange: two-element array containing start & end time of the segment
;   var: variable name (keyword) 
;   state: structure (keyword)
; Note that the routine_name and state are passed on as input to eva_ctime.

PRO eva_ctime_exclusive, var, t, flag, buf, state, routine_name,occur
  case occur of
    1: begin
      print, 'EVA: calling '+routine_name
      call_procedure,routine_name, t, state=state, var=var
      end
    2: begin
      if flag>0 then begin
        buf     = t
        print, 'EVA: segment start time = '+ time_string(buf)
      endif else begin
        print, 'EVA: segment end   time = ', time_string(t)
        trange = [buf,t]
        print, 'EVA: segment selected --> calling '+routine_name
        call_procedure,routine_name, trange, state=state, var=var
        buf   = -1
        print, 'EVA: segment selected --> '+routine_name+' done'
      end
      flag *= -1      
      end
    else:
  endcase

END

pro eva_ctime_get_exact_data,var,v,t,pan,hx,hy,subvar,yind,yind2,z,$
         spec=spec,dtype=dtype,load=load
;
;NAME:
;   eva_ctime_get_exact_data
;PROCEDURE:     eva_ctime_get_exact_data
;PURPOSE:       Get a data structure for ctime.  if var is a string or a strarr,
;               create a structure of data structures.
;               Get the new values for hx and hy, the crosshairs position.
;               Also check the spec option.
;               ctime need never see the actual data structures.
;     All work is done with pointers to reduce data duplication
;               and increase speed.
;COMMON BLOCKS: CTIME_COMMON
;HISTORY:       First appeared in ctime version 1.29
;
@tplot_com
common eva_ctime_common, ptr        ;this should NOT appear in eva_ctime, it is local
;if dtype eq 1 then ptr is a struct of pointers containing the values:
;x = *ptr.x, y = *ptr.y, (v = *ptr.v)
;if dtype eq 3 then ptr is more complex:
;say data='Np Ne':  get_data,'Np',ptr=np_ptr & get_data,'Ne',ptr=ne_ptr
;ptr={n:2,d1:{x:np_ptr.x,y:np_ptr.y,name:'Np'},$
;         d2:{x:ne_ptr.x,y:ne_ptr.y,name:'Ne'}}

  time_scale  = tplot_vars.settings.time_scale
  time_offset = tplot_vars.settings.time_offset
  ytype       = tplot_vars.settings.y[pan].type

  ;if this is a new panel, load the data
  if keyword_set(load) then begin
    get_data,var,dtype=dtype,alim=alim,ptr=ptr
    spec = 0 & str_element,alim,'spec',spec
    case dtype of
      1:  begin
      endcase
      2:  begin   ;note that if dtype eq 2 eva_ctime_get_exact_data does nothing
      endcase     ;ie:  eva_ctime bahaves as if exact eq 0
      3:  begin
        get_data,var,data=var_str
        if ndimen(var_str) eq 0 then var_str = str_sep(strcompress(var_str),' ')
        nd2 = n_elements(var_str)
        ptr = {n:nd2}
        for i=0,nd2-1 do begin
          get_data,var_str[i],ptr=subptr,dtype=subdtype,alim=subalim
          str_element,alim,'spec',subspec
          if not keyword_set(subspec) then subspec = 0
          if subdtype ne 1 then ptr.n = ptr.n-1 $ ;too limiting...
          else begin
            tag = 'd'+strtrim(i,2)
            str_element,/add,subptr,'spec',subspec    ;add spec to substruct
            str_element,/add,subptr,'name',var_str[i] ;add var name to substruct
            str_element,/add,ptr,tag,subptr           ;add substruct to struct
          endelse
        endfor
      endcase
      else:  dprint, 'Invalid value for dtype: ',dtype
    endcase
  endif

  ;get the new values for: v,t,z,yind2,hx,hy,subvar
  yind2 = -1
  subvar = ''
  yind = 0l                       ;zero the time index
  case dtype of                   ;what type of tplot var do we have?
    1: begin
      dt = abs(*ptr.x-t)              ;find the closeva data.x to t
      mini = min(dt,yind,/nan)             ;get the index of the min dt
      t = (*ptr.x)[yind]
      tags = tag_names(ptr)
      wy = where(tags EQ 'Y')
      wv = where(tags EQ 'V')
      if not spec then begin
        if dimen2(*ptr.y) gt 1 then begin ;if y 2D, get nearest line
          if finite(v) then begin
            if ytype eq 0 then dy = abs((*ptr.y)[yind,*]-v) $ ;lin scale plot
            else dy = abs(alog((*ptr.y)[yind,*])-alog(v))     ;log scale plot
            mini = min(dy,yind2,/nan)             ;get index of nearest y
            v = float((*ptr.y)[yind,yind2])
          endif
        endif else v = float((*ptr.y)[yind])
      endif else begin                ;this is a specplot
        if finite(v) then begin
          if dimen2(*ptr.v) eq 1 then vr = *ptr.v $
          else vr = reform((*ptr.v)[yind,*])
          if ytype eq 0 then mini = min(abs(vr-v),yind2,/nan) $ ;lin scale plot
          else mini = min(abs(alog(vr)-alog(v)),yind2,/nan)     ;log scale plot
          v = float(vr[yind2])
          z = float((*ptr.y)[yind,yind2])
        endif
      endelse
      t_scale = (t-time_offset)/time_scale
      hx = data_to_normal(t_scale,tplot_vars.settings.x)
      hy = data_to_normal(v,      tplot_vars.settings.y[pan])
    endcase
    2: begin                        ;not written yet
    endcase
    3: begin                        ;var is a string or strarr of vars
      yinds = lonarr(ptr.n)
      t2    = dblarr(ptr.n)
      v2    = fltarr(ptr.n)+v        ;important for when v is NaN
      for i=0,ptr.n-1 do begin       ;find the substr with the nearest time
        mini = min(abs(*ptr.(i+1).x-t),yind,/nan)
        yinds[i] = yind
        t2[i] = (*ptr.(i+1).x)[yind]
      endfor
      dt  = abs(t2-t)
      sdt = sort(dt)
      w = where(dt eq dt[sdt[0]],wc)  ;see if several have the same minimum dt

      if finite(v) then begin
        if wc eq 1 then begin           ;if one substr to consider...
          j = sdt[0] & yind = yinds[j]
          if dimen2(*ptr.(j+1).y) gt 1 then begin ;if y 2D, get nearest line
            if ytype eq 0 then dy = abs((*ptr.(j+1).y)[yind,*]-v) $ ;lin scale y
            else dy = abs(alog((*ptr.(j+1).y)[yind,*])-alog(v))     ;log scale y
            mini = min(dy,yind2,/nan)             ;get index of nearest y
            v2[j] = (*ptr.(j+1).y)[yind,yind2]
          endif else v2[j] = (*ptr.(j+1).y)[yind]
        endif else begin                ;if multiple substrs to consider...
          j = w[0]
          y  = ((*ptr.(j+1).y)[yinds[j],*])[*] ;[*] works better than REFORM
          if ytype eq 0 then dy = abs(y-v) else dy = abs(alog(y)-alog(v))
          mini = min(dy,yind2,/nan)
          for i=1,wc-1 do begin
            y2  = ((*ptr.(w[i]+1).y)[yinds[w[i]],*])[*]
            if ytype eq 0 then dy = abs(y2-v) else dy = abs(alog(y2)-alog(v))
            mini2 = min(dy,yind22,/nan)
            if mini2 lt mini then begin
              j = w[i] & mini = mini2 & yind2 = yind22
            end
          endfor
          v2[j] = (*ptr.(j+1).y)[yinds[j],yind2]
          if dimen2(*ptr.(j+1).y) eq 1 then yind2 = -1
        endelse
      endif else j = sdt[0]
      t = t2[j]
      v = float(v2[j])
      subvar = ptr.(j+1).name
      t_scale = (t-time_offset)/time_scale
      hx = data_to_normal(t_scale,tplot_vars.settings.x)
      hy = data_to_normal(v,      tplot_vars.settings.y[pan])
    endcase
    else: dprint, 'Invalid value for dtype: ',dtype
  endcase
  yind = long(yind)
  yind2 = fix(yind2)
end



function eva_time_round,time,res,precision=prec,$  ; res must be a scalar!
   days    = days   ,$       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   hours   = hours  ,$       ; Keywords for setting time granularity.
   minutes = minutes,$       ;
   seconds = seconds         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

res=abs(res[0])

prec=6
if res eq 0 then return,time  ; don't round

res0= [0,[1,2,5,10,20,30,60]*1d,[2,5,10,20,30,60]*60d,[2,4,6,12,24]*3600d]
prc0=-[0, 0,0,0, 0, 0, 0, 1,     1,1, 1, 1, 1, 2,      2,2,2, 2, 3]
n = n_elements(res0)
resn = floor(interp(findgen(n),res0,res))

if resn  le 0 then begin
  prec = -floor(alog10(res*1.0001d)) < 10
  res = 10d^(-prec)
endif else begin
  res  = res0[resn < (n-1)]
  prec = prc0[resn < (n-1)]
endelse

if keyword_set(days)    then res = days*86400.d
if keyword_set(hours)   then res = hours*3600.d
if keyword_set(minutes) then res = minutes*60.d
if keyword_set(seconds) then res = seconds*1.d

rtime = time_double(time)

if res ge 1 then return, res * round(rtime/res)
time0 = round(time)
return, time0 + res * round((rtime-time0)/res)

end



;+
;PROCEDURE:   eva_ctime,time,y,z
;INPUT:
;    time: Named variable in which to return the selected time (seconds
;          since 1970)
;    y:    Named variable in which to return the y value
;    z:    Named variable in which to return the z value
;KEYWORDS:
;    PROMPT:  Optional prompt string
;    NPOINTS: Max number of points to return
;    PSYM:    If set to a psym number, the cooresponding psym is plotted at
;             selected points
;    SILENT:  Do not print data point information
;    PANEL:   Set to a named variable to return an array of tplot panel numbers
;             coresponding to the variables points were chosen from.
;    XNORM:   Set to a named variable to return an array of normalized x
;             coordinates of each button-click.
;    YNORM:   Set to a named variable to return an array of normalized y
;             coordinates of each button-click.
;    APPEND:  If set, points are appended to the input arrays,
;             instead of overwriting the old values.
;    VNAME:   Set to a named variable to return an array of tplot variable names,
;             cooresponding to the variables points were chosen from.
;    COLOR:   An alternative color for the crosshairs.  0<=color<=!d.n_colors-1
;    SLEEP:   Sleep time (seconds) between polling the cursor for events.
;             Defaults to 0.1 seconds.  Increasing SLEEP will slow eva_ctime down,
;             but will prevent eva_ctime from monopolizing cpu time.
;    INDS:    Return the indices into the data arrays for the points nearest the
;             recorded times to this named variable.
;    VINDS:   Return the second dimension of the v or y array.
;             Thus  TIME(i) is  data.x(INDS(i))           and
;                   Y(i)    is  data.y(INDS(i),VINDS(i))  and
;                   V(i)    is  data.v(VINDS(i)) or data.v(INDS(i),VINDS(i))
;             for get_data,VNAME(i),data=data,INDS=INDS,VINDS=VINDS
;    EXACT:   Get the time,y, and (if applicable) z values from the data
;             arrays.  If on a multi-line plot, get the value from the line
;             closest to the cursor along y.
;    NOSHOW:  Do not show the plot window.
;    DEBUG:   Avoids default error handling.  Useful for debugging.
;    DAYS, HOURS, MINUTES, SECONDS: Sets time granularity.  For example
;             with MINUTES=1, eva_ctime will find nearest minute to cursor
;             position.
;PURPOSE:
;   Interactively uses the cursor to select a time (or times)
;NOTES:       If you use the keyword EXACT, eva_ctime may run noticeablly slower.
;         Reduce the number of time you cross panels, especially with
;         tplots of large data sets.
;SEE ALSO:  "crosshairs"
;
;CREATED BY:    Davin Larson & Frank Marcoline
;LAST MODIFICATION:     @(#)eva_ctime.pro   1.44 02/11/01
;WARNING!
;  If eva_ctime crashes, you may need to call:
;  IDL> device,set_graph=3,/cursor_crosshair
;-
pro eva_ctime,time,value,zvalue,$
   append  = append ,$       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   exact   = exact  ,$       ;
   npoints = npoints,$       ; Keywords for setting eva_ctime mode and
   inds    = inds   ,$       ; for returning data.
   vinds   = inds2  ,$       ;
   panel   = panel  ,$       ;
   ynorm   = ynorm  ,$       ; added by JBT
   xnorm   = xnorm  ,$       ; added by JBT
   routine_name = routine_name,  $         ; this routine is called everytime the curser is updated.
   cut  = cut       ,$                     ; Shortcut to:  eva_ctime,routine_name='tplot_cut'
   counts  = n   ,$     ;
   vname   = vname  ,$       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   prompt  = prompt ,$       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   local_time=local_time, $  ;  Displays local time instead of UTC
   psym    = psym   ,$       ;
   silent  = silent ,$       ; Less common keywords for affecting
   noshow  = noshow ,$       ; eva_ctime mode, graphics and text output.
   debug   = debug  ,$       ;
   color   = color  ,$       ;
   sleep   = sleep  ,$       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   days    = days   ,$       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   hours   = hours  ,$       ; Keywords for setting time granularity.
   minutes = minutes,$       ;
   seconds = seconds,$         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   state   = state, $
   occur   = occur

@tplot_com.pro

;===================
flag = 1
buf  = 'dummy'
seconds = 1
if ~keyword_set(occur) then occur = 2 
;====================

wndw = struct_value(tplot_vars,'settings.window',default=-1)
if wndw eq -1  then begin
    dprint,dlevel=0,'Tplot has not yet been initialized!,  Returning.'
    return
endif
tplot_d = tplot_vars.settings.d
tplot_x = tplot_vars.settings.x
tplot_y = tplot_vars.settings.y
time_scale  = tplot_vars.settings.time_scale
time_offset = tplot_vars.settings.time_offset
tplot_var   = tplot_vars.options.varnames
if keyword_set(cut) then routine_name='tplot_cut'

;;;;;; make sure we have the correct window
flags = 256+128+16+8
if (!d.flags and flags) ne flags then begin
  m='Current device ('+!d.name+') does not support enough features.  See !d.flags'
  dprint,m
  return
endif
if tplot_d.name ne !d.name then begin
  dprint,'Device has changed from "'+tplot_d.name+'" to "'+!d.name+'" since the Last TPLOT.'
  return
endif
current_window = !d.window
wset, tplot_vars.settings.window
if tplot_d.x_size ne !d.x_size or tplot_d.y_size ne !d.y_size then begin
  wset,current_window
  dprint,'TPLOT window has been resized!'
  return
endif
if not keyword_set(noshow) then wshow ;,icon=0 ;open the window
;;;;;;


;;;;;; check keywords and set defaults
if size(/type,sleep) eq 0    then sleep  = 0.01 ;if not set: 0.01, if set 0: 0
if not keyword_set(exact)   then exact  = 0    else exact  = 1
if not keyword_set(npoints) then max    = 2000 else max    = npoints > 1
if not keyword_set(silent)  then silent = 0
if not silent then begin
  if size(/type,prompt) ne 7 then $
    prompt='Use button 1 to select time, 2 to erase time, and 3 to quit.'
  prompt2 = ' point         name:             date/time              yvalue'
  if exact then begin
    strput,prompt2,'comp',21
    prompt2=prompt2+'        (zvalue)'
  end
  print,prompt,prompt2,format='(a)'
endif
;;;;;;

;;;;;; set graphics function, move cursor to screen, and plot original crosshairs
;the graphics function is set to (bitwise) "xor" rather than standard "copy"
;((a xor b) xor b) = a,  lets call your plot "a" and the crosshairs "b"
;plot "a", set the graphics function to "xor", and plot "b" twice and you get "a"
;this way we don't damage your plot
device, get_graphics = old, set_graphics = 6   ;Set xor graphics function
if not keyword_set(color) then color = !d.n_colors-1 $
else color = (color > 0) < (!d.n_colors-1)
px = 0.5                        ;Pointer (cursor) x and y positions
py = 0.5
hx = 0.5                        ;crossHairs       x and y positions
hy = 0.5
;when cursor,x,y,/dev is called and the cursor is off of the plot, (x,y)=(-1,-1)
cursor,testx,testy,/dev,/nowait               ;find current cursor location
if (testx eq -1) and (testy eq -1) then begin ;if cursor not on current window
  tvcrs,px,py,/norm                             ;move cursor to middle of window
endif else begin                              ;cursor is on window.
  pxpypz = convert_coord(testx,testy,/dev,/to_norm) ;find normal coords
  px = pxpypz[0]
  py = pxpypz[1]
  hx = px
  hy = py
endelse
plots,[0,1],[hy,hy], color=color,/norm,/thick,lines=0
plots,[hx,hx],[0,1], color=color,/norm,/thick,lines=0
opx = px                        ;store values for later comparison
opy = py
ohx = hx                        ;store values for later crossHairs deletion
ohy = hy
;if EXACT set, px & py will differ from hx & hy, else they will be the same
;use p{x,y} when working with pointer and h{x,y} when working with crosshairs
;;;;;;


;;;;;; set up output formats
spaces = '                 '    ;wipes out z output from form5 and form6
if !d.name eq 'X' or 1 then begin
  cr = string(13b)                ;a carriage return (no new line)
  form1 = "(4x,a15,': ',6x,a19,x,g10.4,a,a,$)"         ;transient output line
  form2 = "(4x,a15,': [',i2,']  ',a19,x,g10.4,a,a,$)"  ;transient output line, EXACT
  form3 = "(i4,a15,': ',6x,a19,x,g10.4,a)"             ;recorded point output line
  form4 = "(i4,a15,': [',i2,']  ',a19,x,g10.4,a)"      ;recorded point output, EXACT
  form5 = "(4x,a15,': [',i2,']  ',a19,x,g10.4,x,g,a,$)";transient, EXACT, SPEC
  form6 = "(i4,a15,': [',i2,']  ',a19,x,g10.4,x,g)"    ;recorded,  EXACT, SPEC
endif else begin                ;these are for compatibility with MS-Windows
  cr = ''
  form1 = "(4x,a15,': ',6x,a19,x,g,a,a,TL79,$)"    ;same as above six formats
  form2 = "(4x,a15,': (',i2,')  ',a19,x,g,a,a,TL79,$)"
  form3 = "(i4,a15,': ',6x,a19,x,g,a)"
  form4 = "(i4,a15,': (',i2,')  ',a19,x,g,a)"
  form5 = "(4x,a15,': (',i2,')  ',a19,x,g,x,g,a,TL79,$)"
  form6 = "(i4,a15,': (',i2,')  ',a19,x,g,x,g)"
endelse
;;;;;;


;;;;;; get and print initial position and panel in tplot data coordinates
pan = where(py ge tplot_y[*].window[0] and py le tplot_y[*].window[1])
pan = pan[0]
t =  normal_to_data(px,tplot_x) * time_scale + time_offset
if pan ge 0 and pan lt n_elements(tplot_var) then begin
  v =  normal_to_data(py,tplot_y[pan])
  var = tplot_var[pan]
endif else begin
  v =  !values.f_nan
  var = 'Null'
endelse
print,form=form1,var,time_string(t,prec=prec,local_time=local_time),float(v),cr
;;;;;;

;;;;;; create an error handling routine
if not keyword_set(debug) then begin
  catch,myerror
  if myerror ne 0 then begin      ;begin error handler
    plots,[0,1],[ohy,ohy], color=color,/norm,/thick,lines=0 ;erase crosshairs
    plots,[hx,hx],[0,1],   color=color,/norm,/thick,lines=0
    print
    print,'Error: ',!error          ;report problem
    print,!err_string
    tvcrs,0                         ;turn off cursor
    device,set_graphics=old         ;restore old graphics state
    wset,current_window             ;restore old window
    return                          ;exit on error
  endif
endif                           ;end error handler
;;;;;;


;;;;;; set the initial values for internal and output variables
button=0
if not keyword_set(append) then begin
  time = 0
  value = 0
  panel = 0
  vname = ''
  inds = 0
  inds2 = 0
  zvalue = 0
endif
n    =  0
ind  = -1
ind2 = -1
lastvalidvar = var              ;record previous data variable (not 'Null')
oldbutton    = 0                ;record last button pressed
if (exact ne 0) and (var ne 'Null') then $
  eva_ctime_get_exact_data,var,v,t,pan,hx,hy,subvar,ind,ind2,z,$
  spec=spec,dtype=dtype,/load
;;;;;;

;;;;;; here we are:  the main loop...
;------ begin JBT block ----
xnorm = make_array(max, value = !values.f_nan, /float)
ynorm = make_array(max, value = !values.f_nan, /float)
;------ end JBT block ----
while n lt max do begin
  ;the main loop calls cursor,
  ;which waits until there is a button press or cursor movement
  ;the old crosshairs are reploted (erased), the new crosshairs are ploted

  ;;;; get new position, update crosshairs
  cursor,px,py,/change,/norm    ;get the new position
  button = !MOUSE.BUTTON        ;get the new button state see help on CURSOR procedure
  ;------ begin JBT block ----
  xnorm[n] = px
  ynorm[n] = py
  ;------ end JBT block ----
  hx = px                       ;correct   assignments in the case of EXACT eq 0
  hy = py                       ;temporary assignments in the case of EXACT ne 0
  plots,[0,1],[ohy,ohy], color=color,/norm,/thick,lines=0 ;unplot old cross
  plots,[ohx,ohx],[0,1], color=color,/norm,/thick,lines=0
  if button eq 4 then goto,quit ;yikes! i used a goto!
  if exact eq 0 then begin
    plots,[0,1],[hy,hy], color=color,/norm,/thick,lines=0 ;plot new crosshairs
    plots,[hx,hx],[0,1], color=color,/norm,/thick,lines=0
  endif

  ;;;; Get new data values and crosshair positions from pointer position values,
  ;;;; if we are not deleting the last data point.
  if (opx ne px) or (opy ne py) or (button ne 2) then begin
    t =  normal_to_data(px,tplot_x) * time_scale + time_offset
    res = 1.d/tplot_x.s[1]/!d.x_size
    t = eva_time_round(t,res,days=days,hours=hours,minutes=minutes,seconds=seconds,prec=prec)
    pan = (where(py ge tplot_y[*].window[0] and py le tplot_y[*].window[1]))[0]
    if pan ge 0 and pan lt n_elements(tplot_var) then begin
      v =  normal_to_data(py,tplot_y[pan])
      var = tplot_var[pan]
    endif else begin
      v =  !values.f_nan
      var = 'Null'
    endelse
    ind2 = -1

;    if size(/type,routine_name) eq 7 then begin
;       device, set_graphics = old
;       wset,current_window
;       call_procedure,routine_name,var,t
;       wset, tplot_vars.settings.window
;       device, set_graphics = 6
;    endif



    if exact ne 0 then begin
      if var ne 'Null' then begin ;get data points
        load = var ne lastvalidvar
        eva_ctime_get_exact_data,var,v,t,pan,hx,hy,subvar,ind,ind2,z,$
          spec=spec,dtype=dtype,load=load
      endif
      plots,[0,1],[hy,hy], color=color,/norm,/thick,lines=0 ;plot new crosshairs
      plots,[hx,hx],[0,1], color=color,/norm,/thick,lines=0
    endif

    if not silent then begin    ;print the new data
      if keyword_set(subvar) then varn = var+"->"+subvar else varn = var
      tstr = time_string(t,prec=prec,local_time=local_time)
      if ind2 eq -1 then print,form=form1,varn,     tstr,v,spaces,cr $
      else if spec then  print,form=form5,varn,ind2,tstr,v,z     ,cr $
      else               print,form=form2,varn,ind2,tstr,v,spaces,cr
    endif
  endif
  ;;;; got the current data

  ;;;; if a button state changes, take action:
  if button ne oldbutton then begin
    case button of
      1: begin         ; LEFT BUTTON --> record the new data and print output line
        append_array,time,t
        append_array,value,v
        if keyword_set(spec  ) then append_array,zvalue,z $
        else                        append_array,zvalue,!values.f_nan
        if keyword_set(subvar) then append_array,vname,subvar $
        else                        append_array,vname,var
        append_array,panel,pan
        np = n_elements(time)
        append_array,inds,ind
        append_array,inds2,ind2 > 0     ;if ind2 eq -1 set to zero
        if not silent then begin
          if ind2 eq -1 then print,form=form3,np-1,varn,     tstr,v,spaces $
          else if spec then  print,form=form6,np-1,varn,ind2,tstr,v,z      $
          else               print,form=form4,np-1,varn,ind2,tstr,v,spaces
        endif
        if keyword_set(psym) then plots,t-time_offset,v,psym = psym

        ;====== EVA ======================================
        if (size(/type,routine_name) eq 7) then begin
          plots,[0,1],[hy,hy], color=color,/norm,/thick,lines=0 ; unplot new crosshairs
          plots,[hx,hx],[0,1], color=color,/norm,/thick,lines=0 ; temporarily
          
          device, set_graphics = 3;
          eva_ctime_exclusive,var, t,flag,buf,state,routine_name,occur; do something here
          device, set_graphics = 6; set graphics
          
          plots,[0,1],[hy,hy], color=color,/norm,/thick,lines=0 ; plot back new crosshairs
          plots,[hx,hx],[0,1], color=color,/norm,/thick,lines=0 ;            
        endif
        ;================================================

        n = n + 1
      end
      2: begin          ; MIDDLE BUTTON --> delete last data and print output line
        np = n_elements(time)
        if np ge 2 then begin
          time   = time[0:np-2]
          value  = value[0:np-2]
          vname  = vname[0:np-2]
          panel  = panel[0:np-2]
          inds   = inds[0:np-2]
          inds2  = inds2[0:np-2]
          zvalue = zvalue[0:np-2]
          if not silent then $
            print,form="(79x,a,TL79,'last sample (',i0,') deleted.')",cr,np-1
          n = n-1
        endif else if (np ne 0) and (time[0] ne 0) then begin
          time   = 0
          value  = 0
          panel  = 0
          vname  = ''
          inds   = 0
          inds2  = 0
          zvalue = 0
          if not silent then print,$
            form="(79x,a,TL79,'Zero sample (',i0,') set to zero.')",cr,np-1
          n = (n-1) > 0
        end
        
     end
      else:                     ;do nothing (if 4(=RIGHT BUTTON) then we exited already)
    endcase
  endif


  ;;;; store the current information, and pause (reduce interrupts on cpu)
  if var ne 'Null' then lastvalidvar = var
  oldpanel  = pan
  oldbutton = button
  opx = px
  opy = py
  ohx = hx
  ohy = hy
  dprint,dwait=5.,dlevel=1,'Use right button to exit'
  wait, sleep                   ;Be nice



endwhile ;;;;;; end main loop

;------ begin JBT block ----
tmp_ind = where(finite(xnorm), n_tmp_ind)
if n_tmp_ind gt 0 then xnorm = xnorm[tmp_ind] else xnorm = !values.f_nan
tmp_ind = where(finite(ynorm), n_tmp_ind)
if n_tmp_ind gt 0 then ynorm = ynorm[tmp_ind] else ynorm = !values.f_nan
;------ end JBT block ----

;;;;;; erase the crosshairs
plots,[0,1],[hy,hy], color=color,/norm,/thick,lines=0
plots,[hx,hx],[0,1], color=color,/norm,/thick,lines=0

;;;;;; return life to normal
quit:
print,cr,format='(79x,a,TL79,$)';clear the line
tvcrs                           ;turn off cursor
device,set_graphics=old         ;restore old graphics state
wset,current_window             ;restore old window

;if not keyword_set(noshow) then wshow

if n_elements(time) eq 1 then begin ;turn outputs into scalars
  time   = time[0]
  value  = value[0]
  panel  = panel[0]
  vname  = vname[0]
  inds   = inds[0]
  inds2  = inds2[0]
  zvalue = zvalue[0]
endif

return
END
