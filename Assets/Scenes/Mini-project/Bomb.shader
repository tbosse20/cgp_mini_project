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
        [NoScaleOffset] _PulseTex("Hex Pulse Texture", 2D) = "white" {}
        [NoScaleOffset] _LineTex("Line Texture", 2D) = "white" {}
        _NoiseTex("Noise Texture", 2D) = "white" {}

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
                float2 uv : TEXCOORD0;
                float2 textUv : TEXCOORD5;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                half4 normal : TEXCOORD4;
                half4 thickNormal : TEXCOORD6;
            };

            float4 _BaseColor;
            sampler2D _CameraDepthTexture; // ############
            float _Height; 
            float _Intensity; 
            sampler2D _NoiseTex; // ############
            float4 _NoiseTex_ST;
            float _Test; 

            v2f vert (appdata v) {
                v2f o;
                // v.vertex.y = v.vertex.y / 10;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.textUv = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.normal = v.normal;
                // half4 emission = _BaseColor * _Intensity;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float preTest = unity_ObjectToWorld > 0;
                clip(preTest - 0.00001);

                float4 col = _BaseColor;

                float noiseTexture = tex2D(_NoiseTex, i.textUv.x * 2);
                float pulse = 0;
                pulse += sin(_Time.z * 2.5) * 4 + 10;
                pulse += cos(_Time.z * .5) * 6 + 5;
                col += saturate(pow(noiseTexture * 2, pulse));

                float height = pow((_Height + 10) / 10, 5); // Recalculate height
                // height /= pow(i.uv.x, 1); // Depend to uv scale
                float rimEffect = (1. - saturate(abs(i.uv.y - 0.5) * height));
                col.a *= rimEffect;

                float3 scale = float3(
                    length(unity_ObjectToWorld._m00_m10_m20),
                    length(unity_ObjectToWorld._m01_m11_m21),
                    length(unity_ObjectToWorld._m02_m12_m22)
                );
                col.a *= lerp(1, 0, saturate(scale.x - 10));
                col.a *= (abs(i.normal.y) < 0.999);

                return col;
            }
            ENDCG
        }

        // Inside surface
        Pass {
            
            Cull Front
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
                float2 uv2 : TEXCOORD6;
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
            sampler2D _NoiseTex; // ############
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
                o.uv2 = v.uv;
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
                
                float preTest = unity_ObjectToWorld > 0;
                clip(preTest - 0.00001);

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

                // float noise2 = 0;
                // float angle = 2;
                // noise2 += sin(i.uv.x * _Time.y * _Test) * sin(i.uv.y * _Time.y * _Test2);
                // noise2 += sin(i.uv.y * _Time.y * _Test) * sin(i.uv.y * _Time.y * _Test);
                // noise2 += sin((i.uv.x * _Test2) * _Time.y * _Test);
                // noise2 += cos(_Time.y);
                // return noise2;

                // return ;

                // float2 test2 = lerp(float4(0, 0, 0, 1), float4(1, 1, 1, 1), i.uv);
                // return fixed4(test2, 1, 1);
                // return fixed4(frac(i.uv) * 100, 1, 1);
                // noiseTexture *= 1- saturate(distance(i.uv.xy, (0, 0, .5)) * sin(_Time.y) * 1.5 + 0.5);
                // noiseTexture = saturate(noiseTexture);
                // col.a *= noiseTexture;

                // float pulseTexture = tex2D(_PulseTex, i.uv * scale.xz - scale.xz * .5);

                float noise = 0;

                float noiseTexture = tex2D(_NoiseTex, i.normal.xz * scale);
                noise += (pow(1 - noiseTexture, 5) * 10);
                // https://bgolus.medium.com/progressing-in-circles-13452434fdb9

                noise += sin((distance(i.normal.xz, 0) + 0.5 * -_Time.y) * 10) * .3;
                // noise *= ((sin(i.uv) * tan(-_Time.y) * .4)) * .3 + 1;
                noise += sin(i.uv.x * _Time.y * .1) * .5 + cos(i.uv.y * _Time.y * .1) * .5;
                noise *= (pow(1 - noiseTexture, 10) * 50);
                
                float dw = (frac(i.uv * 50) < 0.05);
                // noise += dw;
                col += saturate(noise) * .1;

                float gradient = saturate(distance(i.normal.xz, 0));
                col.a *= gradient;

                col.a *= 0.5;

                float lineTexture = tex2D(_LineTex, i.uv.xy * scale.xz - scale.xz * .5);
                lineTexture *= pow(saturate(distance(i.uv.xy, (0, 0, .5)) * sin(_Time.y) + .5), 1);
                // return lineTexture;

                // float fresnel = dot(i.worldNormal, i.viewDir) / 50;
                // return fresnel;

                float t = lerp(1, 0, saturate(scale.x - 10));
                col.a *= t;
                
                // col.Emission = _BaseColor.rgb;

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
                v.vertex.y = 0;
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

        // Windup
        Pass {
            
            Cull Back
            ZWrite Off

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
                float2 textUv : TEXCOORD5;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                half3 worldNormal : TEXCOORD3;
                half4 normal : TEXCOORD4;
                half4 thickNormal : TEXCOORD6;
                half3 viewDir : POSITION1;
            };

            float4 _BaseColor;
            sampler2D _CameraDepthTexture;
            float _Height;
            float _Intensity;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            float _Test; 
            float _Test2; 

            v2f vert (appdata v) {
                v2f o;
                // o.uv = v.uv;
                // o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                // v.vertex += v.normal * o.uv;
                
                // https://en.wikibooks.org/wiki/Cg_Programming/Unity/Displacement_Maps
                float4 dispTexCol = tex2Dlod(_NoiseTex, v.uv);
                float dispVal = dot(float3(0.21, 0.72, 0.07), dispTexCol.rgb);
                dispVal *= .5 / (unity_ObjectToWorld - .5);
                v.vertex += v.normal * dispVal;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.screenuv = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.screenuv.z);
                o.normal = v.normal;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = ObjSpaceViewDir(v.vertex);

                // half4 emission = _BaseColor * _Intensity;
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
                fresnel = lerp(fixed4(0, 0, 0, 0), fixed4(1, 1, 1, 1), 1 - fresnel) * .5;
                fresnel += float4(1, 1, 1, 1);
                col += fresnel;

                return col;
            }
            ENDCG
        }
    }
	Fallback "Diffuse"
}
