function hanning_stretch, npoints, edgepoints

    if npoints lt 6L then begin
        message,'Array size too small, returning...',/continue
        return,0
	endif

	if 2L*edgepoints ge npoints-1L then begin
		message,'Number of points for windowed edge is too large for the specified ' + $
				'array size; returning unstretched Hanning window...',/continue
		edgepoints=npoints/2L-2L
	endif

	middle=dindgen(npoints-2L*edgepoints-1L)
	middle[*]=1.

	hann=0.5*(1.-cos(!dpi*dindgen(2L*edgepoints)/edgepoints))
	left=hann[0:edgepoints-1L]
	right=[hann[edgepoints:2L*edgepoints-1L],0.d]

	windowarray=[left,middle,right]
	return,windowarray

end
