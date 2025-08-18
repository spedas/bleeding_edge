;FGM demonstration script by Patrick Cruce


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print, "Hello World!"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
print, 'At any stop statement press .c to continue'
 
;set the timespan
timespan, '2007-3-23', 1

doc_library, 'thm_load_fgm'

stop

;load some data
thm_load_fgm, probe = 'b c', level = 'l2'

;print variable names
tplot_names

stop

;plot a data quantity
tplot, 'thb_fgs_dsl'

stop

;change plot title
tplot_options, 'title', 'THEMIS SciSoft Examples'

;load state data for probe b
thm_load_state, probe = 'b'

;plot some more 
tplot, 'thb_fgs_dsl thb_state_pos'

tplot_names

stop

;get rid of data, demonstrate use of wildcard
del_data, '*_dsl'

;now load data in gsm coordinate system
thm_load_fgm,datatype='fgs',probe='b',coord='gsm', level = 'l2'
 
;transform state data into gsm coordinates
thm_cotrans, 'thb_state_pos', 'thb_state_pos_gsm', out_coord = 'gsm'

tplot_names

stop

;plot position data in 3 different yet similiar coordinate systems
tplot, 'thb_state_pos*'

;zoom in
tlimit,'2007-03-23/16:00:00','2007-03-23/20:00:00'

stop

;generate magnitude variables
xyz_to_polar, 'thb_state_pos_gsm'

xyz_to_polar, 'thb_fgs_gsm'

;plot field strength versus earth distance
tplot,['thb_state_pos_gsm_mag','thb_fgs_gsm_mag']

print, 'Call "tlimit" with no arguments to zoom in using the cursor'

stop

;zoom out
tlimit,'2007-03-23/00:00:00','2007-03-23/24:00:00'

stop

;get direct access to state data
get_data, 'thb_state_pos_gsm_mag', data = d

;heres what the struct looks like
help, /str, d

stop

;manually turn data from km to earth radii
d.y = d.y/6374

;store in new tplot variabel
store_data, 'thb_state_pos_gsm_mag_re', data = d

;note that conversion to RE can be done in a single step as well

del_data,'thb_state_pos_gsm_re'

tKm2Re,'thb_state_pos_gsm_mag'

;plot magnitometer data
tplot, 'thb_fgs_gsm_mag'

;add radius label
tplot, var_label = 'thb_state_pos_gsm_mag_re'

stop

;print current working directory
cwd

;change current working directory(example this command does nothing)
cwd, '.'

stop

;export to png
makepng

;export to gif
makegif,'demo'

;export to postscript
popen,'demo2'

tplot

pclose

;export variable data to ascii
tplot_ascii, 'thb_fgs_gsm_mag'

stop

;look in more detail at magnetometer struct
get_data, 'thb_fgs_gsm', data = d, dlimits = dl

help, /str, d
help, /str, dl
help, /str, dl.data_att
print, dl.data_att.coord_sys

stop

end


