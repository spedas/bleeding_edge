;+
;	Batch File: THM_CRIB_EXPORT
;
;	Purpose:  Demonstrate tplot export functions
;
;	Calling Sequence:
;	.run thm_crib_export, or using cut-and-paste.
;
;	Arguements:
;   None.
;
;	Notes:
;	None.
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-02-06 18:17:50 -0800 (Fri, 06 Feb 2015) $
; $LastChangedRevision: 16905 $
; $URL $
;-

;------------------------------------------------------------------------------
;Loading FGM into tplot
;------------------------------------------------------------------------------

;your exemplar themis data is magnetometer data
timespan,'2007-03-23'

thm_load_fgm, probe = 'b', level = 'l2'

tplot_options,'title','data_export_example'

print,'The SPEDAS software package stores data in tplot variables by default'

print,'To get a list of available variables type "tplot_names"'

print,'(press .c to continue with crib)'

stop

tplot_names

;------------------------------------------------------------------------------
;Access Data Variables Directly as IDL arrays
;------------------------------------------------------------------------------
print,'The most basic way to "export" data from the scisoft package is to access the data directly'

print,'You can do this by typing "get_data,tplot_var_name,time,data"'

print,'We just did this now'

get_data,'thb_fgs_dsl',time,data

help,/str,time
help,/str,data

print,'(press .c to continue with crib)'

stop

;------------------------------------------------------------------------------
; Make plot
;------------------------------------------------------------------------------

print,'We can export a plot to a file by first plotting the data with the command:'
print,'"tplot,tplot_var_name"'

print,'(You need to do this for makepng,makegif,and makeps)'

tplot,'thb_fgs_dsl'

print,'(press .c to continue with crib)'

stop

;------------------------------------------------------------------------------
;Export to PNG
;------------------------------------------------------------------------------

print,'Now we simply type: "makepng,plotname"'

makepng,'thb_fgs_dsl_plot'

print,'(press .c to continue with crib)'

stop

;------------------------------------------------------------------------------
;Export to GIF
;------------------------------------------------------------------------------
print,'You export data to gif format with the "makegif" function as well'

makegif,'thb_fgs_dsl_plot'

print,'(press .c to continue with crib)'

stop
;------------------------------------------------------------------------------
;Export to postscript(.ps)
;------------------------------------------------------------------------------
print,'You can export to postscript format with the "popen & pclose" procedures'

popen,'thb_fgs_dsl_plot'

tplot

pclose

print,'(press .c to continue with crib)'

stop

;------------------------------------------------------------------------------
;Export to encapsulated postscript(.eps)
;------------------------------------------------------------------------------

print,'You can export to encapsulated postscript format with the /encapsulated keyword'

popen,'thb_fgs_dsl_plot',/encapsulated

tplot

pclose

print,'(press .c to continue with crib)'

stop

;------------------------------------------------------------------------------
;Export to Ascii
;------------------------------------------------------------------------------
print,'We can also export data to an ascii file'

print,'Just type "tplot_ascii,tplot_var_name"'

print,'If you want to add a suffix type "tplot_ascii,tplot_var_name,ext=suffix"'
print,'We can do this now'

tplot_ascii,'thb_fgs_dsl',ext='_20070323'

print,'(press .c to continue with crib)'

stop

;------------------------------------------------------------------------------
;Check current output directory
;------------------------------------------------------------------------------
print,'All files go to your current idl directory by default'

print,'Check your current idl directory by typing "cwd"'

cwd

print,'(press .c to continue with crib)'

stop

;------------------------------------------------------------------------------
;Change current output directory
;------------------------------------------------------------------------------

print,'You can change your current by calling cwd,dirname'

cwd,'.'

print,'(The change directory command above is only an example and does nothing)'
print,'(press .c to continue with crib)'

stop

;------------------------------------------------------------------------------
;save all tplot variables in current session
;------------------------------------------------------------------------------

tplot_save,filename='current'

del_data,'*'

tplot_names

print,'Now the data has been saved to current.tplot and idl tplot variables have been deleted'

print,'(press .c to continue with crib)'

stop
;----------
;--------------------------------------------------------------------
;restore all tplot variables from previous session
;------------------------------------------------------------------------------

tplot_restore,filename='current.tplot'

tplot_names

print,'And now our data is back'

print,'The End'

print,'(press .c to continue with crib)'

stop


;------------------------------------------------------------------------------
;Beautify your plot(see tplot cribs in spedas/general/examples for more detail 
;------------------------------------------------------------------------------

;changing thickness

;You may want to increase line thickness to increase the visibility
;on images that you create.
;To do this you can use 4 keywords.  thick,xthick,ythick,charthick
;thick increases the plot line thickness
;xthick increases the x axis line thickness
;ythick increases the y axis line thickness
;charthick increase the character line thickness
;for a tplot variable you set these keyword with the options command
;for example:


;NOTE: if you were using normal plot these options would be passed to plot as keyword
options,'thb_fgs_dsl',xthick=2.0,ythick=2.0,thick=2.0,charthick=2.0 
popen,'thb_fgs_dsl_plot'

tplot  

pclose

print,'(press .c to continue with crib)'

stop

;------------------------------------------------------------------------------
;export from command line to GUI(need system with windowing support)
;------------------------------------------------------------------------------
tplot_gui,'thb_fgs_dsl' ;note that it imports your increased thickness settings too!


end
