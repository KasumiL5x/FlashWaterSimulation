package
{
	import flare.basic.*;
	import flare.collisions.MouseCollision;
	import flare.core.*;
	import flare.events.*;
	import flare.loaders.ColladaLoader;
	import flare.loaders.Flare3DLoader1;
	import flare.materials.*;
	import flare.materials.filters.*;
	import flare.physics.colliders.BoxCollider;
	import flare.physics.colliders.Collider;
	import flare.physics.colliders.MeshCollider;
	import flare.physics.Contact;
	import flare.physics.geom.BVH;
	import flare.primitives.*;
	import flare.system.Input3D;
	import flash.display.*;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	public class Main extends Sprite
	{
		private var _scene:Scene3D;
		private var _skybox:SkyBox;
		private var _water:Water;
		private var _rainTimer:Timer;
		//
		private var _mouseCollider:MouseCollision;
		//
		
		// -*- Scene reflection -*-
		private var _reflectionTex:Texture3D;
		private var _reflectionTexSize:uint = 512;
		private var _reflectionCamera:Camera3D;
		
		// -*- Water properties -*-
		private var _gridSize:uint = 200;
		private var _planeSize:uint = 200;
		private var _canDisturbWater:Boolean = false;
		
		// -*- Box settings -*-
		private var _boxYOffset:int = 5;
		private var _boxHeight:int = 20;
		private var _boxThickness:int = 10;
		
		// -*- Box! :D -*-
		private var left:Box;
		private var right:Box;
		private var front:Box;
		private var back:Box;
		private var ground:Box;
		private var _randomBox:Box;
		private var _randomBoxHeight:Number = 10.0;
		
		// -*- Skybox texture -*-
		[Embed(source="/../bin/data/cubemap.png", mimeType="application/octet-stream")]
		private var SkyboxTexture:Class;
		
		public function Main():void
		{
			_scene = new Viewer3D(this, "", 0.2);
			_scene.antialias = 16;
			_scene.autoResize = true;
			_scene.camera.setPosition(120, 40, -30);
			_scene.camera.lookAt(0, 0, 0);

			var dir_light:Light3D = new Light3D("sunlight", Light3D.DIRECTIONAL);
			var dir_light_dir:Vector3D = new Vector3D(-0.4, -0.5, -0.4);
			dir_light_dir.normalize();
			dir_light.setOrientation(dir_light_dir);
			//dir_light.color = new Vector3D(0.0, 1.0, 0.0);
			_scene.lights.defaultLight = null;
			_scene.addChild(dir_light);
			_scene.lights.techniqueName = "phong";
			
			_skybox = new SkyBox(new SkyboxTexture() as ByteArray, SkyBox.HORIZONTAL_CROSS, null, 1.0);
			_scene.addChild(_skybox);
			
			// Create the scene reflection texture.
			_reflectionTex = new Texture3D(new Point(_reflectionTexSize, _reflectionTexSize));
			_reflectionTex.mipMode = Texture3D.MIP_NONE;
			_reflectionTex.wrapMode = Texture3D.WRAP_CLAMP;
			_reflectionTex.upload(_scene); // Send to GPU; generates an actual underlying texture.
			
			_reflectionCamera = new Camera3D("reflection_camera");
			
			configureBox();
			
			_water = new Water(_scene, _gridSize, _planeSize, _boxHeight - 15);
			_water.MirrorTexture = _reflectionTex;
			_water.WaterPlane.useHandCursor = true;
			_water.WaterPlane.mouseEnabled = true;
			
			_scene.addEventListener(Scene3D.UPDATE_EVENT, onUpdate);
			_scene.addEventListener(Scene3D.RENDER_EVENT, onPreRender);
			_scene.addEventListener(Scene3D.POSTRENDER_EVENT, onPostRender);
			
			_rainTimer = new Timer(100, 0);
			_rainTimer.addEventListener(TimerEvent.TIMER, onRain);
			//_rainTimer.start();
			
			_mouseCollider = new MouseCollision(_scene.camera);
			_mouseCollider.addCollisionWith(_water.WaterPlane);
		}
		
		private function onUpdate( e:Event ):void
		{
			// Toggle rain timer.
			if ( Input3D.keyHit(Input3D.CONTROL) )
			{
				if ( _rainTimer.running )
				{
					_rainTimer.stop()
				}
				else
				{
					_rainTimer.start();
				}
			}
			
			// Toggle disturbing of the water.
			if ( Input3D.keyHit(Input3D.SPACE) )
			{ _canDisturbWater = !_canDisturbWater; }
			
			// Disturb the water if the mouse is over it.
			if ( _canDisturbWater )
			{
				var cols:Boolean = _mouseCollider.test(Input3D.mouseX, Input3D.mouseY);
				if ( cols )
				{
					var u:Number = _mouseCollider.data[0].u;
					var v:Number = _mouseCollider.data[0].v;
					_water.displacePoint01(1.0 - u, 1.0 - v, 0.03, 2.0);// 1.5);
				}
			}
			
			_water.update();
			
			_randomBox.y = 10.0 + (Math.sin((getTimer() * 0.001) * 2.0) * _randomBoxHeight) * 0.5 + 0.5;
			_randomBox.transform.appendRotation(2.0, new Vector3D(0.0, 1.0, 0.0));
		}
		
		private function onPreRender( e:Event ):void
		{
			/*
			_reflectionCamera.copyTransformFrom(_scene.camera);
			_reflectionCamera.transform.appendScale(1.0, -1.0, 1.0);
			
			_scene.setupFrame(_reflectionCamera);
			_scene.context.setRenderToTexture(_reflectionTex.texture, true);
			_scene.context.clear(0.0, 0.0, 0.0, 0.0);
			
			_randomBox.y = -_randomBox.y;
			_randomBox.draw();
			_randomBox.y = -_randomBox.y;
			
			_scene.context.setRenderToBackBuffer();
			_scene.setupFrame(_scene.camera);
			*/
			
			
			// Flip the camera upside down, because it's a 'mirror image.'
			_scene.camera.transform.appendScale(1.0, -1.0, 1.0);
			// Set the render target to the mirror texture.
			_scene.context.setRenderToTexture(_reflectionTex.texture, true);
			// Clear texure.
			_scene.context.clear(0, 0, 0, 0);
			// Render everything that we want to reflect.
			_randomBox.y = -_randomBox.y;
			_randomBox.draw();
			_randomBox.y = -_randomBox.y;
			// Flip the camera back so we don't do the normal rendering upside down!
			_scene.camera.transform.appendScale(1.0, -1.0, 1.0);
			// Restore the backbuffer as the render target.
			_scene.context.setRenderToBackBuffer();
		}
		
		private function onPostRender( e:Event ):void
		{
			// Draw water after everything else.
			_water.draw();
		}
		
		private function onRain( evt:TimerEvent ):void
		{
			var random_x:Number = Math.random();
			var random_y:Number = Math.random();
			_water.displacePoint01(random_x, random_y, 0.01, -1.0);
		}
		
		private function configureBox():void
		{
			var box_mat:Shader3D = new Shader3D("box_mat");
			var cf:ColorFilter = new ColorFilter(0x444444, 1.0);
			box_mat.filters.push(cf);
			box_mat.build();
			
			var v_offset:int = _boxYOffset - _boxHeight / 2;
			var h_offset:int = _planeSize / 2 + _boxThickness / 2;
			
			left = new Box("left", _boxThickness, _boxHeight, _planeSize + _boxThickness * 2, 1, box_mat);
			left.setPosition( -h_offset, v_offset, 0);
			_scene.addChild(left);
			
			right = new Box("right", _boxThickness, _boxHeight, _planeSize + _boxThickness * 2, 1, box_mat);
			right.setPosition(h_offset, v_offset, 0);
			_scene.addChild(right);
			
			back = new Box("back", _planeSize, _boxHeight, _boxThickness, 1, box_mat);
			back.setPosition(0, v_offset, h_offset);
			_scene.addChild(back);
			
			front = new Box("front", _planeSize, _boxHeight, _boxThickness, 1, box_mat);
			front.setPosition(0, v_offset, -h_offset);
			_scene.addChild(front);
			
			ground = new Box("ground", _planeSize, _boxThickness, _planeSize, 1, box_mat);
			ground.setPosition(0, v_offset * 2 - _boxThickness, 0);
			_scene.addChild(ground);
			
			var random_mat:Shader3D = new Shader3D("random_mat");
			random_mat.filters.push(new ColorFilter(0xFF00FF, 1.0));
			random_mat.build();
			_randomBox = new Box("random_box", 10, 10, 10, 1, random_mat);
			_randomBox.setPosition(0, 10, 0);
			_scene.addChild(_randomBox);
		}
	}
}