package  
{
	import adobe.utils.CustomActions;
	import flare.basic.Scene3D;
	import flare.core.Surface3D;
	import flare.core.Texture3D;
	import flare.flsl.FLSLMaterial;
	import flare.primitives.Plane;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.geom.Point;
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
		private var _vertexData:Vector.<Vector.<Number>>;
		private var _currBuffer:uint = 1;
		[Embed(source = "/../bin/data/water_update.pbj", mimeType = "application/octet-stream")]
		private var UpdateShader:Class;
		private var _updateShader:Shader; /**< Computation shader for waves. */
		
		// -*- Materials -*-
		[Embed(source = "/../bin/data/water.flsl.compiled", mimeType = "application/octet-stream")]
		private var _shaderClass:Class;
		private var _shader:FLSLMaterial; /**< Shader for the water. */
		
		// -*- Renderables -*-
		private var _plane:Plane;    /**< Final rendererd geometry. */
		private var _planeSize:uint; /**< Size of the plane geometry. */
		
		public function Water( scene:Scene3D, gridSize:uint, planeSize:uint )
		{
			this._scene = scene;
			this._gridSize = gridSize;
			this._planeSize = planeSize;
			
			initShaders();
			initRenderables();
			initSimulation();
			swapBuffers();
			
			displace(0.5, 0.5, 100);
		}
		
		public function get WaterPlane():Plane
		{
			return _plane;
		}
		
		private function initShaders():void
		{
			_shader = new FLSLMaterial("water_shader", new _shaderClass() as ByteArray);
			_shader.params.CubeTex.value = new Texture3D("data/highlights.png", false, Texture3D.FORMAT_RGBA, Texture3D.TYPE_CUBE);
			_shader.params.NormalTex.value = new Texture3D("data/normalMap.jpg");
			//
			//_shader.params.WaveScale.value[0] = 3.0;
			//
			_shader.params.BaseColor.value[0] = 0.39;
			_shader.params.BaseColor.value[1] = 0.58;
			_shader.params.BaseColor.value[2] = 0.93;
			_shader.params.BaseColor.value[3] = 1.0;
			//
			_shader.params.Ambient.value[0] = 0.2;
		}
		
		private function initRenderables():void
		{
			_plane = new Plane("WaterPlane", _planeSize, _planeSize, _gridSize-1, _shader, "+xz");
		}
		
		private function initSimulation():void
		{
			_vertexData = new Vector.<Vector.<Number>>();
			_vertexData[0] = new Vector.<Number>();
			_vertexData[1] = new Vector.<Number>();
			//_vertexData[0].endian = Endian.LITTLE_ENDIAN;
			//_vertexData[1].endian = Endian.LITTLE_ENDIAN;
			//_vertexData[0].length = _gridSize * _gridSize * 12;
			//_vertexData[1].length = _gridSize * _gridSize * 12;
			for ( var y:uint = 0; y < _gridSize; ++y )
			{
				for ( var x:uint = 0; x < _gridSize; ++x )
				{
					_vertexData[0].push(0.0, 0.0, 0.0);
					_vertexData[1].push(0.0, 0.0, 0.0);
					//var idx:uint = y * _gridSize + x;
					//_vertexData[0][(3 * idx + 1) * 4] = 300.0;
					//_vertexData[1][(3 * idx + 1) * 4] = 300.0;
				}
			}
			
			_updateShader = new Shader(new UpdateShader() as ByteArray);
			
			_waterSurface = new Surface3D("water_surface");
			_waterSurface.addVertexData(Surface3D.COLOR0, 3);
			//_waterSurface.vertexBytes = _vertexData[1 - _currBuffer];
			_waterSurface.vertexVector = _vertexData[1 - _currBuffer];
			_waterSurface.upload(_scene);
			
			_plane.surfaces[0].sources[Surface3D.COLOR0] = _waterSurface;
		}
		
		private function runUpdateShader():void
		{
			var job:ShaderJob = new ShaderJob(_updateShader, _vertexData[1 - _currBuffer], _gridSize, _gridSize);
			job.start(true);
		}
		
		private function updateBuffers():void
		{
			if ( _waterSurface.vertexBuffer )
			{
				//_waterSurface.vertexBytes = _vertexData[1 - _currBuffer];
				_waterSurface.vertexVector = _vertexData[1 - _currBuffer];
				_waterSurface.vertexBuffer.uploadFromVector(_vertexData[1 - _currBuffer], 0, _gridSize*_gridSize);
				//_waterSurface.vertexBuffer.uploadFromByteArray(_vertexData[1 - _currBuffer], 0, 0, _gridSize * _gridSize);
			}
		}
		
		private function swapBuffers():void
		{
			_currBuffer = 1 - _currBuffer;
			
			_updateShader.data.source.input = _vertexData[_currBuffer];
			_updateShader.data.source.width = _gridSize;
			_updateShader.data.source.height = _gridSize;
			_updateShader.data.previous.input = _vertexData[1 - _currBuffer];
			_updateShader.data.previous.width = _gridSize;
			_updateShader.data.previous.height = _gridSize;
		}
		
		public function update():void
		{
			//displace(0.5, 0.5, 10);
			runUpdateShader();
			updateBuffers();
			swapBuffers();
		}
		
		public function displace( x:Number, y:Number, val:Number ):void
		{
			var x_coord:uint = Math.floor(x * _gridSize);
			var y_coord:uint = Math.floor(y * _gridSize);
			var idx:int = _gridSize * y_coord + x_coord;
			_vertexData[_currBuffer][3 * idx + 1] += val;
			_vertexData[1 - _currBuffer][3 * idx + 1] += val;
		}
	}

}