local component=component;local computer=computer;local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D;a=component.proxy(component.list("gpu")())a.bind(component.proxy(component.list("screen")()).address)b,c=a.getResolution()a.setForeground(0x9cc3db)a.setBackground(0x003150)d=function(E,F,G,H)if H then return pcall(component.invoke,E,F,G,H)else return pcall(component.invoke,E,F,G)end end;function e(E,I)if I then n,o=d(E,"open",I)else n,o=d(E,"open","/init.lua")end;if n then _,v=d(E,"read",o,math.maxinteger)d(E,"close",o)return v else return false end end;function g(J)a.fill(1,1,b,c," ")return a.set(math.ceil(b/2-#J/2),math.ceil(c/2),J)end;function w()_G.buffer={}_G.print=function(K)for _ in string.gmatch(tostring(K),"[^\r\n]+")do if#tostring(K)>b then for L=1,math.ceil(#tostring(K)/b)do buffer[#buffer+1]=string.sub(tostring(K),L==1 and 1 or b*(L-1),b*L)end else buffer[#buffer+1]=tostring(K)end end end;buffer[1]="bootloader> "x=false;y=false;B=""::M::g("")for L=1,c do if buffer[#buffer-L+1]then a.set(1,c-L+1,buffer[#buffer-L+1])end end;r,_,A,s=computer.pullSignal(1)if not A then if r=="key_down"then if s==42 or s==54 then x=true elseif s==58 then y=not y end elseif r=="key_up"then if s==42 or s==54 then x=false end end else if r=="key_down"then if s==28 then if B=="exit"then return elseif B=="shutdown"then computer.shutdown()end;m,C=pcall(load(B))if C then for _ in string.gmatch(C,"[^\r\n]+")do if#C>b then for L=1,math.ceil(#C/b)do buffer[#buffer+1]=string.sub(C,L==1 and 1 or b*(L-1),b*L)end else buffer[#buffer+1]=C end end end;buffer[#buffer+1]="bootloader> "B=""goto M elseif s==14 then if#buffer[#buffer]>12 then B=string.sub(B,1,#B-1)buffer[#buffer]=string.sub(buffer[#buffer],1,#buffer[#buffer]-1)end;goto M elseif A<127 and A>31 then z=string.char(A)if x or y then z=string.upper(z)end;buffer[#buffer]=buffer[#buffer]..z;B=B..z end end end;goto M end;g("Hold ALT to stay in bootloader")h=component.proxy(component.list("eeprom")())function computer.getBootAddress()return h.getData()end;function computer.setBootAddress(N)return h.setData(N)end;i=computer.getBootAddress()j=e(i)if j then k=i else for L in pairs(component.list("filesystem"))do j=e(L)k=L;if j then computer.setBootAddress(L)break end end end::O::l=component.invoke(k,"getLabel")m=component.invoke(k,"list","/bios/plugins/")if m then for _,P in ipairs(m)do if not P:match(".*/$")then o=component.invoke(k,"open","/bios/plugins/"..P)load(component.invoke(k,"read",o,math.huge)or"")()end end else n=pcall(component.invoke,k,"makeDirectory","/bios/plugins/")if n then goto O end end;p=computer.uptime()if not j then goto q end;if not q then repeat r,_,_,s=computer.pullSignal(1)if r=="key_down"and s==(56 or 184)then q=true;break end until p+1<=computer.uptime()end::Q::if not q then g("Booting to "..(l~=nil and l or"N/A").." ("..k..")")return load(j)()end::q::q=false;f=e(i,"/bios/bl.bin")if f then goto R end;if k then for L in component.list("filesystem")do f=e(L,"/bios/bl.bin")if f then break end end end;if not f then t=component.list("internet")()if t then if component.invoke(t,"isHttpEnabled")then u=component.invoke(t,"request","https://raw.githubusercontent.com/OpenGCX/BlueBIOS/main/binaries/bl.bin")if u then v=""::S::D=u.read()if D then v=v..D;goto S end;if v then f=v;if k then n,o=d(k,"open","/bios/bl.bin","w")if n then d(k,"write",o,f)d(k,"close",o)end end end end end end end::R::if f then load(f)()else g("")w()end;goto Q