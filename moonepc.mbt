///|
/// EPC identifier accepted by the SGTIN-96 codec.
pub struct Sgtin {
  filter : Int
  company_prefix : String
  item_reference : String
  serial : String
}

///|
/// Serial Shipping Container Code represented as a tag URI.
pub struct Sscc {
  filter : Int
  company_prefix : String
  serial_reference : String
}

///|
/// Global Location Number represented as an SGLN-96 tag URI.
pub struct Sgln {
  filter : Int
  company_prefix : String
  location_reference : String
  extension : String
}

///|
/// Global Returnable Asset Identifier represented as a GRAI-96 tag URI.
pub struct Grai {
  filter : Int
  company_prefix : String
  asset_type : String
  serial : String
}

///|
/// Global Individual Asset Identifier represented as a GIAI-96 tag URI.
pub struct Giai {
  filter : Int
  company_prefix : String
  asset_reference : String
}

///|
/// Global Document Type Identifier represented as a GDTI-96 tag URI.
pub struct Gdti {
  filter : Int
  company_prefix : String
  document_type : String
  serial : String
}

///|
/// Malformed input, unsupported identifiers, and range errors are distinct.
pub enum EpcError {
  InvalidPrefix
  InvalidField(String)
  InvalidFilter(Int)
  InvalidPartition(Int)
  InvalidBitLength(Int)
  InvalidByteOffset(Int)
  InvalidHex
  InvalidBinary
  UnsupportedScheme(String)
}

///|
/// A recognized 96-bit EPC coding scheme supported by this package.
pub enum Epc96 {
  SGTIN96(Sgtin)
  SSCC96(Sscc)
  SGLN96(Sgln)
  GRAI96(Grai)
  GIAI96(Giai)
  GDTI96(Gdti)
}

///|
/// Stable diagnostic metadata extracted from a validated EPC-96 value.
pub struct Epc96Info {
  scheme : String
  header : Int
  filter : Int
  partition : Int
  company_prefix_digits : Int
  bit_length : Int
}

///|
/// A pure identity URI paired with the tag filter needed to encode EPC memory.
pub struct Epc96Identity {
  uri : String
  filter : Int
}

///|
/// Parse one supported EPC tag URI without requiring the caller to select a scheme.
pub fn parse_epc96_tag_uri(uri : String) -> Result[Epc96, EpcError] {
  if uri.has_prefix("urn:epc:tag:sgtin-96:") {
    return parse_sgtin_tag_uri(uri).map(fn(value) { SGTIN96(value) })
  }
  if uri.has_prefix("urn:epc:tag:sscc-96:") {
    return parse_sscc_tag_uri(uri).map(fn(value) { SSCC96(value) })
  }
  if uri.has_prefix("urn:epc:tag:sgln-96:") {
    return parse_sgln_tag_uri(uri).map(fn(value) { SGLN96(value) })
  }
  if uri.has_prefix("urn:epc:tag:grai-96:") {
    return parse_grai_tag_uri(uri).map(fn(value) { GRAI96(value) })
  }
  if uri.has_prefix("urn:epc:tag:giai-96:") {
    return parse_giai_tag_uri(uri).map(fn(value) { GIAI96(value) })
  }
  if uri.has_prefix("urn:epc:tag:gdti-96:") {
    return parse_gdti_tag_uri(uri).map(fn(value) { GDTI96(value) })
  }
  Err(UnsupportedScheme(uri))
}

///|
/// Parse one pure-identity URI using a caller-selected tag filter.
pub fn parse_epc96_identity_uri(
  uri : String,
  filter : Int,
) -> Result[Epc96, EpcError] {
  if uri.has_prefix("urn:epc:id:sgtin:") {
    return parse_sgtin_identity_uri(uri, filter).map(fn(value) {
      SGTIN96(value)
    })
  }
  if uri.has_prefix("urn:epc:id:sscc:") {
    return parse_sscc_identity_uri(uri, filter).map(fn(value) { SSCC96(value) })
  }
  if uri.has_prefix("urn:epc:id:sgln:") {
    return parse_sgln_identity_uri(uri, filter).map(fn(value) { SGLN96(value) })
  }
  if uri.has_prefix("urn:epc:id:grai:") {
    return parse_grai_identity_uri(uri, filter).map(fn(value) { GRAI96(value) })
  }
  if uri.has_prefix("urn:epc:id:giai:") {
    return parse_giai_identity_uri(uri, filter).map(fn(value) { GIAI96(value) })
  }
  if uri.has_prefix("urn:epc:id:gdti:") {
    return parse_gdti_identity_uri(uri, filter).map(fn(value) { GDTI96(value) })
  }
  Err(UnsupportedScheme(uri))
}

///|
/// Encode any supported 96-bit EPC value as hexadecimal tag memory.
pub fn Epc96::encode_hex(self : Epc96) -> Result[String, EpcError] {
  match self {
    SGTIN96(value) => value.encode_hex()
    SSCC96(value) => value.encode_hex()
    SGLN96(value) => value.encode_hex()
    GRAI96(value) => value.encode_hex()
    GIAI96(value) => value.encode_hex()
    GDTI96(value) => value.encode_hex()
  }
}

///|
/// Encode any supported value as 12 bytes in network bit order.
pub fn Epc96::encode_bytes(self : Epc96) -> Result[Array[Byte], EpcError] {
  let hex = match self.encode_hex() {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bytes : Array[Byte] = []
  for i in 0..<12 {
    let high = match hex_digit(hex[i * 2].to_char().unwrap()) {
      Some(value) => value
      None => return Err(InvalidHex)
    }
    let low = match hex_digit(hex[i * 2 + 1].to_char().unwrap()) {
      Some(value) => value
      None => return Err(InvalidHex)
    }
    bytes.push(((high << 4) | low).to_byte())
  }
  Ok(bytes)
}

///|
/// Encode an EPC value as its 96-bit, most-significant-bit-first representation.
pub fn Epc96::encode_bit_string(self : Epc96) -> Result[String, EpcError] {
  let bytes = match self.encode_bytes() {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(
    bytes.fold(init="", fn(bits, byte) {
      bits + padded(byte.to_uint().to_string(radix=2), 8)
    }),
  )
}

///|
fn binary_bit(bits : String, index : Int) -> Int? {
  match bits[index].to_char() {
    Some('0') => Some(0)
    Some('1') => Some(1)
    _ => None
  }
}

///|
fn binary_byte(bits : String, offset : Int) -> Int? {
  let mut value = 0
  for index in 0..<8 {
    let bit = match binary_bit(bits, offset + index) {
      Some(value) => value
      None => return None
    }
    value = (value << 1) | bit
  }
  Some(value)
}

///|
/// Decode one exact 96-character EPC bit string in network bit order.
pub fn decode_epc96_bit_string(bits : String) -> Result[Epc96, EpcError] {
  if bits.length() != 96 {
    return Err(InvalidBitLength(bits.length()))
  }
  for index in 0..<96 {
    if binary_bit(bits, index) is None {
      return Err(InvalidBinary)
    }
  }
  let bytes = Array::makei(12, fn(index) {
    binary_byte(bits, index * 8).unwrap().to_byte()
  })
  decode_epc96_bytes(bytes)
}

///|
/// Render the canonical EPC tag URI, including its scheme-specific filter.
pub fn Epc96::to_tag_uri(self : Epc96) -> String {
  match self {
    SGTIN96(value) => value.to_tag_uri()
    SSCC96(value) => value.to_tag_uri()
    SGLN96(value) => value.to_tag_uri()
    GRAI96(value) => value.to_tag_uri()
    GIAI96(value) => value.to_tag_uri()
    GDTI96(value) => value.to_tag_uri()
  }
}

///|
/// Render the pure-identity URI, which intentionally omits the tag filter.
pub fn Epc96::to_identity_uri(self : Epc96) -> String {
  match self {
    SGTIN96(value) => value.to_identity_uri()
    SSCC96(value) => value.to_identity_uri()
    SGLN96(value) => value.to_identity_uri()
    GRAI96(value) => value.to_identity_uri()
    GIAI96(value) => value.to_identity_uri()
    GDTI96(value) => value.to_identity_uri()
  }
}

///|
/// Preserve the filter alongside the identity URI for lossless storage.
pub fn Epc96::to_identity(self : Epc96) -> Epc96Identity {
  { uri: self.to_identity_uri(), filter: self.inspect().filter, }
}

///|
/// Read the filter paired with this pure-identity URI.
pub fn Epc96Identity::filter(self : Epc96Identity) -> Int {
  self.filter
}

///|
/// Read the pure-identity URI without converting or normalizing it.
pub fn Epc96Identity::uri(self : Epc96Identity) -> String {
  self.uri
}

///|
/// Restore a typed tag value using the explicitly stored filter.
pub fn Epc96Identity::to_epc96(self : Epc96Identity) -> Result[Epc96, EpcError] {
  parse_epc96_identity_uri(self.uri, self.filter)
}

///|
/// Return the partition and header facts used by a validated value.
pub fn Epc96::inspect(self : Epc96) -> Epc96Info {
  let (scheme, header, filter, prefix) = match self {
    SGTIN96(value) => ("sgtin-96", 48, value.filter, value.company_prefix)
    SSCC96(value) => ("sscc-96", 49, value.filter, value.company_prefix)
    SGLN96(value) => ("sgln-96", 50, value.filter, value.company_prefix)
    GRAI96(value) => ("grai-96", 51, value.filter, value.company_prefix)
    GIAI96(value) => ("giai-96", 52, value.filter, value.company_prefix)
    GDTI96(value) => ("gdti-96", 44, value.filter, value.company_prefix)
  }
  let partition = partition_for_digits(prefix.length()).unwrap()
  {
    scheme,
    header,
    filter,
    partition,
    company_prefix_digits: prefix.length(),
    bit_length: 96,
  }
}

///|
/// Encode a collection independently, preserving each item's result position.
pub fn encode_epc96_batch(
  values : Array[Epc96],
) -> Array[Result[String, EpcError]] {
  values.map(fn(value) { value.encode_hex() })
}

///|
/// Decode a collection independently, preserving each item's result position.
pub fn decode_epc96_batch(
  values : Array[String],
) -> Array[Result[Epc96, EpcError]] {
  values.map(fn(value) { decode_epc96(value) })
}

///|
/// Parse EPC tag URIs independently and retain the result position for each row.
pub fn parse_epc96_tag_uri_batch(
  uris : Array[String],
) -> Array[Result[Epc96, EpcError]] {
  uris.map(fn(uri) { parse_epc96_tag_uri(uri) })
}

///|
/// Parse identity URIs with a matching per-row filter; lengths must agree.
pub fn parse_epc96_identity_uri_batch(
  uris : Array[String],
  filters : Array[Int],
) -> Result[Array[Result[Epc96, EpcError]], EpcError] {
  if uris.length() != filters.length() {
    return Err(InvalidField("identity_filter_count"))
  }
  let results = []
  for index in 0..<uris.length() {
    results.push(parse_epc96_identity_uri(uris[index], filters[index]))
  }
  Ok(results)
}

///|
/// Decode fixed-stride reader records containing a 12-byte EPC at `record_offset`.
/// Each record is validated independently, so one invalid header does not hide later rows.
pub fn decode_epc96_records(
  buffer : Array[Byte],
  start : Int,
  count : Int,
  stride : Int,
  record_offset : Int,
) -> Result[Array[Result[Epc96, EpcError]], EpcError] {
  if start < 0 || start > buffer.length() {
    return Err(InvalidByteOffset(start))
  }
  if count < 0 ||
    stride < 12 ||
    record_offset < 0 ||
    record_offset > stride - 12 {
    return Err(InvalidField("record_layout"))
  }
  let results = []
  let mut record_start = start
  for _ in 0..<count {
    if record_offset > 0x7fffffff - record_start {
      results.push(Err(InvalidField("record_offset_overflow")))
    } else if record_start > buffer.length() ||
      record_offset > buffer.length() - record_start ||
      buffer.length() - record_start - record_offset < 12 {
      results.push(Err(InvalidByteOffset(record_start + record_offset)))
    } else {
      results.push(decode_epc96_bytes_at(buffer, record_start + record_offset))
    }
    if stride > buffer.length() - record_start {
      record_start = buffer.length()
    } else {
      record_start = record_start + stride
    }
  }
  Ok(results)
}

///|
/// Encode values into a fixed-stride reader buffer, filling non-EPC bytes uniformly.
pub fn encode_epc96_records(
  values : Array[Epc96],
  stride : Int,
  record_offset : Int,
  fill : Byte,
) -> Result[Array[Byte], EpcError] {
  if stride < 12 || record_offset < 0 || record_offset > stride - 12 {
    return Err(InvalidField("record_layout"))
  }
  if values.length() > 0x7fffffff / stride {
    return Err(InvalidField("record_buffer_size"))
  }
  let buffer = Array::makei(values.length() * stride, fn(_) { fill })
  for index in 0..<values.length() {
    let result = encode_epc96_bytes_into(
      values[index],
      buffer,
      index * stride + record_offset,
    )
    if result is Err(error) {
      return Err(error)
    }
  }
  Ok(buffer)
}

///|
/// Detect and decode one of the supported 96-bit EPC headers.
pub fn decode_epc96(hex : String) -> Result[Epc96, EpcError] {
  let words = match parse_hex_words(hex) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let header = read_bits(words, 0, 8).to_int()
  match header {
    48 => decode_sgtin96(hex).map(fn(value) { SGTIN96(value) })
    49 => decode_sscc96(hex).map(fn(value) { SSCC96(value) })
    50 => decode_sgln96(hex).map(fn(value) { SGLN96(value) })
    51 => decode_grai96(hex).map(fn(value) { GRAI96(value) })
    52 => decode_giai96(hex).map(fn(value) { GIAI96(value) })
    44 => decode_gdti96(hex).map(fn(value) { GDTI96(value) })
    _ => Err(UnsupportedScheme(header.to_string()))
  }
}

///|
/// Decode exactly 12 network-order bytes by their EPC-96 header.
pub fn decode_epc96_bytes(bytes : Array[Byte]) -> Result[Epc96, EpcError] {
  if bytes.length() != 12 {
    return Err(InvalidBitLength(bytes.length() * 8))
  }
  let hex = bytes
    .map(fn(byte) { padded(byte.to_uint().to_string(radix=16), 2) })
    .fold(init="", fn(result, part) { result + part })
  decode_epc96(hex)
}

///|
/// Decode 12 bytes at an offset in a larger reader or transport buffer.
pub fn decode_epc96_bytes_at(
  buffer : Array[Byte],
  offset : Int,
) -> Result[Epc96, EpcError] {
  if offset < 0 || offset > buffer.length() || buffer.length() - offset < 12 {
    return Err(InvalidByteOffset(offset))
  }
  let epc = Array::makei(12, fn(index) { buffer[offset + index] })
  decode_epc96_bytes(epc)
}

///|
/// Write 12 network-order bytes into an existing reader output buffer.
pub fn encode_epc96_bytes_into(
  value : Epc96,
  buffer : Array[Byte],
  offset : Int,
) -> Result[Unit, EpcError] {
  if offset < 0 || offset > buffer.length() || buffer.length() - offset < 12 {
    return Err(InvalidByteOffset(offset))
  }
  let encoded = match value.encode_bytes() {
    Ok(bytes) => bytes
    Err(error) => return Err(error)
  }
  for index in 0..<12 {
    buffer[offset + index] = encoded[index]
  }
  Ok(())
}

///|
priv struct Partition {
  company_digits : Int
  company_bits : Int
  item_digits : Int
  item_bits : Int
}

///|
let partitions : Array[Partition] = [
  { company_digits: 12, company_bits: 40, item_digits: 1, item_bits: 4, },
  { company_digits: 11, company_bits: 37, item_digits: 2, item_bits: 7, },
  { company_digits: 10, company_bits: 34, item_digits: 3, item_bits: 10, },
  { company_digits: 9, company_bits: 30, item_digits: 4, item_bits: 14, },
  { company_digits: 8, company_bits: 27, item_digits: 5, item_bits: 17, },
  { company_digits: 7, company_bits: 24, item_digits: 6, item_bits: 20, },
  { company_digits: 6, company_bits: 20, item_digits: 7, item_bits: 24, },
]

///|
fn number(text : String) -> Int64? {
  if text.length() == 0 {
    return None
  }
  let mut value : Int64 = 0
  for c in text {
    let digit = c.to_int() - '0'.to_int()
    if digit < 0 || digit > 9 {
      return None
    }
    if value > (9223372036854775807L - digit.to_int64()) / 10L {
      return None
    }
    value = value * 10 + digit.to_int64()
  }
  Some(value)
}

///|
fn number_or_zero(text : String) -> Int64? {
  if text.length() == 0 {
    Some(0L)
  } else {
    number(text)
  }
}

///|
fn partition_for_digits(digits : Int) -> Int? {
  for i in 0..<partitions.length() {
    if partitions[i].company_digits == digits {
      return Some(i)
    }
  }
  None
}

///|
fn padded(text : String, width : Int) -> String {
  let mut result = text
  while result.length() < width {
    result = "0" + result
  }
  result
}

///|
fn power10(exponent : Int) -> Int64 {
  let mut value : Int64 = 1L
  for _ in 0..<exponent {
    value = value * 10L
  }
  value
}

///|
/// Parse strict `urn:epc:tag:sgtin-96:F.C.I.S` syntax and check all fields.
pub fn parse_sgtin_tag_uri(uri : String) -> Result[Sgtin, EpcError] {
  let parts = uri.split(".").map(fn(part) { part.to_owned() }).collect()
  let prefix = "urn:epc:tag:sgtin-96:"
  if parts.length() != 4 || !parts[0].has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  if parts[0].length() != prefix.length() + 1 {
    return Err(InvalidField("filter"))
  }
  let filter = match number(parts[0][prefix.length():].to_owned()) {
    Some(value) => value.to_int()
    None => return Err(InvalidField("filter"))
  }
  if filter > 7 {
    return Err(InvalidFilter(filter))
  }
  let index = match partition_for_digits(parts[1].length()) {
    Some(value) => value
    None => return Err(InvalidPartition(parts[1].length()))
  }
  let row = partitions[index]
  if parts[2].length() != row.item_digits {
    return Err(InvalidField("item_reference"))
  }
  let company = match number(parts[1]) {
    Some(value) if value < 1L << row.company_bits => value
    _ => return Err(InvalidField("company_prefix"))
  }
  let item = match number(parts[2]) {
    Some(value) if value < 1L << row.item_bits &&
      value < power10(row.item_digits) => value
    _ => return Err(InvalidField("item_reference"))
  }
  if parts[3].length() > 1 && parts[3].has_prefix("0") {
    return Err(InvalidField("serial"))
  }
  let serial = match number(parts[3]) {
    Some(value) if value < 1L << 38 => value
    _ => return Err(InvalidField("serial"))
  }
  if company < 0L || item < 0L || serial < 0L || parts[3].length() > 12 {
    return Err(InvalidField("numeric_range"))
  }
  Ok({
    filter,
    company_prefix: parts[1],
    item_reference: parts[2],
    serial: parts[3],
  })
}

///|
/// Return canonical tag URI syntax while preserving the supplied decimal IDs.
pub fn Sgtin::to_tag_uri(self : Sgtin) -> String {
  "urn:epc:tag:sgtin-96:" +
  self.filter.to_string() +
  "." +
  self.company_prefix +
  "." +
  self.item_reference +
  "." +
  self.serial
}

///|
/// Render the canonical EPC pure-identity form, which intentionally omits the
/// tag filter because filters describe physical-tag usage rather than identity.
pub fn Sgtin::to_identity_uri(self : Sgtin) -> String {
  "urn:epc:id:sgtin:" +
  self.company_prefix +
  "." +
  self.item_reference +
  "." +
  self.serial
}

///|
/// Parse `urn:epc:tag:sscc-96:F.CompanyPrefix.SerialReference`.
pub fn parse_sscc_tag_uri(uri : String) -> Result[Sscc, EpcError] {
  let prefix = "urn:epc:tag:sscc-96:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 3 || fields[0].length() != 1 {
    return Err(InvalidField("components"))
  }
  let filter = match number(fields[0]) {
    Some(value) => value.to_int()
    None => return Err(InvalidField("filter"))
  }
  if filter > 7 {
    return Err(InvalidFilter(filter))
  }
  let index = match partition_for_digits(fields[1].length()) {
    Some(value) => value
    None => return Err(InvalidPartition(fields[1].length()))
  }
  let row = partitions[index]
  let expected_serial_digits = 17 - row.company_digits
  if fields[2].length() != expected_serial_digits {
    return Err(InvalidField("serial_reference"))
  }
  let company = match number(fields[1]) {
    Some(value) if value < 1L << row.company_bits => value
    _ => return Err(InvalidField("company_prefix"))
  }
  let serial = match number(fields[2]) {
    Some(value) if value < 1L << (58 - row.company_bits) => value
    _ => return Err(InvalidField("serial_reference"))
  }
  if company < 0L || serial < 0L {
    return Err(InvalidField("numeric_range"))
  }
  Ok({ filter, company_prefix: fields[1], serial_reference: fields[2], })
}

///|
/// Render a normalized SSCC tag URI.
pub fn Sscc::to_tag_uri(self : Sscc) -> String {
  "urn:epc:tag:sscc-96:" +
  self.filter.to_string() +
  "." +
  self.company_prefix +
  "." +
  self.serial_reference
}

///|
/// Render the SSCC pure-identity URI, which has no physical-tag filter.
pub fn Sscc::to_identity_uri(self : Sscc) -> String {
  "urn:epc:id:sscc:" + self.company_prefix + "." + self.serial_reference
}

///|
/// Parse an SSCC pure-identity URI and supply the omitted tag filter explicitly.
pub fn parse_sscc_identity_uri(
  uri : String,
  filter : Int,
) -> Result[Sscc, EpcError] {
  if filter < 0 || filter > 7 {
    return Err(InvalidFilter(filter))
  }
  let prefix = "urn:epc:id:sscc:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 2 {
    return Err(InvalidField("identity_components"))
  }
  parse_sscc_tag_uri(
    "urn:epc:tag:sscc-96:" +
    filter.to_string() +
    "." +
    fields[0] +
    "." +
    fields[1],
  )
}

///|
/// Parse an SGLN pure-identity URI and supply its omitted tag filter.
pub fn parse_sgln_identity_uri(
  uri : String,
  filter : Int,
) -> Result[Sgln, EpcError] {
  if filter < 0 || filter > 7 {
    return Err(InvalidFilter(filter))
  }
  let prefix = "urn:epc:id:sgln:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 3 {
    return Err(InvalidField("identity_components"))
  }
  parse_sgln_tag_uri(
    "urn:epc:tag:sgln-96:" +
    filter.to_string() +
    "." +
    fields[0] +
    "." +
    fields[1] +
    "." +
    fields[2],
  )
}

///|
/// Parse `urn:epc:tag:sgln-96:F.CompanyPrefix.LocationReference.Extension`.
pub fn parse_sgln_tag_uri(uri : String) -> Result[Sgln, EpcError] {
  let prefix = "urn:epc:tag:sgln-96:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 4 || fields[0].length() != 1 {
    return Err(InvalidField("components"))
  }
  let filter = match number(fields[0]) {
    Some(value) if value <= 7L => value.to_int()
    Some(value) => return Err(InvalidFilter(value.to_int()))
    None => return Err(InvalidField("filter"))
  }
  let index = match partition_for_digits(fields[1].length()) {
    Some(value) => value
    None => return Err(InvalidPartition(fields[1].length()))
  }
  let row = partitions[index]
  if fields[2].length() != 12 - row.company_digits {
    return Err(InvalidField("location_reference"))
  }
  match number(fields[1]) {
    Some(value) if value < 1L << row.company_bits => ()
    _ => return Err(InvalidField("company_prefix"))
  }
  match number_or_zero(fields[2]) {
    Some(value) if value < 1L << (41 - row.company_bits) => ()
    _ => return Err(InvalidField("location_reference"))
  }
  match number(fields[3]) {
    Some(value) if value < 1L << 41 => ()
    _ => return Err(InvalidField("extension"))
  }
  if fields[3].length() > 13 ||
    (fields[3].length() > 1 && fields[3].has_prefix("0")) {
    return Err(InvalidField("extension"))
  }
  Ok({
    filter,
    company_prefix: fields[1],
    location_reference: fields[2],
    extension: fields[3],
  })
}

///|
/// Render canonical SGLN-96 tag URI syntax.
pub fn Sgln::to_tag_uri(self : Sgln) -> String {
  "urn:epc:tag:sgln-96:" +
  self.filter.to_string() +
  "." +
  self.company_prefix +
  "." +
  self.location_reference +
  "." +
  self.extension
}

///|
/// Render the SGLN pure-identity URI, omitting the tag filter.
pub fn Sgln::to_identity_uri(self : Sgln) -> String {
  "urn:epc:id:sgln:" +
  self.company_prefix +
  "." +
  self.location_reference +
  "." +
  self.extension
}

///|
/// Encode an SGLN-96 URI as a 96-bit hexadecimal EPC.
pub fn Sgln::encode_hex(self : Sgln) -> Result[String, EpcError] {
  let index = match partition_for_digits(self.company_prefix.length()) {
    Some(value) => value
    None => return Err(InvalidPartition(self.company_prefix.length()))
  }
  let row = partitions[index]
  if self.filter < 0 ||
    self.filter > 7 ||
    self.location_reference.length() != 12 - row.company_digits ||
    self.extension.length() > 13 ||
    (self.extension.length() > 1 && self.extension.has_prefix("0")) {
    return Err(InvalidField("numeric_range"))
  }
  let company = match number(self.company_prefix) {
    Some(value) if value < 1L << row.company_bits => value
    _ => return Err(InvalidField("company_prefix"))
  }
  let location = match number_or_zero(self.location_reference) {
    Some(value) if value < 1L << (41 - row.company_bits) => value
    _ => return Err(InvalidField("location_reference"))
  }
  let extension = match number(self.extension) {
    Some(value) if value < 1L << 41 => value
    _ => return Err(InvalidField("extension"))
  }
  let words = [0, 0, 0]
  write_bits(words, 0, 8, 50L)
  write_bits(words, 8, 3, self.filter.to_int64())
  write_bits(words, 11, 3, index.to_int64())
  write_bits(words, 14, row.company_bits, company)
  write_bits(words, 14 + row.company_bits, 41 - row.company_bits, location)
  write_bits(words, 55, 41, extension)
  Ok(hex_words(words))
}

///|
/// Decode a 96-bit hexadecimal EPC as SGLN-96.
pub fn decode_sgln96(hex : String) -> Result[Sgln, EpcError] {
  let words = match parse_hex_words(hex) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if read_bits(words, 0, 8) != 50L {
    return Err(UnsupportedScheme("header"))
  }
  let index = read_bits(words, 11, 3).to_int()
  if index > 6 {
    return Err(InvalidPartition(index))
  }
  let row = partitions[index]
  let location_digits = 12 - row.company_digits
  let location_value = read_bits(
    words,
    14 + row.company_bits,
    41 - row.company_bits,
  )
  let extension = read_bits(words, 55, 41)
  Ok({
    filter: read_bits(words, 8, 3).to_int(),
    company_prefix: padded(
      read_bits(words, 14, row.company_bits).to_string(),
      row.company_digits,
    ),
    location_reference: if location_digits == 0 {
      ""
    } else {
      padded(location_value.to_string(), location_digits)
    },
    extension: extension.to_string(),
  })
}

///|
/// Parse a numeric `urn:epc:tag:grai-96:F.CompanyPrefix.AssetType.Serial` URI.
pub fn parse_grai_tag_uri(uri : String) -> Result[Grai, EpcError] {
  let prefix = "urn:epc:tag:grai-96:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 4 || fields[0].length() != 1 {
    return Err(InvalidField("components"))
  }
  let filter = match number(fields[0]) {
    Some(value) if value <= 7L => value.to_int()
    Some(value) => return Err(InvalidFilter(value.to_int()))
    None => return Err(InvalidField("filter"))
  }
  let index = match partition_for_digits(fields[1].length()) {
    Some(value) => value
    None => return Err(InvalidPartition(fields[1].length()))
  }
  let row = partitions[index]
  if fields[2].length() != 12 - row.company_digits {
    return Err(InvalidField("asset_type"))
  }
  match number(fields[1]) {
    Some(value) if value < 1L << row.company_bits => ()
    _ => return Err(InvalidField("company_prefix"))
  }
  match number_or_zero(fields[2]) {
    Some(value) if value < 1L << (44 - row.company_bits) => ()
    _ => return Err(InvalidField("asset_type"))
  }
  match number(fields[3]) {
    Some(value) if value < 1L << 38 => ()
    _ => return Err(InvalidField("serial"))
  }
  if fields[3].length() > 12 ||
    (fields[3].length() > 1 && fields[3].has_prefix("0")) {
    return Err(InvalidField("serial"))
  }
  Ok({
    filter,
    company_prefix: fields[1],
    asset_type: fields[2],
    serial: fields[3],
  })
}

///|
/// Parse a GRAI pure-identity URI and supply its omitted tag filter.
pub fn parse_grai_identity_uri(
  uri : String,
  filter : Int,
) -> Result[Grai, EpcError] {
  if filter < 0 || filter > 7 {
    return Err(InvalidFilter(filter))
  }
  let prefix = "urn:epc:id:grai:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 3 {
    return Err(InvalidField("identity_components"))
  }
  parse_grai_tag_uri(
    "urn:epc:tag:grai-96:" +
    filter.to_string() +
    "." +
    fields[0] +
    "." +
    fields[1] +
    "." +
    fields[2],
  )
}

///|
/// Render canonical GRAI-96 tag URI syntax.
pub fn Grai::to_tag_uri(self : Grai) -> String {
  "urn:epc:tag:grai-96:" +
  self.filter.to_string() +
  "." +
  self.company_prefix +
  "." +
  self.asset_type +
  "." +
  self.serial
}

///|
/// Render the GRAI pure-identity URI, omitting the tag filter.
pub fn Grai::to_identity_uri(self : Grai) -> String {
  "urn:epc:id:grai:" +
  self.company_prefix +
  "." +
  self.asset_type +
  "." +
  self.serial
}

///|
/// Encode a GRAI-96 URI as a 96-bit hexadecimal EPC.
pub fn Grai::encode_hex(self : Grai) -> Result[String, EpcError] {
  let index = match partition_for_digits(self.company_prefix.length()) {
    Some(value) => value
    None => return Err(InvalidPartition(self.company_prefix.length()))
  }
  let row = partitions[index]
  if self.filter < 0 ||
    self.filter > 7 ||
    self.asset_type.length() != 12 - row.company_digits ||
    self.serial.length() > 12 ||
    (self.serial.length() > 1 && self.serial.has_prefix("0")) {
    return Err(InvalidField("numeric_range"))
  }
  let company = match number(self.company_prefix) {
    Some(value) if value < 1L << row.company_bits => value
    _ => return Err(InvalidField("company_prefix"))
  }
  let asset_type = match number_or_zero(self.asset_type) {
    Some(value) if value < 1L << (44 - row.company_bits) => value
    _ => return Err(InvalidField("asset_type"))
  }
  let serial = match number(self.serial) {
    Some(value) if value < 1L << 38 => value
    _ => return Err(InvalidField("serial"))
  }
  let words = [0, 0, 0]
  write_bits(words, 0, 8, 51L)
  write_bits(words, 8, 3, self.filter.to_int64())
  write_bits(words, 11, 3, index.to_int64())
  write_bits(words, 14, row.company_bits, company)
  write_bits(words, 14 + row.company_bits, 44 - row.company_bits, asset_type)
  write_bits(words, 58, 38, serial)
  Ok(hex_words(words))
}

///|
/// Decode a 96-bit hexadecimal EPC as GRAI-96.
pub fn decode_grai96(hex : String) -> Result[Grai, EpcError] {
  let words = match parse_hex_words(hex) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if read_bits(words, 0, 8) != 51L {
    return Err(UnsupportedScheme("header"))
  }
  let index = read_bits(words, 11, 3).to_int()
  if index > 6 {
    return Err(InvalidPartition(index))
  }
  let row = partitions[index]
  Ok({
    filter: read_bits(words, 8, 3).to_int(),
    company_prefix: padded(
      read_bits(words, 14, row.company_bits).to_string(),
      row.company_digits,
    ),
    asset_type: if 12 - row.company_digits == 0 {
      ""
    } else {
      padded(
        read_bits(words, 14 + row.company_bits, 44 - row.company_bits).to_string(),
        12 - row.company_digits,
      )
    },
    serial: read_bits(words, 58, 38).to_string(),
  })
}

///|
/// Parse a numeric `urn:epc:tag:giai-96:F.CompanyPrefix.AssetReference` URI.
pub fn parse_giai_tag_uri(uri : String) -> Result[Giai, EpcError] {
  let prefix = "urn:epc:tag:giai-96:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 3 || fields[0].length() != 1 {
    return Err(InvalidField("components"))
  }
  let filter = match number(fields[0]) {
    Some(value) if value <= 7L => value.to_int()
    Some(value) => return Err(InvalidFilter(value.to_int()))
    None => return Err(InvalidField("filter"))
  }
  let index = match partition_for_digits(fields[1].length()) {
    Some(value) => value
    None => return Err(InvalidPartition(fields[1].length()))
  }
  let row = partitions[index]
  if fields[2].length() == 0 ||
    fields[2].length() > 25 - row.company_digits ||
    (fields[2].length() > 1 && fields[2].has_prefix("0")) {
    return Err(InvalidField("asset_reference"))
  }
  match number(fields[1]) {
    Some(value) if value < 1L << row.company_bits => ()
    _ => return Err(InvalidField("company_prefix"))
  }
  match number_or_zero(fields[2]) {
    Some(value) if value < 1L << (82 - row.company_bits) => ()
    _ => return Err(InvalidField("asset_reference"))
  }
  Ok({ filter, company_prefix: fields[1], asset_reference: fields[2], })
}

///|
/// Parse a GIAI pure-identity URI and supply its omitted tag filter.
pub fn parse_giai_identity_uri(
  uri : String,
  filter : Int,
) -> Result[Giai, EpcError] {
  if filter < 0 || filter > 7 {
    return Err(InvalidFilter(filter))
  }
  let prefix = "urn:epc:id:giai:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 2 {
    return Err(InvalidField("identity_components"))
  }
  parse_giai_tag_uri(
    "urn:epc:tag:giai-96:" +
    filter.to_string() +
    "." +
    fields[0] +
    "." +
    fields[1],
  )
}

///|
/// Render canonical GIAI-96 tag URI syntax.
pub fn Giai::to_tag_uri(self : Giai) -> String {
  "urn:epc:tag:giai-96:" +
  self.filter.to_string() +
  "." +
  self.company_prefix +
  "." +
  self.asset_reference
}

///|
/// Render the GIAI pure-identity URI, omitting the tag filter.
pub fn Giai::to_identity_uri(self : Giai) -> String {
  "urn:epc:id:giai:" + self.company_prefix + "." + self.asset_reference
}

///|
/// Encode a GIAI-96 URI as a 96-bit hexadecimal EPC.
pub fn Giai::encode_hex(self : Giai) -> Result[String, EpcError] {
  let index = match partition_for_digits(self.company_prefix.length()) {
    Some(value) => value
    None => return Err(InvalidPartition(self.company_prefix.length()))
  }
  let row = partitions[index]
  if self.filter < 0 ||
    self.filter > 7 ||
    self.asset_reference.length() == 0 ||
    self.asset_reference.length() > 25 - row.company_digits ||
    (self.asset_reference.length() > 1 && self.asset_reference.has_prefix("0")) {
    return Err(InvalidField("numeric_range"))
  }
  let company = match number(self.company_prefix) {
    Some(value) if value < 1L << row.company_bits => value
    _ => return Err(InvalidField("company_prefix"))
  }
  let asset = match number(self.asset_reference) {
    Some(value) if value < 1L << (82 - row.company_bits) => value
    _ => return Err(InvalidField("asset_reference"))
  }
  let words = [0, 0, 0]
  write_bits(words, 0, 8, 52L)
  write_bits(words, 8, 3, self.filter.to_int64())
  write_bits(words, 11, 3, index.to_int64())
  write_bits(words, 14, row.company_bits, company)
  write_bits(words, 14 + row.company_bits, 82 - row.company_bits, asset)
  Ok(hex_words(words))
}

///|
/// Decode a 96-bit hexadecimal EPC as GIAI-96.
pub fn decode_giai96(hex : String) -> Result[Giai, EpcError] {
  let words = match parse_hex_words(hex) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if read_bits(words, 0, 8) != 52L {
    return Err(UnsupportedScheme("header"))
  }
  let index = read_bits(words, 11, 3).to_int()
  if index > 6 {
    return Err(InvalidPartition(index))
  }
  let row = partitions[index]
  Ok({
    filter: read_bits(words, 8, 3).to_int(),
    company_prefix: padded(
      read_bits(words, 14, row.company_bits).to_string(),
      row.company_digits,
    ),
    asset_reference: read_bits(
      words,
      14 + row.company_bits,
      82 - row.company_bits,
    ).to_string(),
  })
}

///|
/// Parse a numeric `urn:epc:tag:gdti-96:F.CompanyPrefix.DocumentType.Serial` URI.
pub fn parse_gdti_tag_uri(uri : String) -> Result[Gdti, EpcError] {
  let prefix = "urn:epc:tag:gdti-96:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 4 || fields[0].length() != 1 {
    return Err(InvalidField("components"))
  }
  let filter = match number(fields[0]) {
    Some(value) if value <= 7L => value.to_int()
    Some(value) => return Err(InvalidFilter(value.to_int()))
    None => return Err(InvalidField("filter"))
  }
  let index = match partition_for_digits(fields[1].length()) {
    Some(value) => value
    None => return Err(InvalidPartition(fields[1].length()))
  }
  let row = partitions[index]
  if fields[2].length() != 12 - row.company_digits {
    return Err(InvalidField("document_type"))
  }
  match number(fields[1]) {
    Some(value) if value < 1L << row.company_bits => ()
    _ => return Err(InvalidField("company_prefix"))
  }
  match number_or_zero(fields[2]) {
    Some(value) if value < 1L << (41 - row.company_bits) => ()
    _ => return Err(InvalidField("document_type"))
  }
  match number(fields[3]) {
    Some(value) if value < 1L << 41 => ()
    _ => return Err(InvalidField("serial"))
  }
  if fields[3].length() > 13 ||
    (fields[3].length() > 1 && fields[3].has_prefix("0")) {
    return Err(InvalidField("serial"))
  }
  Ok({
    filter,
    company_prefix: fields[1],
    document_type: fields[2],
    serial: fields[3],
  })
}

///|
/// Parse a GDTI pure-identity URI and supply its omitted tag filter.
pub fn parse_gdti_identity_uri(
  uri : String,
  filter : Int,
) -> Result[Gdti, EpcError] {
  if filter < 0 || filter > 7 {
    return Err(InvalidFilter(filter))
  }
  let prefix = "urn:epc:id:gdti:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let fields = uri[prefix.length():]
    .to_owned()
    .split(".")
    .map(fn(part) { part.to_owned() })
    .collect()
  if fields.length() != 3 {
    return Err(InvalidField("identity_components"))
  }
  parse_gdti_tag_uri(
    "urn:epc:tag:gdti-96:" +
    filter.to_string() +
    "." +
    fields[0] +
    "." +
    fields[1] +
    "." +
    fields[2],
  )
}

///|
/// Render canonical GDTI-96 tag URI syntax.
pub fn Gdti::to_tag_uri(self : Gdti) -> String {
  "urn:epc:tag:gdti-96:" +
  self.filter.to_string() +
  "." +
  self.company_prefix +
  "." +
  self.document_type +
  "." +
  self.serial
}

///|
/// Render the GDTI pure-identity URI, omitting the tag filter.
pub fn Gdti::to_identity_uri(self : Gdti) -> String {
  "urn:epc:id:gdti:" +
  self.company_prefix +
  "." +
  self.document_type +
  "." +
  self.serial
}

///|
/// Encode a GDTI-96 URI as a 96-bit hexadecimal EPC.
pub fn Gdti::encode_hex(self : Gdti) -> Result[String, EpcError] {
  let index = match partition_for_digits(self.company_prefix.length()) {
    Some(value) => value
    None => return Err(InvalidPartition(self.company_prefix.length()))
  }
  let row = partitions[index]
  if self.filter < 0 ||
    self.filter > 7 ||
    self.document_type.length() != 12 - row.company_digits ||
    self.serial.length() > 13 ||
    (self.serial.length() > 1 && self.serial.has_prefix("0")) {
    return Err(InvalidField("numeric_range"))
  }
  let company = match number(self.company_prefix) {
    Some(value) if value < 1L << row.company_bits => value
    _ => return Err(InvalidField("company_prefix"))
  }
  let document_type = match number_or_zero(self.document_type) {
    Some(value) if value < 1L << (41 - row.company_bits) => value
    _ => return Err(InvalidField("document_type"))
  }
  let serial = match number(self.serial) {
    Some(value) if value < 1L << 41 => value
    _ => return Err(InvalidField("serial"))
  }
  let words = [0, 0, 0]
  write_bits(words, 0, 8, 44L)
  write_bits(words, 8, 3, self.filter.to_int64())
  write_bits(words, 11, 3, index.to_int64())
  write_bits(words, 14, row.company_bits, company)
  write_bits(words, 14 + row.company_bits, 41 - row.company_bits, document_type)
  write_bits(words, 55, 41, serial)
  Ok(hex_words(words))
}

///|
/// Decode a 96-bit hexadecimal EPC as GDTI-96.
pub fn decode_gdti96(hex : String) -> Result[Gdti, EpcError] {
  let words = match parse_hex_words(hex) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if read_bits(words, 0, 8) != 44L {
    return Err(UnsupportedScheme("header"))
  }
  let index = read_bits(words, 11, 3).to_int()
  if index > 6 {
    return Err(InvalidPartition(index))
  }
  let row = partitions[index]
  Ok({
    filter: read_bits(words, 8, 3).to_int(),
    company_prefix: padded(
      read_bits(words, 14, row.company_bits).to_string(),
      row.company_digits,
    ),
    document_type: if 12 - row.company_digits == 0 {
      ""
    } else {
      padded(
        read_bits(words, 14 + row.company_bits, 41 - row.company_bits).to_string(),
        12 - row.company_digits,
      )
    },
    serial: read_bits(words, 55, 41).to_string(),
  })
}

///|
/// Encode an SSCC-96 tag URI to 96-bit EPC hexadecimal.
pub fn Sscc::encode_hex(self : Sscc) -> Result[String, EpcError] {
  let index = match partition_for_digits(self.company_prefix.length()) {
    Some(value) => value
    None => return Err(InvalidPartition(self.company_prefix.length()))
  }
  let row = partitions[index]
  if self.filter < 0 ||
    self.filter > 7 ||
    self.serial_reference.length() != 17 - row.company_digits {
    return Err(InvalidField("numeric_range"))
  }
  let company = match number(self.company_prefix) {
    Some(value) if value < 1L << row.company_bits => value
    _ => return Err(InvalidField("company_prefix"))
  }
  let serial = match number(self.serial_reference) {
    Some(value) if value < 1L << (58 - row.company_bits) => value
    _ => return Err(InvalidField("serial_reference"))
  }
  let words = [0, 0, 0]
  write_bits(words, 0, 8, 49L)
  write_bits(words, 8, 3, self.filter.to_int64())
  write_bits(words, 11, 3, index.to_int64())
  write_bits(words, 14, row.company_bits, company)
  write_bits(words, 14 + row.company_bits, 58 - row.company_bits, serial)
  Ok(hex_words(words))
}

///|
/// Decode a 96-bit EPC hex value as SSCC-96.
pub fn decode_sscc96(hex : String) -> Result[Sscc, EpcError] {
  let words = match parse_hex_words(hex) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if read_bits(words, 0, 8) != 49L {
    return Err(UnsupportedScheme("header"))
  }
  let filter = read_bits(words, 8, 3).to_int()
  let index = read_bits(words, 11, 3).to_int()
  if index > 6 {
    return Err(InvalidPartition(index))
  }
  let row = partitions[index]
  Ok({
    filter,
    company_prefix: padded(
      read_bits(words, 14, row.company_bits).to_string(),
      row.company_digits,
    ),
    serial_reference: padded(
      read_bits(words, 14 + row.company_bits, 58 - row.company_bits).to_string(),
      17 - row.company_digits,
    ),
  })
}

///|
/// Parse an SGTIN pure-identity URI with an explicit physical-tag filter.
pub fn parse_sgtin_identity_uri(
  uri : String,
  filter : Int,
) -> Result[Sgtin, EpcError] {
  if filter < 0 || filter > 7 {
    return Err(InvalidFilter(filter))
  }
  let prefix = "urn:epc:id:sgtin:"
  if !uri.has_prefix(prefix) {
    return Err(InvalidPrefix)
  }
  let body = uri[prefix.length():].to_owned()
  let parts = body.split(".").map(fn(part) { part.to_owned() }).collect()
  if parts.length() != 3 {
    return Err(InvalidField("identity_components"))
  }
  parse_sgtin_tag_uri(
    "urn:epc:tag:sgtin-96:" +
    filter.to_string() +
    "." +
    parts[0] +
    "." +
    parts[1] +
    "." +
    parts[2],
  )
}

///|
fn write_bits(
  words : Array[Int],
  offset : Int,
  width : Int,
  value : Int64,
) -> Unit {
  for n in 0..<width {
    let target = offset + n
    let source_shift = width - n - 1
    if ((value >> source_shift) & 1L) == 1L {
      let wi = target / 32
      words[wi] = words[wi] | (1 << (31 - target % 32))
    }
  }
}

///|
fn read_bits(words : Array[Int], offset : Int, width : Int) -> Int64 {
  let mut value : Int64 = 0L
  for n in 0..<width {
    let target = offset + n
    let bit = (words[target / 32] >> (31 - target % 32)) & 1
    value = (value << 1) | bit.to_int64()
  }
  value
}

///|
fn hex_digit(c : Char) -> Int? {
  let n = c.to_int()
  if n >= 48 && n <= 57 {
    Some(n - 48)
  } else if n >= 65 && n <= 70 {
    Some(n - 55)
  } else if n >= 97 && n <= 102 {
    Some(n - 87)
  } else {
    None
  }
}

///|
fn parse_hex_words(hex : String) -> Result[Array[Int], EpcError] {
  if hex.length() != 24 {
    return Err(InvalidBitLength(hex.length() * 4))
  }
  let words = [0, 0, 0]
  for i in 0..<24 {
    let character = match hex[i].to_char() {
      Some(value) => value
      None => return Err(InvalidHex)
    }
    let digit = match hex_digit(character) {
      Some(value) => value
      None => return Err(InvalidHex)
    }
    let wi = i / 8
    words[wi] = (words[wi] << 4) | digit
  }
  Ok(words)
}

///|
fn hex_words(words : Array[Int]) -> String {
  words
  .map(fn(word) { padded(word.reinterpret_as_uint().to_string(radix=16), 8) })
  .fold(init="", fn(a, b) { a + b })
}

///|
/// Encode an SGTIN-96 URI value into three 32-bit big-endian words as hex.
pub fn Sgtin::encode_hex(self : Sgtin) -> Result[String, EpcError] {
  let index = match partition_for_digits(self.company_prefix.length()) {
    Some(value) => value
    None => return Err(InvalidPartition(self.company_prefix.length()))
  }
  let row = partitions[index]
  let company = match number(self.company_prefix) {
    Some(v) => v
    None => return Err(InvalidField("company_prefix"))
  }
  let item = match number(self.item_reference) {
    Some(v) => v
    None => return Err(InvalidField("item_reference"))
  }
  if self.serial.length() > 1 && self.serial.has_prefix("0") {
    return Err(InvalidField("serial"))
  }
  let serial = match number(self.serial) {
    Some(v) => v
    None => return Err(InvalidField("serial"))
  }
  if self.filter < 0 ||
    self.filter > 7 ||
    company >= 1L << row.company_bits ||
    item >= 1L << row.item_bits ||
    item >= power10(row.item_digits) ||
    serial >= 1L << 38 ||
    self.item_reference.length() != row.item_digits ||
    self.serial.length() > 12 {
    return Err(InvalidField("numeric_range"))
  }
  let words = [0, 0, 0]
  write_bits(words, 0, 8, 48L)
  write_bits(words, 8, 3, self.filter.to_int64())
  write_bits(words, 11, 3, index.to_int64())
  write_bits(words, 14, row.company_bits, company)
  write_bits(words, 14 + row.company_bits, row.item_bits, item)
  write_bits(words, 58, 38, serial)
  Ok(hex_words(words))
}

///|
/// Decode a 96-bit hex value. Invalid headers and partition codes are rejected.
pub fn decode_sgtin96(hex : String) -> Result[Sgtin, EpcError] {
  let words = match parse_hex_words(hex) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if read_bits(words, 0, 8) != 48L {
    return Err(UnsupportedScheme("header"))
  }
  let filter = read_bits(words, 8, 3).to_int()
  let index = read_bits(words, 11, 3).to_int()
  if index > 6 {
    return Err(InvalidPartition(index))
  }
  let row = partitions[index]
  if read_bits(words, 14, row.company_bits) >= power10(row.company_digits) {
    return Err(InvalidField("company_prefix"))
  }
  if read_bits(words, 14 + row.company_bits, 44 - row.company_bits) >=
    power10(13 - row.company_digits) {
    return Err(InvalidField("item_reference"))
  }
  let company = read_bits(words, 14, row.company_bits).to_string()
  let item = read_bits(words, 14 + row.company_bits, row.item_bits).to_string()
  let serial = read_bits(words, 58, 38).to_string()
  Ok({
    filter,
    company_prefix: padded(company, row.company_digits),
    item_reference: padded(item, row.item_digits),
    serial,
  })
}
