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

vec3 modVec = vec3(3., 0.0, 3.);
void modMap(inout vec3 p) {
    p.x = mod(p.x, modVec.x) - (0.5 * modVec.x);
    p.y = mod(p.y, modVec.y);
    p.z = mod(p.z, modVec.z);
}
 
float sdf(vec3 p) {
    float outerRadius = .25;
    float innerRadius = .225;

    float blocation = cos(time) * outerRadius;
    float bthickness = 0.025;

    float innerSphere = sdfSphere(p, innerRadius);
    float outerSphere = sdfSphere(p, outerRadius);

    return max(
        -sdBox(
            p+vec3(0,-blocation,0), 
            vec3(outerRadius+.01, bthickness, outerRadius+.01)
        ), 
        max(-innerSphere, outerSphere)
    );
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

    for (int i = 0; i < MAXIMUM_RAY_STEPS; i++) {
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
    vec3 light = vec3(cam.x + 4., cam.y + 4., 5.);
    vec3 direction = normalize(vec3(uv, -1));
    float hitDist = rayMarch(cam, direction);

    vec3 color = vec3(0., 0., 0.);

    if (hitDist < MAX_DIST) {
        vec3 p = cam + direction * hitDist;
        vec3 normal = getNormal(p);
        color = normal;

        if (normal.x == 0. && normal.y < 0. && normal.z == 0.) {
            color = vec3(0,1,0);
        }
        
        // float diffuse = getLight(light, p);
        // color = vec3(diffuse * 0.55);
    }

    gl_FragColor = vec4(color, 1.);
}