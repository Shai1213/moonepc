# Design Notes

MoonEPC separates identifier text from the fixed 96-bit tag-memory record. The public scheme structs retain the GS1 decimal components and filter; the generic `Epc96` enum provides scheme-independent dispatch without erasing the original scheme.

## Encoding model

The first 8 bits select a scheme header, the next 3 bits carry the tag filter, and the next 3 bits select one of seven partition rows. A row determines the company-prefix decimal width and the corresponding binary width. Scheme fields occupy the remaining bits according to their fixed EPC-96 layout. The implementation writes and reads fields most-significant-bit first within 32-bit words and emits network-order bytes.

Text parsing validates decimal syntax, partition widths, filter range and field capacity before constructing a value. Decoding performs the inverse checks, including rejecting bit patterns whose values cannot be represented by the row's decimal field width. This prevents a byte sequence from being accepted and then rendered as an invalid EPC URI.

Pure-identity URIs omit the physical tag filter. MoonEPC therefore requires the caller to supply it when parsing an identity URI and preserves it explicitly in `Epc96Identity` when converting a tag value for storage.

## Buffer integration

The byte API uses exactly 12 bytes per tag. `decode_epc96_bytes_at` and `encode_epc96_bytes_into` accept an offset into a caller-owned buffer and validate the full range before reading or writing. Fixed-stride record helpers accept a stride and EPC offset; decoding reports each row independently so a malformed row does not discard later rows. These APIs describe an EPC memory field only, not a reader protocol frame, checksum or air-interface message.

## Verification boundary

Tests cover all six supported headers, partition boundaries, malformed decimal fields, invalid binary partition values, URI identity/filter behavior, byte order, offsets and partial records. Six known vectors were compared with the GS1 TDT translator. This is finite differential evidence, not certification against the complete GS1 test corpus.
