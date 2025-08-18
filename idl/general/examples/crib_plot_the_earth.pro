PRO crib_plot_the_earth

  ; some test figure
  y=[10:-10:-0.1]
  x=(y^2)/10 - 5
  p = PLOT(x, y, POSITION = [0.1, 0.1, 0.9, 0.9], XRANGE = [-10, 10], YRANGE=[-10, 10])

  ; plot default earth
  PLOT_THE_EARTH, 0, 0, 1, 0, 'k', 'black', 16

END