;
; CRIB: elf_plot_orbits_mercator_crib
;
; Shows how to create mercator orbit plots. Various plots can be produced for
; both mercator and conjugate_mercator
;
; Note: Daily orbit plots are displayed for each hour with a duration of
;       90 minutes each (90 min ~orbital period). For any given
;       orbit plot type 24 plots are created. If all plot types (regular or 
;       conjugate) are requested 48 plots will be created. 
;
;       Due to the complex algorithms used to create the plots and the number
;       of plots created this process a few minutes 
;
;       USE the keyword quick_trace to reduce calculation times (this reduces
;       the resolution of data when calculating IGRF)
;
; SPECIAL NOTE: Currently the mercator plots can only be generated on windows machines. 
; 
; First release: 2020/11/23
;
pro elf_plot_orbits_mercator_crib
  ;
  elf_init
  ;
  ; Set up the day to create plots for
  tdate='2021-01-01'
  dir_products=!elf.local_data_dir + 'gtrackplots'  ; set up directory for plots
  ;
  ;
  ; To create default mercator plots in Geographic coordinates
  elf_map_state_t96_intervals_mercator, tdate, dir_move=dir_products, /quick_trace
  ;
  ;
  print,'*****************************************************************************'
  print,'Plots will have the name dir_products/elf_l2_mercator_20190928_HH.gif'
  print,'where HH = hour (00, 01, ...22, 23)
  print,'Check dir_products to locate plots and view
  print,'The plot name uses the prefix elf since it includes both probes'
  print,'It is highly recommended the /quick_trace keyword be used to reduce the'
  print,'   calculation time.'
  print,'*****************************************************************************'
  stop
  ;
  ; To create mercator conjugate orbit plots
  elf_map_state_t96_intervals_conjugate, tdate, dir_move=dir_products, /quick_trace
  print,'*****************************************************************************'
  print,'Plots will have the name dir_products/ela_l2_mercator_conjugate_20190928_HH.gif'
  print,'*****************************************************************************'
  stop
  ;
end