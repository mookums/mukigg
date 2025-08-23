use truffle::Simulator;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {}

#[wasm_bindgen]
pub fn create_simulator() -> *mut Simulator {
    let simulator = Simulator::default();
    Box::into_raw(Box::new(simulator))
}

#[wasm_bindgen]
/// # Safety
/// You know how WASM is.
pub unsafe fn execute_sql(sim: *mut Simulator, data: &str) -> Result<JsValue, JsValue> {
    let sim = unsafe { &mut *sim };
    sim.execute(data)
        .map(|r| serde_wasm_bindgen::to_value(&r).unwrap())
        .map_err(|e| JsValue::from_str(&e.to_string()))
}

#[wasm_bindgen]
/// # Safety
/// You know how WASM is.
pub unsafe fn free_simulator(sim: *mut Simulator) {
    unsafe {
        std::mem::drop(Box::from_raw(sim));
    }
}

#[wasm_bindgen]
/// # Safety
/// You know how WASM is.
pub unsafe fn get_tables(sim: *mut Simulator) -> Vec<String> {
    let sim = unsafe { &mut *sim };
    sim.get_tables().iter().map(|t| t.0.clone()).collect()
}

#[wasm_bindgen]
/// # Safety
/// You know how WASM is.
pub unsafe fn get_table(
    sim: *mut Simulator,
    name: &str,
) -> Result<JsValue, serde_wasm_bindgen::Error> {
    let sim = unsafe { &mut *sim };
    serde_wasm_bindgen::to_value(&sim.get_table(name).cloned())
}

#[wasm_bindgen]
/// # Safety
/// You know how WASM is.
pub unsafe fn get_constraints(
    sim: *mut Simulator,
    name: &str,
) -> Result<JsValue, serde_wasm_bindgen::Error> {
    let sim = unsafe { &mut *sim };
    serde_wasm_bindgen::to_value(&sim.get_table(name).map(|t| t.constraints.clone()))
}
