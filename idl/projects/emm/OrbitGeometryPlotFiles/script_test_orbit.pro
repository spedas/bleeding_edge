fileroot = 'test'
Time = '2015-06-25/13:00:00'
  

.r mvn_orbproj_panel_brain
.r overlay
.r mvn_threed_projection_panel_brain
.r mvn_orbit_survey_plot_ephemeris

mvn_orbit_survey_plot_ephemeris, time, fileroot,/Crustalfields,/screen

