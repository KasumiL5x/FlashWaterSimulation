package  
{
	import flare.flsl.FLSLMaterial;
	import flare.primitives.Plane;
	/**
	 * ...
	 * @author Daniel Green
	 */
	public class Water 
	{
		// -*- Simulation properties -*-
		private var _gridSize:uint; /**< Simulation grid size. */
		
		// -*- Materials -*-
		private var _shader:FLSLMaterial; /**< Shader for the water. */
		
		// -*- Renderables -*-
		private var _plane:Plane;    /**< Final rendererd geometry. */
		private var _planeSize:uint; /**< Size of the plane geometry. */
		
		public function Water( gridSize:uint, planeSize:uint )
		{
			this._gridSize = gridSize;
			this._planeSize = planeSize;
			
			initializeRenderables();
		}
		
		public function get WaterPlane():Plane
		{
			return _plane;
		}
		
		private function initializeRenderables():void
		{
			_plane = new Plane("WaterPlane", _planeSize, _planeSize, _gridSize-1, _shader, "+xz");
		}
		
	}

}