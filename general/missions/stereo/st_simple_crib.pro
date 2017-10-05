pro  st_simple_crib


@idl_startup


timespan,'7-11-19',2,/days  ;
;timespan,'6 11 17',2,/days

; WIND DATA:

wi_3dp_load                               ; Loads WIND 3DP K0 data into memory
wi_3dp_load,datatype='pm'                 ; Loads WIND 3DP spin res moment data into memory

wi_3dp_load,datatype='elpd_old'                ; Loads WIND 3DP PAD data into memory
reduce_pads,'wi_3dp_elpd_FLUX',1,5,5      ; Reduces 3d data to 2d spectrogram (5th energy step)


wi_mfi_load                               ;  Loads WIND 3 second res MAG data

tplot,'wi_h0_mfi_B3GSE wi_3dp_pm_P_VELS wi_3dp_elpd_FLUX-1-?:?'

wait, 10                                  ; wait 10 seconds
tlimit,'2007-11-20/11:30','2007-11-20/12:10

wait, 15                                  ; wait 15 seconds

tlimit,/full             ; return to full time limits
;  STEREO DATA

st_mag_load
st_swea_load    ;         Loads STEREO SWEA data

tplot,'sta_B_RTN sta_s stb_B_RTN stb_s'

st_part_moments,/get_pads,probe='a'  ; compute pads for ahead spacecraft
st_part_moments,/get_pads,probe='b'  ; compute pads for behind spacecraft

tplot,/add,'sta_SWEA_pad stb_SWEA_pad'

; ACE data

ace_mfi_load,datatype='h0'
ace_swe_load, datatype='h0'





;General tplot commands:


tplot_names          ; Displays a list of currently loaded tplot variables

tplot                ; Replots the last variables.

tlimit,/full         ; Plot the full time range.
tlimit               ; Interactively select time limits




end
