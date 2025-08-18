; This is a crib sheet showing how to use mvn_orb_ql,
; which will make a multipanel plot containing
; three Cartesian MSO plots, a cylindrical MSO plot,
; a 3D projection of the orbit plane, and the ground track
; for a given orbit or set of orbits in a day.


; Load a day
timespan, '2023 12 9'

; Makes a plot in the main window for each orbit
; Hit enter while running to skip to next orbit
; cntrl-alt-del to escape
mvn_orb_ql

; Uses the Z device to save a plot
; can save plot to a location if supply keyword
; savedir, (e.g. savedir='~/Desktop')
mvn_orb_ql, /saveplot

; Makes a plot of a specific orbit
mvn_orb_ql, orb=870

; Plot a specific time, with a marker where the s/c is
; (centers the spacecraft trace over [-0.5, 0.5] the 
; concurrent orbit time)
mvn_orb_ql, tstring='2017 9 10 14:00', /plot_sc_position
