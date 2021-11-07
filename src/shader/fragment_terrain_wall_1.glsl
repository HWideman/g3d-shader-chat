// fragment_terrain_1.glsl

uniform float time;
uniform sampler2D texture1;
uniform vec2 resolution;

float PI = 3.141592653;

int MAXIMUM_RAY_STEPS = 80;
float MIN_DIST = .001;
float MAX_DIST = 500.;

// EPSILON ϵ - usually used to denote a small quantity
float EPSILON = 0.0001;

float hash(vec3 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.318309 + vec3(0.71,0.113,0.419));
    return -1.0+2.0*fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

// returns 3D value noise and its 3 derivatives
// https://iquilezles.org/www/articles/morenoise/morenoise.htm
vec4 noised( in vec3 x ) {
    vec3 p = floor(x);
    vec3 w = fract(x);

    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);

    float a = hash( p+vec3(0,0,0) );
    float b = hash( p+vec3(1,0,0) );
    float c = hash( p+vec3(0,1,0) );
    float d = hash( p+vec3(1,1,0) );
    float e = hash( p+vec3(0,0,1) );
    float f = hash( p+vec3(1,0,1) );
    float g = hash( p+vec3(0,1,1) );
    float h = hash( p+vec3(1,1,1) );

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return vec4( -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z),
                 2.0* du * vec3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,
                                 k2 + k5*u.z + k4*u.x + k7*u.z*u.x,
                                 k3 + k6*u.x + k5*u.y + k7*u.x*u.y ) );
}

float sdfSingleSphere (vec3 p, float r){
    return distance(p, vec3(0., 0., -1.0))-r;

    // return distance(p, vec3(0.))-r;
}

float sdfSphere (vec3 p, float r){
    return distance(mod(p, 64.), vec3(32.))-r;

    // return distance(p, vec3(0.))-r;
}

float sdfTopoSpheres(vec3 p, float r) {
    float sphereDist = distance(mod(p, 64.), vec3(32.))-r;

    vec4 noiseSet = noised(p*vec3(0.25))*0.3;//(noised(p*vec3(.25))*0.75+.15);
    float noise = noiseSet.x*sin(time) + noiseSet.x*cos(time);
    // return sphereDist + 2.*sin(amp*p.x)*sin(amp*p.y)*sin(amp*p.z);
    return sphereDist + noise;
}

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float displacement( vec3 p )
{   
    vec4 noise = noised( p );
    float f;
    f  = 0.5000*noise.x; p = m*p*2.02;
    f += 0.2500*noise.x; p = m*p*2.03;
    f += 0.1250*noise.x; p = m*p*2.01;
	#ifndef LOWDETAIL
        f += 0.0625*noise.x; 
	#endif
    return f;
}

// TERRAIN SRC https://www.shadertoy.com/view/lslfRN

// Compact, self-contained version of IQ's 3D value noise function. I put this together, so be 
// careful how much you trust it. :D
float n3D(vec3 p){
    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

float n2D(vec2 p) {
 
	vec2 i = floor(p); p -= i; p *= p*(3. - p*2.); //p *= p*p*(p*(p*6. - 15.) + 10.);    
    
	return dot(mat2(fract(sin(vec4(0, 41, 289, 330) + dot(i, vec2(41, 289)))*43758.5453))*
               vec2(1. - p.y, p.y), vec2(1. - p.x, p.x));

}

float terrain(vec2 p){
    
    p /= 6.; // Choosing a suitable starting frequency.
    
    // Edging the terrain surfacing into a position I liked more. Not really necessary though.
    p += .5; 

    // Amplitude, amplitude total, and result variables.
    float a = 3., sum = 0., res = 0.;

    // Only five layers. More layers would be nicer, but cycles need to be taken into
    // consideration. A simple way to give the impression that more layers are being added
    // is to increase the frequency by a larger amount from layer to layer.
    for (int i=0; i<5; i++){
        // res += noised(vec3(p, 0.)).x*a; // with noised`
        res += n2D(p*1.5)*a; // Add the noise value for this layer - multiplied by the amplitude.
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

float terrain3D(vec3 p){
    
    p /= vec3(6.); // Choosing a suitable starting frequency.
    
    // Edging the terrain surfacing into a position I liked more. Not really necessary though.
    p += vec3(.5); 

    // Amplitude, amplitude total, and result variables.
    float a = 3., sum = 0., res = 0.;

    // Only five layers. More layers would be nicer, but cycles need to be taken into
    // consideration. A simple way to give the impression that more layers are being added
    // is to increase the frequency by a larger amount from layer to layer.
    for (int i=0; i<5; i++){
        // res += noised(vec3(p, 0.)).x*a; // with noised`
        res += n3D(p*vec3(1.5))*a; // Add the noise value for this layer - multiplied by the amplitude.
        // res += abs(n2D(p) - .5)*a; // Interesting variation.
        // res += n2D(p)*abs(a)*.8; // Another one.
        
        // Scaling the position and doing some skewing at the same time. The skewing isn't 
        // mandatory, but it tends to give more varied - and therefore - interesting results.
        // IQ uses this combination a bit, so I'll assume he came up with the figures. I've 
        // tried other figures, but I tend to like these ones as well.      
        p = mat3(1, -.75, 1, .75, 1, 1, 1, 1, .75)*p*vec3(2.72);
        //p *= 3.2; // No skewing. Cheaper, but less interesting.
        
        sum += a; // I reasoned that the sum will always be positive.
        
        // Tempering the amplitude. Note the negative sign - a less common variation - which
        // was thrown in just to mix things up.
        a *= -.5/1.7; 
    }
    
   
    return res/sum; // Return the noisy terrain value.
    
}

float sdfTopoWall(vec3 p) {
    // vec4 noiseSet = 1.0-abs(noised(p*0.1))*2.;//(noised(p*vec3(.25))*0.75+.15);
    // float noise = noiseSet.x*1.33;
    // return p.z + 70. - noise;

    // float dis = displacement(p)*0.033;

    // return p.z + 70. + (0.2*sin(p.x + 10.))*5. + noise;
    return p.z + 20. + terrain(p.xy);

    // vec4 noiseSet = noised(p*vec3(0.25))*10.;//(noised(p*vec3(.25))*0.75+.15);
    // float noise = noiseSet.x;
    // // // return sphereDist + 2.*sin(amp*p.x)*sin(amp*p.y)*sin(amp*p.z);
    // return p.z - noise;
}

float growth(float initial, float rate, float modulator) {
    return initial * pow((1. + rate), modulator);
}

float sdfGround(vec3 p) {
    return p.y + 10. + (terrain(p.xz) * p.z * 0.05);
}

float sdfTerrainSpheres(vec3 p, float r) {
    float sphereDist = distance(mod(p, 64.), vec3(32.))-r;

    // return sphereDist + 2.*sin(amp*p.x)*sin(amp*p.y)*sin(amp*p.z);
    return sphereDist + terrain(p.xy);
}

float sdf(vec3 p) {
    // p = p + 1. * vec3(0,-0.5*time,time);
    // float dist = sdfSingleSphere(p, .5);
    // float dist = sdfSphere(p, 9.);
    // float dist = sdfTopoSpheres(p, 9.);
    float dist = sdfTopoWall(p);
    float dist2 = sdfGround(p);
    // float dist = sdfTerrainSpheres(p, 9.);
    return min(dist, dist2);
    // return dist2;
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

// via https://www.iquilezles.org/
// vec3 getNormal( vec3 p) {
//     vec2 h = vec2(EPSILON, 0);
//     return normalize(vec3(
//         sdf(p + h.xyy) - sdf(p - h.xyy),
//         sdf(p + h.yxy) - sdf(p - h.yxy),
//         sdf(p + h.yyx) - sdf(p - h.yyx)
//     ));
// }

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

void main(void) {
    // this makes it so that the zero uvs are in the center of the view
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;

    // rayMarch scene
    // vec3 cam = vec3(0., 0., 4.); // static
    // vec3 cam = vec3(vec2(time), 0); // move towards top right
    vec3 cam = vec3(time, 0., 100.); // move right
    // vec3 cam = vec3(0., 0., -time*3.); // move forwards
    // vec3 light = vec3(cam.x + 10., cam.y + 10., 3.); // normal
    vec3 light = vec3(cam.x + 10., cam.y + 10., cam.z + 3.);
    vec3 direction = normalize(vec3(uv, -1));
    float hitDist = rayMarch(cam, direction);

    vec3 color = vec3(0., 0., 0.);

    if (hitDist < MAX_DIST) {
        
        vec3 p = cam + direction * hitDist;

        float diffuse = getLight(light, p, hitDist);
        color = vec3(diffuse);

        color = getNormal(p);    

        // color = vec3(1.);
    }

    gl_FragColor = vec4(color, 1.);
}