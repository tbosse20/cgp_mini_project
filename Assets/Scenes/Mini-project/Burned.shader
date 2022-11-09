Shader "Unlit/NewUnlitShader" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Slider ("Effect", range(1, 100)) = 1.0
    }

    SubShader {
        Tags { "RenderType"="Opaque" 
            "Queue" = "Transparent"}
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha 

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Slider;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
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
                float4 col = fixed4(1, 1, 1, 1);

                float dist = distance((0, 0, .5), i.uv);
                dist *= 100 - _Slider;

                // return dist;

                // float4 col2 = fixed4(.5, .5, .5, 1) * dist;
                // col = (col2) * .5;
                
                // float4 col3 = frac(fixed4(1, 0, 0, 1) * dist + 10);
                float4 col3 = fixed4(0, 0, 0, .5);

                float mask = 0;
                mask += .5 < dist;
                // clip(mask - .5);

                float noise = 0;
                noise += sin((i.uv.y - 0.5) * 20) * .5 + sin((i.uv.x - 0.5) * 30 + 10);
                noise += sin((i.uv.y - 0.2) * 10) * .5 + sin((i.uv.x - 0.7) * 20 + 10);
                noise += sin((i.uv.y - 0.1) * 5) * .5 + sin((i.uv.x - 0.7) * 10 + 10);
                // clip(noise - .01);
                return noise;
                return noise - dist;
                return noise;

                mask += (sin(10 * i.uv.x * .5) + 1) * (sin(i.uv.y * 2) + 1) * .5;
                mask += (sin(7 * i.uv.x * 2 ) + 1) * (cos(i.uv.y * 0.4) + 1) * .6;
                float test3 =  (sin(3 * i.uv.x * 4 ) + 1) * (cos(i.uv.y * 0.15) + 1) * .7;
                float test1 = (sin(10 * i.uv.x * .5) + 1) * (sin(i.uv.y * 2) + 1) * .5;
                float test2 = (sin(7 * i.uv.x * 2 ) + 1) * (cos(i.uv.y * 0.4) + 1) * .6;

                return col;

                return saturate(lerp(col, col3, (test1 + test2 + test3 + mask) * .25));
                
                // col.r = dist + 5;
                // col.a *= 1 - saturate(dist);
                // col.a *= dist < .6;

                return lerp(col3, col, dist * 1.5);
                // return col;

                // float hole = 1 - saturate(lerp(fixed4(1, 1, 1, 1), fixed4(0, 0, 0, 1), dist));
                // return hole;
                // col.a *= hole;

                return col;
            }
            ENDCG
        }
    }
}
