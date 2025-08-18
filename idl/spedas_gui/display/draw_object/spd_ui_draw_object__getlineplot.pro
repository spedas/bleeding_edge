;+
;
; spd_ui_draw_object method: getLinePlot
;
;This function generates the line plot for an update
;There is actually a lot of room to increase draw speed
;by optimizing this function.  In specific we need to find
;a way to downsample a line plot, but the technique must work
;on series that are not functional(ex: circle), must not sort
;the inputs, must be imperceptible, must be fast, and must not
;expect the inputs to be spaced uniformly.  Some possibilities:
;1: uniform decimation
;2: pseudo-random decimation
;3: using pythagorean distance to rewrite non-functional series as functional series
;   then interpolate
;4: DFT with frequency cutoff, iDFT, uniform sample?
;
;Another problem involves determining the correct number of points to
;which the target should be decimated. There is a tradeoff where at one
;end you start to introduce aliasing errors and at the other end you get
;a speed slowdown.
;
;Currently the system uses the some constant factor times the number of pixels
;across the plot as the target decimation and it only decimates inputs that have
;time as the x-axis(which can be assumed to be functional).  These can be reliably
;decimated using normal interpolation.
;
;Inputs:
;  trace(object reference): the spd_ui_line_settings of the trace being generated
;  xrange(2 element double): The xrange of the panel being draw on
;  yrange(2 element double): The yrange of the panel being draw on
;  plotdim1(2 element double): The normalized position of the panel(start,stop), relative to window for x-axis
;  plotdim2(2 element double): The normalized position of the panel(start,stop), relative to window for y-axis
;  xscaling(long) : the scaling mode for x-axis 0(linear),1(log10),2(logN)
;  yscaling(long) : the scaling mode for y-axis 0(linear),1(log10),2(logN)
;  xAxisMajors(double array, variable length):  The positions of the x-axis ticks, normalized relative to panel(need for drawing symbols)
;  dx(ptr to array) : the x axis data being plotted
;  dy(ptr to array) : the y axis data being plotted
;  xistime(boolean):  1 if the x-axis is a time type, 0 other wise
;  mirrorptr(ptr to array,optional) the ptr to the mirror data(will deallocate mirrorptr data)
;Outputs: 
;  linecolor(3 element bytarr):  The color of the line that was drawn
;  refVar(ptr to array): the ptr to reference for use in legend
;  abcissa_out(ptr to array): ptr to abcissa values associated with reference, this feature is not currently in use, as refVar is gridded to pixel resolution, and pixel indexes are used
;
;Returns:
;  model with completed line plot
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getlineplot.pro $
;-
function spd_ui_draw_object::getLinePlot,trace,xrange,yrange,plotdim1,plotdim2,xscaling,yscaling,xAxisMajors,dx,dy,xistime,mirrorptr=mirrorptr,linecolor=linecolor,refvar=refvar,abcissa=abcissa_out

  compile_opt idl2,hidden
  
  zstack = .2
  
  model = obj_new('IDLgrModel')
  
  trace->getProperty,$
    dataX=dataX,$
    dataY=dataY,$
    lineStyle=lineStyle,$
    drawBetweenPts=drawBetweenPts,$
    mirrorLine=mirrorLine,$
    symbol=symbol,$
    plotpoints=plotpoints,$
    everyother=everyother,$
    positiveEndPt=positiveEndPt,$ ;error bars not yet implemented
    negativeEndPt=negativeEndPt,$
    positiveEndRel=positiveEndRel,$
    negativeEndRel=negativeEndRel,$
    barLine=barLine,$
    markSymbol=markSymbol
    
  lineStyle->getProperty,$
    id=id,$
    show=show,$
    color=color,$
    thickness=thick
    
  linecolor=color
  
  ;Make sure output from previous iteration does not iterfere
  if size(refVar,/type) then begin
    undefine,refvar
  endif
  
  if size(abcissa_out,/type) then begin
    undefine,abcissa_out
  endif
  
  ;number of pixels across the panel * res_factor = number of points in lookup
  linedim = self->getPlotSize(plotdim1,plotdim2,self.lineres)
  xpx = linedim[0]
  
  ;0 width range and plot can't be generated
  if xrange[1] - xrange[0] eq 0 then return,model
  
  if yrange[1] - yrange[0] eq 0 then return,model
  
  ;extract data, and eliminate previous copy
  x = temporary(*dx)
  y = temporary(*dy)
  
  if mirrorline then mirror = temporary(*mirrorptr)
  
  ;need at least two points to do separation check.
  if keyword_set(drawBetweenPts) && n_elements(x) gt 1 then begin
  
    ;determine the minimum amount of space that is allowed between points before we draw a gap.
    separation = trace->getPtSpacing()
    
    idx = where(abs((x[1:n_elements(x)-1]-x[0:n_elements(x)-2])) gt separation)
    
    ;These values should probably be inserted rather than replaced.
    if idx[0] ne -1 then begin
      y[idx] = !VALUES.D_NAN
    
      if keyword_set(mirrorline) then begin
        mirror[idx] = !VALUES.D_NAN
      endif
    endif 
    
  endif
  
  ;normalize x values relative to panel
  x = (x - xrange[0])/(xrange[1]-xrange[0])
  
  ;This generates the line reference
  self->makeLineReference,x,y,xpx,ref=refvar
  
  ;normalize the y values relative to the panel
  y = (y - yrange[0])/(yrange[1]-yrange[0]) 
  
  ;perform decimation on postscript plot
  if self.postscript && self.fancompressionfactor gt 0 then begin
      
    yratio = linedim[1]/linedim[0]  
  
    ;compress for postscript, object graphic postscript exporter doesn't compress
    ;For details on compression algorithm, see header for fancompress.pro 
    outidx = fancompress([[x],[y/yratio]],self.fancompressionfactor,/vector)
 
    x = x[outidx]
    y = y[outidx]
  
  endif
    
  if keyword_set(mirrorLine) then begin

    ;normalize mirror values
    mirrorvar = (temporary(mirror) - yrange[0])/(yrange[1]-yrange[0])
    
    ;generate mirror plot
    plot = obj_new('IDLgrPlot',x,mirrorvar,color=self->convertColor(color),linestyle=id,hide=~show,thick=thick,xrange=[0D,1D],yrange=[0D,1D],zvalue=zstack,/use_zvalue,/double)
    model->add,plot
    
  endif
  
  ;generate main line plot
  plot = obj_new('IDLgrPlot',x,y,color=self->convertColor(color),linestyle=id,hide=~show,thick=thick,xrange=[0D,1D],yrange=[0D,1D],zvalue=zstack,/use_zvalue,/double)
  
  model->add,plot
  
  n = n_elements(x)
  
  ;determine symbol positions depending on the option selected
  if plotpoints eq 1 then begin
    x_sym = [x[0],x[n-1]]
    y_sym = [y[0],y[n-1]]
  endif else if plotpoints eq 2 then begin
    x_sym = [x[0]]
    y_sym = [y[0]]
  endif else if plotpoints eq 3 then begin
    x_sym = [x[n-1]]
    y_sym = [y[n-1]]
  endif else if plotpoints eq 4 then begin
  
    ;majors is a little trickier, we have to loop over majors
    if n_elements(xAxisMajors) gt 1 then begin
      for i = 1,n_elements(xAxisMajors)-1 do begin
      
        t = min(abs(x-xAxisMajors[i]),idx)
        if t lt .01D then begin ;only add symbol if it is close to an actual value
          if n_elements(idx_l) eq 0 then begin
            idx_l = [idx]
          endif else begin
            idx_l = [idx_l,idx]
          endelse
        endif
        
      endfor
    endif
    
    if n_elements(idx_l) gt 0 then begin
      x_sym = x[idx_l]
      y_sym = y[idx_l]
    endif
    
  endif else if plotpoints eq 5 then begin
  
    if everyother gt 0 && everyother lt n then begin
    
      ;note that the (n mod everyother) statement is in place to prevent a 0 length lindgen
      ;It may no longer be necessary now that the draw object inputs are better error checked
      x_sym = x[lindgen(((n mod everyOther)ne 0)+n/everyOther)*everyOther]
      y_sym = y[lindgen(((n mod everyOther)ne 0)+n/everyOther)*everyOther]
    ;  x_sym = x[lindgen(n/everyOther)*everyOther]
    ;  y_sym = y[lindgen(n/everyOther)*everyOther]
      
    endif
  endif else begin
    x_sym = temporary(x)
    y_sym = temporary(y)
  endelse
  
  ;symbol plots
  
  ;note that symbol fill is not yet implmented
  
  ;now generate symbol plot from symbol settings
  symbol->getProperty,id=id,show=show,color=color,fill=fill,size=size
  
  if show && size(x_sym,/type) && size(y_sym,/type) then begin
  
    ;the size appears to be double the size in points that it should be.
    ;This modification scales the symbol size down
    xsize = .5*self->pt2norm(size,0)/(plotdim1[1]-plotdim1[0])
    ysize = .5*self->pt2norm(size,1)/(plotdim2[1]-plotdim2[0])
    
    ;get filled symbol if applicable
    if keyword_set(fill) then begin
      ssl_set_symbol, id, /fill, object=grSymbol, color=self->convertColor(color), $
                         obj_size=[xsize,ysize], fail=fail
    endif
    
    ;get normal symbol otherwise
    if ~keyword_set(grSymbol) then begin
      grSymbol = obj_new('IDLgrSymbol',id,color=self->convertColor(color),size=[xsize,ysize])
    endif
    
    plot = obj_new('IDLgrPlot',x_sym,y_sym,color=self->convertColor(color),linestyle=6, $
      xrange=[0D,1D],yrange=[0D,1D], zvalue=zstack+.01,symbol=grsymbol,/use_zvalue,/double)
      
    model->add,plot
    
  endif
  
  ;returning the final model
  return,model
  
end
