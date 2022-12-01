// https://lexdev.net/tutorials/case_studies/overwatch_shield.html
// https://gist.github.com/hadashiA/fbd0afb253f161a1589e3df3d43460fd
// https://bgolus.medium.com/progressing-in-circles-13452434fdb9
// https://en.wikibooks.org/wiki/Cg_Programming/Unity/Displacement_Maps

Shader "Unlit/Bomb" {
    Properties {
        _BaseColor ("Base color", Color) = (.09, .8, .8, 1) // Base color
        _Height ("Rim width", range(0, 1)) = .25 // Outer rim width
        [NoScaleOffset] _HardNoiseTex("Hard noise", 2D) = "white" {} // Primary noise texture 
        [NoScaleOffset] _SoftNoiseTex("Soft noise", 2D) = "white" {} // Secundary noise texture
    }

    SubShader {
        
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha     // Transparency properties
        Cull Off                            // Render both mesh sides
        ZWrite Off

        // Disc surface
        Pass {
            
            Cull Front // Render front mesh

            CGPROGRAM
            #include "BombGeneral.cginc" // Include general code

            v2f vert (appdata v) {
                v.vertex.y = 0; // Set all y-values to 0
                v2f o = generalVert(v); // Get general vert
                return o; 
            }

            // Make animation and highlights
            float makeNoise(v2f i, float text) {

                float noise = 0; // Initialize float for noise
                noise += pow(text, 2); // Static highlights
                noise += sin((distance(i.normal.xz, 0) + .5 * -_Time.y) * 10) * .2; // From center outgoing pulse
                noise += saturate(sin(text * sin(_Time.y * .5 + .5)) * 2); // Over all pulse
                noise *= pow(text, 5) * 10; // Highlight texture 

                return noise;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                showAtScale(1); // Show when object is positive size
                float3 scale = getScale(); // Get scale of object
                float4 col = _BaseColor; // Set base color

                // Scaling texture with moving sin center gradient
                float hardNoiseTex = tex2D(_HardNoiseTex, sin(i.normal.xz) * scale); // Convert texture scale and sin
                float lightning = 1 - hardNoiseTex; // Invert texture values
                lightning = makeNoise(i, lightning); // Make noise on texture
                float softNoiseTex = tex2D(_SoftNoiseTex, i.normal.xz * scale * 3); // Convert texture w/ scale
                lightning *= saturate(softNoiseTex * 2); // Increase soft texture values
                col.a += lightning * .4; // Decrese texture lightning and add to main alpha

                col.a *= distance(i.normal.xz, 0) - scale / 100; // Center gradient
                col.a *= .7; // Half opacity of pass
                
                // White outer rim 
                float outerRim = 1 - saturate(pow(distance(i.normal.y, 0) + _Height, 10)); // Utilize center distance
                col.rgb += pow(outerRim, 10); // Increase highlights

                col.a *= lerp(1, 0, saturate(scale - 10)); // Lerp to invisible when larger than 10

                return col;
            }
            ENDCG
        }

        // Cones
        Pass {
            
            CGPROGRAM
            #include "BombGeneral.cginc" // Include general code

            v2f vert (appdata v) {
                v2f o;

                v.vertex.y = min(.3, v.vertex.y); // Sharp cut ends (postive)
                v.vertex.y = min(.3, -v.vertex.y); // Sharp cut ends (negative)
                v.vertex.y *= (1 / length(unity_ObjectToWorld._m01_m11_m21)) * 10; // Fix length (independed to size)
                
                v.vertex.xz = sin(v.vertex.y) * v.normal.xz; // Curve outgoing 
                v.vertex.xz *= .05 * length(unity_ObjectToWorld._m01_m11_m21); // Thicken realtive to size

                o = generalVert(v); // Get general vert
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                showAtScale(-1); // Show when object is negative size
                float4 col = _BaseColor; // Set base color
                col.rgb *= .5; // Decrease color
                col.a *= .2; // Decrease alpha

                float softNoiseTex = tex2D(_SoftNoiseTex, i.uv * 2);
                col += softNoiseTex * .5;

                // Make fresnel inside cones from white to main color
				float3 viewDir = normalize(i.viewDir); // Normalize view direction vector
                float fresnel = saturate(1 - (3 + 3.5 * pow(dot(viewDir, i.normal), 3))); // Fresnel inner light
                col += fresnel; // Add fresnel to color

                return col;
            }
            ENDCG
        }

        // Windup
        Pass {
            
            CGPROGRAM
            #include "BombGeneral.cginc" // Include general code

            v2f vert (appdata v) {
                float4 dispTexCol = tex2Dlod(_SoftNoiseTex, v.uv); // Convert texture
                float dispVal = dot(.1, dispTexCol.rgb); // Get displacement value using texture
                dispVal *= sin(unity_ObjectToWorld); // Increase displacement factor realtive to size
                v.vertex += v.normal * dispVal; // Extrude vertex by normal realtive to diplacement value 
                v.vertex *= sin(v.normal * _Time.y) * .05 + 1; // Pulse by normals

                v2f o = generalVert(v); // Get general vert
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float3 scale = getScale(); // Get scale of object
                showAtScale(-1); // Show when object is negative size
                
                float4 col = _BaseColor; // Set base color
                col.a = .4; // Decrease opacity

				float3 viewDir = normalize(i.viewDir); // Normalize view direction vector
				float fresnel = 4 + -.5 * pow(1 + dot(viewDir, i.normal), 3.5); // Fresnel
                fresnel = (1 - fresnel) * .5; // Invert fresnel
                col.a += fresnel; // Add fresnel to main alpha
                col.rgb += pow(fresnel, 2); // Highlight fresnel and add to main rgb values

                // Make smoke layers
                float4 smokeLayers = 0; // Make black texture
                // Add multiple noise textures with different size, color-values, and alpha
                for (int iter = 1; iter < 3; iter++) {
                    float2 uvTexture = i.uv * iter * 2 + _Time.x; // Panning textures with different scales
                    float smokeTexture = tex2D(_SoftNoiseTex, uvTexture); // Convert texture to float
                    float4 smoke = iter / 10; // Make smoke, color relative to iteration count
                    smoke.a = smokeTexture; // Set grey texture alpha value by smoke texture
                    smokeLayers += smoke; // Add smoke to smoke layers
                }

                // Add flash to smoke layers
                float flashing = tex2D(_HardNoiseTex, i.uv.x / 1000 + _Time.x); // Convert big panning texture
                smokeLayers += flashing; // Add flash effect to layers
                col *= smokeLayers; // Multiply smoke layers with flash to main color

                float softNoiseTex = tex2D(_SoftNoiseTex, i.uv * 5);
                col.rgb += softNoiseTex * .7;
                
                col.a = saturate(col.a * 1.5); // Adjust alpha to fit 0 - 1, to avoid overlap

                return col;
            }
            ENDCG
        }
        
        // Bloom
        Pass {
            
            CGPROGRAM
            #include "BombGeneral.cginc" // Include general code

            v2f vert (appdata v) {
                
                // Adjust size to look the same getting closer
                float dist = length(ObjSpaceViewDir(v.vertex)); // Get camera to object distance
                dist = min(abs(unity_ObjectToWorld) * 1000, dist * 2); // Pick smallest size or distance 
                v.vertex *= dist; // Change vertex positions depending on picked distance
                
                float dispVal = tex2Dlod(_HardNoiseTex, v.uv); // Convert texture
                v.vertex += v.normal * dispVal; // Extrude vertex by normal realtive to diplacement value 
                v.vertex *= sin(v.normal * _Time.y * 10) * .05 + 1; // Pulse by normals

                v2f o = generalVert(v); // Get general vert
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                // Show only when between -0.2 and 0.1
                float preTest = unity_ObjectToWorld < .1 && unity_ObjectToWorld > -.2;
                clip(preTest - 0.00001);
                
                float4 col = _BaseColor; // Set base color

				float3 viewDir = normalize(i.viewDir); // Normalize view direction vector
                float fresnelBias = 10.25 + unity_ObjectToWorld * 3; // Calculate bias depending on object size
                float fresnelScale = 3.8 + unity_ObjectToWorld * 3; // Calculate scale depending on object size
				float fresnel = fresnelBias - fresnelScale * pow(1 + dot(viewDir, i.normal), 1.5); // Fresnel
                fresnel = saturate(1 - fresnel); // Invert fresnel
                col.a = fresnel; // Add fresnel to main alpha
                col.rgb += pow(fresnel, 10) * 10; // Highlight fresnel and add to main rgb values

                return col;
            }
            ENDCG
        }
    }
	Fallback "Diffuse"
}