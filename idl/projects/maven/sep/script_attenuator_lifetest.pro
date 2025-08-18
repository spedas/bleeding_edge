; this is the first life test of the SEP attenuator in vacuum in the vacuum chamber,
; conducted March 5, 2011.
.r read_attenuator_test_file
!p.charsize =  1.1
!p.multi =  [0,  1,  1]
;popen,  'open_close_durations_20110304_vacuum_life_test'
read_attenuator_test_file,  file = '/disks/data/maven/sep/prelaunch_tests/EM1/20110305_000142_attenuator_lifecycle_vac/actTest_temp.dat',  durationa =  durationa_vacuum_1,  durationb =  durationb_vacuum_1
read_attenuator_test_file,  file = '/disks/data/maven/sep/prelaunch_tests/EM1/20110309_230855_attenuator_lifecycle_vac/actTest_temp.dat',  $
durationa =  durationa_vacuum_2,  durationb =  durationb_vacuum_2

read_attenuator_test_file,  file = '/disks/data/maven/sep/prelaunch_tests/EM1/20110328_171723_atten_vac_lifetest/actTest_temp.dat',  $
durationa =  durationa_vacuum_3,  durationb =  durationb_vacuum_3

Total_durationa =  [durationa_vacuum_1,  durationa_vacuum_2, $
                    durationa_vacuum_3]
Total_durationb =  [durationb_vacuum_1,  durationb_vacuum_2, $
                    durationb_vacuum_3]
good =  where (total_durationa ne total_durationb and $
               total_durationa ne 0 and $
              total_durationb ne 0)
total_durationa =  total_durationa [good]
total_durationb =  total_durationb [good]

;popen, 'SEP_EM1_3_attenuator_life_tests_March_2011'
!p.charsize =  1.7
plot,  total_durationa,  yr =  [220,  300], /ysty,  thick =  1,  $
  xtit =  '# of actuations',  ytit =  'Duration of Stroke, ms',  $
  title =  'Life test at 28 V Bus Voltage'
oplot,  total_durationb,  color =  2,  thick =  1
xyouts,  900,  255,  'March 3-4',  charsize =  2.0,align =  0.5
xyouts,  2600,  255,  'March 9-10',  charsize = 2.0,align =  0.5
xyouts,  3700,  255,  'March 28-29',  charsize =  2.0,align =  0.5
xyouts,  1200,  235,  'Opening stroke',  charsize =  1.8,align =  0.5
xyouts,  1200,  225,  'Closing stroke', charsize =  1.8,align =  0.5,  $
  color =  2
make_JPEG,  'SEP_EM1_3_attenuator_life_tests_March_2011.jpg'


;
!p.charsize =  1.1
!p.multi =  [0,  1,  2]
popen,  'open_close_durations_20110309_vacuum_life_test'
pclose




 
