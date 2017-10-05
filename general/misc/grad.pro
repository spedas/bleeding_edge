;+
;
;Procedure: Grad
;
;Purpose:  Calculates the gradient of a 2d or 3d grid in one of two ways.
;
;  In 2d:
;  Method1(default):
;  gradientX = (grid[x+1,y] - grid[x,y] + grid[x+1,y+1] - grid[x,y+1]) / (2*dx)
;  gradientY = (grid[x,y+1] - grid[x,y] + grid[x+1,y+1] - grid[x+1,y]) / (2*dy)
;  
;  Method2(leftright): 
;  gradientX = (grid[x+1,y] - grid[x,y] + grid[x,y] - grid[x-1,y]) / (2*dx)
;  gradientY = (grid[x,y+1] - grid[x,y] + grid[x,y] - grid[x,y-1]) / (2*dy)
;  This method is actually equivalent to:
;  gradientX = (grid[x+1,y] - grid[x-1,y]) / (2*dx)
;  gradientY = (grid[x,y+1] - grid[x,y-1]) / (2*dy)
;  
;  In 3d: 
;  Method1(default):
;  gradientX = (grid[x+1,y,z] - grid[x,y,z] + grid[x+1,y+1,z] - grid[x,y+1,z] + 
;               grid[x+1,y,z+1] - grid[x,y,z+1] + grid[x+1,y+1,z+1] - grid[x,y+1,z+1])
;               / (4*dx)
;  gradientY = (grid[x,y+1,z] - grid[x,y,z] + grid[x+1,y+1,z] - grid[x+1,y,z] + 
;               grid[x,y+1,z+1] - grid[x,y,z+1] + grid[x+1,y+1,z+1] - grid[x+1,y,z+1])
;               / (4*dy)
;  gradientZ = (grid[x,y,z+1] - grid[x,y,z] + grid[x+1,y,z+1] - grid[x+1,y,z] + 
;               grid[x,y+1,z+1] - grid[x,y+1,z] + grid[x+1,y+1,z+1] - grid[x+1,y+1,z])
;               / (4*dz)
;               
;  Method2(leftright):
;  gradientX = grid[x+1,y,z] - grid[x-1,y,z] / (2*dx)
;  gradientY = grid[x,y+1,z] - grid[x,y-1,z] / (2*dy)
;  gradientZ = grid[x,y,z+1] - grid[x,y,z-1] / (2*dz)
;  
;  Method1 will produce an output that is one element smaller in each dimension
;  and whose element centers are offset by half the nominal spacing of the grid.
;  
;  Method2 will have the same centers and same number of elements as the original
;  grid(if the original grid had regular spacing).
;  
;  
;Example:
;
;Inputs: grid: an NxM grid of points, if it contains NaNs the output may be 
;             unpredictable.(or an NxMxP)
;        x(optional):  An N length array specifying the positions of the grid points on the x-axis
;             xc should be monotonic and should contain no NaNs.  If unset this routine will
;             assume dx = 1.0
;        y(optional):  An M length array specifying the positions of the grid points on the y-axis
;             yc should be monotonic and should contain no NaNs. If unset this routine will
;             assume dy = 1.0
;        z:(optional) a P length array specifying the positions of the grid points on
;             the z-axis.  zc should be monotonic and should contain no NaNs. If unset this routine will
;             assume dz = 1.0
;             
;Keywords:
;        grad:  The gradient is output through this keyword as an NxMx2 array
;        of points.  grad[*,*,0] is the x gradient & grad[*,*,1] is the y gradient
;        
;        xout: The positions of the gradient outputs on the x axis are output through this 
;        keyword as an N length array
;        
;        yout: The positions of the gradient outputs on the y axis are output through this
;        keyword as an M length array
;        
;        xy:  The positions for each output point are passed out as pairs through this
;        keyword. The output array will have dimensions N*Mx2,(N times M by 2)
;        
;        dxy: The gradient for each point is passed out as pairs through this
;        keyword. The output array will have dimensions N*Mx2,(N times M by 2)
;        
;        leftright:  Set this keyword if you want to use the second method
;        of gradient calculation.
;
; Notes:
; 1. This procedure is not particularly tolerant of NaNs in the input, so
; you should remove them before passing them into this routine.
; 
; 2. The output may have slightly different centers/ dimensions as the input.
; This is will definitely be the case if the input array had irregular dimensions.
; 
; 3. xy,dxy are useful output format keywords for the plotxyvec routine
; While grad,xout, & yout may be easier for other tasks.
;
;-


pro grad,grid,x,y,z,grad=grad,$
  xout=xout,yout=yout,zout=zout,xy=xy,$
  dxy=dxy,leftright=leftright,regrid=regrid

compile_opt idl2

if ~keyword_set(grid) then begin
  dprint,'grid must be set.  Returning.'
  return
endif

dim = dimen(grid)

if ~keyword_set(x) then begin 
  xc = dindgen(dim[0])
endif else begin  
  xc = x
endelse

if ~keyword_set(y) then begin
  yc = dindgen(dim[1])
endif else begin
  yc = y
endelse

if n_elements(xc) ne dim[0] then begin
  dprint,'number of elements in xc must equal the number of elements in the 1st dimension of grid'
  return
endif

if n_elements(yc) ne dim[1] then begin
  dprint,'number of elements in yc must equal the number of elements in the 2nd dimension of grid'
  return
endif

if n_elements(dim) eq 3 then begin

  if ~keyword_set(z) then begin
    zc = dindgen(dim[2])
  endif else begin
    zc = z
  endelse
  
  if n_elements(zc) ne dim[2] then begin
    dprint,'number of elements in zc must equal the number of elements in the 3rd dimension of grid'
    return
  endif
  
endif 
  
if keyword_set(leftright) then begin

  xdiv = rebin(shift(xc,-1)-shift(xc,1),dim)

  if n_elements(dim) eq 2 then begin

    ydiv = transpose(rebin(shift(yc,-1)-shift(yc,1),dim[1],dim[0]))

    gradx = (shift(grid,-1,0) - shift(grid,1,0))/xdiv
    gradx[0,*] = (grid[1,*] - grid[0,*])/(xc[1]-xc[0])
    gradx[dim[0]-1,*] = (grid[dim[0]-1,*] - grid[dim[0]-2,*])/(xc[dim[0]-1]-xc[dim[0]-2])
    
    grady = (shift(grid,0,-1) - shift(grid,0,1))/ydiv
    grady[*,0] = (grid[*,1] - grid[*,0])/(yc[1]-yc[0])
    grady[*,dim[1]-1] = (grid[*,dim[1]-1] - grid[*,dim[1]-2])/(yc[dim[1]-1]-yc[dim[1]-2])
  
  endif else if n_elements(dim) eq 3 then begin

    ydiv = transpose(rebin(shift(yc,-1)-shift(yc,1),dim[1],dim[0],dim[2]),[1,0,2])
    zdiv = transpose(rebin(shift(zc,-1)-shift(zc,1),dim[2],dim[1],dim[0]),[2,1,0])

    gradx = (shift(grid,-1,0,0) - shift(grid,1,0,0))/xdiv
    gradx[0,*,*] = (grid[1,*,*] - grid[0,*,*])/(xc[1]-xc[0])
    gradx[dim[0]-1,*,*] = (grid[dim[0]-1,*,*] - grid[dim[0]-2,*,*])/(xc[dim[0]-1]-xc[dim[0]-2])
    
    grady = (shift(grid,0,-1,0) - shift(grid,0,1,0))/ydiv
    grady[*,0,*] = (grid[*,1,*] - grid[*,0,*])/(yc[1]-yc[0])
    grady[*,dim[1]-1,*] = (grid[*,dim[1]-1,*] - grid[*,dim[1]-2,*])/(yc[dim[1]-1]-yc[dim[1]-2])
  
    gradz = (shift(grid,0,0,-1) - shift(grid,0,0,1))/zdiv
    gradz[*,*,0] = (grid[*,*,1] - grid[*,*,0])/(zc[1]-zc[0])
    gradz[*,*,dim[2]-1] = (grid[*,*,dim[2]-1] - grid[*,*,dim[2]-2])/(zc[dim[2]-1]-zc[dim[2]-2])
  endif else begin
    dprint,'Wrong number of dimensions in grid'
    return
  endelse
  
  
  xoff = 0
  yoff = 0
  zoff = 0
  
endif else begin

  dim-= 1
  
  xoff = shift(xc - shift(xc,1),-1) / 2.
  yoff = shift(yc - shift(yc,1),-1) / 2.
  
  dx = rebin(xc[1:dim[0]]-xc[0:dim[0]-1],dim)
  
  if n_elements(dim) eq 2 then begin
  
    dy = transpose(rebin(yc[1:dim[1]]-yc[0:dim[1]-1],dim[1],dim[0]))
  
    gradx = ((grid[1:dim[0],0:dim[1]-1]+grid[1:dim[0],1:dim[1]]) - (grid[0:dim[0]-1,0:dim[1]-1] + grid[0:dim[0]-1,1:dim[1]]))/(2.*dx)
    grady = ((grid[0:dim[0]-1,1:dim[1]]+grid[1:dim[0],1:dim[1]]) - (grid[0:dim[0]-1,0:dim[1]-1] + grid[1:dim[0],0:dim[1]-1]))/(2.*dy)
    
  endif else if n_elements(dim) eq 3 then begin
  
    dy = transpose(rebin(yc[1:dim[1]]-yc[0:dim[1]-1],dim[1],dim[0],dim[2]),[1,0,2])
    dz = transpose(rebin(zc[1:dim[2]]-zc[0:dim[2]-1],dim[2],dim[1],dim[0]),[2,1,0])
  
    gradx = (grid[1:dim[0],0:dim[1]-1,0:dim[2]-1] - grid[0:dim[0]-1,0:dim[1]-1,0:dim[2]-1]) + $
            (grid[1:dim[0],1:dim[1],0:dim[2]-1] - grid[0:dim[0]-1,1:dim[1],0:dim[2]-1]) + $
            (grid[1:dim[0],0:dim[1]-1,1:dim[2]] - grid[0:dim[0]-1,0:dim[1]-1,1:dim[2]]) + $
            (grid[1:dim[0],1:dim[1],1:dim[2]] - grid[0:dim[0]-1,1:dim[1],1:dim[2]]) / $
            (4.*dx)
            
    grady = (grid[0:dim[0]-1,1:dim[1],0:dim[2]-1] - grid[0:dim[0]-1,0:dim[1]-1,0:dim[2]-1]) + $
            (grid[1:dim[0],1:dim[1],0:dim[2]-1] - grid[1:dim[0],0:dim[1]-1,0:dim[2]-1]) + $
            (grid[0:dim[0]-1,1:dim[1],1:dim[2]] - grid[0:dim[0]-1,0:dim[1]-1,1:dim[2]]) + $
            (grid[1:dim[0],1:dim[1],1:dim[2]] - grid[1:dim[0],0:dim[1]-1,1:dim[2]]) / $
            (4.*dy)
            
    gradz = (grid[0:dim[0]-1,0:dim[1]-1,1:dim[2]] - grid[0:dim[0]-1,0:dim[1]-1,0:dim[2]-1]) + $
            (grid[1:dim[0],0:dim[1]-1,1:dim[2]] - grid[1:dim[0],0:dim[1]-1,0:dim[2]-1]) + $
            (grid[0:dim[0]-1,1:dim[1],1:dim[2]] - grid[0:dim[0]-1,1:dim[1],0:dim[2]-1]) + $
            (grid[1:dim[0],1:dim[1],1:dim[2]] - grid[1:dim[0],1:dim[1],0:dim[2]-1]) / $
            (4.*dz)
        
    zoff = shift(zc - shift(zc,1),-1) / 2.
            
  endif else begin
    dprint,'Wrong number of dimensions in grid'
    return
  endelse

endelse

if n_elements(dim) eq 2 then begin

  grad = dindgen([dim,2])

  grad[*,*,0] = gradx
  grad[*,*,1] = grady

  xidx = indgen(dim[0]*dim[1]) mod dim[0]
  yidx = indgen(dim[0]*dim[1]) / dim[0]

  xout = xc + xoff
  yout = yc + yoff

  xarr = xout[xidx]
  yarr = yout[yidx]
  
  xout = xout[0:dim[0]-1]
  yout = yout[0:dim[1]-1]

  xy = [[xarr],[yarr]]

  dxy = reform(grad,dim[0]*dim[1],2)

endif else begin

  grad = dindgen([dim,3])

  grad[*,*,*,0] = gradx
  grad[*,*,*,1] = grady
  grad[*,*,*,2] = gradz

  xidx = indgen(dim[0]*dim[1]*dim[2]) mod dim[0]
  yidx = (indgen(dim[0]*dim[1]*dim[2]) / dim[0]) mod dim[1]
  zidx = (indgen(dim[0]*dim[1]*dim[2]) / dim[0]) / dim[1]

  xout = xc + xoff
  yout = yc + yoff
  zout = zc + zoff

  xarr = xout[xidx]
  yarr = yout[yidx]
  zarr = zout[zidx]
  
  xout = xout[0:dim[0]-1]
  yout = yout[0:dim[1]-1]
  zout = zout[0:dim[2]-1]

  xy = [[xarr],[yarr],[zarr]]

  dxy = reform(grad,dim[0]*dim[1]*dim[2],3)

endelse

end
