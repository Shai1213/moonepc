# MoonEPC

MoonEPC 是纯 MoonBit 实现的 GS1 EPC 标识与 RFID tag-memory 编解码库及命令行工具。它将严格校验的 EPC tag URI、pure-identity URI 和 EPC-96 的 96 位数据互相转换，面向读写器适配层、供应链/资产服务和协议测试工具。

当前支持 SGTIN-96、SSCC-96、SGLN-96、GRAI-96、数字型 GIAI-96 与 GDTI-96。项目不实现通用 GS1 Application Identifier/条码解析、GS1 Digital Link、EPCIS 事件、RFID 空口帧或 CRC、硬件读写器驱动，也不声称覆盖完整 GS1 Tag Data Standard / Tag Data Translation。

主文档：[README.md](README.md)。 设计说明：[docs/design.md](docs/design.md)；GS1 规范版本、六种编码符合性范围和代表性向量：[docs/gs1-tds-2.3-conformance.md](docs/gs1-tds-2.3-conformance.md)；版本记录：[CHANGELOG.md](CHANGELOG.md)。

## 安装

需要近期 MoonBit CLI（支持 `moon.mod`）；已验证 `wasm` 和 `js` 后端。Native 检查/运行还需要本机 C 编译器。发布状态应以 [MoonCakes 模块页](https://mooncakes.io/docs/Shai1213/moonepc) 为准；模块坐标为 `Shai1213/moonepc@0.1.1`。

在消费者项目的 `moon.mod` 中添加精确版本依赖：

```moonbit
import {
  "Shai1213/moonepc@0.1.1",
}
```

在调用包的 `moon.pkg` 中添加导入：

```moonbit
import {
  "Shai1213/moonepc",
}
```

然后运行 `moon update` 和 `moon check --target wasm --deny-warn`。下方 CLI 命令在本项目源码根目录运行；API 示例放入消费者的 `fn main` 或测试块后运行。

在代码中导入 `Shai1213/moonepc`。推荐使用各 scheme 的 `parse_*_tag_uri` 或 `parse_*_identity_uri` 构造经过校验的值；预期输入错误通过 `Result[..., EpcError]` 返回。

## 快速开始

```sh
moon run --target wasm cmd/main -- sgtin-encode urn:epc:tag:sgtin-96:3.0614141.812345.6789
# 3074257bf7194e4000001a85

moon run --target wasm cmd/main -- sgtin-decode 3074257bf7194e4000001a85
# urn:epc:tag:sgtin-96:3.0614141.812345.6789
```

每种支持的 scheme 都有专用的 `<scheme>-encode` 和 `<scheme>-decode` 命令。通用 `encode` 根据 tag URI scheme 分派，通用 `decode` 根据 EPC header 分派：

```sh
moon run --target wasm cmd/main -- encode urn:epc:tag:gdti-96:3.0614141.12345.6789
# 2c74257bf460720000001a85
moon run --target wasm cmd/main -- decode 2c74257bf460720000001a85
# urn:epc:tag:gdti-96:3.0614141.12345.6789
```

pure-identity URI 不包含标签用途 filter，因此编码时必须显式提供 0 到 7 的 filter：

```sh
moon run --target wasm cmd/main -- identity-encode 3 urn:epc:id:gdti:0614141.12345.6789
# 2c74257bf460720000001a85
```

位串适用于需要检查 EPC 网络位序的工具链：

```sh
moon run --target wasm cmd/main -- bits-encode urn:epc:tag:sgtin-96:3.0614141.812345.6789
moon run --target wasm cmd/main -- bits-decode 001100000111010000100101011110111111011100011001010011100100000000000000000000000001101010000101
```

读写器联调时可以查看已解码的 EPC 结构字段：

```sh
moon run --target wasm cmd/main -- inspect 3074257bf7194e4000001a85
```

输出包括 scheme、header、filter、partition、company prefix 位数、EPC 数据位长和规范 tag URI。

解码器接受大小写十六进制，但输入必须恰好为 24 个十六进制字符（96 位）。

CLI 使用 `--help` 或 `-h` 查看命令列表，使用 `--version` 或 `-V` 查看当前包版本。

## MoonBit API

```mbt
let epc = @moonepc.parse_sgtin_tag_uri(
  "urn:epc:tag:sgtin-96:3.0614141.812345.6789",
).unwrap()
let hex = epc.encode_hex().unwrap()
let decoded = @moonepc.decode_sgtin96(hex).unwrap()
assert_eq(decoded.to_tag_uri(), epc.to_tag_uri())
```

统一入口 `parse_epc96_tag_uri`、`parse_epc96_identity_uri` 和 `decode_epc96` 分别按 URI scheme、调用者提供的 filter、EPC header 分派。`Epc96` 支持十六进制、12 字节网络序和 96 字符位串表示。`decode_epc96_records` 与 `encode_epc96_records` 可处理固定步长记录中的 EPC 字段；批量解析 API 保留输入顺序，identity 批量解析要求 URI 与 filter 数组长度相同。字节记录 API 只处理 EPC 数据字段，不包含读写器帧、CRC 或传输协议。

身份 URI 与 tag URI 有意分开：`parse_epc96_identity_uri` 和各 scheme 的 identity parser 要求显式传入 filter，避免从不含 filter 的身份标识中推断标签用途。

## 开发与验证

```sh
moon info
moon fmt
moon check --target all --deny-warn
moon test --target wasm --deny-warn
moon test --target js --deny-warn
moon test --target native --deny-warn
moon run --target wasm cmd/main -- sgtin-decode 3074257bf7194e4000001a85
```

GitHub Actions 对 push、pull request 和手动触发运行全目标检查、WASM/JS/Native 测试，以及 WASM/Native CLI smoke tests。Native 本地测试与运行需安装 C 编译器。测试覆盖已知编码向量、六种 scheme 的分区边界 round-trip、全部 8 个 filter 值在六种 scheme 中的 48 组 URI 编解码往返、统一分派、identity/tag URI 转换、记录字节偏移和非法输入拒绝路径；当前 33 个测试用例在 WASM 与 JS 目标通过。与 GS1 官方 TDT 转换器进行过每种受支持 scheme 一个向量的差分检查，6/6 编码值一致；这不是完整官方套件、全部分区或所有非法输入的兼容性认证。

## 兼容性边界

不支持 SGTIN-198、GRAI-170、字母数字型 GIAI、CPI、GID 等其它 scheme，也不解析任意 EPC URI。遇到未知 header、错误长度、非法字符、越界字段或无效 filter/partition 时返回错误，不猜测或自动修复输入。当前兼容性声明限于仓库列出的测试和六条 TDT 差分向量。

规范版本固定为 GS1 EPC Tag Data Standard (TDS) Release 2.3.0，机器可读翻译基线为 TDT 2.2.0；本项目终点是对六种已列明 EPC-96 scheme 的编码布局、filter、partition、URI 映射和边界行为实现限定范围内的完整符合性，不是完整 TDS/TDT 支持或 GS1 认证。TDS 2.3.0 新增的 “++” schemes 不在当前支持范围。当前官方 TDT 差分证据为六种各一条（6/6），完整目标与现有证据差异、六组代表性输入输出见 [符合性范围说明](docs/gs1-tds-2.3-conformance.md)。本项目为独立 MoonBit 实现，不复制 TDT 实现代码或生成数据。标准：[TDS 2.3.0](https://ref.gs1.org/standards/tds/2.3.0/)；机器可读基线：[TDT 2.2.0](https://ref.gs1.org/standards/tdt/2.2.0/)。

## 许可与 AI 披露

代码按 Apache-2.0 许可发布，见 [LICENSE](LICENSE)。代码、测试和文档使用 AI 辅助编写与审阅；项目维护者仍负责核对标准约束、来源和实现正确性。
