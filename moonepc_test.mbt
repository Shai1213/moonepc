///|
test "sgtin known vector" {
  let value = @moonepc.parse_sgtin_tag_uri(
    "urn:epc:tag:sgtin-96:3.0614141.812345.6789",
  ).unwrap()
  assert_eq(value.encode_hex().unwrap(), "3074257bf7194e4000001a85")
  assert_eq(
    @moonepc.decode_sgtin96("3074257bf7194e4000001a85").unwrap().to_tag_uri(),
    value.to_tag_uri(),
  )
}

///|
test "official TDT EPC96 vectors match all supported schemes" {
  let cases = [
    ("urn:epc:tag:sgtin-96:3.0614141.812345.6789", "3074257bf7194e4000001a85"),
    ("urn:epc:tag:sscc-96:0.123456789012.12345", "310072fa6468503039000000"),
    ("urn:epc:tag:sgln-96:3.0614141.00123.456", "3274257bf400f600000001c8"),
    ("urn:epc:tag:grai-96:5.0614141.81234.123456", "33b4257bf44f54800001e240"),
    ("urn:epc:tag:giai-96:6.999999.123456789", "34dbd08fc0000000075bcd15"),
    ("urn:epc:tag:gdti-96:3.0614141.12345.6789", "2c74257bf460720000001a85"),
  ]
  for (uri, expected_hex) in cases {
    let value = @moonepc.parse_epc96_tag_uri(uri).unwrap()
    assert_eq(value.encode_hex().unwrap(), expected_hex)
    assert_eq(@moonepc.decode_epc96(expected_hex).unwrap().to_tag_uri(), uri)
  }
}

///|
test "generic byte codec preserves network order and all supported schemes" {
  let uris = [
    "urn:epc:tag:sgtin-96:3.0614141.812345.6789", "urn:epc:tag:sscc-96:0.123456789012.12345",
    "urn:epc:tag:sgln-96:3.0614141.00123.456", "urn:epc:tag:grai-96:5.0614141.81234.123456",
    "urn:epc:tag:giai-96:6.999999.123456789", "urn:epc:tag:gdti-96:3.0614141.12345.6789",
  ]
  let headers = [48, 49, 50, 51, 52, 44]
  for i in 0..<uris.length() {
    let uri = uris[i]
    let value = @moonepc.parse_epc96_tag_uri(uri).unwrap()
    let bytes = value.encode_bytes().unwrap()
    assert_eq(bytes.length(), 12)
    assert_eq(bytes[0].to_int(), headers[i])
    assert_eq(@moonepc.decode_epc96_bytes(bytes).unwrap().to_tag_uri(), uri)
  }
  assert_true(@moonepc.decode_epc96_bytes([]) is Err(_))
}

///|
test "inspection exposes the encoded partition and batch conversion is positional" {
  let value = @moonepc.parse_epc96_tag_uri(
    "urn:epc:tag:sgtin-96:3.0614141.812345.6789",
  ).unwrap()
  let info = value.inspect()
  assert_eq(info.scheme, "sgtin-96")
  assert_eq(info.header, 48)
  assert_eq(info.filter, 3)
  assert_eq(info.partition, 5)
  assert_eq(info.company_prefix_digits, 7)
  assert_eq(info.bit_length, 96)
  let encoded = @moonepc.encode_epc96_batch([value, value])
  assert_eq(encoded.length(), 2)
  assert_eq(encoded[0].unwrap(), "3074257bf7194e4000001a85")
  let decoded = @moonepc.decode_epc96_batch([
    "3074257bf7194e4000001a85", "not-hex", "2c74257bf460720000001a85",
  ])
  assert_eq(decoded.length(), 3)
  assert_true(decoded[0] is Ok(_))
  assert_true(decoded[1] is Err(_))
  assert_eq(
    decoded[2].unwrap().to_tag_uri(),
    "urn:epc:tag:gdti-96:3.0614141.12345.6789",
  )
}

///|
test "byte codecs honor offsets and preserve surrounding buffer data" {
  let value = @moonepc.parse_epc96_tag_uri(
    "urn:epc:tag:gdti-96:3.0614141.12345.6789",
  ).unwrap()
  let buffer = Array::makei(16, fn(index) { (index + 160).to_byte() })
  let prefix = buffer[0]
  let suffix = buffer[15]
  @moonepc.encode_epc96_bytes_into(value, buffer, 2).unwrap()
  assert_eq(buffer[0], prefix)
  assert_eq(buffer[15], suffix)
  assert_eq(
    @moonepc.decode_epc96_bytes_at(buffer, 2).unwrap().to_tag_uri(),
    value.to_tag_uri(),
  )
  assert_true(@moonepc.decode_epc96_bytes_at(buffer, 5) is Err(_))
  assert_true(@moonepc.decode_epc96_bytes_at(buffer, -1) is Err(_))
  assert_true(@moonepc.encode_epc96_bytes_into(value, buffer, 5) is Err(_))
}

///|
test "binary string codec roundtrips all supported headers" {
  let uris = [
    "urn:epc:tag:sgtin-96:3.0614141.812345.6789", "urn:epc:tag:sscc-96:0.123456789012.12345",
    "urn:epc:tag:sgln-96:3.0614141.00123.456", "urn:epc:tag:grai-96:5.0614141.81234.123456",
    "urn:epc:tag:giai-96:6.999999.123456789", "urn:epc:tag:gdti-96:3.0614141.12345.6789",
  ]
  for uri in uris {
    let value = @moonepc.parse_epc96_tag_uri(uri).unwrap()
    let bits = value.encode_bit_string().unwrap()
    assert_eq(bits.length(), 96)
    assert_eq(@moonepc.decode_epc96_bit_string(bits).unwrap().to_tag_uri(), uri)
  }
  assert_true(@moonepc.decode_epc96_bit_string("0101") is Err(_))
  assert_true(
    @moonepc.decode_epc96_bit_string("2" + String::make(95, '0')) is Err(_),
  )
}

///|
test "fixed-stride reader records preserve padding and isolate row errors" {
  let first = @moonepc.parse_epc96_tag_uri(
    "urn:epc:tag:sgtin-96:3.0614141.812345.6789",
  ).unwrap()
  let second = @moonepc.parse_epc96_tag_uri(
    "urn:epc:tag:gdti-96:3.0614141.12345.6789",
  ).unwrap()
  let packed = @moonepc.encode_epc96_records(
    [first, second],
    16,
    2,
    (165).to_byte(),
  ).unwrap()
  assert_eq(packed.length(), 32)
  assert_eq(packed[0].to_uint(), 165U)
  assert_eq(packed[1].to_uint(), 165U)
  assert_eq(packed[14].to_uint(), 165U)
  let decoded = @moonepc.decode_epc96_records(packed, 0, 2, 16, 2).unwrap()
  assert_eq(decoded[0].unwrap().to_tag_uri(), first.to_tag_uri())
  assert_eq(decoded[1].unwrap().to_tag_uri(), second.to_tag_uri())
  let truncated = @moonepc.decode_epc96_records(packed, 0, 3, 16, 2).unwrap()
  assert_true(truncated[0] is Ok(_))
  assert_true(truncated[1] is Ok(_))
  assert_true(truncated[2] is Err(_))
  assert_true(
    @moonepc.encode_epc96_records([first], 11, 0, (0).to_byte()) is Err(_),
  )
}

///|
test "fixed-stride reader record offset overflow is reported without wrapping" {
  let result = @moonepc.decode_epc96_records(
    Array::makei(13, fn(_) { (0).to_byte() }),
    13,
    1,
    0x7fffffff,
    0x7ffffff3,
  ).unwrap()
  assert_true(result[0] is Err(@moonepc.InvalidField("record_offset_overflow")))
}

///|
test "batch identity parser checks row alignment before processing" {
  let parsed = @moonepc.parse_epc96_identity_uri_batch(
    ["urn:epc:id:sgtin:0614141.812345.6789", "invalid"],
    [3, 0],
  ).unwrap()
  assert_eq(parsed.length(), 2)
  assert_eq(parsed[0].unwrap().inspect().filter, 3)
  assert_true(parsed[1] is Err(_))
  assert_true(
    @moonepc.parse_epc96_identity_uri_batch(
      ["urn:epc:id:sgtin:0614141.812345.6789"],
      [],
    )
    is Err(_),
  )
}

///|
test "identity value preserves a tag filter across storage roundtrip" {
  let tag = @moonepc.parse_epc96_tag_uri(
    "urn:epc:tag:sgln-96:6.0614141.00123.456",
  ).unwrap()
  let identity = tag.to_identity()
  assert_eq(identity.uri(), "urn:epc:id:sgln:0614141.00123.456")
  assert_eq(identity.filter(), 6)
  assert_eq(identity.to_epc96().unwrap().to_tag_uri(), tag.to_tag_uri())
}

///|
test "sgtin identity roundtrip keeps filter explicit" {
  let tag = @moonepc.parse_sgtin_tag_uri(
    "urn:epc:tag:sgtin-96:5.0614141.812345.6789",
  ).unwrap()
  assert_eq(tag.to_identity_uri(), "urn:epc:id:sgtin:0614141.812345.6789")
  let restored = @moonepc.parse_sgtin_identity_uri(tag.to_identity_uri(), 5).unwrap()
  assert_eq(restored.to_tag_uri(), tag.to_tag_uri())
  assert_true(
    @moonepc.parse_sgtin_identity_uri(tag.to_identity_uri(), 8) is Err(_),
  )
}

///|
test "sgtin rejects malformed fields" {
  assert_true(
    @moonepc.parse_sgtin_tag_uri("urn:epc:tag:sgtin-96:8.0614141.812345.6789")
    is Err(_),
  )
  assert_true(
    @moonepc.parse_sgtin_tag_uri("urn:epc:tag:sgtin-96:3.12345.812345.6789")
    is Err(_),
  )
  assert_true(
    @moonepc.parse_sgtin_tag_uri(
      "urn:epc:tag:sgtin-96:3.0614141.812345.274877906944",
    )
    is Err(_),
  )
  assert_true(@moonepc.decode_sgtin96("30742z7bf7194e4000001a85") is Err(_))
  assert_true(@moonepc.decode_sgtin96("1234") is Err(_))
}

///|
test "sgtin partition boundaries roundtrip" {
  for
    uri in [
      "urn:epc:tag:sgtin-96:0.999999999999.9.274877906943", "urn:epc:tag:sgtin-96:7.99999999999.99.1",
      "urn:epc:tag:sgtin-96:1.9999999999.999.0", "urn:epc:tag:sgtin-96:2.999999999.9999.100",
      "urn:epc:tag:sgtin-96:3.99999999.99999.999999", "urn:epc:tag:sgtin-96:4.9999999.999999.12345678",
      "urn:epc:tag:sgtin-96:5.999999.9999999.123456789",
    ] {
    let value = @moonepc.parse_sgtin_tag_uri(uri).unwrap()
    assert_eq(
      @moonepc.decode_sgtin96(value.encode_hex().unwrap()).unwrap().to_tag_uri(),
      uri,
    )
  }
}

///|
test "sscc partition boundaries and header" {
  for
    uri in [
      "urn:epc:tag:sscc-96:0.123456789012.12345", "urn:epc:tag:sscc-96:1.12345678901.123456",
      "urn:epc:tag:sscc-96:2.1234567890.1234567", "urn:epc:tag:sscc-96:3.123456789.12345678",
      "urn:epc:tag:sscc-96:4.12345678.123456789", "urn:epc:tag:sscc-96:5.1234567.1234567890",
      "urn:epc:tag:sscc-96:6.123456.12345678901",
    ] {
    let value = @moonepc.parse_sscc_tag_uri(uri).unwrap()
    let hex = value.encode_hex().unwrap()
    assert_true(hex.has_prefix("31"))
    assert_eq(@moonepc.decode_sscc96(hex).unwrap().to_tag_uri(), uri)
  }
}

///|
test "sscc identity conversion keeps the caller-selected filter" {
  let tagged = @moonepc.parse_sscc_tag_uri(
    "urn:epc:tag:sscc-96:6.0614141.1234567890",
  ).unwrap()
  assert_eq(tagged.to_identity_uri(), "urn:epc:id:sscc:0614141.1234567890")
  assert_eq(
    @moonepc.parse_sscc_identity_uri(tagged.to_identity_uri(), 6)
    .unwrap()
    .to_tag_uri(),
    tagged.to_tag_uri(),
  )
  assert_true(
    @moonepc.parse_sscc_identity_uri(tagged.to_identity_uri(), 8) is Err(_),
  )
}

///|
test "sgln partition boundaries and location extensions roundtrip" {
  for
    uri in [
      "urn:epc:tag:sgln-96:0.999999999999..2199023255551", "urn:epc:tag:sgln-96:1.99999999999.9.1",
      "urn:epc:tag:sgln-96:2.9999999999.99.2", "urn:epc:tag:sgln-96:3.999999999.999.3",
      "urn:epc:tag:sgln-96:4.99999999.9999.4", "urn:epc:tag:sgln-96:5.9999999.99999.5",
      "urn:epc:tag:sgln-96:6.999999.999999.6",
    ] {
    let value = @moonepc.parse_sgln_tag_uri(uri).unwrap()
    let hex = value.encode_hex().unwrap()
    assert_true(hex.has_prefix("32"))
    assert_eq(@moonepc.decode_sgln96(hex).unwrap().to_tag_uri(), uri)
  }
}

///|
test "grai partition boundaries and serial maximum roundtrip" {
  for
    uri in [
      "urn:epc:tag:grai-96:0.999999999999..274877906943", "urn:epc:tag:grai-96:1.99999999999.9.1",
      "urn:epc:tag:grai-96:2.9999999999.99.2", "urn:epc:tag:grai-96:3.999999999.999.3",
      "urn:epc:tag:grai-96:4.99999999.9999.4", "urn:epc:tag:grai-96:5.9999999.99999.5",
      "urn:epc:tag:grai-96:6.999999.999999.6",
    ] {
    let value = @moonepc.parse_grai_tag_uri(uri).unwrap()
    let hex = value.encode_hex().unwrap()
    assert_true(hex.has_prefix("33"))
    assert_eq(@moonepc.decode_grai96(hex).unwrap().to_tag_uri(), uri)
  }
}

///|
test "sgln and grai identity URI conversion preserves tag-only filter" {
  let sgln = @moonepc.parse_sgln_tag_uri(
    "urn:epc:tag:sgln-96:3.0614141.00123.456",
  ).unwrap()
  assert_eq(sgln.to_identity_uri(), "urn:epc:id:sgln:0614141.00123.456")
  assert_eq(
    @moonepc.parse_sgln_identity_uri(sgln.to_identity_uri(), 3)
    .unwrap()
    .to_tag_uri(),
    sgln.to_tag_uri(),
  )
  let grai = @moonepc.parse_grai_tag_uri(
    "urn:epc:tag:grai-96:5.0614141.81234.123456",
  ).unwrap()
  assert_eq(grai.to_identity_uri(), "urn:epc:id:grai:0614141.81234.123456")
  assert_eq(
    @moonepc.parse_grai_identity_uri(grai.to_identity_uri(), 5)
    .unwrap()
    .to_tag_uri(),
    grai.to_tag_uri(),
  )
  assert_true(
    @moonepc.parse_grai_identity_uri(grai.to_identity_uri(), 8) is Err(_),
  )
}

///|
test "giai partition boundaries and identity URI conversion" {
  for
    company in [
      "999999999999", "99999999999", "9999999999", "999999999", "99999999", "9999999",
      "999999",
    ] {
    let uri = "urn:epc:tag:giai-96:6." + company + ".123456789"
    let value = @moonepc.parse_giai_tag_uri(uri).unwrap()
    let hex = value.encode_hex().unwrap()
    assert_true(hex.has_prefix("34"))
    let decoded = @moonepc.decode_giai96(hex).unwrap()
    assert_eq(decoded.to_tag_uri(), uri)
    assert_eq(
      @moonepc.parse_giai_identity_uri(decoded.to_identity_uri(), 6)
      .unwrap()
      .to_tag_uri(),
      uri,
    )
  }
  assert_true(
    @moonepc.parse_giai_tag_uri("urn:epc:tag:giai-96:0.0614141.0123") is Err(_),
  )
}

///|
test "gdti partition boundaries and 41-bit serial maximum" {
  for
    entry in [
      ("999999999999", ""),
      ("99999999999", "9"),
      ("9999999999", "99"),
      ("999999999", "999"),
      ("99999999", "9999"),
      ("9999999", "99999"),
      ("999999", "999999"),
    ] {
    let company = entry.0
    let document_type = entry.1
    let uri = "urn:epc:tag:gdti-96:0." +
      company +
      "." +
      document_type +
      ".2199023255551"
    let value = @moonepc.parse_gdti_tag_uri(uri).unwrap()
    let hex = value.encode_hex().unwrap()
    assert_true(hex.has_prefix("2c"))
    let decoded = @moonepc.decode_gdti96(hex).unwrap()
    assert_eq(decoded.to_tag_uri(), uri)
    assert_eq(
      @moonepc.parse_gdti_identity_uri(decoded.to_identity_uri(), 0)
      .unwrap()
      .to_tag_uri(),
      uri,
    )
  }
}

///|
test "decimal overflow and noncanonical variable serials are rejected" {
  assert_true(
    @moonepc.parse_sgtin_tag_uri(
      "urn:epc:tag:sgtin-96:0.0614141.812345.999999999999999999999999999",
    )
    is Err(_),
  )
  assert_true(
    @moonepc.parse_grai_tag_uri("urn:epc:tag:grai-96:0.0614141.812345.0001")
    is Err(_),
  )
  assert_true(
    @moonepc.parse_sgln_tag_uri("urn:epc:tag:sgln-96:0.0614141.12345.0001")
    is Err(_),
  )
}

///|
test "generic EPC-96 dispatch roundtrips all supported schemes" {
  for
    entry in [
      ("urn:epc:tag:sgtin-96:3.0614141.812345.6789", "3074257bf7194e4000001a85"),
      ("urn:epc:tag:sscc-96:0.123456789012.12345", "310072fa6468503039000000"),
      ("urn:epc:tag:sgln-96:3.0614141.00123.456", "3274257bf400f600000001c8"),
      ("urn:epc:tag:grai-96:5.0614141.81234.123456", "33b4257bf44f54800001e240"),
      ("urn:epc:tag:giai-96:6.999999.123456789", "34dbd08fc0000000075bcd15"),
      ("urn:epc:tag:gdti-96:3.0614141.12345.6789", "2c74257bf460720000001a85"),
    ] {
    let uri = entry.0
    let expected_hex = entry.1
    let parsed = @moonepc.parse_epc96_tag_uri(uri).unwrap()
    assert_eq(parsed.encode_hex().unwrap(), expected_hex)
    let decoded = @moonepc.decode_epc96(expected_hex).unwrap()
    assert_eq(decoded.to_tag_uri(), uri)
    assert_eq(decoded.to_identity_uri(), parsed.to_identity_uri())
  }
}

///|
test "generic EPC-96 dispatch rejects unknown schemes and malformed hex" {
  assert_true(
    @moonepc.parse_epc96_tag_uri("urn:epc:tag:gid-96:0.1.2.3") is Err(_),
  )
  assert_true(@moonepc.decode_epc96("ffffffffffffffffffffffff") is Err(_))
  assert_true(@moonepc.decode_epc96("not-hex") is Err(_))
}

///|
test "generic EPC identity parsing requires and preserves a valid filter" {
  let identity = "urn:epc:id:gdti:0614141.12345.6789"
  let value = @moonepc.parse_epc96_identity_uri(identity, 3).unwrap()
  assert_eq(value.to_identity_uri(), identity)
  assert_eq(value.to_tag_uri(), "urn:epc:tag:gdti-96:3.0614141.12345.6789")
  assert_true(@moonepc.parse_epc96_identity_uri(identity, 8) is Err(_))
  assert_true(
    @moonepc.parse_epc96_identity_uri("urn:epc:id:gid:1.2.3", 0) is Err(_),
  )
}
