;
; CRIB: elf_summary_plot_crib
; 
; Shows how to create summary or overview plots. 
; Notes: Daily summary plots are created for each hour with a duration of
;        90 minutes each (90 min ~orbital period). Summary plots can be 
;        created for ELFiN A or ELFIN B 
;        
;        If science collections were conducted an overview plots is created
;        for the duration of each science zone. Science zones include
;        NASC, NDES, SDES, SASC for North Ascending, North Descending, 
;        South Descending and South Ascending zones respectively.
;        
;        File naming conventions for hourly plots are:
;          !elf.local_data_dir/elfin/ela/overplots/yyyy/mm/dd/ela_l2_overview_yyyymmdd_hh.gif
;        
;        File naming conventions for science zone plots are:
;          !elf.local_data_dir/elfin/elb/overplots/yyyy/mm/dd/elb_l2_overview_yyyymmdd_hh_szsz.gif
;          where szsz=science zone name
;  
;  Notes: To create a single science zone plot you can use the routine epde_plot_overviews_solo
;       
; First release: 2020/11/23
;
pro elf_summary_plot_crib
  ;
  elf_init
  ;
  ; Set up the day to create plots for
  tdate='2022-01-06'
  ;
  ; elf plot multispec_overviews is a wrapper around the main plot routine
  ; epde_plot_overviews.pro 

  ; PLOT ELFIN A
  elf_plot_multispec_overviews, tdate,  probe='a', /quick_run
  print,'*****************************************************************************'
  print,'Plots will have the name '
  print,'!elf.local_data_dir/elfin/ela/overplots/2020/09/28/ela_l2_overview_20190928_hh.gif;
  print,'where HH = hour (00, 01, ...22, 23)
  print,'Check dir_products to locate plots and view
  print,'The keyword quick_run is used to reduce the calculation time by reducing the
  print,'resolution of the data when calculating IGRF.'
  print,'*****************************************************************************'
  stop

  ; PLOT ELFIN b
  tdate='2020-11-01'
  elf_plot_multispec_overviews, tdate,  probe='b', /quick_run
  print,'*****************************************************************************'
  print,'Plots will have the name '
  print,'!elf.local_data_dir/elfin/elb/overplots/2020/09/28/elb_l2_overview_20190928_hh.gif;
  print,'where HH = hour (00, 01, ...22, 23)
  print,'*****************************************************************************'
  stop

  ; PLOT ELFIN a single science zone
  trange = ['2022-03-22/05:19','2022-03-22/05:27']
  epde_plot_overviews_solo, trange=trange,  probe='a', /quick_run
  print,'*****************************************************************************'
  print,'Plots will have the name '
  print,'!elf.local_data_dir/elfin/elb/overplots/2020/09/28/elb_l2_overview_20190928_scizone.gif;
  print,'where scizone = [nasc, ndes, sasc, sdes]
  print,'*****************************************************************************'
  stop

end