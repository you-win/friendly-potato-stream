use gdnative::prelude::*;
use mouse_rs::Mouse;

#[derive(NativeClass)]
#[inherit(Reference)]
pub struct MouseReader {
    mouse: Mouse,
}

#[methods]
impl MouseReader {
    fn new(_owner: &Reference) -> Self {
        MouseReader {
            mouse: Mouse::new(),
        }
    }

    #[export]
    fn get_mouse_position(&self, _owner: &Reference) -> Vector2 {
        let pos = self.mouse.get_position().unwrap();

        return Vector2::new(pos.x as f32, pos.y as f32);
    }
}

fn init(handle: InitHandle) {
    handle.add_class::<MouseReader>();
}

godot_init!(init);
