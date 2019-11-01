# MonoGameValueDisplayShader.
This is a shader for monogame that has solo functions that displays values on a pixels shader without a font.
i.e. it algorithmically draws them by adding the function to the bottom of the pixel shader.
It can display the values for any global value such as world view or projection matrices or any value that is not reliant on per pixel changes.

The shader is pretty big with quite a few branches so don't be suprised if it takes a bit to compile.
There is also line, point and circle outline drawing functions as well. 
Also included is a simple 2d refraction shader.

In the below image the mouse position is sent to the shader and its values are displayed by the function

<img src="https://github.com/willmotil/MonoGameValueDisplayShader./blob/master/ExampleValueDisplayShader.png" >
