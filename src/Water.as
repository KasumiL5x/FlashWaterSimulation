/*
 * 99 little bugs in the code
 * 99 little bugs in the code
 * Take one down, patch it around
 * 117 little bugs in the code
 */

package  
{
	import adobe.utils.CustomActions;
	import flare.basic.Scene3D;
	import flare.core.Surface3D;
	import flare.core.Texture3D;
	import flare.flsl.FLSLInput;
	import flare.flsl.FLSLMaterial;
	import flare.flsl.FLSLShader;
	import flare.primitives.Plane;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.display3D.textures.Texture;
	import flash.events.ShaderEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	/**
	 * ...
	 * @author Daniel Green
	 */
	public class Water 
	{
		private var _scene:Scene3D;
		
		// -*- Simulation properties -*-
		private var _gridSize:uint; /**< Simulation grid size. */
		private var _waterSurface:Surface3D; /**< Surface information that will be uploaded to the plane. */
		private var _vertexData:Vector.<Number>;
		[Embed(source = "/../bin/data/water_update.pbj", mimeType = "application/octet-stream")]
		private var UpdateShader:Class;
		private var _updateShader:Shader; /**< Computation shader for waves. */
		[Embed(source = "/../bin/data/water_normals.pbj", mimeType = "application/octet-stream")]
		private var NormalsShader:Class;
		private var _normalsShader:Shader;
		[Embed(source = "/../bin/data/water_drop.pbj", mimeType = "application/octet-stream")]
		private var DropShader:Class;
		private var _dropShader:Shader;
		private var _elapsedTime:Number = 0.0;
		
		// -*- Materials -*-
		[Embed(source = "/../bin/data/water.flsl.compiled", mimeType = "application/octet-stream")]
		private var _shaderClass:Class;
		private var _shader:FLSLMaterial; /**< Shader for the water. */
		
		// -*- Renderables -*-
		private var _plane:Plane;    /**< Final rendererd geometry. */
		private var _planeSize:uint; /**< Size of the plane geometry. */
		private var _waterHeight:Number; /**< Offset for the caustics plane. */
		
		// -*- Embedded textures and shit -*-
		[Embed(source="/../bin/data/cubemap.png", mimeType="application/octet-stream")]
		private var CubemapTexture:Class;
		private var _cubemapTexture:Texture3D;
		[Embed(source = "../bin/data/normals_2.JPG", mimeType = "application/octet-stream")]
		private var NormalTexture1:Class;
		private var _normalTexture1:Texture3D;
		
		// -*- Color -*-
		private var _baseColor:Vector3D = new Vector3D(0.21, 0.32, 0.55); // Sea blue
		private var _ambient:Number = 0.0;
		
		// -*- Normal texture -*-
		private var _normalScale:Number = 4.0;
		private var _normalSpeed:Number = 0.05;
		private var _normalAlpha:Number = 0.075;
		
		// -*- Foam -*-
		private var _foamMinHeight:Number = 3.0;
		private var _foamMaxHeight:Number = 5.1;
		private var _foamColor:Vector3D = new Vector3D(0.2, 0.2, 0.2);
		
		// -*- Sunlight -*-
		private var _sunStrength:Number = 1.2;
		private var _sunShine:Number = 75.0;
		private var _sunColor:Vector3D = new Vector3D(1.2, 0.4, 0.1);
		private var _sunPow:Number = 0.45454545454545454545454545454545;
		private var _sunEnvMod:Number = 0.40;
		private var _sunDirection:Vector3D = new Vector3D(0.529813, 0.662266, 0.529813);
		
		// -*- Wave color -*-
		private var _waveColorMod:Number = 0.2;
		private var _waveColorPow:Number = 4.0;
		
		// -*- Specular -*-
		private var _specularPow:Number = 1.0;
		private var _specularMod:Number = 0.26;
		
		// -*- Scene reflection -*-
		private var _sceneReflectMod:Number = 0.25;
		
		public function Water( scene:Scene3D, gridSize:uint, planeSize:uint, height:Number )
		{
			this._scene = scene;
			this._gridSize = gridSize;
			this._planeSize = planeSize;
			this._waterHeight = height;
			
			initTextures();
			initShaders();
			initRenderables();
			initSimulation();
			updateShaderParameters();
			updateShaderConstants();
			
			displacePoint01(0.5, 0.5, 0.1, 10.0);
		}
		
		public function get WaterPlane():Plane
		{
			return _plane;
		}
		
		public function set MirrorTexture( value:Texture3D ):void
		{
			_shader.params.ReflectionTex.value = value;
		}
		
		private function initTextures():void
		{
			_cubemapTexture = new Texture3D(new CubemapTexture() as ByteArray, false, Texture3D.FORMAT_RGBA, Texture3D.TYPE_CUBE);
			_cubemapTexture.filterMode = Texture3D.FILTER_LINEAR;
			
			_normalTexture1 = new Texture3D(new NormalTexture1() as ByteArray);
		}
		
		private function initShaders():void
		{
			_shader = new FLSLMaterial("water_shader", new _shaderClass() as ByteArray);
			_shader.build();
		}
		
		private function initRenderables():void
		{
			_plane = new Plane("WaterPlane", _planeSize, _planeSize, _gridSize-1, _shader, "+xz");
		}
		
		private function initSimulation():void
		{
			_vertexData = new Vector.<Number>();
			for ( var y:uint = 0; y < _gridSize; ++y )
			{
				for ( var x:uint = 0; x < _gridSize; ++x )
				{
					_vertexData.push(0.0, 0.0, 0.0, 0.0);
				}
			}
			
			_updateShader = new Shader(new UpdateShader() as ByteArray);
			
			_normalsShader = new Shader(new NormalsShader() as ByteArray);
			
			_dropShader = new Shader(new DropShader() as ByteArray);
			
			_waterSurface = new Surface3D("water_surface");
			_waterSurface.addVertexData(Surface3D.COLOR0, 4);
			_waterSurface.vertexVector = _vertexData;
			_waterSurface.upload(_scene);
			
			_plane.surfaces[0].sources[Surface3D.COLOR0] = _waterSurface;
		}
		
		private function runUpdateShader():void
		{
			var job:ShaderJob = new ShaderJob(_updateShader, _vertexData, _gridSize, _gridSize);
			job.start(true);
		}
		
		private function runNormalsShader():void
		{
			var job:ShaderJob = new ShaderJob(_normalsShader, _vertexData, _gridSize, _gridSize);
			job.start(true);
		}
		
		private function updateBuffers():void
		{
			if ( _waterSurface.vertexBuffer )
			{
				_waterSurface.vertexVector = _vertexData;
				_waterSurface.vertexBuffer.uploadFromVector(_vertexData, 0, _gridSize*_gridSize);
			}
		}
		
		private function updateShaderConstants():void
		{
			_updateShader.data.source.input = _vertexData;
			_updateShader.data.source.width = _gridSize;
			_updateShader.data.source.height = _gridSize;
			
			_normalsShader.data.source.input = _vertexData;
			_normalsShader.data.source.width = _gridSize;
			_normalsShader.data.source.height = _gridSize;
			
			_dropShader.data.source.input = _vertexData;
			_dropShader.data.source.width = _gridSize;
			_dropShader.data.source.height = _gridSize;
		}
		
		private function updateShaderParameters():void
		{
			// Color
			_shader.params.BaseColor.value[0] = _baseColor.x;
			_shader.params.BaseColor.value[1] = _baseColor.y;
			_shader.params.BaseColor.value[2] = _baseColor.z;
			_shader.params.Ambient.value[0] = _ambient;
			
			// Normal texture
			_shader.params.NormalScale.value[0] = _normalScale;
			_shader.params.NormalSpeed.value[0] = _normalSpeed;
			_shader.params.NormalAlpha.value[0] = _normalAlpha;
			
			// Foam
			_shader.params.FoamMinHeight.value[0] = _foamMinHeight;
			_shader.params.FoamMaxHeight.value[0] = _foamMaxHeight;
			_shader.params.FoamColor.value[0] = _foamColor.x;
			_shader.params.FoamColor.value[1] = _foamColor.y;
			_shader.params.FoamColor.value[2] = _foamColor.z;
			
			// Sunlight
			_shader.params.SunStrength.value[0] = _sunStrength;
			_shader.params.SunShine.value[0] = _sunShine;
			_shader.params.SunColor.value[0] = _sunColor.x;
			_shader.params.SunColor.value[1] = _sunColor.y;
			_shader.params.SunColor.value[2] = _sunColor.z;
			_shader.params.SunPow.value[0] = _sunPow;
			_shader.params.SunEnvMod.value[0] = _sunEnvMod;
			_shader.params.L.value[0] = _sunDirection.x;
			_shader.params.L.value[1] = _sunDirection.y;
			_shader.params.L.value[2] = _sunDirection.z;
			
			// Wave color
			_shader.params.WaveColorMod.value[0] = _waveColorMod;
			_shader.params.WaveColorPow.value[0] = _waveColorPow;
			
			// Specular
			_shader.params.SpecularPow.value[0] = _specularPow;
			_shader.params.SpecularMod.value[0] = _specularMod;
			
			// Scene reflection
			_shader.params.SceneReflectMod.value[0] = _sceneReflectMod;
			
			// Cubemap texture
			_shader.params.CubeTex.value = _cubemapTexture;
			
			// Normal texture
			_shader.params.NormalTex1.value = _normalTexture1;
			
			_shader.rebuild();
		}
		
		public function update():void
		{
			_elapsedTime += _scene.updateTime;
			runUpdateShader();
			runNormalsShader();
			updateBuffers();
			updateShaderConstants();
		}
		
		public function draw():void
		{
			_plane.draw();
		}
		
		public function displacePoint01( x:Number, y:Number, radius:Number=0.03, strength:Number=0.01 ):void
		{
			// Clamp inputs.
			x = Math.max(0.0, Math.min(x, 1.0));
			y = Math.max(0.0, Math.min(y, 1.0));
			// Set shader parameters.
			_dropShader.data.GridSize.value = [_gridSize, _gridSize];
			_dropShader.data.Radius.value = [radius];
			_dropShader.data.Strength.value = [strength];
			_dropShader.data.Center.value = [x, y];
			// Run shader job.
			var job:ShaderJob = new ShaderJob(_dropShader, _vertexData, _gridSize, _gridSize);
			job.start(true);
		}
	}

}