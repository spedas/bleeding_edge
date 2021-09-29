PRO sppeva_plot, paramlist, parent_xsize=parent_xsize
  compile_opt idl2
  
  if undefined(paramlist) then message,'Specify paramlist.'
  
  dim_scr = get_screen_size()
  width  = 0.8*dim_scr[0]
  height = 0.8*dim_scr[1] 
  
  if undefined(xsize) then xsize = width else xsize = dim_scr[0] - parent_xsize - 200 > 0
  
  xtplot, paramlist, xsize=xsize, ysize=height
  
END
