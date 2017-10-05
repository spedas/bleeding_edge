FUNCTION model_boundary_parameters, model, a0=a0
  compile_opt idl2
  if undefined(a0) then a0=3.8
  model = strlowcase(model)

  case model of
    'peredo': begin
      eps = 0.98 & L=26.1 & x0=2.0  & y0=0.3 & z0=0.0 & a=a0-0.6 & Pdyn=3.1
      end
    'roelof': begin
      eps = 0.91 & L=11.2 & x0=4.82 & y0=0.0 & z0=0.0 & a=a0  & Pdyn=2.1
      end
  endcase
  d2r = !DPI/180.d0
  return,{eps:eps, L:L, x0:x0, y0:y0, z0:z0, a:a*d2r, Pdyn:Pdyn}
END