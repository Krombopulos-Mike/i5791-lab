#!/bin/sh
echo "== HOST =="
id 2>/dev/null; hostname; hostname -i 2>/dev/null
echo "== NET =="
cat /proc/net/fib_trie 2>/dev/null | grep -E "^\s+\|-- /" | head -20
cat > /tmp/i5791net.js <<'JS'
const net=require("node:net"), dns=require("node:dns").promises;
const HOSTS=["awd-backoffice.delasport.com","awd-backoffice-ui.delasport.com","awd-backoffice-ui.ext.prod.ard-labs.xyz","payment-monitor-websocket.ext.prod.ard-labs.xyz","payment-monitor.bo.prod.delasport.com","live-stream-socket.ext.prod.ard-labs.xyz","live-stream-socket.ext.delasport.com","traefik-gw.ext.delasport.com","traefik.ext.prod.ard-labs.xyz","platform-marketing-api.ext.delasport.com","awd-backoffice.bo.prod.delasport.com","awd-backoffice.prod.delasport.com","awd-backoffice.ext.prod.ard-labs.xyz","awd-api.ext.prod.ard-labs.xyz","awd.ext.prod.ard-labs.xyz","payments-monitor.bo.prod.delasport.com","backoffice.delasport.com"];
const tcp=(h,p,ms=4000)=>new Promise(r=>{const s=net.connect({host:h,port:p});let d=false;const f=x=>{if(!d){d=true;s.destroy();r(x)}};s.setTimeout(ms);s.on("connect",()=>f("OPEN"));s.on("timeout",()=>f("TIMEOUT"));s.on("error",e=>f("ERR:"+(e.code||e.message)));});
(async()=>{
 for(const h of HOSTS){let ips=[];try{ips=(await dns.lookup(h,{all:true})).map(x=>x.address)}catch(e){ips=["NX:"+e.code]}
   console.log("DNS",h,ips.join(","));}
 for(const h of HOSTS){ console.log("TCP443",h,await tcp(h,443)); }
 for(const h of ["awd-backoffice.delasport.com","awd-backoffice-ui.ext.prod.ard-labs.xyz","payment-monitor.bo.prod.delasport.com","platform-marketing-api.ext.delasport.com"]){ console.log("TCP80",h,await tcp(h,80)); }
})();
JS
node /tmp/i5791net.js 2>&1
echo "== HTTP =="
cat > /tmp/i5791http.js <<'JS'
const https=require("node:https");
function req(host,path,extra={},port=443){return new Promise(r=>{const o={host,port,path,method:"GET",headers:{Host:extra.Host||host,"User-Agent":"Mozilla/5.0",...(extra.headers||{})},timeout:8000,rejectUnauthorized:false,servername:extra.servername||host};
 const q=https.request(o,res=>{let b="";res.on("data",d=>b+=d);res.on("end",()=>r({h:host,p:path,extra:extra.tag||"",st:res.statusCode,len:b.length,body:b.slice(0,160).replace(/\n/g," ")}))});q.on("timeout",()=>{q.destroy();r({h:host,p:path,st:"TIMEOUT"})});q.on("error",e=>r({h:host,p:path,st:"ERR:"+e.code}));q.end();});}
(async()=>{
 const T=[
  ["awd-backoffice.delasport.com","/api/v1/settings"],
  ["awd-backoffice.delasport.com","/"],
  ["awd-backoffice-ui.ext.prod.ard-labs.xyz","/"],
  ["awd-backoffice-ui.delasport.com","/"],
  ["platform-marketing-api.ext.delasport.com","/health"],
  ["payment-monitor-websocket.ext.prod.ard-labs.xyz","/socket.io/?EIO=3&transport=polling&secret=84GTUwWEcvnwZLV"],
 ];
 for(const [h,p] of T) console.log(JSON.stringify(await req(h,p)));
 for(const ip of ["35.246.183.122","34.147.35.148"]){
  for(const h of ["awd-backoffice.delasport.com","awd-backoffice-ui.ext.prod.ard-labs.xyz"]){
   console.log("OVR",JSON.stringify(await req(ip,"/api/v1/settings",{Host:h,servername:h,tag:"host-"+h})));
   console.log("OVR",JSON.stringify(await req(ip,"/",{Host:h,servername:h,tag:"host-"+h})));
  }
 }
 for(const xff of ["127.0.0.1","10.0.0.1","10.128.0.1","172.16.0.1","192.168.0.1"]){
  console.log("XFF",JSON.stringify(await req("awd-backoffice.delasport.com","/api/v1/settings",{headers:{"X-Forwarded-For":xff,"X-Real-IP":xff} })));
 }
})();
JS
node /tmp/i5791http.js 2>&1
echo "== DONE =="
