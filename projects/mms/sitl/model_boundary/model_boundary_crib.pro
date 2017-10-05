; To show usage of model_boundary programs originally developed for EVA.
;
PRO model_boundary_crib
  compile_opt idl2

  ;----------------------------------------
  ; Draw a bow shock model that is scaled to the given location
  ;----------------------------------------
  scx = [16., 10, 0.]
  scy = [0., 15, 35.]
  scz = [1., 0., 0.]
  mBS = model_boundary_draw(pos=[scx,scy,scz],model='peredo')
  mMP = model_boundary_draw(sigma = mBS.sigma, model='roelof')
  zero_x = [-1000,1000]
  zero_y = [0,0]
  plot, mBS.xgse, mBS.ygse,xrange=[20,-20],yrange=[20,-20],$
    xtitle='X (GSE)',ytitle='Y (GSE)'
  oplot, mBS.xgse2, mBS.ygse2
  oplot, mMP.xgse,  mMP.ygse
  oplot, mMP.xgse2, mMP.ygse2
  oplot, zero_x, zero_y, linestyle=2
  oplot, zero_y, zero_x, linestyle=2
  stop
  
  ;---------------------------------------------------------------------------
  ; Estimate shock normal vectors at given locations of the boundary crossing
  ;---------------------------------------------------------------------------
  ; Scaled so that the observed crossing locations will be on the boundary.
  ;  
  xgse = [16., 10, 0.]
  ygse = [0., 15, 35.]
  zgse = [1., 0., 0.]
  result = model_boundary_normal(xgse, ygse, zgse)
  nmax = n_elements(result.nx)
  for n=0,nmax-1 do begin
    print, result.nx[n], result.ny[n], result.nz[n], ', scale=',result.scale[n]
  endfor
  
  stop
END
