import * as THREE from 'three';

import canvasRecord from "canvas-record";
import fragmentShader from '../shader/sphere.glsl';
// import fragmentShader from '../shader/cylinder.glsl';
// import fragmentShader from '../shader/ball_slice.glsl';
// import fragmentShader from '../shader/ball_slice_perpetual.glsl';
// import fragmentShader from '../shader/concrete.glsl';
import vertexShader from '../shader/vertex.glsl';

const clock = new THREE.Clock();

window.onclick = () => {
    clock.running ? clock.stop() : clock.start();
};

let camera, scene, renderer;
let material, geometry, plane;

const RECORDING = false;

const getWidth = () => {
    return window.innerWidth;
};

const getHeight = () => {
    return window.innerHeight;
};

let width = getWidth();
let height = getHeight();

const uniforms = {
    time: { value : 0},
    resolution: { value: new THREE.Vector2(width, height) },
};

const render = () => {
    renderer.render( scene, camera );
    uniforms.time.value = clock.getElapsedTime();
};

const onresize = () => {
    width = getWidth();
    height = getHeight();

    uniforms.resolution = { value: new THREE.Vector2(width, height) };

    camera.aspect = width / height;
    camera.updateProjectionMatrix();

    renderer.setSize( width, height );
    renderer.setClearColor(0xeeeeee, 1);
};

const init = () => {
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x00ff00);
    setupCamera();
    setupRenderer();
    addObjects();
    document.body.appendChild( renderer.domElement );
    render();
    anim();

    if (RECORDING) {
        record();
    }
};

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const record = async () => {
    const canvasRecorder = canvasRecord(renderer.domElement, {
        frameRate: 24,
        recorderOptions: {
            audioBitsPerSecond: 0,
            videoBitsPerSecond: 512000000
        }
    });
    canvasRecorder.start();
    await sleep(5000);
    canvasRecorder.stop();
    canvasRecorder.dispose();
};

const anim = () => {
	requestAnimationFrame( anim );
    render();
};

const setupCamera = () => {
    const frustrumSize = 1;
    camera = new THREE.OrthographicCamera(frustrumSize / -2, frustrumSize / 2, frustrumSize / 2, frustrumSize / -2, -1000, 1000);
	camera.position.z = 2;
};

const setupRenderer = () => {
    renderer = new THREE.WebGLRenderer( { antialias: true } );
    renderer.setPixelRatio(window.devicePixelRatio);
	renderer.setSize( width, height );
};

const addObjects = () => {
    material = new THREE.ShaderMaterial({
        extensions: {
            derivatives: "#extension GL_OES_standard_derivatives : enable"
        },
        side: THREE.DoubleSide,
        uniforms,
        vertexShader,
        fragmentShader,
    });

    geometry = new THREE.PlaneGeometry(1, 1, 1, 1);
    plane = new THREE.Mesh(geometry, material);
    scene.add(plane);
};


export default {
    init,
    onresize,
};
