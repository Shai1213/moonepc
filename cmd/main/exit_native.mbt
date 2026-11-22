///|
#cfg(any(target="native", target="llvm"))
extern "c" fn cli_exit_failure(code : Int) -> Unit = "exit"
