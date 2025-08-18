


pro tplot_plotter::plot,time,tvarname
  ; overload this routine with something useful
  dprint,time_string(time),tvarname

end

pro tplot_plotter::set_window,wnum
  if ~self.limits.haskey('window') then self.limits.window


end

PRO tplot_plotter::GetProperty, dict=dict, limits=limits, ptr=ptr, name=name, data=data
  ; This method can be called either as a static or instance.
  COMPILE_OPT IDL2
  IF (ARG_PRESENT(dict)) THEN dict = self.dict
  IF (ARG_PRESENT(limits)) THEN limits = self.limits
  if arg_present(data) then data = self.data
  IF (ARG_PRESENT(name)) THEN name = self.name
END



function tplot_plotter::init,name,limits=limits,dict=dict,window=wind,wsize=wsize
  if isa(name,/string) then self.name = name
  if ~keyword_set(limits) then  limits = dictionary()
  if ~keyword_set(dict) then dict = dictionary()

  self.limits = limits
  self.dict = dict
  ;self.plotstate = ptr_new()
  if isa(name) then title=name
  if n_elements(wsize) eq 2 then begin
    xsize = wsize[0]
    ysize = wsize[1]
    self.limits.wsize=wsize
  endif
  if keyword_set(wind) then window,wind else  window,/free,title = title,xsize=xsize,ysize=ysize
  self.limits.window = !d.window
  return,1
end


;+
;OBJECT:   tplot_plotter()
;KEYWORDS:
;-
pro tplot_plotter__define
  compile_opt IDL2
  void = {tplot_plotter,  $
    inherits generic_object,  $
    name:'',  $
    ;   window: 0, $
    ;   wsize: [0,0], $
    dict: obj_new(), $
    data: obj_new(), $
    plotstate:  ptr_new(), $
    ;   ptr:  ptr_new()   }
    limits: obj_new() $
    }
    
    return
end


