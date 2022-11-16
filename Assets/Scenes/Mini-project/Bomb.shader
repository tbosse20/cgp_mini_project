// https://lexdev.net/tutorials/case_studies/overwatch_shield.html
// https://gamedevbill.com/paper-burn-shader-in-unity/

Shader "Unlit/Bomb" {
    Properties {
        _BaseColor ("Base color", Color) = (.09, .8, .8, 1)
        _IntersectColor ("Intersect color", Color) = (0, 0, .7, 1)
        _IntersectColor2 ("Intersect color", Color) = (0, 0, .7, 1)
        _Height ("Height", range(0, 25)) = 15.0
        _Intensity ("Intensity", range(0, 25)) = 15.0
        _FadeLength ("Fade length", float) = 10.0
        [NoScaleOffset] _HardNoiseTex("Hard noise", 2D) = "white" {}
        [NoScaleOffset] _SoftNoiseTex("Soft noise", 2D) = "white" {}

        _Test("Test float", float) = 1.0
        _Test2("Test float 2", float) = 1.0

    }

    SubShader {
        
        Tags {
            "RenderType" = "Transparent"
            "IgnoreProjector"="True" 
            "Queue" = "Transparent"
            }
    
        Blend SrcAlpha OneMinusSrcAlpha 
        Cull Off
        ZWrite Off

        // Outside rim
        Pass {
            
            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                v2f o = generalVert(v);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                // Get scale of object
                float3 scale = getScale();

                // Clip when object is negative size
                float preTest = unity_ObjectToWorld > 0;
                clip(preTest - 0.00001);
                
                // Set base color
                float4 col = _BaseColor;
                
                // Adjust height
                float height = pow((_Height + 10) / 10, 5); // Recalculate height
                // height /= pow(i.uv.x, 1); // Depend to uv scale
                float rimEffect = (1. - saturate(abs(i.uv.y - 0.5) * height));
                clip(rimEffect - 0.0001);
                col.a *= rimEffect;

                // Noise texture pulsing with high contrast
                float noiseTexture = tex2D(_HardNoiseTex, i.uvTexture.x * 2);
                float pulse = 0;
                pulse += sin(_Time.z * 2.5) * 4 + 10;
                pulse += cos(_Time.z * .5) * 6 + 5;
                col = saturate(pow(noiseTexture * 2, pulse) + col);

                // Lerp to invisible when larger than 10
                col.a *= lerp(1, 0, saturate(scale.x - 10));

                return col;
            }
            ENDCG
        }

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
                // o.viewDir = mul(modelMatrix, v.vertex).xyz - _WorldSpaceCameraPos;
                o.normalDir = normalize(mul(v.normal, modelMatrixInverse).xyz);
                
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            float makeNoise(v2f i, float text) {
                float noise = 0;
                noise += pow(text, 2);
                noise += sin((distance(i.normal.xz, 0) + .5 * -_Time.y) * 10) * .2;
                noise += sin(i.uv.y * _Time.y * .01) * .1;
                noise *= pow(text, 5) * 10;
                return noise;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                // Clip when object is negative size
                float preTest = unity_ObjectToWorld > 0;
                clip(preTest - 0.00001);

                // Set base color
                float4 col = _BaseColor;

                // Get scale of object
                float3 scale = getScale();

                // Scaling texture at half opacity 
                // float pulseTexture = tex2D(_HardNoiseTex, i.normal.xz * scale);
                // col.a *= saturate(pulseTexture) * .5;

                // Center gradient
                float gradient = pow(saturate(distance(i.normal.xz, 0)), 3);
                
                // Scaling texture with moving sin center gradient
                // https://bgolus.medium.com/progressing-in-circles-13452434fdb9
                float softNoiseTex = tex2D(_SoftNoiseTex, sin(i.normal.xz) * scale);
                float pulseTexture = makeNoise(i, softNoiseTex);
                pulseTexture *= gradient;
                col += pulseTexture * .5;
                
                float invPulseTexture = makeNoise(i, 1-softNoiseTex);
                invPulseTexture *= gradient;
                col.a += invPulseTexture * .2;

                col.a *= gradient;

                // float radiusLines = (frac(i.uv * 50) < 0.15); // Lines outwards
                // float fresnel = dot(i.worldNormal, i.viewDir) / 50;// Fresnel
                // col.a *= 0.5; // Half opacity of pass

                // Lerp to invisible when larger than 10
                float t = lerp(1, 0, saturate(scale.x - 10));
                col.a *= t;

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
                fixed4 col = _IntersectColor2;

                // Adjust height
                float height = pow((_Height + 10) / 10, 5); // Recalculate height
                // height /= pow(i.uv.x, 1); // Depend to uv scale
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

        // Windup
        Pass {
            
            Cull Back

            CGPROGRAM
            #include "BombGeneral.cginc"

            v2f vert (appdata v) {
                
                // https://en.wikibooks.org/wiki/Cg_Programming/Unity/Displacement_Maps
                float4 dispTexCol = tex2Dlod(_SoftNoiseTex, v.uv);
                float dispVal = dot(float3(0.21, 0.72, 0.07), dispTexCol.rgb);
                dispVal *= .5 / (unity_ObjectToWorld - .5);
                v.vertex += v.normal * dispVal;

                v2f o = generalVert(v);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float preTest = unity_ObjectToWorld < 0;
                clip(preTest - 0.00001);
                
                float4 col = _BaseColor;
                col.a = .4;

                // https://gist.github.com/hadashiA/fbd0afb253f161a1589e3df3d43460fd
				float3 f = normalize(i.viewDir);
				float fresnel = 5 + -.5 * pow(1 + dot(f, i.normal), 3);
                fresnel = saturate(lerp(0, 1, 1 - fresnel) * .5 - unity_ObjectToWorld);
                col += fresnel;

                return col;
            }
            ENDCG
        }
    }
	Fallback "Diffuse"
}
