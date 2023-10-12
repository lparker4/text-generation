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
