function st_swea_secondary_flux,energy,eflux,parameter=par

if not keyword_set(par) then begin
    xs = [1.0    ,  3.16,    10., 31.6, 100., 316, 1000., 3160.]

    ys = [1.0e-005, 1e-4, 0.0006, 0.04,  0.5,  1., 0.8 ,  .7]
    eff = spline_fit3(energy,xs,ys,param=par,/xlog,/ylog)
    par.func ='st_swea_secondary_flux'
    str_element,/add,par,'gain',1e6
endif else  eff = spline_fit3(energy,param=par)


if keyword_set(eflux) then begin
   eff = mcp_efficiency(energy) * (energy gt 20)

   nn = total( eflux/sqrt(energy) * eff)
   return,nn
dprint,'compute sum here'

endif


return,eff
end

