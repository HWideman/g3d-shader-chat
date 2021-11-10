uniform float time;
uniform sampler2D texture1;
uniform vec2 resolution;

varying vec2 vUv;
float PI = 3.141592653;

const float MAXIMUM_RAY_STEPS = 80.;
float MIN_DIST = .001;
float MAX_DIST = 10000.;
vec2 add = vec2(1.0, 0.0);

// EPSILON ϵ - usually used to denote a small quantity
float EPSILON = 0.0001;

float sdfSphere (vec3 p, float r){
    float d = distance(p, vec3(0.))-r;

    return d;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdWavyPlane (vec3 p, float h) {
    return p.y + -h;
}

float vplane(vec3 p) {
    return p.z;
}

float sdRepeatingBox( vec3 p, vec3 b ) {
    float r = .05;
    p.y = mod(p.y, r)  - (0.5 * r);
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdf(vec3 p) {
    float outerRadius = .25;
    float innerRadius = .225;
    float blocation = time * 0.05;
    float bthickness = 0.02 - (0.05 * distance(p.y, 0.));

    float innerSphere = sdfSphere(p, innerRadius);
    float outerSphere = sdfSphere(p, outerRadius);

    float outside = max(
                        -sdRepeatingBox(
                            p+vec3(0,-blocation,0), 
                            vec3(outerRadius+.01, bthickness, outerRadius+.01)
                        ), 
                        max(-innerSphere, outerSphere)
                    );

    float inside = max(max(-sdfSphere(p, 0.2), sdfSphere(p, 0.22)), vplane(p));

    float center = sdfSphere(p, 0.1);

    return min(center, min(inside, outside));

    // return outside;
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

float rayMarch(vec3 origin, vec3 direction) {
    // used to store current and last distance
    vec2 dist = vec2(MIN_DIST);

    for (float i = 0.; i < MAXIMUM_RAY_STEPS; i+=1.) {
        // get the point we hit
        vec3 p = origin + direction * dist.y;

        // get minimal distance from objects in the scene
        dist.x = sdf(p);

        // collision detection
        if (abs(dist.x) <= EPSILON) {
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
    vec3 cam = vec3(0., 0., .6);
    // vec3 cam = vec3(vec2(time*0.75), 0);
    vec3 light = vec3(cam.x + 4., cam.y + 4., 5.);
    vec3 direction = normalize(vec3(uv, -1));
    float hitDist = rayMarch(cam, direction);

    vec3 color = vec3(0., 0., 0.);

    if (hitDist < MAX_DIST) {
        vec3 p = cam + direction * hitDist;
        // color = vec3(1.);
        vec3 normal = getNormal(p);
        color = normal;

        if (normal.x == 0. && normal.y < 0. && normal.z == 0.) {
            color = vec3(0,1,0);
        }
        
        float diffuse = getLight(light, p) * 0.55;
        color = vec3(diffuse, diffuse, normal.y);
    }

    gl_FragColor = vec4(color, 1.);
}