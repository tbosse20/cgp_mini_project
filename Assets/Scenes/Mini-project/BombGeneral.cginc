
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
    float2 textUv : TEXCOORD7;

};

float4 _BaseColor;
sampler2D _CameraDepthTexture; // ############
sampler2D _PulseTex; // ############
sampler2D _LineTex; // ############
sampler2D _NoiseTex; // ############
float _Height; 
float4 _PulseTex_ST;
float4 _NoiseTex_ST;
float _Test; 
float _Test2; 

float4 _IntersectColor;
float4 _IntersectColor2;
float _FadeLength;