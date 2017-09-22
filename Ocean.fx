float Script : STANDARDSGLOBAL 
<
    string UIWidget = "none";
    string ScriptClass = "object";
    string ScriptOrder = "standard";
    string ScriptOutput = "color";
    string Script = "Technique=Blinn?Main:Main10;";
> = 0.8;

float4x4 WorldITXf : WorldInverseTranspose < string UIWidget="None"; >;
float4x4 WvpXf : WorldViewProjection < string UIWidget="None"; >;
float4x4 WorldXf : World < string UIWidget="None"; >;
float4x4 ViewIXf : ViewInverse < string UIWidget="None"; >;

// Sun ---

float3 SunPosition : Position 
<
    string Object = "PointLight0";
    string UIName =  "Sun Position";
    string Space = "World";
> = {-0.5f,2.0f,1.25f};

float3 SunColor : Specular 
<
    string UIName =  "Sun Color";
    string Object = "Pointlight0";
    string UIWidget = "Color";
> = {1.0f,1.0f,1.0f};

// ---

float Timer : TIME < string UIWidget = "None"; >;

float3 AmbientColor : Ambient 
<
    string UIName =  "Ambient Light";
    string UIWidget = "Color";
> = {0.07f,0.07f,0.07f};

float Ks
<
    string UIWidget = "slider";
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.05;
    string UIName =  "Specular";
> = 0.4;

float Eccentricity
<
    string UIWidget = "slider";
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.0001;
    string UIName =  "Highlight Eccentricity";
> = 0.3;

texture ColorTexture : DIFFUSE 
<
    string ResourceName = "default_color.dds";
    string UIName =  "Diffuse Texture";
    string ResourceType = "2D";
>;

sampler2D ColorSampler = sampler_state 
{
    Texture = <ColorTexture>;
    FILTER = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};  

struct appdata 
{
    float3 Position	: POSITION;
    float4 UV		: TEXCOORD0;
    float4 Normal	: NORMAL;
    float4 Tangent	: TANGENT0;
    float4 Binormal	: BINORMAL0;
};

struct vertexOutput 
{
    float4 HPosition	: POSITION;
    float2 UV		: TEXCOORD0;

	// in world coordinates
    float3 LightVec	: TEXCOORD1;
    float3 WorldNormal	: TEXCOORD2;
    float3 WorldTangent	: TEXCOORD3;
    float3 WorldBinormal : TEXCOORD4;
    float3 WorldView	: TEXCOORD5;
	float3 WorldPosition : TEXCOORD6;
};

vertexOutput std_VS(appdata IN) 
{
    vertexOutput result = (vertexOutput)0;
	
	float waveLift = 0.1 * sin(Timer + IN.Position.x + IN.Position.z);
	float3 offsetPosition = {0, waveLift, 0};
	
    result.WorldNormal = mul(IN.Normal,WorldITXf).xyz;
    result.WorldTangent = mul(IN.Tangent,WorldITXf).xyz;
    result.WorldBinormal = mul(IN.Binormal,WorldITXf).xyz;
	result.WorldPosition = IN.Position.xyz + offsetPosition;
	
    float4 Po = float4(result.WorldPosition, 1);
    float3 Pw = mul(Po,WorldXf).xyz;
    result.LightVec = (SunPosition - Pw);
	
    result.UV = IN.UV.xy;

    result.WorldView = normalize(ViewIXf[3].xyz - Pw);
    result.HPosition = mul(Po,WvpXf);
	
    return result;
}

float4 std_PS(vertexOutput IN) : COLOR 
{
	float3 lightDirection = normalize(IN.LightVec);
	float3 worldNormal = normalize(IN.WorldNormal);
	float diffuseAmount = dot(lightDirection, worldNormal);
	float3 diffuseColor = tex2D(ColorSampler,IN.UV).rgb;
	
	float3 red = {1, 0, 0};
	float3 blue = {0, 0, 1};
	
	float t = sin(Timer + IN.WorldPosition.x + IN.WorldPosition.z);
	
	float3 result = (1 - t) * red + t * blue;
	
    return float4(result,1);
}

RasterizerState DisableCulling
{
    CullMode = NONE;
};

DepthStencilState DepthEnabling
{
	DepthEnable = TRUE;
};

BlendState DisableBlend
{
	BlendEnable[0] = FALSE;
};

technique10 Main10 < string Script = "Pass=p0;"; > {
    pass p0 < string Script = "Draw=geometry;"; >
	{
        SetVertexShader( CompileShader( vs_4_0, std_VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, std_PS() ) );
                
        SetRasterizerState(DisableCulling);       
		SetDepthStencilState(DepthEnabling, 0);
		SetBlendState(DisableBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF);
    }
}

technique Main < string Script = "Pass=p0;"; > {
    pass p0 < string Script = "Draw=geometry;"; > 
	{
        VertexShader = compile vs_2_0 std_VS();
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = LessEqual;
		AlphaBlendEnable = false;
		CullMode = None;
        PixelShader = compile ps_2_a std_PS();
    }
}