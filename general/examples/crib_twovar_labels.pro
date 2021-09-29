;This crib demonstrates the twovars option, the allows for two
;variables to be printed at the bottom of a tplot using the var_label
;keyword. To be invoked, the var_label keyword must
;be set up with a valid tplot variable name in parentheses after a
;valid tplot variable.

;Plot FGM data, with GSE and GEI position as var_labels

timespan, '2012-03-07'
del_data, '*'
thm_load_fgm, probe='a', level='l2', coord = 'gse'
thm_load_state, probe='a', coord = 'gse',  suffix = '_gse'
thm_load_state, probe='a', coord = 'gei',  suffix = '_gei'

;Split up the vectors, and plot each separately

split_vec, 'tha_state_pos_gse'
split_vec, 'tha_state_pos_gei'
;The ytitles show up on the left
options, 'tha_state_pos_gse_x', 'ytitle', 'GSE_X'
options, 'tha_state_pos_gse_y', 'ytitle', 'GSE_Y'
options, 'tha_state_pos_gse_z', 'ytitle', 'GSE_Z'
options, 'tha_state_pos_gei_x', 'ytitle', 'GEI_X'
options, 'tha_state_pos_gei_y', 'ytitle', 'GEI_Y'
options, 'tha_state_pos_gei_z', 'ytitle', 'GEI_Z'

;different formats can be used for different variables, 
options, 'tha_state_pos_gse_?', 'format', '(1E8.1)'
options, 'tha_state_pos_gei_?', 'format', '(1F8.1)'

;first GSE only,
print, 'PLOTTING WITH SINGLE VARIABLES PER LINE'
tplot, ['tha_fgs_gse', 'tha_fgs_btotal'], $
      var_label = ['tha_state_pos_gse_z', $
                   'tha_state_pos_gse_y', $
                   'tha_state_pos_gse_x']
stop

;invoke the double variable option by adding a second variable in
;parentheses after the first, both will show up, with the appropriate
;formats. In order to fit labels, the first values are not printed.
print, 'PLOTTING WITH TWO VARIABLES PER LINE'
tplot, ['tha_fgs_gse', 'tha_fgs_btotal'], $
       var_label = ['tha_state_pos_gse_z(tha_state_pos_gei_z)', $
                    'tha_state_pos_gse_y(tha_state_pos_gei_y)', $
                    'tha_state_pos_gse_x(tha_state_pos_gei_x)']

stop
;Vector variables can also be used, but the two variables must have
;the same number of components. (Do not combine vector and scalar
;variables, or pressure tensors with fields, etc...).
;Note that array values for ytitle are used here, it is not
;recommended to do this if the variables are
;going to be plotted, but it will work here.
options, 'tha_state_pos_gse', 'ytitle', 'GSE_'+['X','Y','Z']
options, 'tha_state_pos_gei', 'ytitle', 'GEI_'+['X','Y','Z']

;note also that the var_label must be passed in as an array of
;strings, even if there is only one pair of variables.
;no globbing
print, 'PLOTTING WITH TWO VECTOR VARIABLES'
tplot, ['tha_fgs_gse', 'tha_fgs_btotal'], $
       var_label = ['tha_state_pos_gse(tha_state_pos_gei)']

stop

;All of the var_labels do not have to have two variables:
options, 'tha_fgs_btotal', 'ytitle', 'FGS_BTOT'
print, 'PLOTTING WITH SINGLE AND DOUBLE VARIABLES'
tplot, 'tha_fgs_gse', $
       var_label = ['tha_fgs_btotal','tha_state_pos_gse(tha_state_pos_gei)']


stop
;To clear labels, set var_label = 0
print, 'PLOTTING WITH NO VARIABLES'
tplot, var_label = 0

End


