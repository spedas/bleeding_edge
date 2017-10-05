; efw_b1_cmd crib.pro
;
; NOTES:
;   - run with IDL> .run b1_cmd_crib
;   - put an `end` after each block of new requests
;
; Created by Kris Kersten, kris.kersten@gmail.com
;
;
;$LastChangedBy: aaronbreneman $
;$LastChangedDate: 2013-08-05 12:15:35 -0700 (Mon, 05 Aug 2013) $
;$LastChangedRevision: 12792 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/b1_cmd_crib.pro $


rbsp_efw_init,remote_data_dir='http://rbsp.space.umn.edu/data/rbsp/'





;RBSP-A 7/31/2013 14:27:00-14:30:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-31',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-31/14:27:00 - 2013-07-31/14:30:00):'
trange=time_double(['2013-07-31/14:27:00','2013-07-31/14:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
end



;RBSP-B 7/31/2013 12:50:00-12:52:00 UTC (2 minutes)  
;Holzworth lightning request
timespan,'2013-07-31',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-31/12:50:00 - 2013-07-31/12:52:00):'
trange=time_double(['2013-07-31/12:50:00','2013-07-31/12:52:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
end



;RBSP-B 7/31/2013 12:56:00-12:57:00 UTC (1 minute)
;Holzworth lightning request
timespan,'2013-07-31',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-31/12:56:00 - 2013-07-31/12:57:00):'
trange=time_double(['2013-07-31/12:56:00','2013-07-31/12:57:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
end



;RBSP-A 7/30/2013 11:16:00-11:19:00 UTC  (3 minutes)
;Holzworth lightning request
timespan,'2013-07-30',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-30/11:16:00 - 2013-07-30/11:19:00):'
trange=time_double(['2013-07-30/11:16:00','2013-07-30/11:19:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
end


;RBSP-B 7/30/2013 19:17:00-19:21:00 UTC (4 minutes)  <-- 4 minutes
;Holzworth lightning request
timespan,'2013-07-30',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-30/19:17:00 - 2013-07-30/19:21:00):'
trange=time_double(['2013-07-30/19:17:00','2013-07-30/19:21:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
end






















;RBSP-A 7/29/2013 17:46:00-17:48:00 UTC (2 minutes) 
;Holzworth lightning request
timespan,'2013-07-29',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-29/17:46:00 - 2013-07-29/17:48:00):'
trange=time_double(['2013-07-29/17:46:00','2013-07-29/17:48:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
end

;RBSP-A 7/29/2013 17:52:00-17:53:00 UTC (2 minutes) 
;Holzworth lightning request
timespan,'2013-07-29',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-29/17:52:00 - 2013-07-29/17:53:00):'
trange=time_double(['2013-07-29/17:52:00','2013-07-29/17:53:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
end

;RBSP-B 7/29/2013 15:53:00-15:56:00 UTC (2 minutes) 
;Holzworth lightning request
timespan,'2013-07-29',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-29/15:53:00 - 2013-07-29/15:56:00):'
trange=time_double(['2013-07-29/15:53:00','2013-07-29/15:56:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 154038, 46)
end


;RBSP-A 7/28/2013 14:37:00-14:39:00 UTC (2 minutes) 
;Holzworth lightning request
timespan,'2013-07-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-28/14:37:00 - 2013-07-28/14:39:00):'
trange=time_double(['2013-07-28/14:37:00','2013-07-28/14:39:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 36708, 481)
end


;RBSP-A 7/28/2013 14:43:00-14:44:00 UTC (1 minute)
;Holzworth lightning request
timespan,'2013-07-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-28/14:43:00 - 2013-07-28/14:44:00):'
trange=time_double(['2013-07-28/14:43:00','2013-07-28/14:44:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 38147, 239)
end




;RBSP-B 7/28/2013 12:34:00-12:35:00 UTC (1 minute) and 
;Holzworth lightning request
timespan,'2013-07-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		       '    (2013-07-28/12:34:00 - 2013-07-28/12:35:00):'
trange=time_double(['2013-07-28/12:34:00','2013-07-28/12:35:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 127527, 242)
end


;RBSP-B 7/28/2013 12:40:00-12:42:00 UTC (2 minutes)
;Holzworth lightning request
timespan,'2013-07-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		       '    (2013-07-28/12:40:00 - 2013-07-28/12:42:00):'
trange=time_double(['2013-07-28/12:40:00','2013-07-28/12:42:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 128976, 487)
end





;Have NOT send in the request on 19:08:00-19:09:00 UTC (1 minute)
;Holzworth lightning request
timespan,'2013-07-27',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-27/19:08:00 - 2013-07-27/19:09:00):'
trange=time_double(['2013-07-27/19:08:00','2013-07-27/19:09:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 111073, 242)
end

;RBSP-B 7/27/2013 14:30:00-16:00:00 UTC (90 minutes)
timespan,'2013-07-27',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		       '    (2013-07-27/14:30:00 - 2013-07-27/16:00:00):'
trange=time_double(['2013-07-27/14:30:00','2013-07-27/16:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 104867, 1353)
end



























;RBSP-A 7/24/2013 11:38:00-11:39:00 (1 minute) 
;Holzworth lightning request
timespan,'2013-07-24',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-24/11:38:00 - 2013-07-24/11:39:00):'
trange=time_double(['2013-07-24/11:38:00','2013-07-24/11:39:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 202552, 236)
end

;RBSP-A 7/24/2013 11:42-11:44:00 ;UTC (2 minutes)
;Holzworth lightning request
timespan,'2013-07-24',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-24/11:42:00 - 2013-07-24/11:44:00):'
trange=time_double(['2013-07-24/11:42:00','2013-07-24/11:44:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 203508, 484)
end


;RBSP-B 7/24/2013 18:48:00-18:51:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-24',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-24/18:48:00 - 2013-07-24/18:51:00):'
trange=time_double(['2013-07-24/18:48:00','2013-07-24/18:51:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 38457, 726)
end


;RBSP-A 7/25/2013 14:47:00-14:50:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-25',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-25/14:47:00 - 2013-07-25/14:50:00):'
trange=time_double(['2013-07-25/14:47:00','2013-07-25/14:50:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 205675, 721)
end

;RBSP-B 7/25/2013 12:26:00-12:29:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-25',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-25/12:26:00 - 2013-07-25/12:29:00):'
trange=time_double(['2013-07-25/12:26:00','2013-07-25/12:29:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 55997, 721)
end



;RBSP-A 7/26/2013 17:59:00-18:02:00 UTC (3 minutes) - low priority
;Holzworth lightning request
timespan,'2013-07-26',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-26/17:59:00 - 2013-07-26/18:02:00):'
trange=time_double(['2013-07-26/17:59:00','2013-07-26/18:02:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 208799, 719)
end

;RBSP-B 7/26/2013 03:00:00-04:00:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-26',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-26/03:00:00 - 2013-07-26/04:00:00):'
trange=time_double(['2013-07-26/03:00:00','2013-07-26/04:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 70537, 902)
end

;RBSP-B 7/26/2013 15:42:00-15:45:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-26',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-26/15:42:00 - 2013-07-26/15:45:00):'
trange=time_double(['2013-07-26/15:42:00','2013-07-26/15:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 82894, 722)
end



;RBSP-A 7/27/2013 11:30-11:32:00 UTC (2 minutes)
;Holzworth lightning request
timespan,'2013-07-27',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-27/11:30:00 - 2013-07-27/11:32:00):'
trange=time_double(['2013-07-27/11:30:00','2013-07-27/11:32:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 252707, 483)
end

;RBSP-B 7/27/2013 19:04:00-19:06:00 UTC (2 minutes) 
;Holzworth lightning request
timespan,'2013-07-27',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
		          ' (2013-07-27/19:04:00 - 2013-07-27/19:06:00):'
trange=time_double(['2013-07-27/19:04:00','2013-07-27/19:06:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 110113, 483)
end












;RBSP-A  7/23/2013 18:09:00-18:11:00 UTC (2 minutes)
;Holzworth lightning request
timespan,'2013-07-23',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-23/18:09:00 - 2013-07-23/18:11:00):'
trange=time_double(['2013-07-23/18:09:00','2013-07-23/18:11:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 201348, 479)
end



;RBSP-B  7/23/2013 15:27:00-15:30:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-23',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-23/15:27:00 - 2013-07-23/15:30:00):'
trange=time_double(['2013-07-23/15:27:00','2013-07-23/15:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 10819, 722)
end







;SUBMITTED
timespan,'2013-07-14',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-14/08:00:00 - 2013-07-14/11:10:00):'
trange=time_double(['2013-07-14/08:00:00','2013-07-14/11:10:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 8807, 11422)
end


timespan,'2013-07-14',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-14/18:30:00 - 2013-07-14/18:35:00):'
trange=time_double(['2013-07-14/18:30:00','2013-07-14/18:35:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 46666, 302)
end

timespan,'2013-07-14',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-14/18:46:30 - 2013-07-14/19:55:00):'
trange=time_double(['2013-07-14/18:46:30','2013-07-14/19:55:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 49465, 4125)
end




;##########################################
;NOT YET REQUESTED
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/00:35:00 - 2013-07-15/00:42:00):'
trange=time_double(['2013-07-15/00:35:00','2013-07-15/00:42:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 70412, 421)
end


;##########################################
;NOT YET REQUESTED
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/00:50:00 - 2013-07-15/01:35:00):'
trange=time_double(['2013-07-15/00:50:00','2013-07-15/01:35:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 71312, 2706)
end


;##########################################
;NOT YET REQUESTED
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/09:18:00 - 2013-07-15/09:25:00):'
trange=time_double(['2013-07-15/09:18:00','2013-07-15/09:25:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 101843, 421)
end


;##########################################
;NOT YET REQUESTED
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/09:45:00 - 2013-07-15/09:50:00):'
trange=time_double(['2013-07-15/09:45:00','2013-07-15/09:50:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 103463, 301)
end


;##########################################
;NOT YET REQUESTED
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/12:21:00 - 2013-07-15/14:20:00):'
trange=time_double(['2013-07-15/12:21:00','2013-07-15/14:20:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 114653, 7154)
end









timespan,'2013-07-19',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-19/04:00:00 - 2013-07-19/06:15:00):'
trange=time_double(['2013-07-19/04:00:00','2013-07-19/06:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 165922, 2027)
end


timespan,'2013-07-19',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-19/11:00:00 - 2013-07-19/15:00:00):'
trange=time_double(['2013-07-19/11:00:00','2013-07-19/15:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 172230, 5915)
end


timespan,'2013-07-19',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-19/21:00:00 - 2013-07-19/24:00:00):'
trange=time_double(['2013-07-19/21:00:00','2013-07-19/24:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 183554, 2706)
end


timespan,'2013-07-20',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-20/00:00:00 - 2013-07-20/03:00:00):'
trange=time_double(['2013-07-20/00:00:00','2013-07-20/03:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 186259, 2707)
end


;##########################################
;NOT YET REQUESTED
timespan,'2013-07-20',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-20/06:30:00 - 2013-07-20/13:00:00):'
trange=time_double(['2013-07-20/06:30:00','2013-07-20/13:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 192126, 5857)
end






















;RBSP-A 7/22/2013  14:58:00-15:01:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-22',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-22/14:58:00 - 2013-07-22/15:01:00):'
trange=time_double(['2013-07-22/14:58:00','2013-07-22/15:01:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 198701, 722)
end



;RBSP-B 7/22/2013 12:09:00-12:11:00  UTC (2 minutes)
;                and 12:14-12:16:00 (2 minutes)
;Holzworth lightning request
timespan,'2013-07-22',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-22/12:09:00 - 2013-07-22/12:11:00):'
trange=time_double(['2013-07-22/12:09:00','2013-07-22/12:11:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 245355, 481)
end

;Holzworth lightning request
timespan,'2013-07-22',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-22/12:14:00 - 2013-07-22/12:16:00):'
trange=time_double(['2013-07-22/12:14:00','2013-07-22/12:16:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 246557, 482)
end










;RBSP-A 7/21/2013 11:52:00-11:55:00 UTC ( 3 minutes)
;Holzworth lightning request
timespan,'2013-07-21',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-21/11:52:00 - 2013-07-21/11:55:00):'
trange=time_double(['2013-07-21/11:52:00','2013-07-21/11:55:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 196296, 722)
end

;RBSP-B 7/21/2013 18:35:00-18:38:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-21',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-21/18:35:00 - 2013-07-21/18:38:00):'
trange=time_double(['2013-07-21/18:35:00','2013-07-21/18:38:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 228559, 722)
end




;RBSP-A 7/20/2013  18:16:00-18:19:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-20',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-20/18:16:00 - 2013-07-20/18:19:00):'
trange=time_double(['2013-07-20/18:16:00','2013-07-20/18:19:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 193649, 720)
end


;RBSP-B 7/20/2013  15:13:00-15:16:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-20',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-20/15:13:00 - 2013-07-20/15:16:00):'
trange=time_double(['2013-07-20/15:13:00','2013-07-20/15:16:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 200883, 723)
end


RBSP-A 7/19/2013 15:10:00-15:12:00 UTC  (2 minutes)
;Holzworth lightning request
timespan,'2013-07-19',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-19/15:10:00 - 2013-07-19/15:12:00):'
trange=time_double(['2013-07-19/15:10:00','2013-07-19/15:12:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 191729, 479)
end


RBSP-B 7/19/2013 11:54:00-11:57:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-19',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-19/11:54:00 - 2013-07-19/11:57:00):'
trange=time_double(['2013-07-19/11:54:00','2013-07-19/11:57:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 173040, 717)
end





RBSP-A 7/18/2013 11:59:00-12:02:00 UTC (3 minutes)
;Holzworth lightning request
timespan,'2013-07-18',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-18/11:59:00 - 2013-07-18/12:02:00):'
trange=time_double(['2013-07-18/11:59:00','2013-07-18/12:02:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 171290, 717)
end

RBSP-B 7/18/2013 18:16:00-18:19:00 UTC  (3 minutes)
;Holzworth lightning request
timespan,'2013-07-18',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-18/18:16:00 - 2013-07-18/18:19:00):'
trange=time_double(['2013-07-18/18:16:00','2013-07-18/18:19:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 155273, 721)
end






RBSP-A 7/17/2013 18:27:00-18:30:00 UTC (3 minutes)

;Holzworth lightning request
timespan,'2013-07-17',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-17/18:27:00 - 2013-07-17/18:30:00):'
trange=time_double(['2013-07-17/18:27:00','2013-07-17/18:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 146866, 726)
end


RBSP-B 7/17/2013 14:59:00-15:02:00 UTC (3 minutes)

;Holzworth lightning request
timespan,'2013-07-17',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-17/14:59:00 - 2013-07-17/15:02:00):'
trange=time_double(['2013-07-17/14:59:00','2013-07-17/15:02:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 128796, 728)
end



;1024 playback request
timespan,'2013-07-14',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-14/11:00:00 - 2013-07-14/14:00:00):'
trange=time_double(['2013-07-14/11:00:00','2013-07-14/14:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 52441, 2702)
end


;1024 playback request
timespan,'2013-07-14',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'
cmd_string = ''
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-14/16:00:00 - 2013-07-14/18:00:00):'
trange=time_double(['2013-07-14/16:00:00','2013-07-14/18:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 59254, 1807)
end


;1024 playback request
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/19:30:00 - 2013-07-15/22:00:00):'
trange=time_double(['2013-07-15/19:30:00','2013-07-15/22:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 86368, 2258)
end






;RBSP-A 7/16/2013 15:19:00-15:22:00 UTC (3 minutes)

;Holzworth lightning times
timespan,'2013-07-16',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-16/15:19:00 - 2013-07-16/15:22:00):'
trange=time_double(['2013-07-16/15:19:00','2013-07-16/15:22:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 144941, 726)
end


;RBSP-B 7/16/2013 11:44:00-11:47:00 UTC (3 minutes)

timespan,'2013-07-16',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-16/11:44:00 - 2013-07-16/11:47:00):'
trange=time_double(['2013-07-16/11:44:00','2013-07-16/11:47:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 101906, 719)
end








;RBSP-A 7/15/2013 12:10:00-12:11:00 UTC (1 minute) and 
;12:15:00-12:17:00 UTC (2 minutes)

;Holzworth lightning times
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/12:10:00 - 2013-07-15/12:11:00):'
trange=time_double(['2013-07-15/12:10:00','2013-07-15/12:11:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 112191, 242)
end


;Holzworth lightning times
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/12:15:00 - 2013-07-15/12:17:00):'
trange=time_double(['2013-07-15/12:15:00','2013-07-15/12:17:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 113398, 484)
end



;RBSP-B 7/15/2013 18:00:00-18:02:00 UTC (2 minutes) and 
;18:07:00-18:08:00 UTC (1 minute)

;Holzworth lightning times
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/18:00:00 - 2013-07-15/18:02:00):'
trange=time_double(['2013-07-15/18:00:00','2013-07-15/18:02:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 82923, 482)
end

;Holzworth lightning times
timespan,'2013-07-15',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-15/18:07:00 - 2013-07-15/18:08:00):'
trange=time_double(['2013-07-15/18:07:00','2013-07-15/18:08:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 84609, 241)
end



;Holzworth lightning times
timespan,'2013-07-14',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-14/18:36:00 - 2013-07-14/18:44:00):'
trange=time_double(['2013-07-14/18:36:00','2013-07-14/18:44:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 47033, 1929)
end


;Holzworth lightning times
timespan,'2013-07-14',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-14/14:46:00 - 2013-07-14/14:48:00):'
trange=time_double(['2013-07-14/14:46:00','2013-07-14/14:48:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 56959, 483)
end






;RBSP-A 7/13/2013  15:31:00-15:33:00 UTC (2 minutes)
;             and 15:34:00-15:35:00 utc (1 minute)
;RBSP-B 7/13/2013  11:26:00-11:28:00 UTC (2 minutes)


;Holzworth lightning times
timespan,'2013-07-13',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-13/15:31:00 - 2013-07-13/15:33:00):'
trange=time_double(['2013-07-13/15:31:00','2013-07-13/15:33:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 257964, 483)
end


timespan,'2013-07-13',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-13/15:34:00 - 2013-07-13/15:35:00):'
trange=time_double(['2013-07-13/15:34:00','2013-07-13/15:35:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 258686, 240)
end


;Holzworth lightning times
timespan,'2013-07-13',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-13/11:26:00 - 2013-07-13/11:28:00):'
trange=time_double(['2013-07-13/11:26:00','2013-07-13/11:28:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 28878, 481)
end




;Plasmasphere spanning 
timespan,'2013-07-11',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-11/11:00:00 - 2013-07-11/12:00:00):'
trange=time_double(['2013-07-11/11:00:00','2013-07-11/12:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 217205, 3609)
end



;Plasmasphere spanning 
timespan,'2013-07-10',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-10/08:55:00 - 2013-07-10/11:05:00):'
trange=time_double(['2013-07-10/08:55:00','2013-07-10/11:05:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 216904, 1953)
end

timespan,'2013-07-10',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-10/11:25:00 - 2013-07-10/13:30:00):'
trange=time_double(['2013-07-10/11:25:00','2013-07-10/13:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 221467, 1882)
end





;RBSP-A 7/12/2013 12:20:00-12:23:00 UTC  (3 minutes) 

;Holzworth lightning times
timespan,'2013-07-12',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-12/12:20:00 - 2013-07-12/12:23:00):'
trange=time_double(['2013-07-12/12:20:00','2013-07-12/12:23:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 254368, 718)
end



;RBSP-B 7/12/2013 17:48:00-17:52:00 UTC (4 minutes)
;Holzworth lightning times
timespan,'2013-07-12',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-12/17:48:00 - 2013-07-12/17:52:00):'
trange=time_double(['2013-07-12/17:48:00','2013-07-12/17:52:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 11120, 962)
end




;RBSP-A 7/11/2013 18:51:00-18:54:00 UTC (3 minutes)
;RBSP-B 7/11/2013 14:26:00-14:27:00 UTC (1 minute) and 14:29:00-14:31:00 UTC (2 minutes)
;                or if easier: 14:26:00-14:31:00 (5 minutes)

;Holzworth lightning times
timespan,'2013-07-11',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-11/18:51:00 - 2013-07-11/18:54:00):'
trange=time_double(['2013-07-11/18:51:00','2013-07-11/18:54:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 246267, 720)
end



;Holzworth lightning times (group1)
timespan,'2013-07-11',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-11/14:26:00 - 2013-07-11/14:27:00):'
trange=time_double(['2013-07-11/14:26:00','2013-07-11/14:27:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 245823, 239)
end


;Holzworth lightning times (group2)
timespan,'2013-07-11',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-11/14:29:00 - 2013-07-11/14:31:00):'
trange=time_double(['2013-07-11/14:29:00','2013-07-11/14:31:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 246541, 481)
end






;RBSP-A  7/10/2013 15:41:00-15:42:00 and 
;				  15:45:00-15:47:00 (1 min and then 2 min, or you can just download from
 ;                15:41:00- 15:47:00 (6 minutes) 

;Holzworth lightning times (Group 1)
timespan,'2013-07-10',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-10/15:41:00 - 2013-07-10/15:42:00):'
trange=time_double(['2013-07-10/15:41:00','2013-07-10/15:42:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 186771, 243)
end

;Holzworth lightning times (Group 2)
timespan,'2013-07-10',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-10/15:45:00 - 2013-07-10/15:47:00):'
trange=time_double(['2013-07-10/15:45:00','2013-07-10/15:47:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 187735, 478)
end

RBSP-B  7/10/2013 11:12:00-11:14:00 ( 2 minutes)  and 
			     11:15:00 to 11:16:00 (1 minute), or, again, you can
                 just download 11:12:00-11:16:00 (4 minutes

;Holzworth lightning times (Group 1)
timespan,'2013-07-10',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-10/11:12:00 - 2013-07-10/11:14:00):'
trange=time_double(['2013-07-10/11:12:00','2013-07-10/11:14:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 219187, 482)
end

;Holzworth lightning times (Group 2)
timespan,'2013-07-10',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-10/11:15:00 - 2013-07-10/11:16:00):'
trange=time_double(['2013-07-10/11:15:00','2013-07-10/11:16:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 219908, 242)
end






;RBSP-A 7/9/2013 12:35:00-12:38:00 UTC (3 minutes)
;RBSP-B 7/9/2013 17:36:00-17:39:00 UTC (3 minutes)

;Holzworth lightning times
timespan,'2013-07-09',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-09/12:35:00 - 2013-07-09/12:38:00):'
trange=time_double(['2013-07-09/12:35:00','2013-07-09/12:38:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 184368, 721)
end

;Holzworth lightning times
timespan,'2013-07-09',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-09/17:36:00 - 2013-07-09/17:39:00):'
trange=time_double(['2013-07-09/17:36:00','2013-07-09/17:39:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 201890, 724)
end



timespan,'2013-07-05',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-05/04:30:00 - 2013-07-05/06:30:00):'
trange=time_double(['2013-07-05/04:30:00','2013-07-05/06:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 136219, 1807)
end



;Edge of PS 200 Hz waves (group 1)
timespan,'2013-06-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/19:40:00 - 2013-06-28/19:55:00):'
trange=time_double(['2013-06-28/19:40:00','2013-06-28/19:55:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 114689, 1402)
end

timespan,'2013-06-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/20:00:00 - 2013-06-28/21:10:00):'
trange=time_double(['2013-06-28/20:00:00','2013-06-28/21:10:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 117245, 2874)
end





;Edge of PS 200 Hz waves (group 1)
timespan,'2013-06-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/17:15:00 - 2013-06-28/17:52:00):'
trange=time_double(['2013-06-28/17:15:00','2013-06-28/17:52:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 238138, 8891)
end

;Edge of PS 200 Hz waves (group 2)
timespan,'2013-06-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/17:59:00 - 2013-06-28/18:10:00):'
trange=time_double(['2013-06-28/17:59:00','2013-06-28/18:10:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 248712, 2646)
end




;RBSPa - 7/8/2013 19:05:00-19:08:00 UTC (3 minutes)
;RBSPb - 7/8/2013 14:16:00-14:19:00 UTC (3 minutes)

;Holzworth lightning request
timespan,'2013-07-08',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-08/19:05:00 - 2013-07-08/19:08:00):'
trange=time_double(['2013-07-08/19:05:00','2013-07-08/19:08:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 182689, 720)
end



;Holzworth lightning request
timespan,'2013-07-08',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-08/14:16:00 - 2013-07-08/14:19:00):'
trange=time_double(['2013-07-08/14:16:00','2013-07-08/14:19:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 174711, 721)
end



;16 kS/s playback from Jun 28th
timespan,'2013-06-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/18:32:40 - 2013-06-28/18:34:20):'
trange=time_double(['2013-06-28/18:32:40','2013-06-28/18:34:20'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 256812, 399)
end



;RBSPa - 7/7/2-13 15:52:00-15:55:00 UTC (3 minutes - this is a great one, dont loose it!)
;RBSPb - 7/7/2-13 20:42:00-20:45:00 UTC (3 minutes)

;Holzworth lightning request
timespan,'2013-07-07',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-07/15:52:00 - 2013-07-07/15:55:00):'
trange=time_double(['2013-07-07/15:52:00','2013-07-07/15:55:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 179562, 721)
end

;Holzworth lightning request
timespan,'2013-07-07',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-07/20:42:00 - 2013-07-07/20:45:00):'
trange=time_double(['2013-07-07/20:42:00','2013-07-07/20:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 159731, 721)
end



;RBSPa - 7/6/2-13  12:44:00-12:47:00 UTC (3 minutes)
;RBSPb - 7/6/2-13  17:17:00-17:20:00 UTC (3 minutes)


;Holzworth lightning request
timespan,'2013-07-06',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-06/12:44:00 - 2013-07-06/12:47:00):'
trange=time_double(['2013-07-06/12:44:00','2013-07-06/12:47:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 176912, 724)
end


;Holzworth lightning request
timespan,'2013-07-06',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-06/17:17:00 - 2013-07-06/17:20:00):'
trange=time_double(['2013-07-06/17:17:00','2013-07-06/17:20:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 156601, 721)
end





;Request for playback for 4096 S/s times
timespan,'2013-07-05',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-05/05:00:00 - 2013-07-05/05:20:00):'
trange=time_double(['2013-07-05/05:00:00','2013-07-05/05:20:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 105804, 1202)
end


;Request for playback for 1024 S/s times
timespan,'2013-07-05',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-05/00:00:00 - 2013-07-05/01:50:00):'
trange=time_double(['2013-07-05/00:00:00','2013-07-05/01:50:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 132158, 1660)
end









;Holzworth lightning request
timespan,'2013-07-05',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-05/19:12:00 - 2013-07-05/19:15:00):'
trange=time_double(['2013-07-05/19:12:00','2013-07-05/19:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 157756, 721)
end

;Holzworth lightning request
timespan,'2013-07-05',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-05/14:02:00 - 2013-07-05/14:05:00):'
trange=time_double(['2013-07-05/14:02:00','2013-07-05/14:05:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 145961, 722)
end




;Holzworth lightning request
timespan,'2013-07-04',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-04/16:02:00 - 2013-07-04/16:05:00):'
trange=time_double(['2013-07-04/16:02:00','2013-07-04/16:05:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 86320, 719)
end


timespan,'2013-07-04',3
probe='a b'
rbsp_load_efw_b1,probe=probe
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-04/10:51:00 - 2013-07-04/10:53:00):'
trange=time_double(['2013-07-04/10:51:00','2013-07-04/10:53:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string
;util.QUEUE_B1PLAYBACK( 131676, 479)
end




; Holzworth request from 12:56 - 12:59. 
timespan,'2013-07-03',3
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-07-03/12:56:00 - 2013-07-03/12:59:00):'
trange=time_double(['2013-07-03/12:56:00','2013-07-03/12:59:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end



; Holzworth request from 19:54 - 20:00. We've already downloaded data
; through 19:58:30.
timespan,'2013-06-28',3
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/19:58:20 - 2013-06-28/20:00:00):'
trange=time_double(['2013-06-28/19:58:20','2013-06-28/20:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end




; additional check on the  RBSPA 16k mode
timespan,'2013-06-27',3
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/23:35:00 - 2013-06-28/23:40:00):'
trange=time_double(['2013-06-28/23:35:00','2013-06-28/23:40:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end


; now checking RBSPB buffer
timespan,'2013-06-27',3
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/12:35:00 - 2013-06-28/12:40:00):'
trange=time_double(['2013-06-28/12:35:00','2013-06-28/12:40:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/18:05:00 - 2013-06-28/18:10:00):'
trange=time_double(['2013-06-28/18:05:00','2013-06-28/18:10:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


end


; lightning playback, checking RBSPA buffer
timespan,'2013-06-27',3
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/04:00:00 - 2013-06-28/04:03:00):'
trange=time_double(['2013-06-28/04:00:00','2013-06-28/04:03:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/10:10:00 - 2013-06-28/10:13:00):'
trange=time_double(['2013-06-28/10:10:00','2013-06-28/10:13:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/16:22:00 - 2013-06-28/16:25:30):'
trange=time_double(['2013-06-28/16:22:00','2013-06-28/16:25:30'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end


; lightning playback
timespan,'2013-06-27',3
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/06:40:00 - 2013-06-28/06:45:00):'
trange=time_double(['2013-06-28/06:40:00','2013-06-28/06:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/19:55:00 - 2013-06-28/20:00:00):'
trange=time_double(['2013-06-28/19:55:00','2013-06-28/20:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end



; lightning playback, debugging
timespan,'2013-06-27',3
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/14:00:00 - 2013-06-27/15:00:00):'
trange=time_double(['2013-06-27/14:00:00','2013-06-27/15:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/15:00:00 - 2013-06-27/16:00:00):'
trange=time_double(['2013-06-27/15:00:00','2013-06-27/16:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:00:00 - 2013-06-27/17:00:00):'
trange=time_double(['2013-06-27/16:00:00','2013-06-27/17:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/17:00:00 - 2013-06-27/18:00:00):'
trange=time_double(['2013-06-27/17:00:00','2013-06-27/18:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/18:00:00 - 2013-06-27/19:00:00):'
trange=time_double(['2013-06-27/18:00:00','2013-06-27/19:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/19:00:00 - 2013-06-27/20:00:00):'
trange=time_double(['2013-06-27/19:00:00','2013-06-27/20:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/20:00:00 - 2013-06-27/21:00:00):'
trange=time_double(['2013-06-27/20:00:00','2013-06-27/21:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/21:00:00 - 2013-06-27/22:00:00):'
trange=time_double(['2013-06-27/21:00:00','2013-06-27/22:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/22:00:00 - 2013-06-27/23:00:00):'
trange=time_double(['2013-06-27/22:00:00','2013-06-27/23:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/23:00:00 - 2013-06-28/00:00:00):'
trange=time_double(['2013-06-27/23:00:00','2013-06-28/00:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-28/00:00:00 - 2013-06-28/01:00:00):'
trange=time_double(['2013-06-28/00:00:00','2013-06-28/01:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/14:00:00 - 2013-06-27/14:10:00):'
trange=time_double(['2013-06-27/14:00:00','2013-06-27/14:10:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/15:00:00 - 2013-06-27/15:10:00):'
trange=time_double(['2013-06-27/15:00:00','2013-06-27/15:10:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:00:00 - 2013-06-27/16:10:00):'
trange=time_double(['2013-06-27/16:00:00','2013-06-27/16:10:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:10:00 - 2013-06-27/16:20:00):'
trange=time_double(['2013-06-27/16:10:00','2013-06-27/16:20:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:20:00 - 2013-06-27/16:21:00):'
trange=time_double(['2013-06-27/16:20:00','2013-06-27/16:21:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:21:00 - 2013-06-27/16:22:00):'
trange=time_double(['2013-06-27/16:21:00','2013-06-27/16:22:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:22:00 - 2013-06-27/16:23:00):'
trange=time_double(['2013-06-27/16:22:00','2013-06-27/16:23:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:23:00 - 2013-06-27/16:24:00):'
trange=time_double(['2013-06-27/16:23:00','2013-06-27/16:24:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:24:00 - 2013-06-27/16:25:00):'
trange=time_double(['2013-06-27/16:24:00','2013-06-27/16:25:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:25:00 - 2013-06-27/16:26:00):'
trange=time_double(['2013-06-27/16:25:00','2013-06-27/16:26:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:26:00 - 2013-06-27/16:27:00):'
trange=time_double(['2013-06-27/16:26:00','2013-06-27/16:27:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:20:00 - 2013-06-27/16:25:00):'
trange=time_double(['2013-06-27/16:20:00','2013-06-27/16:25:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:21:00 - 2013-06-27/16:26:00):'
trange=time_double(['2013-06-27/16:21:00','2013-06-27/16:26:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-27/16:22:00 - 2013-06-27/16:27:00):'
trange=time_double(['2013-06-27/16:22:00','2013-06-27/16:27:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string




end


; B playback on 6/18, 6/17, 6/16
timespan,'2013-06-12',10
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-18/02:15:00 - 2013-06-18/04:45:00):'
trange=time_double(['2013-06-18/02:15:00','2013-06-18/04:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-18/08:45:00 - 2013-06-18/10:00:00):'
trange=time_double(['2013-06-18/08:45:00','2013-06-18/10:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-18/19:00:00 - 2013-06-18/22:00:00):'
trange=time_double(['2013-06-18/19:00:00','2013-06-18/22:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-17/07:00:00 - 2013-06-17/10:00:00):'
trange=time_double(['2013-06-17/07:00:00','2013-06-17/10:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-16/11:00:00 - 2013-06-16/17:30:00):'
trange=time_double(['2013-06-16/11:00:00','2013-06-16/17:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



end


; more A playback on 6/1
timespan,'2013-06-01',1
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-01/02:00:00 - 2013-06-01/02:30:00):'
trange=time_double(['2013-06-01/02:00:00','2013-06-01/02:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-01/12:15:00 - 2013-06-01/12:45:00):'
trange=time_double(['2013-06-01/12:15:00','2013-06-01/12:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-01/02:30:00 - 2013-06-01/05:00:00):'
trange=time_double(['2013-06-01/02:30:00','2013-06-01/05:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-01/22:30:00 - 2013-06-01/23:00:00):'
trange=time_double(['2013-06-01/22:30:00','2013-06-01/23:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



end




; B playback on 6/9, 6/10
timespan,'2013-06-09',2
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-09/02:00:00 - 2013-06-09/04:00:00):'
trange=time_double(['2013-06-09/02:00:00','2013-06-09/04:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-09/10:00:00 - 2013-06-09/13:30:00):'
trange=time_double(['2013-06-09/10:00:00','2013-06-09/13:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-10/02:30:00 - 2013-06-10/07:00:00):'
trange=time_double(['2013-06-10/02:30:00','2013-06-10/07:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end


; A, B playback after mode change
; A to 4096S/s
; B to 1024S/s

timespan,'2013-06-01',1
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-07/02:15:00 - 2013-06-07/03:15:00):'
trange=time_double(['2013-06-07/02:15:00','2013-06-07/03:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-07/04:30:00 - 2013-06-07/06:30:00):'
trange=time_double(['2013-06-07/04:30:00','2013-06-07/06:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-07/02:00:00 - 2013-06-07/06:00:00):'
trange=time_double(['2013-06-07/02:00:00','2013-06-07/06:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-07/07:45:00 - 2013-06-07/11:45:00):'
trange=time_double(['2013-06-07/07:45:00','2013-06-07/11:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



end




timespan,'2013-06-01',1
probe='a b'
rbsp_load_efw_b1,probe=probe


; RBSPA 2013-06-01
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-01/05:30:00 - 2013-06-01/06:00:00):'
trange=time_double(['2013-06-01/05:30:00','2013-06-01/06:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-01/06:00:00 - 2013-06-01/06:30:00):'
trange=time_double(['2013-06-01/06:00:00','2013-06-01/06:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-01/05:00:00 - 2013-06-01/05:30:00):'
trange=time_double(['2013-06-01/05:00:00','2013-06-01/05:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-06-01/06:30:00 - 2013-06-01/07:00:00):'
trange=time_double(['2013-06-01/06:30:00','2013-06-01/07:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


end




timespan,'2013-05-20',1
probe='a b'
rbsp_load_efw_b1,probe=probe


; RBSPA 2013-05-20
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-20/15:30:00 - 2013-05-20/16:30:00):'
trange=time_double(['2013-05-20/15:30:00','2013-05-20/16:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

;RBSPA (2013-05-20/21:15:00 - 2013-05-20/21:45:00):
;util.QUEUE_B1PLAYBACK( 73534, 3605)

end




timespan,'2013-05-25',1
probe='a b'
rbsp_load_efw_b1,probe=probe

; RBSPB 2013-05-19
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-25/02:20:00 - 2013-05-25/03:00:00):'
trange=time_double(['2013-05-25/02:20:00','2013-05-25/03:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-25/19:50:00 - 2013-05-25/20:20:00):'
trange=time_double(['2013-05-25/19:50:00','2013-05-25/20:20:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


;RBSPB (2013-05-25/02:20:00 - 2013-05-25/03:00:00):
;util.QUEUE_B1PLAYBACK( 248499, 4813)
;RBSPB (2013-05-25/19:50:00 - 2013-05-25/20:20:00):
;util.QUEUE_B1PLAYBACK( 54891, 3608)

end




timespan,'2013-05-19',2
probe='a b'
rbsp_load_efw_b1,probe=probe


; RBSPA 2013-05-19, 20
probe='a'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-19/12:30:00 - 2013-05-19/13:45:00):'
trange=time_double(['2013-05-19/12:30:00','2013-05-19/13:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-20/14:45:00 - 2013-05-20/15:30:00):'
trange=time_double(['2013-05-20/14:45:00','2013-05-20/15:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


; RBSPB 2013-05-19
probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-19/01:00:00 - 2013-05-19/02:30:00):'
trange=time_double(['2013-05-19/01:00:00','2013-05-19/02:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-19/07:40:00 - 2013-05-19/08:30:00):'
trange=time_double(['2013-05-19/07:40:00','2013-05-19/08:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end





; RBSPB 2013-05-18
probe='b'
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-18/08:00:00 - 2013-05-18/08:30:00):'
trange=time_double(['2013-05-18/08:00:00','2013-05-18/08:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end



; RBSPA 2013-05-19
probe='a'
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-19/02:50:00 - 2013-05-19/03:50:00):'
trange=time_double(['2013-05-19/02:50:00','2013-05-19/03:50:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


; RBSPB 2013-05-18

probe='b'
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-18/04:05:00 - 2013-05-18/04:15:00):'
trange=time_double(['2013-05-18/04:05:00','2013-05-18/04:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

probe='b'
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-18/05:10:00 - 2013-05-18/05:30:00):'
trange=time_double(['2013-05-18/05:10:00','2013-05-18/05:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



end



; 2013-05-16

timespan,'2013-05-12',5
probe='a b'
rbsp_load_efw_b1,probe=probe


probe='a'
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-12/08:30:00 - 2013-05-12/09:30:00):'
trange=time_double(['2013-05-12/08:30:00','2013-05-12/09:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-16/18:45:00 - 2013-05-16/20:15:00):'
trange=time_double(['2013-05-16/18:45:00','2013-05-16/20:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


end



; 2013-05-12 (2)

timespan,'2013-05-12',1
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-12/07:30:00 - 2013-05-12/08:30:00):'
trange=time_double(['2013-05-12/07:30:00','2013-05-12/08:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

probe='b'

print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-12/12:30:00 - 2013-05-12/13:30:00):'
trange=time_double(['2013-05-12/12:30:00','2013-05-12/13:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


end




; 2013-05-12

timespan,'2013-05-12',1
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-12/06:30:00 - 2013-05-12/07:30:00):'
trange=time_double(['2013-05-12/06:30:00','2013-05-12/07:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

probe='b'
print,       'RBSP'+strupcase(probe)+$
				  ' (2013-05-12/03:45:00 - 2013-05-12/04:45:00):'
trange=time_double(['2013-05-12/03:45:00','2013-05-12/04:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


end


; 2013-05-03

timespan,'2013-05-03',1
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'
print,       'RBSPA (2013-05-03/07:00:00 - 2013-05-03/08:00:00):'
trange=time_double(['2013-05-03/07:00:00','2013-05-03/08:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

probe='a'
print,       'RBSPA (2013-05-03/18:00:00 - 2013-05-03/19:00:00):'
trange=time_double(['2013-05-03/18:00:00','2013-05-03/19:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


probe='b'
print,       'RBSPB (2013-05-03/02:30:00 - 2013-05-03/03:30:00):'
trange=time_double(['2013-05-03/02:30:00','2013-05-03/03:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

probe='b'
print,       'RBSPB (2013-05-03/06:15:00 - 2013-05-03/08:00:00):'
trange=time_double(['2013-05-03/06:15:00','2013-05-03/08:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



end

;-------------------------------------------------------------------------------
; 2013-04-24 RBSPB - themis conjunction
;-------------------------------------------------------------------------------

timespan,'2013-04-25',1
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='b'
print,       'RBSPB (2013-04-25/04:00:00 - 2013-04-25/05:00:00):'
trange=time_double(['2013-04-25/04:00:00','2013-04-25/05:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



;-------------------------------------------------------------------------------
; 2013-04-14 auroral arc, themis conjunction
;-------------------------------------------------------------------------------
timespan,'2013-04-14',1
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'
print,       'RBSPA (2013-04-14/05:00:00 - 2013-04-14/09:45:00):'
trange=time_double(['2013-04-14/05:00:00','2013-04-14/09:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

probe='b'
print,       'RBSPB (2013-04-14/07:15:00 - 2013-04-14/12:00:00):'
trange=time_double(['2013-04-14/07:15:00','2013-04-14/12:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


end






;-------------------------------------------------------------------------------
; 2013-03-26/14:30 - 17:05 UT - close approach
;-------------------------------------------------------------------------------
timespan,'2013-03-26',1
probe='a b'
rbsp_load_efw_b1,probe=probe

probe='a'
print,       'RBSPA (2013-03-26/14:30:00 - 2013-03-26/17:00:00):'
trange=time_double(['2013-03-26/14:30:00','2013-03-26/17:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

probe='b'
print,       'RBSPB (2013-03-26/14:35:00 - 2013-03-26/17:05:00):'
trange=time_double(['2013-03-26/14:35:00','2013-03-26/17:05:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


end






;-------------------------------------------------------------------------------
; 2013-03-17/14:40 - 17:10 UT - Forrest's charging event (4096S/s apogee)
;-------------------------------------------------------------------------------
timespan,'2013-03-17',1
probe='a'
rbsp_load_efw_b1,probe=probe

probe='a'
print,       'RBSPA (2013-03-17/14:40:00 - 2013-03-17/17:10:00):'
trange=time_double(['2013-03-17/14:40:00','2013-03-17/17:10:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end




;-------------------------------------------------------------------------------
; 2013-02-23/00:00 - 03:00 UT - Forrest's RBSPA injection event
;-------------------------------------------------------------------------------
timespan,'2013-02-22',2
probe='a'
rbsp_load_efw_b1,probe=probe

probe='a'
print,       'RBSPA (2013-02-23/11:00:00 - 2013-02-23/14:00:00):'
trange=time_double(['2013-02-23/11:00:00','2013-02-23/14:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end



;-------------------------------------------------------------------------------
; 2013-02-23/00:00 - 03:00 UT - Forrest's RBSPB injection event
;-------------------------------------------------------------------------------
timespan,'2013-02-22',2
probe='b'
rbsp_load_efw_b1,probe=probe

probe='b'
print,       'RBSPB (2013-02-23/00:00:00 - 2013-02-23/03:00:00):'
trange=time_double(['2013-02-23/00:00:00','2013-02-23/03:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

end


;-------------------------------------------------------------------------------
; 2012-09-30 - 2012-10-01 geomagnetic storm, RBSPA + RBSPB
;-------------------------------------------------------------------------------
timespan,'2012-09-20',20
probe='a b'
rbsp_load_efw_b1,probe=probe

print,'RBSPA (2012-09-17/17:45:00 - 2012-09-17/23:59:59):'
probe='a'

trange=time_double(['2012-09-17/17:45:00','2012-09-17/18:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/18:15:00','2012-09-17/18:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/18:45:00','2012-09-17/19:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/19:15:00','2012-09-17/19:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/19:45:00','2012-09-17/20:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/20:15:00','2012-09-17/20:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/20:45:00','2012-09-17/21:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/21:15:00','2012-09-17/21:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/21:45:00','2012-09-17/22:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/22:15:00','2012-09-17/22:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/22:45:00','2012-09-17/23:15:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/23:15:00','2012-09-17/23:45:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-17/23:45:00','2012-09-17/23:59:59'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



end

;-------------------------------------------------------------------------------
; 2012-09-30 - 2012-10-01 geomagnetic storm, RBSPA + RBSPB
;-------------------------------------------------------------------------------

timespan,'2012-09-30',2
probe='a b'
rbsp_load_efw_b1,probe=probe


; RBSPA
probe='a'

print,'RBSPA (2012-09-30/17:00:00 - 2012-09-30/22:30:00):'

trange=time_double(['2012-09-30/17:00:00','2012-09-30/22:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,'RBSPA (2012-10-01/03:00:00 - 2012-10-01/08:00:00):'

trange=time_double(['2012-10-01/03:00:00','2012-10-01/08:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,'RBSPA (2012-09-30/22:30:00 - 2012-10-01/03:00:00):'

trange=time_double(['2012-09-30/22:30:00','2012-09-30/23:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-30/23:00:00','2012-09-30/23:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-30/23:30:00','2012-09-30/24:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/00:00:00','2012-10-01/00:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/00:30:00','2012-10-01/01:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/01:00:00','2012-10-01/01:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/01:30:00','2012-10-01/02:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/02:00:00','2012-10-01/02:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/02:30:00','2012-10-01/03:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string




; RBSPB
probe='b'

print,'RBSPB (2012-09-30/17:00:00 - 2012-09-30/22:30:00):'

trange=time_double(['2012-09-30/17:00:00','2012-09-30/22:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

print,'RBSPB (2012-10-01/03:00:00 - 2012-10-01/08:00:00):'

trange=time_double(['2012-10-01/03:00:00','2012-10-01/08:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string


print,'RBSPB (2012-09-30/22:30:00 - 2012-10-01/03:00:00):'

trange=time_double(['2012-09-30/22:30:00','2012-09-30/23:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-30/23:00:00','2012-09-30/23:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-09-30/23:30:00','2012-09-30/24:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/00:00:00','2012-10-01/00:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/00:30:00','2012-10-01/01:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/01:00:00','2012-10-01/01:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/01:30:00','2012-10-01/02:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/02:00:00','2012-10-01/02:30:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string

trange=time_double(['2012-10-01/02:30:00','2012-10-01/03:00:00'])
rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
print,cmd_string



;-------------------------------------------------------------------------------
; 2012-09-19 injection event, RBSPB
;-------------------------------------------------------------------------------

;timespan,'2012-09-19',1
;probe='b'
;rbsp_load_efw_b1,probe=probe


; priority 0
;trange=time_double(['2012-09-19/20:50:00','2012-09-19/20:55:00'])
;rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
;print,cmd_string

; priority 1
;trange=time_double(['2012-09-19/23:00:00','2012-09-19/23:05:00'])
;rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
;print,cmd_string

; priority 2
;trange=time_double(['2012-09-19/20:45:00','2012-09-19/21:00:00'])
;rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
;print,cmd_string

; priority 3
;trange=time_double(['2012-09-19/21:00:00','2012-09-19/21:15:00'])
;rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
;print,cmd_string

; priority 4
;trange=time_double(['2012-09-19/20:30:00','2012-09-19/20:45:00'])
;rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
;print,cmd_string

; priority 5
;trange=time_double(['2012-09-19/21:40:00','2012-09-19/21:55:00'])
;rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
;print,cmd_string

; priority 6
;trange=time_double(['2012-09-19/18:25:00','2012-09-19/18:40:00'])
;rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
;print,cmd_string

; priority 7 (perigee)
;trange=time_double(['2012-09-19/16:10:00','2012-09-19/16:30:00'])
;rbsp_efw_b1_cmd,probe=probe,trange=trange,cmd_string=cmd_string
;print,cmd_string



end