;+
;PROCEDURE:   parabola_vertex
;PURPOSE:
;  Calculates the vertex of the parabola defined by three points.
;  The parabola is assumed to be of the form:
;
;    y = A*(x - xv)^2. + yv
;
;  where A is a constant and [xv, yv] are the coordinates of the 
;  vertex.  Works best when the input x values surround the vertex,
;  but works in other cases as well.
;
;  Uses the second-order Lagrange interpolation formula.  This is
;  not a fit -- it is an exact algebraic calculation.
;
;USAGE:
;  parabola_vertex, xi, yi, xv, yv
;
;INPUTS:
;     xi : independent variable (at least 3 values)
;     yi : dependent variable (at least 3 values)
;
;     If xi and yi contain more than 3 values, then the routine 
;     uses the three points surrounding the extremum in yi.  The
;     points do not have to be evenly spaced.
;
;     The xi must be different.
;
;OUTPUTS:
;     xv : location of the parabola vertex in x
;     yv : value of the dependent variable at the vertex
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-10-21 13:14:47 -0700 (Wed, 21 Oct 2020) $
; $LastChangedRevision: 29266 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/parabola_vertex.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro parabola_vertex, xi, yi, xv, yv

  nx = n_elements(xi)
  ny = n_elements(yi)
  if ((nx lt 3) or (nx ne ny)) then begin
    print, 'Error specifying input points.'
    return
  endif

  x = double(xi)
  y = double(yi)
  a = dblarr(3)

  yoff = max(y,i)
  if ((i eq 0) or (i eq nx-1)) then yoff = min(y,i)
  xoff = x[i]
  j = [-1, 0, 1] + ((i > 1) < (nx - 2))

  x = x[j] - xoff
  y = y[j] - yoff

  a[0] = y[0]/((x[0]-x[1])*(x[0]-x[2]))
  a[1] = y[1]/((x[1]-x[0])*(x[1]-x[2]))
  a[2] = y[2]/((x[2]-x[0])*(x[2]-x[1]))

  xv = (a[0]*(x[1]+x[2]) + a[1]*(x[0]+x[2]) + a[2]*(x[0]+x[1]))/(2.*total(a))
  yv = a[0]*(xv-x[1])*(xv-x[2]) + a[1]*(xv-x[0])*(xv-x[2]) + a[2]*(xv-x[0])*(xv-x[1])

  xv += xoff
  yv += yoff

  return

end
