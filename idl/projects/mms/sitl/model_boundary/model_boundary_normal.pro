; INPUT
;  x: scalar or array of the x-component of the s/c positions in GSE
;  y: scalar or array of the y-component of the s/c positions in GSE
;  z: scalar or array of the z-component of the s/c positions in GSE
;  a0: aberration angle in degree
;  model_name: model name
;
FUNCTION model_boundary_normal, x, y, z, a0=a0, model_name=model_name
  compile_opt idl2
  nmax = n_elements(x)
  if (nmax ne n_elements(y) or nmax ne n_elements(z)) then begin
    message,'All x,y,z arrays must have the same number of elements.'
  endif
  un = fltarr(nmax)+1.
  r2d = 180.d0/!DPI
  d2r = !DPI/180.d0
  
  ;-----------------------------
  ; 1. Model
  ;-----------------------------
  if undefined(model_name) then model_name='peredo'
  mdl = model_boundary_parameters('peredo',a0=a0)
  eps = mdl.eps
  L   = mdl.L
  x0  = mdl.x0
  y0  = mdl.y0
  z0  = mdl.z0
  a   = mdl.a
  
  ;-----------------------------
  ; 2. GSE -> Cone system
  ;-----------------------------
  xabd = x*cos(a)-y*sin(a)-x0; s/c position in the aberrated-displaced system
  yabd = x*sin(a)+y*cos(a)-y0
  zabd =                z -z0
  rabd = sqrt(xabd^2+yabd^2+zabd^2)
  cos_the_abd = xabd/rabd
  rmodel = L/(1+eps*cos_the_abd)

  ;------------------
  ; 3. Scale L & r
  ;------------------
  x1 = x*cos(a)-y*sin(a)
  y1 = x*sin(a)+y*cos(a)
  z1 = z
  AAtmp = x0^2+y0^2+z0^2-(L+eps*x0)^2
  AA = AAtmp*un; ensure array
  BB = 2*eps*x1*(L+eps*x0) - 2*x0*x1 - 2*y0*y1 - 2*z0*z1
  CC = x1^2+y1^2+z1^2-(eps*x1)^2
  sigp = (-BB+sqrt(BB^2-4*AA*CC))/(2*AA)
  sigm = (-BB-sqrt(BB^2-4*AA*CC))/(2*AA)
  sigma = sigm

  xabd = x1-sigma*x0
  yabd = y1-sigma*y0
  zabd = z1-sigma*z0
  L    = sigma*L

  ;------------------
  ; 4. Gradient
  ;------------------
  nx =  (xabd*(1-eps^2)+eps*L)*cos(a)+yabd*sin(a)
  ny = -(xabd*(1-eps^2)+eps*L)*sin(a)+yabd*cos(a)
  nz =  zabd
  
  ;------------------
  ; 5. Normal vector
  ;------------------
  nabs = sqrt(nx^2+ny^2+nz^2)
  nx /= nabs
  ny /= nabs
  nz /= nabs
  
  return, {nx:nx, ny:ny, nz:nz, scale:sigma, rabd:rabd, rmodel:rmodel, cone:r2d*acos(cos_the_abd)}
END
