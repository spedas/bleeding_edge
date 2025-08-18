; NOTE, this test was done in air at 75F.

power_supply_voltage =  $
  [22, 22,  24, 24,  26, 26, 28, 28,  28, 30, 30,  32.0,  32.0]
ndata = n_elements(Power_supply_voltage)
open_duration =  [694,  707,  503,  528,  391,  394,  325,  324,  324,  271,  272,  233,  232]
close_duration =  [622,  622,  423,  425,  378,  378,  317,  314,  313,  265,  263,  227,  227]

factor_Sma_power_supply_voltage =  8.9

;Plotset
!P.charsize =  1.7
;popen,  'Attenuator_stroke_duration'
Plot,  power_supply_voltage,  Open_duration,  psy =  -4, Xr =  [20,  35],  $
  xtit =  'power supply voltage',ytit =  'Duration of Stroke, ms',  $
  title =  'Attenuator stroke in Air, 24C'
oplot,  power_supply_voltage,  close_duration,  psy =  -4,  Color =  6
xyouts, 26,  600,  'Close',  charsize =  1.0
xyouts,  24,  300,  'Open',  charsize =  1.0,  color =  6
Plot,  power_supply_voltage/8.89,  Open_duration,  psy =  -4, $
  Xr =  [2.0, 4.0],  $
  xtit =  'SMA voltage',ytit =  'Duration of Stroke, ms',  $
  title =  'Attenuator stroke in Air, 24C'
oplot,  power_supply_voltage/8.89,  close_duration,  psy =  -4,  Color =  6
xyouts, 2.6,  600,  'Close',  charsize =  1.0
xyouts,  2.4,  300,  'Open',  charsize =  1.0,  color =  6
pclose

;this test was done in the B20 vacuum chamber on March 3, 2011
.r read_attenuator_test_file
voltage_loop =  [28,  30,  32,  34,  36,  34,  32,  30,  28,  26,  $
                 24,  22,  24,  26,  28]
nv =n_elements (voltage_loop)
voltage_loop =  [voltage_loop,  voltage_loop,  voltage_loop]
voltage_ext = [28,  30,  32,  34,  36,  34,  32,  30,  28,  26,  $
               24,  22, 20, 18, 16, 15, 16, 18, 20, 22, 24,  26,  28]
; test done a vacuum chamber
read_attenuator_test_file,  file = '/disks/data/maven/sep/prelaunch_tests/EM1/20110303_181746_attn_vacchamber_vacuum_volttest/actVoltTest_20110303_181746.dat',  durationa =  durationa_vacuum,  durationb =  durationb_vacuum

read_attenuator_test_file,  file = '/disks/data/maven/sep/prelaunch_tests/EM1/20110401_160622_atten_volttest_below_22v/actVoltTest_20110401_160622.dat',  durationa =  durationa_vacuum_ext,  durationb =  durationb_vacuum_ext


; test done in vacuum chamber with no vacuum
read_attenuator_test_file,  file = '/disks/data/maven/sep/prelaunch_tests/EM1/20110303_162211_attn_vac_1bar/actVoltTest_20110303_162211.dat',  durationa =  durationa_1bar,  durationb =  durationb_1bar
plotset
!p.multi =  [0,  1,  2]
!p.Charsize =  1.3
popen,  'comparison_SEP_ETU_attenuator_stroke_duration_vs_voltage_vacuum_air'

plot, findgen (3*nv) +1,  durationa_vacuum,  $
  yr =  [100,  820], ytitle = 'Stroke Duration, ms', ysty =  9,  $
  xtit =  'Number of actuations',  xmargin =  [8,  6],  $
  title =  'Stroke duration in air (dashed) and vacuum (solid)'
oplot, findgen (3*nv) +1,  durationb_vacuum, color =  2
oplot, findgen (nv) +1,  durationa_1bar, line =  1
oplot, findgen (nv) +1,  durationb_1bar, color =  2,  line =  1

oplot_different_axis, findgen (3*nv) +1,  voltage_loop,  yr =  [20,  36],  $
  ytitle =  'Bus Voltage, V', color =  6
xyouts, 21, 680, 'Attenuator open stroke',charsize =  1.0
xyouts,  21, 630,'Attenuator close stroke',  charsize =  1.0,  $
  color =  2

Plot,  voltage_loop,  durationa_vacuum,  psy =  -4,  $
  xtit = '"Bus" Voltage',  ytit =  'Stroke Duration, ms', $
  yr =  [100,  820], /ysty, xr = [14, 36], /xsty
oplot, voltage_ext, durationa_vacuum_ext, psy = -4
oplot, voltage_ext, durationb_vacuum_ext, psy = -4, color = 2

oPlot,  voltage_loop[0:14],  durationa_1bar,  psy =  -4, line =  1
oPlot,  voltage_loop,  durationb_vacuum,  psy = -2,color =  2
oPlot,  voltage_loop[0:14],  durationb_1bar,  psy =  -2, line =  1, color =  2
xyouts, 27, 680, 'Attenuator open stroke',charsize =  1.0
xyouts,  27, 630,'Attenuator close stroke',  charsize =  1.0,  $
  color =  2
pclose

make_JPEG,  'comparison_SEP_ETU_attenuator_stroke_duration_vs_voltage_vacuum_air.jpg'



; another way to  plot this is to plot duration and voltage on the
; Y. axis separately


oplot, 






