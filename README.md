<h1>Text Generation Demos in Rust using Glyphon</h1>
<p>The purpose of this demonstration is to demonstrate how to add simple text features to an existing game project in rust. For our sample game project, we will be starting with the [scene2d example from the course website](https://cs.pomona.edu/classes/cs181g/examples/) You may choose to follow along using the same example, or another game project of your own.</p>
**The tutorials will build on each other, so don't attempt to do tutorial 3 without reading 1**
<h2>Hello World Text Tutorial</h2>
*step one

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
