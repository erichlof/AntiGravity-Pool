#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform vec3 uBallPositions[24];
uniform bool uShotIsInProgress;

#define N_LIGHTS 4.0 // there are 8 lights, but they are half-covered by pool table-box
#define N_SPHERES 8
#define N_BOXES 1

//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>


//----------------------------------------------------------------------------------
float BoxInteriorIntersect( vec3 minCorner, vec3 maxCorner, Ray r, out vec3 normal )
//----------------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / r.direction;
	vec3 near = (minCorner - r.origin) * invDir;
	vec3 far  = (maxCorner - r.origin) * invDir;
	
	vec3 tmin = min(near, far);
	vec3 tmax = max(near, far);
	
	float t0 = max( max(tmin.x, tmin.y), tmin.z);
	float t1 = min( min(tmax.x, tmax.y), tmax.z);
	
	if (t0 > t1) return INFINITY;

	/*
	if (t0 > 0.0) // if we are outside the box
	{
		normal = -sign(r.direction) * step(tmin.yzx, tmin) * step(tmin.zxy, tmin);
		return t0;	
	}
	*/

	if (t1 > 0.0) // if we are inside the box
	{
		normal = -sign(r.direction) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
		return t1;
	}

	return INFINITY;
}

vec3 samplePartialSphereLight(vec3 x, vec3 nl, Sphere light, float percentageRadius, vec3 dirToLight, out float weight, inout uvec2 seed)
{
	dirToLight = (light.position - x); // no normalize (for distance calc below)
	float cos_alpha_max = sqrt(1.0 - clamp((light.radius * light.radius) / dot(dirToLight, dirToLight), 0.0, 1.0));
	
	float cos_alpha = mix( cos_alpha_max, 1.0, rand(seed) ); // 1.0 + (rand(seed) * (cos_alpha_max - 1.0));
	
	float sin_alpha = sqrt(max(0.0, 1.0 - cos_alpha * cos_alpha)) * percentageRadius; 
	float phi = rand(seed) * TWO_PI;

	dirToLight = normalize(dirToLight);

	// from "Building an Orthonormal Basis, Revisited" http://jcgt.org/published/0006/01/01/
	float signf = dirToLight.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (signf + dirToLight.z);
	float b = dirToLight.x * dirToLight.y * a;
	vec3 T = vec3( 1.0 + signf * dirToLight.x * dirToLight.x * a, signf * b, -signf * dirToLight.x );
	vec3 B = vec3( b, signf + dirToLight.y * dirToLight.y * a, -dirToLight.y );
	
	vec3 sampleDir = normalize(T * cos(phi) * sin_alpha + B * sin(phi) * sin_alpha + dirToLight * cos_alpha);
	weight = clamp(2.0 * (1.0 - cos_alpha_max) * max(0.0, dot(nl, sampleDir)), 0.0, 1.0);
	
	return sampleDir;
}


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	float d = INFINITY;
	float t = INFINITY;
	vec3 n;
	
	d = BoxInteriorIntersect( boxes[0].minCorner, boxes[0].maxCorner, r, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = boxes[0].emission;
		intersec.color = boxes[0].color;
		intersec.type = boxes[0].type;
	}

	// white cueball / glass aiming ball
	d = SphereIntersect( 2.0, uBallPositions[0], r );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize((r.origin + r.direction * t) - uBallPositions[0]);
		intersec.emission = vec3(0);
		//intersec.color = uShotIsInProgress ? vec3(1) : vec3(2);
		intersec.color = vec3(1);
		intersec.type = uShotIsInProgress ? COAT : REFR;
	}
	
	// black ball
	d = SphereIntersect( 2.0, uBallPositions[1], r );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize((r.origin + r.direction * t) - uBallPositions[1]);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.005);
		intersec.type = COAT;
	}
	
	// red balls
	for (int i = 2; i < 9; i++)
        {
		d = SphereIntersect( 2.0, uBallPositions[i], r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize((r.origin + r.direction * t) - uBallPositions[i]);
			intersec.emission = vec3(0);
			intersec.color = vec3(1.0, 0.0, 0.0);
			intersec.type = COAT;
		}
	}

	// yellow balls
	for (int i = 9; i < 16; i++)
        {
		d = SphereIntersect( 2.0, uBallPositions[i], r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize((r.origin + r.direction * t) - uBallPositions[i]);
			intersec.emission = vec3(0);
			intersec.color = vec3(1.0, 1.0, 0.0);
			intersec.type = COAT;
		}
	}

	// pockets / lights
        for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize((r.origin + r.direction * t) - spheres[i].position);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
		}
	}

	
	return t;
	
} // end float SceneIntersect( Ray r, inout Intersection intersec )


//---------------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed, inout bool rayHitIsDynamic )
//---------------------------------------------------------------------------
{
	Intersection intersec;
	Sphere lightChoice;
	Ray firstRay;
	Ray secondaryRay;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 secondaryMask = vec3(1);
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float randChoose;

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;
	bool firstTypeWasDIFF = false;
	bool shadowTime = false;
	bool firstTypeWasCOAT = false;


	for (int bounces = 0; bounces < 6; bounces++)
	{

		t = SceneIntersect(r, intersec);

		if (bounces == 0)
		{
			if (intersec.type == COAT)
				rayHitIsDynamic = false;
		}
		 
		// //not used in this scene because we are inside a large box shape - no rays can escape
		// if (t == INFINITY)
		// {
                //         break;
		// }
		
		
		if (intersec.type == LIGHT)
		{	
			if (bounces == 0)
			{
				accumCol = mask * intersec.emission;
				break;
			}

			if (firstTypeWasDIFF)
			{
				if (!shadowTime) 
				{
					if (sampleLight)
						accumCol = mask * intersec.emission * 0.5;
					else if (bounceIsSpecular)
						accumCol = mask * intersec.emission;
					
					// start back at the diffuse surface, but this time follow shadow ray branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					shadowTime = true;
					bounceIsSpecular = false;
					sampleLight = true;
					// continue with the shadow ray
					continue;
				}
				
				accumCol += mask * intersec.emission * 0.5; // add shadow ray result to the colorbleed result (if any)
				
				break;	
			}

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					if (sampleLight)
						accumCol = mask * intersec.emission;
					else if (bounceIsSpecular)
					 	accumCol = mask * clamp(intersec.emission, 0.0, 1.0);
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					bounceIsSpecular = true;
					sampleLight = false;
					// continue with the reflection ray
					continue;
				}

				if (bounceIsSpecular || sampleLight)
					accumCol += mask * intersec.emission; // add reflective result to the refractive result (if any)
				break;	
			}

			if (firstTypeWasCOAT)
			{
				if (!shadowTime) 
				{
					if (sampleLight)
						accumCol = mask * intersec.emission * 0.5;

					// start back at the diffuse surface, but this time follow shadow ray branch
					r = secondaryRay;
					r.direction = normalize(r.direction);
					mask = secondaryMask;
					// set/reset variables
					shadowTime = true;
					bounceIsSpecular = false;
					sampleLight = true;
					// continue with the shadow ray
					continue;
				}

				if (!reflectionTime)
				{
					// add initial shadow ray result to secondary shadow ray result (if any) 
					accumCol += mask * intersec.emission * 0.5;

					// start back at the coat surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					bounceIsSpecular = true;
					sampleLight = false;
					// continue with the reflection ray
					continue;
				}

				// add reflective result to the diffuse result
				if (sampleLight || bounceIsSpecular)
					accumCol += mask * intersec.emission;
				
				break;	
			}

			//if (sampleLight || bounceIsSpecular)
			//	accumCol = mask * intersec.emission; // looking at light through a reflection
			
			// reached a light, so we can exit
			// break;

		} // end if (intersec.type == LIGHT)


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 
		{

			if (firstTypeWasDIFF && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}

			if (firstTypeWasREFR && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				reflectionTime = true;
				bounceIsSpecular = true;
				sampleLight = false;
				// continue with the reflection ray
				continue;
			}

			if (firstTypeWasCOAT && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = secondaryRay;
				r.direction = normalize(r.direction);
				mask = secondaryMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}

			if (firstTypeWasCOAT && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				reflectionTime = true;
				bounceIsSpecular = true;
				sampleLight = false;
				// continue with the reflection ray
				continue;
			}

			// nothing left to calculate, so exit	
			break;
		}


		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;

		
		float angleToNearestLight = -INFINITY;
		float aTest;
		int intBest = 0;
		
		// loop through the 8 sphere lights and find the best one to sample
		for (int i = 0; i < N_SPHERES; i++)
		{
			aTest = dot(nl, normalize(spheres[i].position - x));
			aTest += (rand(seed) * 2.0 - 1.0);
			if (aTest > angleToNearestLight)
			{
				angleToNearestLight = aTest;
				intBest = i;
			} 
		}
	
		lightChoice = spheres[intBest];
		

		    
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			if (diffuseCount == 1 && !firstTypeWasDIFF && !firstTypeWasREFR)
			{	
				// save intersection data for future shadowray trace
				firstTypeWasDIFF = true;
				dirToLight = samplePartialSphereLight(x, nl, lightChoice, 0.2, dirToLight, weight, seed);
				firstMask = mask * weight * N_LIGHTS;
                                firstRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				firstRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
			else if (firstTypeWasREFR && rand(seed) < 0.5)
			{
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			dirToLight = samplePartialSphereLight(x, nl, lightChoice, 0.2, dirToLight, weight, seed);
			mask *= weight * N_LIGHTS;

			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
			
		} // end if (intersec.type == DIFF)
		
		/* if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;

			//bounceIsSpecular = true; // turn on mirror caustics
			continue;
		} */
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.2; // IOR of special thin Glass for this game
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (!firstTypeWasREFR && diffuseCount == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;

				mask = vec3(4);
				mask *= Tr;
			}
			else if (firstTypeWasREFR && !reflectionTime && rand(seed) < Re)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}
			
			// transmit ray through surface
			tdir = r.direction; // this lets the viewing ray pass through without bending due to refraction
			r = Ray(x, normalize(tdir));
			r.origin -= nl * uEPS_intersect;

			mask *= intersec.color;
	
			continue;
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (!firstTypeWasREFR && !firstTypeWasCOAT && diffuseCount == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasCOAT = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}
			else if (firstTypeWasREFR && !reflectionTime && rand(seed) < Re)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}
			
			diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			if (firstTypeWasCOAT && diffuseCount == 1)
                        {
                                // save intersection data for future shadowray trace
				dirToLight = samplePartialSphereLight(x, nl, lightChoice, 0.2, dirToLight, weight, seed);
				secondaryMask = mask * weight * N_LIGHTS;
                                secondaryRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				secondaryRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
                        }
			else if (firstTypeWasREFR && rand(seed) < 0.5)
			{
				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			dirToLight = samplePartialSphereLight(x, nl, lightChoice, 0.2, dirToLight, weight, seed);
			mask *= weight * N_LIGHTS;
			
			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} //end if (intersec.type == COAT)
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z = vec3(0);
	vec3 L = vec3(1, 1, 1) * 30.0; // bright White light
	
        spheres[0] = Sphere(10.0, uBallPositions[16], L, z, LIGHT); // bottom left front spherical light
	spheres[1] = Sphere(10.0, uBallPositions[17], L, z, LIGHT); // bottom right front spherical light
	spheres[2] = Sphere(10.0, uBallPositions[18], L, z, LIGHT); // top left front spherical light
	spheres[3] = Sphere(10.0, uBallPositions[19], L, z, LIGHT); // top right front spherical light

	spheres[4] = Sphere(10.0, uBallPositions[20], L, z, LIGHT); // bottom left back spherical light
	spheres[5] = Sphere(10.0, uBallPositions[21], L, z, LIGHT); // bottom right back spherical light
	spheres[6] = Sphere(10.0, uBallPositions[22], L, z, LIGHT); // top left back spherical light
	spheres[7] = Sphere(10.0, uBallPositions[23], L, z, LIGHT); // top right back spherical light
	
	boxes[0] = Box(vec3(-50.5), vec3(50.5), z, vec3(0.0, 0.05, 0.99), DIFF); // Diffuse Box
}


//#include <pathtracing_main>

// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	if (x < 0.5) 
		return sqrt(2.0 * x) - 1.0;
	else return 1.0 - sqrt(2.0 - (2.0 * x));
}

void main( void )
{
	// not needed, three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	
	// seed for rand(seed) function
	uvec2 seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

	vec2 pixelPos = vec2(0);
	vec2 pixelOffset = vec2(0);
	
	float x = rand(seed);
	float y = rand(seed);

	//if (!uCameraIsMoving)
	{
		pixelOffset.x = tentFilter(x);
		pixelOffset.y = tentFilter(y);
	}
	
	// pixelOffset ranges from -1.0 to +1.0, so only need to divide by half resolution
	pixelOffset /= (uResolution * 1.0); // normally this is * 0.5, but for dynamic scenes, * 1.0 looks sharper

	// we must map pixelPos into the range -1.0 to +1.0
	pixelPos = (gl_FragCoord.xy / uResolution) * 2.0 - 1.0;
	pixelPos += pixelOffset;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand(seed) * TWO_PI; // pick random point on aperture
	float randomRadius = rand(seed) * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	
	Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir );

	SetupScene(); 

	bool rayHitIsDynamic = true;
	
	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance( ray, seed, rayHitIsDynamic );
	
	vec4 previousImage = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);
	vec3 previousColor = previousImage.rgb;

	if (uCameraIsMoving)
	{
                previousColor *= 0.6; // motion-blur trail amount (old image)
                pixelColor *= 0.4; // brightness of new image (noisy)
        }
	else if (previousImage.a > 0.0)
	{
                previousColor *= 0.8; // motion-blur trail amount (old image)
                pixelColor *= 0.2; // brightness of new image (noisy)
        }
	else
	{
                previousColor *= 0.94; // motion-blur trail amount (old image)
                pixelColor *= 0.06; // brightness of new image (noisy)
        }
	
        out_FragColor = vec4( pixelColor + previousColor, rayHitIsDynamic? 1.0 : 0.0 );	
}
