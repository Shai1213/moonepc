///|
fn usage() -> Unit {
  println("MoonEPC 0.1.0")
  println("Usage:")
  println("  moonepc --help")
  println("  moonepc --version")
  println("  moonepc sgtin-encode <tag-uri>")
  println("  moonepc sgtin-decode <96-bit-hex>")
  println("  moonepc sscc-encode <tag-uri>")
  println("  moonepc sscc-decode <96-bit-hex>")
  println("  moonepc sgln-encode <tag-uri>")
  println("  moonepc sgln-decode <96-bit-hex>")
  println("  moonepc grai-encode <tag-uri>")
  println("  moonepc grai-decode <96-bit-hex>")
  println("  moonepc giai-encode <tag-uri>")
  println("  moonepc giai-decode <96-bit-hex>")
  println("  moonepc gdti-encode <tag-uri>")
  println("  moonepc gdti-decode <96-bit-hex>")
  println("  moonepc encode <supported-tag-uri>")
  println("  moonepc decode <supported-96-bit-hex>")
  println("  moonepc identity-encode <filter> <supported-identity-uri>")
  println("  moonepc bits-encode <supported-tag-uri>")
  println("  moonepc bits-decode <96-bit-binary-string>")
  println("  moonepc inspect <supported-96-bit-hex>")
}

///|
fn parse_filter(text : String) -> Int? {
  match text {
    "0" => Some(0)
    "1" => Some(1)
    "2" => Some(2)
    "3" => Some(3)
    "4" => Some(4)
    "5" => Some(5)
    "6" => Some(6)
    "7" => Some(7)
    _ => None
  }
}

///|
fn error_text(error : @moonepc.EpcError) -> String {
  match error {
    @moonepc.InvalidPrefix => "invalid EPC URI prefix"
    @moonepc.InvalidField(field) => "invalid field: " + field
    @moonepc.InvalidFilter(value) =>
      "filter is outside 0..7: " + value.to_string()
    @moonepc.InvalidPartition(value) =>
      "unsupported partition: " + value.to_string()
    @moonepc.InvalidBitLength(value) =>
      "expected 96 bits, received " + value.to_string()
    @moonepc.InvalidByteOffset(value) =>
      "EPC byte range is outside the buffer at offset " + value.to_string()
    @moonepc.InvalidHex => "input contains a non-hexadecimal character"
    @moonepc.InvalidBinary => "input contains a non-binary character"
    @moonepc.UnsupportedScheme(value) => "unsupported EPC header: " + value
  }
}

///|
fn fail(message : String) -> Unit {
  println("error: " + message)
  cli_exit_failure(1)
  panic()
}

///|
fn main {
  let args = @env.args()
  if args.length() == 2 && (args[1] == "--help" || args[1] == "-h") {
    usage()
    return
  }
  if args.length() == 2 && (args[1] == "--version" || args[1] == "-V") {
    println("0.1.0")
    return
  }
  if args.length() < 3 {
    usage()
    fail("expected a command and input")
  }
  if args.length() != 3 && !(args.length() == 4 && args[1] == "identity-encode") {
    usage()
    fail("unexpected number of arguments")
  }
  let command = args[1]
  let input = if command == "identity-encode" { args[3] } else { args[2] }
  match command {
    "identity-encode" =>
      match parse_filter(args[2]) {
        Some(filter) =>
          match @moonepc.parse_epc96_identity_uri(input, filter) {
            Ok(value) =>
              match value.encode_hex() {
                Ok(hex) => println(hex)
                Err(error) => fail(error_text(error))
              }
            Err(error) => fail(error_text(error))
          }
        None => fail("invalid filter; expected 0..7")
      }
    "bits-encode" =>
      match @moonepc.parse_epc96_tag_uri(input) {
        Ok(value) =>
          match value.encode_bit_string() {
            Ok(bits) => println(bits)
            Err(error) => fail(error_text(error))
          }
        Err(error) => fail(error_text(error))
      }
    "bits-decode" =>
      match @moonepc.decode_epc96_bit_string(input) {
        Ok(value) => println(value.to_tag_uri())
        Err(error) => fail(error_text(error))
      }
    "encode" =>
      match @moonepc.parse_epc96_tag_uri(input) {
        Ok(value) =>
          match value.encode_hex() {
            Ok(hex) => println(hex)
            Err(error) => fail(error_text(error))
          }
        Err(error) => fail(error_text(error))
      }
    "decode" =>
      match @moonepc.decode_epc96(input) {
        Ok(value) => println(value.to_tag_uri())
        Err(error) => fail(error_text(error))
      }
    "inspect" =>
      match @moonepc.decode_epc96(input) {
        Ok(value) => {
          let info = value.inspect()
          println("scheme=" + info.scheme)
          println("header=" + info.header.to_string())
          println("filter=" + info.filter.to_string())
          println("partition=" + info.partition.to_string())
          println(
            "company_prefix_digits=" + info.company_prefix_digits.to_string(),
          )
          println("bit_length=" + info.bit_length.to_string())
          println("tag_uri=" + value.to_tag_uri())
        }
        Err(error) => fail(error_text(error))
      }
    "sgtin-encode" =>
      match @moonepc.parse_sgtin_tag_uri(input) {
        Ok(value) =>
          match value.encode_hex() {
            Ok(hex) => println(hex)
            Err(error) => fail(error_text(error))
          }
        Err(error) => fail(error_text(error))
      }
    "sgtin-decode" =>
      match @moonepc.decode_sgtin96(input) {
        Ok(value) => println(value.to_tag_uri())
        Err(error) => fail(error_text(error))
      }
    "sscc-encode" =>
      match @moonepc.parse_sscc_tag_uri(input) {
        Ok(value) =>
          match value.encode_hex() {
            Ok(hex) => println(hex)
            Err(error) => fail(error_text(error))
          }
        Err(error) => fail(error_text(error))
      }
    "sscc-decode" =>
      match @moonepc.decode_sscc96(input) {
        Ok(value) => println(value.to_tag_uri())
        Err(error) => fail(error_text(error))
      }
    "sgln-encode" =>
      match @moonepc.parse_sgln_tag_uri(input) {
        Ok(value) =>
          match value.encode_hex() {
            Ok(hex) => println(hex)
            Err(error) => fail(error_text(error))
          }
        Err(error) => fail(error_text(error))
      }
    "sgln-decode" =>
      match @moonepc.decode_sgln96(input) {
        Ok(value) => println(value.to_tag_uri())
        Err(error) => fail(error_text(error))
      }
    "grai-encode" =>
      match @moonepc.parse_grai_tag_uri(input) {
        Ok(value) =>
          match value.encode_hex() {
            Ok(hex) => println(hex)
            Err(error) => fail(error_text(error))
          }
        Err(error) => fail(error_text(error))
      }
    "grai-decode" =>
      match @moonepc.decode_grai96(input) {
        Ok(value) => println(value.to_tag_uri())
        Err(error) => fail(error_text(error))
      }
    "giai-encode" =>
      match @moonepc.parse_giai_tag_uri(input) {
        Ok(value) =>
          match value.encode_hex() {
            Ok(hex) => println(hex)
            Err(error) => fail(error_text(error))
          }
        Err(error) => fail(error_text(error))
      }
    "giai-decode" =>
      match @moonepc.decode_giai96(input) {
        Ok(value) => println(value.to_tag_uri())
        Err(error) => fail(error_text(error))
      }
    "gdti-encode" =>
      match @moonepc.parse_gdti_tag_uri(input) {
        Ok(value) =>
          match value.encode_hex() {
            Ok(hex) => println(hex)
            Err(error) => fail(error_text(error))
          }
        Err(error) => fail(error_text(error))
      }
    "gdti-decode" =>
      match @moonepc.decode_gdti96(input) {
        Ok(value) => println(value.to_tag_uri())
        Err(error) => fail(error_text(error))
      }
    _ => {
      usage()
      fail("unknown command: " + command)
    }
  }
}
