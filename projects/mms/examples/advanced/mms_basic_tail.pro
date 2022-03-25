;+
; script for basic tail science figures (from EVA, first plot)
;
; Plots on the figure include:
;   1: AE
;   2: FGM, srvy, GSM
;   3. FGM Bz
;   4. FGM magnitude
;   5. EDP, -log(scpot)
;   6. FPI density (ion/electron)
;   7. FPI Vi (ion velocity, 3 components)
;   8. (ExB) -> x, y, z
;   9. J total
;   10. EIS protons
;   11. FPI ion spectra
;   12. HPCA O+
;   13. FEEPS intensity
;   14. FPI electron spectra
;   15. EDP X, Y, Z
;   16. EDP HFESP
;   17. DSP BPSD
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2022-03-24 10:01:14 -0700 (Thu, 24 Mar 2022) $
; $LastChangedRevision: 30714 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_basic_tail.pro $
;-

start_time = systime(/sec)

date = '2015-10-16/00:00:00
timespan, date, 1, /day
probe = '1'
; AE options include: 'thm' for THEMIS pseudo AE, 'kyoto' for AE from the WDC at Kyoto
ae_type = 'kyoto'

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows
send_plots_to = 'win'
plot_directory = ''
postscript = send_plots_to eq 'ps' ? 1 : 0

; load the data
if ae_type eq 'thm' then thm_make_ae else kyoto_load_ae
mms_load_fgm, probe=[1, 2, 3, 4], data_rate='srvy', level='l2', /get_fgm_ephem
mms_load_mec, probe=probe, data_rate='srvy', level='l2'
mms_load_fpi, probe=probe, data_rate='fast', level='l2', datatype=['des-moms', 'dis-moms']
mms_load_edp, probe=probe, datatype='scpot', level='l2'
mms_load_edp, probe=probe, data_rate='fast', level='l2', datatype='dce'
mms_load_edp, probe=probe, data_rate='srvy', level='l2', datatype=['dce', 'hfesp']
mms_load_dsp, probe=probe, data_rate='fast', level='l2', datatype='bpsd'
mms_load_hpca, probe=probe, data_rate='srvy', level='l2', datatype='ion'
mms_load_eis, probe=probe, data_rate='srvy', level='l2', datatype='extof'
mms_load_feeps, probe=probe, level='l2', datatype='electron'

; sum the HPCA spectra over the full field of view
mms_hpca_calc_anodes, fov=[0, 360], probe=probe

; split the B-field into its components (so we can plot Bz in its own panel)
split_vec, 'mms'+probe+'_fgm_b_gsm_srvy_l2_bvec'

; join the FPI electron and ion density into a single variable
store_data, 'mms'+probe+'_fpi_combined_density', data= 'mms'+probe+['_des_numberdensity_fast', '_dis_numberdensity_fast']
options, 'mms'+probe+'_fpi_combined_density', labflag=-1

; For the s/c potential, we plot -ln(scpot), to match the plot in EVA
calc, '"mms'+probe+'_edp_fast_scpot_ln" = -ln("mms'+probe+'_edp_scpot_fast_l2")'
; update the Y-axis title
options, 'mms'+probe+'_edp_fast_scpot_ln', ytitle='EDP!CFAST!C-ln(scpot)'

;;;;; The following ExB calculations were taken from EVA, 12/10/2015
; ExB
;------------
sc = 'mms'+strcompress(string(probe), /rem)
vthres = 500.
get_data,sc+'_fgm_b_gse_srvy_l2',data=B
get_data,sc+'_edp_dce_gse_fast_l2',data=E,dl=dl,lim=lim
tnB = tnames(sc+'_fgm_b_gse_srvy_l2',ctB)
tnE = tnames(sc+'_edp_dce_gse_fast_l2',ctE)
if ctB eq 1 and ctE eq 1 then begin
  ; E has a higher time resolution than B
  ; Here, we interpolate B so that its timestamps will match with those of E.
  Bip = fltarr(n_elements(E.x),3)
  wBx = interpol(B.y[*,0], B.x, E.x,/spline)
  wBy = interpol(B.y[*,1], B.x, E.x,/spline)
  wBz = interpol(B.y[*,2], B.x, E.x,/spline)
  iwB2 = 1000./(wBx^2 + wBy^2 + wBz^2)
  EXB = fltarr(n_elements(E.x),3)
  EXB[*,0] = ((E.y[*,1]*wBz - E.y[*,2]*wBy)*iwB2 > (-1)*vthres) < vthres
  EXB[*,1] = ((E.y[*,2]*wBx - E.y[*,0]*wBz)*iwB2 > (-1)*vthres) < vthres
  EXB[*,2] = ((E.y[*,0]*wBy - E.y[*,1]*wBx)*iwB2 > (-1)*vthres) < vthres
  str_element,/delete,'lim','yrange'
  store_data,sc+'_exb_gse',data={x:E.x,y:EXB},dl=dl
  options,sc+'_exb_gse',labels=['(ExB)x','(ExB)y','(ExB)z'],labflag=-1,colors=[2,4,6],$
    ytitle=sc+'!CExB',ysubtitle='[km/s]',constant=0,ystyle=1
endif

; curlometer calculations
fields = 'mms'+['1', '2', '3', '4']+'_fgm_b_gse_srvy_l2'
positions = 'mms'+['1', '2', '3', '4']+'_fgm_r_gse_srvy_l2'
mms_curl, trange=timerange(), fields=fields, positions=positions

; set the label to show along the bottom of the tplot
tkm2re, 'mms'+probe+'_mec_r_gsm'
split_vec, 'mms'+probe+'_mec_r_gsm_re'

options, 'mms'+probe+'_mec_r_gsm_re_x', ytitle='X-GSM (Re)'
options, 'mms'+probe+'_mec_r_gsm_re_y', ytitle='Y-GSM (Re)'
options, 'mms'+probe+'_mec_r_gsm_re_z', ytitle='Z-GSM (Re)'
position_vars = 'mms'+probe+'_mec_r_gsm_re_'+['z', 'y', 'x']

window, ysize=950


tplot, [ae_type eq 'thm' ? 'thmAE' : 'kyoto_ae', $
        'mms'+probe+'_fgm_b_gsm_srvy_l2_bvec', $
        'mms'+probe+'_fgm_b_gsm_srvy_l2_bvec_z', $
        'mms'+probe+'_fgm_b_gsm_srvy_l2_btot', $
        'mms'+probe+'_edp_fast_scpot_ln', $
        'mms'+probe+'_fpi_combined_density', $
        'mms'+probe+'_dis_bulkv_gse_fast', $
        'mms'+probe+'_exb_gse', $
        'jtotal', $
        'mms'+probe+'_epd_eis_srvy_l2_extof_proton_flux_omni', $
        'mms'+probe+'_dis_energyspectr_omni_fast', $
        'mms'+probe+'_hpca_oplus_flux_elev_0-360', $
        'mms'+probe+'_epd_feeps_srvy_l2_electron_intensity_omni', $
        'mms'+probe+'_des_energyspectr_omni_fast', $
        'mms'+probe+'_edp_dce_gse_fast_l2', $
        'mms'+probe+'_edp_hfesp_srvy_l2', $
        'mms'+probe+'_dsp_bpsd_omni_fast_l2'], var_label=position_vars

if postscript then tprint, plot_directory + 'mms'+probe + '_basic_tail'
if send_plots_to eq 'png' then begin
  makepng, plot_directory + 'mms'+probe + '_basic_tail_'+ $
    time_string(date, tformat='YYYYMMDD_hhmmss.fff'), $
    /mkdir
endif

print, 'took ' + string(systime(/sec)-start_time) + ' seconds to run'

stop
end