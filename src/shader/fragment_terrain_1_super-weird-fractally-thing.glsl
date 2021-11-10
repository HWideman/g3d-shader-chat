// fragment_terrain_1.glsl

uniform float time;
uniform sampler2D texture1;
uniform vec2 resolution;

float PI = 3.141592653;

int MAXIMUM_RAY_STEPS = 256;
float MIN_DIST = .001;
float MAX_DIST = 500.;

// EPSILON ϵ - usually used to denote a small quantity
float EPSILON = 0.0001;

float hash(vec3 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + vec3(0.71,0.113,0.419));
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

float sdfSphere (vec3 p, float r){
    return distance(mod(p, 64.), vec3(32.))-r;

    // return distance(p, vec3(0.))-r;
}

float sdfTopoSpheres(vec3 p, float r) {
    return distance(mod(p, 64.), vec3(32.))-r;
}

float sdf(vec3 p) {
    // p = p + 1. * vec3(0,-0.5*time,time);
    // float dist = sdfSphere(p, 9.);
    float dist = sdfTopoSpheres(p, 9.);
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
            // return the last depth
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
float getLight(vec3 origin, vec3 p) {
    float d = distance(origin, p);
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
    // vec3 cam = vec3(0., 0., 2.);
    vec3 cam = vec3(vec2(time*15.), 0);
    vec3 light = vec3(cam.x + 10., cam.y + 10., 3.);
    vec3 direction = normalize(vec3(uv, -1));
    float hitDist = rayMarch(cam, direction);
    vec3 p = cam + direction * hitDist;
    vec4 noise = noised(p);
    vec3 n = getNormal(p);

    p += n * vec3(noise.y*20.);
    hitDist = distance(cam, p);

    vec3 color = vec3(0., 0., 0.);

    if (hitDist < MAX_DIST) {
        // color = vec3(1.);
        vec3 normal = getNormal(p);
        
        // p = 

        float diffuse = getLight(light, p);
        color = vec3(diffuse * 0.85);

        // float d1 = dot(normal, vec3(noise.x));
        // float val = clamp(dot(d1, diffuse), .1, 1.);

        

        // color = vec3(val);
    }

    gl_FragColor = vec4(color, 1.);
}