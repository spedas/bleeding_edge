;+
;PROCEDURE: thm_crib_tplot_overlay
;
;  ***** A copy and paste crib *****
;
;PURPOSE:
;  A crib showing how to overlay spectra on top of spectra.
;
;DETAILS
;  This crib shows how to combine full and burst mode spectra into one plot by
;  overlaying the burst mode data on top of the full mode data.
;
;  The DATAGAP keyword is very useful when you want to overlay burst mode
;  spectra plots over full mode spectra. Set the DATAGAP keyword to a number
;  of seconds that is less than the time gap of the burst data, but greater than
;  the sample interval of the underlying full mode data.  This way the time gaps
;  between the burst mode data won't be interpolated by SPECPLOT and cover up
;  the full mode data between the burst mode data. 
;
;
;CREATED BY:  Bryan Kerr
;
;-

; Load the data and set DATAGAP keyword to a number of seconds greater than
; highest full mode sample rate in the timspan, about 390 seconds in this case,
; but less than the length of the time gap between burst segments (~44 minutes).

thm_part_getspec, probe=['a'], trange=['07-03-23/10:30','07-03-23/12:40'], $
                  theta=[-90,90], phi=[0,360], data_type=['peif','peib'], $
                  /energy, datagap=400

; Store the data in a tplot pseudovariable.
store_data,'tha_comb',data=['tha_peif_en_eflux','tha_peib_en_eflux']

; Set y- and z-limits so that full and burst data will have same scale
ylim,'th*comb',5,23000 ; set y-axis limits
zlim,'th*comb',10,3e6 ; set all spectra to same color scale
ylim,'tha*eflux',5,23000 ; set y-axis limits for spectra plots
zlim,'tha*eflux',10,3e6 ; set all spectra to same color scale

tplot,'tha_comb' ; plot only the combined spectra

; Plot the full, burst, and combined spectra in separate panels.
;tplot,['tha_peif_en_eflux','tha_peib_en_eflux','tha_comb'] 

end