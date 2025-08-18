;+
; PROCEDURE mplot_downsample_data, max_points, x, y
;
; PURPOSE:
;
;   Enables fast plotting of time series plots with many elements. 
;   
;   This function is intended for use when plotting time series plots using
;   MPLOT.  When n_elements >> number of pixels on the screen, the large number
;   of points slows down plotting considerably without adding any visual
;   information to the final plot.
;   
;   This procedure groups the data into regularly spaced time intervals.  If 
;   MAX_POINTS is set correctly (see below), each interval is less than a pixel
;   in the plot.  The procedure finds the minimum and maximum value of the 
;   time series in that interval, and constructs a new time series from the 
;   minima and maxima.  The new series has many fewer points than the original
;   (and therefore the plotting runs much faster), but the resulting plot is 
;   nearly visually identical to the full time series plot.
;   
;   If the number of input points is smaller than MAX_POINTS, the function does
;   nothing.
;   
;   This should not be used as a 'real' downsampling procedure to make a new
;   time series that can be used for calculations at a reduced cadence--use 
;   only for plotting.
;   
;   Works best with regularly spaced data that is plotted without a plot 
;   symbol set.
;
; INPUT:
;    
;    MAX_POINTS: The maximum number of points in the downsampled array.
;     Set to a number that is several times larger than the maximum pixel
;     width of the plot window (something like 10000 gives more than enough
;     points for nearly any display, and plots nearly instantly).  If the
;     number of input points is smaller than max_points, the function does
;     nothing.
;     For TPLOT variables, set 'max_points' using the OPTIONS procedure.
;    X: The time array.
;    Y: The data array.
;
; KEYWORDS:
;
;    DY: Optional uncertainty in y.
;    
; CREATED BY:
; 
;   pulupa
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2021-07-06 16:49:05 -0700 (Tue, 06 Jul 2021) $
; $LastChangedRevision: 30102 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/mplot_downsample_data.pro $
;-

pro mplot_downsample_data, max_points, x, y, dy = dy, dg = dg

  if n_elements(x) LE max_points then return

  xr = !X.crange

  plot_hist = histogram(x, min = xr[0], max = xr[1], nbins = max_points/2, $
    rev = rev, $
    locations = plot_x0)

  plot_x = []
  plot_y = []
  plot_dy = []

  for i = 0, n_elements(plot_x0) - 1 do begin

    if rev[i] LT rev[i+1] then begin

      xdata_pixel = x[rev[rev[i]:(rev[i+1]-1)]]
      ydata_pixel = y[rev[rev[i]:(rev[i+1]-1)],*]

      if keyword_set(dy) then dydata_pixel = dy[rev[rev[i]:(rev[i+1]-1)]]

      min_y = min(ydata_pixel, min_ind, dim = 1)
      max_y = max(ydata_pixel, max_ind, dim = 1)
      
      if xdata_pixel[min_ind[0]] LT xdata_pixel[max_ind[0]] then begin

        plot_y = [[plot_y], [ydata_pixel[min_ind]], [ydata_pixel[max_ind]]]

        if keyword_set(dy) then $
          plot_dy = [plot_dy, dydata_pixel[min_ind], dydata_pixel[max_ind]]

        plot_x = [plot_x, xdata_pixel[min_ind[0]], xdata_pixel[max_ind[0]]]

      endif else begin

        plot_y = [[plot_y], [ydata_pixel[max_ind]], [ydata_pixel[min_ind]]]

        if keyword_set(dy) then $
          plot_dy = [plot_dy, dydata_pixel[max_ind], dydata_pixel[min_ind]]

        plot_x = [plot_x, xdata_pixel[max_ind[0]], xdata_pixel[min_ind[0]]]

      endelse

    end

  endfor

  if ndimen(plot_y) GT 1 then plot_y = transpose(plot_y)

  x = plot_x
  y = plot_y
  if keyword_set(dy) then dy = plot_dy
  
  if keyword_set(dg) then makegap,dg,x,y,dy=dy

end