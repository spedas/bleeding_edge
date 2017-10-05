;+
; NAME:
;   rbsp_efw_boom_deploy_history (function)
;
; PURPOSE:
;   Returns a structure with all the boom lengths for input date and time
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;
; NOTES: Boom deploy schedule from https://efw.ssl.berkeley.edu/svn/SOC/software/deploy_history/
;
;		 To Convert SPB total stroke to dipole tip-to-tip, double stroke length and 
;		 add 1.82 m; e.g. 20-m stroke = 41.8-m tip-to-tip dipole.
;
;		 To convert AXB total stroke to dipole tip-to-tip, add AFT and FWD total strokes 
;		 and add 1.2 m for deck spacing and 0.76 m for whip and sphere
;		 e.g. 4.02-m stroke on FWD and AFT AXB stacers gives a dipole tip-to-tip of 10.0 m.
;
; ARGUMENTS:
;
; KEYWORDS:	allvals -> set to fill with a structure with all the mission boom length
;						changes based on date and time
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;	2013-05-17:	Created by Aaron Breneman (UMN)
;
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2014-10-28 13:46:07 -0700 (Tue, 28 Oct 2014) $
; $LastChangedRevision: 16071 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_boom_deploy_history.pro $
;
;-



function rbsp_efw_boom_deploy_history,datetime,allvals=av

dt2 = time_double(datetime)

;------------------------------------------------------------------------------------
;RBSPA
;------------------------------------------------------------------------------------

deploystartA12 = '2012-09-13/19:44:10'
deployendA12   = '2012-09-13/19:57:47'
lengthA12 = 4

;13-SEP-2012	19:44:10	sTART DEPLOY 1-2 BOOMS TO 4-M STROKE, 84 CLICKS	SPIN RATE	SPIN RATE 7.04 RPM
;13-SEP-2012	19:57:47	END DEPLOY 1-2 BOOMS TO 4-M STROKE	SPIN RATE 6.97 RPM

deploystartA34 = '2012-09-13/20:01:30'
deployendA34   = '2012-09-13/20:14:07'
lengthA34 = 4
;13-SEP-2012	20:01:30	START DEPLOY 3-4 BOOMS TO 4-M STROKE, 84 CLICKS	SPIN RATE 6.97 RPM
;13-SEP-2012	20:14:07	END DEPLOY 3-4 BOOMS TO 4-M STROKE	SPIN RATE 6.90 RPM

deploystartA12 = [deploystartA12,'2012-09-14/15:17:30']
deployendA12 =   [deployendA12,'2012-09-14/15:25:59']
lengthA12 = [lengthA12,7]
;14-SEP-2012	15:17:30	START DEPLOY 1-2 BOOMS TO 7-M STROKE, 63 CLICKS	SPIN RATE 6.90 RPM
;14-SEP-2012	15:25:59	END DEPLOY 1-2 BOOMS TO 7-M STROKE	SPIN RATE 6.79 RPM
deploystartA34 = [deploystartA34,'2012-09-14/15:29:00']
deployendA34 =   [deployendA34,'2012-09-14/15:36:55']
lengthA34 = [lengthA34,7]
;14-SEP-2012	15:29:00	START DEPLOY 3-4 BOOMS TO 7-M STROKE, 63 CLICKS	SPIN RATE 6.79 RPM
;14-SEP-2012	15:36:55	END DEPLOY 3-4 BOOMS TO 7-M STROKE	SPIN RATE 6.67 RPM

deploystartA12 = [deploystartA12,'2012-09-17/14:51:00']
deployendA12 =   [deployendA12,'2012-09-17/15:05:28']
lengthA12 = [lengthA12,15]
;17-SEP-2012	14:51:00	START DEPLOY 1-2 BOOMS TO 15-M STROKE, 105 CLICKS	SPIN RATE 14.23 RPM
;17-SEP-2012	15:05:28	END DEPLOY 1-2 BOOMS TO 15-M STROKE	SPIN RATE 13.49 RPM
deploystartA34 = [deploystartA34,'2012-09-17/15:08:30']
deployendA34 =   [deployendA34,'2012-09-17/15:22:12']
lengthA34 = [lengthA34,15]
;17-SEP-2012	15:08:30	START DEPLOY 3-4 BOOMS TO 15-M STROKE, 105 CLICKS	SPIN RATE 13.49 RPM
;17-SEP-2012	15:22:12	END DEPLOY 3-4 BOOMS TO 15-M STROKE	SPIN RATE 12.83 RPM

deploystartA12 = [deploystartA12,'2012-09-18/16:49:45']
deployendA12 =   [deployendA12,'2012-09-18/17:04:06']
lengthA12 = [lengthA12,20]
;18-SEP-2012	16:49:45	START DEPLOY 1-2 BOOMS TO 20-M STROKE, 105 CLICKS	SPIN RATE 12.83 RPM
;18-SEP-2012	17:04:06	END DEPLOY 1-2 BOOMS TO 20-M STROKE, 105 CLICKS	SPIN RATE 11.95 RPM
deploystartA34 = [deploystartA34,'2012-09-18/16:49:45']
deployendA34 =   [deployendA34,'2012-09-18/17:04:06']
lengthA34 = [lengthA34,20]
;18-SEP-2012	16:49:45	START DEPLOY 3-4 BOOMS TO 20-M STROKE, 105 CLICKS	SPIN RATE 11.95 RPM
;18-SEP-2012	17:04:06	END DEPLOY 3-4 BOOMS TO 20-M STROKE, 105 CLICKS	SPIN RATE 11.19 RPM

deploystartA12 = [deploystartA12,'2012-09-18/17:22:10']
deployendA12 =   [deployendA12,'2012-09-18/17:36:32']
lengthA12 = [lengthA12,25]
;18-SEP-2012	17:22:10	START DEPLOY 1-2 BOOMS TO 25-M STROKE, 105 CLICKS	SPIN RATE 11.19 RPM
;18-SEP-2012	17:36:32	END DEPLOY 1-2 BOOMS TO 25-M STROKE, 105 CLICKS	SPIN RATE 10.29 RPM
deploystartA34 = [deploystartA34,'2012-09-18/17:38:45']
deployendA34 =   [deployendA34,'2012-09-18/17:51:20']
lengthA34 = [lengthA34,25]
;18-SEP-2012	17:38:45	START DEPLOY 3-4 BOOMS TO 25-M STROKE, 105 CLICKS	SPIN RATE 10.29 RPM
;18-SEP-2012	17:51:20	END DEPLOY 3-4 BOOMS TO 25-M STROKE, 105 CLICKS	SPIN RATE 9.53 RPM

deploystartA12 = [deploystartA12,'2012-09-19/19:06:30']
deployendA12 =   [deployendA12,'2012-09-19/19:21:08']
lengthA12 = [lengthA12,30]
;19-SEP-2012	19:06:30	START DEPLOY 1-2 BOOMS TO 30-M STROKE, 105 CLICKS	SPIN RATE 9.52 RPM
;19-SEP-2012	19:21:08	END DEPLOY 1-2 BOOMS TO 30-M STROKE, 105 CLICKS	SPIN RATE 8.68 RPM
deploystartA34 = [deploystartA34,'2012-09-19/19:24:30']
deployendA34 =   [deployendA34,'2012-09-19/19:36:56']
lengthA34 = [lengthA34,30]
;19-SEP-2012	19:24:30	START DEPLOY 3-4 BOOMS TO 30-M STROKE, 105 CLICKS	SPIN RATE 8.68 RPM
;19-SEP-2012	19:36:56	END DEPLOY 3-4 BOOMS TO 30-M STROKE, 105 CLICKS	SPIN RATE 7.98 RPM

deploystartA12 = [deploystartA12,'2012-09-21/16:27:30']
deployendA12 =   [deployendA12,'2012-09-21/16:41:36']
lengthA12 = [lengthA12,35]
;21-SEP-2012	16:27:30	START DEPLOY 1-2 BOOMS TO 35-M STROKE, 105 CLICKS	SPIN RATE 11.02 RPM
;21-SEP-2012	16:41:36	END DEPLOY 1-2 BOOMS TO 35-M STROKE, 105 CLICKS	SPIN RATE 10.01 RPM
deploystartA34 = [deploystartA34,'2012-09-21/16:45:00']
deployendA34 =   [deployendA34,'2012-09-21/16:57:24']
lengthA34 = [lengthA34,35]
;21-SEP-2012	16:45:00	START DEPLOY 3-4 BOOMS TO 35-M STROKE, 105 CLICKS	SPIN RATE 10.1 RPM
;21-SEP-2012	16:57:24	END DEPLOY 3-4 BOOMS TO 35-M STROKE, 105 CLICKS	SPIN RATE 9.17 RPM

deploystartA12 = [deploystartA12,'2012-09-21/17:02:40']
deployendA12 =   [deployendA12,'2012-09-21/17:16:34']
lengthA12 = [lengthA12,40]
;21-SEP-2012	17:02:40	START DEPLOY 1-2 BOOMS TO 40-M STROKE, 105 CLICKS	SPIN RATE 9.17 RPM
;21-SEP-2012	17:16:34	END DEPLOY 1-2 BOOMS TO 40-M STROKE, 105 CLICKS	SPIN RATE 8.32 RPM
deploystartA34 = [deploystartA34,'2012-09-21/17:20:40']
deployendA34 =   [deployendA34,'2012-09-21/17:33:00']
lengthA34 = [lengthA34,40]
;21-SEP-2012	17:20:40	START DEPLOY 3-4 BOOMS TO 40-M STROKE, 105 CLICKS	SPIN RATE 8.32 RPM
;21-SEP-2012	17:33:00	END DEPLOY 3-4 BOOMS TO 40-M STROKE, 105 CLICKS	SPIN RATE 7.62 RPM

deploystartA12 = [deploystartA12,'2012-09-22/18:53:40']
deployendA12 =   [deployendA12,'2012-09-22/19:07:30']
lengthA12 = [lengthA12,45]
;22-SEP-2012	18:53:40	START DEPLOY 1-2 BOOMS TO 45-M STROKE, 105 CLICKS	SPIN RATE 7.62 RPM
;22-SEP-2012	19:07:30	END DEPLOY 1-2 BOOMS TO 45-M STROKE, 105 CLICKS	SPIN RATE 6.92 RPM
deploystartA34 = [deploystartA34,'2012-09-22/19:09:10']
deployendA34 =   [deployendA34,'2012-09-22/19:21:34']
lengthA34 = [lengthA34,45]
;22-SEP-2012	19:09:10	START DEPLOY 3-4 BOOMS TO 45-M STROKE, 105 CLICKS	SPIN RATE 6.92 RPM
;22-SEP-2012	19:21:34	END DEPLOY 3-4 BOOMS TO 45-M STROKE, 105 CLICKS	SPIN RATE 6.34 RPM

deploystartA12 = [deploystartA12,'2012-09-22/19:24:00']
deployendA12 =   [deployendA12,'2012-09-22/19:35:14']
lengthA12 = [lengthA12,49.1]
;22-SEP-2012	19:24:00	START DEPLOY 1-2 BOOMS TO 49.1-M STROKE, 86 CLICKS	SPIN RATE 6.34 RPM
;22-SEP-2012	19:35:14	END DEPLOY 1-2 BOOMS TO 49.1-M STROKE, 86 CLICKS	SPIN RATE 5.87 RPM
deploystartA34 = [deploystartA34,'2012-09-22/19:37:40']
deployendA34 =   [deployendA34,'2012-09-22/19:47:50']
lengthA34 = [lengthA34,49.1]
;22-SEP-2012	19:37:40	START DEPLOY 3-4 BOOMS TO 49.1-M STROKE, 86 CLICKS	SPIN RATE 5.87 RPM
;22-SEP-2012	19:47:50	END DEPLOY 3-4 BOOMS TO 49.1-M STROKE, 86 CLICKS	SPIN RATE 5.48 RPM
; TOTAL RADIAL DIPOLE AT 100.02 M TIP-TO-TIP.
;

deploystartA5 = '2012-09-24/17:59:10'
deployendA5	  = '2012-09-24/17:59:10'
lengthA5 = 0.07
;24-SEP-2012	17:59:10	AFT-V5 STACER DEPLOY, 10 CLICKS CMD, 10 CLICKS DEP, 0.07-M TOTAL STROKE
deploystartA5 = [deploystartA5,'2012-09-24/18:05:20']
deployendA5	  = [deployendA5,'2012-09-24/18:05:20']
lengthA5 = [lengthA5,1.39]
;24-SEP-2012	18:05:20	AFT-V5 STACER DEPLOY, 200 CLICKS CMD, 201 CLICKS DEP, 1.39-M TOTAL STROKE

deploystartA5 = [deploystartA5,'2012-09-24/18:10:00']
deployendA5	  = [deployendA5,'2012-09-24/18:10:00']
lengthA5 = [lengthA5,2.68]
;24-SEP-2012	18:10:00	AFT-V5 STACER DEPLOY, 200 CLICKS CMD, 201 CLICKS DEP, 2.68-M TOTAL STROKE
deploystartA5 = [deploystartA5,'2012-09-24/18:13:30']
deployendA5	  = [deployendA5,'2012-09-24/18:13:30']
lengthA5 = [lengthA5,4.02]
;24-SEP-2012	18:13:30	AFT-V5 STACER DEPLOY, 224 CLICKS CMD, 225 CLICKS DEP, 4.02-M TOTAL STROKE

deploystartA6 = '2012-09-24/18:19:00'
deployendA6	  = '2012-09-24/18:19:00'
lengthA6 = 0.07
;24-SEP-2012	18:19:00	FWD-V6 STACER DEPLOY, 10 CLICKS CMD, 11 CLICKS DEP, 0.07-M TOTAL STROKE
deploystartA6 = [deploystartA6,'2012-09-24/18:22:30']
deployendA6	  = [deployendA6,'2012-09-24/18:22:30']
lengthA6 = [lengthA6,1.39]
;24-SEP-2012	18:22:30	FWD-V6 STACER DEPLOY, 200 CLICKS CMD, 201 CLICKS DEP, 1.39-M TOTAL STROKE
deploystartA6 = [deploystartA6,'2012-09-24/18:25:30']
deployendA6	  = [deployendA6,'2012-09-24/18:25:30']
lengthA6 = [lengthA6,2.68]
;24-SEP-2012	18:25:30	FWD-V6 STACER DEPLOY, 200 CLICKS CMD, 201 CLICKS DEP, 2.68-M TOTAL STROKE
deploystartA6 = [deploystartA6,'2012-09-24/18:28:30']
deployendA6	  = [deployendA6,'2012-09-24/18:28:30']
lengthA6 = [lengthA6,4.02]
;24-SEP-2012	18:28:30	FWD-V6 STACER DEPLOY, 224 CLICKS CMD, 225 CLICKS DEP, 4.02-M TOTAL STROKE
; TOTAL AXIAL DIPOLE AT 10.0-M TIP-TO-TIP.
;

deploystartA5 = [deploystartA5,'2012-10-13/04:46:00']
deployendA5	  = [deployendA5,'2012-10-13/04:46:00']
lengthA5 = [lengthA5,5.12]
;13-OCT-2012	04:46:00	AFT-V5 STACER DEPLOY, 180 CLICKS DEP, 1.10-M ADDL STROKE, 5.12-M TOTAL STROKE

deploystartA6 = [deploystartA6,'2012-10-13/04:57:50']
deployendA6	  = [deployendA6,'2012-10-13/04:57:50']
lengthA6 = [lengthA6,4.52]
;13-OCT-2012	04:57:50	FWD-V6 STACER DEPLOY, 82 CLICKS DEP, 0.5-M ADDL STROKE, 4.52-M TOTAL STROKE
; TOTAL AXIAL DIPOLE AT 11.6-M TIP-TO-TIP.
;
deploystartA5 = [deploystartA5,'2012-10-23/22:42:00']
deployendA5	  = [deployendA5,'2012-10-23/23:02:00']
lengthA5 = [lengthA5,6.0]
;23-OCT-2012	22:42:00	START AFT-V5 STACER DEPLOY.
;23-OCT-2012	23:02:00	END AFT-V5 STACER DEPLOY, 169 CLICKS, 6.0-M TOTAL STROKE.
;	note:  NO FWD-V6 STACER DEPLOY IN THIS OPERATION.
; TOTAL AXIAL DIPOLE AT 12.5-M TIP-TO-TIP.
;

;
; AXB TRIM #3:
deploystartA6 = [deploystartA6,'2012-11-09/18:37:15']
deployendA6	  = [deployendA6,'2012-11-09/18:37:15']
lengthA6 = [lengthA6,5.44]
;09-NOV-2012	18:37:15	END FWD-V6 STACER DEPLOY, 185 CLICKS DEP, 0.92-M ADDL STROKE, 5.44-M TOTAL STROKE.
; NO OPERATIONS ON AFT-V5 STACER; STROKE REMAINS AT 6.0-M.
; TOTAL AXIAL DIPOLE AT 13.4-M, TIP-TO-TIP.
;
; AXB TRIM #4:
deploystartA6 = [deploystartA6,'2012-12-07/04:40:30']
deployendA6	  = [deployendA6,'2012-12-07/04:40:50']
lengthA6 = [lengthA6,5.69]
;07-DEC 2012	04:40:30	START FWD-V6 STACER DEPLOY.
;07-DEC 2012	04:40:50	END FWD-V6 STACER DEPLOY, 48 CLICKS DEP, 0.25-M ADDL STROKE, 5.69-M TOTAL STROKE.
; NO OPERATIONS ON AFT-V5 STACER; STROKE REMAINS AT 6.0-M.
; TOTAL AXIAL DIPOLE AT 13.65-M, TIP-TO-TIP.
;
;===========================================================================================================================
; SC	Date		Time		Operation	Notes

;RBSP-B


deploystartB12 = '2012-09-13/23:06:10'
deployendB12   = '2012-09-13/23:19:00'
lengthB12 = 4
;13-SEP-2012	23:06:10	sTART DEPLOY 1-2 BOOMS TO 4-M STROKE, 84 CLICKS	SPIN RATE	SPIN RATE 7.04 RPM
;13-SEP-2012	23:19:00	END DEPLOY 1-2 BOOMS TO 4-M STROKE	SPIN RATE 6.97 RPM
deploystartB34 = '2012-09-13/23:24:40'
deployendB34   = '2012-09-13/23:37:20'
lengthB34 = 4
;13-SEP-2012	23:24:40	START DEPLOY 3-4 BOOMS TO 4-M STROKE, 84 CLICKS	SPIN RATE 6.97 RPM
;13-SEP-2012	23:37:20	END DEPLOY 3-4 BOOMS TO 4-M STROKE	SPIN RATE 6.90 RPM

deploystartB12 = [deploystartB12,'2012-09-14/17:14:50']
deployendB12   = [deployendB12,	 '2012-09-14/17:23:00']
lengthB12 = [lengthB12,7]
;14-SEP-2012	17:14:50	START DEPLOY 1-2 BOOMS TO 7-M STROKE, 63 CLICKS	SPIN RATE 6.90 RPM
;14-SEP-2012	17:23:00	END DEPLOY 1-2 BOOMS TO 7-M STROKE	SPIN RATE 6.78 RPM
deploystartB34 = [deploystartB34,'2012-09-14/17:26:20']
deployendB34   = [deployendB34,'2012-09-14/17:34:26']
lengthB34 = [lengthB34,7]
;14-SEP-2012	17:26:20	START DEPLOY 3-4 BOOMS TO 7-M STROKE, 63 CLICKS	SPIN RATE 6.78 RPM
;14-SEP-2012	17:34:26	END DEPLOY 3-4 BOOMS TO 7-M STROKE	SPIN RATE 6.67 RPM


deploystartB12 = [deploystartB12,'2012-09-17/18:06:40']
deployendB12   = [deployendB12,'2012-09-17/18:20:16']
lengthB12 = [lengthB12,15]
;17-SEP-2012	18:06:40	START DEPLOY 1-2 BOOMS TO 15-M STROKE, 105 CLICKS	SPIN RATE 14.11 RPM
;17-SEP-2012	18:20:16	END DEPLOY 1-2 BOOMS TO 15-M STROKE	SPIN RATE 13.38 RPM
deploystartB34 = [deploystartB34,'2012-09-17/18:23:00']
deployendB34   = [deployendB34,'2012-09-17/18:36:26']
lengthB34 = [lengthB34,15]
;17-SEP-2012	18:23:00	START DEPLOY 3-4 BOOMS TO 15-M STROKE, 105 CLICKS	SPIN RATE 13.38 RPM
;17-SEP-2012	18:36:26	END DEPLOY 3-4 BOOMS TO 15-M STROKE	SPIN RATE 12.73 RPM


deploystartB12 = [deploystartB12,'2012-09-18/10:07:45']
deployendB12   = [deployendB12,'2012-09-18/10:21:02']
lengthB12 = [lengthB12,20]
;18-SEP-2012	10:07:45	START DEPLOY 1-2 BOOMS TO 20-M STROKE, 105 CLICKS	SPIN RATE 12.73 RPM
;18-SEP-2012	10:21:02	END DEPLOY 1-2 BOOMS TO 20-M STROKE, 105 CLICKS	SPIN RATE 11.86 RPM
deploystartB34 = [deploystartB34,'2012-09-18/10:24:45']
deployendB34   = [deployendB34,'2012-09-18/10:38:12']
lengthB34 = [lengthB34,20]
;18-SEP-2012	10:24:45	START DEPLOY 3-4 BOOMS TO 20-M STROKE, 105 CLICKS	SPIN RATE 11.86 RPM
;18-SEP-2012	10:38:12	END DEPLOY 3-4 BOOMS TO 20-M STROKE, 105 CLICKS	SPIN RATE 11.11 RPM

deploystartB12 = [deploystartB12,'2012-09-18/10:41:30']
deployendB12   = [deployendB12,'2012-09-18/10:54:32']
lengthB12 = [lengthB12,25]
;18-SEP-2012	10:41:30	START DEPLOY 1-2 BOOMS TO 25-M STROKE, 105 CLICKS	SPIN RATE 11.10 RPM
;18-SEP-2012	10:54:32	END DEPLOY 1-2 BOOMS TO 25-M STROKE, 105 CLICKS	SPIN RATE 10.21 RPM
deploystartB34 = [deploystartB34,'2012-09-18/10:57:15']
deployendB34   = [deployendB34,'2012-09-18/11:10:38']
lengthB34 = [lengthB34,25]
;18-SEP-2012	10:57:15	START DEPLOY 3-4 BOOMS TO 25-M STROKE, 105 CLICKS	SPIN RATE 10.21 RPM
;****Aaron's Note: I think the time 10:10:38 must be 11:11:38
;18-SEP-2012	10:10:38	END DEPLOY 3-4 BOOMS TO 25-M STROKE, 105 CLICKS	SPIN RATE 9.45 RPM

deploystartB12 = [deploystartB12,'2012-09-19/23:02:40']
deployendB12   = [deployendB12,'2012-09-19/23:15:45']
lengthB12 = [lengthB12,30]
;19-SEP-2012	23:02:40	START DEPLOY 1-2 BOOMS TO 30-M STROKE, 105 CLICKS	SPIN RATE 9.45 RPM
;19-SEP-2012	23:15:45	END DEPLOY 1-2 BOOMS TO 30-M STROKE, 105 CLICKS	SPIN RATE 8.62 RPM
deploystartB34 = [deploystartB34,'2012-09-19/23:19:15']
deployendB34   = [deployendB34,'2012-09-19/23:32:37']
lengthB34 = [lengthB34,30]
;19-SEP-2012	23:19:15	START DEPLOY 3-4 BOOMS TO 30-M STROKE, 105 CLICKS	SPIN RATE 8.62 RPM
;19-SEP-2012	23:32:37	END DEPLOY 3-4 BOOMS TO 30-M STROKE, 105 CLICKS	SPIN RATE 7.92 RPM


deploystartB12 = [deploystartB12,'2012-09-21/10:12:50']
deployendB12   = [deployendB12,'2012-09-21/10:25:55']
lengthB12 = [lengthB12,35]
;21-SEP-2012	10:12:50	START DEPLOY 1-2 BOOMS TO 35-M STROKE, 105 CLICKS	SPIN RATE 11.03 RPM
;21-SEP-2012	10:25:55	END DEPLOY 1-2 BOOMS TO 35-M STROKE, 105 CLICKS	SPIN RATE 10.01 RPM
deploystartB34 = [deploystartB34,'2012-09-21/10:28:10']
deployendB34   = [deployendB34,'2012-09-21/10:41:27']
lengthB34 = [lengthB34,35]
;21-SEP-2012	10:28:10	START DEPLOY 3-4 BOOMS TO 35-M STROKE, 105 CLICKS	SPIN RATE 10.01 RPM
;21-SEP-2012	10:41:27	END DEPLOY 3-4 BOOMS TO 35-M STROKE, 105 CLICKS	SPIN RATE 9.17 RPM

deploystartB12 = [deploystartB12,'2012-09-21/10:44:40']
deployendB12   = [deployendB12,'2012-09-21/10:57:43']
lengthB12 = [lengthB12,40]
;21-SEP-2012	10:44:40	START DEPLOY 1-2 BOOMS TO 40-M STROKE, 105 CLICKS	SPIN RATE 9.17 RPM
;21-SEP-2012	10:57:43	END DEPLOY 1-2 BOOMS TO 40-M STROKE, 105 CLICKS	SPIN RATE 8.33 RPM
deploystartB34 = [deploystartB34,'2012-09-21/11:01:40']
deployendB34   = [deployendB34,'2012-09-21/11:14:59']
lengthB34 = [lengthB34,40]
;21-SEP-2012	11:01:40	START DEPLOY 3-4 BOOMS TO 40-M STROKE, 105 CLICKS	SPIN RATE 8.33 RPM
;21-SEP-2012	11:14:59	END DEPLOY 3-4 BOOMS TO 40-M STROKE, 105 CLICKS	SPIN RATE 7.62 RPM

deploystartB12 = [deploystartB12,'2012-09-22/21:35:30']
deployendB12   = [deployendB12,'2012-09-22/21:48:41']
lengthB12 = [lengthB12,45]
;22-SEP-2012	21:35:30	START DEPLOY 1-2 BOOMS TO 45-M STROKE, 105 CLICKS	SPIN RATE 7.62 RPM
;22-SEP-2012	21:48:41	END DEPLOY 1-2 BOOMS TO 45-M STROKE, 105 CLICKS	SPIN RATE 6.93 RPM
deploystartB34 = [deploystartB34,'2012-09-22/21:50:30']
deployendB34   = [deployendB34,'2012-09-22/22:03:57']
lengthB34 = [lengthB34,45]
;22-SEP-2012	21:50:30	START DEPLOY 3-4 BOOMS TO 45-M STROKE, 105 CLICKS	SPIN RATE 6.93 RPM
;22-SEP-2012	22:03:57	END DEPLOY 3-4 BOOMS TO 45-M STROKE, 105 CLICKS	SPIN RATE 6.35 RPM

deploystartB12 = [deploystartB12,'2012-09-22/22:06:40']
deployendB12   = [deployendB12,'2012-09-22/22:17:23']
lengthB12 = [lengthB12,49.1]
;22-SEP-2012	22:06:40	START DEPLOY 1-2 BOOMS TO 49.1-M STROKE, 86 CLICKS	SPIN RATE 6.35 RPM
;22-SEP-2012	22:17:23	END DEPLOY 1-2 BOOMS TO 49.1-M STROKE, 86 CLICKS	SPIN RATE 5.88 RPM
deploystartB34 = [deploystartB34,'2012-09-22/22:20:30']
deployendB34   = [deployendB34,'2012-09-22/22:31:31']
lengthB34 = [lengthB34,49.1]
;22-SEP-2012	22:20:30	START DEPLOY 3-4 BOOMS TO 49.1-M STROKE, 86 CLICKS	SPIN RATE 5.88 RPM
;22-SEP-2012	22:31:31	END DEPLOY 3-4 BOOMS TO 49.1-M STROKE, 86 CLICKS	SPIN RATE 5.48 RPM
; TOTAL RADIAL DIPOLE AT 100.02 M TIP-TO-TIP.
;
;
deploystartB5 = '2012-09-24/20:33:00'
deployendB5	  = '2012-09-24/20:33:00'
lengthB5 = 0.08
;24-SEP-2012	20:33:00	AFT-V5 STACER DEPLOY, 10 CLICKS CMD, 12 CLICKS DEP, 0.08-M TOTAL STROKE
deploystartB5 = [deploystartB5,'2012-09-24/20:36:00']
deployendB5 = 	[deployendB5,'2012-09-24/20:36:00']
lengthB5 = [lengthB5,1.41]
;24-SEP-2012	20:36:00	AFT-V5 STACER DEPLOY, 200 CLICKS CMD, 203 CLICKS DEP, 1.41-M TOTAL STROKE
deploystartB5 = [deploystartB5,'2012-09-24/20:38:30']
deployendB5 = 	[deployendB5,'2012-09-24/20:38:30']
lengthB5 = [lengthB5,2.72]
;24-SEP-2012	20:38:30	AFT-V5 STACER DEPLOY, 200 CLICKS CMD, 203 CLICKS DEP, 2.72-M TOTAL STROKE
deploystartB5 = [deploystartB5,'2012-09-24/20:42:30']
deployendB5 = 	[deployendB5,'2012-09-24/20:42:30']
lengthB5 = [lengthB5,4.02]
;24-SEP-2012	20:42:30	AFT-V5 STACER DEPLOY, 216 CLICKS CMD, 219 CLICKS DEP, 4.02-M TOTAL STROKE

deploystartB6 = '2012-09-24/20:46:30'
deployendB6	  = '2012-09-24/20:46:30'
lengthB6 = 0.07
;24-SEP-2012	20:46:30	FWD-V6 STACER DEPLOY, 10 CLICKS CMD, 11 CLICKS DEP, 0.07-M TOTAL STROKE
deploystartB6 = [deploystartB6,'2012-09-24/20:49:00']
deployendB6 = 	[deployendB6,'2012-09-24/20:49:00']
lengthB6 = [lengthB6,1.40]
;24-SEP-2012	20:49:00	FWD-V6 STACER DEPLOY, 200 CLICKS CMD, 202 CLICKS DEP, 1.40-M TOTAL STROKE
deploystartB6 = [deploystartB6,'2012-09-24/20:52:00']
deployendB6 = 	[deployendB6,'2012-09-24/20:52:00']
lengthB6 = [lengthB6,2.69]
;24-SEP-2012	20:52:00	FWD-V6 STACER DEPLOY, 200 CLICKS CMD, 201 CLICKS DEP, 2.69-M TOTAL STROKE
deploystartB6 = [deploystartB6,'2012-09-24/20:56:00']
deployendB6 = 	[deployendB6,'2012-09-24/20:56:00']
lengthB6 = [lengthB6,4.02]
;24-SEP-2012	20:56:00	FWD-V6 STACER DEPLOY, 223 CLICKS CMD, 224? CLICKS DEP, 4.02-M TOTAL STROKE
; TOTAL AXIAL DIPOLE AT 10.0-M TIP-TO-TIP.
;
;
deploystartB5 = [deploystartB5,'2012-10-12/16:36:37']
deployendB5 = 	[deployendB5,'2012-10-12/16:36:37']
lengthB5 = [lengthB5,1.11]
;12-OCT-2012	16:36:37	AFT-V5 STACER DEPLOY, 181 CLICKS DEP, 1.11-M ADDL STROKE, 5.13-M TOTAL STROKE
deploystartB6 = [deploystartB6,'2012-10-12/16:57:30']
deployendB6 = 	[deployendB6,'2012-10-12/16:57:30']
lengthB6 = [lengthB6,4.53]
;12-OCT-2012	16:57:30	FWD-V6 STACER DEPLOY, 81 CLICKS DEP, 0.51-M ADDL STROKE, 4.53-M TOTAL STROKE
; TOTAL AXIAL DIPOLE AT 11.6-M TIP-TO-TIP.
;
deploystartB5 = [deploystartB5,'2012-10-23/20:18:00']
deployendB5 = 	[deployendB5,'2012-10-23/20:45:00']
lengthB5 = [lengthB5,5.9]
;23-OCT-2012	20:18:00	START AFT-V5 STACER DEPLOY.
;23-OCT-2012	20:45:00	END AFT-V5 STACER DEPLOY, 149 CLICKS TOTAL, 5.9-M TOTAL STROKE.
;	NOTE:  NO FWD-V6 STACER OPERATIONS.
; TOTAL AXIAL DIPOLE AT 12.4-M TIP-TO-TIP.
;
;
;
;
; AXB TRIM #3:
deploystartB6 = [deploystartB6,'2012-11-09/22:07:00']
deployendB6 = 	[deployendB6,'2012-11-09/22:07:45']
lengthB6 = [lengthB6,5.46]
;09-NOV-2012	22:07:00	START FWD-V6 STACER DEPLOY.
;09-NOV-2012	22:07:45	END FWD-V6 STACER DEPLOY, 186 CLICKS DEP, 0.93-M ADDL STROKE, 5.46-M TOTAL STROKE.
; NO OPERATIONS ON AFT-V5 STACER; STOKE REMAINS AT 5.9-M TOTAL.
; TOTAL AXIAL DIPOLE AT 13.3-M TIP-TO-TIP.
;
; AXB TRIM #4:
deploystartB6 = [deploystartB6,'2012-12-07/17:24:30']
deployendB6 = 	[deployendB6,'2012-12-07/17:24:50']
lengthB6 = [lengthB6,5.71]
;07-DEC 2012	17:24:30	START FWD-V6 STACER DEPLOY.
;07-DEC 2012	17:24:50	END FWD-V6 STACER DEPLOY, 48 CLICKS DEP, 0.25-M ADDL STROKE, 5.71-M TOTAL STROKE.
; NO OPERATIONS ON AFT-V5 STACER; STROKE REMAINS AT 6.0-M.
; TOTAL AXIAL DIPOLE AT 13.55-M, TIP-TO-TIP.
;


;Structure with all mission values
av = {deploystartA12:deploystartA12,$
      deploystartA34:deploystartA34,$
      deploystartA5:deploystartA5,$
      deploystartA6:deploystartA6,$
      deployendA12:deployendA12,$
      deployendA34:deployendA34,$
      deployendA5:deployendA5,$
      deployendA6:deployendA6,$
      lengthA12:lengthA12,$
      lengthA34:lengthA34,$
      lengthA5:lengthA5,$
      lengthA6:lengthA6,$
      deploystartB12:deploystartB12,$
      deploystartB34:deploystartB34,$
      deploystartB5:deploystartB5,$
      deploystartB6:deploystartB6,$
      deployendB12:deployendB12,$
      deployendB34:deployendB34,$
      deployendB5:deployendB5,$
      deployendB6:deployendB6,$
      lengthB12:lengthB12,$
      lengthB34:lengthB34,$
      lengthB5:lengthB5,$
      lengthB6:lengthB6}





;now let's determine what the lengths are at the time requested
;		 To Convert SPB total stroke to dipole tip-to-tip, double stroke length and 
;		 add 1.82 m; e.g. 20-m stroke = 41.8-m tip-to-tip dipole.

;		 To convert AXB total stroke to dipole tip-to-tip, add AFT and FWD total strokes 
;		 and add 1.2 m for deck spacing and 0.76 m for whip and sphere
;		 e.g. 4.02-m stroke on FWD and AFT AXB stacers gives a dipole tip-to-tip of 10.0 m.


tdiff = time_double(datetime) - time_double(deployendA12)
goo = where(tdiff ge 0)
if goo[0] ne -1 then mn = min(tdiff[goo],wh) else mn = -1
if mn ne -1 then blength_A12 = 2*lengthA12[wh] + 1.82 else blength_A12 = -1

tdiff = time_double(datetime) - time_double(deployendA34)
goo = where(tdiff ge 0)
if goo[0] ne -1 then mn = min(tdiff[goo],wh) else mn = -1
if mn ne -1 then blength_A34 = 2*lengthA34[wh] + 1.82 else blength_A34 = -1

tdiff = time_double(datetime) - time_double(deployendB12)
goo = where(tdiff ge 0)
if goo[0] ne -1 then mn = min(tdiff[goo],wh) else mn = -1
if mn ne -1 then blength_B12 = 2*lengthB12[wh] + 1.82 else blength_B12 = -1

tdiff = time_double(datetime) - time_double(deployendB34)
goo = where(tdiff ge 0)
if goo[0] ne -1 then mn = min(tdiff[goo],wh) else mn = -1
if mn ne -1 then blength_B34 = 2*lengthB34[wh] + 1.82 else blength_B34 = -1



tdiff = time_double(datetime) - time_double(deployendA5)
goo = where(tdiff ge 0)
if goo[0] ne -1 then mn = min(tdiff[goo],wh) else mn = -1
if mn ne -1 then blength_A5 = lengthA5[wh] + 1.82 else blength_A5 = -1

tdiff = time_double(datetime) - time_double(deployendA6)
goo = where(tdiff ge 0)
if goo[0] ne -1 then mn = min(tdiff[goo],wh) else mn = -1
if mn ne -1 then blength_A6 = lengthA6[wh] + 1.82 else blength_A6 = -1

if blength_A5 eq -1 and blength_A6 eq -1 then blength_A56 = -1
if blength_A5 ne -1 and blength_A6 ne -1 then blength_A56 = blength_A5 + blength_A6 + 1.2 + 0.76
if blength_A5 eq -1 and blength_A6 ne -1 then blength_A56 = blength_A6 + 1.2 + 0.76
if blength_A5 ne -1 and blength_A6 eq -1 then blength_A56 = blength_A5 + 1.2 + 0.76




tdiff = time_double(datetime) - time_double(deployendB5)
goo = where(tdiff ge 0)
if goo[0] ne -1 then mn = min(tdiff[goo],wh) else mn = -1
if mn ne -1 then blength_B5 = lengthB5[wh] + 1.82 else blength_B5 = -1

tdiff = time_double(datetime) - time_double(deployendB6)
goo = where(tdiff ge 0)
if goo[0] ne -1 then mn = min(tdiff[goo],wh) else mn = -1
if mn ne -1 then blength_B6 = lengthB6[wh] + 1.82 else blength_B6 = -1

if blength_B5 eq -1 and blength_B6 eq -1 then blength_B56 = -1
if blength_B5 ne -1 and blength_B6 ne -1 then blength_B56 = blength_B5 + blength_B6 + 1.2 + 0.76
if blength_B5 eq -1 and blength_B6 ne -1 then blength_B56 = blength_B6 + 1.2 + 0.76
if blength_B5 ne -1 and blength_B6 eq -1 then blength_B56 = blength_B5 + 1.2 + 0.76


lengths = {datetime:datetime,$
           A12:blength_A12,$
           A34:blength_A34,$
           B12:blength_B12,$
           B34:blength_B34,$
           A56:blength_A56,$
           B56:blength_B56}


return,lengths


end









