uniform float time;
uniform sampler2D texture1;
uniform vec2 resolution;

varying vec2 vUv;
float PI = 3.141592653;

int MAXIMUM_RAY_STEPS = 256;
float MIN_DIST = .001;
float MAX_DIST = 10000.;
vec2 add = vec2(1.0, 0.0);

// EPSILON ϵ - usually used to denote a small quantity
float EPSILON = 0.0001;

float sdfSphere (vec3 p, float r){
    // return distance(mod(p, 10.), vec3(5.))-r;

    return distance(p, vec3(0.))-r;
}

float sdf(vec3 p) {
    // p = p + 1. * vec3(0,-0.5*time,time);
    return sdfSphere(p, .2);
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
    vec3 cam = vec3(0., 0., .75);
    // vec3 cam = vec3(vec2(time*0.75), 0);
    vec3 light = vec3(cam.x + 10., cam.y + 10., 3.);
    vec3 direction = normalize(vec3(uv, -1));
    float hitDist = rayMarch(cam, direction);

    vec3 color = vec3(0., 0., 0.);
    if (hitDist < MAX_DIST) {
        vec3 p = cam + direction * hitDist;
        // color = vec3(1.);
        vec3 normal = getNormal(p);
        
        // float diffuse = getLight(light, p);
        // color = vec3(diffuse * 0.85);
        color = normal;
    }

    gl_FragColor = vec4(color, 1.);
}