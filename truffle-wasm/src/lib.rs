use truffle_sim::{GenericDialect, Simulator};
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {}

#[wasm_bindgen]
pub fn create_simulator() -> *mut Simulator {
    let simulator = Simulator::new(Box::new(GenericDialect {}));
    Box::into_raw(Box::new(simulator))
}

#[wasm_bindgen]
/// # Safety
/// You know how WASM is.
pub unsafe fn execute_sql(sim: *mut Simulator, data: &str) -> Result<(), JsValue> {
    let sim = unsafe { &mut *sim };
    sim.execute(data)
        .map_err(|e| JsValue::from_str(&format!("{e}")))
}

#[wasm_bindgen]
/// # Safety
/// You know how WASM is.
pub unsafe fn free_simulator(sim: *mut Simulator) {
    unsafe {
        std::mem::drop(Box::from_raw(sim));
    }
}
