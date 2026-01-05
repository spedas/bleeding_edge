;+
;
;PROCEDURE:       MEX_ASP_IMA_SC_BINS
;
;PURPOSE:         
;                 Reads MEX/ASPERA-3 (IMA) FOV blockage matrix (1 = NO blocked / 0 = blocked).
;
;INPUTS:          None.
;
;KEYWORDS:        None.
;
;NOTE:            See this PDF file in pp. 74-84; however, the definition here is opposite.
;                 https://archives.esac.esa.int/psa/ftp/MARS-EXPRESS/ASPERA-3/MEX-M-ASPERA3-2-EDR-IMA-EXT5-V1.0/DOCUMENT/IMA_CALIBRATION_REPORT.PDF
;
;CREATED BY:      Takuya Hara on 2018-02-01.
;
;LAST MODIFICATION:
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-01-01 12:17:28 -0800 (Thu, 01 Jan 2026) $
; $LastChangedRevision: 33942 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_ima_sc_bins.pro $
;
;-
PRO mex_asp_ima_sc_bins, da
  da = INTARR(16, 16) ; azimuth, polar
  da[*] = 1
  da[0, 0:6] = 0
  da[1, 2:6] = 0
  da[8, 0:1] = 0
  da[9:15, 0:7] = 0
  da[11:13, 11:15] = 0
  da[12, 8:10] = 0
  da[15, 8:9] = 0
  RETURN
END
