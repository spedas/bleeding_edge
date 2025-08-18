

pro mav_sep_msg_handler,msg,status=status,decom=decom,cmdpkt=cmdpkt

common mav_sep_msg_handler_com, $
   sep1_science,sep1_hkp,sep1_noise,sep1_memdump,sep1_memstate, $
   sep2_science,sep2_hkp,sep2_noise,sep2_memdump,sep2_memstate, $
   last_status,memstate,membuff

    SEPname = 'SEP'
    realtime =1
      
    if keyword_set(cmdpkt) then begin         ; Interpret SEP commands
        mav_gse_command_decom,cmdpkt,memstate,hkp=sephkp,membuff=membuff    ; Note this will not work properly with two SEPs !!!
        mav_gse_structure_append  ,memstate_ptrs, memstate, realtime=realtime
        return
    endif
           
            if keyword_set(status) then last_status = status
            case msg.id of
                '08'x:  dprint,dlevel=0,msg.length,' Event'
                '09'x:  dprint,dlevel=0,msg.length,' Unused'
                '18'x: begin    ;SEP1 Science
                    sep1_science = mav_sep_science_decom(msg,hkp=sep1_hkp ,last=sep1_science, memdump=sep1_memdump)  ;,last=lastscience)
                    mav_gse_structure_append,  sepscience_ptrs, sep1_science , realtime=realtime, tname= SEPname+'1_SCIENCE'
                    end
                '1C'x: begin    ;SEP2 Science
                    sep2_science = mav_sep_science_decom(msg,hkp=sep2_hkp ,last=sep2_science, memdump=sep2_memdump)  ;,last=lastscience)
                    mav_gse_structure_append,  sepscience_ptrs, sep2_science , realtime=realtime, tname= SEPname+'2_SCIENCE'
                    end
                '19'x: begin     ;SEP1 HKP
                    sep1_hkp = mav_sep_hkp_decom(msg,last=sep1_hkp,memstate=sep1_memstate)
                    mav_gse_structure_append  ,sephkp_ptrs, sep1_hkp , realtime=realtime, tname=SEPname+'1_HKP'
                    end
                '1D'x: begin     ;SEP2 HKP
                    sep2_hkp = mav_sep_hkp_decom(msg,last=sep2_hkp,memstate=sep2_memstate)
                    mav_gse_structure_append  ,sephkp_ptrs, sep2_hkp , realtime=realtime, tname=SEPname+'2_HKP'
                    end
                '1a'x: begin ;SEP1 Noise
                    sep1_noise = mav_sep_noise_decom(msg,hkp=sep1_hkp,last=sep1_noise)
                    mav_gse_structure_append, sepnoise_ptrs, sep1_noise, realtime=realtime,tname=SEPname+'1_NOISE'
                    end
                '1E'x: begin ;SEP2 Noise
                    sep2_noise = mav_sep_noise_decom(msg,hkp=sep2_hkp,last=sep2_noise)
                    mav_gse_structure_append, sepnoise_ptrs, sep2_noise, realtime=realtime,tname=SEPname+'2_NOISE'
                    end
                '1b'x: begin ; SEP1 MEMDUMP
                    sep1_memdump = mav_sep_memdump_decom(msg,hkp=sep1_hkp,last=sep1_memdump)
                    mav_gse_structure_append, sepmemdump_ptrs, sep1_memdump,  realtime=realtime,tname= SEPname+'1_MEMDUMP'
                    dprint,unit=u,dlevel=4,msg.length,' MemDump' ;,string(msg.data[0:5],format=
                    end
                '1f'x: begin ; SEP2 MEMDUMP
                    sep2_memdump = mav_sep_memdump_decom(msg,hkp=sep2_hkp,last=sep2_memdump)
                    mav_gse_structure_append, sepmemdump_ptrs, sep2_memdump,  realtime=realtime,tname= SEPname+'2_MEMDUMP'
                    dprint,unit=u,dlevel=4,msg.length,' MemDump' ;,string(msg.data[0:5],format=
                    end
                else: begin
;                    dprint,'Bad MISG message id:', msg.id
                    return                
                    end

            endcase
            decom=1
end



