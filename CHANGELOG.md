# Changelog

## 0.1.1

- Add a regression matrix for all eight 3-bit filter values across six EPC-96 schemes (48 scheme/filter roundtrips).
- Distinguish local regression coverage from the six official TDT reference-vector comparisons.

## 0.1.0

- Add strict EPC-96 URI parsing and encoding/decoding for SGTIN, SSCC, SGLN, GRAI, numeric GIAI and GDTI.
- Add generic dispatch, explicit-filter identity URI conversion, bit-string and network-order byte codecs, batch operations and fixed-stride record helpers.
- Add a command-line interface for scheme-specific and generic conversion, identity encoding, bit strings and EPC inspection.
- Validate decoded binary fields against decimal partition capacities and reject SGTIN serial forms that cannot round-trip without losing leading zeros.
- Verify six GS1 TDT reference vectors and malformed/boundary cases across WASM, JavaScript and wasm-gc test targets; 32 test cases pass on each target.
