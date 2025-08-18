;       @(#)arrange_plots.pro	1.6     05/03/99
;+
; NAME: ARRANGE_PLOTS
;
; PURPOSE:  Returns normal coordinates of plot position box, suitable for
;          passing to PLOT, when you want to put many plots on one
;          page. Differs from setting !p.multi, because plots can be
;          put against one another with no space between. You can
;          specify the outer margins through keywords, as well as the
;          gaps between plots. By default, the margins are 0.1 left,
;          0.05 right, 0.1 bottom, 0.07 top, and there is no gap
;          between plots in either direction.
; 
; INPUTS: 
;
; KEYWORD PARAMETERS: 
;                     NX - the number of plots in the x direction
;
;                     NY - the number of plots in the y direction
;
;                     NPLOTS - the total number of plots
;
;                     X0MARGIN, Y0MARGIN,
;                      X1MARGIN, Y1MARGIN - the plot margins, in
;                      normalized coordinates.
;
;                     SQUARE - if set, the resulting plots are
;                              square. The larger dimension is shrunk to
;                              make squares.
; OUTPUTS: 
;          x0, y0, x1, y1: These are named variables in which the
;          left, lower, right, and upper boundaries, respectively of
;          each plot are returned.
;
;
;
; EXAMPLE: 
;   arrange_plots, x0, y0, x1, y1, nx=3
;   erase
;   for i=0,2 do plot,my_data,position=[x0[i],y0[i],x1[i],y1[i]],/noerase
;          
;
;
; MODIFICATION HISTORY:
;
;-
pro arrange_plots, x0o, y0o, x1o, y1o, $
                   nplots = nplots, x0margin = x0margin, x1margin = x1margin, $
                   y0margin = y0margin, y1margin = y1margin, help = help, $
                   nx = nx, ny = ny, xgap = xgap, ygap = ygap,  $
                   square = square

if not (arg_present(x0o) and arg_present(y0o) and  $
        arg_present(x1o) and arg_present(y1o)) then begin 
    message,'you must pass in 4 arguments, in which the plot position ' + $
      'values will be returned...x0, y0, x1, y1...',/continue
    return
endif

if keyword_set(help) then begin
    print,'use the values returned in the four named variables as '
    print,'input to the POSITION keyword...like this:'
    print,'plot,stuff,position = [x0[ix],y0[iy],x1[ix],y1[iy]]'
    print,'where ix and iy are the row and column numbers.'
endif

if not (defined(nplots) or defined(nx) or defined(ny)) then begin
    message,'Must define nplots, nx, or ny...',/continue
    return
end

case 1 of 
    (defined(nx) or defined(ny)) eq 0:begin
        sides = long(sqrt(float(nplots)))
        nx = sides
        ny = sides-1L
        repeat begin
            ny = ny + 1L
        endrep until (nx * ny) ge nplots
    end
    defined(nx) and defined(nplots):begin
        ny = nplots/nx + 1
    end
    defined(ny) and defined(nplots):begin
        nx = nplots/ny + 1
    end
    defined(nx) and defined(ny): begin
        nplots = nx*ny
    end
    defined(nx) and (defined(ny) eq 0) and  $
      (defined(nplots) eq 0):begin
        ny = 1
        nplots = nx*ny
    end
    defined(ny) and (defined(nx) eq 0) and  $
      (defined(nplots) eq 0):begin
        nx = 1
        nplots = nx*ny
    end
endcase

if not defined(x0margin) then x0margin = 0.1
if not defined(x1margin) then x1margin = 0.05
if not defined(y0margin) then y0margin = 0.1
if not defined(y1margin) then y1margin = 0.07
if not defined(xgap) then xgap = 0.
if not defined(ygap) then ygap = 0.

xmargin = x0margin + x1margin
ymargin = y0margin + y1margin

dx = (1. - xmargin)/float(nx) - xgap
dy = (1. - ymargin)/float(ny) - ygap
if keyword_set(square) then begin
    aspect = (float(!d.y_size) / float(!d.x_size))
    pdx = dx  / aspect
    pdy = dy 
    pdx = pdx < pdy
    pdy = pdx
    dxnew = pdx * aspect
    dynew = pdy 
    dxm = 0.5 * abs(dxnew - dx)*float(nx)
    dym = 0.5 * abs(dynew - dy)*float(ny)
    dx = dxnew
    dy = dynew
    x0margin = x0margin + dxm
    x1margin = x1margin + dxm
    y0margin = y0margin + dym
    y1margin = y1margin + dym
    xmargin = x0margin + x1margin
    ymargin = y0margin + y1margin
endif

y0 = reverse(findgen(ny)/float(ny)*(1. - ymargin) + y0margin)
y1 = y0 + dy

x0 = (findgen(nx)/float(nx))*(1. - xmargin) + x0margin
x1 = x0 + dx

x0o = fltarr(nplots)
y0o = fltarr(nplots)
x1o = fltarr(nplots)
y1o = fltarr(nplots)

for i=0,nplots-1 do begin
    ix = i mod nx
    iy = i / nx
    x0o[i] = x0[ix]
    y0o[i] = y0[iy]
    x1o[i] = x1[ix] 
    y1o[i] = y1[iy]
endfor

return
end

