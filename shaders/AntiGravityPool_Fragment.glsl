precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform vec3 uBallPositions[24];
uniform bool uShotIsInProgress;

#define N_LIGHTS 8.0
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
vec3 CalculateRadiance(Ray r)
//---------------------------------------------------------------------------
{
	Intersection intersec;
	Sphere lightChoice;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;

	int intBest = 0;
	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool lastTypeWasREFR = false;


	for (int bounces = 0; bounces < 4; bounces++)
	{
		
		t = SceneIntersect(r, intersec);

		// //not used in this scene because we are inside a large box shape - no rays can escape
		// if (t == INFINITY)
                //         break;
		
		
		if (intersec.type == LIGHT)
		{	
			// viewing light directly, or seeing light source through aiming cueball glass
			if (bounces == 0 || lastTypeWasREFR) 
			{
				accumCol = mask * clamp(intersec.emission, 0.0, 5.0);
				break;
			}
	
			if (bounceIsSpecular || sampleLight) 
			{
				accumCol = mask * intersec.emission;
				break;
			}
				
			//reached a light, so we can exit
			break;
		}


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 
			break;


		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;

		    
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			lastTypeWasREFR = false;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// loop through the 8 sphere lights and find the best one to sample
			for (int i = 0; i < N_SPHERES; i++)
			{
				intBest = rand() < dot(nl, normalize(spheres[i].position - x)) ? i : intBest;
			}
			lightChoice = spheres[intBest];

			dirToLight = randomDirectionInSpecularLobe(normalize(lightChoice.position - x), 0.13);
			mask *= N_LIGHTS;
			mask *= max(0.0, dot(nl, dirToLight)) * 0.005;

			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
			
		} // end if (intersec.type == DIFF)
		
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.3; // IOR of special Glass aiming cueball for this game

			// use 'nl' instead of 'n' in below function arguments for non-ray-bending clear materials
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);


			if (rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// if (bounces == 1)
			// 	mask = vec3(2.0);

			mask *= intersec.color;
			mask *= TP;

			// transmit ray through surface
			tdir = normalize(r.direction); // this lets the viewing ray pass through without bending due to refraction
			r = Ray(x, tdir);
			r.origin -= nl * uEPS_intersect;

			lastTypeWasREFR = true;

			continue;
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.8; // IOR of very thick ClearCoat for pool balls
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			lastTypeWasREFR = false;

			if (rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}
			
			diffuseCount++;

			mask *= TP;
			mask *= intersec.color;
			
			bounceIsSpecular = false;

			// if (diffuseCount == 1 && rand() < 0.5)
			// {
			// 	// choose random Diffuse sample vector
			// 	r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
			// 	r.origin += nl * uEPS_intersect;
			// 	continue;
			// }

			// loop through the 8 sphere lights and find the best one to sample
			for (int i = 0; i < N_SPHERES; i++)
			{
				intBest = rand() * 1.5 < dot(nl, normalize(spheres[i].position - x)) ? i : intBest;
			}
			lightChoice = spheres[intBest];

			dirToLight = randomDirectionInSpecularLobe(normalize(lightChoice.position - x), 0.2);
			mask *= N_LIGHTS;
			mask *= max(0.0, dot(nl, dirToLight)) * 0.01;
			
			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} //end if (intersec.type == COAT)
		
	} // end for (int bounces = 0; bounces < 4; bounces++)
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance(Ray r)


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
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}

void main( void )
{
	// not needed, three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	
	// calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord); // old way of generating random numbers

	randVec4 = texture(tBlueNoiseTexture, (gl_FragCoord.xy + (uRandomVec2 * 255.0)) / 255.0); // new way of rand()
	
	vec2 pixelOffset = vec2( tentFilter(rng()), tentFilter(rng()) ) * 0.5;
	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + pixelOffset) / uResolution) * 2.0 - 1.0;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand() * TWO_PI; // pick random point on aperture
	float randomRadius = rand() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	
	Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir );

	SetupScene(); 
	
	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance(ray);
	
	vec4 previousImage = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);
	vec3 previousColor = previousImage.rgb;

	if (uCameraIsMoving)
	{
                previousColor *= 0.5; // motion-blur trail amount (old image)
                pixelColor *= 0.5; // brightness of new image (noisy)
        }
	else
	{
                previousColor *= 0.9; // motion-blur trail amount (old image)
                pixelColor *= 0.1; // brightness of new image (noisy)
        }
	
        pc_fragColor = vec4( pixelColor + previousColor, 1.0 );	
}
