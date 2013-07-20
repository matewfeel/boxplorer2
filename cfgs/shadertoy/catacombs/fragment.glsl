// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// From https://www.shadertoy.com/view/lsf3zr

// boxplorer i/o
varying vec3 eye, dir;
uniform float xres, yres, speed, time;
uniform sampler2D bg_texture;

#define iChannel0 bg_texture
float iGlobalTime = time;
vec2 iResolution = vec2(xres, yres);
vec3 iMouse = dir;

#include "setup.inc"

float fbm( vec3 p, vec3 n )
{
  p *= 0.15;

  float x = texture2D( iChannel0, p.yz ).x;
  float y = texture2D( iChannel0, p.zx ).x;
  float z = texture2D( iChannel0, p.xy ).x;

  return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

float distToBox( in vec3 p, in vec3 abc )
{
  vec3 di = max(abs(p)-abc,0.0);
  return dot(di,di);
}



vec2 column( in float x, in float y, in float z )
{
  vec3 p = vec3( x, y, z );

  float y2=y-0.40;
  float y3=y-0.35;
  float y4=y-1.00;

  float di1=distToBox( p, vec3(0.10*0.85,1.00,0.10*0.85) );
  float di2=distToBox( p, vec3(0.12,0.40,0.12) );
  float di3=distToBox( p, vec3(0.05,0.35,0.14) );
  float di4=distToBox( p, vec3(0.14,0.35,0.05) );
  float di5=distToBox( vec3((x-y2)*0.7071, (y2+x)*0.7071, z), vec3(0.10*0.7071,  0.10*0.7071, 0.12) );
  float di6=distToBox( vec3(x, (y2+z)*0.7071, (z-y2)*0.7071), vec3(0.12,  0.10*0.7071, 0.10*0.7071) );
  float di7=distToBox( vec3((x-y3)*0.7071, (y3+x)*0.7071, z), vec3(0.10*0.7071,  0.10*0.7071, 0.14) );
  float di8=distToBox( vec3(x, (y3+z)*0.7071, (z-y3)*0.7071), vec3(0.14,  0.10*0.7071, 0.10*0.7071) );
  float di9=distToBox( vec3(x,y4,z), vec3(0.14,0.02,0.14) );

  float dm = min(min(min(di9,di2),min(di3,di4)),min(min(di5,di6),min(di7,di8)));
  vec2 res = vec2( dm, 3.0 );
  if( di1<res.x ) res = vec2( di1, 2.0 );

  return vec2( sqrt(res.x), res.y );
}


vec3 map( in vec3 pos )
{

  float sid = 0.0;
  float dis;

    // floor
  float mindist = pos.y;

    // ceilin
  float x = fract( pos.x+128.0 ) - 0.5;
  float z = fract( pos.z+128.0 ) - 0.5;
  float y = 1.0 - pos.y;
  dis = -sqrt( y*y + min(x*x,z*z)) + 0.4;
  dis = max( dis, y );
  if( dis<mindist )
  {
    mindist = dis;
    sid = 1.0;
  }


    // columns
  float fxc = fract( pos.x+128.5 ) - 0.5;
  float fzc = fract( pos.z+128.5 ) - 0.5;
  vec2 dis2 = column( fxc, pos.y, fzc );
    
  if( dis2.x<mindist )
  {
    mindist = dis2.x;
    sid = dis2.y;
  }

  
  float dsp = 1.0*clamp(pos.y,0.0,1.0)*abs(sin(6.0*pos.y)*sin(50.0*pos.x)*sin(4.0*6.2831*pos.z));
  mindist -= dsp*0.03;

  return vec3(mindist,sid,dsp);
}


vec3 calcColor( in vec3 pos, in vec3 nor, in float sid )
{
  vec3 col = vec3( 1.0 );

  float kk = fbm( 4.0*pos, nor );

  if( sid<0.5 )
  {

    vec2 peldxz = fract( 12.0*pos.xz );
    peldxz = 4.0*peldxz*(1.0-peldxz);
    float de = 20.0*length(fwidth(pos.xz));
    float peld = smoothstep( 0.15-de, 0.15+de, min( peldxz.x, peldxz.y ) );
    col = 0.05 + 0.95*vec3(peld);
  }
    else if( sid>0.5 && sid<1.5 )
  {
    float fx = fract( pos.x+128.0 ); 
    float fz = fract( pos.z+128.0 ); 
    
    col = vec3(0.7,0.7,0.7);
    
    float p = 1.0;
    p *= smoothstep( 0.02, 0.03, abs(fx-0.1) );
    p *= smoothstep( 0.02, 0.03, abs(fx-0.9) );
    p *= smoothstep( 0.02, 0.03, abs(fz-0.1) );
    p *= smoothstep( 0.02, 0.03, abs(fz-0.9) );
    col = mix( 0.75*vec3(0.3,0.15,0.15), col, p );
  }
    else if( sid>1.5 && sid<2.5 )
  {
    float l = fract( 12.0*pos.y );
    float peld = smoothstep( 0.1, 0.2, l );
    col = 0.05 + 0.95*vec3(peld);
    
  }
  
  
  col *= 2.0*kk;
  
  return col; 
}


vec3 castRay( in vec3 ro, in vec3 rd, in float precis,
              in float startf, in float maxd )
{
  float h=precis*2.0;
  vec3 c;
  float t = startf;
  float dsp = 0.0;
  float sid = -1.0;
  for( int i=0; i<50; i++ )
  {
    if( abs(h)<precis||t>maxd ) continue;//break;
    t += h;
    vec3 res = map( ro+rd*t );
    h = res.x;
    sid = res.y;
    dsp = res.z;
  }

  if( t>maxd ) sid=-1.0;
  return vec3( t, sid, dsp );
}


float softshadow( in vec3 ro, in vec3 rd, in float mint,
                  in float maxt, in float k )
{
  float res = 1.0;
  float dt = 0.02;
  float t = mint;
  for( int i=0; i<32; i++ )
  {
    if( t<maxt )
    {
      float h = map( ro + rd*t ).x;
      res = min( res, k*h/t );
      t += max( 0.05, dt );
    }
  }
  return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos )
{
  vec3 eps = vec3( 0.001, 0.0, 0.0 );
  vec3 nor = vec3(
  map(pos+eps.xyy).x - map(pos-eps.xyy).x,
  map(pos+eps.yxy).x - map(pos-eps.yxy).x,
  map(pos+eps.yyx).x - map(pos-eps.yyx).x );
  return normalize(nor);
}


vec3 doBumpMap( in vec3 pos, in vec3 nor )
{
  float e = 0.0015;
  float b = 0.01;
    
  float ref = fbm( 48.0*pos, nor );
  vec3 gra = -b*vec3( fbm(48.0*vec3(pos.x+e, pos.y, pos.z),nor)-ref,
                      fbm(48.0*vec3(pos.x, pos.y+e, pos.z),nor)-ref,
                      fbm(48.0*vec3(pos.x, pos.y, pos.z+e),nor)-ref )/e;
  
  vec3 tgrad = gra - nor * dot ( nor , gra );
  return normalize ( nor - tgrad );
}

float calcAO( in vec3 pos, in vec3 nor )
{
  float ao = 1.0;
  float totao = 0.0;
  float sca = 15.0;
  for( int aoi=0; aoi<5; aoi++ )
  {
    float hr = 0.01 + 0.015*float(aoi*aoi);
    vec3 aopos =  nor * hr + pos;
    float dd = map( aopos ).x;
    totao += -(dd-hr)*sca;
    sca *= 0.5;
  }
  return 1.0 - clamp( totao, 0.0, 1.0 );
}




vec4 render( in vec3 ro, in vec3 rd )
{ 
    // move lights
  vec3 lpos[7];
  vec4 lcol[7];

  for( int i=0; i<7; i++ )
  {
    float la = 1.0;
    lpos[i].x = 0.5 + 2.2*cos(0.22+0.2*iGlobalTime + 17.0*float(i) );
    lpos[i].y = 0.25;
    lpos[i].z = 1.5 + 2.2*cos(2.24+0.2*iGlobalTime + 13.0*float(i) );

    // make the lights avoid the columns
    vec2 ilpos = floor( lpos[i].xz );
    vec2 flpos = lpos[i].xz - ilpos;
    flpos = flpos - 0.5;
    if( length(flpos)<0.2 ) flpos = 0.2*normalize(flpos);
    lpos[i].xz = ilpos + flpos;
    
    float li = sqrt(0.5 + 0.5*sin(2.0*iGlobalTime+ 23.1*float(i)));

    float h = float(i)/8.0;
    vec3 c = mix( vec3(1.0,0.8,0.6), vec3(1.0,0.3,0.05), 0.5+0.5*sin(40.0*h) );
    lcol[i] = vec4( c, li );
  }

  vec3 col = vec3(0.0);
  vec3 res = castRay(ro,rd,0.001,0.025,20.0);
  float t = res.x;
  if( res.y>-0.5 )
  {
    vec3 pos = ro + t*rd;
    vec3 nor = calcNormal( pos );
    col = calcColor( pos, nor, res.y );

    nor = doBumpMap( pos, nor );

    float ao = calcAO( pos, nor );
    ao *= 0.7 + 0.6*res.z;
      // lighting
    vec3 brdf = 0.03*ao*vec3(0.25,0.20,0.20)*(0.5+0.5*nor.y);
    vec3 spe = vec3(0.0);
    for( int i=0; i<7; i++ )
    {
      vec3 lig = lpos[i] - pos;
      float llig = dot( lig, lig);
      float im = inversesqrt( llig );
      lig = lig * im;
      float dif = dot( nor, lig );
      dif = clamp( dif, 0.0, 1.0 );
      float at = 2.0*exp2( -2.3*llig )*lcol[i].w;
      dif *= at;
      float at2 = exp2( -0.35*llig );

      float sh = 0.0;
      if( dif>0.02 ) { sh = softshadow( pos, lig, 0.02, sqrt(llig), 32.0 ); dif *= sh; }

      float dif2 = clamp( dot(nor,normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 );
      brdf += 0.20*ao*dif2*vec3(0.35,0.20,0.10)*at2;
      brdf += 2.50*ao*dif*lcol[i].xyz;
      
      float pp = clamp( dot( reflect(rd,nor), lig ), 0.0, 1.0 );
      spe += ao*lcol[i].xyz*at*sh*(pow(pp,16.0) + 0.5*pow(pp,4.0));
    }
    
      // material
    col = mix( col, vec3(0.1,0.3,0.0), sqrt(max(1.0-ao,0.0))*smoothstep(-0.5,-0.1,nor.y) );
    col = mix( col, vec3(0.1,0.3,0.0), (1.0-smoothstep( 0.0, 0.12, abs(nor.y) - 0.1*(1.0-smoothstep(-0.1,0.3,pos.y)) ))*(1.0-smoothstep(0.5,1.0,pos.y)) );
    
    col = col*brdf;
    col += 3.0*spe*vec3(1.0,0.6,0.2);
  }

  col *= exp( -0.055*t*t );

    // lights
  for( int i=0; i<7; i++ )
  {
    vec3 lv = lpos[i] - ro;
    float ll = length( lv );
    if( ll<t )
    {
      float dle = clamp( dot( rd, lv/ll ), 0.0, 1.0 );
      dle = (1.0-smoothstep( 0.0, 0.2*(0.7+0.3*lcol[i].w), acos(dle)*ll ));
      col += dle*6.0*lcol[i].w*lcol[i].xyz*dle*exp( -0.07*ll*ll );;
    }
  }

  return vec4( col, t );
}

void main( void )
{
  vec2 q = gl_FragCoord.xy/iResolution.xy;
  vec2 p = -1.0+2.0*q;
  p.x *= iResolution.x/iResolution.y;
  vec2 mo = iMouse.xy/iResolution.xy;
     
  float time = iGlobalTime;

  // camera 
  vec3 ce = vec3( 0.5, 0.25, 1.5 );
  vec3 ro = ce + vec3( 1.3*cos(0.11*time + 6.0*mo.x), 0.65*(1.0-mo.y), 1.3*sin(0.11*time + 6.0*mo.x) );
  vec3 ta = ce + vec3( 0.95*cos(1.2+.08*time), 0.4*0.25+0.75*ro.y, 0.95*sin(2.0+0.07*time) );
  float roll = -0.15*sin(0.1*time);
  
  // camera tx
  vec3 cw = normalize( ta-ro );
  vec3 cp = vec3( sin(roll), cos(roll),0.0 );
  vec3 cu = normalize( cross(cw,cp) );
  vec3 cv = normalize( cross(cu,cw) );
  vec3 rd = normalize( p.x*cu + p.y*cv + 1.5*cw );

  // Use boxplorer camera
  if (!setup_ray( eye, dir, ro, rd )) {
    gl_FragColor = vec4(0);
    gl_FragDepth = 0.0;
    return;
  }
  
  vec4 colz = render( ro, rd );

  vec3 col = sqrt( colz.xyz );
  
  // vigneting
  col *= 0.25+0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );

  write_pixel(dir, colz.w, col);
}
