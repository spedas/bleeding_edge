;COMMON BLOCK:  xtplot_com
common xtplot_com, xtplot_base, $; base ID
                   xtplot_routine_name, $; routine name to be called after each mouse-event (obsolete)
                   xtplot_right_click, $; right click event enabled? 1 for Yes, 0 for No
                   xtplot_pcsrA, $; csrA point 
                   xtplot_tcsrA, $; csrA time (in double)
                   xtplot_vnameA,$; csrA variable name in which point and time are defined
                   xtplot_pcsrB, xtplot_tcsrB, xtplot_vnameB, $
                   xtplot_var1,  $; storage. Any number of variables can be stored if you use
                   xtplot_var2,  $; structures.
                   xtplot_var3
