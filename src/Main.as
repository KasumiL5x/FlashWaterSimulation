package
{
	import flare.basic.*;
	import flare.core.*;
	import flare.events.*;
	import flare.materials.*;
	import flare.materials.filters.*;
	import flare.primitives.*;
	import flash.display.*;
	
	public class Main extends Sprite
	{
		private var _scene:Scene3D;
		
		public function Main():void
		{
			_scene = new Viewer3D(this);
			_scene.autoResize = true;
			_scene.camera.setPosition(0, 0, -100);
			_scene.camera.lookAt(0, 0, 0);
			
			var material:Shader3D = new Shader3D("", null, false);
			material.filters.push(new ColorFilter(0xFF00FF, 1.0));
			material.build();
			
			var plane:Plane = new Plane("srcPlane", 10, 10, 1, material);
			for ( var i:uint = 0; i < 200; ++i )
			{
				var clone:Mesh3D = plane.clone() as Mesh3D;
				clone.name == "plane" + i;
				clone.x = Math.random() * 100 - 50;
				clone.y = Math.random() * 100 - 50;
				clone.z = Math.random() * 100 - 50;
				
				clone.addEventListener(MouseEvent3D.CLICK, onClick);
				clone.useHandCursor = true;
				clone.addComponent(new SetOrientationComponent(_scene.camera));
				_scene.addChild(clone);
			}
		}
		
		private function onClick( e:MouseEvent3D ):void
		{
			e.info.mesh.parent = null;
		}
	}
}