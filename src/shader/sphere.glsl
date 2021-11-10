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

float sdfSphere (vec3 p, float r) {
    // return distance(mod(p, 3.), vec3(1.5))-r;

    return distance(p, vec3(0.))-r;
}

float sdfPlane (vec3 p) {
    return p.y + .25;
}

float sdf(vec3 p) {
    // return sdfSphere(p, .2);
    return min(sdfSphere(p, .2), sdfPlane(p));
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

// via iquelezles
// https://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
// https://www.shadertoy.com/view/lsKcDD
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
	float res = 1.0;
    float t = mint;
    float ph = 1e10; // big, such that y = 0 on the first iteration
    
    for( int i=0; i<32; i++ ) {
		float h = sdf( ro + rd*t );
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, 10.0*d/max(0.0,t-y) );
        ph = h;
        
        t += h;
        
        if( res<0.0001 || t>tmax ) break;
    }

    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
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
    vec3 cam = vec3(0., 0., 1.5);
    // vec3 cam = vec3(0., 0., time);
    vec3 light = vec3(1., sin(time) + 1., 0.);
    vec3 direction = normalize(vec3(uv, -1));
    float hitDist = rayMarch(cam, direction);

    vec3 color = vec3(0., 0., 0.);
    if (hitDist < MAX_DIST) {
        vec3 p = cam + direction * hitDist;
        vec3 normal = getNormal(p);
        color = normal;
        
        float diffuse = getLight(light, p);
        color = vec3(diffuse*.85);

        float shadow = calcSoftshadow(p, light, 0.001, 1.);
        color *= shadow;
    }

    gl_FragColor = vec4(color, 1.);
}