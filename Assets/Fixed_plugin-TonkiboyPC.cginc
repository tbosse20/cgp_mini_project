#pragma target 3.0
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

struct appdata {
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f {
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    float3 normal : NORMAL;
    float3 viewDir : TEXCOORD1;
    float3 worldNormal : TEXCOORD2;
};

float4 _BaseColor; // Base color

float _TransL; // Opacity for major gradient
float _UpperLerpL; // Gradient start position
float _LowerLerpL; // Gradient end position

float _TransS; // Opacity for minor gradient
float _UpperLerpS; // Gradient start position
float _LowerLerpS; // Gradient end position

v2f vert (appdata v) {
    v2f o;

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.normal = v.normal;
    o.uv = v.uv;
    
    // Rotate uv map in -normal.z
    if (-o.normal.z > 0.99) {
        float rotation = 3.14;
        float c = cos(rotation);
        float s = sin(rotation);
        float2x2 mat = float2x2(c, -s, s, c);
        o.uv = o.uv * 2 - 1;
        o.uv = mul(mat, o.uv);
        o.uv = o.uv * 0.5 + 0.5;
    }
    
    return o;
}

// Gradient function
float InverseLerp(float a, float b, float v) {
    return (v-a) / (b-a);
}

fixed4 make_gradients(v2f i) {

    fixed4 col = _BaseColor; // Set base color to color

    // Make major gradient mask
    float tL = saturate(InverseLerp(_UpperLerpL, _LowerLerpL, i.uv.y));
    tL *= _TransL; // Adjust opacity

    // Make minor gradient mask
    float tS = saturate(InverseLerp(_UpperLerpS, _LowerLerpS, i.uv.y));
    tS *= _TransS; // Adjust opacity

    float4 t = tL + tS; // Add major and minor gradient mask

    col.a *= t; // Multiply color with mask
    col.a *= abs(i.normal.y) < 0.99; // Only show vertical faces

    return col; // Return color with mask
}