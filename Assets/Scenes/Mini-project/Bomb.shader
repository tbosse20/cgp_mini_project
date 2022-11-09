// https://lexdev.net/tutorials/case_studies/overwatch_shield.html

Shader "Unlit/Bomb" {
    Properties {
        _BaseColor ("Base color", Color) = (.09, .8, .8, 1)
        _IntersectColor ("Intersect color", Color) = (0, 0, .7, 1)
        _IntersectColor2 ("Intersect color", Color) = (0, 0, .7, 1)
        _Height ("Height", range(0, 25)) = 15.0
        _FadeLength ("Fade length", float) = 10.0
        [NoScaleOffset] _PulseTex("Hex Pulse Texture", 2D) = "white" {}
        [NoScaleOffset] _LineTex("Line Texture", 2D) = "white" {}

        _Test("Test float", float) = 1.0
        _Test2("Test float 2", float) = 1.0

    }

    SubShader {
        
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Transparent"
            }
    
        Blend SrcAlpha OneMinusSrcAlpha 

        // Outside rim
        Pass {
            
            Cull Off
            ZWrite Off
            ZTest Less

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                half4 normal : TEXCOORD4;
            };

            float4 _BaseColor;
            sampler2D _CameraDepthTexture; // ############
            float _Height; 

            v2f vert (appdata v) {
                v2f o;
                // v.vertex.y = v.vertex.y / 10;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float4 col = _BaseColor;

                float height = pow((_Height + 10) / 10, 5); // Recalculate height
                // height /= pow(i.uv.x, 1); // Depend to uv scale
                float rimEffect = (1. - saturate(abs(i.uv.y - 0.5) * height));
                float ySides = (abs(i.normal.y) < 0.999);
                float rims = rimEffect * ySides;
                col.a *= rims;

                // col.Emission = _BaseColor.rgb; // Add Emission

                return col;
            }
            ENDCG
        }

        // Inside surface
        Pass {
            
            Cull Off
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                float4 clipPos : TEXCOORD3;
                half3 worldNormal : TEXCOORD5;
                half4 normal : TEXCOORD4;
                half3 viewDir: POSITION1;

            };

            float4 _BaseColor;
            sampler2D _CameraDepthTexture; // ############
            sampler2D _PulseTex; // ############
            sampler2D _LineTex; // ############
            float _Height; 
            float4 _PulseTex_ST; 
            float _Test; 
            float _Test2; 

            v2f vert (appdata v) {
                v2f o;
                v.vertex.y = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // o.clipPos = (v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.uv = TRANSFORM_TEX(v.uv, _PulseTex);
                o.normal = v.normal;
                o.viewDir = ObjSpaceViewDir(v.vertex);
                return o;
            }

            float CalculateBurnNoise(float angle, float2 noiseData)
            {
                float noise = 0;
                noise += (sin(10*angle-noiseData.x* .5)+1) * (sin(noiseData.y*2 )+1)*.5;
                noise += (sin(7 *angle+noiseData.x* 2 )+1) * (cos(noiseData.y*0.4  )+1)*.6;
                noise += (sin(3 *angle+noiseData.x* 4 )+1) * (cos(noiseData.y*0.15)+1)*.7;
                
                return noise;
            }
            fixed4 frag (v2f i) : SV_Target {
                
                float4 col = _BaseColor;

                float sceneZ = LinearEyeDepth(
                    SAMPLE_DEPTH_TEXTURE_PROJ(
                        _CameraDepthTexture,
                    UNITY_PROJ_COORD(i.screenuv)
                    ));

                float3 scale = float3(
                    length(unity_ObjectToWorld._m00_m10_m20),
                    length(unity_ObjectToWorld._m01_m11_m21),
                    length(unity_ObjectToWorld._m02_m12_m22)
                );

                float pulseTexture = tex2D(_PulseTex, i.uv.xy * scale.xz - scale.xz * .5);
                float gradient = pow(saturate(distance(i.uv.xy, (0, 0, .5)) * .9 + .5), 7);
                pulseTexture *= gradient;
                col.a *= pulseTexture;

                float noise = 0;
                noise += sin((distance(i.uv.xy, (0, 0, .5)) - 0.25)) * 100;
                // noise += sin((distance(i.uv.x, (0, 0, .5)) - 0.5 * sin(_Time.y)) * 1) * 10;
                noise += sin((distance(i.uv.xy, (0, 0, .5)) + 0.5 * sin(_Time.y)) * 20);
                // noise += sin((distance(i.uv.y, (0, 0, .5)) - 0.5 * _Time.y) * 20);
                // noise += sin((distance(i.uv.x, (0, 0, .5)) - 0.5 * _Time.y)) * .1 + sin((distance(i.uv.y, (0, 0, .5)) - 0.9 * _Time.y)) * .1;
                // noise = saturate(noise);
                return noise;
                float lineTexture = tex2D(_LineTex, i.uv.xy * scale.xz - scale.xz * .5);
                lineTexture *= pow(saturate(distance(i.uv.xy, (0, 0, .5)) * sin(_Time.y) + .5), 1);

                float2 test = frac(distance(i.uv.xy, (0, 0, .5)) * 25) / (sin(_Time.y) + 1.1);
                test *= lineTexture;
                test *= noise;
                return fixed4(test, 1, 1);

                return lineTexture;

                // return frac(i.screenuv);

                // return fixed4(frac(i.uv * 10), 1, 1);

                // col += 

                // float fresnel = dot(i.worldNormal, i.viewDir) / 50;
                // return fresnel;

                col.a *= i.normal.y > 0.999;

                // col.Emission = col.rgb * tex2D(_PulseTex, i.uv).a;

                return col;
            }
            ENDCG
        }

        // In front objects
        Pass {
            
            Cull Front
            ZWrite Off
            ZTest Greater

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                // half3 normal : TEXCOORD4;
            };

            float4 _BaseColor;
            float4 _IntersectColor;
            float4 _IntersectColor2;
            sampler2D _CameraDepthTexture; // ############
            float _FadeLength;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.uv = v.uv;
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                fixed4 col = _IntersectColor;
                float sceneZ = LinearEyeDepth(
                    SAMPLE_DEPTH_TEXTURE_PROJ(
                        _CameraDepthTexture,
                    UNITY_PROJ_COORD(i.screenuv)
                    ));
                float partZ = i.screenuv.z;
                float diff = sceneZ - partZ;
                float intersect = saturate(pow(_FadeLength * 2, 5) * diff);
                fixed4 test = fixed4(lerp(i.uv, _BaseColor, intersect));
                
                // col.a *= test;

                return col;
            }
            ENDCG
        }

        // Intersection
        Pass {
            
            Cull Front
            ZWrite Off
            ZTest Greater

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                half3 normal : TEXCOORD4;
            };

            float4 _BaseColor;
            float4 _IntersectColor;
            float4 _IntersectColor2;
            sampler2D _CameraDepthTexture; // ############
            float _FadeLength;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.uv = v.uv;
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                fixed4 col = _IntersectColor2;
                float sceneZ = LinearEyeDepth(
                    SAMPLE_DEPTH_TEXTURE_PROJ(
                        _CameraDepthTexture,
                    UNITY_PROJ_COORD(i.screenuv)
                    ));
                float partZ = i.screenuv.z;
                float diff = sceneZ - partZ;
                float intersect = saturate(pow(_FadeLength * 2, 5) * diff);
                fixed4 test = fixed4(lerp(i.uv, fixed4(0, 0, 0, 1), intersect));
                
                col.a *= test;

                return col;
            }
            ENDCG
        }
    }
}
