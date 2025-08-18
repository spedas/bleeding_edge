;+
;FUNCTION:   spline_smooth
;PURPOSE:
;  Uses spline smoothing to create a smooth curve through noisy data.
;  This routine uses splinecoeff.pro, written by Nikola Vitas.  See
;  detailed documentation below (and https://github.com/nikolavitas).
;
;USAGE:
;  ys = spline_smooth(x, y, weight=w, labmda=lambda)
;
;INPUTS:
;       x:         Independent variable.
;
;       y:         Dependent variable.  Same number of elements as x.
;
;KEYWORDS:
;       WEIGHT:    Weights for y.  Default = replicate(1.,n_elements(y))
;
;       LAMBDA:    Smoothing factor.  A value of 0 corresponds to cubic
;                  splines.  Larger values increase the smoothing.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-06-23 12:31:58 -0700 (Fri, 23 Jun 2023) $
; $LastChangedRevision: 31907 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/misc/spline_smooth.pro $
;
;CREATED BY:	David L. Mitchell  2021-10-18
;-

FUNCTION splinecoeff, x, y, sigm=sigm, lambda=lambda

;+
; NAME:
;       SPLINECOEFF
;
; PURPOSE:
;
;       This procedure computes coefficients of cubic splines for a
;       given observational set and smoothing parameter lambda. The 
;       method is coded after Pollock D.S.G. (1999), "A Handbook of 
;       Time-Series Analysis, Signal Processing and Dynamics, Academic 
;       Press", San Diego.
;
; AUTHOR:
;
;       Nikola Vitas
;       Instituto de Astrofísica de Canarias (IAC)
;       C/ Vía Láctea, s/n
;       E38205 - La Laguna (Tenerife), España
;       Email: n.vitas@iac.es
;       Homepage: nikolavitas.blogspot.com
;
; CATEGORY:
;
;       Numerics, statistics.
;
; CALLING SEQUENCE:
;
;       coeffs = SPLINECOEFF([x,] y, [sigma=sigma,] lambda=lambda)
;
; OPTIONAL INPUTS:
;
; OUTPUTS:
;
; INPUT KEYWORDS:
;
;       LAMBDA = Scalar, float. Smoothing parameter (It can be determined
;                empirically, by the LS method or by cross- validation, e.g. see 
;                the book of Pollock.) Lambda equals 0 results in a cubic spline 
;                interpolation. In the other extreme, for a very large lambda,
;                the result is smoothing by a linear function.
;
;       SIGMA  = Array. Weight of each data point. If not specified, all  
;                measurements have same weight.

; OUTPUT KEYWORDS:
;
;       X     = Array. Independent variable.
;       Y     = Array. Function to be smoothed or interpolated.
;
;  EXAMPLE:
;
;       x = .....
;       y = .....
;       coeffs = SPLINECOEFF(x, y, lambda = 1.d5)
;       y1 = FLTARR(N_ELEMENTS(y) - 1)
;       x1 = x[0:N_ELEMENTS(y)-2]
;       FOR i = 0, N_ELEMENTS(y)-2 DO y1[i] = coeff.d[I] + $
;                                             coeff.c[I] * (x[I+1]-x[I]) + $
;                                             coeff.b[I] * (x[I+1]-x[I])^2 + $
;                                             coeff.a[I] * (x[I+1]-x[I])^3
;   PLOT, x, y, psym = 3
;   OPLOT, x1, y1
;
; DEPENDENCIES:
;
;
; MODIFICATION HISTORY:
;
;       Written by Nikola Vitas, December 2005. 
;       - Small modifications, () replaced with [], NV, October, 2012
;-
;================================================================================
; SplineCoeff by Nikola Vitas is licensed under a Creative Commons 
; Attribution-NonCommercial-ShareAlike 3.0 Unported License.
;                                                                                          
; This software is provided by NV ''as is'' and any express or implied warranties, 
; including, but not limited to, the implied warranties of merchantability and 
; fitness for a particular purpose are disclaimed. In no event shall NV be liable 
; for any direct, indirect, incidental, special, exemplary, or consequential 
; damages (including, but not limited to, procurement of substitute goods or 
; services; loss of use, data, or profits; loss of use, data, or profits; or 
; business interruption) however caused and on any theory of liability, whether 
; in contract, strict liability, or tort (including negligence or otherwise) 
; arising in any way out of the use of this software, even if advised of the 
; possibility of such damage.                            
;================================================================================

num = SIZE(x, /N_ELEMENTS)
n = num-1
IF NOT(KEYWORD_SET(lambda)) THEN MESSAGE, 'Parameter lambda is not defined.'
IF NOT(KEYWORD_SET(sigm)) THEN sigm = FLTARR(num)+1

; Definition of the help variables
h = DBLARR(num) & r = DBLARR(num) & f = DBLARR(num) & p = DBLARR(num)
q = DBLARR(num) & u = DBLARR(num) & v = DBLARR(num) & w = DBLARR(num)

; Definition of the unknown coefficients
a = DBLARR(num) & b = DBLARR(num) & c = DBLARR(num) & d = DBLARR(num)

; Computation of the initial values
h[0] = x[1] - x[0]
r[0] = 3.d/h[0]

; Computation of all H, R, F, P & Q
FOR i = 1, n - 1 DO BEGIN
        h[i] = x[i+1] - x[i]
        r[i] = 3.D/h[i]
        f[i] = -(r[i-1] + r[i])
        p[i] = 2.D * (x[i+1] - x[i-1])
        q[i] = 3.D * (y[i+1] - y[i])/h[i] - 3.D * (y[i] - y[i-1])/h[i-1]
ENDFOR

; Compute diagonals of the matrix: W + LAMBDA T' SIGMA T
FOR i = 1, n - 1 DO BEGIN
        u[i] = r[i-1]^2 * sigm[i-1] + f[i]^2 * sigm[i] + r[i]^2 * sigm[I+1]
        u[i] = lambda * u[i] + p[i]
        v[i] = f[i] * r[i] * sigm[i] + r[i] * f[i+1] * sigm[i+1]
        v[i] = lambda * v[i] + h[i]
        w[i] = lambda * r[i] * r[i+1] * sigm[i+1]
ENDFOR

; Decomposition in the form L' D L
v[1] = v[1]/u[1]
w[1] = w[1]/u[1]

FOR j = 2, n-1 DO BEGIN
        u[j] = u[j] - u[j-2] * w[j-2]^2 - u[j-1] * v[j-1]^2
        v[j] = (v[j] - u[j-1] * v[j-1] * w[j-1])/u[j]
        w[j] = w[j]/u[j]
ENDFOR

; Gaussian eliminations to solve Lx = T'y
q[0] = 0.D
FOR j = 2, n-1 DO q[j] = q[j] - v[j-1] * q[j-1] - w[j-2] * q[j-2]
FOR j = 1, n-1 DO q[j] = q[j]/u[j]

; Gaussian eliminations to solve L'c = D^{-1}x
q[n-2] = q[n-2] - v[n-2]*q[n-1]
FOR j = n-3, 1, -1 DO q[j] = q[j] - v[j] * q[j+1] - w[j] * q[j+2]

; Coefficients in the first segment
d[0] = y[0] - lambda * r[0] * q[1] * sigm[0]
d[1] = y[1] - lambda * (f[1] * q[1] + r[1] * q[2]) * sigm[1]
a[0] = q[1]/(3.D * h[0])
b[0] = 0.D
c[0] = (d[1] - d[0])/h[0] - q[1] * h[0]/3.D

; Other coefficients
FOR j = 1, n-1 DO BEGIN
  a[j] = (q(j+1)-q[j])/(3.D * h[j])
  b[j] = q[j]
  c[j] = (q[j] + q[j-1]) * h[j-1] + c[j-1]
  d[j] = r[j-1] * q[j-1] + f[j] * q[j] + r[j] * q[j+1]
  d[j] = y[j] - lambda * d[j] * sigm[j]
ENDFOR
d[n] = y[n] - lambda * r[n-1] * q[n-1] * sigm[n]

splcoeff = {a:DBLARR(num), b:DBLARR(num), c:DBLARR(num), d:DBLARR(num)}
splcoeff.a = a
splcoeff.b = b
splcoeff.c = c
splcoeff.d = d

RETURN, splcoeff

END

function spline_smooth, x, y, weight=weight, lambda=lambda

  nx = n_elements(x)
  if (size(lambda,/type) eq 0) then lambda = 1D else lambda = double(lambda[0])
  if (n_elements(weight) ne nx) then weight = replicate(1.,nx)

; Compute coefficients of the cubic splines

  coeff = splinecoeff(x, y, sigm=weight, lambda=lambda)

; Compute the smooth spline

  ys = fltarr(nx)
  for i=0L,(nx-2L) do ys[i] = coeff.d[i] + $
                              coeff.c[i] * (x[i+1]-x[i]) + $
                              coeff.b[i] * (x[i+1]-x[i])^2 + $
                              coeff.a[i] * (x[i+1]-x[i])^3

; Linear extrapolation for the last point

  slope = (ys[nx-2L] - ys[nx-3L])/(x[nx-2L] - x[nx-3L])
  ys[nx-1L] = ys[nx-2L] + (x[nx-1L] - x[nx-2L])*slope

  return, ys

end
