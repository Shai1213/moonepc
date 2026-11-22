///|
#cfg(target="wasm")
fn cli_exit_failure(code : Int) -> Unit = "wasi_snapshot_preview1" "proc_exit"

///|
#cfg(target="wasm-gc")
fn cli_exit_failure(code : Int) -> Unit = "__moonbit_sys_unstable" "exit"
