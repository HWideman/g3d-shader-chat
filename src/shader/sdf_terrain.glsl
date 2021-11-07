// fragment_terrain_1.glsl

uniform float time;
uniform sampler2D texture1;
uniform vec2 resolution;

float PI = 3.141592653;

int MAXIMUM_RAY_STEPS = 1024;
float MIN_DIST = .001;
float MAX_DIST = 500.;

// EPSILON ϵ - usually used to denote a small quantity
float EPSILON = 0.0001;

// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
vec3 mod289 (vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289 (vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+10.0)*x); }
float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
            + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float terrain(vec2 p){
    p /= 6.; // Choosing a suitable starting frequency.
    
    // Edging the terrain surfacing into a position I liked more. Not really necessary though.
    p += .5; 

    // Amplitude, amplitude total, and result variables.
    float a = .1, sum = 0., res = 0.;

    // Only five layers. More layers would be nicer, but cycles need to be taken into
    // consideration. A simple way to give the impression that more layers are being added
    // is to increase the frequency by a larger amount from layer to layer.
    for (int i=0; i<5; i++){
        // res += noised(vec3(p, 0.)).x*a; // with noised`
        res += snoise(p*1.)*a; // Add the noise value for this layer - multiplied by the amplitude.
        // res += abs(n2D(p) - .5)*a; // Interesting variation.
        // res += n2D(p)*abs(a)*.8; // Another one.
        
        // Scaling the position and doing some skewing at the same time. The skewing isn't 
        // mandatory, but it tends to give more varied - and therefore - interesting results.
        // IQ uses this combination a bit, so I'll assume he came up with the figures. I've 
        // tried other figures, but I tend to like these ones as well.      
        p = mat2(1, -.75, .75, 1)*p*2.72;
        //p *= 3.2; // No skewing. Cheaper, but less interesting.
        
        sum += a; // I reasoned that the sum will always be positive.
        
        // Tempering the amplitude. Note the negative sign - a less common variation - which
        // was thrown in just to mix things up.
        a *= -.5/1.7; 
    }
    
   
    return res/sum; // Return the noisy terrain value.
    
}

float fbm(vec2 p, float H) {
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for( int i=0; i<3; i++ )
    {
        t += a*snoise(f*p);
        f *= 2.0;
        a *= G;
    }
    return t;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

float sdFbm(vec3 p) {
    return 0.;
}
float hash(vec3 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + vec3(0.71,0.113,0.419));
    return -1.0+2.0*fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}
float sph( vec3 i, vec3 f, vec3 c )
{
   // random radius at grid vertex i+c
   float rad = 0.5*hash(i+c);
   // distance to sphere at grid vertex i+c
   return length(f-vec3(c)) - rad; 
}

float sdfstuff( vec3 p )
{
    vec3 i = vec3(floor(p));
    vec3 f =       fract(p);
   // distance to the 8 corners spheres
   return min(min(min(sph(i,f,vec3(0,0,0)),
                      sph(i,f,vec3(0,0,1))),
                  min(sph(i,f,vec3(0,1,0)),
                      sph(i,f,vec3(0,1,1)))),
              min(min(sph(i,f,vec3(1,0,0)),
                      sph(i,f,vec3(1,0,1))),
                  min(sph(i,f,vec3(1,1,0)),
                      sph(i,f,vec3(1,1,1)))));
}

float sdFbm( vec3 p, float d ) {
   float s = 1.0;
   for( int i=0; i<11; i++ )
   {
       // evaluate new octave
       float n = s*sdfstuff(p);
	
       // add
       n = smax(n,d-0.1*s,0.3*s);
       d = smin(n,d      ,0.3*s);
	
       // prepare next octave
       p = mat3( 0.00, 1.60, 1.20,
                -1.60, 0.72,-0.96,
                -1.20,-0.96, 1.28 )*p;
       s = 0.5*s;
   }
   return d;
}

float sdf(vec3 p) {
    // float dist = sdfTopoWall(p);
    // float dist = sdfstuff(p);
    float dist = sdFbm(p, 1.);
    return dist;
}

// via the art of code
vec3 getNormal(vec3 p) {
	float d = sdf(p);
    vec2 e = vec2(EPSILON, 0);
    
    vec3 n = d - vec3(
        sdf(p-e.xyy),
        sdf(p-e.yxy),
        sdf(p-e.yyx)
    );
    
    return normalize(n);
}

// src - https://www.shadertoy.com/view/4tByzD
float rayMarch(vec3 origin, vec3 direction) {
    // used to store current and last distance
    vec2 dist = vec2(MIN_DIST);

    for (int i = 0; i < MAXIMUM_RAY_STEPS; i++) {
        // get the point we hit
        vec3 p = origin + direction * dist.y;

        // get minimal distance from objects in the scene
        dist.x = sdf(p);

        // collision detection
        if (dist.x <= EPSILON) {

            // // // return the last depth
            return dist.y;
        }

        // increase last distance
        dist.y += dist.x;

        if (dist.y >= MAX_DIST) {
            return MAX_DIST;
        }
    }

    return MAX_DIST;
}

// diffuse lighting
float getLight(vec3 origin, vec3 p, float d) {
    // float d = distance(origin, p);
    vec3 l = normalize((origin - p) * d);
    vec3 n = getNormal(p);

    // dot gives value between -1 and 1
    // clamp between 0 and 1
    float dif = clamp(dot(n, l), 0., 1.);
    return dif;
}

mat3 lookAt(in vec3 eye, in vec3 tar, in float r){
    vec3 cw = normalize(tar - eye);// camera w
    vec3 cp = vec3(sin(r), cos(r), 0.);// camera up
    vec3 cu = normalize(cross(cw, cp));// camera u
    vec3 cv = normalize(cross(cu, cw));// camera v
    return mat3(cu, cv, cw);
}

void main(void) {
    // this makes it so that the zero uvs are in the center of the view
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;

    // uv.x += time*0.1;

    // rayMarch scene
    // vec3 cam = vec3(0., 0., 9.); // static
    vec3 cam = vec3(vec2(time), 0); // move towards top right
    // vec3 cam = vec3(time*0.4, 0., 10.); // move right
    // vec3 cam = vec3(0., 0., -time*3.); // move forwards
    // vec3 light = vec3(cam.x + 10., cam.y + 10., 3.); // normal
    vec3 light = vec3(cam.x + 0., cam.y + 10., cam.z + 3.);
    vec3 direction = normalize(vec3(uv, -1));
    // vec3 direction = lookAt(cam, vec3(cam.x, 0., 0.), 0.) * normalize(vec3(uv, 1.0));
    float hitDist = rayMarch(cam, direction);

    vec3 color = vec3(0., 0., 0.);

    if (hitDist < MAX_DIST) {
        
        vec3 p = cam + direction * hitDist;

        float diffuse = getLight(light, p, hitDist);
        color = vec3(diffuse);

        // color = getNormal(p);    

        // color = vec3(1.);
    }

    gl_FragColor = vec4(color, 1.);
}