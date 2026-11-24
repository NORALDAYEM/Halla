// Rotate the crown geometry, keeping its circular base seated above the microphone.
(() => {
  const emblem = document.querySelector('.full-logo');
  if (!emblem) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const crown = document.createElement('canvas');
  crown.className = 'live-crown';
  crown.setAttribute('aria-hidden','true');
  const ctx = crown.getContext('2d');
  if (!ctx) return;
  crown.width = 380;
  crown.height = 292;
  emblem.append(crown);
  const music = document.createElement('span');
  music.className = 'mic-melody';
  music.setAttribute('aria-hidden','true');
  for (const note of ['♪','♫','♬','♪']) {
    const glyph = document.createElement('i');
    glyph.textContent = note;
    music.append(glyph);
  }
  emblem.append(music);

  const tau = Math.PI*2, segments = 96;
  function point(angle,radius,height){
    return [190 + radius*Math.sin(angle), 244 - height + 0.19*radius*Math.cos(angle)];
  }
  function face(points,fill) {
    ctx.beginPath();
    points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));
    ctx.closePath();ctx.fillStyle=fill;ctx.fill();
    ctx.strokeStyle=fill;ctx.lineWidth=.7;ctx.stroke();
  }
  function topHeight(a){return 103+69*Math.pow((1+Math.cos(8*a))/2,4);}
  function gold(a,level){
    const shine=(1+Math.sin(a-.5))/2;
    return 'hsl(42 91% '+(level+shine*22+12*Math.pow(shine,15))+'%)';
  }
  function draw(angle){
    ctx.clearRect(0,0,380,292);
    const strips=[];
    for(let i=0;i<segments;i++){
      const a=i*tau/segments,b=(i+1)*tau/segments;
      const ta=topHeight(a),tb=topHeight(b);
      const rings=[[103,0,0],[110,5,5],[111,14,14],[105,18,18],[108,37,37],[115,44,44],[111,52,52],[116,68,68],[125+(ta-103)*.25,ta,tb]];
      const vertices=(r,j)=>point((j?b:a)+angle,j&&r===rings.at(-1)?125+(tb-103)*.25:r[0],r[j?2:1]);
      strips.push({z:Math.cos((a+b)/2+angle),paint:()=>{
        const levels=[38,53,30,40,61,31,48,39];
        for(let k=0;k<rings.length-1;k++)face([vertices(rings[k],0),vertices(rings[k],1),vertices(rings[k+1],1),vertices(rings[k+1],0)],gold((a+b)/2+angle,levels[k]));
      }});
    }
    for(let i=0;i<8;i++){
      const a=i*tau/8+angle;
      strips.push({z:Math.cos(a)+.014,paint:()=>{
        const [x,y]=point(a,142,173);
        const g=ctx.createRadialGradient(x-3,y-4,1,x,y,9);
        g.addColorStop(0,'#fff8c3');g.addColorStop(.45,'#f6b93d');g.addColorStop(1,'#744006');
        ctx.fillStyle=g;ctx.beginPath();ctx.arc(x,y,8,0,tau);ctx.fill();
        if(Math.cos(a)>0){const [jx,jy]=point(a,110,29);ctx.fillStyle='#006e93';ctx.beginPath();ctx.ellipse(jx,jy,5*Math.cos(a)+1,7,0,0,tau);ctx.fill();}
      }});
    }
    strips.push({z:0,paint:()=>{
      face([[187,111],[193,111],[193,54],[187,54]],'#bd831d');
      const facets=[];
      for(let j=0;j<8;j++){
        const a=angle+j*tau/8,b=a+tau/8;
        const rim=t=>[190+24*Math.sin(t),34+4*Math.cos(t)];
        facets.push({z:Math.cos((a+b)/2),paint:()=>{
          const tint=Math.round(43+23*(1+Math.sin(a))*.5);
          face([rim(a),rim(b),[190,59]],'hsl(193 91% '+tint+'%)');
          face([rim(a),rim(b),[190,22]],'hsl(186 95% '+(tint+15)+'%)');
        }});
      }
      facets.sort((a,b)=>a.z-b.z).forEach(f=>f.paint());
    }});
    strips.sort((a,b)=>a.z-b.z).forEach(s=>s.paint());
  }
  let frame=0,elapsed=0,last;
  function tick(time){
    if(last!==undefined)elapsed+=time-last;
    last=time;draw(elapsed*tau/8500);frame=requestAnimationFrame(tick);
  }
  function sync(){
    cancelAnimationFrame(frame);last=undefined;
    emblem.classList.toggle('motion-logo',!reduced.matches);
    if(!reduced.matches&&!document.hidden)frame=requestAnimationFrame(tick);
  }
  reduced.addEventListener('change',sync);document.addEventListener('visibilitychange',sync);
  sync();
})();
