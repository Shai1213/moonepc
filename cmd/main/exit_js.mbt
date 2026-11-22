///|
#cfg(target="js")
extern "js" fn cli_exit_failure(code : Int) -> Unit =
  #| function(code) {
  #|   if (typeof process !== "undefined" && typeof process.exit === "function") {
  #|     process.exit(code);
  #|   }
  #|   throw new Error("CLI process exit is unavailable");
  #| }
