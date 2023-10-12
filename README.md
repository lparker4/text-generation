<h1>Text Generation Demos in Rust using Glyphon</h1>
<p>The purpose of this demonstration is to demonstrate how to add simple text features to an existing game project in rust. For our sample game project, we will be starting with the scene2d example from the course website (https://cs.pomona.edu/classes/cs181g/examples/) You may choose to follow along using the same example, or another game project of your own.</p>
<p>If you would like to check your work, the files in this repository are working examples. Files in the main directory called helloworld.rs, typewriter.rs, and score.rs are finished versions for each of the tutorials, and can each be copy+pasted into the main rs file in the src directory to run that example code.</p>
**The tutorials will build on each other, so don't attempt to do tutorial 3 without reading 1
<h2>Hello World Text Tutorial</h2>

<ol>
  <li>Add dependencies to the cargo.toml file</li>
  <!-- -->

        # Our graphics API
        wgpu = "0.17.1"
        glyphon = {git="https://github.com/grovesNL/glyphon.git",rev="1de354c05da2414afdbd5ff0fe2b4104dcf7d414"}
  <li>Change present_mode and alpha_mode in SurfaceConfiguration declaration</li>
  <!-- -->

        let mut config = wgpu::SurfaceConfiguration {
                usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
                format: swapchain_format,
                width: size.width,
                height: size.height,
                present_mode: wgpu::PresentMode::Fifo,
                alpha_mode: CompositeAlphaMode::Opaque,
                view_formats: vec![],
        };
  <li>Change ControlFlow to be the Poll version to improve frame changing</li>
  <!-- -->

          *control_flow = ControlFlow::Poll;
  <li>Add Text rendering code, including a text buffer, to the run function</li>
  <!-- -->
  
            // Set up text renderer
            let mut font_system = FontSystem::new();
            let mut cache = SwashCache::new();
            let mut atlas = TextAtlas::new(&device, &queue, swapchain_format);
            let mut text_renderer =
                TextRenderer::new(&mut atlas, &device, MultisampleState::default(), None);
            let mut buffer = Buffer::new(&mut font_system, Metrics::new(30.0, 42.0));
        
        
            let physical_width = (size.width as f64 * window.scale_factor()) as f32;
            let physical_height = (size.height as f64 * window.scale_factor()) as f32;
        
        
            buffer.set_size(&mut font_system, physical_width, physical_height);
            buffer.set_text(&mut font_system, "Hello world! 👋\nThis is rendered with 🦅 glyphon 🦁\nThe text below should be partially clipped.\na b c d e f g h i j k l m n o p q r s t u v w x y z", Attrs::new().family(Family::SansSerif), Shaping::Advanced);
            buffer.shape_until_scroll(&mut font_system);
  <li>Add Text rendering prepare function to Event::MainEventsCleared beneath queue.write_buffer calls</li>
  <!-- -->

        text_renderer.prepare(
            &device,
            &queue,
            &mut font_system,
            &mut atlas,
            Resolution {
                width: config.width,
                height: config.height,
            },
            [TextArea {
                buffer: &buffer,
                left: 10.0,
                top: 10.0,
                scale: 1.0,
                bounds: TextBounds {
                    left: 0,
                    top: 0,
                    right: 600,
                    bottom: 160,
                },
                default_color: Color::rgb(255, 255, 255),
            }],
            &mut cache,
        ).unwrap();
  <li>After the rpass definition inside of the definition for encoder in Event::MainEventsCleared, make call to text_renderer.render()</li>
  <!-- -->

        text_renderer.render(&atlas, &mut rpass).unwrap();

  <li>Add trim call for the text atlas after frame.present call in Event::MainEventsCleared</li>
  <!-- -->

        atlas.trim();

</ol>
<h2>Typewriter Demo</h2>
<ol>
    <li>Add initial string and displayed string variables to the beginning of the run function before the main loop. These variables will serve as the string that will eventually be typed out, the number of characters total in the string, and a displayed text String variable that will get added to every frame to be displayed.</li>
    <!-- -->

    let mut original_text = "Hello world! 👋\nThis is rendered with 🦅 glyphon 🦁\nThe text below should be partially clipped.\na b c d e f g h i j k l m n o p q r s t u v w x y z";
      let num_chars = original_text.len() as u32;
      let mut displayed_text:String = String::from("");
    <li>Add/edit a set_text line before the run call, to set the buffer text to be the displayed text, which is currently an empty String.</li>
  <!-- -->
  
    buffer.set_text(&mut font_system, displayed_text, Attrs::new().family(Family::SansSerif), Shaping::Advanced);
    <li>Create a file called game_state.rs, and add the following code. This will serve as a game state object that we can make calls to, see the variables of, and edit the variables of from any files. Although we could make these variables in the original main function, in more complicated games, it will be beneficial to have a gamestate, and these are some variables regarding text that make sense to go inside this class.</li>
  <!-- -->

    pub struct GameState{
        // is there currently typewriter typing happening
        pub typing: bool,
        pub chars_typed: u32,
    }
    
    pub fn init_game_state() -> GameState {
        // any necessary functions
        GameState {
            //is there currently typewriter typing happening
            typing : false,
            chars_typed : 0,
        }
    }
   <li>Add the game state module to the top of your main class</li>
  <!-- -->

    mod game_state;

 <li>Instantiate a game_state object, and set gs.typing to be true in the beginning of your run function, before the main loop runs.</li>
  <!-- -->

    let mut gs = game_state::init_game_state();
    gs.typing = true;

 <li>Add typing logic to MainEventsCleared event handler near the beginning</li>
  <!-- -->

                if gs.typing{
                    let chars_iter = original_text.chars();
                    for char in chars_iter.skip(gs.chars_typed as usize){
                        displayed_text += &char.to_string();
                        break;
                    }
                    buffer.set_text(&mut font_system, &displayed_text, Attrs::new().family(Family::SansSerif), Shaping::Advanced);
                    // ADD TYPING LOGIC
                    gs.chars_typed += 1;
                    if gs.chars_typed == num_chars{
                        gs.typing = false;
                    }
                }
 <li>Edit text buffer text to be a reference to displayed text in its original declaration before the main loop, notice that we also reset this text value every time a frame passes in MainEventsCleared in the snippet above</li>
    <!-- -->
  
    buffer.set_text(&mut font_system, &displayed_text, Attrs::new().family(Family::SansSerif), Shaping::Advanced);
  
</ol>

<h2>Score Tutorial</h2>
<ol>
 <li>In the game_state module, add variables for score and score_changing as follows.</li>
    <!-- -->

    pub struct GameState{
        // is there currently typewriter typing happening
        pub typing: bool,
        pub chars_typed: u32,
        pub score: usize,
        pub score_changing: bool,
    }
    
    pub fn init_game_state() -> GameState {
        // any necessary functions
        GameState {
            //is there currently typewriter typing happening
            typing : false,
            chars_typed : 0,
            score : 0,
            score_changing : false,
        }
    }
   <li>During the run function before the main loop is called, change the buffer text to be the score variable referenced as a string.</li>
    <!-- -->

    buffer.set_text(&mut font_system, &gs.score.to_string(), Attrs::new().family(Family::SansSerif), Shaping::Advanced);

   <li>Add key -> score increase logic in MainEventsCleared at beginning. Notice the else statement, which turns off the score_changing logic when the key is released, so that repeats don’t occur when the key is held down for more than one frame before releasing</li>
    <!-- -->

      if input.is_key_down(winit::event::VirtualKeyCode::Space){
                          if !gs.score_changing{
                              gs.score += 1;
                              buffer.set_text(&mut font_system, &gs.score.to_string(), Attrs::new().family(Family::SansSerif), Shaping::Advanced);    
                              gs.score_changing = true;
                          }
      }else{
          gs.score_changing = false;
      }

   <li>Delete the text additions that we made in the last tutorial, like the additional variables. Make sure that all references to deleted variables are changed accordingly to represent the score text, or are deleted.</li>
</ol>






