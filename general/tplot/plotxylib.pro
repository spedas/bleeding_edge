;+
;Procedure: plotxylib
;
;Purpose:  A library of helper functions for plotxy, plotxyz, and plotxyvec.  
;          To make the library available for a routine just call: plotxylib
;          That will force all the routines to be compiled.
;          
;          pxy_set_state sets the state of !TPLOTXY which keeps track
;          of windowing information for the plotxy* routines.  pxy_push_state
;          pushes arguments to these routines onto a data structure that allows
;          them to be replot without retyping the arguments.  pxy_replot will
;          replot a series of calls from memory.  pxy_get_pos will calculate
;          the position and shape of a window from the windowing information
;          in !TPLOTXY and the requested data ranges and margins for a window.
;          pxy_set_window is a routine that houses some redundant
;          initialization code. 
;          
;          SEE ALSO: plotxy,plotxyz,plotxyvec
;
; $LastChangedBy: lphilpott $
; $LastChangedDate: 2011-05-26 11:53:59 -0700 (Thu, 26 May 2011) $
; $LastChangedRevision: 8701 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/plotxylib.pro $
;
;-


;HELPER FUNCTION
;set window up, store windowing information
pro pxy_set_window,overplot,addpanel,replot,window,xsize,ysize,wtitle,multi,mmargin,mtitle,noisotropic,isotropic=isotropic

  compile_opt hidden,idl2

;if the window has not yet been generated or no more
;windows are available

  if ~keyword_set(overplot) && ~keyword_set(addpanel) && strlowcase(!D.name) ne 'ps' && strlowcase(!D.name) ne 'z' then begin
   
     if ~undefined(window) or keyword_set(xsize) or keyword_set(ysize) or keyword_set(wtitle) or !D.window eq -1 then begin

        device,window_state=wlist
        
        if ~undefined(window) then begin

          ;if the window doesn't really exist create it
           if window ge n_elements(wlist) || window lt 0 then $
              message,'You passed an out of range window value' $
           else if wlist[window] eq 0 then $
              window,window,xsize=640,ysize=512 $
           else $
              wset,window 
    
        endif else if !D.window eq -1 then begin
           window = 0
           xsize = 640
           ysize = 512
        endif else $
           window = !D.window

        if not keyword_set(xsize) then begin
           xs = !D.X_SIZE
        endif else begin
           xs = xsize
        endelse

        if not keyword_set(ysize) then begin
           ys = !D.Y_SIZE
        endif else begin
           ys = ysize
        endelse

        if not keyword_set(wtitle) then begin 
           wt = strcompress('IDL ' + string(window))
        endif else begin
           wt = wtitle
        endelse

        window,window,xsize=xs,ysize=ys,title=wt,retain=2

        
     endif 

  endif
  
     ;if this isn't a recursive call making use of the state information
   ;then we can safely reset the state information
   ;Moved outside of above if stmt so that multi works properly with postscript. May cause unforeseen bugs.
     if (~keyword_set(replot) and ~keyword_set(overplot) and ~keyword_set(addpanel)) then begin
      
        pxy_set_state,multi, mmargin, mtitle

     endif
  
  if ~keyword_set(multi) and (keyword_set(mtitle) or keyword_set(mmargin)) then begin
    dprint, 'Can only specify mtitle and mmargin when specifying multi. These arguments will be ignored.'
  endif

  if keyword_set(addpanel) then begin
     if keyword_set(multi) then begin
        message, 'Add and multi cannot be used in the same command.'
     endif
     !tplotxy.current++
  
  endif

  if ~keyword_set(noisotropic) then begin
     isotropic = 1
  endif else begin
     isotropic = 0
  endelse

end

;helper function, intializes the tplotxy system variable
pro pxy_set_state,multi, mmargin, mtitle

  compile_opt idl2,hidden

  plotlist = 0

  if keyword_set(multi) then begin

     args = strsplit(multi,' *[ ,/:;\.\\] *',/extract,/fold_case,/regex,count=c)

     if c ne 2 then begin
        message,'illegal multi string "' + multi + '"'
     endif

     if stregex(args[0],'r',/boolean) then begin
        revcols = 1
     endif else begin
        revcols = 0
     endelse

     if stregex(args[1],'r',/boolean) then begin
        revrows = 1
     endif else begin
        revrows = 0
     endelse

     cols = long(stregex(args[0],'[0-9]*',/extract))

     if cols eq 0 then begin
        message,'error parsing multi cols: "' + args[0] + '"'
     endif 

     rows = long(stregex(args[1],'[0-9]*',/extract))
     
     if cols eq 0 then begin
        message,'error parsing multi rows: "' + args[1] + '"'
     endif 
     
     panels = intarr(cols, rows)
     
     if keyword_set(mmargin) then begin
        if n_elements(mmargin) ne 4 then begin
          message,'malformed mmargin'
        endif
        if ~is_num(mmargin,/real) then begin
          message,'mmargin must contain real number'
        endif
        id = where(mmargin gt 1 or mmargin lt 0) 
        if id[0] ne -1 then begin
          message,'mmargin must be in the range [0,1]'
        endif
        if (((mmargin[0]+mmargin[2]) gt 1) or ((mmargin[1]+mmargin[3]) gt 1)) then begin
          message,'mmargin too big: no space left in window'
        endif
        margin = float(mmargin) 
     endif else begin
        margin = [.0,.0,.0,.0]
     endelse
     if keyword_set(mtitle) then begin
        title = mtitle
        if (margin[2] eq 0) then begin ;allow some space for the title if the user hasn't
          margin[2] = 0.05
        endif
     endif else begin
        title = ''
     endelse

  endif else begin
    
     revcols = 0
     revrows = 0
     cols = 1
     rows = 1
     margin = [.0,.0,.0,.0]
     title = ''
     panels = [0]
 
  endelse

  DEFSYSV,'!tplotxy',exists=bool

  ;free any old memory
  if bool && is_struct(*(!tplotxy.plotvec)) then begin
     
     plotvec = !tplotxy.plotvec

     t=csvector(*plotvec,/free)
     ptr_free,plotvec

  endif
  if bool && ptr_valid(!tplotxy.panels) then begin
     
     paneltemp = !tplotxy.panels
     ptr_free,paneltemp

  endif

  tplotxyval = { rows:rows,$
                 revrows:revrows,$
                 cols:cols,$
                 revcols:revcols,$
                 current:0,$ ;this doesn't record panels used, but rather where next panel should go automatically (counting from top left). Panels added with mpanel are not included in the count.
                 pos:dblarr(4),$ ;these values needed to properly overplot arrows
                 xrange:dblarr(2),$
                 yrange:dblarr(2),$
                 plotvec:ptr_new(csvector('start')),$
                 margin:margin,$
                 title:title,$
                 panels:ptr_new(panels)}


  DEFSYSV,'!tplotxy',tplotxyval

end


;adds the information to repeat the previous tplotxy call to the 
;tplotxy global variable
pro pxy_push_state,func_name,state,_extra=ex

  compile_opt idl2,hidden

  plotvec = *(!tplotxy.plotvec)

  ptr_free,!tplotxy.plotvec

  str_element,state,'ex',ex,/add

  func = {func:func_name,state:state}

  !tplotxy.plotvec = ptr_new(csvector(func,plotvec))

end

;determines the position of the current panel
;using the margin information and the tplotxy information
;assumes data is already logarithm'd, sorted, etc...

function pxy_get_pos,x,y,isotropic,xmargin,ymargin,mpanel

  compile_opt idl2,hidden

  ;validate inputs
  if keyword_set(xmargin) then begin

     if n_elements(xmargin) ne 2 then begin
        message,'malformed x margin'
     endif

     if ~is_num(xmargin,/real) then begin
        message,'x margin must contain real number'
     endif

     id = where(xmargin gt 1 or xmargin lt 0) 

     if id[0] ne -1 then begin
        message,'x margin must be in the range [0,1]'
     endif

  endif else begin

     xmargin = [.15,.17]

  endelse
              
  if keyword_set(ymargin) then begin

     if n_elements(ymargin) ne 2 then begin
        message,'malformed y margin'
     endif
     
     if ~is_num(ymargin,/real) then begin
        message,'y margin must contain real number'
     endif

     id = where(ymargin gt 1 or ymargin lt 0) 

     if id[0] ne -1 then begin
        message,'y margin must be in the range [0,1]'
     endif

  endif else begin

     ymargin = [.1,.075]

  endelse

  
  ;verify that the current panel is not too large
  temparr = where(*(!tplotxy.panels) eq 0, cnt)
  if ((!tplotxy.current ge (!tplotxy.rows * !tplotxy.cols)) or (cnt eq 0))then begin
     message,'no more panels available in current layout'
  endif

  xpanel_size = 1.0/!tplotxy.cols
  ypanel_size = 1.0/!tplotxy.rows

  ; Handle cases where the users wants to plot to a specific panel, or create a plot that takes up multiple panels
  ; NB: panels is an array that will match the layout you see on your screen (i.e [0,0] is top left),
  ; ypanel_cur is 0 for the bottom row rather than the top as coordinates are measured from bottom left.
  if keyword_set(mpanel) then begin
    !tplotxy.current-- ; current keeps track of the automatic order of panels. Calling with specific panel doesn't count.
    validarg = stregex(mpanel, '^(([0-9]+,)|([0-9]+:[0-9]+,))(([0-9]+)|([0-9]+:[0-9]+))$',/boolean)
    if ~validarg then begin
      message, 'mpanel must be in the form of a string x,y or x1:x2, y1:y2'
    endif
    args = strsplit(mpanel,'[,]',/extract,count=c)
    argcol = long(strsplit(args[0],':',/extract,count=colct))
    argrow = long(strsplit(args[1],':',/extract,count=rowct))
    xpanel_cur1 = argcol[0]
    ypanel_cur1 = !tplotxy.rows-1-argrow[0] 
    mincol = argcol[0]
    if (colct eq 2) then begin
       maxcol = argcol[1]
    endif else begin
       maxcol = argcol[0]
    endelse
    minrow = argrow[0]
    if (rowct eq 2) then begin
       maxrow = argrow[1]
    endif else begin
       maxrow = argrow[0]
    endelse
    xpanel_cur2 = maxcol
    ypanel_cur2 = !tplotxy.rows-1-maxrow
    if ((mincol gt maxcol) or (minrow gt maxrow)) then begin
          message, 'mpanel column and row numbers must be specified in ascending order'
    endif
    if ((maxcol gt (!tplotxy.cols-1)) or (maxrow gt (!tplotxy.rows -1))) then begin
          message, 'mpanel column and row numbers must be valid for current plot (column and row numbers start at 0)'
    endif
    for i=mincol, maxcol do begin
      for j=minrow, maxrow do begin
        if ((*(!tplotxy.panels))[i,j] eq 1) then begin
          message,'cannot plot in a panel that is already in use'
        endif
        ; mark the panel as used
        (*(!tplotxy.panels))[i,j] = 1
      endfor
    endfor   

  endif else begin ;when mpanel is not set
    panelfound = 0
    spaceavail = 1
    while(~panelfound and spaceavail) do begin ;checking space available should not be necessary as this is checked earlier. Putting it here to avoid infinite loop under unforeseen circumstances.
      if !tplotxy.revcols eq 0 then begin
        xpanel_cur1 = !tplotxy.current mod !tplotxy.cols
      endif else begin
        xpanel_cur1 = !tplotxy.cols - 1 - (!tplotxy.current mod !tplotxy.cols)
      endelse
  
      if !tplotxy.revrows ne 0 then begin
        ypanel_cur1 = !tplotxy.current / !tplotxy.cols
      endif else begin
       ypanel_cur1 = !tplotxy.rows - 1 - (!tplotxy.current / !tplotxy.cols)
      endelse
      if ((*(!tplotxy.panels))[xpanel_cur1, (!tplotxy.rows-1-ypanel_cur1)] eq 0) then begin
        panelfound = 1
      endif else begin
        !tplotxy.current++
        temp = where(*(!tplotxy.panels) eq 0, cntempty)
        if (cntempty eq 0) then begin
          spaceavail = 0
        endif
      endelse
    endwhile
    ; mark the panel as used
    (*(!tplotxy.panels))[xpanel_cur1,!tplotxy.rows-1-ypanel_cur1] = 1
    xpanel_cur2 = xpanel_cur1
    ypanel_cur2 = ypanel_cur1
  endelse
  
  ; sorting out overall margins
  deltax = 1-!tplotxy.margin[1]-!tplotxy.margin[3]
  deltay = 1-!tplotxy.margin[0]-!tplotxy.margin[2] 

  ;coordinates
  x1 = (xpanel_cur1 * xpanel_size + xpanel_size*(xpanel_cur2-xpanel_cur1+1)*xmargin[0])*deltax + !tplotxy.margin[1]
  x2 = ((xpanel_cur2+1) * xpanel_size - xpanel_size*(xpanel_cur2-xpanel_cur1+1)*xmargin[1])*deltax + !tplotxy.margin[1]
  ; ypanel counts from bottom up rather than top down
  y1 = (ypanel_cur2 * ypanel_size + ypanel_size*(ypanel_cur1-ypanel_cur2+1)*ymargin[0])*deltay + !tplotxy.margin[0]
  y2 = ((ypanel_cur1+1) * ypanel_size - ypanel_size*(ypanel_cur1-ypanel_cur2+1)*ymargin[1])*deltay + !tplotxy.margin[0]
  if keyword_set(isotropic) then begin

     x_data_sz = abs(double(x[1])-double(x[0]))

     y_data_sz = abs(double(y[1])-double(y[0]))

     ;plot size normalized into centimeters for comparisons
     x_plot_sz = !D.x_size*(x2-x1)/!D.x_px_cm
     
     y_plot_sz = !D.y_size*(y2-y1)/!D.y_px_cm

     if x_data_sz/y_data_sz lt x_plot_sz/y_plot_sz then begin

        x_plot_sz = y_plot_sz * x_data_sz/y_data_sz

     endif else begin

        y_plot_sz = x_plot_sz * y_data_sz/x_data_sz

     endelse 
     
     x2 = x1 + !D.x_px_cm * x_plot_sz/!D.x_size

     y2 = y1 + !D.y_px_cm * y_plot_sz/!D.y_size 
       
  endif
  
  !tplotxy.pos = [x1,y1,x2,y2]
  !tplotxy.xrange = x
  !tplotxy.yrange = y

  return, [x1,y1,x2,y2]

end

pro pxy_replot

  compile_opt idl2,hidden

  !tplotxy.current = 0
  (*(!tplotxy.panels))[*] = 0

  plotvec = *(!tplotxy.plotvec)

  len = csvector(plotvec,/length)

  for i = 1,len-1 do begin

     c = csvector(i,plotvec,/read)

     state=c.state

     if c.func eq 'plotxy' then begin

        plotxy, state.vectors,replot=1,_extra=state.ex

     endif else if c.func eq 'plotxyz' then begin

        plotxyz,state.x,state.y,state.z,replot=1,_extra=state.ex

     endif else if c.func eq 'plotxyvec' then begin

        plotxyvec,state.xy,state.dxy,replot=1,_extra=state.ex
        
     endif else begin
        
        message,'unrecognized replot function'

     endelse

  endfor

end

pro pxy_make_title
  xpos = 0.5
  ypos = 1-0.9*!tplotxy.margin[2]
  csize = !tplotxy.margin[2]*!d.y_size*0.5/!d.y_ch_size ;slightly arbitrary numbers to make the title look nice in most cases
 
  ;Using a program such as David Fanning's str_size would probably work better. This draws on his program but doesn't try very hard to find the right size
  currentWindow = !D.Window
  if((!D.Flags and 256) ne 0) then begin ;Don't try to change size if exporting to postscript for example
    Window, /Pixmap, /Free, XSize=!D.X_Size, YSize=!D.Y_Size
    XYOUTS, !tplotxy.title, WIDTH=w, charsize=-csize
    if (w gt 0.9) then begin
      while (w gt 0.9) do begin
        csize = csize-0.2
        XYOUTS, !tplotxy.title, WIDTH=w, charsize=-csize
        endwhile
        endif
  endif
  if currentWindow ne -1 then WSet, currentWindow
  xyouts,xpos, ypos, !tplotxy.title, alignment=0.5,/normal, charsize=csize

end

pro plotxylib

;does nothing
;call plotxylib at the beginning of any
;routine that needs the routines in this
;library to guarantee that they are compiled

end
