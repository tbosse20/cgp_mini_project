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
};

float4 _BaseColor; // Base color

float _TransS; // Opacity for minor gradient
float _ColorStartS; // Gradient start position
float _ColorEndS; // Gradient end position

float _TransL; // Opacity for major gradient
float _ColorStartL; // Gradient start position
float _ColorEndL; // Gradient end position

v2f vert (appdata v) {
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    o.normal = v.normal;
    return o;
}

// Gradient function
float InverseLerp(float a, float b, float v) {
    return (v-a) / (b-a);
}

fixed4 make_gradients(v2f i) {
    fixed4 col = _BaseColor; // Set base color to color

    // Make major gradient mask
    float tL = saturate(InverseLerp(_ColorStartL, _ColorEndL, i.uv.y));
    tL *= _TransL; // Adjust opacity

    // Make minor gradient mask
    float tS = saturate(InverseLerp(_ColorStartS, _ColorEndS, i.uv.y));
    tS *= _TransS; // Adjust opacity

    float4 t = tL + tS; // Add major and minor gradient mask

    col.a *= t; // Multiply color with mask
    col.a *= abs(i.normal.y) < 0.99; // Only show vertical faces

    return col; // Return color with mask
}