#!/bin/sh
echo "== HOST =="
id 2>/dev/null; hostname
cat > /tmp/i5791p2.js <<'JS'
const net=require("node:net"), dns=require("node:dns").promises, https=require("node:https"), http=require("node:http");
const tcp=(h,p,ms=5000)=>new Promise(r=>{const s=net.connect({host:h,port:p});let d=false;const f=x=>{if(!d){d=true;s.destroy();r(x)}};s.setTimeout(ms);s.on("connect",()=>f("OPEN"));s.on("timeout",()=>f("TIMEOUT"));s.on("error",e=>f("ERR:"+(e.code||e.message)));});
const HOSTS=["traefik-gw.int.delasport.com","member.int.delasport.com","traefik-gw.int.test-delasport.com","api.int.test-delasport.com","member.int.test-delasport.com","delasport-spring-boot-admin.test-delasport.com","traefik-gw.int.dev-delasport.com","delasport-spring-boot-admin.int.dev-delasport.com","awd-backoffice.int.delasport.com","awd.int.delasport.com","payment.int.delasport.com","payment-monitor.int.delasport.com","bo.int.delasport.com","backoffice.int.delasport.com","admin.int.delasport.com","rabbitmq.int.delasport.com","db1.int.delasport.com","platform-marketing-api.int.delasport.com"];
function req(ip,port,path,host,tls=true){return new Promise(r=>{const mod=tls?https:http; const o={host:ip,port,path,method:"GET",headers:{Host:host,"User-Agent":"Mozilla/5.0"},timeout:8000,rejectUnauthorized:false,servername:host};
 const q=mod.request(o,res=>{let b="";res.on("data",d=>b+=d);res.on("end",()=>r({ip,port,path,host,st:res.statusCode,len:b.length,body:b.slice(0,200).replace(/\n/g," "),hdr:JSON.stringify(res.headers).slice(0,250)}))});
 q.on("timeout",()=>{q.destroy();r({ip,port,path,host,st:"TIMEOUT"})});q.on("error",e=>r({ip,port,path,host,st:"ERR:"+(e.code||e.message)}));q.end();});}
(async()=>{
 for(const h of HOSTS){let ips=[];try{ips=(await dns.lookup(h,{all:true})).map(x=>x.address)}catch(e){ips=["NX"]}
   console.log("DNS",h,ips.join(","));
   for(const ip of ips){ if(/^10\.|^192\.168\.|^172\.(1[6-9]|2\d|3[01])\./.test(ip)){ for(const p of [443,80]) console.log("INTTCP",h,ip,p,await tcp(ip,p)); } }
 }
 console.log("== direct internal traefik ==");
 for(const ip of ["10.156.1.207","10.156.0.47","10.156.0.59","10.156.1.7"]){
   for(const p of [443,80]) console.log("TCP",ip,p,await tcp(ip,p));
 }
 const probes=[
  ["10.156.1.207",443,"/api/v1/settings","awd-backoffice.delasport.com"],
  ["10.156.1.207",443,"/","awd-backoffice.delasport.com"],
  ["10.156.1.207",443,"/","traefik-gw.int.delasport.com"],
  ["10.156.1.207",80,"/api/v1/settings","awd-backoffice.delasport.com"],
  ["10.156.0.59",443,"/api/v1/settings","awd-backoffice.delasport.com"],
  ["10.156.0.59",80,"/api/v1/settings","awd-backoffice.delasport.com"],
  ["10.156.0.47",443,"/","member.int.delasport.com"],
 ];
 for(const [ip,p,path,host] of probes){ console.log("REQ",JSON.stringify(await req(ip,p,path,host,p===443))); }
})();
JS
node /tmp/i5791p2.js 2>&1
echo "== DONE =="
