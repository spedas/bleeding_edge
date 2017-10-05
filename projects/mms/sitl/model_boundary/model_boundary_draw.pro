;+
; NAME: model_boundary_draw
;
; PURPOSE: To draw bow shock and magnetopause. (Originally created for EVA)
; 
;   This routine will return some arrays for plotting.
;     e.g. 
;     MMS> model = model_boundary_draw()
;     MMS> plot, model.xgse, model.ygse,xrange=[20,-20],yrange=[20,-20]
;     MMS> oplot, model.xgse2, model.ygse2
;     
; KEYWORDS:
;   MODEL_NAME: Currenly supported for 'peredo' and 'roelof'
;   THETA_RANGE: Default range is [0,180]
;   POS:         Position (x,y,z) of a spacecraft in a 3-element array. 
;                The model will be scalled to the given position.
;
; CREATED BY: Mitsuo Oka
;
; $LastChangedBy: moka $
; $LastChangedDate: 2017-04-15 09:31:13 -0700 (Sat, 15 Apr 2017) $
; $LastChangedRevision: 23161 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/model_boundary/model_boundary_draw.pro $
;
FUNCTION model_boundary_draw, theta_range=theta_range, phi=phi, model_name=model_name, Pdyn=Pdyn,$
  pos=pos, sigma_in=sigma_in
  compile_opt idl2
  
  if undefined(model_name) then model_name='peredo'
  if undefined(theta_range) then theta_range = [0, 180]
  if undefined(phi) then phi = 0; phi = 0 for a cut at z=0
  
  ; Set a model
  r2d = 180.d0/!DPI
  d2r = !DPI/180.d0
  mdl = model_boundary_parameters(model_name,a0=a0)
  L = mdl.L
  eps = mdl.eps
  x0 = mdl.x0
  y0 = mdl.y0
  z0 = mdl.z0
  a  = mdl.a

  ;-----------------------
  ; Sigma (Scaling factor)
  ;-----------------------
  if undefined(sigma_in) then begin
    ; Scale with spacecraft position 
    if ~undefined(pos) then begin
      x = pos[0]
      y = pos[1]
      z = pos[2]
      x1 = x*cos(a)-y*sin(a) ; Temporary variables
      y1 = x*sin(a)+y*cos(a) ; Do not add (x0,y0,z0)
      z1 = z                 
      AAtmp = x0^2+y0^2+z0^2-(L+eps*x0)^2
      AA = AAtmp;*un; ensure array
      BB = 2*eps*x1*(L+eps*x0) - 2*x0*x1 - 2*y0*y1 - 2*z0*z1
      CC = x1^2+y1^2+z1^2-(eps*x1)^2
      sigp = (-BB+sqrt(BB^2-4*AA*CC))/(2*AA)
      sigm = (-BB-sqrt(BB^2-4*AA*CC))/(2*AA)
      sigma = sigm;...... Scaling factor
      print, 'sigma=',sigma
    endif else begin
      sigma = 1.
    endelse
  endif else begin
    sigma = sigma_in
  endelse
  L  *= sigma
  x0 *= sigma
  y0 *= sigma
  z0 *= sigma
  
  ;message, 'not implemented yet'
  
  ;--------------------------
  ; Vary cone angle 'theta'
  ;--------------------------
  imax = 1000
  theta_min = d2r*theta_range[0]
  theta_max = d2r*theta_range[1]
  dtheta = (theta_max-theta_min)/float(imax)
  theta = theta_min + dtheta*findgen(imax)
  rmodel = L/(1+eps*cos(theta))
  un = fltarr(imax) + 1.

  ;-------------------------------
  ; positions in the aberrated-displaced system (cone system)
  ;-------------------------------
  phi = un*d2r*phi ; make phi an array
  xabd = rmodel*cos(theta)
  yabd = rmodel*sin(theta)*cos(phi)
  zabd = rmodel*sin(theta)*sin(phi)
  xabd2=  xabd; 
  yabd2= -yabd; The point on the other side of the axis
  zabd2= -zabd; 
  
  ;--------------------
  ; transform to GSE
  ;--------------------
  xgse =  (xabd+x0)*cos(a)+(yabd+y0)*sin(a)
  ygse = -(xabd+x0)*sin(a)+(yabd+y0)*cos(a)
  zgse = zabd
  xgse2=  (xabd2+x0)*cos(a)+(yabd2+y0)*sin(a)
  ygse2= -(xabd2+x0)*sin(a)+(yabd2+y0)*cos(a)
  zgse2= zabd2

  return, {xgse:xgse, ygse:ygse, zgse:zgse, xgse2:xgse2, ygse2:ygse2, zgse2:zgse2, sigma:sigma}
END
