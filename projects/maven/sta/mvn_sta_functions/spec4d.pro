	
;+
;PROCEDURE: spec4d,data
;   Plots 3d data as energy spectra.
;INPUTS:
;   data   - 3d data structure filled by themis routines get_th?_p???
;KEYWORDS:
;   LIMITS - A structure containing limits and display options.
;             see: "options", "xlim" and "ylim", to change limits
;   UNITS  - convert to given data units before plotting
;   COLOR  - array of colors to be used for each bin
;   BINS   - array of bins to be plotted  (see "edit3dbins" to change)
;   OVERPLOT  - Overplots last plot if set.
;   LABEL  - Puts bin labels on the plot if set.
;
;See "plot3d" for another means of plotting data.
;See "conv_units" to change units.
;See "time_stamp" to turn time stamping on and off.
;
;
;CREATED BY:	Davin Larson  June 1995
;FILE:  spec4d.pro
;VERSION 1.25
;MODIFICATIONS: 
;	09-05-24	mcfadden	keyword 'sec' added to plot internal secondary spectra
;	14-01-10	mcfadden	modified to accept mass dimension
;-
pro spec4d,tempdat,   $
  LIMITS = limits, $
  UNITS = units,   $         ; obsolete.  Use units function 
  COLOR = col,     $
  BDIR = bdir,     $
  PHI = phi,       $
  THETA = theta,   $
  PITCHANGLE = pang,   $
  VECTOR = vec,    $
  SUNDIR = sundir, $
  a_color = a_color, $
  LABEL = label,   $
  xdat = xdat, $
  ydat = ydat, $
  dydat = dydat, $
  BINS = bins,     $
  VELOCITY = vel, $
  mbin = mbin, $
  OVERPLOT = oplot,sec = sec,pot = pot,title=title
;@wind_com.pro

if size(/type,tempdat) ne 8 or tempdat.valid eq 0 then begin
  print,'Invalid Data'
  return
endif

if ndimen(tempdat.data) eq 3 then begin

	if not keyword_set(mbin) then mbin=0

	tmp = tempdat
	tmp.gf[*,*,0] = tmp.gf[*,*,mbin-1]
	tmp.eff[*,*,0] = tmp.eff[*,*,mbin-1]
	tmp.mass_arr[*,*,0] = tmp.mass_arr[*,*,mbin-1]
	tmp.tof_arr[*,*,0] = tmp.tof_arr[*,*,mbin-1]
	tmp.bkg[*,*,0] = tmp.bkg[*,*,mbin-1]
	tmp.data[*,*,0] = tmp.data[*,*,mbin-1]

	spec3d,tmp,   $
  		LIMITS = limits, $
  		UNITS = units,   $         ; obsolete.  Use units function 
  		COLOR = col,     $
  		BDIR = bdir,     $
  		PHI = phi,       $
  		THETA = theta,   $
  		PITCHANGLE = pang,   $
  		VECTOR = vec,    $
  		SUNDIR = sundir, $
  		a_color = a_color, $
  		LABEL = label,   $
  		xdat = xdat, $
  		ydat = ydat, $
  		dydat = dydat, $
  		BINS = bins,     $
  		VELOCITY = vel, $
  		OVERPLOT = oplot,sec = sec,pot = pot,title=title

if not keyword_set(mbin) then begin

    for i=1,tempdat.nmass-1 do begin
	tmp = tempdat
	tmp.gf[*,*,0] = tmp.gf[*,*,i]
	tmp.eff[*,*,0] = tmp.eff[*,*,i]
	tmp.mass_arr[*,*,0] = tmp.mass_arr[*,*,i]
	tmp.tof_arr[*,*,0] = tmp.tof_arr[*,*,i]
	tmp.bkg[*,*,0] = tmp.bkg[*,*,i]
	tmp.data[*,*,0] = tmp.data[*,*,i]
	spec3d,tmp,   $
  		UNITS = units,   $         ; obsolete.  Use units function 
  		COLOR = col,     $
  		BDIR = bdir,     $
  		PHI = phi,       $
  		THETA = theta,   $
  		PITCHANGLE = pang,   $
  		VECTOR = vec,    $
  		SUNDIR = sundir, $
  		a_color = a_color, $
  		LABEL = label,   $
  		xdat = xdat, $
  		ydat = ydat, $
  		dydat = dydat, $
  		BINS = bins,     $
  		VELOCITY = vel, $
  		OVERPLOT = 1
    endfor

endif
endif

end
