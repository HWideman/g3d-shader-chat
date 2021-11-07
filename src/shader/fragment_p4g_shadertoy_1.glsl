// SRC - https://www.shadertoy.com/view/tdffzN

uniform float time;
uniform sampler2D texture1;
uniform vec2 resolution;

#define PI 3.141

float unionSdf(float d1, float d2) {
    return min(d1, d2);
}


float rectSdf(
    vec2 uv, 
	vec2 halfSize
) {
    vec2 componentDist = abs(uv) - halfSize;
    float dOut = length(max(componentDist, 0.));
    float dIn = min(max(componentDist.x, componentDist.y), 0.);
    return dOut + dIn;
}


vec2 translate(
	vec2 uv,
    vec2 t
) {
    return uv - t;
}


mat2 rotate2d(float theta) {
    return mat2(cos(theta), -sin(theta),
               sin(theta), cos(theta));
}


float baseShapeSdf(vec2 uv) {
    // Long 
    vec2 shortBarScale = vec2(1./7., 1.);
    // Main shapes
    float longBar = rectSdf(uv, vec2(0.5,4.5));
    float shortBarTop = rectSdf(
        translate(uv, vec2(0., 4.)), 
        vec2(3.5, 0.5)
    );
    float shortBarBottom = rectSdf(
    	translate(uv, vec2(0., -4.)),
        vec2(3.5, 0.5)
    );
    float detailBoxQ1 = rectSdf(
        translate(uv, vec2(2., 3.)),
        vec2(.5, .5)
    );
    float detailBoxQ2 = rectSdf(
        translate(uv, vec2(-2., 3.)),
        vec2(.5, .5)
    );
    float detailBoxQ3 = rectSdf(
        translate(uv, vec2(-2., -3.)),
        vec2(.5, .5)
    );
    float detailBoxQ4 = rectSdf(
        translate(uv, vec2(2., -3.)),
        vec2(.5, .5)
    );
    float shape = longBar;
    shape = unionSdf(shape, shortBarTop);
    shape = unionSdf(shape, shortBarBottom);
    shape = unionSdf(shape, detailBoxQ1);
    shape = unionSdf(shape, detailBoxQ2);
    shape = unionSdf(shape, detailBoxQ3);
    shape = unionSdf(shape, detailBoxQ4);
    return shape;
}

float outlineShape(float shapeSdf) {
    return smoothstep(0., .1, shapeSdf) - smoothstep(0.07, .2, shapeSdf);
}

float placeShape(
	vec2 uv, 
    vec2 t,
    float theta
) {
    float shapeSdf = baseShapeSdf(rotate2d(theta)*translate(uv, t));
    return outlineShape(shapeSdf);
}


float singleTile(vec2 uv) {
    uv = abs(uv);
    float mainShape = placeShape(uv, vec2(0.), 0.);
    
    // float tlShape = placeShape(uv, vec2(5., 5.), 0.);
    
    float tile = mainShape;// + tlShape ;
    return tile;
}


void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    float tileScale = 3.;
    vec2 scaleUv = uv*tileScale;
    // scaleUv += time / 3.5;
    vec2 fractUv = fract(scaleUv);
    // Map each tile to [-5.5, -5.5] x [5.5, 5.5]
    fractUv = 10.*fractUv - 5.;
    float tile = singleTile(fractUv);

    vec3 color = vec3(0.061,0.300,0.274);
    color = mix(color, vec3(0.379,1.000,0.084), tile);

    gl_FragColor = vec4(color, 1.0);
}