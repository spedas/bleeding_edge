;+
;PROCEDURE: setfileenv
;PURPOSE:
;   Sets up environment variables giving information on the location
;   of master index files and file paths of WIND 3DP data.
;  This should be the one and only file that needs editting for new file systems.
;CREATED BY:    Davin Larson and Peter Schroeder
;VERSION:   @(#)setfileenv.pro    1.24 03/09/20
;
;-

pro setfileenv,force=force

if keyword_set(getenv('FILE_ENV_SET')) and not keyword_set(force) then return

; Only run this procedure once!
setenv,'FILE_ENV_SET=1'

basedir = getenv('BASE_DATA_DIR')

if not keyword_set(basedir) then begin
   basedir =!version.os_family eq 'Windows' ? 'y:' : '/home/wind/dat'

   message,/info,'Warning! Environment variable "BASE_DATA_DIR" is not set!;'
   message,/info,'Using default value: "'+basedir+'"'
endif

themisdir = getenv('THEMIS_DATA_DIR')

setenv,'THG_MAG_FILES=' + themisdir+'thg/l2/mag/

setenv,'WI_K0_3DP_FILES='   +basedir+'/wi/3dp/k0/????/wi_k0_3dp*.cdf'
setenv,'WI_K0_SWE_FILES='   +basedir+'/wi/swe/k0/????/wi_k0_swe*.cdf'
setenv,'WI_SWE_K0_FILES='   +basedir+'/wi/swe/k0/????/wi_k0_swe*.cdf'
setenv,'WI_SWE_K0_B_FILES=' +basedir+'/wi/swe/k0/bartel/wi_swe_k0*.cdf'
setenv,'WI_K0_MFI_FILES='   +basedir+'/wi/mfi/k0/????/wi_k0_mfi*.cdf'
setenv,'WI_SP_MFI_FILES='   +basedir+'/wi/mfi/sp/????/wi_sp_mfi*.cdf'
setenv,'WI_K0_MFI_B_FILES=' +basedir+'/wi/mfi/k0/bartel/wi_*.cdf'
setenv,'WI_H0_MFI_FILES='   +basedir+'/wi/mfi/h0/v??/wi_h0_mfi*.cdf'
setenv,'WI_OR_DEF_FILES='   +basedir+'/wi/or/def/????/wi_or_def*.cdf'
setenv,'WI_OR_PRE_FILES='   +basedir+'/wi/or/pre/????/wi_or_pre*.cdf'
setenv,'WI_OR_CMB_FILES='   +basedir+'/wi/or/cmb/????/wi_or_*.cdf'
setenv,'WI_OR_LNG_FILES='   +basedir+'/wi/or/lng/wi_or_lng*.cdf'
setenv,'WI_OR_CMB_B_FILES=' +basedir+'/wi/or/cmb/bartel/wi_or_cmb_B*.cdf'
setenv,'GE_K0_EPI_FILES='   +basedir+'/ge/epi/k0/????/ge_k0_epi*.cdf'

setenv,'WI_3DP_ELPD_FILES='   +basedir+'/wi/3dp/elpd/????/wi_3dp_elpd*.cdf'
setenv,'WI_3DP_ELPD_B_FILES=' +basedir+'/wi/3dp/elpd/bartel/wi_3dp_elpd*.cdf'
setenv,'WI_3DP_PDFIT_FILES='  +basedir+'/wi/3dp/pdfit/????/*pdfit*.cdf'
setenv,'WI_3DP_EHSP_FILES='   +basedir+'/wi/3dp/ehsp/????/wi_3dp_ehsp*.cdf'
setenv,'WI_3DP_EHSP_B_FILES=' +basedir+'/wi/3dp/ehsp/bartel/wi_3dp_ehsp*.cdf'
setenv,'WI_3DP_SFSP_FILES='   +basedir+'/wi/3dp/sfsp/????/wi_3dp_sfsp*.cdf'
setenv,'WI_3DP_SFSP_B_FILES=' +basedir+'/wi/3dp/sfsp/bartel/wi_3dp_sfsp_B*.cdf'
setenv,'WI_3DP_SFSP2_FILES='  +basedir+'/wi/3dp/sfsp2/????/wi_sfsp_3dp*.cdf'
setenv,'WI_3DP_SFSP2_B_FILES='+basedir+'/wi/3dp/sfsp2/bartel/wi_3dp_sfsp2_B*.cdf'
setenv,'WI_3DP_SOSP_B_FILES=' +basedir+'/wi/3dp/sosp/bartel/wi_3dp_sosp_B*.cdf'
setenv,'WI_3DP_PLSP_FILES='   +basedir+'/wi/3dp/plsp/????/wi_plsp_3dp*.cdf'
setenv,'WI_PLSP_3DP_FILES='   +basedir+'/wi/3dp/plsp/????/wi_plsp_3dp*.cdf'
setenv,'WI_3DP_PLSP_B_FILES=' +basedir+'/wi/3dp/plsp/bartel/wi_3dp_plsp_B*.cdf'

setenv,'WI_EHPD_3DP_FILES='   +basedir+'/wi/3dp/ehpd/????/wi_ehpd_3dp*'
setenv,'WI_EHSP_3DP_FILES='   +basedir+'/wi/3dp/ehsp2/????/wi_ehsp_3dp*'
setenv,'WI_ELM2_3DP_FILES='   +basedir+'/wi/3dp/elm2/????/wi_elm2_3dp*'
setenv,'WI_ELPD_3DP_FILES='   +basedir+'/wi/3dp/elpd/????/wi_elpd_3dp*.cdf'
setenv,'WI_ELSP_3DP_FILES='   +basedir+'/wi/3dp/elsp/????/wi_elsp_3dp*'
setenv,'WI_EM_3DP_FILES='     +basedir+'/wi/3dp/em/????/wi_em_3dp*'
setenv,'WI_K0_3DP_FILES='     +basedir+'/wi/3dp/k0/????/wi_k0_3dp*'
setenv,'WI_K0_SWE_FILES='     +basedir+'/wi/swe/k0/????/wi_k0_swe*'
setenv,'WI_OR_DEF_FILES='     +basedir+'/wi/or/def/????/wi_or_def*'
setenv,'WI_OR_LNG_FILES='     +basedir+'/wi/or/lng/????/wi_or_lng*'
setenv,'WI_OR_PRE_FILES='     +basedir+'/wi/or/pre/????/wi_or_pre*'
setenv,'WI_PLSP_3DP_FILES='   +basedir+'/wi/3dp/plsp/????/wi_plsp_3dp*'
setenv,'WI_SFPD_3DP_FILES='   +basedir+'/wi/3dp/sfpd/????/wi_sfpd_3dp*'
setenv,'WI_SFSP_3DP_FILES='   +basedir+'/wi/3dp/sfsp1/????/wi_sfsp_3dp*'
setenv,'WI_SOSP_3DP_FILES='   +basedir+'/wi/3dp/sosp1/????/wi_sosp_3dp*'
setenv,'WI_SOPD_3DP_FILES='   +basedir+'/wi/3dp/sopd/????/wi_sopd_3dp*'


; The following environment variables will slowly be replaced.

if not keyword_set(getenv('WIND_DATA_DIRS')) then $
   setenv,'WIND_DATA_DIRS='+basedir+'/d*/'

disks= getenv('WIND_DATA_DIRS')
indexdir = getenv('CDF_INDEX_DIR')+'/'

setenv,'GE_K0_CPI_FILES='+disks+'ge/k0/cpi/ge_k0_cpi*'
setenv,'GE_K0_EFD_FILES='+disks+'ge/k0/efd/ge_k0_efd*'
setenv,'GE_K0_LEP_FILES='+disks+'ge/k0/lep/ge_k0_lep*'
setenv,'GE_K0_MGF_FILES='+disks+'ge/k0/mgf/ge_k0_mgf*'
setenv,'GE_K0_PWI_FILES='+disks+'ge/k0/pwi/ge_k0_pwi*'
setenv,'IG_K0_PCI_FILES='+disks+'ig/k0/pci/ig_k0_pci*'
setenv,'PO_K0_EFI_FILES='+disks+'po/k0/efi/po_k0_efi*'
setenv,'PO_K0_HYD_FILES='+disks+'po/k0/hyd/po_k0_hyd*'
setenv,'PO_K0_MFE_FILES='+disks+'po/k0/mfe/po_k0_mfe*'
setenv,'PO_K0_PIX_FILES='+disks+'po/k0/pix/po_k0_pix*'
setenv,'PO_K0_PWI_FILES='+disks+'po/k0/pwi/po_k0_pwi*'
setenv,'PO_K0_UVI_FILES='+disks+'po/k0/uvi/po_k0_uvi*'
setenv,'SO_K0_CEL_FILES='+disks+'so/k0/cel/so_k0_cel*'
setenv,'SO_K0_CST_FILES='+disks+'so/k0/cst/so_k0_cst*'
setenv,'SO_K0_ERN_FILES='+disks+'so/k0/ern/so_k0_ern*'
setenv,'WI_AT_DEF_FILES='+disks+'wi/at/def/wi_at_def*'
setenv,'WI_AT_PRE_FILES='+disks+'wi/at/pre/wi_at_pre*'
;setenv,'WI_EHPD_3DP_FILES='+disks+'wi/3dp/ehpd/wi_ehpd_3dp*'
;setenv,'WI_EHSP_3DP_FILES='+disks+'wi/3dp/ehsp/wi_ehsp_3dp*'
;setenv,'WI_ELM2_3DP_FILES='+disks+'wi/3dp/elm2/wi_elm2_3dp*'
;setenv,'WI_ELPD_3DP_FILES='+disks+'wi/3dp/elpd/wi_elpd_3dp*'
;setenv,'WI_ELSP_3DP_FILES='+disks+'wi/3dp/elsp/wi_elsp_3dp*'
;setenv,'WI_EM_3DP_FILES='+disks+'wi/3dp/em/wi_em_3dp*'
setenv,'WI_FRM_3DP_FILES='+disks+'wi/3dp/frm/wi_frm_3dp*'
;setenv,'WI_H0_MFI_FILES='+disks+'wi/h0/mfi/wi_h0_mfi*'
setenv,'WI_HKP_3DP_FILES='+disks+'wi/3dp/hkp/wi_hkp_3dp*'
;setenv,'WI_K0_3DP_FILES='+disks+'wi/k0/3dp/wi_k0_3dp*'
setenv,'WI_K0_EPA_FILES='+disks+'wi/k0/epa/wi_k0_epa*'
;setenv,'WI_K0_MFI_FILES='+disks+'wi/k0/mfi/wi_k0_mfi*'
setenv,'WI_K0_SMS_FILES='+disks+'wi/k0/sms/wi_k0_sms*'
setenv,'WI_K0_SPHA_FILES='+disks+'wi/k0/spha/wi_k0_spha*'
;setenv,'WI_K0_SWE_FILES='+disks+'wi/k0/swe/wi_k0_swe*'
setenv,'WI_K0_WAV_FILES='+disks+'wi/k0/wav/wi_k0_wav*'
setenv,'WI_LZ_3DP_FILES='+disks+'wi/lz/3dp/wi_lz_3dp*'
;setenv,'WI_OR_DEF_FILES='+disks+'wi/or/def/wi_or_def*'
;setenv,'WI_OR_LNG_FILES='+disks+'wi/or/lng/wi_or_lng*'
;setenv,'WI_OR_PRE_FILES='+disks+'wi/or/pre/wi_or_pre*'
setenv,'WI_PHSP_3DP_FILES='+disks+'wi/3dp/phsp/wi_phsp_3dp*'
;setenv,'WI_PLSP_3DP_FILES='+disks+'wi/3dp/plsp/wi_plsp_3dp*'
setenv,'WI_PM_3DP_FILES='+disks+'wi/3dp/pm/wi_pm_3dp*'
;setenv,'WI_SFPD_3DP_FILES='+disks+'wi/3dp/sfpd/wi_sfpd_3dp*'
;setenv,'WI_SFSP_3DP_FILES='+disks+'wi/3dp/sfsp/wi_sfsp_3dp*'
setenv,'WI_SOPD_3DP_FILES='+disks+'wi/3dp/sopd/wi_sopd_3dp*'
;setenv,'WI_SOSP_3DP_FILES='+disks+'wi/3dp/sosp/wi_sosp_3dp*'
;setenv,'WI_SP_MFI_FILES='+disks+'wi/sp/mfi/wi_sp_mfi*'


return
end
