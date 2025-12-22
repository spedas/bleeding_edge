Function fa_dsp_process_varnames
;Variable list for DSP, sdt dqd, then tplot_name
a = ['DspADC_Mag3ac fa_dspadc_mag3ac', $
     'DspADC_Ne2 fa_dspadc_ne2', $
     'DspADC_Ne3 fa_dspadc_ne3', $
     'DspADC_Ne6 fa_dspadc_ne6', $
     'DspADC_Ne7 fa_dspadc_ne7', $
     'DspADC_V1 fa_dspadc_v1', $
     'DspADC_V2 fa_dspadc_v2', $
     'DspADC_V3 fa_dspadc_v3', $
     'DspADC_V4 fa_dspadc_v4', $
     'DspADC_V5 fa_dspadc_v5', $
     'DspADC_V6 fa_dspadc_v6', $
     'DspADC_V7 fa_dspadc_v7', $
     'DspADC_V8 fa_dspadc_v8', $
     'DspADC_V1-V2 fa_dspadc_e12', $
     'DspADC_V1-V2HG fa_dspadc_e12hg', $
     'DspADC_V1-V4 fa_dspadc_e14', $
     'DspADC_V1-V4HG fa_dspadc_e14hg', $
     'DspADC_V12TRK fa_dspadc_v12trk', $
     'DspADC_V14TRK fa_dspadc_v14trk', $
     'DspADC_V3-V4 fa_dspadc_e34', $
     'DspADC_V3-V4HG fa_dspadc_e34hg', $
     'DspADC_V5-V6 fa_dspadc_e56', $
     'DspADC_V5-V8 fa_dspadc_e58', $
     'DspADC_V5-V8HG fa_dspadc_e58hg', $
     'DspADC_V7-V8  fa_dspadc_e78', $
     'DspADC_V9-V10 fa_dspadc_e910', $
     'DspADC_V910TRK fa_dspadc_v910trk', $
     'DspHSBM_Mag3ac fa_dsphsbm_mag3ac', $
     'DspHSBM_V1-V2 fa_dsphsbm_e12', $
     'DspHSBM_V1-V4 fa_dsphsbm_e14', $
     'DspHSBM_V3-V4 fa_dsphsbm_e34', $
     'DspHSBM_V5-V6 fa_dsphsbm_e56', $
     'DspHSBM_V5-V8 fa_dsphsbm_e58', $
     'DspHSBM_V7-V8 fa_dsphsbm_e78', $
     'DspHSBM_V9-V10 fa_dsphsbm_e910']

na = n_elements(a)
b = strarr(2, na)
For j = 0, na-1 Do b[*, j] = strsplit(a[j], ' ', /extract)

Return, b

End

