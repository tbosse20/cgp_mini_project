// https://lexdev.net/tutorials/case_studies/overwatch_shield.html
// https://gamedevbill.com/paper-burn-shader-in-unity/
// https://gist.github.com/hadashiA/fbd0afb253f161a1589e3df3d43460fd
// https://bgolus.medium.com/progressing-in-circles-13452434fdb9
// https://en.wikibooks.org/wiki/Cg_Programming/Unity/Displacement_Maps

Shader "Unlit/Bomb" {
    Properties {
        _BaseColor ("Base color", Color) = (.09, .8, .8, 1)
        _IntersectColor ("Intersect color", Color) = (0, 0, .7, 1)
        _IntersectColor2 ("Intersect color", Color) = (0, 0, .7, 1)
        _Height ("Height", range(0, 1)) = .25
        _Intensity ("Intensity", range(0, 50)) = 15.0
        _FadeLength ("Fade length", float) = 10.0
        [NoScaleOffset] _HardNoiseTex("Hard noise", 2D) = "white" {}
        [NoScaleOffset] _SoftNoiseTex("Soft noise", 2D) = "white" {}

        _Test("Test float", float) = 1.0
        _Test2("Test float 2", float) = 1.0

    }

    SubShader {
        
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            }
    
        Blend SrcAlpha OneMinusSrcAlpha 
        Cull Off
        ZWrite Off

        // Inside surface
        Pass {
            
            Cull Front

            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                v.vertex.y = 0;
                v2f o = generalVert(v);
                
                float4x4 modelMatrix = unity_ObjectToWorld;
                float4x4 modelMatrixInverse = unity_WorldToObject; 
                o.normalDir = normalize(mul(v.normal, modelMatrixInverse).xyz);
                
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            float makeNoise(v2f i, float text) {
                float noise = 0;
                noise += pow(text, 2);
                noise += sin((distance(i.normal.xz, 0) + .5 * -_Time.y) * 10) * .2;
                noise += sin(i.uv.y * _Time.y * .01) * .1;
                noise += saturate(sin(text * sin(_Time.y * .5 + .5)) * 2);
                noise *= pow(text, 5) * 10;
                return noise;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                showAtScale(1); // Show when object is positive size
                float3 scale = getScale(); // Get scale of object
                float4 col = _BaseColor; // Set base color

                // Scaling texture with moving sin center gradient
                float hardNoiseTex = tex2D(_HardNoiseTex, sin(i.normal.xz) * scale);
                float lightning = 1 - hardNoiseTex;
                lightning = makeNoise(i, lightning);
                float softNoiseTex = tex2D(_SoftNoiseTex, i.normal.xz * scale * 3);
                lightning *= saturate(softNoiseTex * 2);
                col.a += lightning * .4;

                col.a *= distance(i.normal.xz, 0) - scale / 100; // Center gradient
                // float radiusLines = (frac(i.uv * 50) < 0.15); // Lines outwards
                // float fresnel = dot(i.worldNormal, i.viewDir) / 50; // Fresnel
                
                col.a *= lerp(1, 0, saturate(scale.x - 10)); // Lerp to invisible when larger than 10

                col.a *= .7; // Half opacity of pass

                return col;
            }
            ENDCG
        }

        // Outside rim
        Pass {
            
            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                v.vertex.y = 0;
                v2f o = generalVert(v);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float3 scale = getScale(); // Get scale of object
                showAtScale(1); // Show when object is positive size
                
                float4 col = _BaseColor; // Set base color

                // Adjust height
                float rimEffect = (-distance(i.normal.y, 0)) + _Height;
                clip(rimEffect - 0.0001);
                col.a *= rimEffect;
                
                // Noise texture pulsing with high contrast
                float noiseTexture = tex2D(_HardNoiseTex, i.normal.xz * scale);
                noiseTexture = pow(noiseTexture * 10, 10);

                col.rgb += noiseTexture;
                col.a = pow(col.a, 10);

                col.a *= lerp(1, 0, saturate(scale - 10)); // Lerp to invisible when larger than 10

                return col;
            }
            ENDCG
        }

        // In front objects
        Pass {
            
            Cull Front
            ZTest Greater

            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                v2f o = generalVert(v);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                showAtScale(1); // Show when object is positive size

                fixed4 col = _IntersectColor;
                float sceneZ = getSceneZ(i);
                float partZ = i.screenuv.z;
                float diff = sceneZ - partZ;
                float intersect = saturate(pow(_FadeLength * 2, 5) * diff);
                float test = lerp(i.uv, _BaseColor, intersect);

                return col;
            }
            ENDCG
        }

        // Intersection
        Pass {
            
            Cull Front
            ZTest Greater

            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                v2f o = generalVert(v);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                showAtScale(1); // Show when object is positive size
                
                fixed4 col = _IntersectColor2;

                // Adjust height
                float height = pow((_Height + 10) / 10, 5); // Recalculate height
                float rimEffect = (1. - saturate(abs(i.uv.y - 0.5) * height));
                clip(rimEffect - 0.0001);
                col.a *= rimEffect;

                float sceneZ = getSceneZ(i);
                float partZ = i.screenuv.z;
                float diff = sceneZ - partZ;
                float intersect = saturate(pow(_FadeLength * 2, 5) * diff);
                float test = lerp(i.uv, fixed4(0, 0, 0, 1), intersect);
                
                col.a *= test;

                return col;
            }
            ENDCG
        }

        // Cones
        Pass {
            
            Cull Off

            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                v2f o;

                v.vertex.y = min(.3, v.vertex.y);
                v.vertex.y = min(.3, -v.vertex.y);
                v.vertex.y *= (1 / length(unity_ObjectToWorld._m01_m11_m21)) * 10;
                
                v.vertex.xz = sin(v.vertex.y);
                v.vertex.x *= v.normal.x * .05 * length(unity_ObjectToWorld._m01_m11_m21);
                v.vertex.z *= v.normal.z * .05 * length(unity_ObjectToWorld._m01_m11_m21);

                o = generalVert(v);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                showAtScale(-1); // Show when object is negative size
                
                float4 col = _BaseColor;
                col.a = .4;

				float3 f = normalize(ObjSpaceViewDir(i.normal));
                float fresnel = 3 + 3.5 * pow(dot(f, i.normal), 3);
                fresnel = saturate(lerp(0, 1, 1-fresnel));
                col += fresnel;

                return col;
            }
            ENDCG
        }

        // Windup
        Pass {
            
            Cull Back

            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                
                float4 dispTexCol = tex2Dlod(_SoftNoiseTex, v.uv);
                float dispVal = dot(float3(0.1, 0.1, 0.1), dispTexCol.rgb);
                dispVal *= sin(unity_ObjectToWorld);
                v.vertex += v.normal * dispVal;

                v2f o = generalVert(v);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                showAtScale(-1); // Show when object is negative size
                
                float4 col = _BaseColor; // Set base color
                col.a = .4;

                float3 scale = getScale();
                float softNoiseTex = tex2D(_SoftNoiseTex, i.uv * 10 / scale);
                col += softNoiseTex * .5 ;
                col *= (.3, .3, .3, 1);

				float3 f = normalize(i.viewDir);
				float fresnel = 4 + -.5 * pow(1 + dot(f, i.normal), 3.5);
                fresnel = saturate(lerp(0, 1, 1 - fresnel) * .5 - unity_ObjectToWorld);
                col += fresnel;

                return col;
            }
            ENDCG
        }
        

        // Windup smoke
        Pass {
            
            Cull Off

            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                
                float4 dispTexCol = tex2Dlod(_SoftNoiseTex, v.uv);
                float dispVal = dot(float3(0.1, 0.1, 0.1), dispTexCol.rgb);
                dispVal *= sin(unity_ObjectToWorld);
                v.vertex += v.normal * dispVal;

                v2f o = generalVert(v);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                showAtScale(-1); // Show when object is negative size
                
                float4 col = fixed4(1, 1, 1, 1);

                for (int ii = 1; ii < 3; ii++) {
                    float smoke = tex2D(_SoftNoiseTex, i.uv * (ii * 2) + _Time.x);
                    float color = ii / 10;
                    col *= fixed4(color, color, color, smoke);
                }
                
                float blackout = tex2D(_HardNoiseTex, i.normalDir + _Time.x);
                col.a *= blackout * .5;
                col.a += .1;
                
                return col;
            }
            ENDCG
        }
        

        // Bloom
        Pass {
            
            Cull Off
            ZWrite Off

            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                
                float dist = length(ObjSpaceViewDir(v.vertex));
                dist = min(abs(unity_ObjectToWorld) * 1000, dist * 2);
                v.vertex *= dist;
                v2f o = generalVert(v);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float preTest = unity_ObjectToWorld < -.01 && unity_ObjectToWorld > -.2;
                clip(preTest - 0.00001);
                
                float4 col = _BaseColor;

				float3 f = normalize(i.viewDir);
				float fresnel = (10.25 + unity_ObjectToWorld * 3) - (3.8 + unity_ObjectToWorld * 3) * pow(1 + dot(f, i.normal), 1.5);
                fresnel = saturate(lerp(_BaseColor, fixed4(1, 1, 1, 1), 1-fresnel));
                col.a = fresnel;
                fresnel = saturate(lerp(_BaseColor, fixed4(1, 1, 1, 1), fresnel));
                col.rgb += pow(fresnel, 10) * 10;
                
                return col;
            }
            ENDCG
        }
    }
	Fallback "Diffuse"
}
