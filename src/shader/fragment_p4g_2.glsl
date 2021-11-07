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
    // float longBar = rectSdf(uv, vec2(0.5,4.5));
    float longBar = rectSdf(
        translate(uv, vec2(.75, .0)), 
        vec2(0.25,3.)
    );
    // float longBar2 = rectSdf(uv, vec2(0.5,4.5));
    // float longBar2 = rectSdf(
    //     translate(uv, vec2(.75, .0)), 
    //     vec2(0.25,3.)
    // );
    float detailBoxQ1 = rectSdf(
        translate(uv, vec2(1.25, 2.)),
        vec2(.25, .25)
    );
    // float detailBoxQ2 = rectSdf(
    //     translate(uv, vec2(-2., 2.)),
    //     vec2(.25, .25)
    // );
    // float detailBoxQ3 = rectSdf(
    //     translate(uv, vec2(-2., -2.)),
    //     vec2(.25, .25)
    // );
    // float detailBoxQ4 = rectSdf(
    //     translate(uv, vec2(2., -2.)),
    //     vec2(.25, .25)
    // );
    float shape = longBar;
    // shape = unionSdf(shape, longBar2);
    shape = unionSdf(shape, detailBoxQ1);
    // shape = unionSdf(shape, detailBoxQ2);
    // shape = unionSdf(shape, detailBoxQ3);
    // shape = unionSdf(shape, detailBoxQ4);
    return shape;
}


// float baseShapeSdf(vec2 uv) {
//     // Long 
//     vec2 shortBarScale = vec2(1./7., 1.);
//     // Main shapes
//     float longBar = rectSdf(uv, vec2(0.5,4.5));
//     float shortBarTop = rectSdf(
//         translate(uv, vec2(0., 4.)), 
//         vec2(3.5, 0.5)
//     );
//     float shortBarBottom = rectSdf(
//     	translate(uv, vec2(0., -4.)),
//         vec2(3.5, 0.5)
//     );
//     float detailBoxQ1 = rectSdf(
//         translate(uv, vec2(2., 3.)),
//         vec2(.5, .5)
//     );
//     float detailBoxQ2 = rectSdf(
//         translate(uv, vec2(-2., 3.)),
//         vec2(.5, .5)
//     );
//     float detailBoxQ3 = rectSdf(
//         translate(uv, vec2(-2., -3.)),
//         vec2(.5, .5)
//     );
//     float detailBoxQ4 = rectSdf(
//         translate(uv, vec2(2., -3.)),
//         vec2(.5, .5)
//     );
//     float shape = longBar;
//     shape = unionSdf(shape, shortBarTop);
//     shape = unionSdf(shape, shortBarBottom);
//     shape = unionSdf(shape, detailBoxQ1);
//     shape = unionSdf(shape, detailBoxQ2);
//     shape = unionSdf(shape, detailBoxQ3);
//     shape = unionSdf(shape, detailBoxQ4);
//     return shape;
// }

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
    float mainShape = placeShape(uv, vec2(.5, .75), 0.);
    
    // float tlShape = placeShape(vec2(uv.x, uv.y), vec2(.5, .75), 1.5708);
    
    float tile = mainShape;// + tlShape ;
    // float tile = tlShape;
    return tile;
}


void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
	vec2 UV = gl_FragCoord.xy/resolution.xy;

    vec3 col = vec3(0.);

    uv *= 6.5;
    vec2 gv = fract(uv) - 0.5; // grid coordinates wherein each cell contains coords from -0.5 to 0.5
    vec2 id = floor(uv);
    float checker = mod(id.x+id.y, 2.)*2.-1.;
    col.rg = gv;
    col = vec3(checker);
    // col = vec3(id, 0.);
    if (checker == 1.) col = vec3(0.,1.,0.);
    if (gv.x > .49 || gv.y > .49) col = vec3(1, 0, 0);
    // if (mod(id.x, 3.) == 0. || mod(id.y, 3.) == 0.) col = vec3(0.,0.,0.1*abs(id.x + id.y));
    if (mod(id.x, 2.) == 0. && mod(id.y, 2.) == 0.) {
        col = vec3(0,0,1);
    }
    if(mod(id.x - 1))
    // if (mod(id.x, 3.) == 0.)
    gl_FragColor = vec4(col, 1.);
}