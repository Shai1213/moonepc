# MoonEPC 生态查重记录

检索日期：2026-11-23（复核 MoonCakes `epc`、`sgtin`、`gs1`、`rfid` 查询及 GitHub 仓库状态；完整反向检索记录见 2026-11-22）。结论只覆盖本文列出的公开索引和资料，不等同于全网唯一性证明或主办方裁决。

## 项目指纹

- 问题：在 MoonBit 程序中将 GS1 EPC 纯身份 URI、带 filter 的 tag URI 和 RFID EPC tag-memory 96 位 hex 互相转换，并拒绝非法分区、字段、header 与位长。
- 使用者与输入：读写器适配层输入 96 位 hex；供应链/资产服务输入 EPC tag 或 identity URI；协议测试输入边界字段和已知编码向量。
- 行为与输出：严格校验六种 EPC-96 scheme（SGTIN、SSCC、SGLN、GRAI、数字型 GIAI、GDTI）；返回 typed 值、规范 URI 或 96 位 hex，也可通过统一入口按 header/scheme 分派。
- 不包括：GS1 AI/条码解析、GS1 Digital Link、EPCIS、空口帧/CRC、硬件驱动及其他 EPC 编码长度或 scheme。

## 检索范围与证据

- 按比赛 Research Guide 执行 MoonCakes 本地 `moon search`：`epc`（0 个结果）、`tds`（命中 `moonbitstack/moonsqls`，SQL Server TDS 协议，无 EPC tag-memory 功能）、`gs1`（命中 `Qlcdsba/moonbit-barcoder`、`fan-ere/moonbarcode`、`fan-ere/moon-pdf417-core`、`gywcs101/MoonDataMatrix`、`sssssurf/checkdigit`）、`rfid`（命中铁路 ATP/Eurobalise 项目）。检索结果不能证明不存在未索引包。
- Final reverse queries on 2026-11-22: MoonCakes `epc tag uri` and `epc96` returned 0 modules; `epc` also returned 0. `pure identity`, `SGTIN`, and `RFID tag` returned lexical matches in unrelated identity, weaving, embroidery, and other summaries; no EPC-96 codec was identified in those results. GitHub repository search `EPC language:MoonBit` returned 0 repositories (`incomplete_results=false`). Exact `Shai1213/moonepc` lookup returned 404 before publication. These indexed searches are bounded and do not cover unindexed/private repositories or prove uniqueness.
- 2026-11-23 repeat query: MoonCakes `epc` returned no modules; `sgtin` returned five unrelated packages, `gs1` returned barcode/check-digit and other modules, and `rfid` returned a railway ATP/Eurobalise package. Exact GitHub `Shai1213/moonepc` lookup still reports not found. These searches do not replace the bounded full reverse-search record above.
- GS1 相邻包源码/功能核对：[`moonbit-barcoder`](https://github.com/Qlcdsba/moonbit-barcoder) 的范围是 GS1 AI/Code 128 条码数据；[`moonbarcode`](https://github.com/fan-ere/moonbarcode) 聚焦一维条码生成、验证、渲染和 AI 解析。这些包解决扫描器条码 payload，而非 EPC TDS 96 位 tag-memory header/partition 编解码，归类为同一 GS1 方向、核心任务不同。
- `moon search tds` 的 [`moonsqls`](https://github.com/moonbitstack/moonsqls) 指 SQL Server Tabular Data Stream，词面缩写相同但领域、用户和输入输出不同，判为无实质功能重合。
- `moon search rfid` 的 [`moonbit-cbtc-atp`](https://github.com/zklmbq02140831/moonbit-cbtc-atp) 包含铁路 Eurobalise/ATP 电文及安全校验；其 RFID 是铁路信号传输场景，不执行 GS1 EPC URI 与通用商品/资产 EPC tag-memory 转换，判为相邻但任务不同。
- GitHub MoonBit EPC/RFID 搜索记录见预留注册项：EPC、RFID 未返回直接仓库；GS1 命中 `moonbit-barcoder`，其 README 与源码已核对。账户绑定的 GitHub 列表在 2026-11-21 返回 0 个公开仓库。公共搜索和用户仓库列表不是 GitHub 全站穷尽性索引。
- 比赛注册表已存在 `moonbit-barcoder`、RINEX（`xuting22/rinex`）和八边形几何（`haol-05/moon-octagon`）记录；前者是相邻条码处理，后两者是不同问题域，均不实现 EPC tag-memory codec。
- 标准依据：GS1 [TDS](https://ref.gs1.org/standards/tds/) 与官方 [TDT](https://github.com/gs1/TDT)。实现使用独立 MoonBit 位操作代码；未复制 TDT 实现或生成文件。有限差分结果及样本哈希见下节；未运行官方完整 TDT 兼容套件。

## 候选比较

### Official TDT differential check (2026-11-22)

Using the official `gs1/TDT` translator and `TDT_JSON_artefacts.zip`, one EPC-96 tag-URI -> HEX -> tag-URI vector was tested for each supported scheme. All 6 encoded values matched MoonEPC bit-for-bit after case normalization; both decoders returned the original tag URI. This is a bounded interoperability check, not the complete official suite.

| Scheme | GCP length | EPC-96 hex |
| --- | ---: | --- |
| SGTIN-96 | 7 | `3074257bf7194e4000001a85` |
| SSCC-96 | 12 | `310072fa6468503039000000` |
| SGLN-96 | 7 | `3274257bf400f600000001c8` |
| GRAI-96 | 7 | `33b4257bf44f54800001e240` |
| GIAI-96 | 6 | `34dbd08fc0000000075bcd15` |
| GDTI-96 | 7 | `2c74257bf460720000001a85` |

Official artefact SHA-256: `FC8CDF44267C3454A5D259796B15B36483944E0B43498AE53FB306BBCAA23120`; translator SHA-256: `A36595D5708010794E8274E85F04E0E346EA9D7F28A51B67E7B03F9F7E32C1CC`. The GS1 GCP-prefix list endpoint denied access during retrieval; no GCP auto-discovery, pure-identity URI, Digital Link, invalid-input, or exhaustive partition compatibility is claimed from these six vectors.

| 候选 | 用户/输入输出 | 核心功能 | 与 MoonEPC 关系 | 判定 |
| --- | --- | --- | --- | --- |
| `moonbit-barcoder` / `moonbarcode` | 条码消费者；GS1 AI 字符串或条码内容，输出解析字段/符号 | GS1 AI 与条码编码、校验、渲染 | GS1 领域相邻；不做 EPC header/partition/tag URI 与 96 位 tag-memory 互转 | 高度相邻的不同功能，不构成成熟直接替代 |
| `moonbit-cbtc-atp` | 铁路信号系统；Eurobalise/ATP 数据 | 铁路控制报文与安全验证 | 使用 RFID/应答器技术但标识体系、数据模型和工作流不同 | 同词面领域邻接，无实质任务重合 |
| `moonsqls` | SQL Server 客户端；TDS 网络协议数据 | 数据库连接、查询和事务 | “TDS”缩写相同；不是 GS1 Tag Data Standard | 无实质功能重合 |
| RINEX / 八边形几何 | GNSS 文件交换 / 几何计算 | 科学数据和几何算法 | 用户、输入输出和协议均不同 | 不同问题域，作为候选方向比较 |

## 候选复核评分（2026-11-22）

以下是依据上述可复查的模块搜索结果、标准依据和已完成实现范围所作的工程复核，不是用户访谈或参赛者个人经历。各项 1–5 分；“重合风险”分数越高表示在已检索生态中直接重合风险越低。任何硬失败都不能由总分抵消。

| 候选问题域 | 生态复用广度 | 用户/工作流多样性 | 重合风险 | 实现深度 | 可验证性 | 可行性 | 可维护性 | 总分 | 关键依据与未验证项 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| GS1 EPC-96 标识与 tag-memory 转换 | 4 | 4 | 4 | 4 | 5 | 4 | 4 | 29/35 | GS1 TDS/TDT 提供明确位布局和可运行参考转换器；已有六种 scheme 的实现及逐种一条差分向量。实际下游采用规模未做访谈或下载量验证；完整官方套件仍未运行。 |
| RINEX 观测文件检查 | 3 | 3 | 4 | 4 | 5 | 4 | 4 | 27/35 | 已有 `xuting22/rinex` MoonBit 项目，问题域相邻且已有接收检查能力；扩展候选需先证明新增工作流优于维护或扩展该项目。 |
| 八边形抽象域与关系不变量分析 | 4 | 4 | 3 | 4 | 5 | 4 | 4 | 28/35 | 已有 `haol-05/moon-octagon` 覆盖整数八边形域及控制流分析，直接重叠风险高于 EPC；应优先考虑参与现有实现。 |

本复核维持 EPC-96 候选：它有规范和参考实现作为行为基线，检索到的 GS1 条码项目处理的是条码 payload/AI 而非 EPC tag-memory bit layout，且六种支持 scheme 已有有限差分结果。评分反映工程判断而非用户需求调查；不得据此声称已验证市场需求、生态唯一性或主办方认可。

## 决策与限制

在记录的 MoonCakes 检索结果和源码证据范围内，未发现成熟 MoonBit 项目直接实现本项目限定的六种 GS1 EPC-96 URI/tag-memory 转换。条码与 GS1 AI 工具不是完全无关，应在 README 和申报材料中持续说明边界。最终反向搜索覆盖了 `epc96`、`epc tag uri`、`pure identity`、`SGTIN`、`RFID tag` 和 GitHub `EPC language:MoonBit` 仓库查询；结果受公开索引范围限制，不构成绝对唯一性证明。
