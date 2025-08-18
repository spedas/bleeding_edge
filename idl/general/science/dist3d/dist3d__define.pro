
pro dist3d::help
printdat,self
help,self,/obj
end


function dist3d::instance
class = obj_class(self)
ins = call_function(class+'__define')
for i=0,n_tags(ins)-1 do ins.(i) = self.(i)
return,ins
end



pro dist3d__define,structdef=dat, project_name=project_name
   dat = {dist3d,  $
          project_name:'',  $
          spacecraft:'',  $
          data_name:'' , $
          units_name:'' , $
          units_procedure:'' , $
          tplotname: '', $
          time:0d , $
          trange:[0d,0d],  $
          end_time:0d,  $
          index: 0l , $
          nbins: 0l,  $
          nenergy: 0l , $
          magf: [0.,0.,1.], $
          sc_pot: 0.   ,$
          mass: 0.  , $
          charge: 1., $
          valid: 0   }

return
end

