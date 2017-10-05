;+
;	Batch File: THM_CRIB_STATE
;
;	Purpose:  Demonstrate the loading, coordinate transformation,
;	plotting and labeling with state data
;
;	Calling Sequence:
;	.run thm_crib_state, or using cut-and-paste.
;
;	Arguements:
;   None.
;
;	Notes:
;	None.
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-01-05 17:01:57 -0800 (Mon, 05 Jan 2015) $
; $LastChangedRevision: 16596 $
; $URL $
;-

;start with a clean slate
del_data,'*'

timespan,'2007-06-23'

tplot_options,'title','Load State Examples'

;here's how to load some state data
thm_load_state,probe='a'

tplot_names

print,'heres the basic state data for probe a'

stop

tplot,'*'

print,'heres a plot of this data.  Initially the data is in GEI coordinates.'

stop

;now we transform the coordinates

cotrans,'tha_state_pos','tha_state_pos_gse',/gei2gse
cotrans,'tha_state_vel','tha_state_vel_gse',/gei2gse

tplot_names

print,'We just transformed to gse'
print,'Heres a list of our coordinate transformed variables'

stop

tplot,['tha_state_pos_gse','tha_state_vel_gse']

print,'Heres a plot of our coordinate transformed variables'

stop

;translate to polar coords
xyz_to_polar,'tha_state_pos_gse'
xyz_to_polar,'tha_state_vel_gse'

;clean up old variables
del_data,'tha_state_???'
del_data,'tha_state_???_gse'

tplot_names

print,'We just transformed into polar coordinates'
print,'Heres our state data in polar(spherical) coordinates'

stop

tplot,'tha_state_pos_gse_*'

print,'Heres a plot of our position data in spherical coordinates'

stop

print,'Now lets transform the magnitude into earth radii(RE)'

;now we divide it by a scaling factor
;d.x is always time in tplot
;d.y is always your dependent data(in this case magnititude)

get_data,'tha_state_pos_gse_mag',data=d,dlimits=dl

d.y = d.y/6371.2

store_data,'tha_state_pos_gse_mag_re',data=d,dlimits=dl

del_data,'tha_state_pos_gse_mag_re'

;note that this conversion can be done with a single function call as well

tKm2Re,'tha_state_pos_gse_mag'

;last we store the data in a new variable

tplot_names

print,'Now we have a new variable storing the polar magnititude in RE'

stop

tplot,'tha_state_pos_gse_mag_re'

print,'Heres its plot'

stop

;Last we're going to see how to plot this data with some other data

thm_load_fgm,probe='a',datatype='fgs',coord='gse', level = 'l2'

xyz_to_polar,'tha_fgs_gse'

tplot,['tha_fgs_gse_mag','tha_state_pos_gse_mag_re']

print,'Heres the magnititude of the magnetometer vector plotted vs the distance of the spacecraft from earth(in RE)'

stop

tplot,'tha_fgs_gse_mag',var_label='tha_state_pos_gse_mag_re'

print,'Here is a plot with the X Axis Labeled in time and Re'

stop

options,'tha_state_pos_gse_mag_re','ytitle','Distance(RE)'

;because distance won't quite fit in the plot I made it a little wider on
;the left
tplot_options,'xmargin',[15,5]

tplot

print,'Here is the same plot but with a second x label as well'

stop

print,'To get the other quantities from thm_load_state you can make the following call'

thm_load_state,/get_support_data,probe='a'

tplot_names

stop

print,'and we are done'

del_data,'*'

end
