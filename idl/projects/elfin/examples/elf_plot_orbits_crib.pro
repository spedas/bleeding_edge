;
; CRIB: elf_plot_orbits_crib
;
; Shows how to create orbit plots. Various plots can be produced including
; GEO, GEO Hi Resolution, SM (ELFIN A plotted on top of B, and vs versa), and 
; SM Hi resolution. The above plots can be created for either Northern or 
; Southern hemisphere
; 
; Note: Daily orbit plots are displayed for each hour with a duration of
;       90 minutes each (90 min ~orbital period). For any given  
;       orbit plot type 24 plots are created. If all plot types are requested
;       144 plots will be created. If both Northern and Southern hemisphere
;       are requested the total daily count of orbit plots is 288.
;       
;       Due to the complex algorithms used to create the plots and the number
;       of plots created this process can take from 5-20 minutes depending on
;       the plots requested
;
;       USE the keyword quick_trace to reduce calculation times (this reduces 
;       the resolution of data when calculating IGRF)
; 
; NOTES: To run this crib sheet you will need to first compile aacgmidl
;              IDL >  .compile aacgmidl 
;        You can also check aacgmidl routines
;              IDL > aacgm_example
;          or  IDL > aacgm_plot 
;
;**********************************************
;       
; First release: 2020/11/23
;
pro elf_plot_orbits_crib
  ;
  elf_init
  ;
  ; Set up the day to create plots for
  tdate='2021-01-01'
  dir_products=!elf.local_data_dir + 'gtrackplots'  ; set up directory for plots
  ;
  ;
  ; To create default plots in Geographic coordinates in the 
  elf_map_state_t96_intervals, tdate, dir_move=dir_products, /quick_trace
  ;
  ;
  print,'*****************************************************************************'
  print,'Plots will have the name dir_products/elf_l2_northtrack_20190928_HH.gif'
  print,'where HH = hour (00, 01, ...22, 23)
  print,'Check dir_products to locate plots and view 
  print,'The plot name uses the prefix elf since it includes both probes'
  print,'*****************************************************************************'
  stop
  ; 
  ; To create SM coordinate plots (ELFIN A will be plotted on top of ELFIN B)
  elf_map_state_t96_intervals, tdate, dir_move=dir_products, /sm, /quick_trace
  print,'*****************************************************************************'
  print,'Plots will have the name dir_products/ela_l2_northtrack_sm_20190928_HH.gif'
  print,'In this case the plot name uses the prefix ela since ELFIN A is displayed on top'
  print,'*****************************************************************************'
  stop
  ;
  ; To create hi resolution plots
  elf_map_state_t96_intervals,tdate,dir_move=dir_products, /hires, /quick_trace
  print,'*****************************************************************************'
  print,'Plots will have the name dir_products/ela_l2_northtrack_20190928_HH_hires.gif'
  print,'*****************************************************************************'
  stop
  ; 
  ;
  ; To create southern hemisphere plots in SM coordinates
  elf_map_state_t96_intervals,tdate,dir_move=dir_products, /south, /sm, /quick_trace
  print,'*****************************************************************************'
  print,'Plots will have the name dir_products/ela_l2_southtrack_sm_20190928_HH.gif'
  print,'*****************************************************************************'
  stop
  ; 
  ;
  ; To create southern hemisphere plots in SM coordinates with ELfIN B displayed
  ; on top of ELFIN A
  elf_map_state_t96_intervals,tdate,dir_move=dir_products, /south, /sm, /bfirst, /hires, /quick_trace  
  print,'*****************************************************************************'
  print,'Plots will have the name dir_products/elb_l2_southtrack_sm_20190928_HH_hires.gif'
  print,'NOTE: the keyword bfirst is only relevant when requesting SM coordinates'
  print,'When using the keyword bfirst the plot name will use elb
  print,'*****************************************************************************'
  stop    
  ;
end