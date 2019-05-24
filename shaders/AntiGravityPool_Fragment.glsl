#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform vec3 uBallPositions[24];
uniform bool uShotIsInProgress;

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

float samplePartialSphereLight(vec3 x, vec3 nl, out vec3 dirToLight, Sphere light, float percentageRadius, inout uvec2 seed)
{
	vec3 randPointOnLight = light.position + (randomSphereDirection(seed) * light.radius * percentageRadius);
	dirToLight = randPointOnLight - x;
	
	float r2 = light.radius * light.radius;
	float d2 = dot(dirToLight, dirToLight);
	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));

	dirToLight = normalize(dirToLight);
	float dotNlRayDir = max(0.0, dot(nl, dirToLight));
	
	return 2.0 * (1.0 - cos_a_max) * dotNlRayDir;
}


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	float d;
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

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 dirToLight;
	vec3 tdir;
        
	float nc, nt, Re, Tr;
	float weight;
	float randChoose;
	//float diffuseColorBleeding = 0.2; // range: 0.0 - 0.5, amount of color bleeding between surfaces

	//int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;

	rayHitIsDynamic = false;

	for (int bounces = 0; bounces < 4; bounces++)
	{

		float t = SceneIntersect(r, intersec);
			
		/*
		//not used in this scene because we are inside a large box shape - no rays can escape
		if (t == INFINITY)
		{
                        break;
		}
		*/
		
		
		if (intersec.type == LIGHT)
		{	
			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					if (sampleLight)
						accumCol = mask * intersec.emission;
					else if (bounceIsSpecular)
						accumCol = mask * clamp(intersec.emission, 0.0, 0.1);
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					bounceIsSpecular = true;
					sampleLight = false;
					// continue with the reflection ray
					continue;
				}
				else
				{
					accumCol += mask * intersec.emission; // add reflective result to the refractive result (if any)
					break;
				}	
			}
			if (sampleLight)
				accumCol = mask * intersec.emission;
			else if (bounceIsSpecular)
				accumCol = mask * clamp(intersec.emission, 0.0, 1.0); // looking directly at light or through a SPEC reflection
			
			// reached a light, so we can exit
			break;
		} // end if (intersec.type == LIGHT)


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 
		{
			if (firstTypeWasREFR && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				mask = firstMask;
				// set/reset variables
				reflectionTime = true;
				bounceIsSpecular = true;
				sampleLight = false;
				// continue with the reflection ray
				continue;
			}

			// comment out the following break statement if refractive caustics are still desired
			// nothing left to calculate, so exit	
			break;
		}


		// useful data 
		vec3 n = intersec.normal;
                vec3 nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		vec3 x = r.origin + r.direction * t;

		
		float angleToNearestLight = -INFINITY;
		float aTest;
		int intBest = 0;
		
		// loop through the 8 sphere lights and find the best one to sample
		for (int i = 0; i < N_SPHERES; i++)
		{
			aTest = dot(nl, normalize(spheres[i].position - x));
			//aTest += (1.0 / distance(x, spheres[i].position));
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
			//diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			weight = samplePartialSphereLight(x, nl, dirToLight, lightChoice, 0.3, seed);
			mask *= clamp(weight, 0.0, 1.0);

			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} // end if (intersec.type == DIFF)
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;

			//bounceIsSpecular = true; // turn on mirror caustics
			continue;
		}
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.2; // IOR of special thin Glass for this game
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			Tr = 1.0 - Re;

			if (!firstTypeWasREFR && bounces == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;

				mask = vec3(4);
			}
			
			// transmit ray through surface
			tdir = r.direction; // this lets the viewing ray pass through without bending due to refraction
			r = Ray(x, tdir);
			r.origin -= nl * uEPS_intersect;

			mask *= Tr;
			mask *= intersec.color;
				
			continue;
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			Tr = 1.0 - Re;

			// clearCoat counts as refractive surface
			if (bounces == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
			}
			
			if (bounces > 0 && bounceIsSpecular)
			{
				if (rand(seed) < Re)
				{	
					r = Ray( x, reflect(r.direction, nl) );
					r.origin += nl * uEPS_intersect;
					continue;	
				}
			}
			
			//diffuseCount++;

			mask *= Tr;
			mask *= intersec.color;
			
			bounceIsSpecular = false;

			weight = samplePartialSphereLight(x, nl, dirToLight, lightChoice, 0.3, seed);
			mask *= clamp(weight, 0.0, 1.0);
			
			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} //end if (intersec.type == COAT)
		
	} // end for (int bounces = 0; bounces < 4; bounces++)
	
	return accumCol;      
} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z = vec3(0);
	vec3 L = vec3(1, 1, 1) * 20.0; // bright White light
	
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

	if (!uCameraIsMoving)
	{
		pixelOffset.x = tentFilter(x);
		pixelOffset.y = tentFilter(y);
	}
	
	
	// pixelOffset ranges from -1.0 to +1.0, so only need to divide by half resolution
	pixelOffset /= (uResolution * 1.0); // usually is * 0.5, but in this game, * 1.0 makes the pool balls a little crisper

	// we must map pixelPos into the range -1.0 to +1.0
	pixelPos = (gl_FragCoord.xy / uResolution) * 2.0 - 1.0;
	pixelPos += pixelOffset;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand(seed) * TWO_PI; // pick random point on aperture
	float randomRadius = rand(seed) * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * randomRadius;
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	
	Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir );

	SetupScene(); 

	bool rayHitIsDynamic = false;
	
	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance( ray, seed, rayHitIsDynamic );
	
	vec4 previousImage = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);
	vec3 previousColor = previousImage.rgb;

	if (uCameraIsMoving || previousImage.a > 0.0)
	{
                previousColor *= 0.6; // motion-blur trail amount (old image)
                pixelColor *= 0.4; // brightness of new image (noisy)
        }
	else
	{
                previousColor *= 0.94; // motion-blur trail amount (old image)
                pixelColor *= 0.06; // brightness of new image (noisy)
        }
	
        out_FragColor = vec4( pixelColor + previousColor, rayHitIsDynamic? 1.0 : 0.0 );	
}
