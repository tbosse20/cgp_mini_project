Shader "Unlit/Bomb" {
    Properties {
        _BaseColor ("Base color", Color) = (.09, .8, .8, 1)
        _IntersectColor ("Intersect color", Color) = (0, 0, .7, 1)
        _IntersectColor2 ("Intersect color", Color) = (0, 0, .7, 1)
        _Height ("Height", range(0, 25)) = 15.0
        _FadeLength ("Fade length", float) = 10.0
        [NoScaleOffset] _PulseTex("Hex Pulse Texture", 2D) = "white" {}

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
            float _Height; 
            float4 _PulseTex_ST; 

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

                col.a *= tex2D(_PulseTex, i.uv.xy * scale.xz - scale.xz * .5);

                // return frac(i.screenuv);

                // return fixed4(frac(i.uv * 10), 1, 1);

                col += pow(saturate(distance(i.uv.xy, (0, 0, .5)) * .5 + .7), 10) * 1;

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
