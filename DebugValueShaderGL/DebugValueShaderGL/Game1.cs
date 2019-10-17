
using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System.Collections.Generic;

namespace DebugValueShaderGL
{
    /// <summary>
    /// This is the main type for your game.
    /// </summary>
    public class Game1 : Game
    {
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;
        //SpriteFont font;

        Effect refractionEffect;
        Texture2D tex2dForground;
        Texture2D tex2dRefractionTexture;

        // some default control values for the refractions.
        Vector2 scrollOffset = new Vector2();
        Vector2 scrollDirection = new Vector2(.707106f, -.707106f);
        float scrollSpeed = .037f;
        float waveLength = .2f;
        float frequency = .07f;
        Vector2 forceOrigin = new Vector2(0f, 0f);
        Vector2 forceDirectionNormal = new Vector2(1, 0);
        float forceRange = 300;
        float angularRangeDegrees = 15;
        int step = 1;

        // To alter the size and position on the screen of all the image squares.
        // Change the w h values.
        public int StW { get; set; }
        public int StH { get; set; }


        public Game1()
        {
            graphics = new GraphicsDeviceManager(this);
            graphics.PreferredBackBufferWidth = 1200;
            graphics.PreferredBackBufferHeight = 800;
            graphics.GraphicsProfile = GraphicsProfile.HiDef;
            Window.AllowUserResizing = true;
            Content.RootDirectory = "Content";
            IsMouseVisible = true;
            StW = graphics.PreferredBackBufferWidth / 4;
            StH = graphics.PreferredBackBufferHeight / 3;
        }

        protected override void Initialize()
        {
            base.Initialize();
        }

        protected override void LoadContent()
        {
            spriteBatch = new SpriteBatch(GraphicsDevice);

            //font = Content.Load<SpriteFont>("MgGenFont");
            refractionEffect = Content.Load<Effect>("ShaderDebugFx");

            // the primary two textures used for all the tests.
            tex2dForground = Content.Load<Texture2D>("MG_Logo_Small_exCanvs"); ;
            tex2dRefractionTexture = Content.Load<Texture2D>("RefactionTexture");
        }

        protected override void UnloadContent()
        {
        }

        // timers for update hate for keys to repeat firing.
        float regularCycleTimerDirection = 1f;
        float regularCycleTimer = 1.0f;
        float pauseTimer = 1.0f;
        float pauseDelay = .5f;
        int choice = 0;

        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();
            // elapsed time
            float elapsed = (float)gameTime.ElapsedGameTime.TotalSeconds;

            // 2 second oscilation 1 second = 1/half a wavelength or a frequency peak.
            if (regularCycleTimer > 1.0f)
                regularCycleTimerDirection = -1f;
            if (regularCycleTimer < 0f)
                regularCycleTimerDirection = 1f;
            regularCycleTimer += regularCycleTimerDirection * elapsed * .20f;

            if (pauseTimer > 0f)
                pauseTimer = pauseTimer - elapsed;
            else
            {
                if (Keyboard.GetState().IsKeyDown(Keys.Space))
                {
                    choice++;
                    //if (choice >= Asset.Texture2DList.Count)
                    //    choice = 0;
                    //tex2dForground = Asset.Texture2DList[choice];
                    pauseTimer = pauseDelay;
                }
                if (Keyboard.GetState().IsKeyDown(Keys.Up))
                    waveLength += .001f;
                if (Keyboard.GetState().IsKeyDown(Keys.Down))
                    waveLength -= .001f;
                if (Keyboard.GetState().IsKeyDown(Keys.Right))
                    frequency += .001f;
                if (Keyboard.GetState().IsKeyDown(Keys.Left))
                    frequency -= .001f;
                if (Keyboard.GetState().IsKeyDown(Keys.W))
                    waveLength -= .01f;
                if (Keyboard.GetState().IsKeyDown(Keys.F))
                    frequency -= .01f;

            }

            // scroll may not use this or might use it.
            scrollOffset += scrollDirection * scrollSpeed * elapsed;

            // in this case its probably the mouse position.
            forceOrigin = Mouse.GetState().Position.ToVector2();

            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);

            // Draw the images well be using. row 1  far left we squeeze the regular two images in here that we use.

            spriteBatch.Begin();
            spriteBatch.Draw(tex2dRefractionTexture, new Rectangle(StW * 0, StH * 0, StW, StH / 2), Color.White);
            spriteBatch.Draw(tex2dForground, new Rectangle(StW * 0, StH / 2, StW, StH / 2), Color.White);
            spriteBatch.End();

            // top 
            Draw2dRefractionTechnique("RefractionMap", tex2dForground, tex2dRefractionTexture, new Rectangle(StW * 1, StH * 0, StW, StH), forceOrigin, forceDirectionNormal, forceRange, angularRangeDegrees, frequency, waveLength, regularCycleTimer, step, scrollOffset, false, scrollSpeed, gameTime);
            
            // Draw to rest of screen for testing.
            Draw2dRefractionTechnique("ShaderDebugDraw", tex2dForground, tex2dRefractionTexture, new Rectangle(0, StH, StW * 4, StH * 3 - StH), forceOrigin, forceDirectionNormal, forceRange, angularRangeDegrees, frequency, waveLength, regularCycleTimer, step, scrollOffset, true, scrollSpeed, gameTime);

            base.Draw(gameTime);
        }

        /// <summary>
        /// Draw a refracted texture using the refraction technique.
        /// </summary>
        public void Draw2dRefractionTechnique(
            string technique, Texture2D texture, Texture2D displacementTexture, Rectangle screenRectangle,
              Vector2 forceOrigin, Vector2 forceDirectionNormal, float forceDistance, float angularRangeDegrees, float frequency, float sampleWavelength,
              float cycleTime, int step, Vector2 scrollVector, bool useScroll, float circularScrollspeed, GameTime gameTime)
        {
            double time = gameTime.TotalGameTime.TotalSeconds * circularScrollspeed;
            if (useScroll == false)
                scrollVector = new Vector2((float)Math.Cos(time), (float)Math.Sin(time));

            if (sampleWavelength < 0f)
                sampleWavelength = 0f;
            if (frequency < 0f)
                frequency = 0f;

            Vector2 shaderTextPosition = screenRectangle.Location.ToVector2() + new Vector2(20f, 20f);

            // Set an effect parameter to make the displacement texture scroll in a giant circle.
            refractionEffect.CurrentTechnique = refractionEffect.Techniques[technique];
            refractionEffect.Parameters["DisplacementTexture"].SetValue(displacementTexture); //displacementTexture
            refractionEffect.Parameters["DisplacementLookupScrollOffset"].SetValue(FlipVectorYforSpriteBatch(scrollVector));
            refractionEffect.Parameters["ForceLocation"].SetValue(FlipVectorYforSpriteBatch(forceOrigin));
            refractionEffect.Parameters["SampleWavelength"].SetValue(sampleWavelength);
            refractionEffect.Parameters["Frequency"].SetValue(frequency);
            refractionEffect.Parameters["TextPosition"].SetValue(FlipVectorYforSpriteBatch(shaderTextPosition));
            
            //refractionEffect.Parameters["ForceDirectionNormal"].SetValue(forceDirectionNormal);  //(FlipVectorYforSpriteBatch(displacement));
            //refractionEffect.Parameters["ForceDistance"].SetValue(forceDistance);
            //refractionEffect.Parameters["AngularRangeDegrees"].SetValue(angularRangeDegrees);
            //refractionEffect.Parameters["TextureSize"].SetValue(texture.Bounds.Size.ToVector2());
            //refractionEffect.Parameters["ViewportSize"].SetValue( graphics.GraphicsDevice.Viewport.Bounds.Size.ToVector2() );
            //refractionEffect.Parameters["IntegerStep"].SetValue((float)step);
            //refractionEffect.Parameters["CycleTime"].SetValue( cycleTime );

            spriteBatch.Begin(0, null, null, null, null, refractionEffect);
            spriteBatch.Draw(texture, screenRectangle, Color.White);
            spriteBatch.End();
        }

        /// <summary>
        /// since i used spritebatch for this example the y values need fliped by the height, on the shader y 0 is actually on the bottom.
        /// </summary>
        public Vector2 FlipVectorYforSpriteBatch(Vector2 vec)
        {
            return new Vector2(vec.X, graphics.GraphicsDevice.Viewport.Bounds.Size.ToVector2().Y - vec.Y);
        }

    }
}

